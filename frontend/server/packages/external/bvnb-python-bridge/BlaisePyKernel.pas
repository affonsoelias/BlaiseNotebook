unit BlaisePyKernel;

{
  BlaisePyKernel - Cross-Platform Native Python Bridge for BlaiseNotebook
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)

  Provides zero-dependency interoperability between Object Pascal and Python:
  - Persistent Session Daemon (CPython 3.10+) via native HTTP/JSON (TFPHttpClient)
  - 100% Cross-Platform (Windows, Linux, macOS) — no Python4Lazarus / DLL required
  - Bridges NumPy, Pandas, and Scikit-learn into BlaiseNotebook cells
  - Exclusively emits interactive Chart.js (<bv-chart>) configurations and responsive tables
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, Math,
  fphttpclient, fpjson, jsonparser,
  BlaiseOutput;

type
  { TBlaisePy - Static manager for the Python persistent session daemon }
  TBlaisePy = class
  private
    class var FUseDaemon: Boolean;
    class var FDaemonChecked: Boolean;
    class var FDaemonUrl: string;
    class function CheckDaemon: Boolean;
    class function PostDaemonJson(const AEndpoint, AJson: string): string;
  public
    class procedure Init(const ADllPath: string = ''; const ADllName: string = '');
    class procedure Finalize;
    class function Exec(const ACode: string): Boolean;
    class function EvalStr(const AExpr: string): string;
    class procedure ResetSession;

    // Direct Daemon control
    class property UseDaemon: Boolean read FUseDaemon write FUseDaemon;
    class property DaemonUrl: string read FDaemonUrl write FDaemonUrl;

    // Visualization bridges directly to BlaiseVue Chart.js (<bv-chart>) and data tables
    class procedure ShowDataFrame(const AVarName: string; const ATitle: string = 'Pandas DataFrame'; AMaxRows: Integer = 50);
    class procedure ShowSeriesChart(const AVarName: string; const ATitle: string = 'Chart.js Plot'; const AChartType: string = 'line');
    class procedure ShowDataFrameChart(const AVarName: string; const AXCol, AYCol: string; const ATitle: string = 'Chart.js Plot'; const AChartType: string = 'line');
  end;

// Convenience global routines for notebook cells
procedure PyRun(const ACode: string);
function PyEval(const AExpr: string): string;
procedure PyReset;
procedure ShowPyDataFrame(const AVarName: string; const ATitle: string = 'Pandas DataFrame'; AMaxRows: Integer = 50);
procedure ShowPySeriesChart(const AVarName: string; const ATitle: string = 'Chart.js Plot'; const AChartType: string = 'line');
procedure ShowPyDataFrameChart(const AVarName: string; const AXCol, AYCol: string; const ATitle: string = 'Chart.js Plot'; const AChartType: string = 'line');

implementation

