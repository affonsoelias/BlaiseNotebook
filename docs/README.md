# 📐 BlaiseNotebook Documentation

Welcome to the official documentation for **BlaiseNotebook** — the premier interactive scientific computing notebook designed specifically for the **Object Pascal** ecosystem.

BlaiseNotebook unites the compiled execution speed of **Free Pascal**, the vast machine learning and data science ecosystem of **Python** (via Python4Delphi), the low-latency asynchronous server architecture of **Synopse mORMot 2**, and the reactive Web component model of **BlaiseVue** with **Chart.js (`<bv-chart>`)**.

---

## 📚 Table of Contents

1. [Getting Started & Installation](GETTING_STARTED.md)
   - System Prerequisites (FPC, Lazarus, Python, BlaiseVue CLI)
   - Running the Web Application
   - Compiling and Launching the mORMot 2 Kernel Server
   - Quick Workflow Walkthrough

2. [System Architecture & Internals](ARCHITECTURE.md)
   - Component Hierarchy & Reactive Frontend (`<bv-notebook>`, `<bv-cell>`, `<bv-code-editor>`, `<bv-output>`)
   - Bidirectional WebSocket Execution Protocol (`execute_cell`, `stream`, `display_data`, `execute_reply`, `interrupt_all`)
   - Native Server Sandboxing & FPC Compilation Harness (`uCodeRunner.pas`)
   - Standalone Simulator Fallback

3. [Scientific Computing & Machine Learning Guide](SCIENTIFIC_COMPUTING.md)
   - Native Pascal Mathematics with `BlaiseMathKernel.pas` (`TVector`, Mean, StdDev, Linear Regression)
   - Python Bridge with `BlaisePyKernel.pas` (NumPy, Pandas, Scikit-Learn)
   - In-Cell Hardware-Accelerated Visualizations with `BlaiseOutput.pas` (`ShowChart`, `ShowTable`, `ShowPyDataFrame`)

4. [Notebook File Format Specification (.bynb)](NOTEBOOK_FORMAT.md)
   - JSON Schema Definition
   - Metadata, Cell Objects, and Output Payloads
   - Interoperability with Jupyter Notebooks

5. [Pascal & Kernel API Reference](API_REFERENCE.md)
   - `BlaiseMathKernel` Unit Reference
   - `BlaisePyKernel` Unit Reference
   - `BlaiseOutput` Unit Reference
   - WebSocket Message Payloads & Events

---

## ⚡ Key Highlights

| Feature | Description |
| :--- | :--- |
| **🏎️ Compiled Speed** | Direct compilation to native Win64/Linux x86_64 machine code using Free Pascal Compiler (FPC 3.2.2+). |
| **🐍 Python Integration** | Native CPython 3.10–3.13 API bridge via Python4Delphi, sharing memory structures and NumPy arrays. |
| **📈 In-Cell Charting** | Interactive line, bar, scatter, radar, and doughnut charts rendered via Chart.js directly beneath each code cell. |
| **⏹ Execution Control** | Asynchronous execution queue with instantaneous interrupt capabilities (`⏹ Interrupt`). |
| **🎨 Responsive UI** | Built with BlaiseVue, featuring Flatly Light and Darkly Dark modes, drawer project menu, and keyboard shortcuts (`Shift+Enter`, `Ctrl+Enter`). |
| **📜 Open Source License** | Core runtime and components licensed under **Modified LGPL v2.1 with Static Linking Exception**; Kernel binaries under **GPL v2**. |
