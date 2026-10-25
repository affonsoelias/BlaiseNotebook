# 🤖 Track 4: AI & Machine Learning Expert — Models & Evaluation

> **Welcome to Track 4!** In this final track, you will unlock the frontier of modern computing in Object Pascal: training **Artificial Intelligence and Machine Learning models** with **Scikit-Learn** directly from your notebook!
>
> ⏱️ **Estimated time:** 30 minutes  
> 🎯 **Level:** Advanced / Expert (Built on Tracks 1, 2 & 3)

---

## 📖 Lesson 4.1: The Machine Learning Workflow (Made Super Simple)

Every supervised Machine Learning task follows 4 easy steps:

```text
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ 1. Collect Data │ ───▶  │ 2. Split Data   │ ───▶  │ 3. Train Model  │ ───▶  │ 4. Evaluate     │
│ Features & Target│      │ Train & Test Set│       │ .Fit(X, Y)      │       │ Accuracy / R²   │
└─────────────────┘       └─────────────────┘       └─────────────────┘       └─────────────────┘
```

1. **Features (`X`)**: The inputs you know (e.g. Study Hours, Sleep Hours).
2. **Target (`Y`)**: What you want the AI to predict (e.g. Final Exam Score, Approved/Denied).
3. **Train-Test Split**: We give 70-80% of our data to the AI to learn, and keep 20-30% secret to test how smart the model really is!

```pascal
var
  DF, XTrain, XTest: TPyDataFrame;
  YTrain, YTest: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Feature1', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]);
  DF.AddColumn('Feature2', [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0]);
  DF.AddColumn('Target',   [15.0, 25.0, 32.0, 44.0, 56.0, 68.0, 75.0, 89.0, 95.0, 108.0]);

  // Split into 80% Train, 20% Test with a single call:
  PyTrainTestSplit(DF.Columns(['Feature1', 'Feature2']), DF.Column('Target'), 0.20,
                   XTrain, XTest, YTrain, YTest, 42);

  Writeln(Format('Training Set: %d samples | Testing Set: %d samples', 
    [XTrain.RowCount, XTest.RowCount]));
end;
```

---

## 📖 Lesson 4.2: Continuous Forecasting with Linear Regression

Use **`TPyLinearRegression`** when predicting continuous numerical numbers (trends, prices, growth):

$$ y = m \cdot x + b $$

```pascal
var
  DF: TPyDataFrame;
  Model: TPyLinearRegression;
  NewExperience, PredictedSalary: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('YearsExp', [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
  DF.AddColumn('SalaryK',  [42.0, 50.0, 58.0, 67.0, 75.0, 84.0, 92.0, 101.0]);

  // 1. Train the model:
  Model := TPyLinearRegression.Create;
  Model.Fit(DF.Column('YearsExp'), DF.Column('SalaryK'));

  // 2. Inspect fitted mathematical formula:
  Writeln(Format('Fitted Formula: Salary = %.2f * Years + %.2f', [Model.Slope, Model.Intercept]));
  Writeln(Format('Model Accuracy (R² Score): %.4f', [Model.Score(DF.Column('YearsExp'), DF.Column('SalaryK'))]));

  // 3. Predict for a developer with 9 years of experience:
  NewExperience := TPySeries.Create([9.0]);
  PredictedSalary := Model.Predict(NewExperience);
  Writeln(Format('Predicted Salary for 9 Years Exp: $%.2fk', [PredictedSalary[0]]));
end;
```

---

## 📖 Lesson 4.3: Ensemble Trees: Random Forest Regressor

When data is non-linear, a single straight line won't suffice. **Random Forest** trains an ensemble of dozens of decision trees and combines their votes:

