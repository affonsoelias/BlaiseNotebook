unit uCodeRunner;

{
  uCodeRunner - Dynamic Free Pascal Compilation & Execution Sandbox
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)
}

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Process, DateUtils, fphttpclient, sha1,
  mormot.core.base, mormot.core.json, mormot.core.os;

type
  TOnStreamOutput = procedure(const ACellId, AStreamType, AText: RawUtf8) of object;
  TOnDisplayData = procedure(const ACellId, APayloadJson: RawUtf8) of object;
  TOnExecuteReply = procedure(const ACellId, AStatus: RawUtf8; AExecCount, ATimeMs: Integer) of object;

  { TCodeRunner - Compiles and runs Pascal scripts on the fly }
  TCodeRunner = class
  private
    FWorkspaceDir: string;
    FPackagesDir: string;
    FOnStream: TOnStreamOutput;
    FOnDisplay: TOnDisplayData;
    FOnReply: TOnExecuteReply;
    FCurrentProcess: TProcess;
    FCurrentCellId: string;
    FInterrupted: Boolean;
    FDaemonProcess: TProcess;
    FDaemonPort: Integer;

    function FindDaemonScript: string;
    procedure EnsureSessionDaemon;
    procedure StopSessionDaemon;
    function ComputeSourceHash(const ASource: string): string;
    procedure DiscoverPackageDirs(ADirs: TStrings);
    function ExtractUserUses(var ASource: string; out AUserUnits: string): Boolean;
    function FindFPCExe: string;
    function FindPythonExe: string;
    function IsPipCommand(const ASource: string; out APipArgs: string): Boolean;
    procedure ExecutePip(const ACellId: string; AExecCount: Integer; const APipArgs: string; AStartTick: Int64);
    function PrepareSourceFile(const ACellId: string; const ASource: string; out APrgPath: string): Boolean;
    function CompileSource(const APrgPath: string; out AExePath: string; out AErrors: string): Boolean;
    procedure ExecuteBinary(const ACellId: string; const AExePath: string; AExecCount: Integer; AStartTick: Int64);
  public
    constructor Create(const AWorkspaceDir: string = '');
    destructor Destroy; override;

    procedure ExecuteCell(const ACellId: string; AExecCount: Integer; const ASource: string);
    procedure Interrupt(const ACellId: string = '');
    procedure RestartKernel(const ACellId: string = '');

    property DaemonPort: Integer read FDaemonPort write FDaemonPort;
    property OnStream: TOnStreamOutput read FOnStream write FOnStream;
    property OnDisplay: TOnDisplayData read FOnDisplay write FOnDisplay;
    property OnReply: TOnExecuteReply read FOnReply write FOnReply;
  end;

implementation

{ TCodeRunner }

constructor TCodeRunner.Create(const AWorkspaceDir: string);
var
  SR: TSearchRec;
