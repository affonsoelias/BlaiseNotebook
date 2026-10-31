program bvnb;

{
  =====================================================================
   BlaiseNotebook CLI (bvnb) - Diagnostics, Git Auto-Updater & Runner
   Part of BlaiseNotebook Suite (GNU GPL v2 / Modified LGPL v2.1)
  =====================================================================
   Commands:
     bvnb doctor                  Diagnoses environment (Git, FPC, Lazarus, bv, Python, NumPy, Pandas, Sklearn)
     bvnb self-update [--check]   Syncs & recompiles BlaiseNotebook directly from GitHub via Git
     bvnb channel [use <name>]    Inspects or switches repository channel (main | develop)
     bvnb build                   Compiles frontend SPA (bv run build) and native mORMot 2 server (bv mormot build)
     bvnb run                     Starts the native BlaiseNotebook mORMot 2 server
     bvnb setup-python            Installs numpy, pandas, and scikit-learn into the detected Python 3 environment
     bvnb help                    Displays this CLI reference
}

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Process, StrUtils, Sockets;

const
  BVNB_VERSION = '1.0.0';

function ExecCmdCapture(const CmdLine: string; out OutText: string): Boolean;
var
  OutStr: string;
begin
  OutStr := '';
  {$IFDEF WINDOWS}
  Result := RunCommand('cmd.exe', ['/c', CmdLine], OutStr);
  {$ELSE}
  Result := RunCommand('sh', ['-c', CmdLine], OutStr);
  {$ENDIF}
  OutText := Trim(OutStr);
end;

function ExecCmdInteractive(const CmdLine, WorkDir: string): Integer;
var
  Proc: TProcess;
begin
  Result := -1;
  Proc := TProcess.Create(nil);
  try
    if WorkDir <> '' then
      Proc.CurrentDirectory := WorkDir;
    {$IFDEF WINDOWS}
    Proc.Executable := 'cmd.exe';
    Proc.Parameters.Add('/c');
    Proc.Parameters.Add(CmdLine);
    {$ELSE}
    Proc.Executable := 'sh';
    Proc.Parameters.Add('-c');
    Proc.Parameters.Add(CmdLine);
    {$ENDIF}
    Proc.Options := [poWaitOnExit];
    Proc.Execute;
    Result := Proc.ExitStatus;
  finally
    Proc.Free;
  end;
end;

function GetRepoRoot: string;
var
  ExeDir, ParentDir, CurDir: string;
begin
  // 1. Check relative to executable (bin/bvnb.exe -> ../)
  ExeDir := ExcludeTrailingPathDelimiter(ExtractFilePath(ExpandFileName(ParamStr(0))));
  if DirectoryExists(ExeDir + DirectorySeparator + 'frontend') then
    Exit(ExeDir);

  ParentDir := ExcludeTrailingPathDelimiter(ExpandFileName(ExeDir + DirectorySeparator + '..'));
  if DirectoryExists(ParentDir + DirectorySeparator + 'frontend') then
    Exit(ParentDir);

  // 2. Check relative to current working directory
  CurDir := ExcludeTrailingPathDelimiter(GetCurrentDir);
  if DirectoryExists(CurDir + DirectorySeparator + 'frontend') then
    Exit(CurDir);

  ParentDir := ExcludeTrailingPathDelimiter(ExpandFileName(CurDir + DirectorySeparator + '..'));
  if DirectoryExists(ParentDir + DirectorySeparator + 'frontend') then
    Exit(ParentDir);

  Result := ParentDir;
end;

function FindFPCExecutable(out FpcExe, FpcVer, SourceDesc: string): Boolean;
var
  OutStr, Cand, FoundPath: string;
