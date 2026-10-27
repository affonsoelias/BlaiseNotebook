# 📐 BlaiseNotebook

**BlaiseNotebook** is a pioneering, interactive web-based computational notebook environment for the **Object Pascal** ecosystem (similar to Jupyter Notebook and Google Colab), engineered specifically for **Data Science**, **Artificial Intelligence**, and **High-Performance Scientific Computing**.

By unifying the reactive Single File Component architecture of **BlaiseVue**, hardware-accelerated charting via **Chart.js (`<bv-chart>`)**, ultra-fast asynchronous execution through **Synopse mORMot 2**, native **Free Pascal** mathematical routines, and a 100% cross-platform, zero-dependency bridge to the Python scientific stack (`numpy`, `pandas`, `scikit-learn`), BlaiseNotebook brings modern exploratory data analysis to Object Pascal developers on **Windows, Linux, and macOS**.

---

## ✨ Key Features & Capabilities

- 🔄 **Persistent Stateful Kernel (Shared Daemon)**: Variables and DataFrames created in Cell 1 (e.g. `DF := TPyDataFrame.Create('sales');`) remain live in memory and instantly accessible in subsequent cells without re-running. The session can be reset anytime with **`🔄 Restart Kernel`**.
- ⚡ **Zero-Delay Compilation Cache**: Fast SHA-1 cryptographic signature caching in `uCodeRunner.pas`. Cells with unchanged source skip FPC compilation entirely (0ms compile overhead), dropping execution latency to ~30ms (a 12x speedup).
- 🌍 **100% Cross-Platform & Portable (Windows / Linux)**: Zero hardcoded paths and zero external Lazarus IDE packages required (`Python4Lazarus` is no longer needed). Compiles out-of-the-box with standard **Free Pascal (FPC 3.2.2+)**.
- 🛠️ **Official `bvnb` CLI (Diagnostics, Build & Git Auto-Updater)**: Built-in command-line tool inspired by BlaiseVue's `bv` CLI for environment diagnostics (`bvnb doctor`), one-command compilation (`bvnb build`), Python environment setup (`bvnb setup-python`), and Git channel updates (`bvnb self-update`, `bvnb channel`).
- 💡 **Smart Autocompletion & Real-Time Syntax Highlighting**: Dual-layer synchronized editor with syntax coloring for Pascal keywords, comments, strings, and scientific types. Press `Ctrl + Space` or type `.` after a variable to open interactive autocomplete suggestions.
- 📋 **Interactive DataGrid Pro**: Render tabular datasets with interactive column sorting (numerical and alphabetical), instant in-memory multi-column search, flexible pagination (10, 25, 50, 100 rows), and one-click CSV export ("📋 Copiar CSV" and "💾 Download CSV").
- 📊 **One-Click Dashboard View (Streamlit / Voila Style)**: Toggle between code development and an executive presentation layout with a single click on **`📊 Dashboard View`**. Technical code editors, gutters, and helper cells are cleanly hidden, highlighting only executive Markdown prose, interactive charts, and DataGrid Pro tables.
- ⠿ **Fluid Drag & Drop Cell Reordering**: Reorder Pascal code and Markdown cells smoothly via the `⠿` drag handle with live animated drop slots and full Undo (`Ctrl+Z`) support.
- 📦 **Modular Extensibility & In-Cell `%pip install`**: Extensible package system (`packages/core/` and `packages/external/`) with dynamic discovery and instant pip package installation directly inside code cells.
- 📈 **Hardware-Accelerated Reactive Plots**: Generate Line, Bar, Scatter, and Pie charts directly from Pascal methods (`DF.PlotLine`, `DF.PlotBar`, `DF.PlotScatter`, `DF.PlotPie`) with sequential multi-output stacking.

---

## 📖 Official Documentation

Comprehensive technical guides and references are available in the [`docs/`](docs/README.md) directory:

- 🚀 **[Getting Started & Installation](docs/GETTING_STARTED.md):** Cross-platform compilation (Windows & Linux), `bvnb` CLI usage, and quick-start tutorial.
- 🏛️ **[System Architecture & Internals](docs/ARCHITECTURE.md):** Frontend components, WebSocket lifecycle, persistent daemon, and sandboxing.
- 🔬 **[Scientific Computing & Machine Learning](docs/SCIENTIFIC_COMPUTING.md):** `TVector`, linear regression, Python bridge, and Chart.js plotting.
- 📦 **[Modular Packages & Extensibility](docs/PACKAGES.md):** Architecture of `packages/core/`, `packages/external/`, dynamic `uses`, and `%pip`.
- 📄 **[Notebook File Format Specification (.bynb)](docs/NOTEBOOK_FORMAT.md):** JSON schema, cell state, and output formats.
- 📚 **[Pascal Units & Kernel API Reference](docs/API_REFERENCE.md):** Method signatures, fluent API, and WebSocket event payloads.

---

