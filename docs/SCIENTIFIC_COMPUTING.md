# 📊 Data Science & Machine Learning with Pure Pascal

Have you ever wanted to work with **Pandas DataFrames**, plot **interactive charts**, and train **Machine Learning models** without having to memorize Python syntax?

With **BlaiseNotebook**, you get the best of both worlds: you write **clean, strongly-typed Object Pascal code**, and the notebook automatically handles the Python data science engine under the hood via a high-performance **persistent Python daemon** (`localhost:9099`) and **Zero-Delay Compilation Cache**!

---

## 💡 Quick Overview: The Easy Pascal Data Science API

In your notebook cells, you have access to three main building blocks:

1. **`TPyDataFrame`**: A 2D table (like an Excel spreadsheet or Pandas DataFrame) that holds rows and columns with interactive DataGrid Pro rendering, charting, and cross-cell persistence (`Attach`, `SaveAs`).
2. **`TPySeries`**: A single column with built-in statistics (Mean, Standard Deviation, Median, Min, Max).
3. **Machine Learning Models**:
   - `TPyLinearRegression`: For trend lines and forecasting.
   - `TPyRandomForestRegressor`: For powerful AI predictions with decision tree ensembles.
   - `TPyRandomForestClassifier`: For classifying data into categories.
   - `TPyDecisionTreeClassifier`: Interpretable rule-based decision trees with feature importance.
   - `TPyLogisticRegression`: Logistic regression classification.
   - `TPyKMeans`: For automatic clustering.

---

## 1. Creating and Exploring Data with DataGrid Pro

### Creating a DataFrame in Pascal
You can build a DataFrame row-by-row or column-by-column:

```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('StudyHours', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
  DF.AddColumn('ExamScore',  [50.0, 55.0, 65.0, 70.0, 80.0, 85.0, 92.0, 98.0]);

  // Display the data as an interactive DataGrid Pro table below the cell:
  DF.ShowTable('Student Exam Data', 10);
end;
```

### Loading Data from a CSV File
Have a `.csv` file on your computer? Loading it takes one line:

```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.FromCSV('workspace/data/sales.csv');
  DF.ShowTable('Company Sales', 25);
end;
```

### ⚡ Exploring Tables with DataGrid Pro
When you call `ShowTable` or `DF.ShowTable`, BlaiseNotebook renders a rich client-side DataGrid:
- **Instant Sorting**: Click column headers to sort numerically or alphabetically ascending (`▲`) or descending (`▼`).
- **Real-Time Search**: Filter thousands of records instantly using the live search box.
- **Pagination**: Navigate pages cleanly with dropdown controls (`10`, `25`, `50`, `100` rows per page).
- **One-Click Export**: Click **📋 Copiar CSV** to copy to clipboard, or **💾 Download CSV** to save directly to disk.

---

## 2. Stateful Cross-Cell Continuity (Persistent Kernel)

BlaiseNotebook maintains an active, persistent Python daemon session (`localhost:9099`). This means you don't need to re-read datasets or retrain models when you run subsequent cells!

### Cell 1: Load and Persist
```pascal
var
  RawDF: TPyDataFrame;
begin
  RawDF := TPyDataFrame.FromCSV('large_dataset.csv');
  // Register in kernel daemon memory:
  RawDF.SaveAs('my_dataset');
  Writeln('Dataset loaded and cached in kernel memory!');
end;
```

### Cell 2: Reuse Anywhere Without Reloading
```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  // Attach to the live variable in memory:
  DF.Attach('my_dataset');
  
  // Instant statistics and visualization without re-reading the file!
  DF.PlotBar('Revenue by Region', 'Region', 'Revenue');
end;
```

### Resetting Kernel Memory
If you ever want to clear all active variables in the persistent daemon, click **🔄 Reiniciar Kernel** in the toolbar, or call `PyReset;` inside any cell.

---

## 3. In-Notebook Package Management (`%pip install`)

