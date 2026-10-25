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

## 🗺️ Product Roadmap

For the strategic evolutionary roadmap and planned milestones, see [ROADMAP.md](ROADMAP.md).

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

Access the full-stack application at **`http://localhost:8090/`** (serves SPA frontend and active WebSocket execution kernel on `/ws`).
