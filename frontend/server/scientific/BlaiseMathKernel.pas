unit BlaiseMathKernel;

{
  BlaiseMathKernel - High-Performance Native Mathematics & Statistics for Object Pascal
  Part of BlaiseNotebook Suite (Modified LGPL v2.1 with Linking Exception)
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Math, Classes;

type
  TDoubleArray = array of Double;

  { TVector: High-performance 1D numerical array }
  TVector = record
  private
    FData: TDoubleArray;
    function GetItem(Index: Integer): Double;
    procedure SetItem(Index: Integer; const Value: Double);
    function GetCount: Integer;
  public
    class function Create(const AValues: array of Double): TVector; static;
    class function CreateRandom(ACount: Integer; AMin: Double = 0.0; AMax: Double = 1.0): TVector; static;
    class function CreateLinear(ACount: Integer; AStart: Double; AStep: Double): TVector; static;

    function Soma: Double;
    function CalculaMedia: Double;
    function CalculaVariancia: Double;
    function CalculaDesvioPadrao: Double;
    function CalculaMediana: Double;
    function CalculaMinimo: Double;
    function CalculaMaximo: Double;

    function LinearRegression(const Y: TVector; out Slope, Intercept, R2: Double): Boolean;
    function ToJson: string;

    property Items[Index: Integer]: Double read GetItem write SetItem; default;
    property Count: Integer read GetCount;
    property Data: TDoubleArray read FData write FData;
  end;

implementation

{ TVector }

function TVector.GetItem(Index: Integer): Double;
begin
  Result := FData[Index];
end;

procedure TVector.SetItem(Index: Integer; const Value: Double);
begin
  FData[Index] := Value;
end;

function TVector.GetCount: Integer;
begin
  Result := Length(FData);
end;

class function TVector.Create(const AValues: array of Double): TVector;
var
  i: Integer;
begin
  SetLength(Result.FData, Length(AValues));
  for i := 0 to High(AValues) do
    Result.FData[i] := AValues[i];
end;

class function TVector.CreateRandom(ACount: Integer; AMin, AMax: Double): TVector;
var
  i: Integer;
begin
  SetLength(Result.FData, ACount);
  Randomize;
  for i := 0 to ACount - 1 do
    Result.FData[i] := AMin + Random * (AMax - AMin);
end;

class function TVector.CreateLinear(ACount: Integer; AStart, AStep: Double): TVector;
var
  i: Integer;
begin
  SetLength(Result.FData, ACount);
  for i := 0 to ACount - 1 do
    Result.FData[i] := AStart + (i * AStep);
end;

function TVector.Soma: Double;
var
  i: Integer;
begin
  Result := 0.0;
  for i := 0 to High(FData) do
    Result := Result + FData[i];
end;

function TVector.CalculaMedia: Double;
begin
  if Length(FData) = 0 then Exit(0.0);
  Result := Soma / Length(FData);
end;

function TVector.CalculaVariancia: Double;
var
  M, DiffSum: Double;
  i: Integer;
begin
  if Length(FData) <= 1 then Exit(0.0);
  M := CalculaMedia;
  DiffSum := 0.0;
  for i := 0 to High(FData) do
    DiffSum := DiffSum + Sqr(FData[i] - M);
  Result := DiffSum / (Length(FData) - 1);
end;

function TVector.CalculaDesvioPadrao: Double;
begin
  Result := Sqrt(CalculaVariancia);
end;

function TVector.CalculaMediana: Double;
var
  Sorted: TDoubleArray;
  i, j, N, Mid: Integer;
  Tmp: Double;
begin
  N := Length(FData);
  if N = 0 then Exit(0.0);

  SetLength(Sorted, N);
  for i := 0 to N - 1 do
    Sorted[i] := FData[i];

  // Simple insertion sort
  for i := 1 to N - 1 do
  begin
    Tmp := Sorted[i];
    j := i - 1;
    while (j >= 0) and (Sorted[j] > Tmp) do
    begin
      Sorted[j + 1] := Sorted[j];
      Dec(j);
    end;
    Sorted[j + 1] := Tmp;
  end;

  Mid := N div 2;
  if Odd(N) then
    Result := Sorted[Mid]
  else
    Result := (Sorted[Mid - 1] + Sorted[Mid]) / 2.0;
end;

function TVector.CalculaMinimo: Double;
var
  i: Integer;
begin
  if Length(FData) = 0 then Exit(0.0);
  Result := FData[0];
  for i := 1 to High(FData) do
    if FData[i] < Result then Result := FData[i];
end;

function TVector.CalculaMaximo: Double;
var
  i: Integer;
begin
  if Length(FData) = 0 then Exit(0.0);
  Result := FData[0];
  for i := 1 to High(FData) do
    if FData[i] > Result then Result := FData[i];
end;

function TVector.LinearRegression(const Y: TVector; out Slope, Intercept, R2: Double): Boolean;
var
  N, i: Integer;
  SumX, SumY, SumXY, SumX2, SumY2: Double;
  MeanX, MeanY, SS_tot, SS_res, YPred: Double;
begin
  N := Length(FData);
  if (N <= 1) or (N <> Length(Y.FData)) then
  begin
    Slope := 0; Intercept := 0; R2 := 0;
    Exit(False);
  end;

  SumX := 0; SumY := 0; SumXY := 0; SumX2 := 0; SumY2 := 0;
  for i := 0 to N - 1 do
  begin
    SumX := SumX + FData[i];
    SumY := SumY + Y.FData[i];
    SumXY := SumXY + (FData[i] * Y.FData[i]);
    SumX2 := SumX2 + Sqr(FData[i]);
    SumY2 := SumY2 + Sqr(Y.FData[i]);
  end;

  Slope := (N * SumXY - SumX * SumY) / (N * SumX2 - Sqr(SumX));
  Intercept := (SumY - Slope * SumX) / N;

  // Compute R2 (Coefficient of Determination)
  MeanY := SumY / N;
  SS_tot := 0;
  SS_res := 0;
  for i := 0 to N - 1 do
  begin
    SS_tot := SS_tot + Sqr(Y.FData[i] - MeanY);
    YPred := Slope * FData[i] + Intercept;
    SS_res := SS_res + Sqr(Y.FData[i] - YPred);
  end;

  if SS_tot > 0 then
    R2 := 1.0 - (SS_res / SS_tot)
  else
    R2 := 1.0;

  Result := True;
end;

function TVector.ToJson: string;
var
  i: Integer;
begin
  Result := '[';
  for i := 0 to High(FData) do
  begin
    if i > 0 then Result := Result + ',';
    Result := Result + FloatToStrF(FData[i], ffFixed, 7, 4);
  end;
  Result := Result + ']';
end;

end.