Need an extra library for your analysis like `seaborn` or `xgboost`? You can install it directly inside any notebook cell using the `%pip` or `!pip` magic command:

```python
%pip install seaborn xgboost openpyxl
```

The output streams in real-time, and installed packages are immediately available to your persistent kernel without restarting the server!

---

## 4. Instant Statistics

Want to find the average, highest, or lowest values? Access any column with `.Column('Name')`:

```pascal
var
  DF: TPyDataFrame;
  Scores: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Scores', [75.0, 82.5, 91.0, 68.0, 95.0, 88.0]);

  Scores := DF.Column('Scores');
  Writeln('Total Students: ', Scores.Count);
  Writeln('Average Score:  ', Scores.Mean:0:2);
  Writeln('Highest Score:  ', Scores.Max:0:2);
  Writeln('Lowest Score:   ', Scores.Min:0:2);
  Writeln('Spread (StdDev): ', Scores.StdDev:0:2);
end;
```

---

## 5. Beautiful Interactive Charts

BlaiseNotebook automatically renders responsive Chart.js canvas elements right under your cell:

### Line Chart
```pascal
DF.PlotLine('Study Hours vs Exam Score', 'StudyHours', 'ExamScore');
```

### Bar Chart
```pascal
DF.PlotBar('Revenue by Product Category', 'Category', 'Revenue');
```

### Scatter Plot
```pascal
DF.PlotScatter('Engine Size vs Fuel Efficiency', 'EngineSize', 'MPG');
```

### Pie & Doughnut Charts
```pascal
DF.PlotPie('Budget Distribution by Team', 'Team', 'Budget');
DF.PlotDoughnut('Team Hours (Doughnut)', 'Team', 'Hours');
```

### Distribution Histogram
```pascal
DF.PlotHistogram('Project Hours Distribution', 'Hours', 4);
```

### 5-Number Summary BoxPlot
```pascal
DF.PlotBoxPlot('Budget Dispersion (BoxPlot)', 'Team', 'Budget');
```

---

## 6. Training Machine Learning Models

### Random Forest Regressor
Train an ensemble AI model to predict continuous numbers:

```pascal
var
  DF: TPyDataFrame;
  RF: TPyRandomForestRegressor;
  Pred: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Hours', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
  DF.AddColumn('Tests', [1, 2, 2, 3, 3, 4, 4, 5]);
  DF.AddColumn('Score', [50.0, 55.0, 65.0, 70.0, 80.0, 85.0, 92.0, 98.0]);

  // Create model with 25 trees
  RF := TPyRandomForestRegressor.Create(25, -1, 42);
  RF.Fit(DF.Columns(['Hours', 'Tests']), DF.Column('Score'));

  Writeln(Format('Model Accuracy (R² Score): %.4f', 
    [RF.Score(DF.Columns(['Hours', 'Tests']), DF.Column('Score'))]));

  // Predict values for the dataset
  Pred := RF.Predict(DF.Columns(['Hours', 'Tests']));
  Writeln('Predicted score for 1st student: ', Pred[0]:0:2);

  // Plot which features matter most:
  RF.PlotFeatureImportances(['Hours', 'Tests'], 'Feature Importance');
end;
```

### Linear Regression
Fit straight lines ($y = m \cdot x + b$) to model trends:

```pascal
var
  DF: TPyDataFrame;
  LR: TPyLinearRegression;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('YearsExperience', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
  DF.AddColumn('SalaryK',          [40.0, 48.0, 55.0, 64.0, 73.0, 82.0, 95.0]);

  LR := TPyLinearRegression.Create;
  LR.Fit(DF.Column('YearsExperience'), DF.Column('SalaryK'));

  Writeln(Format('Salary = %.2f * Years + %.2f', [LR.Slope, LR.Intercept]));
  Writeln(Format('Model Fit (R²): %.4f', [LR.Score(DF.Column('YearsExperience'), DF.Column('SalaryK'))]));

  DF.PlotBar('Salary Growth by Experience', 'YearsExperience', 'SalaryK');
end;
```

---

