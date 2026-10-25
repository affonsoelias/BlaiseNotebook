# 🔬 Scientific Computing & Data Science in BlaiseNotebook

BlaiseNotebook offers a dual-engine architecture:
1. **Native Object Pascal High-Performance Engine (`BlaiseMathKernel.pas`):** Compiled numerical algorithms, descriptive statistics, and linear regression executing with zero memory overhead.
2. **Python Scientific Stack Bridge (`BlaisePyKernel.pas`):** Transparent CPython API integration providing direct access to **NumPy**, **Pandas**, and **Scikit-learn** from your Pascal notebook cells.
3. **Reactive In-Cell Visualizations (`BlaiseOutput.pas`):** Real-time interactive charting with Chart.js (`<bv-chart>`) and scrollable data tables rendered directly below the executed code.

---

## 1. Native Pascal Engine (`BlaiseMathKernel`)

The `BlaiseMathKernel` unit provides native numerical algorithms compiled directly by Free Pascal.

### The `TVector` Type

`TVector` is a high-performance scientific record representing a 1D array of `Double` values with built-in mathematical methods:

```pascal
var
  V: TVector;
  Mean, StdDev, Median: Double;
begin
  // Create a random vector with 100 observations between 10.0 and 50.0
  V := TVector.CreateRandom(100, 10.0, 50.0);

  // Compute descriptive statistics
  Mean := V.CalculaMedia;
  StdDev := V.CalculaDesvioPadrao;
  Median := V.CalculaMediana;

  Writeln(Format('Vector Count: %d', [V.Count]));
  Writeln(Format('Sample Mean: %.4f', [Mean]));
  Writeln(Format('Std Deviation: %.4f', [StdDev]));
  Writeln(Format('Median: %.4f', [Median]));
end;
```

#### Supported `TVector` Operations:
- `Create(const Arr: array of Double)`
- `CreateRandom(Count: Integer; MinVal, MaxVal: Double)`
- `CalculaMedia: Double` (Sample Mean $\mu$)
- `CalculaVariancia: Double` (Sample Variance $\sigma^2$)
- `CalculaDesvioPadrao: Double` (Standard Deviation $\sigma$)
- `CalculaMediana: Double` (Sample Median)
- `Soma: Double` (Sum of all elements)
- `Min: Double` and `Max: Double`
- `Normalizar: TVector` (Min-Max normalization to range $[0, 1]$)
- `DotProduct(const Other: TVector): Double` (Scalar dot product)

### Linear Regression (`TLinearRegression`)

Fit linear trends ($y = m \cdot x + b$) and compute the coefficient of determination ($R^2$):

```pascal
var
  X, Y: TVector;
  Reg: TLinearRegression;
  PredictedY: Double;
begin
  X := TVector.Create([1.0, 2.0, 3.0, 4.0, 5.0]);
  Y := TVector.Create([2.1, 3.9, 6.2, 8.1, 9.9]);

  Reg := TLinearRegression.Fit(X, Y);

  Writeln(Format('Slope (m): %.4f', [Reg.Slope]));
  Writeln(Format('Intercept (b): %.4f', [Reg.Intercept]));
  Writeln(Format('Determination (R²): %.4f', [Reg.RSquared]));

  PredictedY := Reg.Predict(6.0);
  Writeln(Format('Predicted Y for X=6.0: %.2f', [PredictedY]));
end;
```

---

## 2. In-Cell Visualizations with Chart.js (`BlaiseOutput`)

The `BlaiseOutput` unit interfaces the compiled Pascal binary with the BlaiseVue frontend via the `@@BLAISE_PAYLOAD@@:` protocol.

### `ShowChart`
Renders an interactive canvas chart using Chart.js directly beneath the active code cell:

```pascal
ShowChart(
  'Monthly Revenue Comparison', // Chart Title
  'bar',                        // Chart Type: 'line', 'bar', 'scatter', 'radar', 'pie', 'doughnut'
  '{"labels":["Jan","Feb","Mar","Apr","May","Jun"],' +
  '"datasets":[' +
  '  {"label":"2025","data":[65, 59, 80, 81, 56, 55],"backgroundColor":"#3b82f6"},' +
  '  {"label":"2026","data":[78, 72, 94, 99, 74, 85],"backgroundColor":"#10b981"}' +
  ']}'
);
```

### `ShowTable`
Outputs a responsive, scrollable data table:

```pascal
ShowTable(
  'Employee Performance Dataset',
  '["ID", "Name", "Department", "Rating", "Score"]',
  '[' +
  '  ["#101", "Alice Smith", "Research", "Exceeds", "98.5"],' +
  '  ["#102", "Bob Miller", "Engineering", "Meets", "88.2"],' +
  '  ["#103", "Carol White", "Data Science", "Exceeds", "95.0"]' +
  ']'
);
```

---

## 3. Python Scientific Stack Bridge (`BlaisePyKernel`)

Through the `BlaisePyKernel` unit, Pascal developers can invoke CPython 3.10–3.13 packages like **NumPy**, **Pandas**, and **Scikit-learn**.

### Executing Python Scripts from Pascal

```pascal
var
  Script: string;
begin
  Script :=
    'import pandas as pd'#10 +
    'import numpy as np'#10 +
    'np.random.seed(42)'#10 +
    'data = {"X": np.linspace(0, 10, 20), "Y": np.sin(np.linspace(0, 10, 20))}'#10 +
    'df = pd.DataFrame(data)'#10 +
    'print("Dataframe shape:", df.shape)';

  PyRun(Script);
end;
```

### Displaying a Pandas DataFrame in the Notebook

The `ShowPyDataFrame` helper converts any active Pandas DataFrame variable in Python into an interactive notebook table:

```pascal
// Displays up to 10 rows of the 'df' DataFrame
ShowPyDataFrame('df', 'Sine Wave Simulation Data', 10);
```

### Plotting Python Results Directly with Chart.js

```pascal
var
  PyMLScript: string;
begin
  PyMLScript :=
    'from sklearn.ensemble import RandomForestRegressor'#10 +
    'import numpy as np'#10 +
    'X = np.array([[1], [2], [3], [4], [5], [6], [7], [8]])'#10 +
    'y = np.array([1.5, 3.7, 5.2, 7.8, 9.1, 11.4, 13.9, 15.8])'#10 +
    'model = RandomForestRegressor(n_estimators=50, random_state=42)'#10 +
    'model.fit(X, y)'#10 +
    'y_pred = model.predict(X).tolist()'#10 +
    'print("Random Forest Training Complete! Score:", model.score(X, y))';

  PyRun(PyMLScript);

  // Plot actual vs predicted values with a native Chart.js line graph
  ShowChart(
    'Scikit-Learn Random Forest Regression Fit',
    'line',
    '{"labels":["#1","#2","#3","#4","#5","#6","#7","#8"],' +
    '"datasets":[' +
    '  {"label":"Ground Truth","data":[1.5,3.7,5.2,7.8,9.1,11.4,13.9,15.8],"borderColor":"#3b82f6","fill":false},' +
    '  {"label":"Random Forest Fit","data":[1.8,3.5,5.6,7.4,9.3,11.2,13.6,15.5],"borderColor":"#10b981","borderDash":[5,5],"fill":false}' +
    ']}'
  );
end;
```
