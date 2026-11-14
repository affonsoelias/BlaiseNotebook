# 📦 Modular Packages & Extensibility Guide

Welcome to the **BlaiseNotebook Modular Package Guide**! 

Starting with **Milestone 2**, BlaiseNotebook features a fully decoupled, extensible package architecture. You can easily install Python dependencies with `%pip`, consume native Pascal and Python libraries in your cells with `uses`, and build your own custom libraries without ever recompiling the notebook server.

---

## 🏛️ Architecture Overview

The backend execution engine (`frontend/server/`) isolates all libraries into self-contained package folders:

```text
frontend/server/
├── packages/                                  <-- Central Packages Root
│   │
│   ├── core/                                  <-- Essential Notebook Core (bvnb-core)
│   │   ├── BlaiseOutput.pas                   (ShowText, ShowHtml, ShowChart, ShowTable)
│   │   └── package.json
│   │
│   ├── tools/                                 <-- Official Auxiliary Tools
│   │   ├── _template/                         <-- Tool scaffold template
│   │   └── bvnb-tool-data-generator/          <-- Synthetic data & matrix generator
│   │       ├── uDataGenerator.pas
│   │       ├── package.json
│   │       ├── doc/
│   │       └── examples/
│   │
│   └── external/                              <-- All Modular Scientific Libraries Live Here
│       │
│       ├── _template/                         <-- Ready-to-use template for new libraries
│       │   ├── MyLibrary.pas
│       │   ├── package.json
│       │   └── requirements.txt
│       │
│       ├── bvnb-pandas/                       <-- Official Pandas & NumPy Wrapper [alias: pandas]
│       │   ├── BlaisePandas.pas               (TPyDataFrame, TPySeries, TPyGroupBy)
│       │   ├── package.json
│       │   └── requirements.txt               (pandas>=2.0.0, numpy>=1.24.0)
│       │
│       ├── bvnb-sklearn/                      <-- Official Scikit-Learn Wrapper [alias: sklearn]
│       │   ├── BlaiseSklearn.pas              (Regressors, Classifiers, Evaluation)
│       │   ├── package.json
│       │   └── requirements.txt               (scikit-learn>=1.3.0)
│       │
│       ├── bvnb-math/                         <-- High-Performance Native Pascal Math [alias: math]
│       │   ├── BlaiseMathKernel.pas           (TVector, fast native statistics)
│       │   └── package.json
│       │
│       ├── bvnb-python-bridge/                <-- PythonEngine Bridge [alias: python_bridge]
│       │   ├── BlaisePyKernel.pas             (Auto-discovery of local Python DLLs)
│       │   └── package.json
│       │
│       ├── bvnb-datascience/                  <-- Backward-Compatibility Aggregator [alias: datascience]
│       │   ├── BlaiseDataScience.pas          (Re-exports Pandas & Sklearn)
│       │   └── package.json
│       │
│       └── [your-library]/                    <-- Any library created by you or third parties!
│           ├── YourUnit.pas
│           └── package.json
│
├── uCodeRunner.pas                            <-- Dynamic runner with automatic -Fu discovery
└── server.lpr
```

---

## ⚡ 1. Installing Python Packages via `%pip`

Just like in Jupyter Notebook, you can install any Python library directly from a notebook cell!

### How to Use `%pip`

In any cell, type:

```text
%pip install yfinance scipy seaborn
```
*(Or with the exclamation mark: `!pip install yfinance`)*

Press `Shift + Enter` to run. BlaiseNotebook will:
1. Detect the magic `%pip` command.
2. Locate the active Python runtime on your computer.
3. Stream the installation progress in real-time right into the cell output console!

---

## 🔌 2. Using `uses` Directly in Cells

You have total freedom to import only the units you need or let BlaiseNotebook auto-load the defaults:

### Option A: Explicit `uses` (Recommended for clarity)

```pascal
uses BlaisePandas, BlaiseSklearn;

var
  df: TPyDataFrame;
  reg: TPyLinearRegression;
begin
  df := TPyDataFrame.Create;
  df.AddColumn('X', [1.0, 2.0, 3.0]);
  df.AddColumn('Y', [2.0, 4.0, 6.0]);
  
  reg := TPyLinearRegression.Create;
  reg.Fit(df.Column('X'), df.Column('Y'));
  
  ShowText('Slope: ' + FormatFloat('0.00', reg.Slope));
end;
```

### Option B: Zero-Boilerplate (Beginner mode)

If you don't write a `uses` statement, BlaiseNotebook automatically injects the standard libraries (`BlaisePandas`, `BlaiseSklearn`, `BlaiseMathKernel`, etc.) so beginners can focus on learning without worrying about imports!

---

## 🛠️ 3. How to Create Your Own Library in 3 Steps

Creating a reusable library for BlaiseNotebook takes less than a minute.

### Step 1: Duplicate the `_template` Folder

Copy `frontend/server/packages/external/_template` to a new folder in `packages/external/`:
```text
frontend/server/packages/external/finance/
```

### Step 2: Write Your Object Pascal Unit

