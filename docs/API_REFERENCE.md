# 📚 Pascal Units & Kernel API Reference

This document provides a comprehensive API reference for the native Pascal units and WebSocket execution protocol of **BlaiseNotebook**.

---

## 1. `BlaiseDataScience` Unit

Strongly-typed Object Pascal API for Python scientific computing (**Pandas**, **NumPy**, **Scikit-Learn**). Automatically included in cell execution scope.

### `TPySeries` Class
Represents a 1D vector or Pandas Series.
```pascal
type
  TPySeries = class
    // Constructors
    constructor Create(const AVarName: string; const AName: string = '');
    constructor Create(const AValues: array of Double; const AName: string = '');
    constructor Create(const AValues: array of string; const AName: string = '');
    constructor Create(const AValues: array of Integer; const AName: string = '');
    constructor Create(const AVec: TVector; const AName: string = '');

    // Conversion & Summary
    function ToArray: TDoubleArray;
    function ToVector: TVector;
    function Describe: string;
    procedure Print;

    // Visualizations
    procedure Plot(const ATitle: string = ''; const AChartType: string = 'line');
    procedure PlotAgainst(const AXSeries: TPySeries; const ATitle: string = ''; const AChartType: string = 'line');

    // Arithmetic
    function Multiply(const AFactor: Double): TPySeries;
    function Add(const AValue: Double): TPySeries;
    function Add(const AOther: TPySeries): TPySeries;
    function Subtract(const AOther: TPySeries): TPySeries;

    // Slicing
    function Head(ACount: Integer = 5): TPySeries;
    function Tail(ACount: Integer = 5): TPySeries;

    // Statistical Properties
    property Name: string;
    property Count: Integer;
    property Mean: Double;
    property StdDev: Double;
    property Min: Double;
    property Max: Double;
    property Sum: Double;
    property Median: Double;
    property Items[Index: Integer]: Double; default;
  end;
```

### `TPyDataFrame` Class
Represents a 2D tabular dataset (Pandas DataFrame).
```pascal
type
  TPyDataFrame = class
    constructor Create;
    constructor Create(const AVarName: string);
    class function FromCSV(const AFilePath: string): TPyDataFrame;
    class function FromJSON(const AJsonStr: string): TPyDataFrame;

    // Fluent Column Construction
    function AddColumn(const AColName: string; const AValues: array of Double): TPyDataFrame;
    function AddColumn(const AColName: string; const AValues: array of string): TPyDataFrame;
    function AddColumn(const AColName: string; const AValues: array of Integer): TPyDataFrame;
    function AddColumn(const AColName: string; const ASeries: TPySeries): TPyDataFrame;
    function AddColumn(const AColName: string; const AVec: TVector): TPyDataFrame;

    // Slicing & Extraction
    function Column(const AColName: string): TPySeries;
    function Columns(const AColNames: array of string): TPyDataFrame;
    function Drop(const AColName: string): TPyDataFrame;
    function Head(ACount: Integer = 5): TPyDataFrame;
    function Tail(ACount: Integer = 5): TPyDataFrame;

    // Metadata
    function RowCount: Integer;
    function ColumnCount: Integer;
    function ColumnNames: TStrings;
    function Describe: string;
    procedure Print;

    // Visualizations
    procedure ShowTable(const ATitle: string = 'DataFrame'; AMaxRows: Integer = 50);
    procedure PlotLine(const ATitle, AXCol, AYCol: string);
    procedure PlotLine(const ATitle, AXCol: string; const AYCols: array of string);
    procedure PlotBar(const ATitle, AXCol, AYCol: string);
    procedure PlotBar(const ATitle, AXCol: string; const AYCols: array of string);
    procedure PlotScatter(const ATitle, AXCol, AYCol: string);
    procedure PlotArea(const ATitle, AXCol, AYCol: string);

    // Export
    procedure ToCSV(const AFilePath: string);
  end;
```

### Machine Learning Classes

#### `TPyLinearRegression`
Ordinary Least Squares linear regression model.
```pascal
type
  TPyLinearRegression = class
    constructor Create;
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    procedure Fit(const X: TPySeries; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Predict(const X: TPySeries): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;
    function Score(const X: TPySeries; const Y: TPySeries): Double;
    function Slope: Double;
    function Coefficients: TDoubleArray;
    function Intercept: Double;
    function Summary: string;
  end;
```