begin
  FpcExe := '';
  FpcVer := '';
  SourceDesc := '';
  Result := False;

  // 1. Try system PATH
  FoundPath := ExeSearch({$IFDEF WINDOWS}'fpc.exe'{$ELSE}'fpc'{$ENDIF}, GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
  begin
    if ExecCmdCapture('"' + FoundPath + '" -iV', OutStr) and (OutStr <> '') then
    begin
      FpcExe := FoundPath;
      FpcVer := Trim(OutStr);
      SourceDesc := 'system PATH (' + FoundPath + ')';
      Exit(True);
    end;
  end;

  // 2. Check standard installations
  {$IFDEF WINDOWS}
  Cand := 'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := 'Lazarus IDE (C:\lazarus\fpc\3.2.2)';
    Exit(True);
  end;

  Cand := 'C:\lazarus\fpc\3.2.0\bin\x86_64-win64\fpc.exe';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := 'Lazarus IDE (C:\lazarus\fpc\3.2.0)';
    Exit(True);
  end;

  Cand := 'D:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := 'Lazarus IDE (D:\lazarus\fpc\3.2.2)';
    Exit(True);
  end;

  Cand := 'C:\FPC\3.2.2\bin\i386-win32\fpc.exe';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := 'FPC Standalone (C:\FPC\3.2.2)';
    Exit(True);
  end;
  {$ELSE}
  Cand := '/usr/bin/fpc';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := '/usr/bin/fpc';
    Exit(True);
  end;

  Cand := '/usr/local/bin/fpc';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := '/usr/local/bin/fpc';
    Exit(True);
  end;

  Cand := '/opt/homebrew/bin/fpc';
  if FileExists(Cand) then
  begin
    FpcExe := Cand;
    if ExecCmdCapture('"' + Cand + '" -iV', OutStr) then FpcVer := Trim(OutStr);
    SourceDesc := 'Homebrew (/opt/homebrew/bin/fpc)';
    Exit(True);
  end;
  {$ENDIF}
end;

function FindPythonExecutable(out PyExe, PyVer, SourceDesc: string): Boolean;
const
  PY_VERSIONS: array[1..5] of string = ('Python313', 'Python312', 'Python311', 'Python310', 'Python39');
var
  EnvPy, LocalAppData, ProgFiles, Cand, FoundPath, OutStr: string;
  i: Integer;
begin
  PyExe := '';
  PyVer := '';
  SourceDesc := '';
  Result := False;

  EnvPy := Trim(GetEnvironmentVariable('BLAISE_PYTHON_EXE'));
  if (EnvPy <> '') and FileExists(EnvPy) then
  begin
    if ExecCmdCapture('"' + EnvPy + '" --version', OutStr) then PyVer := Trim(OutStr);
    PyExe := EnvPy;
    SourceDesc := 'BLAISE_PYTHON_EXE (' + EnvPy + ')';
    Exit(True);
  end;

  {$IFDEF WINDOWS}
  LocalAppData := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA'));
  ProgFiles := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('ProgramFiles'));
  for i := Low(PY_VERSIONS) to High(PY_VERSIONS) do
  begin
    if LocalAppData <> '' then
    begin
      Cand := LocalAppData + '\Programs\Python\' + PY_VERSIONS[i] + '\python.exe';
      if FileExists(Cand) then
      begin
        PyExe := Cand;
        if ExecCmdCapture('"' + Cand + '" --version', OutStr) then PyVer := Trim(OutStr);
        SourceDesc := Cand;
        Exit(True);
      end;
    end;
    if ProgFiles <> '' then
    begin
      Cand := ProgFiles + '\' + PY_VERSIONS[i] + '\python.exe';
      if FileExists(Cand) then
      begin
        PyExe := Cand;
        if ExecCmdCapture('"' + Cand + '" --version', OutStr) then PyVer := Trim(OutStr);
        SourceDesc := Cand;
        Exit(True);
      end;
    end;
  end;

  FoundPath := ExeSearch('python.exe', GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) and (Pos('WindowsApps', FoundPath) = 0) then
  begin
    if ExecCmdCapture('"' + FoundPath + '" --version', OutStr) and (Pos('Python ', OutStr) > 0) then
    begin
      PyExe := FoundPath;
      PyVer := Trim(OutStr);
      SourceDesc := 'system PATH (' + FoundPath + ')';
      Exit(True);
    end;
  end;
  {$ELSE}
  FoundPath := ExeSearch('python3', GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
  begin
    if ExecCmdCapture('"' + FoundPath + '" --version', OutStr) and (Pos('Python ', OutStr) > 0) then
    begin
      PyExe := FoundPath;
      PyVer := Trim(OutStr);
      SourceDesc := 'system PATH (' + FoundPath + ')';
      Exit(True);
    end;
  end;

  FoundPath := ExeSearch('python', GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
  begin
    if ExecCmdCapture('"' + FoundPath + '" --version', OutStr) and (Pos('Python ', OutStr) > 0) then
    begin
      PyExe := FoundPath;
      PyVer := Trim(OutStr);
      SourceDesc := 'system PATH (' + FoundPath + ')';
      Exit(True);
    end;
  end;
  {$ENDIF}
end;

function FindBvExecutable(out BvExe, BvDesc: string): Boolean;
var
  FoundPath, SiblingBv: string;
begin
  BvExe := '';
  BvDesc := '';
  Result := False;

  FoundPath := ExeSearch({$IFDEF WINDOWS}'bv.exe'{$ELSE}'bv'{$ENDIF}, GetEnvironmentVariable('PATH'));
  if (FoundPath <> '') and FileExists(FoundPath) then
  begin
    BvExe := FoundPath;
    BvDesc := 'system PATH (' + FoundPath + ')';
    Exit(True);
  end;

  SiblingBv := ExpandFileName(GetRepoRoot + DirectorySeparator + '..' + DirectorySeparator + 'BlaiseVue' + DirectorySeparator + 'bin' + DirectorySeparator + {$IFDEF WINDOWS}'bv.exe'{$ELSE}'bv'{$ENDIF});
  if FileExists(SiblingBv) then
  begin
    BvExe := SiblingBv;
    BvDesc := SiblingBv;
    Exit(True);
  end;
end;

function CheckPythonModule(const PyExe, ModName: string; out ModVer: string): Boolean;
var
  OutStr: string;
begin
  ModVer := '';
  Result := RunCommand(PyExe, ['-c', 'import ' + ModName + '; print(getattr(' + ModName + ', ''__version__'', ''installed''))'], OutStr)
            and (Trim(OutStr) <> '')
            and (Pos('Traceback', OutStr) = 0)
            and (Pos('ModuleNotFoundError', OutStr) = 0)
            and (Pos('ImportError', OutStr) = 0);
  if Result then
    ModVer := Trim(OutStr);
end;

// =====================================================================
//  1. DOCTOR - ENVIRONMENT DIAGNOSTICS (bvnb doctor)
// =====================================================================

procedure CmdDoctor;
var
  RepoDir, OSName, GitVer, FpcExe, FpcVer, FpcSource, BvExe, BvDesc: string;
  PyExe, PyVer, PySource, ModVer, BranchName, ShortHash, RemoteUrl: string;
  DaemonScript, PackagesDir, ServerBin: string;
  HasGit, HasFpc, HasBv, HasPy, HasLazarus: Boolean;
  HasNumpy, HasPandas, HasSklearn: Boolean;
  AllHealthy: Boolean;
begin
  RepoDir := GetRepoRoot;
  AllHealthy := True;

  {$IFDEF WINDOWS}
  OSName := 'Windows (x86_64)';
  {$ELSE}
    {$IFDEF LINUX}
    OSName := 'Linux (x86_64)';
    {$ELSE}
    OSName := 'macOS (Darwin)';
    {$ENDIF}
  {$ENDIF}

  BranchName := 'Unknown';
  ShortHash := '';
  RemoteUrl := '';
  if DirectoryExists(RepoDir + DirectorySeparator + '.git') then
  begin
    ExecCmdCapture('git -C "' + RepoDir + '" rev-parse --abbrev-ref HEAD', BranchName);
    ExecCmdCapture('git -C "' + RepoDir + '" rev-parse --short HEAD', ShortHash);
    ExecCmdCapture('git -C "' + RepoDir + '" remote get-url origin', RemoteUrl);
  end;

  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  BlaiseNotebook Doctor - Scientific Environment Diagnostics (v' + BVNB_VERSION + ')');
  WriteLn('======================================================================');
  WriteLn('  Operating System:     ', OSName);
  WriteLn('  Project Directory:    ', RepoDir);
  if ShortHash <> '' then
    WriteLn('  Git Channel:          ', BranchName, ' (Commit: ', ShortHash, ')')
  else
    WriteLn('  Git Channel:          Standalone installation');
  if RemoteUrl <> '' then
    WriteLn('  Remote Origin:        ', RemoteUrl);
  WriteLn('');

  // [1] Core Pascal & Framework Tooling
  WriteLn('[1] Core Pascal & BlaiseVue Tooling:');

  HasGit := ExecCmdCapture('git --version', GitVer) and (Pos('git version', GitVer) > 0);
  if HasGit then
    WriteLn('  [v] Git CLI:              ', GitVer, ' detected in PATH')
  else
  begin
    AllHealthy := False;
    WriteLn('  [X] Git CLI:              Not detected in PATH!');
    WriteLn('      -> Install from: https://git-scm.com/');
  end;

  HasFpc := FindFPCExecutable(FpcExe, FpcVer, FpcSource);
  if HasFpc then
    WriteLn('  [v] Free Pascal (FPC):    v', FpcVer, ' (', FpcSource, ')')
  else
  begin
    AllHealthy := False;
    WriteLn('  [X] Free Pascal (FPC):    Not detected!');
    WriteLn('      -> Install Free Pascal or Lazarus IDE: https://www.lazarus-ide.org/');
  end;

  {$IFDEF WINDOWS}
  HasLazarus := FileExists('C:\lazarus\lazarus.exe') or FileExists('C:\lazarus\lazbuild.exe') or (ExeSearch('lazbuild.exe', GetEnvironmentVariable('PATH')) <> '');
  {$ELSE}
  HasLazarus := (ExeSearch('lazarus-ide', GetEnvironmentVariable('PATH')) <> '') or (ExeSearch('lazbuild', GetEnvironmentVariable('PATH')) <> '') or DirectoryExists('/usr/lib/lazarus');
  {$ENDIF}
  if HasLazarus then
    WriteLn('  [v] Lazarus IDE:          Detected (No extra packages required - 100% portable!)')
  else
    WriteLn('  [!] Lazarus IDE:          Not found (Optional - FPC alone compiles everything)');

  HasBv := FindBvExecutable(BvExe, BvDesc);
  if HasBv then
    WriteLn('  [v] BlaiseVue CLI (bv):   Verified at ', BvDesc)
  else
  begin
    AllHealthy := False;
    WriteLn('  [X] BlaiseVue CLI (bv):   Not detected in PATH!');
    WriteLn('      -> Required to transpile .bv components and build mORMot server.');
  end;

  WriteLn('');
  WriteLn('[2] Scientific & AI Runtime (Python Bridge):');

  HasPy := FindPythonExecutable(PyExe, PyVer, PySource);
  if HasPy then
  begin
    WriteLn('  [v] Python 3 Interpreter: ', PyVer, ' (', PySource, ')');

    HasNumpy := CheckPythonModule(PyExe, 'numpy', ModVer);
    if HasNumpy then
      WriteLn('  [v] Package numpy:        v', ModVer)
    else
    begin
      AllHealthy := False;
      WriteLn('  [X] Package numpy:        Not installed! (Run "bvnb setup-python")');
    end;

    HasPandas := CheckPythonModule(PyExe, 'pandas', ModVer);
    if HasPandas then
      WriteLn('  [v] Package pandas:       v', ModVer)
    else
    begin
      AllHealthy := False;
      WriteLn('  [X] Package pandas:       Not installed! (Run "bvnb setup-python")');
    end;

    HasSklearn := CheckPythonModule(PyExe, 'sklearn', ModVer);
    if HasSklearn then
      WriteLn('  [v] Package scikit-learn: v', ModVer)
    else
    begin
      AllHealthy := False;
      WriteLn('  [X] Package scikit-learn: Not installed! (Run "bvnb setup-python")');
    end;
  end
  else
  begin
    AllHealthy := False;
    WriteLn('  [X] Python 3 Interpreter: Not detected!');
    WriteLn('      -> Install Python 3.10+ from: https://www.python.org/');
  end;

  WriteLn('');
  WriteLn('[3] BlaiseNotebook Kernel & Packages Architecture:');

  DaemonScript := RepoDir + DirectorySeparator + 'frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'kernel' + DirectorySeparator + 'blaise_kernel_daemon.py';
  if FileExists(DaemonScript) then
    WriteLn('  [v] Session Daemon:       Verified (frontend/server/kernel/blaise_kernel_daemon.py)')
  else
  begin
    AllHealthy := False;
    WriteLn('  [X] Session Daemon:       Missing at ', DaemonScript);
  end;

  PackagesDir := RepoDir + DirectorySeparator + 'frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'packages';
  if DirectoryExists(PackagesDir) then
    WriteLn('  [v] Scientific Packages:  Verified (core/ + external/math, pandas, sklearn, python_bridge)')
  else
  begin
    AllHealthy := False;
    WriteLn('  [X] Scientific Packages:  Missing at ', PackagesDir);
  end;

  ServerBin := RepoDir + DirectorySeparator + 'frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'bin' + DirectorySeparator + {$IFDEF WINDOWS}'server.exe'{$ELSE}'server'{$ENDIF};
  if FileExists(ServerBin) then
    WriteLn('  [v] Compiled Server:      Ready (frontend/server/bin/', ExtractFileName(ServerBin), ')')
  else
    WriteLn('  [!] Compiled Server:      Not built yet (Run "bvnb build" to compile)');

  WriteLn('');
  WriteLn('======================================================================');
  if AllHealthy then
    WriteLn('  [v] Diagnostics complete: BlaiseNotebook is 100% healthy & portable!')
  else
    WriteLn('  [!] Issues found with required items marked above with [X].');
  WriteLn('======================================================================');
  WriteLn('');
end;

// =====================================================================
//  2. BUILD & RUN COMMANDS (bvnb build | bvnb run | bvnb setup-python)
// =====================================================================

procedure CmdBuild;
var
  RepoDir, FrontendDir, BvExe, BvDesc: string;
  Code: Integer;
begin
  RepoDir := GetRepoRoot;
  FrontendDir := RepoDir + DirectorySeparator + 'frontend';

  if not FindBvExecutable(BvExe, BvDesc) then
  begin
    WriteLn('  [ERROR] BlaiseVue CLI (bv) not found. Ensure "bv" is on your PATH.');
    Halt(1);
  end;

  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  BlaiseNotebook Builder - Full-Stack Compilation');
  WriteLn('======================================================================');
  WriteLn('  [1/2] Building Reactive Frontend SPA (bv run build)...');
  Code := ExecCmdInteractive('"' + BvExe + '" run build', FrontendDir);
  if Code <> 0 then
  begin
    WriteLn('  [ERROR] Frontend SPA compilation failed.');
    Halt(Code);
  end;

  WriteLn('');
  WriteLn('  [2/2] Building Native mORMot 2 Kernel Server (bv mormot build)...');
  Code := ExecCmdInteractive('"' + BvExe + '" mormot build', FrontendDir);
  if Code <> 0 then
  begin
    WriteLn('  [ERROR] Native mORMot 2 server compilation failed.');
    Halt(Code);
  end;

  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  [v] BlaiseNotebook successfully built! Run "bvnb run" to start.');
  WriteLn('======================================================================');
  WriteLn('');
end;

function IsTcpPortAvailable(APort: Word): Boolean;
var
  S: TSocket;
  Addr: TInetSockAddr;
  Res: Integer;
begin
  Result := False;
  S := fpSocket(AF_INET, SOCK_STREAM, 0);
  if S = -1 then Exit;
  try
    FillChar(Addr, SizeOf(Addr), 0);
    Addr.sin_family := AF_INET;
    Addr.sin_port := htons(APort);
    Addr.sin_addr.s_addr := 0; // INADDR_ANY
    Res := fpBind(S, @Addr, SizeOf(Addr));
    Result := (Res = 0);
  finally
    CloseSocket(S);
  end;
end;

function FindNextAvailableTcpPort(StartPort: Word; MaxAttempts: Word = 50): Word;
var
  Candidate: Word;
begin
  Candidate := StartPort;
  while Candidate < StartPort + MaxAttempts do
  begin
    if IsTcpPortAvailable(Candidate) then
      Exit(Candidate);
    Inc(Candidate);
  end;
  Result := StartPort;
end;

procedure CmdKill;
var
  DummyOut: string;
begin
  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  Terminating lingering server instances and releasing locked ports...');
  WriteLn('======================================================================');
  {$IFDEF WINDOWS}
  ExecCmdCapture('taskkill /F /IM server.exe', DummyOut);
  {$ELSE}
  ExecCmdCapture('killall -9 server', DummyOut);
  {$ENDIF}
  WriteLn('  [+] Lingering server.exe processes terminated.');
  WriteLn('  [+] Sockets and ports released.');
  WriteLn('======================================================================');
  WriteLn('');
end;

procedure CmdRun;
var
  RepoDir, FrontendDir, ServerDir, ServerBin, EnvPath, EnvLine, BvExe, BvDesc: string;
  EnvLines: TStringList;
  TargetPort, OrigPort: Word;
  PortArg, ExtraArgs, Url, DummyOut: string;
  i: Integer;
begin
  RepoDir := GetRepoRoot;
  FrontendDir := RepoDir + DirectorySeparator + 'frontend';
  ServerDir := FrontendDir + DirectorySeparator + 'server';
  ServerBin := ServerDir + DirectorySeparator + 'bin' + DirectorySeparator + 'server' + {$IFDEF WINDOWS}'.exe'{$ELSE}''{$ENDIF};

  // 1. Terminate any previous lingering/zombie server instances on Windows/Linux
  {$IFDEF WINDOWS}
  ExecCmdCapture('taskkill /F /IM server.exe', DummyOut);
  {$ELSE}
  ExecCmdCapture('killall -9 server', DummyOut);
  {$ENDIF}

  // 2. Parse command-line port if explicitly requested (e.g. bvnb run --port 8092)
  TargetPort := 8090;
  PortArg := '';
  for i := 2 to ParamCount do
  begin
    if (ParamStr(i) = '--port') or (ParamStr(i) = '-p') then
    begin
      if i + 1 <= ParamCount then
        PortArg := ParamStr(i + 1);
    end
    else if Copy(ParamStr(i), 1, 7) = '--port=' then
      PortArg := Copy(ParamStr(i), 8, MaxInt);
  end;

  if PortArg <> '' then
    TargetPort := StrToIntDef(PortArg, 8090)
  else
  begin
    // Check .env configuration file
    EnvPath := FrontendDir + DirectorySeparator + '.env';
    if FileExists(EnvPath) then
    begin
      EnvLines := TStringList.Create;
      try
        EnvLines.LoadFromFile(EnvPath);
        for i := 0 to EnvLines.Count - 1 do
        begin
          EnvLine := Trim(EnvLines[i]);
          if (EnvLine <> '') and (EnvLine[1] <> '#') and (Pos('PORT=', UpperCase(EnvLine)) = 1) then
          begin
            TargetPort := StrToIntDef(Trim(Copy(EnvLine, 6, MaxInt)), 8090);
            Break;
          end;
        end;
      finally
        EnvLines.Free;
      end;
    end;
  end;

  // 3. Verify TCP socket availability and perform automatic port conflict fallback
  if not IsTcpPortAvailable(TargetPort) then
  begin
    OrigPort := TargetPort;
    TargetPort := FindNextAvailableTcpPort(TargetPort + 1);
    WriteLn('');
    WriteLn('  [!] Notice: Port ' + IntToStr(OrigPort) + ' is busy or locked by a lingering socket.');
    WriteLn('  [+] Automatically switched to available port: ' + IntToStr(TargetPort));
  end;

  Url := 'http://localhost:' + IntToStr(TargetPort);
  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  Starting BlaiseNotebook Native Server...');
  WriteLn('  URL:        ', Url);
  WriteLn('  WebSocket:  ws://localhost:', IntToStr(TargetPort), '/ws');
  WriteLn('======================================================================');
  WriteLn('');

  // 4. Launch browser automatically in the background
  {$IFDEF WINDOWS}
  ExecCmdCapture('start "" "' + Url + '"', DummyOut);
  {$ELSE}
  ExecCmdCapture('xdg-open "' + Url + '" >/dev/null 2>&1 &', DummyOut);
  {$ENDIF}

  // 5. Run native server with selected free port
  ExtraArgs := ' --port ' + IntToStr(TargetPort);
  if FileExists(ServerBin) then
    ExecCmdInteractive('"' + ServerBin + '"' + ExtraArgs, ServerDir)
  else if FindBvExecutable(BvExe, BvDesc) then
    ExecCmdInteractive('"' + BvExe + '" mormot run' + ExtraArgs, FrontendDir)
  else
  begin
    WriteLn('  [ERROR] Server binary not found: ', ServerBin);
    WriteLn('          Compile first using: bvnb build');
    Halt(1);
  end;
end;

procedure CmdSetupPython;
var
  PyExe, PyVer, PySource: string;
  Code: Integer;
begin
  if not FindPythonExecutable(PyExe, PyVer, PySource) then
  begin
    WriteLn('  [ERROR] Python 3 interpreter not found on this machine.');
    WriteLn('          Install Python 3.10+ from https://www.python.org/');
    Halt(1);
  end;

  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  BlaiseNotebook - Python Scientific Stack Installer');
  WriteLn('======================================================================');
  WriteLn('  Python Interpreter: ', PyExe, ' (', PyVer, ')');
  WriteLn('  Installing:         numpy pandas scikit-learn');
  WriteLn('======================================================================');
  WriteLn('');

  Code := ExecCmdInteractive('"' + PyExe + '" -m pip install --upgrade numpy pandas scikit-learn', GetRepoRoot);
  if Code = 0 then
  begin
    WriteLn('');
    WriteLn('  [v] Python scientific packages installed successfully!');
  end
  else
  begin
    WriteLn('');
    WriteLn('  [ERROR] pip installation exited with code ', Code);
    Halt(Code);
  end;
end;

// =====================================================================
//  3. GIT AUTO-UPDATER (bvnb self-update) & CHANNEL MANAGER (bvnb channel)
// =====================================================================

procedure CmdSelfUpdate;
var
  RepoDir, CurBranch, TargetBranch, GitVer, GitStatusOut, FilteredStatus, LineStr, FetchOut: string;
  DiffOut, BehindOut, AheadOut, CheckoutOut, PullOut, FpcExe, FpcVer, FpcSource: string;
  BinDir, CompCmd, CompOut, TargetBin, MoveCmd, DummyOut: string;
  DiffList: TStringList;
  CheckOnly, NeedRecompile, HadLocalBinMod: Boolean;
  i: Integer;
begin
  RepoDir := GetRepoRoot;

  if not (ExecCmdCapture('git --version', GitVer) and (Pos('git version', GitVer) > 0)) then
  begin
    WriteLn('  [ERROR] Git was not detected on this system. Install from https://git-scm.com/');
    Halt(1);
  end;

  if not DirectoryExists(RepoDir + DirectorySeparator + '.git') then
  begin
    WriteLn('  [ERROR] The BlaiseNotebook directory is not a Git repository: ', RepoDir);
    WriteLn('          Clone with: git clone https://github.com/affonsoelias/BlaiseNotebook.git');
    Halt(1);
  end;

  CheckOnly := False;
  TargetBranch := '';

  for i := 2 to ParamCount do
  begin
    if (ParamStr(i) = '--check') or (ParamStr(i) = '-c') then
      CheckOnly := True
    else if Copy(ParamStr(i), 1, 10) = '--channel=' then
      TargetBranch := LowerCase(Trim(Copy(ParamStr(i), 11, MaxInt)))
    else if Copy(ParamStr(i), 1, 9) = '--branch=' then
      TargetBranch := LowerCase(Trim(Copy(ParamStr(i), 10, MaxInt)))
    else if (ParamStr(i) = '-h') or (ParamStr(i) = '--help') then
    begin
      WriteLn('');
      WriteLn('  BlaiseNotebook Git Auto-Updater');
      WriteLn('  Usage: bvnb self-update [options]');
      WriteLn('');
      WriteLn('  Options:');
      WriteLn('    --check              Check for GitHub updates without applying');
      WriteLn('    --channel=<name>     Switch to channel (main | develop)');
      WriteLn('    --branch=<name>      Alias for --channel');
      WriteLn('    -h, --help           Show this help message');
      WriteLn('');
      Halt(0);
    end;
  end;

  ExecCmdCapture('git -C "' + RepoDir + '" rev-parse --abbrev-ref HEAD', CurBranch);
  CurBranch := Trim(CurBranch);
  if TargetBranch = '' then
    TargetBranch := CurBranch;

  if (TargetBranch <> 'main') and (TargetBranch <> 'develop') then
  begin
    WriteLn('  [ERROR] Unknown channel: "', TargetBranch, '". Choose "main" or "develop".');
    Halt(1);
  end;

  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  BlaiseNotebook Auto-Updater (bvnb self-update)');
  WriteLn('======================================================================');
  WriteLn('  Project Root:     ', RepoDir);
  WriteLn('  Current Channel:  ', CurBranch);
  WriteLn('  Target Channel:   ', TargetBranch);
  if CheckOnly then
    WriteLn('  Mode:             CHECK ONLY (--check)')
  else
    WriteLn('  Mode:             SYNC, UPDATE & REBUILD');
  WriteLn('======================================================================');
  WriteLn('');

  // Safety check for uncommitted local changes (ignoring compiled binaries and .env)
  ExecCmdCapture('git -C "' + RepoDir + '" status --porcelain', GitStatusOut);
  FilteredStatus := '';
  HadLocalBinMod := False;
  DiffList := TStringList.Create;
  try
    DiffList.Text := GitStatusOut;
    for i := 0 to DiffList.Count - 1 do
    begin
      LineStr := StringReplace(Trim(DiffList[i]), '\', '/', [rfReplaceAll]);
      if LineStr = '' then Continue;
      if (Pos('bin/bvnb', LineStr) > 0) or
         (Pos('frontend/.env', LineStr) > 0) or
         (Pos('.env', LineStr) > 0) then
      begin
        if Pos('bin/bvnb', LineStr) > 0 then HadLocalBinMod := True;
        Continue;
      end;
      if FilteredStatus <> '' then FilteredStatus := FilteredStatus + LineEnding;
      FilteredStatus := FilteredStatus + DiffList[i];
    end;
  finally
    DiffList.Free;
  end;
  GitStatusOut := FilteredStatus;

  if (Trim(GitStatusOut) <> '') and (not CheckOnly) then
  begin
    WriteLn('  [WARNING] You have uncommitted local changes in the BlaiseNotebook repository:');
    WriteLn(GitStatusOut);
    WriteLn('  Run "git stash" or commit before updating to avoid overwriting your work.');
    Halt(1);
  end;

  WriteLn('  Connecting to GitHub (affonsoelias/BlaiseNotebook)...');
  ExecCmdCapture('git -C "' + RepoDir + '" fetch origin', FetchOut);

  BehindOut := '0';
  AheadOut := '0';
  ExecCmdCapture('git -C "' + RepoDir + '" rev-list --count HEAD..origin/' + TargetBranch, BehindOut);
  ExecCmdCapture('git -C "' + RepoDir + '" rev-list --count origin/' + TargetBranch + '..HEAD', AheadOut);
  BehindOut := Trim(BehindOut);
  AheadOut := Trim(AheadOut);

  if TargetBranch = CurBranch then
  begin
    if (BehindOut = '0') or (BehindOut = '') then
    begin
      WriteLn('  [v] BlaiseNotebook is already up to date with GitHub (' + TargetBranch + ').');
      if (AheadOut <> '0') and (AheadOut <> '') then
        WriteLn('      (Local branch has ' + AheadOut + ' unpushed commit(s) ahead of origin/' + TargetBranch + ')');
      WriteLn('======================================================================');
      WriteLn('');
      Exit;
    end;
    ExecCmdCapture('git -C "' + RepoDir + '" diff --name-only HEAD...origin/' + TargetBranch, DiffOut);
  end
  else
  begin
    ExecCmdCapture('git -C "' + RepoDir + '" diff --name-only HEAD origin/' + TargetBranch, DiffOut);
  end;

  if (BehindOut <> '0') and (BehindOut <> '') then
    WriteLn('  [+] New commits found on GitHub: ', BehindOut);

  WriteLn('  [+] Modified files on GitHub:');
  DiffList := TStringList.Create;
  try
    DiffList.Text := DiffOut;
    for i := 0 to DiffList.Count - 1 do
      if Trim(DiffList[i]) <> '' then
        WriteLn('      * ' + Trim(DiffList[i]));
  finally
    DiffList.Free;
  end;

  if CheckOnly then
  begin
    WriteLn('');
    WriteLn('  [TIP] Run "bvnb self-update" to download, apply, and rebuild.');
    WriteLn('======================================================================');
    WriteLn('');
    Exit;
  end;

  if HadLocalBinMod then
  begin
    BinDir := RepoDir + DirectorySeparator + 'bin';
    {$IFDEF WINDOWS}
    MoveCmd := 'cmd.exe /c cd /d "' + BinDir + '" && move /y bvnb.exe bvnb_old.exe > nul 2>&1';
    ExecCmdCapture(MoveCmd, DummyOut);
    {$ENDIF}
    ExecCmdCapture('git -C "' + RepoDir + '" checkout -- bin/bvnb bin/bvnb.exe bin/bvnb.o', DummyOut);
  end;

  if TargetBranch <> CurBranch then
  begin
    WriteLn('  [+] Switching channel: ' + CurBranch + ' -> ' + TargetBranch + '...');
    ExecCmdCapture('git -C "' + RepoDir + '" checkout ' + TargetBranch, CheckoutOut);
  end;

  WriteLn('  [+] Synchronizing files (git pull origin ' + TargetBranch + ')...');
  ExecCmdCapture('git -C "' + RepoDir + '" pull origin ' + TargetBranch, PullOut);

  NeedRecompile := (TargetBranch <> CurBranch) or (Pos('bin/bvnb.pas', DiffOut) > 0) or (Pos('bin\bvnb.pas', DiffOut) > 0) or HadLocalBinMod;
  if NeedRecompile and FindFPCExecutable(FpcExe, FpcVer, FpcSource) then
  begin
    WriteLn('  [BUILD] Recompiling bvnb CLI binary with Free Pascal...');
    BinDir := RepoDir + DirectorySeparator + 'bin';
    {$IFDEF WINDOWS}
    MoveCmd := 'cmd.exe /c cd /d "' + BinDir + '" && move /y bvnb.exe bvnb_old.exe > nul 2>&1';
    ExecCmdCapture(MoveCmd, DummyOut);
    CompCmd := 'cmd.exe /c cd /d "' + BinDir + '" && "' + FpcExe + '" -MObjFPC -Sh bvnb.pas';
    ExecCmdCapture(CompCmd, CompOut);
    {$ELSE}
    CompCmd := 'sh -c "cd ''' + BinDir + ''' && ''' + FpcExe + ''' -MObjFPC -Sh bvnb.pas && chmod +x bvnb"';
    ExecCmdCapture(CompCmd, CompOut);
    {$ENDIF}
    TargetBin := BinDir + DirectorySeparator + {$IFDEF WINDOWS}'bvnb.exe'{$ELSE}'bvnb'{$ENDIF};
    if FileExists(TargetBin) then
    begin
      WriteLn('  [SUCCESS] CLI binary ' + ExtractFileName(TargetBin) + ' recompiled!');
      {$IFDEF WINDOWS}
      ExecCmdCapture('cmd.exe /c cd /d "' + BinDir + '" && del /f /q bvnb_old.exe > nul 2>&1', DummyOut);
      {$ENDIF}
    end;
  end;

  // Rebuild Frontend + Server after pulling updates
  CmdBuild;

  WriteLn('======================================================================');
  WriteLn('  [v] BlaiseNotebook successfully updated on channel "' + TargetBranch + '"!');
  WriteLn('======================================================================');
  WriteLn('');
end;

procedure CmdChannel;
var
  RepoDir, CurBranch, ShortHash, RemoteUrl, SubCmd, TargetBranch: string;
begin
  RepoDir := GetRepoRoot;

  if not DirectoryExists(RepoDir + DirectorySeparator + '.git') then
  begin
    WriteLn('  [ERROR] The BlaiseNotebook directory is not a Git repository.');
    Halt(1);
  end;

  SubCmd := '';
  if ParamCount >= 2 then
    SubCmd := LowerCase(Trim(ParamStr(2)));

  if (SubCmd = 'use') or (SubCmd = 'switch') then
  begin
    if ParamCount < 3 then
    begin
      WriteLn('Usage: bvnb channel use <main|develop>');
      Halt(1);
    end;
    TargetBranch := LowerCase(Trim(ParamStr(3)));
    if (TargetBranch <> 'main') and (TargetBranch <> 'develop') then
    begin
      WriteLn('  [ERROR] Invalid channel: "', TargetBranch, '". Choose "main" or "develop".');
      Halt(1);
    end;

    WriteLn('Switching to channel "' + TargetBranch + '"...');
    ExecCmdCapture('git -C "' + RepoDir + '" checkout ' + TargetBranch, SubCmd);
    CmdSelfUpdate;
  end
  else
  begin
    ExecCmdCapture('git -C "' + RepoDir + '" rev-parse --abbrev-ref HEAD', CurBranch);
    CurBranch := Trim(CurBranch);
    ExecCmdCapture('git -C "' + RepoDir + '" rev-parse --short HEAD', ShortHash);
    ExecCmdCapture('git -C "' + RepoDir + '" remote get-url origin', RemoteUrl);

    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('  BlaiseNotebook Repository Channels (Git)');
    WriteLn('======================================================================');
    WriteLn('  Repository:       ', RemoteUrl);
    WriteLn('  Project Root:     ', RepoDir);
    WriteLn('');
    WriteLn('  Available Channels:');
    if CurBranch = 'main' then
    begin
      WriteLn('    * main       [ACTIVE] Stable release channel (End user / Production)');
      WriteLn('      develop    [Available] Development channel (Contributors / Bleeding-edge)');
    end
    else if CurBranch = 'develop' then
    begin
      WriteLn('      main       [Available] Stable release channel (End user / Production)');
      WriteLn('    * develop    [ACTIVE] Development channel (Contributors / Bleeding-edge)');
    end
    else
    begin
      WriteLn('    * ' + CurBranch + ' [ACTIVE - Custom]');
      WriteLn('      main       [Available] Stable release channel');
      WriteLn('      develop    [Available] Development channel');
    end;
    WriteLn('');
    WriteLn('  Current Commit:   ', ShortHash, ' (on ', CurBranch, ')');
    WriteLn('');
    WriteLn('  Commands:');
    WriteLn('    bvnb channel use main       Switch to stable release channel');
    WriteLn('    bvnb channel use develop    Switch to development channel');
    WriteLn('    bvnb self-update --check    Check if updates are available on GitHub');
    WriteLn('======================================================================');
    WriteLn('');
  end;
end;

procedure ShowHelp;
begin
  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  BlaiseNotebook CLI (bvnb v' + BVNB_VERSION + ') - Scientific Computing in Pascal');
  WriteLn('======================================================================');
  WriteLn('  Usage: bvnb <command> [options]');
  WriteLn('');
  WriteLn('  # === Diagnostics & Git Auto-Updater ===');
  WriteLn('  bvnb doctor                  Diagnoses environment (Git, FPC, bv, Python, NumPy, Pandas, Sklearn)');
  WriteLn('  bvnb self-update [--check]   Syncs & rebuilds BlaiseNotebook directly from GitHub via Git');
  WriteLn('  bvnb channel [use <name>]    Inspects or switches repository branch (main | develop)');
  WriteLn('');
  WriteLn('  # === Build, Execution & Process Management ===');
  WriteLn('  bvnb build                   Compiles Frontend SPA + Native mORMot 2 Server');
  WriteLn('  bvnb run [--port <port>]     Starts BlaiseNotebook with smart port auto-fallback & browser');
  WriteLn('  bvnb kill                    Terminates lingering server instances and frees locked ports');
  WriteLn('  bvnb setup-python            Installs numpy, pandas, and scikit-learn via pip');
  WriteLn('  bvnb help                    Displays this help overview');
  WriteLn('======================================================================');
  WriteLn('');
end;

var
  Cmd: string;
begin
  if ParamCount = 0 then
  begin
    ShowHelp;
    Halt(0);
  end;

  Cmd := LowerCase(Trim(ParamStr(1)));
  if (Cmd = 'doctor') or (Cmd = 'doc-env') then
    CmdDoctor
  else if (Cmd = 'self-update') or (Cmd = 'selfupdate') or (Cmd = 'update') or (Cmd = 'upgrade') then
    CmdSelfUpdate
  else if (Cmd = 'channel') or (Cmd = 'branch') then
    CmdChannel
  else if (Cmd = 'build') or (Cmd = 'compile') then
    CmdBuild
  else if (Cmd = 'run') or (Cmd = 'start') or (Cmd = 'serve') then
    CmdRun
  else if (Cmd = 'kill') or (Cmd = 'stop') then
    CmdKill
  else if (Cmd = 'setup-python') or (Cmd = 'pip-setup') or (Cmd = 'install-python') then
    CmdSetupPython
  else
    ShowHelp;
end.
