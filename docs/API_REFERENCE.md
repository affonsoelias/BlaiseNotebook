# 📖 BlaiseNotebook Quick Reference & Cheat Sheet

This quick reference provides copy-pasteable snippets and descriptions of the most useful classes and functions available in **BlaiseNotebook**.

---

## 📌 Top Classes at a Glance

| Class | What it represents | Common uses |
| :--- | :--- | :--- |
| **`TPyDataFrame`** | 2D Tabular Dataset (Pandas DataFrame) | Loading CSVs, filtering columns, showing tables, plotting charts. |
| **`TPySeries`** | 1D Column / Vector (Pandas Series) | Calculating averages, medians, standard deviations, min, max. |
| **`TPyRandomForestRegressor`** | Ensemble AI Decision Trees | Predicting continuous numerical values with high accuracy. |
| **`TPyRandomForestClassifier`** | Ensemble AI Classification | Categorizing data into classes/labels. |
| **`TPyLinearRegression`** | Linear Model ($y = m \cdot x + b$) | Finding trend lines, slopes, intercepts, and $R^2$ scores. |
| **`TPyKMeans`** | Unsupervised Clustering | Grouping data points into clusters automatically. |
| **`TVector`** | High-Speed Native Pascal Array | Blazingly fast compiled math and vector operations. |

---

## 📋 Common Code Snippets

### 1. Working with DataFrames (`TPyDataFrame`)

```pascal
var
  DF: TPyDataFrame;
begin
  // Create an empty DataFrame
  DF := TPyDataFrame.Create;

  // Add columns with arrays of numbers or text
  DF.AddColumn('Product', ['Apples', 'Oranges', 'Bananas']);
  DF.AddColumn('Price',   [2.5, 3.0, 1.8]);
  DF.AddColumn('Stock',   [100, 80, 120]);

  // Load from a CSV file instead
  // DF := TPyDataFrame.FromCSV('data/my_file.csv');

  // Check rows and columns
  Writeln('Rows: ', DF.RowCount, ' | Columns: ', DF.ColumnCount);

  // Show as an interactive table in the notebook
  DF.ShowTable('Inventory', 10);

  // Plot a chart with one call
  DF.PlotBar('Stock by Product', 'Product', 'Stock');
  DF.PlotLine('Price Trend', 'Product', 'Price');

  // Export back to CSV
  DF.ToCSV('workspace/output.csv');
end;
```

---

### 2. Computing Statistics with Series (`TPySeries`)

```pascal
var
  S: TPySeries;
begin
  // Extract a column from a DataFrame
  S := DF.Column('Price');

  Writeln('Count:   ', S.Count);
  Writeln('Average: ', S.Mean:0:2);
  Writeln('StdDev:  ', S.StdDev:0:2);
  Writeln('Median:  ', S.Median:0:2);
  Writeln('Min:     ', S.Min:0:2);
  Writeln('Max:     ', S.Max:0:2);
  Writeln('Sum:     ', S.Sum:0:2);

  // Quick summary string:
  Writeln(S.Describe);
end;
```

---

### 3. Machine Learning: Random Forest

```pascal
var
  RF: TPyRandomForestRegressor;
begin
  // Create model: 30 trees, random seed 42
  RF := TPyRandomForestRegressor.Create(30, -1, 42);

  // Train the model
  RF.Fit(DF.Columns(['Feature1', 'Feature2']), DF.Column('Target'));

  // Evaluate accuracy (R² score between 0.0 and 1.0)
  Writeln('Accuracy R²: ', RF.Score(DF.Columns(['Feature1', 'Feature2']), DF.Column('Target')):0:4);

  // Predict values for new or existing features
  // PredSeries := RF.Predict(DF.Columns(['Feature1', 'Feature2']));

  // Plot feature importance bar chart
  RF.PlotFeatureImportances(['Feature1', 'Feature2'], 'Feature Impact');
end;
```

---

### 4. Machine Learning: Linear Regression

```pascal
var
  LR: TPyLinearRegression;
begin
  LR := TPyLinearRegression.Create;
  LR.Fit(DF.Column('X'), DF.Column('Y'));

  Writeln('Slope:     ', LR.Slope:0:4);
  Writeln('Intercept: ', LR.Intercept:0:4);
  Writeln('Fit R²:    ', LR.Score(DF.Column('X'), DF.Column('Y')):0:4);
  Writeln('Summary:   ', LR.Summary);
end;
```

---

### 5. High-Performance Native Math (`TVector`)

```pascal
var
  V: TVector;
begin
  // Create 100 random values between 1.0 and 50.0
  V := TVector.CreateRandom(100, 1.0, 50.0);

  Writeln('Average: ', V.CalculaMedia:0:4);
  Writeln('StdDev:  ', V.CalculaDesvioPadrao:0:4);
  Writeln('Median:  ', V.CalculaMediana:0:4);
  Writeln('Total:   ', V.Soma:0:4);
end;
```

---

### 6. Interactive Visualizations (`BlaiseOutput`)

```pascal
// Display an interactive Chart.js graph
ShowChart(
  'Monthly Visitors',
  'line', // or 'bar', 'scatter', 'pie', 'doughnut'
  '{"labels":["Jan","Feb","Mar","Apr"],"datasets":[{"label":"2026","data":[120, 190, 300, 500],"borderColor":"#3b82f6"}]}'
);

// Display a custom table
ShowTable(
  'User Registrations',
  ['ID', 'Username', 'Role'],
  '[{"ID":1,"Username":"alice","Role":"Admin"},{"ID":2,"Username":"bob","Role":"User"}]'
);
```

---

### 7. Custom Python Execution (`BlaisePyKernel`)

```pascal
// Run raw Python when needed
PyRun('import math; result = math.factorial(6)');

// Retrieve value as string
Writeln('6! is: ', PyEval('str(result)'));
```
