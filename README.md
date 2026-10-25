# 📐 BlaiseNotebook

**BlaiseNotebook** is a pioneering, interactive web-based computational notebook environment for the **Object Pascal** ecosystem (similar to Jupyter Notebook and Google Colab), engineered specifically for **Data Science**, **Artificial Intelligence**, and **High-Performance Scientific Computing**.

By unifying the reactive Single File Component architecture of **BlaiseVue**, hardware-accelerated charting via **Chart.js (`<bv-chart>`)**, ultra-fast asynchronous execution through **Synopse mORMot 2**, native **Free Pascal** mathematical routines, and an out-of-the-box bridge to the Python scientific stack via **Python4Delphi / Python4Lazarus** (`numpy`, `pandas`, `scikit-learn`), BlaiseNotebook brings modern exploratory data analysis to Object Pascal developers worldwide.

---

## 📖 Official Documentation

Comprehensive technical guides and references are available in the [`docs/`](docs/README.md) directory:

- 🚀 **[Getting Started & Installation](docs/GETTING_STARTED.md):** Prerequisites, build steps, and server launch.
- 🏛️ **[System Architecture & Internals](docs/ARCHITECTURE.md):** Frontend components, WebSocket lifecycle, and sandboxing.
- 🔬 **[Scientific Computing & Machine Learning](docs/SCIENTIFIC_COMPUTING.md):** `TVector`, linear regression, Python4Delphi bridge, and Chart.js plotting.
- 📄 **[Notebook File Format Specification (.bynb)](docs/NOTEBOOK_FORMAT.md):** JSON schema, cell state, and output formats.
- 📚 **[Pascal Units & Kernel API Reference](docs/API_REFERENCE.md):** Method signatures and WebSocket event payloads.

---

## 🏛️ System Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   BlaiseVue Frontend (Web SPA / WebUI)                  │
│   <bv-notebook>  •  <bv-cell>  •  <bv-code-editor>  •  <bv-output>     │
│   In-Cell Reactive Chart.js (<bv-chart>)  •  Interactive Markdown      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Bidirectional WebSocket ($ws)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Synopse mORMot 2 Kernel (Native Pascal Server)           │
│   Async HTTP / WebSocket Server  •  Cell Execution Orchestrator        │
│   Dynamic FPC Compilation Sandbox  •  Real-time Output Streaming       │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│       Native Pascal Engine           │  │    Python4Delphi Bridge      │
│   Math, Vectors, Linear Regression,  │  │  pandas, numpy, scikit-learn │
│   Matrix Operations, NumPascal       │  │  Reactive Chart.js outputs   │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

---

## 🗺️ Project Roadmap & Implementation Status

All four foundational stages are **100% implemented, tested, and verified**:

### ✅ Stage 1: BlaiseVue Frontend & Reactive UI Components *(Implemented)*
- [x] **`<bv-notebook>` Canvas**: Clean global toolbar (Run All, Add Code/Markdown, Clear Outputs, Save `.bynb`, Open `.bynb`), reactive WebSocket kernel status pill, and inter-cell insertion dividers.
- [x] **`<bv-cell>` Component**: Polymorphic cell supporting Pascal Code and Markdown, execution counter (`In [ 1 ]:` / `In [ * ]:` / `In [ ]:`), and cell-level controls (reorder, delete, type toggle).
- [x] **`<bv-code-editor>`**: Monospace code editor with line numbers gutter, smart indentation (2 spaces), `Shift + Enter` execution shortcut, and `Ctrl + Enter` in-place execution.
- [x] **`<bv-markdown>`**: Rich Markdown renderer supporting headers, formatted text, blockquotes, lists, and code blocks with double-click inline editing.
- [x] **In-Cell `<bv-output>` Multi-Format Output Area**:
  - `stdout`/`stderr`: Real-time console logs with timestamps and monospace terminal styling.
  - `table`: Responsive data table viewer for tabular datasets and DataFrames.
  - `chart`: Canvas charts powered by **Chart.js** via `<bv-chart>` rendered **directly underneath the code cell**.
- [x] **Clean SPA Layout**: Streamlined interface exclusively focused on the notebook environment.

---

### ✅ Stage 2: mORMot 2 Kernel & WebSocket Execution Engine *(Implemented)*
- [x] **mORMot 2 HTTP & WebSocket Server**: Low-latency, high-throughput asynchronous server hosting static SPA assets and handling bidirectional cell communication over `/ws`.
- [x] **WebSocket Execution Protocol**:
  - `execute_cell`: Transmits cell code, cell ID, and execution count.
  - `stream`: Streams partial `stdout` / `stderr` in real-time as computations proceed.
  - `display_data`: Pushes rich structured payloads (Chart.js JSON configs, table rows/cols).
  - `execute_reply`: Returns execution status, completion timestamps, and elapsed time in milliseconds.
