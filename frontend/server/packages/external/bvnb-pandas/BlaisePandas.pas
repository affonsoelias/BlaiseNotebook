unit BlaisePandas;

{
  BlaisePandas - Strongly-Typed Object Pascal API for Python Pandas & NumPy
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)

  Provides native Object Pascal abstractions for Pandas DataFrame & Series:
  - TPyDataFrame: Idiomatic wrapper for Pandas DataFrame
  - TPySeries: Idiomatic wrapper for Pandas Series & 1D numeric vectors
  - TPyGroupBy: Fluent aggregation engine
  - Seamless Chart.js and Data Table visual outputs
}

{ objfpc}{+}
{ advancedrecords}

interface

uses
  SysUtils, Classes, Math, StrUtils,
  BlaiseOutput, BlaisePyKernel, BlaiseMathKernel;

type
  TPySeries = class;
  TPyDataFrame = class;
  TPyGroupBy = class;

  { TPyGroupBy - GroupBy aggregator for fluent analytical queries }
  TPyGroupBy = class
  private
    FDFVarName: string;
    FGroupCol: string;
    function EscapeStr(const S: string): string;
  public
    constructor Create(const ADFVarName, AGroupCol: string);
    function Mean: TPyDataFrame;
    function Sum: TPyDataFrame;
    function Count: TPyDataFrame;
    function Min: TPyDataFrame;
    function Max: TPyDataFrame;
  end;

  { TPySeries - Strongly-typed wrapper around a Pandas Series / 1D Array }
  TPySeries = class
  private
    FVarName: string;
    FName: string;
    function GetCount: Integer;
    function GetMean: Double;
    function GetStdDev: Double;
    function GetMin: Double;
    function GetMax: Double;
    function GetSum: Double;
    function GetMedian: Double;
    function GetItem(AIndex: Integer): Double;
    procedure SetName(const AValue: string);
  public
    constructor Create(const AVarName: string; const AName: string = ''); overload;
    constructor Create(const AValues: array of Double; const AName: string = ''); overload;
    constructor Create(const AValues: array of string; const AName: string = ''); overload;
    constructor Create(const AValues: array of Integer; const AName: string = ''); overload;
    constructor Create(const AVec: TVector; const AName: string = ''); overload;

    function ToArray: TDoubleArray;
    function ToVector: TVector;
    function Describe: string;
    procedure Print;

    // Visualizations
    procedure Plot(const ATitle: string = ''; const AChartType: string = 'line');
    procedure PlotAgainst(const AXSeries: TPySeries; const ATitle: string = ''; const AChartType: string = 'line');

    // Vectorized arithmetic operations
    function Multiply(const AFactor: Double): TPySeries;
    function Add(const AValue: Double): TPySeries; overload;
    function Add(const AOther: TPySeries): TPySeries; overload;
    function Subtract(const AOther: TPySeries): TPySeries;

    function Head(ACount: Integer = 5): TPySeries;
    function Tail(ACount: Integer = 5): TPySeries;

    property VarName: string read FVarName;
    property Name: string read FName write SetName;
    property Count: Integer read GetCount;
    property Mean: Double read GetMean;
    property StdDev: Double read GetStdDev;
    property Min: Double read GetMin;
    property Max: Double read GetMax;
    property Sum: Double read GetSum;
    property Median: Double read GetMedian;
    property Items[Index: Integer]: Double read GetItem; default;
  end;

  { TPyDataFrame - Strongly-typed wrapper around a Pandas DataFrame }
  TPyDataFrame = class
  private
    FVarName: string;
    function EscapeStr(const S: string): string;
  public
    constructor Create; overload;
    constructor Create(const AVarName: string); overload;
    class function FromCSV(const AFilePath: string): TPyDataFrame;
    class function FromJSON(const AJsonStr: string): TPyDataFrame;

    // Fluent column addition
    function AddColumn(const AColName: string; const AValues: array of Double): TPyDataFrame; overload;
    function AddColumn(const AColName: string; const AValues: array of string): TPyDataFrame; overload;
    function AddColumn(const AColName: string; const AValues: array of Integer): TPyDataFrame; overload;
    function AddColumn(const AColName: string; const ASeries: TPySeries): TPyDataFrame; overload;
    function AddColumn(const AColName: string; const AVec: TVector): TPyDataFrame; overload;

    // Slicing and extraction
    function Column(const AColName: string): TPySeries;
    function Columns(const AColNames: array of string): TPyDataFrame;
    function Drop(const AColName: string): TPyDataFrame;
    function Head(ACount: Integer = 5): TPyDataFrame;
    function Tail(ACount: Integer = 5): TPyDataFrame;

    // Metadata & Summary
    function RowCount: Integer;
    function ColumnCount: Integer;
    function ColumnNames: TStrings;
    function Describe: string;
    procedure Print;

    // Interactive Visualizations
    procedure ShowTable(const ATitle: string = 'DataFrame'; AMaxRows: Integer = 50);
    procedure PlotLine(const ATitle, AXCol, AYCol: string); overload;
    procedure PlotLine(const ATitle, AXCol: string; const AYCols: array of string); overload;
    procedure PlotBar(const ATitle, AXCol, AYCol: string); overload;
    procedure PlotBar(const ATitle, AXCol: string; const AYCols: array of string); overload;
    procedure PlotScatter(const ATitle, AXCol, AYCol: string);
    procedure PlotArea(const ATitle, AXCol, AYCol: string);
    procedure PlotPie(const ATitle, ALabelCol, AValueCol: string);
    procedure PlotDoughnut(const ATitle, ALabelCol, AValueCol: string);
    procedure PlotHistogram(const ATitle, ACol: string; ABins: Integer = 10);
    procedure PlotBoxPlot(const ATitle, ACategoryCol, AValueCol: string);

    // Fluent Filtering, Sorting and Transformations
    function Filter(const AExpression: string): TPyDataFrame;
    function SortBy(const AColName: string; Ascending: Boolean = True): TPyDataFrame; overload;
    function SortBy(const AColNames: array of string; Ascending: Boolean = True): TPyDataFrame; overload;
    function DropColumns(const AColNames: array of string): TPyDataFrame;
    function DropNA: TPyDataFrame; overload;
    function DropNA(const ASubsetCols: array of string): TPyDataFrame; overload;
    function GroupBy(const AColName: string): TPyGroupBy;

    // Persistence & Inter-cell continuity
    procedure ToCSV(const AFilePath: string);
    procedure Attach(const AVarName: string);
    procedure SaveAs(const AVarName: string);

    property VarName: string read FVarName;
  end;


