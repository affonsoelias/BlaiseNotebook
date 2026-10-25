# 🔬 Scientific Computing & Data Science in BlaiseNotebook

BlaiseNotebook features a unified scientific computing architecture designed specifically for Object Pascal:
1. **Strongly-Typed Pascal Data Science API (`BlaiseDataScience.pas`):** Object-oriented Pascal abstractions for **Pandas** and **Scikit-learn**, enabling DataFrames, machine learning models, and visualizations in 100% pure Pascal without raw Python strings.
2. **Native Object Pascal Numerical Engine (`BlaiseMathKernel.pas`):** Compiled numerical algorithms, descriptive statistics, and linear regression executing with zero memory overhead.
3. **Reactive In-Cell Visualizations (`BlaiseOutput.pas`):** Real-time interactive charting with Chart.js (`<bv-chart>`) and scrollable data tables rendered directly below the executed code.
4. **Low-Level Python Runtime Bridge (`BlaisePyKernel.pas`):** Direct CPython 3.x API execution for advanced custom scripting when needed.

---

## 1. Strongly-Typed Pascal Data Science API (`BlaiseDataScience`)

The `BlaiseDataScience` unit lets you build data pipelines and train machine learning models using familiar Pascal classes:

### Pandas DataFrames in Pure Pascal (`TPyDataFrame`)

Create DataFrames in-memory or load from CSV files:

```pascal
var
  DF: TPyDataFrame;
  HoursSeries: TPySeries;
begin
  // 1. Instantiate an in-memory DataFrame
  DF := TPyDataFrame.Create;
  DF.AddColumn('StudyHours', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]);
  DF.AddColumn('MockTests',  [1, 2, 2, 3, 3, 4, 4, 5, 5, 6]);
  DF.AddColumn('ExamScore',  [45.0, 52.0, 60.0, 68.0, 75.0, 82.0, 88.0, 91.0, 96.0, 99.0]);

  // Slicing and Series operations
  HoursSeries := DF.Column('StudyHours');
  Writeln(Format('Observations: %d, Columns: %d', [DF.RowCount, DF.ColumnCount]));
  Writeln(Format('Mean Study Hours: %.2f (StdDev: %.2f)', [HoursSeries.Mean, HoursSeries.StdDev]));

  // Display responsive interactive table directly below the cell
  DF.ShowTable('Student Exam Performance', 10);

  // Render hardware-accelerated Chart.js line graph
  DF.PlotLine('Study Hours vs Exam Score', 'StudyHours', 'ExamScore');
end;
```

#### Loading Data from CSV:
```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.FromCSV('workspace/data/sales.csv');
  DF.ShowTable('Sales Dataset', 25);
  DF.PlotBar('Revenue by Region', 'Region', 'Revenue');
end;
```

---

### Machine Learning: Random Forest Regressor (`TPyRandomForestRegressor`)

Train ensemble decision trees and predict outcomes with full hyperparameter controls:

```pascal
var
  DF: TPyDataFrame;
  RF: TPyRandomForestRegressor;
  Score: Double;
  Predictions: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Hours', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
  DF.AddColumn('Tests', [1, 2, 2, 3, 3, 4, 4, 5]);
  DF.AddColumn('Score', [50.0, 55.0, 65.0, 70.0, 80.0, 85.0, 92.0, 98.0]);

  // Create Random Forest: 30 trees, max depth unlimited (-1), random seed 42
  RF := TPyRandomForestRegressor.Create(30, -1, 42);
  RF.Fit(DF.Columns(['Hours', 'Tests']), DF.Column('Score'));

  Score := RF.Score(DF.Columns(['Hours', 'Tests']), DF.Column('Score'));
  Writeln(Format('Random Forest R² Score: %.4f', [Score]));

  // Predict values
  Predictions := RF.Predict(DF.Columns(['Hours', 'Tests']));
  Writeln('First Predicted Score: ', Predictions[0]:0:2);

  // Visualize feature importances
  RF.PlotFeatureImportances(['Hours', 'Tests'], 'Feature Importance Breakdown');
end;
```

---

### Machine Learning: Linear Regression (`TPyLinearRegression`)

Fit Ordinary Least Squares models with direct access to mathematical parameters:

```pascal
var
  DF: TPyDataFrame;
  LR: TPyLinearRegression;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Experience', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
  DF.AddColumn('SalaryK',    [42.0, 48.0, 55.0, 63.0, 72.0, 81.0, 92.0, 105.0]);

  LR := TPyLinearRegression.Create;
  LR.Fit(DF.Column('Experience'), DF.Column('SalaryK'));

  Writeln('Model: ', LR.Summary);
  Writeln(Format('Slope (Coefficient): %.4f', [LR.Slope]));
  Writeln(Format('Y-Intercept: %.4f', [LR.Intercept]));
  Writeln(Format('R² Score: %.4f', [LR.Score(DF.Column('Experience'), DF.Column('SalaryK'))]));

  DF.PlotBar('Salary (k$) by Experience', 'Experience', 'SalaryK');
end;
```

---

### Dataset Splitting (`PyTrainTestSplit`)

Split data into training and test partitions with a single call:

```pascal
var
  DF: TPyDataFrame;
  XTrain, XTest: TPyDataFrame;
  YTrain, YTest: TPySeries;
begin
  DF := TPyDataFrame.FromCSV('dataset.csv');
  PyTrainTestSplit(DF.Columns(['Feature1', 'Feature2']), DF.Column('Target'), 0.20,
    XTrain, XTest, YTrain, YTest, 42);

  Writeln(Format('Train Rows: %d | Test Rows: %d', [XTrain.RowCount, XTest.RowCount]));
end;
```

---

## 2. Native Pascal Engine (`BlaiseMathKernel`)

The `BlaiseMathKernel` unit provides native numerical algorithms compiled directly by Free Pascal.

### The `TVector` Type

`TVector` is a high-performance scientific record representing a 1D array of `Double` values:

```pascal
var
  V: TVector;
  Mean, StdDev, Median: Double;
begin
  V := TVector.CreateRandom(100, 10.0, 50.0);
  Mean := V.CalculaMedia;
  StdDev := V.CalculaDesvioPadrao;
  Median := V.CalculaMediana;

  Writeln(Format('Vector Count: %d | Mean: %.4f | StdDev: %.4f', [V.Count, Mean, StdDev]));
end;
```

---

## 3. In-Cell Visualizations (`BlaiseOutput`)

The `BlaiseOutput` unit interfaces the compiled Pascal binary with the BlaiseVue frontend via the `@@BLAISE_PAYLOAD@@:` protocol.

### `ShowChart`
Renders an interactive canvas chart using Chart.js directly beneath the active code cell:

```pascal
ShowChart(
  'Monthly Revenue Comparison',
  'bar',
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
  ['Name', 'Department', 'KPI_Score'],
  '[{"Name":"Alice","Department":"Engineering","KPI_Score":94.2},' +
  ' {"Name":"Bob","Department":"Research","KPI_Score":88.7}]'
);
```

---

## 4. Low-Level Python Bridge (`BlaisePyKernel`)

For situations where custom Python scripts or unsupported libraries are needed:

```pascal
var
  ResultStr: string;
begin
  PyRun('import math; x = math.sqrt(144)');
  ResultStr := PyEval('str(x)');
  Writeln('Evaluated from Python: ', ResultStr);
end;
```