## 7. Splitting Data into Train & Test Sets

Want to properly evaluate your model without overfitting? Use `PyTrainTestSplit`:

```pascal
var
  DF: TPyDataFrame;
  XTrain, XTest: TPyDataFrame;
  YTrain, YTest: TPySeries;
begin
  DF := TPyDataFrame.FromCSV('dataset.csv');

  // Split: 80% training data, 20% test data
  PyTrainTestSplit(DF.Columns(['Feature1', 'Feature2']), DF.Column('Target'), 0.20,
    XTrain, XTest, YTrain, YTest, 42);

  Writeln(Format('Training rows: %d | Test rows: %d', [XTrain.RowCount, XTest.RowCount]));
end;
```

---

## 8. Fluent Pandas-style Data Manipulation

Manipulate and aggregate tabular data cleanly without writing SQL or Python boilerplate:

```pascal
var
  DF, CleanDF, FilteredDF, SortedDF, GroupedDF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Category', ['Hardware', 'Software', 'Hardware', 'Software', 'Services']);
  DF.AddColumn('SalesK',   [120.0, 85.0, 140.0, 90.0, 45.0]);
  DF.AddColumn('Margin',   [0.25, 0.45, 0.28, 0.50, 0.35]);

  // Drop missing rows
  CleanDF := DF.DropNA;

  // Filter with expressive query strings
  FilteredDF := CleanDF.Filter('SalesK > 80.0 and Margin >= 0.30');
  FilteredDF.ShowTable('High Margin Products', 10);

  // Fluent sorting
  SortedDF := FilteredDF.SortBy('SalesK', False); // Descending

  // Analytical GroupBy
  GroupedDF := DF.GroupBy('Category').Mean;
  GroupedDF.ShowTable('Average Sales & Margin per Category', 10);
end;
```

---

## 9. Classification Models & Rigorous Evaluation

Train predictive classifiers and generate labeled confusion matrices:

```pascal
var
  DF, XTrain, XTest, CM: TPyDataFrame;
  YTrain, YTest, YPred: TPySeries;
  TreeClf: TPyDecisionTreeClassifier;
  Accuracy: Double;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('UsageHours', [10.0, 25.0, 4.0, 35.0, 2.0, 50.0]);
  DF.AddColumn('Features',   [3, 8, 1, 12, 1, 15]);
  DF.AddColumn('Subscribed', [0, 1, 0, 1, 0, 1]); // 1 = Yes, 0 = No

  PyTrainTestSplit(DF.Columns(['UsageHours', 'Features']), DF.Column('Subscribed'), 0.33,
                   XTrain, XTest, YTrain, YTest, 42);

  // Train Decision Tree Classifier
  TreeClf := TPyDecisionTreeClassifier.Create(3, 42);
  TreeClf.Fit(XTrain, YTrain);
  YPred := TreeClf.Predict(XTest);

  // Evaluate accuracy score
  Accuracy := PyAccuracyScore(YTest, YPred);
  Writeln(Format('Decision Tree Accuracy: %.2f%%', [Accuracy * 100.0]));

  // Plot feature importance
  TreeClf.PlotFeatureImportances(['UsageHours', 'Features'], 'Subscription Drivers');

  // Generate and display confusion matrix table
  CM := PyConfusionMatrix(YTest, YPred);
  CM.ShowTable('Model Confusion Matrix', 10);
end;
```

---

## 10. Executive Dashboard View (Modo Apresentação)

Need to present results to managers, executives, or clients without showing raw Pascal code?

- Click **📊 Dashboard View** on the toolbar or press `Ctrl + Shift + D`.
- BlaiseNotebook instantly hides code cells and code editors, transforming your notebook into a clean, executive presentation canvas.
- All interactive Chart.js graphs and DataGrid Pro tables remain fully interactive.
- Ready for high-quality PDF reports and physical printing (`Ctrl + P`).
- Click **✏️ Modo Edição** or press `Ctrl + Shift + D` again to return to developer mode anytime.