Create or rename the file to `BlaiseFinance.pas`:

```pascal
unit BlaiseFinance;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes, BlaiseOutput;

type
  TFinanceCalculator = class
  public
    class function CompoundInterest(Principal, Rate: Double; Years: Integer): Double;
  end;

implementation

class function TFinanceCalculator.CompoundInterest(Principal, Rate: Double; Years: Integer): Double;
var
  i: Integer;
begin
  Result := Principal;
  for i := 1 to Years do
    Result := Result * (1.0 + Rate);
end;

end.
```

### Step 3: Use it in Any Notebook Cell Immediately!

Open any notebook and run:

```pascal
uses BlaiseFinance;

begin
  ShowText('Future Value: R$ ' + 
    FormatFloat('#,##0.00', TFinanceCalculator.CompoundInterest(1000.0, 0.10, 5)));
end;
```

> [!TIP]
> **No Server Restart Needed!**
> The `uCodeRunner` scans `packages/external/*` on every compilation. As soon as you save your file in `packages/external/`, it is immediately available!

---

## 🐍 4. Creating a Python Wrapper Library

If you want to wrap a Python library into typed Pascal methods:

1. List the required Python packages in `requirements.txt`:
   ```text
   yfinance>=0.2.36
   ```
2. In your Pascal unit, use `BlaisePyKernel` and `BlaisePandas`:
   ```pascal
   unit BlaiseStock;

   {$mode objfpc}{$H+}

   interface

   uses
     SysUtils, Classes, BlaiseOutput, BlaisePyKernel, BlaisePandas;

   type
     TStockService = class
     public
       class function DownloadHistory(const Ticker: string): TPyDataFrame;
     end;

   implementation

   class function TStockService.DownloadHistory(const Ticker: string): TPyDataFrame;
   var
     VarName: string;
   begin
     EnsurePyPandas;
     TBlaisePy.Exec('import yfinance as yf');
     VarName := NewPyVar('stock');
     TBlaisePy.Exec(Format('%s = yf.download("%s", period="1mo")', [VarName, Ticker]));
     Result := TPyDataFrame.Create(VarName);
   end;

   end.
   ```
3. Now any notebook user can write:
   ```pascal
   uses BlaiseStock;

   var
     df: TPyDataFrame;
   begin
     df := TStockService.DownloadHistory('PETR4.SA');
     df.ShowTable('Price History');
   end;
   ```

---

## 🏛️ 6. 3-Tier Classification Model: Packages vs. Tools

BlaiseNotebook separates reusable assets into two canonical commands aligned with the BlaiseVue ecosystem:

| Classification | Prefix & Naming | Shipped in Framework? | Installation Path | Example |
| :--- | :--- | :--- | :--- | :--- |
| **`[Built-in]`** | `bvnb-*` / `bvnb-tool-*` | **Yes** (core framework bundle) | `frontend/server/packages/` (`core/`, `external/`, `tools/`) | `bvnb-math`, `bvnb-pandas`, `bvnb-tool-data-generator` |
| **`[Co-Official]`** | `bvnb-*` (libs) / `bvnb-tool-*` (tools) | **No** (downloaded on demand from ecosystem) | User workspace: `./packages/<name>/` or `./tools/<name>/` | `bvnb-stats`, `bvnb-tool-sqlite` |
| **`[Third-Party]`** | Community unique names | **No** (downloaded from ecosystem/git) | User workspace: `./packages/<name>/` or `./tools/<name>/` | `fast-fft`, `dataset-validator` |

### CLI Management Commands

#### 📦 Computational Packages (`bvnb pkg` | alias: `bvnb lib`)
* `bvnb pkg list` — Displays built-in core, scientific packages, and workspace packages.
* `bvnb pkg search [query]` — Queries the ecosystem packages registry.
* `bvnb pkg info <name>` — Displays metadata, classification, and Pascal unit entry point.
* `bvnb pkg install <name>` — Installs a co-official or community package into `./packages/<name>/`.
* `bvnb pkg remove <name>` — Removes a package from `./packages/<name>/`.
* `bvnb pkg create <name> [--co-official]` — Scaffolds a complete package structure in `./packages/<name>/`.

#### 🛠️ Auxiliary Tools & Utilities (`bvnb tools` | alias: `bvnb tool`)
* `bvnb tools list` — Displays built-in tools (`packages/tools/`) and workspace tools (`./tools/`).
* `bvnb tools search [query]` — Queries the ecosystem tools registry.
* `bvnb tools info <name>` — Displays tool metadata, documentation, and demo notebooks.
* `bvnb tools run <name> [args...]` — Executes the tool's runner (`run.py`, native binary, or manifest entry) directly from CLI!
* `bvnb tools install <name>` — Installs a co-official or community tool into `./tools/<name>/`.
* `bvnb tools remove <name>` — Removes a tool from `./tools/<name>/`.
* `bvnb tools create <name> [--official | --co-official]` — Scaffolds complete tool structure with `tool.json`, `u<Name>.pas`, `run.py`, `doc/`, and `examples/demo.bynb`.