```pascal
var
  DF: TPyDataFrame;
  RF: TPyRandomForestRegressor;
  Score: Double;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('EngineSize', [1.2, 1.6, 2.0, 2.5, 3.0, 4.0, 5.0]);
  DF.AddColumn('Horsepower', [90, 120, 150, 210, 280, 420, 500]);
  DF.AddColumn('FuelEconomy', [38.0, 34.0, 29.0, 24.0, 20.0, 15.0, 12.0]);

  // Train a Random Forest with 50 decision trees:
  RF := TPyRandomForestRegressor.Create(50, -1, 42);
  RF.Fit(DF.Columns(['EngineSize', 'Horsepower']), DF.Column('FuelEconomy'));

  Score := RF.Score(DF.Columns(['EngineSize', 'Horsepower']), DF.Column('FuelEconomy'));
  Writeln(Format('Random Forest Fit R² Score: %.4f', [Score]));

  // Plot which features were most influential:
  RF.PlotFeatureImportances(['EngineSize', 'Horsepower'], 'What Drives Fuel Economy?');
end;
```

---

## 📖 Lesson 4.4: Classification with Logistic Regression

When the answer is **Yes / No**, **True / False**, or a discrete category, we use a classifier:

```pascal
var
  DF, XTrain, XTest, Probabilities: TPyDataFrame;
  YTrain, YTest, YPred: TPySeries;
  Classifier: TPyLogisticRegression;
  Accuracy: Double;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Age',         [22.0, 25.0, 45.0, 52.0, 28.0, 58.0, 35.0, 62.0]);
  DF.AddColumn('AnnualIncome',[25.0, 32.0, 85.0, 95.0, 42.0, 110.0, 65.0, 125.0]);
  DF.AddColumn('BoughtCar',   [0, 0, 1, 1, 0, 1, 1, 1]); // 1 = Bought, 0 = Did not buy

  // Split:
  PyTrainTestSplit(DF.Columns(['Age', 'AnnualIncome']), DF.Column('BoughtCar'), 0.25,
                   XTrain, XTest, YTrain, YTest, 42);

  // Train Logistic Regression:
  Classifier := TPyLogisticRegression.Create(200, 42);
  Classifier.Fit(XTrain, YTrain);

  YPred := Classifier.Predict(XTest);
  Accuracy := PyAccuracyScore(YTest, YPred);
  Writeln(Format('Classification Accuracy: %.2f%%', [Accuracy * 100.0]));

  // Inspect probabilities:
  Probabilities := Classifier.PredictProba(XTest);
  Probabilities.ShowTable('Confidence Probabilities for Test Observations', 10);
end;
```

---

## 📖 Lesson 4.5: Interpretable Decision Tree Classifiers

Decision Trees are beloved because they make logical rules that humans can easily understand and explain:

```pascal
var
  DF: TPyDataFrame;
  Tree: TPyDecisionTreeClassifier;
  Accuracy: Double;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('CreditScore', [550.0, 620.0, 710.0, 780.0, 590.0, 810.0]);
  DF.AddColumn('DebtRatio',   [0.55, 0.40, 0.22, 0.15, 0.48, 0.10]);
  DF.AddColumn('Approved',    [0, 0, 1, 1, 0, 1]); // 1 = Approved, 0 = Denied

  // Train Decision Tree with depth 3:
  Tree := TPyDecisionTreeClassifier.Create(3, 42);
  Tree.Fit(DF.Columns(['CreditScore', 'DebtRatio']), DF.Column('Approved'));

  Accuracy := Tree.Score(DF.Columns(['CreditScore', 'DebtRatio']), DF.Column('Approved'));
  Writeln(Format('Training Set Accuracy: %.2f%%', [Accuracy * 100.0]));

  // Visualize feature importance:
  Tree.PlotFeatureImportances(['CreditScore', 'DebtRatio'], 'Approval Factor Weight');
end;
```

---

## 📖 Lesson 4.6: Model Evaluation & Confusion Matrices

How do you know if an AI model is truly trustworthy? You look at its **Confusion Matrix**:

- **True Positives**: Correctly predicted `1`.
- **True Negatives**: Correctly predicted `0`.
- **False Positives (Type I Error)**: Predicted `1` when it was actually `0`.
- **False Negatives (Type II Error)**: Predicted `0` when it was actually `1`.