// Utility routines for Pandas & DataFrames
function PyFloat(const V: Double): string;
function NewPyVar(const APrefix: string = 'var'): string;
procedure EnsurePyPandas;

implementation

var
  GVarSeq: Int64 = 0;
  FormatSettingsUS: TFormatSettings;

const
  CHART_COLORS: array[0..6] of string = (
    '#3b82f6', // Blue
    '#10b981', // Emerald
    '#f59e0b', // Amber
    '#ef4444', // Red
    '#8b5cf6', // Violet
    '#06b6d4', // Cyan
    '#ec4899'  // Pink
  );

function NewPyVar(const APrefix: string = 'var'): string;
begin
  Inc(GVarSeq);
  Result := Format('__ds_%s_%d__', [APrefix, GVarSeq]);
end;

function PyFloat(const V: Double): string;
begin
  if IsNan(V) then
    Result := 'float("nan")'
  else if IsInfinite(V) then
  begin
    if V > 0 then Result := 'float("inf")'
    else Result := '-float("inf")';
  end
  else
    Result := FloatToStr(V, FormatSettingsUS);
end;

procedure EnsurePyPandas;
begin
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  TBlaisePy.Exec(
    'import sys'#10 +
    'import json'#10 +
    'import numpy as np'#10 +
    'import pandas as pd'#10
  );
end;

{ TPySeries }

constructor TPySeries.Create(const AVarName: string; const AName: string);
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := AVarName;
  FName := AName;
  if FVarName <> '' then
    TBlaisePy.Exec(Format('if "%s" not in globals(): %s = pd.Series()', [FVarName, FVarName]));
  if FName = '' then
  begin
    FName := TBlaisePy.EvalStr(Format('str(%s.name) if hasattr(%s, "name") and %s.name is not None else ""',
      [FVarName, FVarName, FVarName]));
  end;
end;

constructor TPySeries.Create(const AValues: array of Double; const AName: string);
var
  i: Integer;
  Code: string;
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := NewPyVar('s');
  FName := AName;

  Code := FVarName + ' = pd.Series([';
  for i := 0 to High(AValues) do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + PyFloat(AValues[i]);
  end;
  Code := Code + Format('], name="%s")', [FName]);
  TBlaisePy.Exec(Code);
end;

constructor TPySeries.Create(const AValues: array of string; const AName: string);
var
  i: Integer;
  Code: string;
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := NewPyVar('s');
  FName := AName;

  Code := FVarName + ' = pd.Series([';
  for i := 0 to High(AValues) do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + '"' + StringReplace(AValues[i], '"', '\"', [rfReplaceAll]) + '"';
  end;
  Code := Code + Format('], name="%s")', [FName]);
  TBlaisePy.Exec(Code);
end;

constructor TPySeries.Create(const AValues: array of Integer; const AName: string);
var
  i: Integer;
  Code: string;
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := NewPyVar('s');
  FName := AName;

  Code := FVarName + ' = pd.Series([';
  for i := 0 to High(AValues) do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + IntToStr(AValues[i]);
  end;
  Code := Code + Format('], name="%s")', [FName]);
  TBlaisePy.Exec(Code);
end;

