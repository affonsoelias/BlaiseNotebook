program bvnb;

{
  =====================================================================
   BlaiseNotebook CLI (bvnb) - Diagnostics, Git Auto-Updater & Runner
   Part of BlaiseNotebook Suite (GNU GPL v2 / Modified LGPL v2.1)
  =====================================================================
   Commands:
     bvnb doctor                  Diagnoses environment (Git, FPC, Lazarus, bv, Python, NumPy, Pandas, Sklearn)
     bvnb self-update [--check]   Syncs & recompiles BlaiseNotebook directly from GitHub via Git (--force supported)
     bvnb channel [use <name>]    Inspects or switches repository channel (main | develop)
     bvnb rollback                Restores previous working CLI binary from persistent backup
     bvnb pkg <list|search|...>   Manages official and community packages / tools
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

  // macOS Homebrew & standard Linux fallbacks
  Cand := '/opt/homebrew/bin/python3';
  if FileExists(Cand) then
  begin
    if ExecCmdCapture('"' + Cand + '" --version', OutStr) and (Pos('Python ', OutStr) > 0) then
    begin
      PyExe := Cand;
      PyVer := Trim(OutStr);
      SourceDesc := 'Homebrew (' + Cand + ')';
      Exit(True);
    end;
  end;

  Cand := '/usr/local/bin/python3';
  if FileExists(Cand) then
  begin
    if ExecCmdCapture('"' + Cand + '" --version', OutStr) and (Pos('Python ', OutStr) > 0) then
    begin
      PyExe := Cand;
      PyVer := Trim(OutStr);
      SourceDesc := '/usr/local/bin/python3';
      Exit(True);
    end;
  end;

  Cand := '/usr/bin/python3';
  if FileExists(Cand) then
  begin
    if ExecCmdCapture('"' + Cand + '" --version', OutStr) and (Pos('Python ', OutStr) > 0) then
    begin
      PyExe := Cand;
      PyVer := Trim(OutStr);
      SourceDesc := '/usr/bin/python3';
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


function PadRight(const S: string; const Len: Integer): string;
begin
  Result := S;
  while Length(Result) < Len do
    Result := Result + ' ';
end;

function ReadPackageJsonField(const AFilePath, AField: string): string;
var
  Lines: TStringList;
  i, p: Integer;
  Line, Key: string;
begin
  Result := '';
  if not FileExists(AFilePath) then Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFilePath);
    Key := '"' + LowerCase(AField) + '"';
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];
      p := Pos(Key, LowerCase(Line));
      if p > 0 then
      begin
        p := Pos(':', Line);
        if p > 0 then
        begin
          Line := Trim(Copy(Line, p + 1, MaxInt));
          if (Length(Line) > 0) and (Line[Length(Line)] = ',') then
            SetLength(Line, Length(Line) - 1);
          Line := Trim(Line);
          if (Length(Line) >= 2) and (Line[1] = '"') and (Line[Length(Line)] = '"') then
            Line := Copy(Line, 2, Length(Line) - 2);
          Result := Trim(Line);
          Exit;
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function DeleteDirRecursive(const ADir: string): Boolean;
var
  SR: TSearchRec;
  Path: string;
