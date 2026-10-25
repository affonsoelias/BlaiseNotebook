# 🚀 Getting Started with BlaiseNotebook

This guide will walk you through setting up, compiling, and running BlaiseNotebook on your machine.

---

## 📋 System Prerequisites

Before running BlaiseNotebook, ensure the following dependencies are installed and available on your system:

### 1. Free Pascal Compiler (FPC)
- **Version:** FPC 3.2.2 or newer (64-bit target recommended).
- **Verification:**
  ```bash
  fpc -iV
  # Output: 3.2.2
  ```
- **PATH Requirement:** Ensure `fpc.exe` (or `fpc` on Linux/macOS) is available on your system `PATH`.

### 2. Lazarus IDE & Python4Lazarus
- **Version:** Lazarus 3.0+ with FPC 3.2.2.
- **Python4Lazarus Package:** Required for the Python bridge (`BlaisePyKernel`).
- Available via Lazarus Online Package Manager (OPM) or from [Python4Delphi GitHub repository](https://github.com/pyscripter/python4delphi).

### 3. Python 3.10 – 3.13 (64-bit)
- Standard CPython 64-bit installation matching your OS architecture.
- Recommended scientific libraries:
  ```bash
  pip install numpy pandas scikit-learn websockets
  ```

### 4. BlaiseVue CLI (`bv`)
- The BlaiseVue command-line tool coordinates transpilation, component registration, and mORMot 2 server management.
- Verify installation:
  ```bash
  bv --version
  ```

---

## 🛠️ Installation & Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/affonsoelias/BlaiseNotebook.git
   cd BlaiseNotebook
   ```

2. **Select Working Branch:**
   - Active development takes place on the `develop` branch:
     ```bash
     git checkout develop
     ```

3. **Navigate to the Frontend Directory:**
   ```bash
   cd frontend
   ```

---

## 🖥️ Running the Application

BlaiseNotebook can be run in two primary modes:

### Mode A: Full-Stack Native Server (Recommended)

In this mode, Synopse mORMot 2 serves both the compiled single-page application (SPA) and hosts the native execution kernel over WebSocket (`/ws` on port `8090`):

```bash
# 1. Compile the reactive frontend assets
bv run build

# 2. Compile the high-performance mORMot 2 server binary
bv mormot build

# 3. Launch the native server
bv mormot run
```

- Open your browser at: **`http://localhost:8090/`**
- The status pill in the upper-right corner will turn green: **`● Kernel mORMot 2 Connected`**.

### Mode B: Standalone Web Simulator

If you run the frontend independently without starting the mORMot 2 server (e.g., using `bv serve` or opening `dist/index.html`):
- The status pill will display **`● Standalone Mode (Active Simulator)`**.
- The built-in intelligent simulator will parse scientific code patterns, generate descriptive statistics, and render Chart.js graphs and responsive tables directly in the browser!

---

## ⌨️ Keyboard Shortcuts

BlaiseNotebook is designed for rapid exploratory programming using standard notebook keybindings:

| Action | Shortcut | Scope |
| :--- | :--- | :--- |
| **Execute Cell** | `Shift + Enter` | Focused code cell |
| **Execute Cell In-Place** | `Ctrl + Enter` | Focused code cell |
| **Smart Indent (2 spaces)** | `Tab` | Code editor |
| **Save Notebook (.bynb)** | `Ctrl + S` | Global |
| **Open Notebook** | `Ctrl + O` | Global |
| **New Notebook** | `Alt + N` | Global |
| **Add Code Cell** | `Alt + C` | Global |
| **Toggle Light / Dark Mode** | Navbar Moon/Sun icon (`☀️`/`🌙`) | Global |

---

## 🧪 Loading the Scientific Demo Project

A pre-packaged demo notebook [`demo.bynb`](../demo.bynb) is included with the project. It provides:
1. **Introduction Markdown:** An overview of the Object Pascal computational environment.
2. **Native Pascal Mathematical Block:** Random vector generation, sample mean, standard deviation, and inline Bar Chart plotting with Chart.js.
3. **Python Bridge Documentation:** Explanation of CPython 3.13 integration.
4. **Machine Learning Pipeline:** Pandas DataFrame training history and model convergence line curve rendered under the cell.

You can reload or save notebooks at any time using the **`📂 Open`** and **`💾 Save (.bynb)`** buttons in the toolbar.