## 🏛️ System Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   BlaiseVue Frontend (Web SPA / WebUI)                  │
│   <bv-notebook>  •  <bv-cell>  •  <bv-code-editor>  •  <bv-output>     │
│   Syntax Highlighter & Autocomplete  •  DataGrid Pro  •  Undo/Redo & Trash │
│   In-Cell Reactive Chart.js (<bv-chart>)  •  Interactive Markdown      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Bidirectional WebSocket ($ws)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│               Synopse mORMot 2 Kernel (Native Pascal Server)           │
│   Async HTTP / WebSocket Server  •  Cell Execution Orchestrator        │
│   SHA-1 Compilation Cache  •  Cross-Platform FPC & Python Auto-Finder  │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
                    ▼                                ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│       Native Pascal Engine           │  │  Persistent Python Daemon    │
│   Math, Vectors, Linear Regression,  │  │  (localhost:9099 via HTTP)   │
│   Matrix Operations, NumPascal       │  │  pandas, numpy, scikit-learn │
│   Dynamic Package Auto-Discovery     │  │  Stateful Variable Store     │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

---

## 🚀 Quick Start & Compilation (Windows & Linux)

### 1. Prerequisites
- **[Free Pascal Compiler (FPC) 3.2.2+](https://www.freepascal.org/)** (or [Lazarus IDE](https://www.lazarus-ide.org/) — **no external packages like `Python4Lazarus` are required!**)
- **[Python 3.9+](https://www.python.org/)** (with `numpy`, `pandas`, `scikit-learn`)
- **[BlaiseVue CLI (`bv`)](https://github.com/affonsoelias/BlaiseVue)** in your `PATH` (or cloned in a sibling `../BlaiseVue` folder)
- **Git** (for `bvnb self-update` and channel management)

### 2. Cloning the Repository (Important: Use `git clone`)

Always obtain BlaiseNotebook via **`git clone`** rather than downloading a `.zip` archive so that the official `bvnb self-update` and `bvnb channel` Git auto-updater commands work seamlessly:

```bash
git clone https://github.com/affonsoelias/BlaiseNotebook.git
cd BlaiseNotebook
```

### 3. Compiling the Official `bvnb` CLI

Next, compile the lightweight `bvnb` CLI utility from the repository root:

**On Windows (PowerShell / CMD):**
```powershell
fpc -MObjFPC -Sh bin\bvnb.pas
```

**On Linux / macOS (Terminal):**
```bash
fpc -MObjFPC -Sh bin/bvnb.pas
```

*(Tip: Add the `bin/` folder to your system `PATH` to invoke `bvnb` from any directory on your machine!)*

### 4. Diagnosing, Building & Running with `bvnb`

```bash
# 1. Check your environment (FPC, Python 3, NumPy, Pandas, Scikit-Learn, BlaiseVue)
./bin/bvnb doctor

# 2. (Optional) Automatically install numpy, pandas, and scikit-learn if missing
./bin/bvnb setup-python

# 3. Compile the Frontend SPA and Native mORMot 2 Server
./bin/bvnb build

# 4. Launch the BlaiseNotebook server on http://localhost:8090/
./bin/bvnb run
```

---

## 🛠️ Official CLI Reference (`bvnb`)

Inspired by BlaiseVue's `bv` CLI, `bvnb` provides complete lifecycle management, environment diagnostics, and Git auto-updates:

| Command | Description |
| :--- | :--- |
| **`bvnb doctor`** | Runs a complete diagnostic check of your OS, Git, Free Pascal (`fpc`), BlaiseVue (`bv`), Python 3 interpreter, scientific libraries (`numpy`, `pandas`, `scikit-learn`), and server binaries. |
| **`bvnb build`** | Compiles the reactive frontend SPA (`bv run build`) and the native mORMot 2 server (`bv mormot build`). |
| **`bvnb run`** | Starts the native BlaiseNotebook server on `http://localhost:8090/` (auto-builds if the binary is not yet compiled). |
| **`bvnb setup-python`** | Automatically installs or upgrades `numpy`, `pandas`, and `scikit-learn` in the detected Python 3 interpreter. |
| **`bvnb self-update`** | Fetches the latest commits from GitHub (`origin`), pulls changes with `git pull --ff-only`, recompiles `bvnb`, and rebuilds the entire application. |
| **`bvnb self-update --check`** | Checks if new updates are available on GitHub without modifying local files. |
| **`bvnb self-update --channel=develop`** | Switches to the specified branch (`main` or `develop`), pulls the latest updates, and recompiles Everything. |
| **`bvnb channel`** | Displays the active Git channel (`main` stable vs. `develop` bleeding-edge) and current commit hash. |
| **`bvnb channel use <main\|develop>`** | Switches the repository between the `main` (stable) and `develop` (bleeding-edge) channels. |

---

## 🗺️ Product Roadmap

For the completed milestones and upcoming phases, see [ROADMAP.md](ROADMAP.md).

---

## 🧪 Demo Project (`demo.bynb`)

A complete scientific demo project is provided in the repository:
- **Root file**: [`demo.bynb`](demo.bynb)
- **Examples folder**: [`examples/demo_datascience.bynb`](examples/demo_datascience.bynb)

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