begin
  Result := True;
  Path := IncludeTrailingPathDelimiter(ADir);
  if FindFirst(Path + '*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          if (SR.Attr and faDirectory) <> 0 then
            DeleteDirRecursive(Path + SR.Name)
          else
            DeleteFile(Path + SR.Name);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
  RemoveDir(ADir);
end;

function CopyFileSimple(const Src, Dst: string): Boolean;
var
  SrcStream, DstStream: TFileStream;
begin
  Result := False;
  try
    SrcStream := TFileStream.Create(Src, fmOpenRead or fmShareDenyWrite);
    try
      DstStream := TFileStream.Create(Dst, fmCreate);
      try
        DstStream.CopyFrom(SrcStream, SrcStream.Size);
        Result := True;
      finally
        DstStream.Free;
      end;
    finally
      SrcStream.Free;
    end;
  except
    Result := False;
  end;
end;

function CopyDirectory(const SrcDir, DstDir: string): Boolean;
var
  SR: TSearchRec;
  SrcPath, DstPath: string;
begin
  Result := True;
  SrcPath := IncludeTrailingPathDelimiter(SrcDir);
  DstPath := IncludeTrailingPathDelimiter(DstDir);
  ForceDirectories(DstPath);

  if FindFirst(SrcPath + '*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          if (SR.Attr and faDirectory) <> 0 then
            CopyDirectory(SrcPath + SR.Name, DstPath + SR.Name)
          else
            CopyFileSimple(SrcPath + SR.Name, DstPath + SR.Name);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
end;

function FindLocalEcosystemRepo: string;
var
  Candidate: string;
begin
  Result := '';
  // 1. Sibling directory to BlaiseNotebook repo (works across Windows, Linux, macOS)
  Candidate := ExpandFileName(GetRepoRoot + DirectorySeparator + '..' + DirectorySeparator + 'blaiseNotebook-ecosystem');
  if DirectoryExists(Candidate) and FileExists(Candidate + DirectorySeparator + 'ecosystem.json') then
    Exit(Candidate);

  // 2. User's Documents/blaiseNotebook-ecosystem directory (cross-platform via GetUserDir)
  Candidate := ExcludeTrailingPathDelimiter(GetUserDir) + DirectorySeparator + 'Documents' + DirectorySeparator + 'blaiseNotebook-ecosystem';
  if DirectoryExists(Candidate) and FileExists(Candidate + DirectorySeparator + 'ecosystem.json') then
    Exit(Candidate);

  // 3. User home directory ~/blaiseNotebook-ecosystem
  Candidate := ExcludeTrailingPathDelimiter(GetUserDir) + DirectorySeparator + 'blaiseNotebook-ecosystem';
  if DirectoryExists(Candidate) and FileExists(Candidate + DirectorySeparator + 'ecosystem.json') then
    Exit(Candidate);

  // 4. Windows default dev environment fallback
  {$IFDEF WINDOWS}
  Candidate := 'C:' + DirectorySeparator + 'Users' + DirectorySeparator + 'Pichau' + DirectorySeparator + 'Documents' + DirectorySeparator + 'blaiseNotebook-ecosystem';
  if DirectoryExists(Candidate) and FileExists(Candidate + DirectorySeparator + 'ecosystem.json') then
    Exit(Candidate);
  {$ENDIF}
end;

function IsReservedPackageName(const AName: string): Boolean;
var
  L: string;
begin
  L := LowerCase(Trim(AName));
  if (Length(L) > 0) and (L[1] = '@') then
    L := Copy(L, 2, MaxInt);

  // 1. Official prefixes
  if (Pos('bvnb-', L) = 1) or (Pos('blaise-', L) = 1) then
    Exit(True);

  // 2. Reserved core, scientific, and tool aliases
  Result := (L = 'core') or (L = 'math') or (L = 'pandas') or (L = 'sklearn') or
            (L = 'datascience') or (L = 'python_bridge') or (L = 'bridge') or
            (L = 'python') or (L = 'tools') or (L = 'data_generator') or
            (L = 'sdk') or (L = 'kernel') or (L = 'runtime') or (L = 'std') or
            (L = 'bvnb');
end;

function ResolveCanonicalPackageName(const AName: string): string;
var
  L: string;
begin
  L := LowerCase(Trim(AName));
  if (L = 'core') or (L = 'blaise-core') or (L = 'bvnb-core') then
    Result := 'bvnb-core'
  else if (L = 'math') or (L = 'blaise-math') or (L = 'bvnb-math') then
    Result := 'bvnb-math'
  else if (L = 'pandas') or (L = 'blaise-pandas') or (L = 'bvnb-pandas') then
    Result := 'bvnb-pandas'
  else if (L = 'sklearn') or (L = 'blaise-sklearn') or (L = 'bvnb-sklearn') then
    Result := 'bvnb-sklearn'
  else if (L = 'datascience') or (L = 'blaise-datascience') or (L = 'bvnb-datascience') then
    Result := 'bvnb-datascience'
  else if (L = 'python_bridge') or (L = 'bridge') or (L = 'blaise-python-bridge') or (L = 'bvnb-python-bridge') then
    Result := 'bvnb-python-bridge'
  else if (L = 'data_generator') or (L = 'generator') or (L = 'bvnb-tool-data-generator') then
    Result := 'bvnb-tool-data-generator'
  else if (L = '_template') or (L = 'bvnb-tool-template') or (L = 'tool_template') then
    Result := 'bvnb-tool-template'
  else
    Result := AName;
end;

function IsOfficialBuiltinPackage(const AName: string; out ACategory, AUnitName: string): Boolean;
var
  Canonical: string;
begin
  Result := False;
  ACategory := '';
  AUnitName := '';
  Canonical := ResolveCanonicalPackageName(AName);

  if Canonical = 'bvnb-core' then
  begin
    ACategory := 'Official Core System (frontend/server/packages/core)';
    AUnitName := 'BlaiseOutput.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-math' then
  begin
    ACategory := 'Official Scientific Package (frontend/server/packages/external/bvnb-math)';
    AUnitName := 'BlaiseMathKernel.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-pandas' then
  begin
    ACategory := 'Official Scientific Package (frontend/server/packages/external/bvnb-pandas)';
    AUnitName := 'BlaisePandas.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-sklearn' then
  begin
    ACategory := 'Official Scientific Package (frontend/server/packages/external/bvnb-sklearn)';
    AUnitName := 'BlaiseSklearn.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-datascience' then
  begin
    ACategory := 'Official Scientific Package (frontend/server/packages/external/bvnb-datascience)';
    AUnitName := 'BlaiseDataScience.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-python-bridge' then
  begin
    ACategory := 'Official Scientific Package (frontend/server/packages/external/bvnb-python-bridge)';
    AUnitName := 'BlaisePyKernel.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-tool-data-generator' then
  begin
    ACategory := 'Official Auxiliary Tool (frontend/server/packages/tools/bvnb-tool-data-generator)';
    AUnitName := 'uDataGenerator.pas';
    Result := True;
  end
  else if Canonical = 'bvnb-tool-template' then
  begin
    ACategory := 'Official Tool Template (frontend/server/packages/tools/_template)';
    AUnitName := 'uToolTemplate.pas';
    Result := True;
  end;
end;

function GetShortAlias(const ACanonical: string): string;
var
  L: string;
begin
  L := LowerCase(Trim(ACanonical));
  if L = 'bvnb-core' then Result := 'core'
  else if L = 'bvnb-math' then Result := 'math'
  else if L = 'bvnb-pandas' then Result := 'pandas'
  else if L = 'bvnb-sklearn' then Result := 'sklearn'
  else if L = 'bvnb-datascience' then Result := 'datascience'
  else if L = 'bvnb-python-bridge' then Result := 'python_bridge'
  else if L = 'bvnb-tool-data-generator' then Result := 'data_generator'
  else if L = 'bvnb-tool-template' then Result := '_template'
  else Result := '';
end;

// =====================================================================
//  PACKAGE & EXTENSIONS MANAGER (bvnb pkg)
// =====================================================================

procedure CmdPackage;
var
  SubCmd, PkgArg, PkgName, PkgVer, RepoDir, PackagesDir, CoreDir, ExtDir, ToolsDir, UserPkgDir: string;
  LocalEcoRepo, LocalEcoPkg, ManifestFile, PkgDesc, MainUnit, UnitName, TemplateDir, DestDir: string;
  EcoJsonFile, EcoContent, TarCmd, DummyOut, PyExe, PyVer, PySource: string;
  Lines, ManifestLines: TStringList;
  IsTool, FoundAny: Boolean;
  p, i: Integer;
  SR: TSearchRec;

  procedure ListDirPackages(const ATitle, ABaseDir: string);
  var
    SR: TSearchRec;
    ItemDir, MFile, MName, MVer, MDesc, MUnit: string;
    Count: Integer;
  begin
    WriteLn('  --- ' + ATitle + ' ---');
    if not DirectoryExists(ABaseDir) then
    begin
      WriteLn('      (Directory not found: ' + ExtractRelativePath(GetCurrentDir + DirectorySeparator, ABaseDir) + ')');
      WriteLn('');
      Exit;
    end;
    Count := 0;
    MFile := IncludeTrailingPathDelimiter(ABaseDir) + 'package.json';
    if FileExists(MFile) then
    begin
      MName := ReadPackageJsonField(MFile, 'name');
      if MName = '' then MName := ExtractFileName(ExcludeTrailingPathDelimiter(ABaseDir));
      MVer := ReadPackageJsonField(MFile, 'version');
      if MVer = '' then MVer := '1.0.0';
      MDesc := ReadPackageJsonField(MFile, 'description');
      MUnit := ReadPackageJsonField(MFile, 'main');
      Write('    * ' + PadRight(MName, 26) + ' [v' + MVer + ']');
      if MUnit <> '' then
        Write(' (Unit: ' + MUnit + ')');
      WriteLn('');
      if MDesc <> '' then
        WriteLn('        ' + MDesc);
      Inc(Count);
    end;

    if FindFirst(IncludeTrailingPathDelimiter(ABaseDir) + '*', faAnyFile, SR) = 0 then
    begin
      try
        repeat
          if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and (SR.Name <> '..') and (SR.Name[1] <> '.') then
          begin
            ItemDir := IncludeTrailingPathDelimiter(ABaseDir) + SR.Name;
            MFile := ItemDir + DirectorySeparator + 'package.json';
            MName := ReadPackageJsonField(MFile, 'name');
            if MName = '' then MName := SR.Name;
            MVer := ReadPackageJsonField(MFile, 'version');
            if MVer = '' then MVer := '1.0.0';
            MDesc := ReadPackageJsonField(MFile, 'description');
            MUnit := ReadPackageJsonField(MFile, 'main');
            if MUnit = '' then MUnit := SR.Name + '.pas';

            Write('    * ' + PadRight(MName, 26) + ' [v' + MVer + ']');
            if MUnit <> '' then
              Write(' (Unit: ' + MUnit + ')');
            if GetShortAlias(MName) <> '' then
              Write(' [alias: ' + GetShortAlias(MName) + ']')
            else if (MName <> SR.Name) and (Pos('bvnb-', MName) = 1) then
              Write(' [alias: ' + SR.Name + ']');
            WriteLn('');
            if MDesc <> '' then
              WriteLn('        ' + MDesc);
            Inc(Count);
          end;
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
    end;
    if Count = 0 then
      WriteLn('      (No packages found)');
    WriteLn('');
  end;

begin
  RepoDir := GetRepoRoot;
  PackagesDir := RepoDir + DirectorySeparator + 'frontend' + DirectorySeparator + 'server' + DirectorySeparator + 'packages';
  CoreDir := PackagesDir + DirectorySeparator + 'core';
  ExtDir := PackagesDir + DirectorySeparator + 'external';
  ToolsDir := PackagesDir + DirectorySeparator + 'tools';
  UserPkgDir := GetCurrentDir + DirectorySeparator + 'packages';

  SubCmd := '';
  PkgArg := '';
  if ParamCount >= 2 then
    SubCmd := LowerCase(Trim(ParamStr(2)));
  if ParamCount >= 3 then
    PkgArg := Trim(ParamStr(3));

  if (SubCmd = 'list') or (SubCmd = 'ls') or (SubCmd = '') then
  begin
    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('  BlaiseNotebook Packages & Tools Registry');
    WriteLn('======================================================================');
    WriteLn('  Workspace Dir:  ', GetCurrentDir);
    WriteLn('  Official Dir:   ', PackagesDir);
    WriteLn('======================================================================');
    WriteLn('');

    ListDirPackages('Official Core System (frontend/server/packages/core)', CoreDir);
    ListDirPackages('Official Scientific Packages (frontend/server/packages/external)', ExtDir);
    ListDirPackages('Official Auxiliary Tools (frontend/server/packages/tools)', ToolsDir);
    ListDirPackages('Workspace Third-Party Packages (./packages/)', UserPkgDir);

    WriteLn('======================================================================');
    WriteLn('  Tips:');
    WriteLn('    bvnb pkg search [query]       Search community registry packages');
    WriteLn('    bvnb pkg install <name>       Install package into ./packages/');
    WriteLn('    bvnb pkg create <name>        Scaffold new package in ./packages/');
    WriteLn('    bvnb pkg create <name> --tool Scaffold official tool in packages/tools/');
    WriteLn('    bvnb pkg remove <name>        Remove third-party package from ./packages/');
    WriteLn('======================================================================');
    WriteLn('');
    Exit;
  end;

  if (SubCmd = 'search') or (SubCmd = 'find') then
  begin
    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('  BlaiseNotebook Ecosystem Registry Search');
    WriteLn('======================================================================');
    if PkgArg <> '' then
      WriteLn('  Search Query:   "', PkgArg, '"')
    else
      WriteLn('  Listing all available ecosystem packages');
    WriteLn('======================================================================');
    WriteLn('');

    // Check local ecosystem repository first (Windows, Linux, macOS)
    LocalEcoRepo := FindLocalEcosystemRepo;
    if LocalEcoRepo <> '' then
      EcoJsonFile := LocalEcoRepo + DirectorySeparator + 'ecosystem.json'
    else
      EcoJsonFile := '';

    FoundAny := False;
    if FileExists(EcoJsonFile) then
    begin
      WriteLn('  [+] Connected to local ecosystem registry: ' + LocalEcoRepo);
      WriteLn('');
      // Scan packages directory in blaiseNotebook-ecosystem
      if DirectoryExists(LocalEcoRepo + DirectorySeparator + 'packages') then
      begin
        Lines := TStringList.Create;
        try
          if FindFirst(LocalEcoRepo + DirectorySeparator + 'packages' + DirectorySeparator + '*', faAnyFile, SR) = 0 then
          begin
            repeat
              if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and (SR.Name <> '..') and (SR.Name <> '_template') then
              begin
                if (PkgArg = '') or (Pos(LowerCase(PkgArg), LowerCase(SR.Name)) > 0) then
                begin
                  ManifestFile := LocalEcoRepo + DirectorySeparator + 'packages' + DirectorySeparator + SR.Name + DirectorySeparator + 'package.json';
                  PkgVer := ReadPackageJsonField(ManifestFile, 'version');
                  if PkgVer = '' then PkgVer := '1.0.0';
                  PkgDesc := ReadPackageJsonField(ManifestFile, 'description');

                  Write('    * ' + PadRight(SR.Name, 22) + ' [v' + PkgVer + ']');
                  if DirectoryExists(UserPkgDir + DirectorySeparator + SR.Name) then
                    Write('  [INSTALLED IN WORKSPACE]')
                  else
                    Write('  [AVAILABLE]');
                  WriteLn('');
                  if PkgDesc <> '' then
                    WriteLn('        ' + PkgDesc);
                  FoundAny := True;
                end;
              end;
            until FindNext(SR) <> 0;
            FindClose(SR);
          end;
        finally
          Lines.Free;
        end;
      end;
    end
    else
    begin
      WriteLn('  [INFO] Querying online GitHub registry (affonsoelias/blaiseNotebook-ecosystem)...');
      ExecCmdCapture('curl -s https://raw.githubusercontent.com/affonsoelias/blaiseNotebook-ecosystem/main/ecosystem.json', EcoContent);
      if Pos('"packages"', EcoContent) > 0 then
      begin
        WriteLn('  [v] Registry online catalog reachable.');
        FoundAny := True;
      end
      else
        WriteLn('  [!] Remote registry currently offline or initializing.');
    end;

    if not FoundAny then
    begin
      WriteLn('    No packages matching "' + PkgArg + '" were found.');
      WriteLn('    Submit your package at: https://github.com/affonsoelias/blaiseNotebook-ecosystem');
    end;

    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('');
    Exit;
  end;

  if (SubCmd = 'install') or (SubCmd = 'add') or (SubCmd = 'i') then
  begin
    if PkgArg = '' then
    begin
      WriteLn('Usage: bvnb pkg install <package-name>[@version]');
      Halt(1);
    end;

    p := Pos('@', PkgArg);
    if p > 0 then
    begin
      PkgName := Copy(PkgArg, 1, p - 1);
      PkgVer := Copy(PkgArg, p + 1, MaxInt);
    end
    else
    begin
      PkgName := PkgArg;
      PkgVer := 'latest';
    end;

    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('  BlaiseNotebook Package Installer (bvnb pkg install)');
    WriteLn('======================================================================');
    WriteLn('  Target Package: ', PkgName, ' (', PkgVer, ')');
    WriteLn('  Install Path:   ', UserPkgDir + DirectorySeparator + PkgName);
    WriteLn('======================================================================');
    WriteLn('');

    // Security & Namespace Protection: Block installing official built-in packages in ./packages/
    if IsOfficialBuiltinPackage(PkgName, PkgDesc, MainUnit) then
    begin
      WriteLn('  [INFO] "' + ResolveCanonicalPackageName(PkgName) + '" is already an official built-in component:');
      WriteLn('         Category: ' + PkgDesc);
      WriteLn('         Unit:     ' + MainUnit);
      WriteLn('');
      WriteLn('         It is permanently included and ready to use in your notebooks:');
      WriteLn('           uses');
      WriteLn('             BlaiseOutput,');
      WriteLn('             ' + ChangeFileExt(MainUnit, '') + ';');
      WriteLn('');
      WriteLn('         Installation into ./packages/ blocked to prevent namespace shadowing.');
      WriteLn('======================================================================');
      WriteLn('');
      Exit;
    end;

    ForceDirectories(UserPkgDir);
    DestDir := UserPkgDir + DirectorySeparator + PkgName;

    // Check local ecosystem repository first (Windows, Linux, macOS)
    LocalEcoRepo := FindLocalEcosystemRepo;
    if LocalEcoRepo <> '' then
      LocalEcoPkg := LocalEcoRepo + DirectorySeparator + 'packages' + DirectorySeparator + PkgName
    else
      LocalEcoPkg := '';

    if DirectoryExists(LocalEcoPkg) then
    begin
      WriteLn('  [+] Installing package from local ecosystem: ' + LocalEcoPkg + '...');
      if DirectoryExists(DestDir) then
        DeleteDirRecursive(DestDir);
      CopyDirectory(LocalEcoPkg, DestDir);
    end
    else
    begin
      WriteLn('  [+] Fetching package from GitHub releases (affonsoelias/blaiseNotebook-ecosystem)...');
      DummyOut := '';
      ExecCmdCapture('curl -s -L "https://github.com/affonsoelias/blaiseNotebook-ecosystem/releases/download/' + PkgName + '-' + PkgVer + '/' + PkgName + '-' + PkgVer + '.zip" -o "' + UserPkgDir + DirectorySeparator + PkgName + '.zip"', DummyOut);
      if FileExists(UserPkgDir + DirectorySeparator + PkgName + '.zip') then
      begin
        {$IFDEF WINDOWS}
        ExecCmdCapture('tar -xf "' + UserPkgDir + DirectorySeparator + PkgName + '.zip" -C "' + DestDir + '"', DummyOut);
        {$ELSE}
        ExecCmdCapture('unzip -q -o "' + UserPkgDir + DirectorySeparator + PkgName + '.zip" -d "' + DestDir + '"', DummyOut);
        {$ENDIF}
        DeleteFile(UserPkgDir + DirectorySeparator + PkgName + '.zip');
      end
      else
      begin
        WriteLn('  [ERROR] Package "' + PkgName + '" not found in ecosystem registry.');
        WriteLn('          Verify package name with: bvnb pkg search');
        Halt(1);
      end;
    end;

    if DirectoryExists(DestDir) then
    begin
      WriteLn('  [SUCCESS] Package "' + PkgName + '" installed successfully in ./packages/' + PkgName + '!');

      // Check if requirements.txt exists and install python dependencies
      if FileExists(DestDir + DirectorySeparator + 'requirements.txt') then
      begin
        WriteLn('');
        WriteLn('  [+] Detected Python requirements.txt. Installing dependencies via pip...');
        if FindPythonExecutable(PyExe, PyVer, PySource) then
        begin
          ExecCmdInteractive('"' + PyExe + '" -m pip install -r "' + DestDir + DirectorySeparator + 'requirements.txt"', GetCurrentDir);
        end
        else
          WriteLn('  [WARNING] Python executable not found. Run "bvnb setup-python" after setup.');
      end;

      ManifestFile := DestDir + DirectorySeparator + 'package.json';
      MainUnit := ReadPackageJsonField(ManifestFile, 'main');
      if MainUnit = '' then MainUnit := PkgName + '.pas';
      UnitName := ChangeFileExt(MainUnit, '');

      WriteLn('');
      WriteLn('  Ready to use inside your notebook code cells:');
      WriteLn('    uses');
      WriteLn('      BlaiseOutput,');
      WriteLn('      ' + UnitName + ';');
      WriteLn('');
      WriteLn('======================================================================');
      WriteLn('');
    end;
    Exit;
  end;

  if (SubCmd = 'remove') or (SubCmd = 'uninstall') or (SubCmd = 'rm') then
  begin
    if PkgArg = '' then
    begin
      WriteLn('Usage: bvnb pkg remove <package-name>');
      Halt(1);
    end;

    // Safety: Protect official packages
    if (LowerCase(PkgArg) = 'core') or (LowerCase(PkgArg) = 'math') or
       (LowerCase(PkgArg) = 'pandas') or (LowerCase(PkgArg) = 'sklearn') or
       (LowerCase(PkgArg) = 'python_bridge') or (LowerCase(PkgArg) = 'data_generator') then
    begin
      WriteLn('  [ERROR] "' + PkgArg + '" is a protected official BlaiseNotebook package/tool.');
      WriteLn('          Official packages cannot be removed with "bvnb pkg remove".');
      Halt(1);
    end;

    DestDir := UserPkgDir + DirectorySeparator + PkgArg;
    if not DirectoryExists(DestDir) then
    begin
      WriteLn('  [ERROR] Package "' + PkgArg + '" is not installed in ./packages/');
      Halt(1);
    end;

    WriteLn('  [+] Removing package ./packages/' + PkgArg + '...');
    DeleteDirRecursive(DestDir);
    WriteLn('  [SUCCESS] Package "' + PkgArg + '" removed successfully.');
    Exit;
  end;

  if (SubCmd = 'create') or (SubCmd = 'new') then
  begin
    if PkgArg = '' then
    begin
      WriteLn('Usage: bvnb pkg create <package-name> [--tool]');
      Halt(1);
    end;

    IsTool := False;
    for i := 3 to ParamCount do
      if (ParamStr(i) = '--tool') or (ParamStr(i) = '-t') then
        IsTool := True;

    // Security & Namespace Reservation Check
    if (not IsTool) and IsReservedPackageName(PkgArg) then
    begin
      WriteLn('');
      WriteLn('  [ERROR] Cannot create third-party package with reserved name: "' + PkgArg + '"');
      WriteLn('          Names starting with "bvnb-", "blaise-", or matching official components');
      WriteLn('          (core, math, pandas, sklearn, datascience, python_bridge, data_generator, tools, sdk)');
      WriteLn('          are strictly reserved for the official BlaiseNotebook distribution.');
      WriteLn('');
      WriteLn('  Tip: Choose a unique community name (e.g. "my-' + PkgArg + '", "fast-' + PkgArg + '").');
      WriteLn('       If you are authoring an official tool, use: bvnb pkg create <name> --tool');
      WriteLn('');
      Halt(1);
    end;

    if IsTool then
    begin
      if (Pos('bvnb-tool-', PkgArg) <> 1) and (Pos('bvnb-', PkgArg) <> 1) then
        PkgName := 'bvnb-tool-' + PkgArg
      else
        PkgName := PkgArg;
      DestDir := ToolsDir + DirectorySeparator + PkgArg;
    end
    else
    begin
      PkgName := PkgArg;
      DestDir := UserPkgDir + DirectorySeparator + PkgArg;
    end;

    if DirectoryExists(DestDir) then
    begin
      WriteLn('  [ERROR] Directory already exists: ' + DestDir);
      Halt(1);
    end;

    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('  BlaiseNotebook Package & Tool Scaffolder');
    WriteLn('======================================================================');
    WriteLn('  Name:           ', PkgArg);
    if IsTool then
      WriteLn('  Category:       Official Auxiliary Tool (frontend/server/packages/tools/)')
    else
      WriteLn('  Category:       Workspace Third-Party Package (./packages/)');
    WriteLn('  Target Dir:     ', DestDir);
    WriteLn('======================================================================');
    WriteLn('');

    ForceDirectories(DestDir);
    ForceDirectories(DestDir + DirectorySeparator + 'examples');

    UnitName := 'u' + UpperCase(Copy(PkgArg, 1, 1)) + Copy(PkgArg, 2, MaxInt);
    UnitName := StringReplace(UnitName, '-', '_', [rfReplaceAll]);

    // 1. Unit Pascal
    Lines := TStringList.Create;
    try
      Lines.Add('unit ' + UnitName + ';');
      Lines.Add('');
      Lines.Add('{$mode objfpc}{$H+}');
      Lines.Add('');
      Lines.Add('interface');
      Lines.Add('');
      Lines.Add('uses');
      Lines.Add('  SysUtils, Classes;');
      Lines.Add('');
      Lines.Add('function ' + UnitName + 'Info: string;');
      Lines.Add('function ' + UnitName + 'Calculate(const AValue: Double): Double;');
      Lines.Add('');
      Lines.Add('implementation');
      Lines.Add('');
      Lines.Add('function ' + UnitName + 'Info: string;');
      Lines.Add('begin');
      Lines.Add('  Result := ''Package ' + PkgArg + ' v1.0.0 (Ready)'';');
      Lines.Add('end;');
      Lines.Add('');
      Lines.Add('function ' + UnitName + 'Calculate(const AValue: Double): Double;');
      Lines.Add('begin');
      Lines.Add('  Result := AValue * 2.0;');
      Lines.Add('end;');
      Lines.Add('');
      Lines.Add('end.');
      Lines.SaveToFile(DestDir + DirectorySeparator + UnitName + '.pas');
    finally
      Lines.Free;
    end;

    // 2. package.json
    ManifestLines := TStringList.Create;
    try
      ManifestLines.Add('{');
      ManifestLines.Add('  "name": "' + PkgName + '",');
      ManifestLines.Add('  "version": "1.0.0",');
      if IsTool then
        ManifestLines.Add('  "description": "Official auxiliary tool ' + PkgArg + ' for BlaiseNotebook",')
      else
        ManifestLines.Add('  "description": "Community extension ' + PkgArg + ' for BlaiseNotebook",');
      ManifestLines.Add('  "author": "BlaiseNotebook Developer",');
      ManifestLines.Add('  "license": "Modified LGPL v2.1 with Static Linking Exception",');
      ManifestLines.Add('  "main": "' + UnitName + '.pas",');
      if IsTool then
        ManifestLines.Add('  "category": "tool",')
      else
        ManifestLines.Add('  "category": "extension",');
      ManifestLines.Add('  "keywords": ["' + PkgArg + '", "blaisenotebook"]');
      ManifestLines.Add('}');
      ManifestLines.SaveToFile(DestDir + DirectorySeparator + 'package.json');
    finally
      ManifestLines.Free;
    end;

    // 3. README.md
    Lines := TStringList.Create;
    try
      Lines.Add('# 📦 ' + PkgArg);
      Lines.Add('');
      Lines.Add('Modular package for BlaiseNotebook.');
      Lines.Add('');
      Lines.Add('## Quick Notebook Usage');
      Lines.Add('');
      Lines.Add('```pascal');
      Lines.Add('uses');
      Lines.Add('  BlaiseOutput,');
      Lines.Add('  ' + UnitName + ';');
      Lines.Add('');
      Lines.Add('begin');
      Lines.Add('  Writeln(' + UnitName + 'Info());');
      Lines.Add('  Writeln(''Calculated: '', ' + UnitName + 'Calculate(21.0):0:2);');
      Lines.Add('end;');
      Lines.Add('```');
      Lines.SaveToFile(DestDir + DirectorySeparator + 'README.md');
    finally
      Lines.Free;
    end;

    // 4. requirements.txt
    Lines := TStringList.Create;
    try
      Lines.Add('# Add Python pip dependencies here (e.g. numpy>=2.0.0)');
      Lines.SaveToFile(DestDir + DirectorySeparator + 'requirements.txt');
    finally
      Lines.Free;
    end;

    // 5. Optional In-Package Extended Documentation (doc/guide.md)
    ForceDirectories(DestDir + DirectorySeparator + 'doc');
    Lines := TStringList.Create;
    try
      Lines.Add('# 📖 ' + PkgArg + ' Documentation');
      Lines.Add('');
      Lines.Add('This optional directory stores extended Markdown (.md) documentation.');
      Lines.Add('');
      Lines.Add('## API Reference');
      Lines.Add('* `' + UnitName + 'Info`: Returns package metadata.');
      Lines.Add('* `' + UnitName + 'Calculate`: Core processing routine.');
      Lines.SaveToFile(DestDir + DirectorySeparator + 'doc' + DirectorySeparator + 'guide.md');
    finally
      Lines.Free;
    end;

    // 6. Optional In-Package Example Notebook (examples/demo.bynb)
    ForceDirectories(DestDir + DirectorySeparator + 'examples');
    Lines := TStringList.Create;
    try
      Lines.Add('{');
      Lines.Add('  "metadata": {');
      Lines.Add('    "name": "demo_' + PkgArg + '",');
      Lines.Add('    "framework": "BlaiseVue",');
      Lines.Add('    "engine": "Synopse mORMot 2 + Free Pascal + Python",');
      Lines.Add('    "license": "Modified LGPL v2.1 with Static Linking Exception",');
      Lines.Add('    "created_at": "2026-11-09T00:00:00.000Z"');
      Lines.Add('  },');
      Lines.Add('  "cells": [');
      Lines.Add('    {');
      Lines.Add('      "id": "cell_1",');
      Lines.Add('      "type": "markdown",');
      Lines.Add('      "source": "# 📦 Demo: ' + PkgArg + '\nThis notebook demonstrates using ' + UnitName + ' directly.",');
      Lines.Add('      "execution_count": 0,');
      Lines.Add('      "status": "idle",');
      Lines.Add('      "execution_time_ms": 0,');
      Lines.Add('      "outputs": []');
      Lines.Add('    },');
      Lines.Add('    {');
      Lines.Add('      "id": "cell_2",');
      Lines.Add('      "type": "code",');
      Lines.Add('      "source": "uses\n  BlaiseOutput,\n  ' + UnitName + ';\n\nbegin\n  Writeln(' + UnitName + 'Info());\n  Writeln(''Calculation: '', ' + UnitName + 'Calculate(21.0):0:2);\nend;",');
      Lines.Add('      "execution_count": 0,');
      Lines.Add('      "status": "idle",');
      Lines.Add('      "execution_time_ms": 0,');
      Lines.Add('      "outputs": []');
      Lines.Add('    }');
      Lines.Add('  ]');
      Lines.Add('}');
      Lines.SaveToFile(DestDir + DirectorySeparator + 'examples' + DirectorySeparator + 'demo_' + PkgArg + '.bynb');
    finally
      Lines.Free;
    end;

    WriteLn('  [SUCCESS] Package scaffolded successfully!');
    WriteLn('    * Pascal Unit: ' + DestDir + DirectorySeparator + UnitName + '.pas');
    WriteLn('    * Manifest:    ' + DestDir + DirectorySeparator + 'package.json');
    WriteLn('    * README:      ' + DestDir + DirectorySeparator + 'README.md');
    WriteLn('    * Docs:        ' + DestDir + DirectorySeparator + 'doc' + DirectorySeparator + 'guide.md (optional)');
    WriteLn('    * Examples:    ' + DestDir + DirectorySeparator + 'examples' + DirectorySeparator + 'demo_' + PkgArg + '.bynb (optional)');
    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('');
    Exit;
  end;

  WriteLn('Unknown pkg sub-command: "', SubCmd, '". Use "list", "search", "install", "remove", or "create".');
end;

// =====================================================================
//  ROLLBACK UTILITY (bvnb rollback)
// =====================================================================

procedure CmdRollback;
var
  RepoDir, BinDir, ActiveBin, BakBin, DummyOut: string;
begin
  RepoDir := GetRepoRoot;
  BinDir := RepoDir + DirectorySeparator + 'bin';
  {$IFDEF WINDOWS}
  ActiveBin := BinDir + DirectorySeparator + 'bvnb.exe';
  BakBin := BinDir + DirectorySeparator + 'bvnb.bak.exe';
  {$ELSE}
  ActiveBin := BinDir + DirectorySeparator + 'bvnb';
  BakBin := BinDir + DirectorySeparator + 'bvnb.bak';
  {$ENDIF}

  WriteLn('');
  WriteLn('======================================================================');
  WriteLn('  BlaiseNotebook CLI Rollback Utility (bvnb rollback)');
  WriteLn('======================================================================');

  if not FileExists(BakBin) then
  begin
    WriteLn('  [ERROR] No previous backup found at: ', BakBin);
    WriteLn('          Backups are automatically created before each "bvnb self-update".');
    WriteLn('======================================================================');
    WriteLn('');
    Halt(1);
  end;

  WriteLn('  [+] Restoring backup: ' + ExtractFileName(BakBin) + ' -> ' + ExtractFileName(ActiveBin) + '...');
  {$IFDEF WINDOWS}
  ExecCmdCapture('cmd.exe /c cd /d "' + BinDir + '" && copy /y bvnb.bak.exe bvnb.exe > nul 2>&1', DummyOut);
  {$ELSE}
  ExecCmdCapture('cp -f "' + BakBin + '" "' + ActiveBin + '" && chmod +x "' + ActiveBin + '"', DummyOut);
  {$ENDIF}

  if FileExists(ActiveBin) then
  begin
    WriteLn('  [SUCCESS] Previous working CLI binary restored successfully!');
    WriteLn('======================================================================');
    WriteLn('');
  end
  else
  begin
    WriteLn('  [ERROR] Failed to restore binary.');
    WriteLn('======================================================================');
    WriteLn('');
    Halt(1);
  end;
end;

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
  WriteLn('  [1/2] Building Reactive Frontend SPA (bv build)...');
  Code := ExecCmdInteractive('"' + BvExe + '" build', FrontendDir);
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
  ExecCmdCapture('killall -9 server >/dev/null 2>&1; pkill -9 -f "server" >/dev/null 2>&1', DummyOut);
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
  ExecCmdCapture('killall -9 server >/dev/null 2>&1; pkill -9 -f "server" >/dev/null 2>&1', DummyOut);
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

  // 4. Launch browser automatically in the background (Windows, Linux, macOS)
  {$IFDEF WINDOWS}
  ExecCmdCapture('start "" "' + Url + '"', DummyOut);
  {$ELSE}
    {$IFDEF DARWIN}
    ExecCmdCapture('open "' + Url + '" >/dev/null 2>&1 &', DummyOut);
    {$ELSE}
    ExecCmdCapture('xdg-open "' + Url + '" >/dev/null 2>&1 &', DummyOut);
    {$ENDIF}
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
  BinDir, CompCmd, CompOut, TargetBin, MoveCmd, DummyOut, NewBin: string;
  DiffList: TStringList;
  CheckOnly, ForceUpdate, NeedRecompile, HadLocalBinMod: Boolean;
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
  ForceUpdate := False;
  TargetBranch := '';

  for i := 2 to ParamCount do
  begin
    if (ParamStr(i) = '--check') or (ParamStr(i) = '-c') then
      CheckOnly := True
    else if (ParamStr(i) = '--force') or (ParamStr(i) = '-f') then
      ForceUpdate := True
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
      WriteLn('    --force, -f          Force update and reset uncommitted local files');
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

  // Safety check for uncommitted local changes (ignoring compiled binaries, logs and untracked files)
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
      // Untracked (??) or ignored (!!) files are not uncommitted tracked modifications
      if (Copy(LineStr, 1, 2) = '??') or (Copy(LineStr, 1, 2) = '!!') then
        Continue;
      if (Pos('bin/bvnb', LineStr) > 0) or
         (Pos('frontend/.env', LineStr) > 0) or
         (Pos('.env', LineStr) > 0) or
         (Pos('.log', LineStr) > 0) then
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
    if ForceUpdate then
    begin
      WriteLn('  [INFO] Local changes detected, but --force was specified.');
      WriteLn('         Resetting local modifications to synchronize cleanly with GitHub...');
      ExecCmdCapture('git -C "' + RepoDir + '" checkout -- .', DummyOut);
      HadLocalBinMod := True;
    end
    else
    begin
      WriteLn('  [WARNING] You have uncommitted local changes in the BlaiseNotebook repository:');
      WriteLn(GitStatusOut);
      WriteLn('  Run "git stash" or commit before updating, or run "bvnb self-update --force".');
      Halt(1);
    end;
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

    // Persistent backup of active binary before recompile
  BinDir := RepoDir + DirectorySeparator + 'bin';
  {$IFDEF WINDOWS}
  ExecCmdCapture('cmd.exe /c cd /d "' + BinDir + '" && if exist bvnb.exe copy /y bvnb.exe bvnb.bak.exe > nul 2>&1', DummyOut);
  {$ELSE}
  ExecCmdCapture('cd "' + BinDir + '" && if [ -f bvnb ]; then cp -f bvnb bvnb.bak 2>/dev/null; fi', DummyOut);
  {$ENDIF}

  NeedRecompile := (TargetBranch <> CurBranch) or (Pos('bin/bvnb.pas', DiffOut) > 0) or (Pos('bin\bvnb.pas', DiffOut) > 0) or HadLocalBinMod or ForceUpdate;
  if NeedRecompile and FindFPCExecutable(FpcExe, FpcVer, FpcSource) then
  begin
    WriteLn('  [BUILD] Recompiling bvnb CLI binary with Free Pascal...');
    {$IFDEF WINDOWS}
    NewBin := BinDir + DirectorySeparator + 'bvnb.new.exe';
    CompCmd := 'cmd.exe /c cd /d "' + BinDir + '" && "' + FpcExe + '" -MObjFPC -Sh -o"bvnb.new.exe" bvnb.pas';
    ExecCmdCapture(CompCmd, CompOut);
    if FileExists(NewBin) then
    begin
      // Safe Windows binary swap: move running exe to old, move new to active
      ExecCmdCapture('cmd.exe /c cd /d "' + BinDir + '" && move /y bvnb.exe bvnb.old.exe > nul 2>&1 && move /y bvnb.new.exe bvnb.exe > nul 2>&1', DummyOut);
      WriteLn('  [SUCCESS] CLI binary bvnb.exe recompiled successfully!');
    end
    else
      WriteLn('  [WARNING] Recompilation output: ' + CompOut);
    {$ELSE}
    CompCmd := 'cd "' + BinDir + '" && "' + FpcExe + '" -MObjFPC -Sh bvnb.pas && chmod +x bvnb';
    ExecCmdCapture(CompCmd, CompOut);
    TargetBin := BinDir + DirectorySeparator + 'bvnb';
    if FileExists(TargetBin) then
      WriteLn('  [SUCCESS] CLI binary bvnb recompiled successfully!');
    {$ENDIF}
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
  WriteLn('  bvnb self-update [--check]   Syncs & rebuilds BlaiseNotebook directly from GitHub via Git (--force)');
  WriteLn('  bvnb channel [use <name>]    Inspects or switches repository branch (main | develop)');
  WriteLn('  bvnb rollback                Restores previous working CLI binary from persistent backup');
  WriteLn('  bvnb pkg <list|search|...>   Manages official and community packages & tools');
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
  else if (Cmd = 'rollback') or (Cmd = 'revert-cli') then
    CmdRollback
  else if (Cmd = 'pkg') or (Cmd = 'package') or (Cmd = 'packages') or (Cmd = 'lib') then
    CmdPackage
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
