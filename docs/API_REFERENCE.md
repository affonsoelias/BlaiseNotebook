# 📖 BlaiseNotebook Quick Reference & Cheat Sheet

This quick reference provides copy-pasteable snippets and descriptions of the most useful classes, functions, shortcuts, and features available in **BlaiseNotebook**.

---

## 📌 Top Classes at a Glance

| Class | What it represents | Common uses |
| :--- | :--- | :--- |
| **`TPyDataFrame`** | 2D Tabular Dataset (Pandas DataFrame) | Loading CSVs, filtering columns, showing tables, plotting charts, attaching persistent daemon variables (`Attach`, `SaveAs`). |
| **`TPySeries`** | 1D Column / Vector (Pandas Series) | Calculating averages, medians, standard deviations, min, max. |
| **`TPyGroupBy`** | Fluent GroupBy Aggregator | Performing analytical aggregations (`.Mean`, `.Sum`, `.Count`, `.Min`, `.Max`). |
| **`TPyLogisticRegression`** | Logistic Regression Classification | Probability estimation and binary/multiclass categorization. |
| **`TPyDecisionTreeClassifier`** | Decision Tree Classifier | Interpretable rule-based classification and feature importance. |
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

  // Show as an interactive DataGrid Pro table in the notebook
  DF.ShowTable('Inventory', 10);

  // Plot a chart with one call
  DF.PlotBar('Stock by Product', 'Product', 'Stock');
  DF.PlotLine('Price Trend', 'Product', 'Price');

  // Persist DataFrame variable in kernel memory across cells
  DF.SaveAs('inventory_df');

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

### 3. Cross-Cell State Persistence & Python Bridge

BlaiseNotebook maintains an active, stateful Python daemon (`localhost:9099`). Variables and datasets created in one cell remain alive and available in subsequent cells!

```pascal
// --- Cell 1: Load and name the persistent variable ---
var
  RawDF: TPyDataFrame;
begin
  RawDF := TPyDataFrame.FromCSV('sales.csv');
  RawDF.SaveAs('persisted_sales'); // Registered in the Python daemon
  Writeln('Data saved to persistent memory!');
end;

// --- Cell 2: Attach and continue without reopening the file ---
var
  SalesDF: TPyDataFrame;
begin
  SalesDF := TPyDataFrame.Create;
  SalesDF.Attach('persisted_sales'); // Attaches directly to the live variable
  SalesDF.PlotBar('Sales by Region', 'Region', 'Revenue');
end;

// --- Running plain Python and retrieving results ---
PyRun('import math; custom_metric = math.sqrt(256) * 4');
Writeln('Evaluated result: ', PyEval('str(custom_metric)'));

// --- Clearing the persistent session (memory reset) ---
PyReset; // Clears user variables in the daemon
```

---

### 4. In-Notebook Package Management (`%pip` and `!pip`)

You can install or update Python packages directly from any notebook cell without leaving BlaiseNotebook or using an external terminal:

```python
%pip install seaborn xgboost openpyxl
```

Or check package information:

```python
!pip show scikit-learn
```

---

### 5. Machine Learning: Random Forest

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

### 6. Machine Learning: Linear Regression

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

### 7. High-Performance Native Math (`TVector`)

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

### 8. Interactive Visualizations (`BlaiseOutput`)

```pascal
// Display an interactive Chart.js graph
ShowChart(
  'Monthly Visitors',
  'line', // or 'bar', 'scatter', 'pie', 'doughnut'
  '{"labels":["Jan","Feb","Mar","Apr"],"datasets":[{"label":"2026","data":[120, 190, 300, 500],"borderColor":"#3b82f6"}]}'
);

// Display a custom table with DataGrid Pro
ShowTable(
  'User Registrations',
  ['ID', 'Username', 'Role'],
  '[{"ID":1,"Username":"alice","Role":"Admin"},{"ID":2,"Username":"bob","Role":"User"}]'
);
```

---

### 9. Advanced Scientific Visualizations (`TPyDataFrame`)

```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Category', ['Tech', 'Health', 'Finance', 'Energy']);
  DF.AddColumn('RevenueM', [45.2, 32.1, 58.7, 24.9]);

  // Pie & Doughnut charts
  DF.PlotPie('Revenue Share by Sector', 'Category', 'RevenueM');
  DF.PlotDoughnut('Sector Distribution', 'Category', 'RevenueM');

  // Distribution Histogram with automatic bins
  DF.PlotHistogram('Revenue Frequency Distribution', 'RevenueM', 4);

  // 5-Number Summary BoxPlot (Min, Q1, Median, Q3, Max)
  DF.PlotBoxPlot('Revenue Dispersion by Category', 'Category', 'RevenueM');
end;
```

---

### 10. Fluent Pandas-style Data Manipulation

