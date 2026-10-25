# 🎓 BlaiseNotebook Hands-On Course: From Beginner to Advanced

Welcome to the **BlaiseNotebook Interactive Course**! This course is designed to take you from a complete beginner to an advanced practitioner capable of analyzing complex datasets, drawing interactive charts, and training machine learning models using **Object Pascal**.

Every lesson in this course is a self-contained, executable notebook (`.bynb`) located in this directory.

---

## 🗺️ Course Syllabus

```
Level 1: The Basics
  ├── Example 1: Getting Started & The Notebook Interface (01_getting_started.bynb)
  └── Example 2: Rich Markdown, Notes & Mathematical Formulas (02_rich_markdown_and_latex.bynb)

Level 2: Native Computing & Visualizations
  ├── Example 3: Object Pascal Logic & High-Performance Math (03_native_pascal_and_math.bynb)
  └── Example 4: Interactive Charts & Data Tables (04_interactive_charts_and_tables.bynb)

Level 3: Modern Data Science & AI in Pascal
  ├── Example 5: Tabular Data & Pandas in Pure Pascal (05_pandas_dataframes_in_pascal.bynb)
  ├── Example 6: Machine Learning with Scikit-Learn (06_machine_learning_in_pascal.bynb)
  ├── Example 7: Advanced Workflows, Python Interop & Projects (07_advanced_workflows_and_python_interop.bynb)
  ├── Example 8: Advanced Scientific Charts & Fluent Analytics (08_advanced_charts_and_fluent_analytics.bynb)
  └── Example 9: Classification Models & Model Evaluation Metrics (09_classification_and_model_evaluation.bynb)
```

---

## 📚 Lesson Breakdown

### 🟢 Level 1: Foundations

#### [Example 1: Getting Started & The Notebook Interface](01_getting_started.bynb)
- **Topics covered:** The anatomy of BlaiseNotebook; what cells are; using the toolbar (Run, Run All, Stop, Clear, Dark Theme); writing your first `Writeln`; keyboard shortcuts (`Shift + Enter`, `Ctrl + Enter`); reading execution numbers and timing.
- **Estimated time:** 5 minutes.

#### [Example 2: Rich Markdown, Notes & Mathematical Formulas](02_rich_markdown_and_latex.bynb)
- **Topics covered:** Creating Markdown cells; headings, lists, bold/italics, quotes, and tables; writing mathematical equations with LaTeX / KaTeX ($E = mc^2$, $\sigma = \sqrt{\frac{\sum (x - \mu)^2}{N}}$); syntax-highlighted code snippets; editing and previewing modes.
- **Estimated time:** 10 minutes.

---

### 🟡 Level 2: Numerical Computing & Interactive Visualizations

#### [Example 3: Object Pascal Logic & High-Performance Math](03_native_pascal_and_math.bynb)
- **Topics covered:** Loops, conditionals, and variables in Pascal notebook cells; fast numerical processing with `TVector`; generating random and linear distributions; computing descriptive statistics (Mean, Variance, StdDev, Median, Min, Max); fitting linear equations natively.
- **Estimated time:** 15 minutes.

#### [Example 4: Interactive Charts & Data Tables](04_interactive_charts_and_tables.bynb)
- **Topics covered:** Rendering Chart.js (`<bv-chart>`) graphs directly beneath code; line graphs with smooth splines and fills; multi-dataset bar charts with custom colors; scatter plots; displaying responsive scrollable data tables with `ShowTable`.
- **Estimated time:** 15 minutes.

---

### 🔴 Level 3: Modern Data Science & Machine Learning in Pascal

#### [Example 5: Tabular Data & Pandas in Pure Pascal](05_pandas_dataframes_in_pascal.bynb)
- **Topics covered:** Working with DataFrames without typing Python strings; creating DataFrames with `TPyDataFrame.Create`; adding columns fluently; reading CSV files; column extraction with `TPySeries`; series statistics (`.Mean`, `.StdDev`, `.Median`); slicing with `.Head` and `.Tail`; plotting charts in a single line of Pascal (`.PlotLine`, `.PlotBar`, `.PlotScatter`); exporting to CSV.
- **Estimated time:** 20 minutes.

#### [Example 6: Machine Learning with Scikit-Learn in Pascal](06_machine_learning_in_pascal.bynb)
- **Topics covered:** Training machine learning models with pure Pascal classes; Linear Regression (`TPyLinearRegression`); Random Forest Regressors (`TPyRandomForestRegressor`); predicting outcomes and evaluating $R^2$ accuracy scores; plotting feature importances; Random Forest Classifier; K-Means clustering (`TPyKMeans`); splitting datasets with `PyTrainTestSplit`.
- **Estimated time:** 25 minutes.

#### [Example 7: Advanced Workflows, Python Interop & Projects](07_advanced_workflows_and_python_interop.bynb)
- **Topics covered:** Direct low-level Python execution when needed (`PyRun`, `PyEval`); passing variables between Pascal and Python; interrupting long-running loops with the ⏹ Interrupt button; saving and exporting `.bynb` project files; sharing notebooks with colleagues; best practices for building reproducible scientific notebooks.
- **Estimated time:** 20 minutes.

---

#### [Example 8: Advanced Scientific Charts & Fluent Analytics](08_advanced_charts_and_fluent_analytics.bynb)
- **Topics covered:** Pie and Doughnut Charts (`.PlotPie`, `.PlotDoughnut`); statistical distribution histograms (`.PlotHistogram`) with automatic bin estimation; 5-number summary BoxPlots (`.PlotBoxPlot`); fluent expression filtering (`.Filter('Rating >= 4.2')`); sorting (`.SortBy`); GroupBy aggregations (`.GroupBy('Region').Mean`, `.Sum`).
- **Estimated time:** 15 minutes.

#### [Example 9: Classification Models & Model Evaluation Metrics](09_classification_and_model_evaluation.bynb)
- **Topics covered:** Logistic Regression classification (`TPyLogisticRegression`); predicting class probabilities (`.PredictProba`); Decision Tree Classifier (`TPyDecisionTreeClassifier`); computing feature importances (`.PlotFeatureImportances`); measuring accuracy with `PyAccuracyScore`; generating confusion matrix tables with `PyConfusionMatrix`.
- **Estimated time:** 20 minutes.

---


## 🚀 How to Open an Example Notebook

1. Launch BlaiseNotebook:
   ```bash
   cd frontend
   bv mormot run
   ```
2. Open your browser at **`http://localhost:8090/`**.
3. In the top toolbar, click **📁 Project** -> **📂 Open Project (.bynb)**.
4. Select any `.bynb` file from this `examples/` folder.
5. Press **▶ Run All** to run the complete notebook, or click on any cell and press **`Shift + Enter`** to explore interactively!
