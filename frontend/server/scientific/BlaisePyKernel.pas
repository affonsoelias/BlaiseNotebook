unit BlaisePyKernel;

{
  BlaisePyKernel - Python4Delphi / Python4Lazarus Bridge for BlaiseNotebook
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)

  Provides seamless interoperability between Object Pascal and Python:
  - Initializes Python runtime with auto-discovery of local Python 3.x installations
  - Bridges NumPy, Pandas, Scikit-learn, and Matplotlib into BlaiseNotebook cells
  - Captures outputs, figures, and DataFrames directly into BlaiseVue reactive outputs
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes,
  PythonEngine, BlaiseOutput;

type
  { TBlaisePy - Static manager for the Python environment }
  TBlaisePy = class
  private
    class var FEngine: TPythonEngine;
    class var FInitialized: Boolean;
    class procedure EnsureEngine;
  public
    class procedure Init(const ADllPath: string = ''; const ADllName: string = '');
    class procedure Finalize;
    class function Engine: TPythonEngine;
    class function Exec(const ACode: string): Boolean;
    class function EvalStr(const AExpr: string): string;

    // Visualization bridges directly to BlaiseVue outputs
    class procedure ShowPlot(const ATitle: string = 'Matplotlib Plot');
    class procedure ShowDataFrame(const AVarName: string; const ATitle: string = 'Pandas DataFrame'; AMaxRows: Integer = 50);
    class procedure ShowSeriesChart(const AVarName: string; const ATitle: string = 'Series Chart'; const AChartType: string = 'line');
  end;

// Convenience global routines for notebook cells
procedure PyRun(const ACode: string);
function PyEval(const AExpr: string): string;
procedure ShowPyPlot(const ATitle: string = 'Matplotlib Plot');
procedure ShowPyDataFrame(const AVarName: string; const ATitle: string = 'Pandas DataFrame'; AMaxRows: Integer = 50);
procedure ShowPySeriesChart(const AVarName: string; const ATitle: string = 'Series Chart'; const AChartType: string = 'line');

implementation

const
  DEFAULT_PY_PATHS: array[1..4] of string = (
    'C:\Users\Pichau\AppData\Local\Programs\Python\Python313',
    'C:\Users\Pichau\AppData\Local\Programs\Python\Python312',
    'C:\Users\Pichau\AppData\Local\Programs\Python\Python311',
    'C:\Program Files\Python313'
  );

{ TBlaisePy }

class procedure TBlaisePy.EnsureEngine;
var
  i: Integer;
  CandidatePath: string;
begin
  if FInitialized and Assigned(FEngine) and FEngine.Initialized then
    Exit;

  if not Assigned(FEngine) then
    FEngine := TPythonEngine.Create(nil);

  FEngine.AutoLoad := False;
  FEngine.UseLastKnownVersion := False;

  // Auto-detect Python 3.13 / 3.12 DLL
  for i := Low(DEFAULT_PY_PATHS) to High(DEFAULT_PY_PATHS) do
  begin
    CandidatePath := DEFAULT_PY_PATHS[i];
    if DirectoryExists(CandidatePath) then
    begin
      if FileExists(CandidatePath + DirectorySeparator + 'python313.dll') then
      begin
        FEngine.DllPath := CandidatePath;
        FEngine.DllName := 'python313.dll';
        FEngine.RegVersion := '3.13';
        FEngine.APIVersion := 1013;
        Break;
      end
      else if FileExists(CandidatePath + DirectorySeparator + 'python312.dll') then
      begin
        FEngine.DllPath := CandidatePath;
        FEngine.DllName := 'python312.dll';
        FEngine.RegVersion := '3.12';
        FEngine.APIVersion := 1013;
        Break;
      end;
    end;
  end;

  if FEngine.DllName = '' then
  begin
    FEngine.DllName := 'python313.dll';
    FEngine.APIVersion := 1013;
    FEngine.RegVersion := '3.13';
  end;

  try
    FEngine.LoadDll;
    FInitialized := FEngine.Initialized;
  except
    on E: Exception do
      WriteLn('[BlaisePyKernel] Aviso ao carregar Python DLL: ' + E.Message);
  end;
end;

class procedure TBlaisePy.Init(const ADllPath: string; const ADllName: string);
begin
  if not Assigned(FEngine) then
    FEngine := TPythonEngine.Create(nil);

  if ADllPath <> '' then
    FEngine.DllPath := ADllPath;
  if ADllName <> '' then
    FEngine.DllName := ADllName;

  FEngine.AutoLoad := False;
  FEngine.UseLastKnownVersion := False;
  FEngine.LoadDll;
  FInitialized := FEngine.Initialized;
end;

class procedure TBlaisePy.Finalize;
begin
  if Assigned(FEngine) then
  begin
    try
      FEngine.UnloadDll;
    except
    end;
    FreeAndNil(FEngine);
  end;
  FInitialized := False;
end;

class function TBlaisePy.Engine: TPythonEngine;
begin
  EnsureEngine;
  Result := FEngine;
end;