```pascal
var
  DF, FilteredDF, SortedDF, AggDF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('City',    ['NY', 'SF', 'NY', 'SF', 'Chicago', 'Chicago']);
  DF.AddColumn('SalesK',  [120.5, 95.0, 110.2, 145.8, 80.0, 92.4]);
  DF.AddColumn('Rating',  [4.8, 4.2, 4.9, 4.7, 3.8, 4.1]);

  // Fluent filtering with query expressions
  FilteredDF := DF.Filter('Rating >= 4.2 and SalesK > 100.0');
  FilteredDF.ShowTable('Top Performing Branches', 10);

  // Sorting ascending or descending
  SortedDF := DF.SortBy('SalesK', False); // False = Descending
  SortedDF.ShowTable('Sorted by Sales (Highest First)', 10);

  // GroupBy aggregations
  AggDF := DF.GroupBy('City').Mean;
  AggDF.ShowTable('City Average Metrics', 10);
end;
```

---

### 11. Classification Models & Evaluation Metrics

```pascal
var
  DF, XTrain, XTest, CM: TPyDataFrame;
  YTrain, YTest, YPred: TPySeries;
  TreeClf: TPyDecisionTreeClassifier;
  Accuracy: Double;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Age',      [22.0, 45.0, 52.0, 28.0, 35.0, 60.0]);
  DF.AddColumn('IncomeK',  [30.0, 85.0, 92.0, 45.0, 65.0, 110.0]);
  DF.AddColumn('Approved', [0, 1, 1, 0, 1, 1]); // Target (1 = Yes, 0 = No)

  // Split Train / Test
  PyTrainTestSplit(DF.Columns(['Age', 'IncomeK']), DF.Column('Approved'), 0.33,
                   XTrain, XTest, YTrain, YTest, 42);

  // Fit Decision Tree
  TreeClf := TPyDecisionTreeClassifier.Create(3, 42);
  TreeClf.Fit(XTrain, YTrain);

  YPred := TreeClf.Predict(XTest);

  // Model evaluation metrics
  Accuracy := PyAccuracyScore(YTest, YPred);
  Writeln(Format('Accuracy: %.2f%%', [Accuracy * 100.0]));

  // Plot feature importances
  TreeClf.PlotFeatureImportances(['Age', 'IncomeK'], 'Feature Breakdown');

  // Labeled Confusion Matrix Table
  CM := PyConfusionMatrix(YTest, YPred);
  CM.ShowTable('Confusion Matrix', 10);
end;
```

---

## ⚡ Interactive DataGrid Pro Features

Every `ShowTable(...)` and `DF.ShowTable(...)` renders an interactive DataGrid Pro interface:

- **Sortable Columns**: Click any column header to sort ascending (`▲`) or descending (`▼`). Numeric columns are sorted numerically, text alphabetically.
- **Instant Search / Filter**: Type in the search input to filter rows in real time across all visible columns.
- **Configurable Pagination**: Switch page sizes between `10`, `25`, `50`, and `100` rows per page with page navigation controls (`Previous` / `Next`).
- **RFC 4180 CSV Export**:
  - Click **📋 Copy CSV** to copy the current filtered table to your system clipboard.
  - Click **💾 Download CSV** to trigger an automatic download of `tabela_<timestamp>.csv`.

---

## ⌨️ Shortcuts & UI Capabilities

| Shortcut / Action | Feature | Description |
| :--- | :--- | :--- |
| `Ctrl + Space` | **IntelliSense Autocomplete** | Opens completion popup with Pascal keywords, data science classes, and standard methods. |
| Type `.` (dot) | **Member Autocomplete** | Trigger completion list for methods on known objects (e.g. `DF.`, `S.`, `RF.`, `LR.`). |
| `↑` / `↓` + `Enter` or `Tab` | **Select Suggestion** | Inserts selected method or snippet with automatic cursor positioning (`$0`). |
| `Ctrl + Z` | **Undo** | Undoes the last structural action (adding, deleting, reordering cells or clearing outputs). |
| `Ctrl + Y` or `Ctrl + Shift + Z` | **Redo** | Redoes the previously undone structural action. |
| `Z` (command mode) | **Restore Cell** | Instantly restores the last deleted cell to its original position. |
| `Ctrl + Shift + D` | **Dashboard View** | Toggles clean executive presentation mode (hides code cells, expands visual outputs). |
| `Shift + Enter` | **Run Cell & Next** | Compiles and executes current cell, advancing to the next cell. |
| `Ctrl + Enter` | **Run Cell in Place** | Compiles and executes the current cell while keeping focus. |
| `🔄 Reiniciar Kernel` | **Reset Kernel** | Restarts the persistent Python daemon, resets variable state, and clears compilation caches. |
