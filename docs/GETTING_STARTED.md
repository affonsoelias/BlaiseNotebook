# 🚀 Getting Started with BlaiseNotebook

Welcome to BlaiseNotebook! This friendly guide walks you through launching the tool, navigating the interface, writing code with intelligent autocompletion, exploring tables with DataGrid Pro, drawing charts, and presenting in Dashboard View.

---

## 🏁 Step 1: Starting the Application

Starting BlaiseNotebook is as simple as running a single command:

```bash
cd frontend
bv mormot run
```

Then open your favorite web browser and go to:
👉 **`http://localhost:8090/`**

> **💡 Status Check:** Look at the pill in the top-right corner of the screen. When it shows a green dot **`● Kernel Connected`**, your notebook is connected to the native Pascal engine!

---

## 🖥️ Step 2: Getting to Know the Interface

BlaiseNotebook is designed to be clean, intuitive, and distraction-free:

```text
+-----------------------------------------------------------------------------------------------+
| ▶▶ Run All | ⏹ Interrupt | 🔄 Restart Kernel | ➕ Code | ➕ Markdown | 🧹 Clear | 📊 Dashboard |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
| [1] In: [ Pascal Code Cell ]                                                                  |
|     uses BlaiseDataScience;                                                                   |
|     var DF: TPyDataFrame;                                                                     |
|     begin                                                                                     |
|       DF := TPyDataFrame.Create('sales');                                                     |
|       DF.AddColumn('Month', ['Jan', 'Feb', 'Mar']);                                           |
|       DF.AddColumn('Revenue', [12000, 18500, 24000]);                                         |
|       DF.ShowTable('Q1 Revenue', 10);                                                         |
|     end.                                                                                      |
|                                                                                               |
|     Out:                                                                                      |
|     [ 📋 Interactive DataGrid Pro with Sorting, Live Search, Pagination & CSV Export ]       |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+
```

### The Top Toolbar:
- **▶▶ Run All:** Executes every code cell in your notebook in sequential order.
- **⏹ Interrupt:** Immediately halts long-running calculations.
- **🔄 Restart Kernel:** Resets the continuous session memory, clearing all live variables and daemon state.
- **➕ Pascal Code:** Adds a new executable Object Pascal code cell.
- **➕ Documentation:** Adds a new formatted Markdown text cell for notes or formulas.
- **🧹 Clear Outputs:** Clears execution counts and all output areas across the notebook.
- **📊 Dashboard View:** Alternates between Code Development mode and Executive Presentation mode with a single click.
- **💾 Save (.bynb):** Downloads your current notebook state as a portable `.bynb` JSON file.
- **📂 Open:** Loads an existing `.bynb` file from your computer.

---

## ✍️ Step 3: Writing & Running Code with Autocompletion

1. Click on any code cell.
2. Notice the **Real-Time Syntax Highlighting**: Pascal keywords (`begin`, `end`, `var`, `procedure`), scientific types (`TPyDataFrame`, `TPySeries`, `TVector`), strings, and comments are colorized instantly.
3. Use **Intelligent Autocomplete**:
   - Press **`Ctrl + Space`** anywhere to open the autocomplete menu.
   - Type a dot **`.`** after any variable (e.g., `DF.`) to open fluent Data Science method suggestions:
     - `.AddColumn(Name, Values)`
     - `.ShowTable(Title, MaxRows)`
     - `.PlotLine(XCol, YCol, Title)`
     - `.PlotBar(XCol, YCol, Title)`
     - `.PlotScatter(XCol, YCol, Title)`
     - `.PlotPie(Col, Title)`
     - `.ToCSV(FilePath)`
   - Use **`ArrowUp` / `ArrowDown`** to navigate and **`Enter`** or **`Tab`** to insert.
4. Press **`Shift + Enter`** on your keyboard (or click the green **▶ Run** button on the cell header).
5. Thanks to the **Zero-Delay Compilation Cache**, unchanged cells re-execute in only ~30ms (0ms compile overhead)!

---

## 📋 Step 4: Exploring Tables with DataGrid Pro

When a cell calls `DF.ShowTable(...)`, it renders an interactive **DataGrid Pro** card:

- 🔼 **Column Sorting:** Click any column header to sort ascending (`▲`), descending (`▼`), or reset (`⇅`). Numbers and text sort accurately.
- 🔍 **Live Search:** Type in the `🔍 Buscar...` input to filter rows in real-time across all columns.
- 📄 **Pagination:** Select between 10, 25, 50, or 100 rows per page, and navigate smoothly with `⏮`, `◀`, `▶`, `⏭`.
- 📋 **One-Click CSV Export:**
  - Click **`📋 Copiar CSV`** to copy the table directly to your clipboard.
  - Click **`💾 Download CSV`** to download a formatted `.csv` file.

---

## 📊 Step 5: Executive Presentation with Dashboard View

Want to present your findings to clients, colleagues, or stakeholders without showing lines of Pascal code?

1. Click **`📊 Dashboard View`** on the top toolbar.
2. Watch the notebook transform into an executive dashboard (Streamlit / Voila style):
   - Code editors, line gutters, cell action buttons, and technical prompts disappear.
   - Cells with purely internal code (like imports and variable assignments) are automatically hidden.
   - Markdown cells render as clean executive section headers and analytical reports.
   - Charts and DataGrid Pro tables expand into full-width responsive presentation cards.
3. Click **`✏️ Modo Edição`** (or the exit button on the purple dashboard banner) whenever you want to return to editing code.

---

## 🔄 Step 6: Stateful Kernel & Cross-Cell Variables

Variables created in previous cells persist throughout your entire session!

```pascal
// In Cell 1:
uses BlaiseDataScience;
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create('dados_vendas');
  DF.AddColumn('Produto', ['Teclado', 'Mouse', 'Monitor']);
  DF.AddColumn('Preco',   [250.0, 85.0, 1400.0]);
  Writeln('DataFrame inicializado na memória!');
end.
```

```pascal
// In Cell 2 (executes immediately using the live DataFrame!):
uses BlaiseDataScience;
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create('dados_vendas');
  DF.ShowTable('Produtos Carregados da Célula 1', 10);
  DF.PlotBar('Preços por Produto', 'Produto', 'Preco');
end.
```

To clear all memory and reset the daemon, simply click **`🔄 Restart Kernel`** on the toolbar.

---

## ⌨️ Handy Keyboard Shortcuts

Save time and code faster with these built-in shortcuts:

| Shortcut | What it does |
| :--- | :--- |
| **`Shift + Enter`** | Run current cell and focus next. |
| **`Ctrl + Enter`** | Run current cell in-place. |
| **`Ctrl + Space`** | Trigger intelligent autocompletion popup. |
| **`Tab`** | Smart indent code by 2 spaces (or insert selected suggestion). |
| **`ArrowUp / Down`** | Navigate through autocomplete suggestions. |
| **`Esc`** | Dismiss autocomplete popup. |
| **Double-Click** | Edit any Markdown documentation cell. |

---

## 🎓 Next Steps: Take the Hands-On Course!

Ready to explore all features? Head over to our **[Hands-On Course Guide](../examples/README.md)** with complete progressive examples covering data manipulation, statistics, machine learning, and interactive dashboards!
