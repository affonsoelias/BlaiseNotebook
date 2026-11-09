unit uDataGenerator;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Math;

type
  TDoubleArray = array of Double;

{ Generates an array of linearly spaced numbers between AStart and AStop }
function GenerateLinspace(const AStart, AStop: Double; const ACount: Integer): TDoubleArray;

{ Generates an array of uniform random values between AMin and AMax }
function GenerateUniform(const ACount: Integer; const AMin, AMax: Double): TDoubleArray;

{ Generates synthetic linear regression points: Y = A * X + B + Gaussian Noise }
procedure GenerateLinearDataset(const ACount: Integer; const Slope, Intercept, NoiseStdDev: Double;
  out XValues, YValues: TDoubleArray);

implementation

function GenerateLinspace(const AStart, AStop: Double; const ACount: Integer): TDoubleArray;
var
  i: Integer;
  Step: Double;
begin
  SetLength(Result, ACount);
  if ACount <= 0 then Exit;
  if ACount = 1 then
  begin
    Result[0] := AStart;
    Exit;
  end;
  Step := (AStop - AStart) / (ACount - 1);
  for i := 0 to ACount - 1 do
    Result[i] := AStart + (i * Step);
end;

function GenerateUniform(const ACount: Integer; const AMin, AMax: Double): TDoubleArray;
var
  i: Integer;
  Range: Double;
begin
  SetLength(Result, ACount);
  Range := AMax - AMin;
  for i := 0 to ACount - 1 do
    Result[i] := AMin + (Random * Range);
end;

procedure GenerateLinearDataset(const ACount: Integer; const Slope, Intercept, NoiseStdDev: Double;
  out XValues, YValues: TDoubleArray);
var
  i: Integer;
  u1, u2, z: Double;
begin
  XValues := GenerateLinspace(0.0, 10.0, ACount);
  SetLength(YValues, ACount);
  for i := 0 to ACount - 1 do
  begin
    // Box-Muller transform for gaussian noise
    repeat
      u1 := Random;
    until u1 > 0.0000001;
    u2 := Random;
    z := Sqrt(-2.0 * Ln(u1)) * Cos(2.0 * Pi * u2);
    YValues[i] := (Slope * XValues[i]) + Intercept + (z * NoiseStdDev);
  end;
end;

end.