constructor TPySeries.Create(const AVec: TVector; const AName: string);
var
  i: Integer;
  Code: string;
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := NewPyVar('s');
  FName := AName;

  Code := FVarName + ' = pd.Series([';
  for i := 0 to AVec.Count - 1 do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + PyFloat(AVec[i]);
  end;
  Code := Code + Format('], name="%s")', [FName]);
  TBlaisePy.Exec(Code);
end;

procedure TPySeries.SetName(const AValue: string);
begin
  FName := AValue;
  TBlaisePy.Exec(Format('%s.name = "%s"', [FVarName, FName]));
end;

function TPySeries.GetCount: Integer;
begin
  Result := StrToIntDef(TBlaisePy.EvalStr(Format('len(%s)', [FVarName])), 0);
end;

function TPySeries.GetMean: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.mean())', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPySeries.GetStdDev: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.std())', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPySeries.GetMin: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.min())', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPySeries.GetMax: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.max())', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPySeries.GetSum: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.sum())', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPySeries.GetMedian: Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.median())', [FVarName])), 0.0, FormatSettingsUS);
end;

function TPySeries.GetItem(AIndex: Integer): Double;
begin
  Result := StrToFloatDef(TBlaisePy.EvalStr(Format('float(%s.iloc[%d])', [FVarName, AIndex])), 0.0, FormatSettingsUS);
end;

function TPySeries.ToArray: TDoubleArray;
var
  JsonStr: string;
  Len, P1, P2: Integer;
  ItemStr: string;
begin
  SetLength(Result, 0);
  JsonStr := TBlaisePy.EvalStr(Format('json.dumps([float(x) for x in %s.dropna().values])', [FVarName]));
  if (Length(JsonStr) >= 2) and (JsonStr[1] = '[') and (JsonStr[Length(JsonStr)] = ']') then
  begin
    JsonStr := Copy(JsonStr, 2, Length(JsonStr) - 2);
    if Trim(JsonStr) = '' then Exit;
    P1 := 1;
    while P1 <= Length(JsonStr) do
    begin
      P2 := PosEx(',', JsonStr, P1);
      if P2 = 0 then P2 := Length(JsonStr) + 1;
      ItemStr := Trim(Copy(JsonStr, P1, P2 - P1));
      Len := Length(Result);
      SetLength(Result, Len + 1);
      Result[Len] := StrToFloatDef(ItemStr, 0.0, FormatSettingsUS);
      P1 := P2 + 1;
    end;
  end;
end;

function TPySeries.ToVector: TVector;
begin
  Result.Data := ToArray;
end;

function TPySeries.Describe: string;
begin
  Result := TBlaisePy.EvalStr(Format('str(%s.describe())', [FVarName]));
end;

procedure TPySeries.Print;
begin
  WriteLn(TBlaisePy.EvalStr(Format('str(%s)', [FVarName])));
  Flush(Output);
end;

procedure TPySeries.Plot(const ATitle: string; const AChartType: string);
var
  TitleText: string;
begin
  TitleText := ATitle;
  if TitleText = '' then TitleText := FName;
  if TitleText = '' then TitleText := 'Series Chart';
  TBlaisePy.ShowSeriesChart(FVarName, TitleText, AChartType);
end;

procedure TPySeries.PlotAgainst(const AXSeries: TPySeries; const ATitle: string; const AChartType: string);
var
  TitleText: string;
  PyCode, ChartJson: string;