begin
  inherited Create;
  if AWorkspaceDir <> '' then
    FWorkspaceDir := AWorkspaceDir
  else
    FWorkspaceDir := ExtractFilePath(ParamStr(0)) + 'workspace';

  ForceDirectories(FWorkspaceDir);

  // Locate packages/ directory
  FPackagesDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'packages');
  if not DirectoryExists(FPackagesDir) then
    FPackagesDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + 'packages');
  if not DirectoryExists(FPackagesDir) then
    FPackagesDir := ExpandFileName('packages');
  if not DirectoryExists(FPackagesDir) then
    FPackagesDir := ExpandFileName('frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'packages');

  // Purge any stale package unit artifacts from workspace to avoid PPU checksum mismatch
  if FindFirst(FWorkspaceDir + DirectorySeparator + 'Blaise*.*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (LowerCase(ExtractFileExt(SR.Name)) = '.ppu') or (LowerCase(ExtractFileExt(SR.Name)) = '.o') then
          DeleteFile(FWorkspaceDir + DirectorySeparator + SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  FDaemonPort := 9099;
  FDaemonProcess := nil;
  EnsureSessionDaemon;
end;

destructor TCodeRunner.Destroy;
begin
  StopSessionDaemon;
  inherited Destroy;
end;


function TCodeRunner.FindDaemonScript: string;
var
  Candidate: string;
begin
  Result := '';
  // 1. Check ../kernel/blaise_kernel_daemon.py
  Candidate := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + 'kernel' + DirectorySeparator + 'blaise_kernel_daemon.py');
  if FileExists(Candidate) then Exit(Candidate);

  // 2. Check kernel/blaise_kernel_daemon.py
  Candidate := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'kernel' + DirectorySeparator + 'blaise_kernel_daemon.py');
  if FileExists(Candidate) then Exit(Candidate);

  // 3. Check frontend/server/kernel/blaise_kernel_daemon.py
  Candidate := ExpandFileName('frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'kernel' + DirectorySeparator + 'blaise_kernel_daemon.py');
  if FileExists(Candidate) then Exit(Candidate);

  // 4. Check server/kernel/blaise_kernel_daemon.py
  Candidate := ExpandFileName('server' + DirectorySeparator + 'kernel' + DirectorySeparator + 'blaise_kernel_daemon.py');
  if FileExists(Candidate) then Exit(Candidate);

  // 5. Check in workspace/../kernel/blaise_kernel_daemon.py
  Candidate := ExpandFileName(FWorkspaceDir + DirectorySeparator + '..' + DirectorySeparator + 'kernel' + DirectorySeparator + 'blaise_kernel_daemon.py');
  if FileExists(Candidate) then Exit(Candidate);
end;

procedure TCodeRunner.EnsureSessionDaemon;
var
  Client: TFPHttpClient;
  Resp: string;
  PyExe: string;
  ScriptPath: string;
  WaitCount: Integer;
begin
  // Check if daemon is already responding
  Client := TFPHttpClient.Create(nil);
  try
    try
      Client.IOTimeout := 400;
      Resp := Client.Get('http://127.0.0.1:' + IntToStr(FDaemonPort) + '/ping');
      if Pos('"status": "ok"', Resp) > 0 then
        Exit; // already running!
    except
      // not responding, will launch below
    end;
  finally
    Client.Free;
  end;

  PyExe := FindPythonExe;
  if PyExe = '' then PyExe := 'python';

  ScriptPath := FindDaemonScript;
  if (ScriptPath = '') or not FileExists(ScriptPath) then
    Exit;

  try
    if Assigned(FDaemonProcess) then
    begin
      try
        if FDaemonProcess.Running then
          FDaemonProcess.Terminate(0);
      except
      end;
      FreeAndNil(FDaemonProcess);
    end;

    FDaemonProcess := TProcess.Create(nil);
    FDaemonProcess.Executable := PyExe;
    FDaemonProcess.Parameters.Add(ScriptPath);
    FDaemonProcess.Parameters.Add('--port');
    FDaemonProcess.Parameters.Add(IntToStr(FDaemonPort));
    FDaemonProcess.Options := [poNoConsole];
    FDaemonProcess.Execute;

    // Wait up to 2 seconds for daemon to start
    WaitCount := 0;
    while (WaitCount < 20) and FDaemonProcess.Running do
    begin
      Sleep(100);
      Inc(WaitCount);
      Client := TFPHttpClient.Create(nil);
      try
        try
          Client.IOTimeout := 200;
          Resp := Client.Get('http://127.0.0.1:' + IntToStr(FDaemonPort) + '/ping');
          if Pos('"status": "ok"', Resp) > 0 then
            Break;
        except
        end;
      finally
        Client.Free;
      end;
    end;
  except
  end;
end;

procedure TCodeRunner.StopSessionDaemon;
var
  Client: TFPHttpClient;
  Stream: TStringStream;
begin
  try
    Client := TFPHttpClient.Create(nil);
    Stream := TStringStream.Create('{}');
    try
      Client.IOTimeout := 500;
      Client.AddHeader('Content-Type', 'application/json');
      Client.RequestBody := Stream;
      Client.Post('http://127.0.0.1:' + IntToStr(FDaemonPort) + '/shutdown');
    except
    end;
    Stream.Free;
    Client.Free;
  except
  end;

  if Assigned(FDaemonProcess) then
  begin
    try
      if FDaemonProcess.Running then
      begin
        Sleep(100);
        if FDaemonProcess.Running then
          FDaemonProcess.Terminate(0);
      end;
    except
    end;
    FreeAndNil(FDaemonProcess);
  end;
end;

procedure TCodeRunner.RestartKernel(const ACellId: string);
var
  Client: TFPHttpClient;
  Stream: TStringStream;
  SR: TSearchRec;
begin
  // 1. Reset Python daemon state
  try
    Client := TFPHttpClient.Create(nil);
    Stream := TStringStream.Create('{}');
    try
      Client.IOTimeout := 1500;
      Client.AddHeader('Content-Type', 'application/json');
      Client.RequestBody := Stream;
      Client.Post('http://127.0.0.1:' + IntToStr(FDaemonPort) + '/reset');
    except
    end;
    Stream.Free;
    Client.Free;
  except
  end;

  // 2. Ensure daemon is running
  EnsureSessionDaemon;

  // 3. Purge workspace binaries and temp files
  if FindFirst(FWorkspaceDir + DirectorySeparator + 'cell_*.*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        DeleteFile(FWorkspaceDir + DirectorySeparator + SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  if Assigned(FOnStream) then
  begin
    FOnStream(RawUtf8(ACellId), 'stdout', '[Kernel] Workspace memory cleared and session restarted successfully.'#10);
  end;
end;

function TCodeRunner.ComputeSourceHash(const ASource: string): string;
begin
  Result := SHA1Print(SHA1String(Trim(ASource)));
end;

procedure TCodeRunner.DiscoverPackageDirs(ADirs: TStrings);
var
  CoreDir, ExtDir: string;
  SR: TSearchRec;
begin
  if ADirs = nil then Exit;

  // 1. Core package dir
  CoreDir := FPackagesDir + DirectorySeparator + 'core';
  if DirectoryExists(CoreDir) and (ADirs.IndexOf(CoreDir) < 0) then
    ADirs.Add(CoreDir);

  // 2. Discover all subdirectories under packages/external/
  ExtDir := FPackagesDir + DirectorySeparator + 'external';
  if DirectoryExists(ExtDir) then
  begin
    if ADirs.IndexOf(ExtDir) < 0 then
      ADirs.Add(ExtDir);

    if FindFirst(ExtDir + DirectorySeparator + '*', faAnyFile, SR) = 0 then
    begin
      try
        repeat
          if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
          begin
            if DirectoryExists(ExtDir + DirectorySeparator + SR.Name) and (ADirs.IndexOf(ExtDir + DirectorySeparator + SR.Name) < 0) then
              ADirs.Add(ExtDir + DirectorySeparator + SR.Name);
          end;
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;
  end;

  // 4. Current workspace dir
  if (FWorkspaceDir <> '') and DirectoryExists(FWorkspaceDir) and (ADirs.IndexOf(FWorkspaceDir) < 0) then
    ADirs.Add(FWorkspaceDir);
end;

function TCodeRunner.ExtractUserUses(var ASource: string; out AUserUnits: string): Boolean;
var
  i, Len, UsesPos, SemiPos: Integer;
  InComment, InLineComment: Boolean;
  Token: string;
begin
  Result := False;
  AUserUnits := '';
  Len := Length(ASource);
  i := 1;
  InComment := False;
  InLineComment := False;
  UsesPos := 0;

  while (i <= Len) do
  begin
    // Check line comment //
    if not InComment and not InLineComment and (i < Len) and (ASource[i] = '/') and (ASource[i+1] = '/') then
    begin
      InLineComment := True;
      Inc(i, 2);
      Continue;
    end;

    if InLineComment then
    begin
      if ASource[i] in [#10, #13] then
        InLineComment := False;
      Inc(i);
      Continue;
    end;

    // Check block comment { ... }
    if not InComment and (ASource[i] = '{') then
    begin
      InComment := True;
      Inc(i);
      Continue;
    end;

    if InComment then
    begin
      if ASource[i] = '}' then
        InComment := False;
      Inc(i);
      Continue;
    end;

    // Skip whitespace
    if ASource[i] in [' ', #9, #10, #13] then
    begin
      Inc(i);
      Continue;
    end;

    // Check identifier token
    if (UpCase(ASource[i]) in ['A'..'Z', '_']) then
    begin
      Token := '';
      UsesPos := i;
      while (i <= Len) and (UpCase(ASource[i]) in ['A'..'Z', '0'..'9', '_']) do
      begin
        Token := Token + UpCase(ASource[i]);
        Inc(i);
      end;

      if Token = 'USES' then
      begin
        // Found uses! Find terminating semicolon
        SemiPos := 0;
        while (i <= Len) do
        begin
          if ASource[i] = ';' then
          begin
            SemiPos := i;
            Break;
          end;
          Inc(i);
        end;

        if SemiPos > UsesPos then
        begin
          // Extract units
          AUserUnits := Trim(Copy(ASource, UsesPos + 4, SemiPos - (UsesPos + 4)));
          // Remove uses clause from source
          Delete(ASource, UsesPos, SemiPos - UsesPos + 1);
          ASource := Trim(ASource);
          Result := True;
          Exit;
        end;
      end
      else
      begin
        // First token is NOT 'uses' (e.g. 'var', 'begin', 'const', etc.)
        Exit;
      end;
    end
    else
      Inc(i);
  end;
end;

function TCodeRunner.PrepareSourceFile(const ACellId: string; const ASource: string; out APrgPath: string): Boolean;
var
  CleanSource: string;
  CodeLines: TStringList;
  HasProgramTag: Boolean;
  FinalCode: TStringList;
  SafeId: string;
  FullText: string;
  UserUnits: string;
  HasUserUses: Boolean;
begin
  Result := False;
  CleanSource := Trim(ASource);
  if CleanSource = '' then Exit;

  SafeId := ACellId;
  SafeId := StringReplace(SafeId, '-', '_', [rfReplaceAll]);
  SafeId := StringReplace(SafeId, ' ', '_', [rfReplaceAll]);

  APrgPath := FWorkspaceDir + DirectorySeparator + 'cell_' + SafeId + '.lpr';

  CodeLines := TStringList.Create;
  FinalCode := TStringList.Create;
  try
    CodeLines.Text := CleanSource;
    HasProgramTag := (Pos('program ', LowerCase(CleanSource)) = 1) or
                     (Pos('program'#10, LowerCase(CleanSource)) = 1) or
                     (Pos('program'#13, LowerCase(CleanSource)) = 1);

    if HasProgramTag then
    begin
      // User provided a full program
      FinalCode.Assign(CodeLines);
    end
    else
    begin
      // Check if user provided custom uses clause
      HasUserUses := ExtractUserUses(CleanSource, UserUnits);

      // Normalize snippet end:
      FullText := Trim(CleanSource);
      if Pos('begin', LowerCase(FullText)) = 0 then
      begin
        CleanSource := 'begin' + sLineBreak + '  ' + CleanSource + sLineBreak + 'end.';
      end
      else
      begin
        if (Length(FullText) >= 4) and (Copy(FullText, Length(FullText) - 3, 4) = 'end;') then
          CleanSource := Copy(FullText, 1, Length(FullText) - 1) + '.'
        else if (Length(FullText) >= 4) and (Copy(FullText, Length(FullText) - 3, 4) <> 'end.') then
          CleanSource := FullText + sLineBreak + 'end.';
      end;

      // Wrap snippet into a valid Object Pascal console program
      FinalCode.Add('program CellRunner_' + SafeId + ';');
      FinalCode.Add('{$mode objfpc}{$H+}');
      FinalCode.Add('{$modeswitch advancedrecords}');
      FinalCode.Add('uses');
      if HasUserUses then
      begin
        FinalCode.Add('  SysUtils, Math, Classes, BlaiseOutput,');
        FinalCode.Add('  ' + UserUnits + ';');
      end
      else
      begin
        FinalCode.Add('  SysUtils, Math, Classes, BlaiseOutput, BlaiseMathKernel,');
        FinalCode.Add('  BlaisePyKernel, BlaiseDataScience, BlaisePandas, BlaiseSklearn;');
      end;
      FinalCode.Add('');
      FinalCode.Add(CleanSource);
    end;

    FinalCode.SaveToFile(APrgPath);
    Result := True;
  finally
    CodeLines.Free;
    FinalCode.Free;
  end;
end;

function TCodeRunner.CompileSource(const APrgPath: string; out AExePath: string; out AErrors: string): Boolean;
var
  Proc: TProcess;
  OutStream: TMemoryStream;
  BytesRead: LongInt;
  Buffer: array[0..2047] of Byte;
  PackageDirs: TStringList;
  i: Integer;
  OutputStr: string;
begin
  Result := False;
  AExePath := ChangeFileExt(APrgPath, {$ifdef WINDOWS}'.exe'{$else}''{$endif});
  AErrors := '';

  Proc := TProcess.Create(nil);
  OutStream := TMemoryStream.Create;
  PackageDirs := TStringList.Create;
  try
    Proc.Executable := FindFPCExe;
    Proc.Parameters.Add('-Mobjfpc');
    Proc.Parameters.Add('-Sh');
    Proc.Parameters.Add('-O2');
    Proc.Parameters.Add('-FE' + FWorkspaceDir);
    // Dynamically discover and register all package directories
    DiscoverPackageDirs(PackageDirs);
    for i := 0 to PackageDirs.Count - 1 do
      Proc.Parameters.Add('-Fu' + PackageDirs[i]);

    Proc.Parameters.Add(APrgPath);

    Proc.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    Proc.Execute;

    while Proc.Running do
    begin
      while Proc.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
          OutStream.Write(Buffer, BytesRead);
      end;
      Sleep(10);
    end;

    // Read remaining bytes
    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
        OutStream.Write(Buffer, BytesRead);
    end;

    if OutStream.Size > 0 then
    begin
      SetLength(OutputStr, OutStream.Size);
      OutStream.Position := 0;
      OutStream.Read(OutputStr[1], OutStream.Size);
      AErrors := OutputStr;
    end;

    Result := (Proc.ExitStatus = 0) and FileExists(AExePath);
  finally
    Proc.Free;
    OutStream.Free;
    PackageDirs.Free;
  end;
end;

procedure TCodeRunner.Interrupt(const ACellId: string);
begin
  if (ACellId = '') or (FCurrentCellId = ACellId) then
  begin
    FInterrupted := True;
    if (FCurrentProcess <> nil) and FCurrentProcess.Running then
    begin
      try
        FCurrentProcess.Terminate(1);
      except
      end;
    end;
  end;
end;

procedure TCodeRunner.ExecuteBinary(const ACellId: string; const AExePath: string; AExecCount: Integer; AStartTick: Int64);
var
  Proc: TProcess;
  BytesRead: LongInt;
  Buffer: array[0..2047] of Byte;
  Chunk, Accum: string;
  ElapsedMs: Integer;

  procedure FlushAccum(AllLines: Boolean);
  var
    PosN: Integer;
    CurLine, CurPayload: string;
  begin
    while True do
    begin
      PosN := Pos(#10, Accum);
      if PosN > 0 then
      begin
        CurLine := Copy(Accum, 1, PosN - 1);
        Delete(Accum, 1, PosN);
        if (Length(CurLine) > 0) and (CurLine[Length(CurLine)] = #13) then
          SetLength(CurLine, Length(CurLine) - 1);

        if Pos('@@BLAISE_PAYLOAD@@:', CurLine) = 1 then
        begin
          CurPayload := Copy(CurLine, Length('@@BLAISE_PAYLOAD@@:') + 1, MaxInt);
          if Assigned(FOnDisplay) then
            FOnDisplay(RawUtf8(ACellId), RawUtf8(CurPayload));
        end
        else
        begin
          if Assigned(FOnStream) then
            FOnStream(RawUtf8(ACellId), 'stdout', RawUtf8(CurLine + #10));
        end;
      end
      else
      begin
        if AllLines and (Accum <> '') then
        begin
          CurLine := Accum;
          Accum := '';
          if (Length(CurLine) > 0) and (CurLine[Length(CurLine)] = #13) then
            SetLength(CurLine, Length(CurLine) - 1);

          if Pos('@@BLAISE_PAYLOAD@@:', CurLine) = 1 then
          begin
            CurPayload := Copy(CurLine, Length('@@BLAISE_PAYLOAD@@:') + 1, MaxInt);
            if Assigned(FOnDisplay) then
              FOnDisplay(RawUtf8(ACellId), RawUtf8(CurPayload));
          end
          else
          begin
            if Assigned(FOnStream) then
              FOnStream(RawUtf8(ACellId), 'stdout', RawUtf8(CurLine));
          end;
        end;
        Break;
      end;
    end;
  end;

begin
  FInterrupted := False;
  FCurrentCellId := ACellId;
  Proc := TProcess.Create(nil);
  FCurrentProcess := Proc;
  try
    Proc.Executable := AExePath;
    Proc.CurrentDirectory := FWorkspaceDir;
    Proc.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    Proc.Execute;

    Accum := '';

    while Proc.Running do
    begin
      while Proc.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
        begin
          SetString(Chunk, PAnsiChar(@Buffer[0]), BytesRead);
          Accum := Accum + Chunk;
          FlushAccum(False);
        end;
      end;
      Sleep(10);
    end;

    // Read all remaining bytes after process exits
    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
      begin
        SetString(Chunk, PAnsiChar(@Buffer[0]), BytesRead);
        Accum := Accum + Chunk;
      end;
    end;

    // Flush any remaining lines, including the last one without newline
    FlushAccum(True);

    ElapsedMs := GetTickCount64() - AStartTick;

    if Assigned(FOnReply) then
    begin
      if FInterrupted then
        FOnReply(RawUtf8(ACellId), 'aborted', AExecCount, ElapsedMs)
      else if Proc.ExitStatus = 0 then
        FOnReply(RawUtf8(ACellId), 'success', AExecCount, ElapsedMs)
      else
        FOnReply(RawUtf8(ACellId), 'error', AExecCount, ElapsedMs);
    end;

  finally
    FCurrentProcess := nil;
    Proc.Free;
  end;
end;

function TCodeRunner.FindFPCExe: string;
var
  EnvFpc, FoundPath: string;
begin
  EnvFpc := Trim(GetEnvironmentVariable('BLAISE_FPC_EXE'));
  if (EnvFpc <> '') and FileExists(EnvFpc) then
    Exit(EnvFpc);

  FoundPath := ExeSearch({$IFDEF WINDOWS}'fpc.exe'{$ELSE}'fpc'{$ENDIF}, GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
    Exit(FoundPath);

  {$IFDEF WINDOWS}
  if FileExists('C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe') then
    Exit('C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe');
  if FileExists('C:\lazarus\fpc\3.2.0\bin\x86_64-win64\fpc.exe') then
    Exit('C:\lazarus\fpc\3.2.0\bin\x86_64-win64\fpc.exe');
  if FileExists('D:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe') then
    Exit('D:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe');
  if FileExists('C:\FPC\3.2.2\bin\i386-win32\fpc.exe') then
    Exit('C:\FPC\3.2.2\bin\i386-win32\fpc.exe');
  {$ELSE}
  if FileExists('/usr/bin/fpc') then
    Exit('/usr/bin/fpc');
  if FileExists('/usr/local/bin/fpc') then
    Exit('/usr/local/bin/fpc');
  if FileExists('/opt/homebrew/bin/fpc') then
    Exit('/opt/homebrew/bin/fpc');
  {$ENDIF}

  Result := 'fpc';
end;

function TCodeRunner.FindPythonExe: string;
const
  PY_VERSIONS: array[1..5] of string = ('Python313', 'Python312', 'Python311', 'Python310', 'Python39');
var
  EnvPy, LocalAppData, ProgFiles, Cand, FoundPath: string;
  i: Integer;
begin
  Result := '';

  // 1. Explicit environment variable override
  EnvPy := Trim(GetEnvironmentVariable('BLAISE_PYTHON_EXE'));
  if (EnvPy <> '') and FileExists(EnvPy) then
    Exit(EnvPy);

  {$IFDEF WINDOWS}
  // 2. Dynamic user LocalAppData & ProgramFiles discovery on Windows (no hardcoded username!)
  LocalAppData := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA'));
  ProgFiles := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('ProgramFiles'));
  for i := Low(PY_VERSIONS) to High(PY_VERSIONS) do
  begin
    if LocalAppData <> '' then
    begin
      Cand := LocalAppData + '\Programs\Python\' + PY_VERSIONS[i] + '\python.exe';
      if FileExists(Cand) then Exit(Cand);
    end;
    if ProgFiles <> '' then
    begin
      Cand := ProgFiles + '\' + PY_VERSIONS[i] + '\python.exe';
      if FileExists(Cand) then Exit(Cand);
    end;
    Cand := 'C:\' + PY_VERSIONS[i] + '\python.exe';
    if FileExists(Cand) then Exit(Cand);
  end;

  FoundPath := ExeSearch('python.exe', GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) and (Pos('WindowsApps', FoundPath) = 0) then
    Exit(FoundPath);

  Result := 'python';
  {$ELSE}
  // 2. Standard Linux / macOS PATH discovery
  FoundPath := ExeSearch('python3', GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
    Exit(FoundPath);

  FoundPath := ExeSearch('python', GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
    Exit(FoundPath);

  if FileExists('/usr/bin/python3') then Exit('/usr/bin/python3');
  if FileExists('/usr/local/bin/python3') then Exit('/usr/local/bin/python3');
  if FileExists('/opt/homebrew/bin/python3') then Exit('/opt/homebrew/bin/python3');

  Result := 'python3';
  {$ENDIF}
end;

function TCodeRunner.IsPipCommand(const ASource: string; out APipArgs: string): Boolean;
var
  Trimmed: string;
begin
  Result := False;
  APipArgs := '';
  Trimmed := Trim(ASource);
  if Trimmed = '' then Exit;

  if (Copy(Trimmed, 1, 5) = '%pip ') or (Copy(Trimmed, 1, 5) = '!pip ') then
  begin
    APipArgs := Trim(Copy(Trimmed, 6, Length(Trimmed) - 5));
    Result := True;
  end
  else if (LowerCase(Trimmed) = '%pip') or (LowerCase(Trimmed) = '!pip') then
  begin
    APipArgs := 'help';
    Result := True;
  end;
end;

procedure TCodeRunner.ExecutePip(const ACellId: string; AExecCount: Integer; const APipArgs: string; AStartTick: Int64);
var
  Proc: TProcess;
  PyExe: string;
  BytesRead: LongInt;
  Buffer: array[0..2047] of Byte;
  Chunk: string;
  ElapsedMs: Integer;
  i: Integer;
  CurArg: string;
  InQuote: Boolean;
  QuoteChar: Char;
  ArgsList: TStringList;
begin
  PyExe := FindPythonExe;
  if PyExe = '' then
  begin
    if Assigned(FOnStream) then
      FOnStream(RawUtf8(ACellId), 'stderr', '[Pip Error] Python interpreter not found.'#10);
    if Assigned(FOnReply) then
      FOnReply(RawUtf8(ACellId), 'error', AExecCount, 0);
    Exit;
  end;

  if Assigned(FOnStream) then
    FOnStream(RawUtf8(ACellId), 'stdout', RawUtf8('[Pip] Executing: python -m pip ' + APipArgs + sLineBreak));

  Proc := TProcess.Create(nil);
  ArgsList := TStringList.Create;
  try
    Proc.Executable := PyExe;
    Proc.Parameters.Add('-m');
    Proc.Parameters.Add('pip');

    // Parse command line arguments preserving quotes
    CurArg := '';
    InQuote := False;
    QuoteChar := #0;
    for i := 1 to Length(APipArgs) do
    begin
      if not InQuote and (APipArgs[i] in ['"', #39]) then
      begin
        InQuote := True;
        QuoteChar := APipArgs[i];
      end
      else if InQuote and (APipArgs[i] = QuoteChar) then
      begin
        InQuote := False;
        QuoteChar := #0;
      end
      else if not InQuote and (APipArgs[i] in [' ', #9, #10, #13]) then
      begin
        if CurArg <> '' then
        begin
          ArgsList.Add(CurArg);
          CurArg := '';
        end;
      end
      else
        CurArg := CurArg + APipArgs[i];
    end;
    if CurArg <> '' then
      ArgsList.Add(CurArg);

    for i := 0 to ArgsList.Count - 1 do
      Proc.Parameters.Add(ArgsList[i]);

    Proc.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    Proc.Execute;

    FCurrentProcess := Proc;
    FCurrentCellId := ACellId;
    FInterrupted := False;

    while Proc.Running do
    begin
      while Proc.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
        if BytesRead > 0 then
        begin
          SetString(Chunk, PAnsiChar(@Buffer[0]), BytesRead);
          if Assigned(FOnStream) then
            FOnStream(RawUtf8(ACellId), 'stdout', RawUtf8(Chunk));
        end;
      end;
      Sleep(10);
    end;

    // Read remaining bytes after exit
    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
      begin
        SetString(Chunk, PAnsiChar(@Buffer[0]), BytesRead);
        if Assigned(FOnStream) then
          FOnStream(RawUtf8(ACellId), 'stdout', RawUtf8(Chunk));
      end;
    end;

    ElapsedMs := GetTickCount64() - AStartTick;

    if Assigned(FOnReply) then
    begin
      if FInterrupted then
        FOnReply(RawUtf8(ACellId), 'aborted', AExecCount, ElapsedMs)
      else if Proc.ExitStatus = 0 then
        FOnReply(RawUtf8(ACellId), 'success', AExecCount, ElapsedMs)
      else
        FOnReply(RawUtf8(ACellId), 'error', AExecCount, ElapsedMs);
    end;
  finally
    FCurrentProcess := nil;
    ArgsList.Free;
    Proc.Free;
  end;
end;

procedure TCodeRunner.ExecuteCell(const ACellId: string; AExecCount: Integer; const ASource: string);
var
  PrgPath, ExePath, Errors: string;
  HashPath, CurrentHash, CachedHash: string;
  StartTick: Int64;
  ElapsedMs: Integer;
  PipArgs: string;
  SafeId: string;
  CacheHit: Boolean;
  SL: TStringList;
begin
  EnsureSessionDaemon;
  StartTick := GetTickCount64();

  // Intercept %pip or !pip magic commands
  if IsPipCommand(ASource, PipArgs) then
  begin
    ExecutePip(ACellId, AExecCount, PipArgs, StartTick);
    Exit;
  end;

  SafeId := ACellId;
  SafeId := StringReplace(SafeId, '-', '_', [rfReplaceAll]);
  SafeId := StringReplace(SafeId, ' ', '_', [rfReplaceAll]);

  ExePath := FWorkspaceDir + DirectorySeparator + 'cell_' + SafeId + {$ifdef WINDOWS}'.exe'{$else}''{$endif};
  HashPath := FWorkspaceDir + DirectorySeparator + 'cell_' + SafeId + '.hash';
  CurrentHash := ComputeSourceHash(ASource);

  // Check compilation cache
  CacheHit := False;
  if FileExists(ExePath) and FileExists(HashPath) then
  begin
    SL := TStringList.Create;
    try
      try
        SL.LoadFromFile(HashPath);
        CachedHash := Trim(SL.Text);
        if (CachedHash <> '') and (CachedHash = CurrentHash) then
          CacheHit := True;
      except
        CacheHit := False;
      end;
    finally
      SL.Free;
    end;
  end;

  if CacheHit then
  begin
    if Assigned(FOnStream) then
      FOnStream(RawUtf8(ACellId), 'stdout', '[Kernel] Code unchanged. Executing cached binary (0ms compilation)...'#10);

    ExecuteBinary(ACellId, ExePath, AExecCount, StartTick);
    Exit;
  end;

  // Cache miss: Prepare source and compile
  if not PrepareSourceFile(ACellId, ASource, PrgPath) then
  begin
    if Assigned(FOnReply) then
      FOnReply(RawUtf8(ACellId), 'error', AExecCount, 0);
    Exit;
  end;

  // Stream notification: Compiling
  if Assigned(FOnStream) then
    FOnStream(RawUtf8(ACellId), 'stdout', '[Kernel] Compiling with Free Pascal (FPC 3.2.2)...'#10);

  if not CompileSource(PrgPath, ExePath, Errors) then
  begin
    if FileExists(HashPath) then
      DeleteFile(HashPath);
    ElapsedMs := GetTickCount64() - StartTick;
    if Assigned(FOnStream) then
      FOnStream(RawUtf8(ACellId), 'stderr', RawUtf8(Errors));
    if Assigned(FOnReply) then
      FOnReply(RawUtf8(ACellId), 'error', AExecCount, ElapsedMs);
    Exit;
  end;

  // Save successful hash to cache file
  SL := TStringList.Create;
  try
    try
      SL.Text := CurrentHash;
      SL.SaveToFile(HashPath);
    except
    end;
  finally
    SL.Free;
  end;

  // Execute the compiled program
  ExecuteBinary(ACellId, ExePath, AExecCount, StartTick);
end;

end.