class function TBlaisePy.Exec(const ACode: string): Boolean;
begin
  Result := False;
  EnsureEngine;
  if not FInitialized then
  begin
    WriteLn('[BlaisePyKernel] Erro: Python Engine nao esta inicializado.');
    Exit;
  end;

  try
    FEngine.ExecString(AnsiString(ACode));
    Result := True;
  except
    on E: Exception do
    begin
      WriteLn('[Python Error] ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TBlaisePy.EvalStr(const AExpr: string): string;
begin
  Result := '';
  EnsureEngine;
  if not FInitialized then Exit;

  try
    Result := FEngine.EvalStringAsStr(AnsiString(AExpr));
  except
    on E: Exception do
      WriteLn('[Python Eval Error] ' + E.Message);
  end;
end;

class procedure TBlaisePy.ShowPlot(const ATitle: string);
var
  PyHelper: string;
  PngBase64: string;
begin
  EnsureEngine;
  // Script to encode the current matplotlib figure to base64
  PyHelper :=
    'import io, base64'#10 +
    'import matplotlib.pyplot as plt'#10 +
    '__buf__ = io.BytesIO()'#10 +
    'plt.savefig(__buf__, format="png", bbox_inches="tight", dpi=120)'#10 +
    '__buf__.seek(0)'#10 +
    '__b64_img__ = base64.b64encode(__buf__.read()).decode("ascii")'#10 +
    'plt.close("all")'#10;

  Exec(PyHelper);
  PngBase64 := EvalStr('__b64_img__');
  if PngBase64 <> '' then
  begin
    // Trim any accidental quotes
    if (Length(PngBase64) >= 2) and (PngBase64[1] = '''') and (PngBase64[Length(PngBase64)] = '''') then
      PngBase64 := Copy(PngBase64, 2, Length(PngBase64) - 2);
    TBlaiseOutput.ShowImage(ATitle, PngBase64);
  end;
end;

class procedure TBlaisePy.ShowDataFrame(const AVarName: string; const ATitle: string; AMaxRows: Integer);
var
  PyHelper: string;
  ColsJson, RowsJson: string;
  Payload: string;
begin
  EnsureEngine;
  // Convert DataFrame to JSON columns and records
  PyHelper :=
    Format(
      'import json'#10 +
      '__df_sub__ = %s.head(%d)'#10 +
      '__cols_json__ = json.dumps(list(__df_sub__.columns.astype(str)))'#10 +
      '__rows_json__ = __df_sub__.to_json(orient="records")'#10,
      [AVarName, AMaxRows]);

  Exec(PyHelper);
  ColsJson := EvalStr('__cols_json__');
  RowsJson := EvalStr('__rows_json__');

  if (ColsJson <> '') and (RowsJson <> '') then
  begin
    // If Python string has enclosing quotes from EvalStringAsStr, clean them:
    if (Length(ColsJson) >= 2) and (ColsJson[1] = '''') and (ColsJson[Length(ColsJson)] = '''') then
      ColsJson := Copy(ColsJson, 2, Length(ColsJson) - 2);
    if (Length(RowsJson) >= 2) and (RowsJson[1] = '''') and (RowsJson[Length(RowsJson)] = '''') then
      RowsJson := Copy(RowsJson, 2, Length(RowsJson) - 2);

    Payload := Format('{"type":"table","title":"%s","columns":%s,"rows":%s}',
      [ATitle, ColsJson, RowsJson]);
    WriteLn(BLAISE_PAYLOAD_TAG + Payload);
    Flush(Output);
  end;
end;

class procedure TBlaisePy.ShowSeriesChart(const AVarName: string; const ATitle: string; const AChartType: string);
var
  PyHelper: string;
  DataJson: string;
begin
  EnsureEngine;
  PyHelper :=
    Format(
      'import json'#10 +
      '__s__ = %s'#10 +
      '__c_labels__ = [str(x) for x in __s__.index]'#10 +
      '__c_values__ = [float(x) for x in __s__.values]'#10 +
      '__chart_json__ = json.dumps({'#10 +
      '  "labels": __c_labels__,'#10 +
      '  "datasets": [{"label": "%s", "data": __c_values__, "borderColor": "#3b82f6", "backgroundColor": "rgba(59, 130, 246, 0.2)"}]'#10 +
      '})'#10,
      [AVarName, ATitle]);

  Exec(PyHelper);
  DataJson := EvalStr('__chart_json__');
  if DataJson <> '' then
  begin
    if (Length(DataJson) >= 2) and (DataJson[1] = '''') and (DataJson[Length(DataJson)] = '''') then
      DataJson := Copy(DataJson, 2, Length(DataJson) - 2);
    TBlaiseOutput.ShowChart(ATitle, AChartType, DataJson);
  end;
end;

{ Global procedures }

procedure PyRun(const ACode: string);
begin
  TBlaisePy.Exec(ACode);
end;

function PyEval(const AExpr: string): string;
begin
  Result := TBlaisePy.EvalStr(AExpr);
end;

procedure ShowPyPlot(const ATitle: string);
begin
  TBlaisePy.ShowPlot(ATitle);
end;

procedure ShowPyDataFrame(const AVarName: string; const ATitle: string; AMaxRows: Integer);
begin
  TBlaisePy.ShowDataFrame(AVarName, ATitle, AMaxRows);
end;

procedure ShowPySeriesChart(const AVarName: string; const ATitle: string; const AChartType: string);
begin
  TBlaisePy.ShowSeriesChart(AVarName, ATitle, AChartType);
end;

initialization

finalization
  TBlaisePy.Finalize;

end.