#### `TPyRandomForestRegressor`
Ensemble Random Forest regressor with tree count and depth controls.
```pascal
type
  TPyRandomForestRegressor = class
    constructor Create(nEstimators: Integer = 100; maxDepth: Integer = -1; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;
    function FeatureImportances: TDoubleArray;
    procedure PlotFeatureImportances(const AFeatures: array of string; const ATitle: string = 'Feature Importances');
  end;
```

#### `TPyRandomForestClassifier`
Ensemble Random Forest classifier for discrete target labels.
```pascal
type
  TPyRandomForestClassifier = class
    constructor Create(nEstimators: Integer = 100; maxDepth: Integer = -1; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame; const Y: TPySeries);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Score(const X: TPyDataFrame; const Y: TPySeries): Double;
  end;
```

#### `TPyKMeans`
Unsupervised K-Means clustering model.
```pascal
type
  TPyKMeans = class
    constructor Create(nClusters: Integer = 3; randomState: Integer = 42);
    procedure Fit(const X: TPyDataFrame);
    function Predict(const X: TPyDataFrame): TPySeries;
    function Labels: TPySeries;
    function Inertia: Double;
  end;
```

#### Utility: `PyTrainTestSplit`
```pascal
procedure PyTrainTestSplit(const X: TPyDataFrame; const Y: TPySeries; TestSize: Double;
  out XTrain, XTest: TPyDataFrame; out YTrain, YTest: TPySeries; RandomState: Integer = 42);
```

---

## 2. `BlaiseMathKernel` Unit

High-performance numerical analysis routines written in pure Object Pascal.

### `TVector` Record
```pascal
type
  TVector = record
    Data: array of Double;
    function Count: Integer;
    class function Create(const Arr: array of Double): TVector; static;
    class function CreateRandom(ACount: Integer; MinVal, MaxVal: Double): TVector; static;
    function CalculaMedia: Double;
    function CalculaVariancia: Double;
    function CalculaDesvioPadrao: Double;
    function CalculaMediana: Double;
    function Soma: Double;
    function Min: Double;
    function Max: Double;
  end;
```

---

## 3. `BlaiseOutput` Unit

Frontend communication layer for streaming structured payloads.

### Procedures

#### `ShowChart`
```pascal
procedure ShowChart(
  const ATitle: string; 
  const AChartType: string; 
  const ADataJson: string; 
  const AOptionsJson: string = '{}'
);
```

#### `ShowTable`
```pascal
procedure ShowTable(
  const ATitle: string; 
  const AColumns: array of string; 
  const ARowsJson: string
);
```

---

## 4. `BlaisePyKernel` Unit

Direct low-level CPython execution via Python4Delphi / Python4Lazarus.

### Procedures & Functions
- `PyRun(const ACode: string)`: Executes a Python snippet.
- `PyEval(const AExpr: string): string`: Evaluates a Python expression to string.
- `ShowPyDataFrame(const AVarName: string; const ATitle: string = 'Pandas DataFrame'; AMaxRows: Integer = 50)`
- `ShowPySeriesChart(const AVarName, ATitle, AChartType: string)`
- `ShowPyDataFrameChart(const AVarName, AXCol, AYCol, ATitle, AChartType: string)`

---

## 5. WebSocket Protocol Specification

The BlaiseNotebook execution kernel operates over JSON-RPC WebSockets on `/ws`:

### Requests (Frontend -> Kernel)
- `execute_cell`: `{ "action": "execute_cell", "cell_id": "...", "execution_count": 1, "source": "..." }`
- `interrupt_cell`: `{ "action": "interrupt_cell", "cell_id": "..." }`
- `interrupt_all`: `{ "action": "interrupt_all" }`

### Responses (Kernel -> Frontend)
- `stream`: `{ "event": "stream", "cell_id": "...", "stream_type": "stdout"|"stderr", "text": "..." }`
- `display_data`: `{ "event": "display_data", "cell_id": "...", "payload": { "type": "chart"|"table", ... } }`
- `execute_reply`: `{ "event": "execute_reply", "cell_id": "...", "status": "success"|"error", "execution_count": 1, "execution_time_ms": 120 }`
