# 📐 BlaiseNotebook

**BlaiseNotebook** is a pioneering, interactive web-based computational notebook environment for the **Object Pascal** ecosystem (similar to Jupyter Notebook and Google Colab), engineered specifically for **Data Science**, **Artificial Intelligence**, and **High-Performance Scientific Computing**.

By unifying the reactive Single File Component architecture of **BlaiseVue**, hardware-accelerated charting via **Chart.js (`<bv-chart>`)**, ultra-fast asynchronous execution through **Synopse mORMot 2**, native **Free Pascal** mathematical routines, and an out-of-the-box bridge to the Python scientific stack via **Python4Delphi / Python4Lazarus** (`numpy`, `pandas`, `scikit-learn`), BlaiseNotebook brings modern exploratory data analysis to Object Pascal developers worldwide.

---

## ✨ Key Features & Capabilities

- 🔄 **Persistent Stateful Kernel (Shared Daemon)**: Variables and DataFrames created in Cell 1 (e.g. `DF := TPyDataFrame.Create('sales');`) remain live in memory and instantly accessible in subsequent cells without re-running. The session can be reset anytime with **`🔄 Restart Kernel`**.
- ⚡ **Zero-Delay Compilation Cache**: Fast SHA-1 cryptographic signature caching in `uCodeRunner.pas`. Cells with unchanged source skip FPC compilation entirely (0ms compile overhead), dropping execution latency to ~30ms (a 12x speedup).
- 💡 **Smart Autocompletion & Real-Time Syntax Highlighting**: Dual-layer synchronized editor with syntax coloring for Pascal keywords, comments, strings, and scientific types. Press `Ctrl + Space` or type `.` after a variable to open interactive autocomplete suggestions.
- 📋 **Interactive DataGrid Pro**: Render tabular datasets with interactive column sorting (numerical and alphabetical), instant in-memory multi-column search, flexible pagination (10, 25, 50, 100 rows), and one-click CSV export ("📋 Copiar CSV" and "💾 Download CSV").
- 📊 **One-Click Dashboard View (Streamlit / Voila Style)**: Toggle between code development and an executive presentation layout with a single click on **`📊 Dashboard View`**. Technical code editors, gutters, and helper cells are cleanly hidden, highlighting only executive Markdown prose, interactive charts, and DataGrid Pro tables.
- 📦 **Modular Extensibility & In-Cell `%pip install`**: Extensible package system (`packages/core/` and `packages/external/`) with dynamic discovery and instant pip package installation directly inside code cells.
- 📈 **Hardware-Accelerated Reactive Plots**: Generate Line, Bar, Scatter, and Pie charts directly from Pascal methods (`DF.PlotLine`, `DF.PlotBar`, `DF.PlotScatter`, `DF.PlotPie`) with sequential multi-output stacking.

---

## 📖 Official Documentation

Comprehensive technical guides and references are available in the [`docs/`](docs/README.md) directory:

- 🚀 **[Getting Started & Installation](docs/GETTING_STARTED.md):** Prerequisites, build steps, and server launch.
- 🏛️ **[System Architecture & Internals](docs/ARCHITECTURE.md):** Frontend components, WebSocket lifecycle, persistent daemon, and sandboxing.
- 🔬 **[Scientific Computing & Machine Learning](docs/SCIENTIFIC_COMPUTING.md):** `TVector`, linear regression, Python4Delphi bridge, and Chart.js plotting.
- 📦 **[Modular Packages & Extensibility](docs/PACKAGES.md):** Architecture of `packages/core/`, `packages/external/`, dynamic `uses`, and `%pip`.
- 📄 **[Notebook File Format Specification (.bynb)](docs/NOTEBOOK_FORMAT.md):** JSON schema, cell state, and output formats.
- 📚 **[Pascal Units & Kernel API Reference](docs/API_REFERENCE.md):** Method signatures, fluent API, and WebSocket event payloads.

---

## 🏛️ System Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   BlaiseVue Frontend (Web SPA / WebUI)                  │
│   <bv-notebook>  •  <bv-cell>  •  <bv-code-editor>  •  <bv-output>     │
│   Syntax Highlighter & Autocomplete  •  DataGrid Pro  •  Dashboard View │
│   In-Cell Reactive Chart.js (<bv-chart>)  •  Interactive Markdown      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Bidirectional WebSocket ($ws)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Synopse mORMot 2 Kernel (Native Pascal Server)           │
│   Async HTTP / WebSocket Server  •  Cell Execution Orchestrator        │
│   SHA-1 Compilation Cache  •  Persistent Session Daemon Controller    │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│       Native Pascal Engine           │  │  Persistent Python Daemon    │
│   Math, Vectors, Linear Regression,  │  │  (localhost:9099)            │
│   Matrix Operations, NumPascal       │  │  pandas, numpy, scikit-learn │
│   Dynamic Package Auto-Discovery     │  │  Stateful Variable Store     │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

---

## 🗺️ Product Roadmap

For the completed milestones and evolution history, see [ROADMAP.md](ROADMAP.md).

---

## 🧪 Demo Project (`demo.bynb`)

A complete scientific demo project is provided in the repository:
- **Root file**: [`demo.bynb`](demo.bynb)
- **Examples folder**: [`examples/demo_datascience.bynb`](examples/demo_datascience.bynb)

### What it demonstrates:
1. **Cell 1 (Markdown)**: Introduction to the interactive Pascal computing ecosystem.
2. **Cell 2 (Native Pascal Math)**: Generates random vectors, calculates mean and standard deviation, and immediately plots a Bar Chart with `<bv-chart>` under the code.
3. **Cell 3 (Markdown)**: Explains the persistent Python bridge and fluent DataFrames.
4. **Cell 4 (Data Science & Scikit-Learn)**: Uses Pandas and Scikit-Learn to simulate predictive modeling, displays an interactive DataGrid Pro table (`DF.ShowTable`), and renders accuracy convergence plots with `<bv-chart>`.

Load this file anytime using the **📂 Open** button on the toolbar or simply launch the notebook (which preloads it automatically).

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

## 🚀 Quick Start

### Prerequisites
- [Free Pascal Compiler](https://www.freepascal.org/) (FPC 3.2.2+)
- [Lazarus IDE](https://www.lazarus-ide.org/) (with `Python4Lazarus` and `BlaiseVue` installed)
- [Python](https://www.python.org/) 3.10+ (with `numpy`, `pandas`, `scikit-learn` installed)
- [BlaiseVue](https://github.com/affonsoelias/BlaiseVue) (`bv` command on PATH)

### Running the Application

```bash
cd frontend
# Build the native high-performance server (bin/server.exe)
bv mormot build

# Run the server on port 8090
bv mormot run
```

Then open your browser at **`http://localhost:8090/`**.