begin
  TitleText := ATitle;
  if TitleText = '' then TitleText := FName;
  if TitleText = '' then TitleText := 'Comparison';

  PyCode :=
    Format(
      '__x_vals__ = [str(x) for x in %s.values]'#10 +
      '__y_vals__ = [float(y) for y in %s.values]'#10 +
      '__c_json__ = json.dumps({'#10 +
      '  "labels": __x_vals__,'#10 +
      '  "datasets": [{"label": "%s", "data": __y_vals__, "borderColor": "#3b82f6", "backgroundColor": "rgba(59, 130, 246, 0.2)", "tension": 0.3}]'#10 +
      '})',
      [AXSeries.VarName, FVarName, TitleText]);
  TBlaisePy.Exec(PyCode);
  ChartJson := TBlaisePy.EvalStr('__c_json__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(TitleText, AChartType, ChartJson);
end;

function TPySeries.Multiply(const AFactor: Double): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s * %s', [NewVar, FVarName, PyFloat(AFactor)]));
  Result := TPySeries.Create(NewVar, FName);
end;

function TPySeries.Add(const AValue: Double): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s + %s', [NewVar, FVarName, PyFloat(AValue)]));
  Result := TPySeries.Create(NewVar, FName);
end;

function TPySeries.Add(const AOther: TPySeries): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s + %s', [NewVar, FVarName, AOther.VarName]));
  Result := TPySeries.Create(NewVar, FName);
end;

function TPySeries.Subtract(const AOther: TPySeries): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s - %s', [NewVar, FVarName, AOther.VarName]));
  Result := TPySeries.Create(NewVar, FName);
end;

function TPySeries.Head(ACount: Integer): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s.head(%d)', [NewVar, FVarName, ACount]));
  Result := TPySeries.Create(NewVar, FName);
end;

function TPySeries.Tail(ACount: Integer): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s.tail(%d)', [NewVar, FVarName, ACount]));
  Result := TPySeries.Create(NewVar, FName);
end;

{ TPyDataFrame }

constructor TPyDataFrame.Create;
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := NewPyVar('df');
  TBlaisePy.Exec(Format('%s = pd.DataFrame()', [FVarName]));
end;

constructor TPyDataFrame.Create(const AVarName: string);
begin
  inherited Create;
  EnsurePyPandas;
  FVarName := AVarName;
  if FVarName <> '' then
    TBlaisePy.Exec(Format('if "%s" not in globals(): %s = pd.DataFrame()', [FVarName, FVarName]));
end;

class function TPyDataFrame.FromCSV(const AFilePath: string): TPyDataFrame;
var
  NewVar, SafePath: string;
begin
  EnsurePyPandas;
  NewVar := NewPyVar('df');
  SafePath := StringReplace(AFilePath, '\', '/', [rfReplaceAll]);
  TBlaisePy.Exec(
    Format(
      'import os'#10 +
      '__csv_path = "%s"'#10 +
      'if not os.path.exists(__csv_path) and os.path.exists(os.path.basename(__csv_path)):'#10 +
      '    __csv_path = os.path.basename(__csv_path)'#10 +
      '%s = pd.read_csv(__csv_path)',
      [SafePath, NewVar]));
  Result := TPyDataFrame.Create(NewVar);
end;

class function TPyDataFrame.FromJSON(const AJsonStr: string): TPyDataFrame;
var
  NewVar: string;
begin
  EnsurePyPandas;
  NewVar := NewPyVar('df');
  TBlaisePy.Exec(Format('import io; %s = pd.read_json(io.StringIO("""%s"""))', [NewVar, AJsonStr]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.EscapeStr(const S: string): string;
begin
  Result := StringReplace(S, '"', '\"', [rfReplaceAll]);
end;

function TPyDataFrame.AddColumn(const AColName: string; const AValues: array of Double): TPyDataFrame;
var
  i: Integer;
  Code: string;
begin
  Code := Format('%s["%s"] = pd.Series([', [FVarName, EscapeStr(AColName)]);
  for i := 0 to High(AValues) do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + PyFloat(AValues[i]);
  end;
  Code := Code + '])';
  TBlaisePy.Exec(Code);
  Result := Self;
end;

function TPyDataFrame.AddColumn(const AColName: string; const AValues: array of string): TPyDataFrame;
var
  i: Integer;
  Code: string;
begin
  Code := Format('%s["%s"] = pd.Series([', [FVarName, EscapeStr(AColName)]);
  for i := 0 to High(AValues) do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + '"' + EscapeStr(AValues[i]) + '"';
  end;
  Code := Code + '])';
  TBlaisePy.Exec(Code);
  Result := Self;
end;

function TPyDataFrame.AddColumn(const AColName: string; const AValues: array of Integer): TPyDataFrame;
var
  i: Integer;
  Code: string;
begin
  Code := Format('%s["%s"] = pd.Series([', [FVarName, EscapeStr(AColName)]);
  for i := 0 to High(AValues) do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + IntToStr(AValues[i]);
  end;
  Code := Code + '])';
  TBlaisePy.Exec(Code);
  Result := Self;
end;

function TPyDataFrame.AddColumn(const AColName: string; const ASeries: TPySeries): TPyDataFrame;
begin
  TBlaisePy.Exec(Format('%s["%s"] = %s', [FVarName, EscapeStr(AColName), ASeries.VarName]));
  Result := Self;
end;

function TPyDataFrame.AddColumn(const AColName: string; const AVec: TVector): TPyDataFrame;
var
  i: Integer;
  Code: string;
begin
  Code := Format('%s["%s"] = pd.Series([', [FVarName, EscapeStr(AColName)]);
  for i := 0 to AVec.Count - 1 do
  begin
    if i > 0 then Code := Code + ',';
    Code := Code + PyFloat(AVec[i]);
  end;
  Code := Code + '])';
  TBlaisePy.Exec(Code);
  Result := Self;
end;

function TPyDataFrame.Column(const AColName: string): TPySeries;
var
  NewVar: string;
begin
  NewVar := NewPyVar('s');
  TBlaisePy.Exec(Format('%s = %s["%s"]', [NewVar, FVarName, EscapeStr(AColName)]));
  Result := TPySeries.Create(NewVar, AColName);
end;

function TPyDataFrame.Columns(const AColNames: array of string): TPyDataFrame;
var
  NewVar, ListStr: string;
  i: Integer;
begin
  NewVar := NewPyVar('df');
  ListStr := '[';
  for i := 0 to High(AColNames) do
  begin
    if i > 0 then ListStr := ListStr + ', ';
    ListStr := ListStr + '"' + EscapeStr(AColNames[i]) + '"';
  end;
  ListStr := ListStr + ']';
  TBlaisePy.Exec(Format('%s = %s[%s]', [NewVar, FVarName, ListStr]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.Drop(const AColName: string): TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df');
  TBlaisePy.Exec(Format('%s = %s.drop(columns=["%s"])', [NewVar, FVarName, EscapeStr(AColName)]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.Head(ACount: Integer): TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df');
  TBlaisePy.Exec(Format('%s = %s.head(%d)', [NewVar, FVarName, ACount]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.Tail(ACount: Integer): TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df');
  TBlaisePy.Exec(Format('%s = %s.tail(%d)', [NewVar, FVarName, ACount]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.RowCount: Integer;
begin
  Result := StrToIntDef(TBlaisePy.EvalStr(Format('len(%s)', [FVarName])), 0);
end;

function TPyDataFrame.ColumnCount: Integer;
begin
  Result := StrToIntDef(TBlaisePy.EvalStr(Format('len(%s.columns)', [FVarName])), 0);
end;

function TPyDataFrame.ColumnNames: TStrings;
var
  JsonStr: string;
  P1, P2: Integer;
  ItemStr: string;
begin
  Result := TStringList.Create;
  JsonStr := TBlaisePy.EvalStr(Format('json.dumps(list(%s.columns.astype(str)))', [FVarName]));
  if (Length(JsonStr) >= 2) and (JsonStr[1] = '[') and (JsonStr[Length(JsonStr)] = ']') then
  begin
    JsonStr := Copy(JsonStr, 2, Length(JsonStr) - 2);
    if Trim(JsonStr) = '' then Exit;
    P1 := 1;
    while P1 <= Length(JsonStr) do
    begin
      P2 := PosEx(',', JsonStr, P1);
      if P2 = 0 then P2 := Length(JsonStr) + 1;
      ItemStr := Trim(Copy(JsonStr, P1, P2 - P1));
      if (Length(ItemStr) >= 2) and (ItemStr[1] = '"') and (ItemStr[Length(ItemStr)] = '"') then
        ItemStr := Copy(ItemStr, 2, Length(ItemStr) - 2);
      Result.Add(ItemStr);
      P1 := P2 + 1;
    end;
  end;
end;

function TPyDataFrame.Describe: string;
begin
  Result := TBlaisePy.EvalStr(Format('str(%s.describe())', [FVarName]));
end;

procedure TPyDataFrame.Print;
begin
  WriteLn(TBlaisePy.EvalStr(Format('str(%s)', [FVarName])));
  Flush(Output);
end;

procedure TPyDataFrame.ShowTable(const ATitle: string; AMaxRows: Integer);
begin
  TBlaisePy.ShowDataFrame(FVarName, ATitle, AMaxRows);
end;

procedure TPyDataFrame.PlotLine(const ATitle, AXCol, AYCol: string);
begin
  TBlaisePy.ShowDataFrameChart(FVarName, AXCol, AYCol, ATitle, 'line');
end;

procedure TPyDataFrame.PlotLine(const ATitle, AXCol: string; const AYCols: array of string);
var
  PyHelper, ChartJson: string;
  ColsList: string;
  i: Integer;
begin
  ColsList := '[';
  for i := 0 to High(AYCols) do
  begin
    if i > 0 then ColsList := ColsList + ', ';
    ColsList := ColsList + '"' + EscapeStr(AYCols[i]) + '"';
  end;
  ColsList := ColsList + ']';

  PyHelper :=
    Format(
      '__x_labels__ = [str(x) for x in %s["%s"]]'#10 +
      '__datasets__ = []'#10 +
      '__y_cols__ = %s'#10 +
      '__colors__ = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899"]'#10 +
      'for idx, col in enumerate(__y_cols__):'#10 +
      '    c = __colors__[idx %% len(__colors__)]'#10 +
      '    __datasets__.append({'#10 +
      '        "label": col,'#10 +
      '        "data": [float(v) for v in %s[col]],'#10 +
      '        "borderColor": c,'#10 +
      '        "backgroundColor": c + "33",'#10 +
      '        "tension": 0.3'#10 +
      '    })'#10 +
      '__chart_payload__ = json.dumps({"labels": __x_labels__, "datasets": __datasets__})',
      [FVarName, EscapeStr(AXCol), ColsList, FVarName]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'line', ChartJson);
end;

procedure TPyDataFrame.PlotPie(const ATitle, ALabelCol, AValueCol: string);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__x_labels__ = [str(x) for x in %s["%s"]]'#10 +
      '__y_values__ = [float(x) for x in %s["%s"]]'#10 +
      '__colors__ = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899", "#84cc16", "#14b8a6", "#f97316", "#6366f1", "#a855f7"]'#10 +
      '__bg_colors__ = [__colors__[i %% len(__colors__)] for i in range(len(__x_labels__))]'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "labels": __x_labels__,'#10 +
      '  "datasets": [{'#10 +
      '    "label": "%s",'#10 +
      '    "data": __y_values__,'#10 +
      '    "backgroundColor": __bg_colors__,'#10 +
      '    "hoverOffset": 6'#10 +
      '  }]'#10 +
      '})',
      [FVarName, EscapeStr(ALabelCol), FVarName, EscapeStr(AValueCol), EscapeStr(ATitle)]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'pie', ChartJson);
end;

procedure TPyDataFrame.PlotDoughnut(const ATitle, ALabelCol, AValueCol: string);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__x_labels__ = [str(x) for x in %s["%s"]]'#10 +
      '__y_values__ = [float(x) for x in %s["%s"]]'#10 +
      '__colors__ = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899", "#84cc16", "#14b8a6", "#f97316", "#6366f1", "#a855f7"]'#10 +
      '__bg_colors__ = [__colors__[i %% len(__colors__)] for i in range(len(__x_labels__))]'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "labels": __x_labels__,'#10 +
      '  "datasets": [{'#10 +
      '    "label": "%s",'#10 +
      '    "data": __y_values__,'#10 +
      '    "backgroundColor": __bg_colors__,'#10 +
      '    "hoverOffset": 6'#10 +
      '  }]'#10 +
      '})',
      [FVarName, EscapeStr(ALabelCol), FVarName, EscapeStr(AValueCol), EscapeStr(ATitle)]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'doughnut', ChartJson);
end;

procedure TPyDataFrame.PlotHistogram(const ATitle, ACol: string; ABins: Integer);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__vals__ = %s["%s"].dropna().astype(float)'#10 +
      '__counts__, __bin_edges__ = np.histogram(__vals__, bins=%d)'#10 +
      '__labels__ = [f"{__bin_edges__[i]:.1f} - {__bin_edges__[i+1]:.1f}" for i in range(len(__counts__))]'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "labels": __labels__,'#10 +
      '  "datasets": [{'#10 +
      '    "label": "%s (Frequency)",'#10 +
      '    "data": [int(c) for c in __counts__],'#10 +
      '    "backgroundColor": "rgba(59, 130, 246, 0.75)",'#10 +
      '    "borderColor": "#2563eb",'#10 +
      '    "borderWidth": 1.5,'#10 +
      '    "borderRadius": 4'#10 +
      '  }]'#10 +
      '})',
      [FVarName, EscapeStr(ACol), ABins, EscapeStr(ATitle)]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'bar', ChartJson);
end;

procedure TPyDataFrame.PlotBoxPlot(const ATitle, ACategoryCol, AValueCol: string);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__cats__ = [str(c) for c in %s["%s"].unique()]'#10 +
      '__min_vals__, __q1_vals__, __med_vals__, __q3_vals__, __max_vals__ = [], [], [], [], []'#10 +
      'for c in __cats__:'#10 +
      '    sub = %s[%s["%s"] == c]["%s"].dropna().astype(float)'#10 +
      '    if len(sub) > 0:'#10 +
      '        __min_vals__.append(float(sub.min()))'#10 +
      '        __q1_vals__.append(float(sub.quantile(0.25)))'#10 +
      '        __med_vals__.append(float(sub.median()))'#10 +
      '        __q3_vals__.append(float(sub.quantile(0.75)))'#10 +
      '        __max_vals__.append(float(sub.max()))'#10 +
      '    else:'#10 +
      '        __min_vals__.append(0.0)'#10 +
      '        __q1_vals__.append(0.0)'#10 +
      '        __med_vals__.append(0.0)'#10 +
      '        __q3_vals__.append(0.0)'#10 +
      '        __max_vals__.append(0.0)'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "labels": __cats__,'#10 +
      '  "datasets": ['#10 +
      '    {"label": "Min", "data": __min_vals__, "backgroundColor": "#94a3b8"},'#10 +
      '    {"label": "Q1 (25%%)", "data": __q1_vals__, "backgroundColor": "#60a5fa"},'#10 +
      '    {"label": "Median", "data": __med_vals__, "backgroundColor": "#10b981"},'#10 +
      '    {"label": "Q3 (75%%)", "data": __q3_vals__, "backgroundColor": "#f59e0b"},'#10 +
      '    {"label": "Max", "data": __max_vals__, "backgroundColor": "#ef4444"}'#10 +
      '  ]'#10 +
      '})',
      [FVarName, EscapeStr(ACategoryCol), FVarName, FVarName, EscapeStr(ACategoryCol), EscapeStr(AValueCol)]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'bar', ChartJson);
end;

function TPyDataFrame.Filter(const AExpression: string): TPyDataFrame;
var
  NewVar, EscExpr: string;
begin
  NewVar := NewPyVar('df_filtered');
  EscExpr := StringReplace(AExpression, '"', '\"', [rfReplaceAll]);
  TBlaisePy.Exec(Format('%s = %s.query("%s").copy()', [NewVar, FVarName, EscExpr]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.SortBy(const AColName: string; Ascending: Boolean): TPyDataFrame;
var
  NewVar, AscStr: string;
begin
  NewVar := NewPyVar('df_sorted');
  if Ascending then AscStr := 'True' else AscStr := 'False';
  TBlaisePy.Exec(Format('%s = %s.sort_values(by="%s", ascending=%s).copy()',
    [NewVar, FVarName, EscapeStr(AColName), AscStr]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.SortBy(const AColNames: array of string; Ascending: Boolean): TPyDataFrame;
var
  NewVar, AscStr, ColsList: string;
  i: Integer;
begin
  NewVar := NewPyVar('df_sorted');
  if Ascending then AscStr := 'True' else AscStr := 'False';
  ColsList := '[';
  for i := 0 to High(AColNames) do
  begin
    if i > 0 then ColsList := ColsList + ', ';
    ColsList := ColsList + '"' + EscapeStr(AColNames[i]) + '"';
  end;
  ColsList := ColsList + ']';
  TBlaisePy.Exec(Format('%s = %s.sort_values(by=%s, ascending=%s).copy()',
    [NewVar, FVarName, ColsList, AscStr]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.DropColumns(const AColNames: array of string): TPyDataFrame;
var
  NewVar, ColsList: string;
  i: Integer;
begin
  NewVar := NewPyVar('df_dropped');
  ColsList := '[';
  for i := 0 to High(AColNames) do
  begin
    if i > 0 then ColsList := ColsList + ', ';
    ColsList := ColsList + '"' + EscapeStr(AColNames[i]) + '"';
  end;
  ColsList := ColsList + ']';
  TBlaisePy.Exec(Format('%s = %s.drop(columns=%s, errors="ignore").copy()',
    [NewVar, FVarName, ColsList]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.DropNA: TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_clean');
  TBlaisePy.Exec(Format('%s = %s.dropna().copy()', [NewVar, FVarName]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.DropNA(const ASubsetCols: array of string): TPyDataFrame;
var
  NewVar, ColsList: string;
  i: Integer;
begin
  NewVar := NewPyVar('df_clean');
  ColsList := '[';
  for i := 0 to High(ASubsetCols) do
  begin
    if i > 0 then ColsList := ColsList + ', ';
    ColsList := ColsList + '"' + EscapeStr(ASubsetCols[i]) + '"';
  end;
  ColsList := ColsList + ']';
  TBlaisePy.Exec(Format('%s = %s.dropna(subset=%s).copy()', [NewVar, FVarName, ColsList]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyDataFrame.GroupBy(const AColName: string): TPyGroupBy;
begin
  Result := TPyGroupBy.Create(FVarName, AColName);
end;

{ TPyGroupBy }

constructor TPyGroupBy.Create(const ADFVarName, AGroupCol: string);
begin
  inherited Create;
  FDFVarName := ADFVarName;
  FGroupCol := AGroupCol;
end;

function TPyGroupBy.EscapeStr(const S: string): string;
begin
  Result := StringReplace(S, '"', '\"', [rfReplaceAll]);
end;

function TPyGroupBy.Mean: TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_mean');
  TBlaisePy.Exec(Format('%s = %s.groupby("%s", as_index=False).mean(numeric_only=True)',
    [NewVar, FDFVarName, EscapeStr(FGroupCol)]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyGroupBy.Sum: TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_sum');
  TBlaisePy.Exec(Format('%s = %s.groupby("%s", as_index=False).sum(numeric_only=True)',
    [NewVar, FDFVarName, EscapeStr(FGroupCol)]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyGroupBy.Count: TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_count');
  TBlaisePy.Exec(Format('%s = %s.groupby("%s", as_index=False).count()',
    [NewVar, FDFVarName, EscapeStr(FGroupCol)]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyGroupBy.Min: TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_min');
  TBlaisePy.Exec(Format('%s = %s.groupby("%s", as_index=False).min(numeric_only=True)',
    [NewVar, FDFVarName, EscapeStr(FGroupCol)]));
  Result := TPyDataFrame.Create(NewVar);
end;

function TPyGroupBy.Max: TPyDataFrame;
var
  NewVar: string;
begin
  NewVar := NewPyVar('df_max');
  TBlaisePy.Exec(Format('%s = %s.groupby("%s", as_index=False).max(numeric_only=True)',
    [NewVar, FDFVarName, EscapeStr(FGroupCol)]));
  Result := TPyDataFrame.Create(NewVar);
end;


procedure TPyDataFrame.PlotBar(const ATitle, AXCol, AYCol: string);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__x_labels__ = [str(x) for x in %s["%s"]]'#10 +
      '__y_values__ = [float(x) for x in %s["%s"]]'#10 +
      '__colors__ = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899"]'#10 +
      '__bar_colors__ = [__colors__[i %% len(__colors__)] for i in range(len(__x_labels__))]'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "labels": __x_labels__,'#10 +
      '  "datasets": [{'#10 +
      '    "label": "%s",'#10 +
      '    "data": __y_values__,'#10 +
      '    "backgroundColor": __bar_colors__,'#10 +
      '    "borderRadius": 6'#10 +
      '  }]'#10 +
      '})',
      [FVarName, EscapeStr(AXCol), FVarName, EscapeStr(AYCol), EscapeStr(ATitle)]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'bar', ChartJson);
end;

procedure TPyDataFrame.PlotBar(const ATitle, AXCol: string; const AYCols: array of string);
var
  PyHelper, ChartJson: string;
  ColsList: string;
  i: Integer;
begin
  ColsList := '[';
  for i := 0 to High(AYCols) do
  begin
    if i > 0 then ColsList := ColsList + ', ';
    ColsList := ColsList + '"' + EscapeStr(AYCols[i]) + '"';
  end;
  ColsList := ColsList + ']';

  PyHelper :=
    Format(
      '__x_labels__ = [str(x) for x in %s["%s"]]'#10 +
      '__datasets__ = []'#10 +
      '__y_cols__ = %s'#10 +
      '__colors__ = ["#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#8b5cf6", "#06b6d4", "#ec4899"]'#10 +
      'for idx, col in enumerate(__y_cols__):'#10 +
      '    c = __colors__[idx %% len(__colors__)]'#10 +
      '    __datasets__.append({'#10 +
      '        "label": col,'#10 +
      '        "data": [float(v) for v in %s[col]],'#10 +
      '        "backgroundColor": c,'#10 +
      '        "borderColor": c'#10 +
      '    })'#10 +
      '__chart_payload__ = json.dumps({"labels": __x_labels__, "datasets": __datasets__})',
      [FVarName, EscapeStr(AXCol), ColsList, FVarName]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'bar', ChartJson);
end;

procedure TPyDataFrame.PlotScatter(const ATitle, AXCol, AYCol: string);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__scatter_points__ = [{"x": float(row["%s"]), "y": float(row["%s"])} for _, row in %s.iterrows()]'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "datasets": [{'#10 +
      '    "label": "%s",'#10 +
      '    "data": __scatter_points__,'#10 +
      '    "backgroundColor": "#3b82f6"'#10 +
      '  }]'#10 +
      '})',
      [EscapeStr(AXCol), EscapeStr(AYCol), FVarName, ATitle]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'scatter', ChartJson);
end;

procedure TPyDataFrame.PlotArea(const ATitle, AXCol, AYCol: string);
var
  PyHelper, ChartJson: string;
begin
  PyHelper :=
    Format(
      '__x_labels__ = [str(x) for x in %s["%s"]]'#10 +
      '__y_values__ = [float(x) for x in %s["%s"]]'#10 +
      '__chart_payload__ = json.dumps({'#10 +
      '  "labels": __x_labels__,'#10 +
      '  "datasets": [{'#10 +
      '    "label": "%s",'#10 +
      '    "data": __y_values__,'#10 +
      '    "fill": True,'#10 +
      '    "borderColor": "#10b981",'#10 +
      '    "backgroundColor": "rgba(16, 185, 129, 0.25)",'#10 +
      '    "tension": 0.3'#10 +
      '  }]'#10 +
      '})',
      [FVarName, EscapeStr(AXCol), FVarName, EscapeStr(AYCol), ATitle]);
  TBlaisePy.Exec(PyHelper);
  ChartJson := TBlaisePy.EvalStr('__chart_payload__');
  if ChartJson <> '' then
    TBlaiseOutput.ShowChart(ATitle, 'line', ChartJson);
end;

procedure TPyDataFrame.ToCSV(const AFilePath: string);
var
  SafePath: string;
begin
  SafePath := StringReplace(AFilePath, '\', '/', [rfReplaceAll]);
  TBlaisePy.Exec(
    Format(
      'import os'#10 +
      '__csv_path = "%s"'#10 +
      '__csv_dir = os.path.dirname(__csv_path)'#10 +
      'if __csv_dir and not os.path.exists(__csv_dir):'#10 +
      '    os.makedirs(__csv_dir, exist_ok=True)'#10 +
      '%s.to_csv(__csv_path, index=False)',
      [SafePath, FVarName]));
end;

procedure TPyDataFrame.Attach(const AVarName: string);
begin
  FVarName := AVarName;
end;

procedure TPyDataFrame.SaveAs(const AVarName: string);
begin
  TBlaisePy.Exec(Format('%s = %s', [AVarName, FVarName]));
  FVarName := AVarName;
end;


initialization
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  FormatSettingsUS := DefaultFormatSettings;
  FormatSettingsUS.DecimalSeparator := '.';
  FormatSettingsUS.ThousandSeparator := ',';

end.
