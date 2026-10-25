unit BlaiseOutput;

{
  BlaiseOutput - Interactive Output Protocol for BlaiseNotebook
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)
  
  Allows Object Pascal scripts executing in a cell to emit structured outputs
  (rich data tables, Chart.js visual configurations) directly to
  the BlaiseVue frontend via JSON magic stream delimiters.
}

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes;

const
  BLAISE_PAYLOAD_TAG = '@@BLAISE_PAYLOAD@@:';

type
  TBlaiseOutput = class
  public
    class procedure Print(const S: string);
    class procedure ShowTable(const ATitle: string; const AColumns: array of string; const ARowsJson: string);
    class procedure ShowChart(const ATitle, AChartType, ADataJson: string; const AOptionsJson: string = '{}');
  end;

// Global helper procedures for intuitive cell scripts
procedure ShowTable(const ATitle: string; const AColumns: array of string; const ARowsJson: string);
procedure ShowChart(const ATitle, AChartType, ADataJson: string; const AOptionsJson: string = '{}');

implementation

procedure ShowTable(const ATitle: string; const AColumns: array of string; const ARowsJson: string);
begin
  TBlaiseOutput.ShowTable(ATitle, AColumns, ARowsJson);
end;

procedure ShowChart(const ATitle, AChartType, ADataJson: string; const AOptionsJson: string);
begin
  TBlaiseOutput.ShowChart(ATitle, AChartType, ADataJson, AOptionsJson);
end;

{ TBlaiseOutput }

class procedure TBlaiseOutput.Print(const S: string);
begin
  WriteLn(S);
  Flush(Output);
end;

class procedure TBlaiseOutput.ShowTable(const ATitle: string; const AColumns: array of string; const ARowsJson: string);
var
  ColsJson: string;
  i: Integer;
  Payload: string;
begin
  ColsJson := '[';
  for i := 0 to High(AColumns) do
  begin
    if i > 0 then ColsJson := ColsJson + ',';
    ColsJson := ColsJson + '"' + AColumns[i] + '"';
  end;
  ColsJson := ColsJson + ']';

  Payload := Format('{"type":"table","title":"%s","columns":%s,"rows":%s}',
    [ATitle, ColsJson, ARowsJson]);

  WriteLn(BLAISE_PAYLOAD_TAG + Payload);
  Flush(Output);
end;

class procedure TBlaiseOutput.ShowChart(const ATitle, AChartType, ADataJson: string; const AOptionsJson: string);
var
  Opt: string;
  Payload: string;
begin
  Opt := AOptionsJson;
  if Trim(Opt) = '' then Opt := '{}';

  Payload := Format('{"type":"chart","title":"%s","chartType":"%s","data":%s,"options":%s}',
    [ATitle, AChartType, ADataJson, Opt]);

  WriteLn(BLAISE_PAYLOAD_TAG + Payload);
  Flush(Output);
end;

end.