```pascal
var
  CM: TPyDataFrame;
begin
  // Generate a labeled Confusion Matrix table:
  CM := PyConfusionMatrix(YTest, YPred);

  // Render directly as an interactive table!
  CM.ShowTable('Model Performance (Confusion Matrix: Actual vs Predicted)', 10);
end;
```

---

## 📖 Lesson 4.7: Unsupervised Clustering with K-Means

What if your data doesn't have labels, and you want the AI to discover natural customer segments on its own? Use **`TPyKMeans`**:

```pascal
var
  DF: TPyDataFrame;
  KMeans: TPyKMeans;
  ClusterLabels: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('IncomeK',     [15.0, 16.0, 75.0, 82.0, 130.0, 140.0]);
  DF.AddColumn('SpendingScore',[85.0, 78.0, 48.0, 52.0, 15.0, 12.0]);

  // Automatically partition customers into 3 clusters:
  KMeans := TPyKMeans.Create(3, 42);
  KMeans.Fit(DF);

  ClusterLabels := KMeans.Labels;
  DF.AddColumn('AssignedCluster', ClusterLabels);
  
  DF.ShowTable('Discovered Customer Segments (K-Means Clusters)', 10);
  Writeln(Format('Cluster Compactness (Inertia): %.2f', [KMeans.Inertia]));
end;
```

---

## 🏆 Practice Challenge 4: Complete Machine Learning Pipeline

Build an end-to-end predictive pipeline in a single Pascal cell:
1. Create a dataset of 10 customer records (`'UsageTime'`, `'Calls'`, `'Subscribed'`).
2. Split 70% Train, 30% Test with `PyTrainTestSplit`.
3. Train a `TPyDecisionTreeClassifier`.
4. Predict outcomes and print the accuracy percentage.
5. Render the Confusion Matrix table.

### Solution:

```pascal
var
  DF, XTrain, XTest, CM: TPyDataFrame;
  YTrain, YTest, YPred: TPySeries;
  Model: TPyDecisionTreeClassifier;
  Acc: Double;
begin
  Writeln('=== END-TO-END PREDICTIVE AI PIPELINE ===');

  DF := TPyDataFrame.Create;
  DF.AddColumn('UsageHours',   [2.0, 4.0, 8.0, 15.0, 22.0, 35.0, 42.0, 50.0, 6.0, 18.0]);
  DF.AddColumn('SupportCalls', [5, 4, 3, 1, 1, 0, 0, 0, 4, 2]);
  DF.AddColumn('Renewed',      [0, 0, 0, 1, 1, 1, 1, 1, 0, 1]); // 1 = Renewed, 0 = Churned

  // 1. Train / Test Split:
  PyTrainTestSplit(DF.Columns(['UsageHours', 'SupportCalls']), DF.Column('Renewed'), 0.30,
                   XTrain, XTest, YTrain, YTest, 42);

  // 2. Train Decision Tree:
  Model := TPyDecisionTreeClassifier.Create(3, 42);
  Model.Fit(XTrain, YTrain);

  // 3. Predict on Test data:
  YPred := Model.Predict(XTest);

  // 4. Evaluate Accuracy:
  Acc := PyAccuracyScore(YTest, YPred);
  Writeln(Format('Validation Test Accuracy: %.2f%%', [Acc * 100.0]));

  // 5. Confusion Matrix:
  CM := PyConfusionMatrix(YTest, YPred);
  CM.ShowTable('Validation Confusion Matrix', 10);

  Writeln('🎉 Pipeline successfully executed in pure Object Pascal!');
end;
```

---

### 🎓 Congratulations, Graduate!
You have completed all 4 tracks of the **BlaiseNotebook Masterclass**!

You now possess the skills to:
- Write, debug, and document notebooks in Object Pascal.
- Render hardware-accelerated interactive charts.
- Wrangle complex datasets with fluent Pandas-style queries and aggregations.
- Train, predict, and evaluate predictive Machine Learning models.

Explore the accompanying executable notebooks anytime in the [`examples/`](../../examples/README.md) folder!
