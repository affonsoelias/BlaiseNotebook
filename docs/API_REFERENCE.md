# 📚 Pascal Units & Kernel API Reference

This document provides a comprehensive API reference for the native Pascal units and WebSocket execution protocol of **BlaiseNotebook**.

---

## 1. `BlaiseMathKernel` Unit

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
    function Normalizar: TVector;
    function DotProduct(const Other: TVector): Double;
  end;
```

### `TLinearRegression` Record

```pascal
type
  TLinearRegression = record
    Slope: Double;        // Regression slope (m)
    Intercept: Double;    // Y-intercept (b)
    RSquared: Double;     // Coefficient of determination (R²)
    class function Fit(const X, Y: TVector): TLinearRegression; static;
    function Predict(XVal: Double): Double;
  end;
```

---

## 2. `BlaiseOutput` Unit

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
- **`ATitle`:** Header title displayed on the chart card.
- **`AChartType`:** One of `'line'`, `'bar'`, `'scatter'`, `'radar'`, `'pie'`, `'doughnut'`.
- **`ADataJson`:** Valid Chart.js data configuration string with `labels` and `datasets`.
- **`AOptionsJson`:** Optional Chart.js options JSON string.

#### `ShowTable`
```pascal
procedure ShowTable(
  const ATitle: string; 
  const AColumnsJson: string; 
  const ARowsJson: string
);
```
- **`ATitle`:** Table card title.
- **`AColumnsJson`:** JSON array of column header strings (e.g. `["Col A", "Col B"]`).
- **`ARowsJson`:** JSON 2D array of rows (e.g. `[["1", "Val"], ["2", "Val"]]`).

---

## 3. `BlaisePyKernel` Unit

Direct CPython API integration via Python4Delphi / Python4Lazarus.

### Procedures & Functions

#### `PyInit`
```pascal
function PyInit(const ADllPath: string = ''): Boolean;
```
Initializes the embedded CPython engine. Automatically detects local installations of `python313.dll`, `python312.dll`, or `python311.dll`.

#### `PyRun`
```pascal
function PyRun(const ACode: string): Boolean;
```
Executes a Python code block in the global Python execution namespace. Standard output is routed to the notebook output area.

#### `PyEval`
```pascal
function PyEval(const AExpr: string): string;
```
Evaluates a Python expression string and returns the string representation (`repr()`) of the resulting Python object.

#### `ShowPyDataFrame`
```pascal
procedure ShowPyDataFrame(
  const AVarName: string; 
  const ATitle: string = 'DataFrame'; 
  AMaxRows: Integer = 20
);
```
Extracts a Pandas `DataFrame` variable by identifier and emits an interactive notebook table.

#### `ShowPySeriesChart`
```pascal
procedure ShowPySeriesChart(
  const AVarName: string; 
  const ATitle: string; 
  const AChartType: string = 'line'
);
```
Plots a Pandas `Series` or 1D NumPy array directly into a Chart.js card.

---

## 4. WebSocket Message Protocol (`/ws`)

### Actions (Client -> Server)

| Action | Parameters | Description |
| :--- | :--- | :--- |
| `execute_cell` | `cell_id: string`<br>`execution_count: integer`<br>`source: string` | Requests compilation and execution of code cell. |
| `interrupt_cell` | `cell_id: string` | Aborts execution of specified cell. |
| `interrupt_all` | *(none)* | Aborts active execution and empties server queue. |

### Events (Server -> Client)

| Event | Parameters | Description |
| :--- | :--- | :--- |
| `stream` | `cell_id: string`<br>`stream_type: "stdout" \| "stderr"`<br>`text: string` | Real-time console logs and error output. |
| `display_data` | `cell_id: string`<br>`payload: object` | Structured JSON payloads (Chart.js configs or tables). |
| `execute_reply`| `cell_id: string`<br>`status: "success" \| "error"`<br>`execution_count: integer`<br>`execution_time_ms: integer` | Completion notification with execution metrics. |
| `interrupt_reply`| `status: "interrupted"` | Confirmation of successful interruption. |