- [x] **Dynamic Sandbox Execution**:
  - Dynamic Free Pascal compilation harness (`uCodeRunner.pas`) invoking `fpc.exe` with real-time output pipes.
  - Fast execution (typical 200–300ms turnaround for compilation and execution).

---

### ✅ Stage 3: Dual Scientific Engines (Native Pascal + Python4Delphi) *(Implemented)*
- [x] **Native Pascal Scientific Unit (`BlaiseMathKernel.pas`)**:
  - Advanced record `TVector` with descriptive statistics (mean, median, standard deviation, variance).
  - Random dataset generators and linear regression fitting (`TLinearRegression`) in pure compiled Pascal.
- [x] **Output Magic Delimiter Protocol (`BlaiseOutput.pas`)**:
  - Magic delimiter `@@BLAISE_PAYLOAD@@:` for zero-copy streaming of tables and charts.
  - Global helper procedures: `ShowChart(Title, ChartType, DataJson)` and `ShowTable(Title, Columns, RowsJson)`.
- [x] **Python4Delphi / Python4Lazarus Bridge (`BlaisePyKernel.pas`)**:
  - Embedded Python 3.13 integration via CPython API.
  - Automatic detection of local Python DLLs (`python313.dll`, `python312.dll`).
  - Seamless execution: `PyRun` and `PyEval`.
  - Chart.js visualization bridges: `ShowPyDataFrame` (Pandas tables), `ShowPySeriesChart` (Chart.js series), `ShowPyDataFrameChart` (multi-column Chart.js curves).

---

### ✅ Stage 4: End-to-End Scientific Demo Notebook *(Implemented)*
- [x] Pre-built demo notebook [`demo.bynb`](demo.bynb) (also located at [`examples/demo_datascience.bynb`](examples/demo_datascience.bynb)):
  1. High-throughput statistical simulation in pure native Pascal (`TVector`).
  2. Dataset manipulation and training with Pandas & Scikit-learn via Python4Delphi.
  3. Interactive canvas visualization using `<bv-chart>` directly under each code block.
- [x] Fully automated WebSocket test harness (`scratch/test_demo_notebook.py`) verifying real-time compilation, Python execution, and Chart.js streaming.

---

## 🧪 Demo Project (`demo.bynb`)

A complete scientific demo project is provided in the repository:
- **Root file**: [`demo.bynb`](demo.bynb)
- **Examples folder**: [`examples/demo_datascience.bynb`](examples/demo_datascience.bynb)

### What it demonstrates:
1. **Cell 1 (Markdown)**: Introduction to the interactive Pascal computing ecosystem.
2. **Cell 2 (Native Pascal Math)**: Generates random vectors, calculates mean and standard deviation, and immediately plots a Bar Chart with `<bv-chart>` under the code.
3. **Cell 3 (Markdown)**: Explains the Python4Delphi bridge.
4. **Cell 4 (Python4Delphi & Scikit-learn)**: Uses Pandas and CPython 3.13 to simulate machine learning iterations, outputs an interactive table (`ShowPyDataFrame`), and plots an accuracy convergence curve with `<bv-chart>` directly under the code cell!

You can load this file anytime using the **📂 Open** button on the toolbar or simply launch the notebook (which preloads it automatically).

---

## 📜 Licensing Agreement

BlaiseNotebook strictly follows the official licensing model of the **Lazarus IDE**, **Free Pascal**, and **BlaiseVue**:

- **Core Framework, Components & Scientific Runtime**:
  Licensed under the **Modified GNU LGPL v2.1 with Static Linking Exception**.  
  *This permits developers, scientists, and commercial entities to build proprietary applications, algorithms, and data pipelines without being required to release their proprietary source code.*

- **Kernel Binaries, CLI Tools & Server Executables**:
  Licensed under the **GNU General Public License v2 (GNU GPL v2)**.

For full legal terms, refer to the [LICENSE](LICENSE) file.

---

## 🚀 Quick Start (Development)

### Prerequisites
- [Free Pascal Compiler](https://www.freepascal.org/) (FPC 3.2.2+)
- [Lazarus IDE](https://www.lazarus-ide.org/) (with `Python4Lazarus` and `BlaiseVue` installed)
- [Python](https://www.python.org/) 3.10+ (with `numpy`, `pandas`, `scikit-learn` installed)
- [BlaiseCLI](https://github.com/affonsoelias/BlaiseVue) (`bv` command on PATH)

### 1. Running the Frontend (Vite / Dev Server)

```bash
cd frontend
bv run dev
# Or start with Hot Module Replacement (HMR):
bv serve
```

Open your browser at **`http://localhost:8080/`**.

### 2. Building & Running the mORMot 2 Native Kernel Server

```bash
cd frontend
# Build the native high-performance server (bin/server.exe)
bv mormot build

# Run the server on port 8090
bv mormot run
```

Access the full-stack application at **`http://localhost:8090/`** (serves SPA frontend and active WebSocket execution kernel on `/ws`).
