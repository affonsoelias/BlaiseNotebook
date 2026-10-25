unit uCodeRunner;

{
  uCodeRunner - Dynamic Free Pascal Compilation & Execution Sandbox
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)
}

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Process, DateUtils,
  mormot.core.base, mormot.core.json, mormot.core.os;

type
  TOnStreamOutput = procedure(const ACellId, AStreamType, AText: RawUtf8) of object;
  TOnDisplayData = procedure(const ACellId, APayloadJson: RawUtf8) of object;
  TOnExecuteReply = procedure(const ACellId, AStatus: RawUtf8; AExecCount, ATimeMs: Integer) of object;

  { TCodeRunner - Compiles and runs Pascal scripts on the fly }
  TCodeRunner = class
  private
    FWorkspaceDir: string;
    FScientificDir: string;
    FPython4LazarusDir: string;
    FPython4LazarusLibDir: string;
    FOnStream: TOnStreamOutput;
    FOnDisplay: TOnDisplayData;
    FOnReply: TOnExecuteReply;
    FCurrentProcess: TProcess;
    FCurrentCellId: string;
    FInterrupted: Boolean;

    function PrepareSourceFile(const ACellId: string; const ASource: string; out APrgPath: string): Boolean;
    function CompileSource(const APrgPath: string; out AExePath: string; out AErrors: string): Boolean;
    procedure ExecuteBinary(const ACellId: string; const AExePath: string; AExecCount: Integer; AStartTick: Int64);
  public
    constructor Create(const AWorkspaceDir: string = '');
    destructor Destroy; override;

    procedure ExecuteCell(const ACellId: string; AExecCount: Integer; const ASource: string);
    procedure Interrupt(const ACellId: string = '');

    property OnStream: TOnStreamOutput read FOnStream write FOnStream;
    property OnDisplay: TOnDisplayData read FOnDisplay write FOnDisplay;
    property OnReply: TOnExecuteReply read FOnReply write FOnReply;
  end;

implementation

{ TCodeRunner }

constructor TCodeRunner.Create(const AWorkspaceDir: string);
begin
  inherited Create;
  if AWorkspaceDir <> '' then
    FWorkspaceDir := AWorkspaceDir
  else
    FWorkspaceDir := ExtractFilePath(ParamStr(0)) + 'workspace';

  ForceDirectories(FWorkspaceDir);

  // Locate scientific/ directory with BlaiseOutput and BlaiseMathKernel
  FScientificDir := ExtractFilePath(ParamStr(0)) + 'scientific';
  if not DirectoryExists(FScientificDir) then
    FScientificDir := ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + 'scientific';
  if not DirectoryExists(FScientificDir) then
    FScientificDir := ExpandFileName('scientific');
  if not DirectoryExists(FScientificDir) then
    FScientificDir := ExpandFileName('frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'scientific');

  // Locate Python4Lazarus package directories
  FPython4LazarusDir := 'C:\Users\Pichau\AppData\Local\lazarus\onlinepackagemanager\packages\PythonForLazarus\python4lazarus';
  FPython4LazarusLibDir := FPython4LazarusDir + DirectorySeparator + 'lib' + DirectorySeparator + 'x86_64-win64';
end;

destructor TCodeRunner.Destroy;
begin
  inherited Destroy;
end;

function TCodeRunner.PrepareSourceFile(const ACellId: string; const ASource: string; out APrgPath: string): Boolean;
var
  CleanSource: string;
  CodeLines: TStringList;
  HasProgramTag: Boolean;
  FinalCode: TStringList;
  SafeId: string;
  FullText: string;
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
      FinalCode.Add('  SysUtils, Math, Classes, BlaiseOutput, BlaiseMathKernel,');
      FinalCode.Add('  PythonEngine, BlaisePyKernel;');
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
  OutputStr: string;
begin
  Result := False;
  AExePath := ChangeFileExt(APrgPath, {$ifdef WINDOWS}'.exe'{$else}''{$endif});
  AErrors := '';

  Proc := TProcess.Create(nil);
  OutStream := TMemoryStream.Create;
  try
    Proc.Executable := 'fpc';
    Proc.Parameters.Add('-Mobjfpc');
    Proc.Parameters.Add('-Sh');
    Proc.Parameters.Add('-O2');
    Proc.Parameters.Add('-FE' + FWorkspaceDir);
    if DirectoryExists(FScientificDir) then
      Proc.Parameters.Add('-Fu' + FScientificDir);
    if DirectoryExists(FPython4LazarusLibDir) then
      Proc.Parameters.Add('-Fu' + FPython4LazarusLibDir);
    if DirectoryExists(FPython4LazarusDir) then
      Proc.Parameters.Add('-Fu' + FPython4LazarusDir);

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

procedure TCodeRunner.ExecuteCell(const ACellId: string; AExecCount: Integer; const ASource: string);
var
  PrgPath, ExePath, Errors: string;
  StartTick: Int64;
  ElapsedMs: Integer;
begin
  StartTick := GetTickCount64();

  if not PrepareSourceFile(ACellId, ASource, PrgPath) then
  begin
    if Assigned(FOnReply) then
      FOnReply(RawUtf8(ACellId), 'error', AExecCount, 0);
    Exit;
  end;

  // Stream notification: Compiling
  if Assigned(FOnStream) then
    FOnStream(RawUtf8(ACellId), 'stdout', '[Kernel] Compilando via Free Pascal (FPC 3.2.2)...'#10);

  if not CompileSource(PrgPath, ExePath, Errors) then
  begin
    ElapsedMs := GetTickCount64() - StartTick;
    if Assigned(FOnStream) then
      FOnStream(RawUtf8(ACellId), 'stderr', RawUtf8(Errors));
    if Assigned(FOnReply) then
      FOnReply(RawUtf8(ACellId), 'error', AExecCount, ElapsedMs);
    Exit;
  end;

  // Execute the compiled program
  ExecuteBinary(ACellId, ExePath, AExecCount, StartTick);
end;

end.
