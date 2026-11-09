# 🛠️ Official Data Generator Tool (`data_generator`)

Auxiliary tool for BlaiseNotebook to synthesize datasets, linspace vectors, uniform distributions, and linear regression points with gaussian noise.

## Quick Usage in Notebook

```pascal
uses
  BlaiseOutput,
  uDataGenerator;

var
  X, Y: TDoubleArray;
  i: Integer;
begin
  GenerateLinearDataset(10, 2.5, 4.0, 0.5, X, Y);
  for i := 0 to High(X) do
    Writeln('Point ', i + 1, ': X = ', X[i]:0:2, ' => Y = ', Y[i]:0:2);
end;
```