function EscapeJson(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: ; // skip carriage return
    else
      Result := Result + S[i];
    end;
  end;
end;

{ TBlaisePy }

class function TBlaisePy.CheckDaemon: Boolean;
var
  Client: TFPHttpClient;
  Resp: string;
begin
  if FDaemonChecked and FUseDaemon then
  begin
    Result := True;
    Exit;
  end;

  FDaemonChecked := True;
  FUseDaemon := False;
  if FDaemonUrl = '' then
  begin
    FDaemonUrl := GetEnvironmentVariable('BLAISE_PY_DAEMON_URL');
    if FDaemonUrl = '' then
      FDaemonUrl := 'http://127.0.0.1:9099';
  end;

  Client := TFPHttpClient.Create(nil);
  try
    try
      Client.IOTimeout := 1200;
      Resp := Client.Get(FDaemonUrl + '/ping');
      if Pos('"status": "ok"', Resp) > 0 then
        FUseDaemon := True;
    except
      FUseDaemon := False;
    end;
  finally
    Client.Free;
  end;
  Result := FUseDaemon;
end;

class function TBlaisePy.PostDaemonJson(const AEndpoint, AJson: string): string;
var
  Client: TFPHttpClient;
  Stream: TStringStream;
begin
  Result := '';
  Client := TFPHttpClient.Create(nil);
  Stream := TStringStream.Create(AJson);
  try
    Client.IOTimeout := 30000;
    Client.AddHeader('Content-Type', 'application/json');
    Client.RequestBody := Stream;
    Result := Client.Post(FDaemonUrl + AEndpoint);
  finally
    Stream.Free;
    Client.Free;
  end;
end;

class procedure TBlaisePy.ResetSession;
begin
  if CheckDaemon then
  begin
    try
      PostDaemonJson('/reset', '{}');
    except
    end;
  end;
end;

class procedure TBlaisePy.Init(const ADllPath: string; const ADllName: string);
begin
  // Maintained for backward compatibility; checks daemon readiness
  CheckDaemon;
end;

class procedure TBlaisePy.Finalize;
begin
  // Session state persists in the external Python daemon
end;

class function TBlaisePy.Exec(const ACode: string): Boolean;
var
  Resp, StdOutText, StdErrText, ErrText: string;
  Data: TJSONData;
  Obj: TJSONObject;
begin
  Result := False;

  if not CheckDaemon then
  begin
    WriteLn('[BlaisePyKernel] Error: Python daemon (port 9099) did not respond. Verify Python 3 is installed (run "bvnb doctor").');
    Flush(Output);
    Exit;
  end;

  try
    Resp := PostDaemonJson('/exec', '{"code":"' + EscapeJson(ACode) + '"}');
    if Resp <> '' then
    begin
      Data := GetJSON(Resp);
      try
        if Data is TJSONObject then
        begin
          Obj := TJSONObject(Data);
          StdOutText := Obj.Get('stdout', '');
          StdErrText := Obj.Get('stderr', '');
          ErrText := Obj.Get('error', '');

          if StdOutText <> '' then
          begin
            Write(StdOutText);
            Flush(Output);
          end;

          if StdErrText <> '' then
          begin
            Write(StdErrText);
            Flush(StdErr);
          end;

          if ErrText <> '' then
          begin
            WriteLn('[Python Error] ' + ErrText);
            Flush(Output);
            Result := False;
          end
          else
            Result := (Obj.Get('status', '') = 'ok');
        end;
      finally
        Data.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      WriteLn('[BlaisePyKernel] Communication error with Python daemon: ' + E.Message);
      Flush(Output);
      Result := False;
    end;
  end;
end;

class function TBlaisePy.EvalStr(const AExpr: string): string;
var
  Resp: string;
  Data: TJSONData;
  Obj: TJSONObject;
begin
  Result := '';

  if not CheckDaemon then Exit;

  try
    Resp := PostDaemonJson('/eval', '{"expr":"' + EscapeJson(AExpr) + '"}');
    if Resp <> '' then
    begin
      Data := GetJSON(Resp);
      try
        if Data is TJSONObject then
        begin
          Obj := TJSONObject(Data);
          Result := Obj.Get('value', '');
        end;
      finally
        Data.Free;
      end;
    end;
  except
    on E: Exception do
      WriteLn('[Python Eval Error] ' + E.Message);
  end;
end;

class procedure TBlaisePy.ShowDataFrame(const AVarName: string; const ATitle: string; AMaxRows: Integer);
var
  PyHelper: string;
  ColsJson, RowsJson: string;
  Payload: string;
begin
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
  PyHelper :=
    Format(
      'import json'#10 +
      '__s__ = %s'#10 +
      '__c_labels__ = [str(x) for x in __s__.index]'#10 +
      '__c_values__ = [float(x) for x in __s__.values]'#10 +
      '__chart_json__ = json.dumps({'#10 +
      '  "labels": __c_labels__,'#10 +
      '  "datasets": [{"label": "%s", "data": __c_values__, "borderColor": "#3b82f6", "backgroundColor": "rgba(59, 130, 246, 0.2)", "tension": 0.3}]'#10 +
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

class procedure TBlaisePy.ShowDataFrameChart(const AVarName: string; const AXCol, AYCol: string; const ATitle: string; const AChartType: string);
var
  PyHelper: string;
  DataJson: string;
begin
  PyHelper :=
    Format(
      'import json'#10 +
      '__df__ = %s'#10 +
      '__c_labels__ = [str(x) for x in __df__["%s"]]'#10 +
      '__c_values__ = [float(x) for x in __df__["%s"]]'#10 +
      '__chart_json__ = json.dumps({'#10 +
      '  "labels": __c_labels__,'#10 +
      '  "datasets": [{"label": "%s", "data": __c_values__, "borderColor": "#10b981", "backgroundColor": "rgba(16, 185, 129, 0.2)", "tension": 0.3, "fill": True}]'#10 +
      '})'#10,
      [AVarName, AXCol, AYCol, ATitle]);

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

procedure PyReset;
begin
  TBlaisePy.ResetSession;
end;

procedure ShowPyDataFrame(const AVarName: string; const ATitle: string; AMaxRows: Integer);
begin
  TBlaisePy.ShowDataFrame(AVarName, ATitle, AMaxRows);
end;

procedure ShowPySeriesChart(const AVarName: string; const ATitle: string; const AChartType: string);
begin
  TBlaisePy.ShowSeriesChart(AVarName, ATitle, AChartType);
end;

procedure ShowPyDataFrameChart(const AVarName: string; const AXCol, AYCol: string; const ATitle: string; const AChartType: string);
begin
  TBlaisePy.ShowDataFrameChart(AVarName, AXCol, AYCol, ATitle, AChartType);
end;

initialization
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

finalization
  TBlaisePy.Finalize;

end.
