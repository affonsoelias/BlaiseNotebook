# 🚀 Getting Started with BlaiseNotebook

Welcome to BlaiseNotebook! This guide walks you through installing prerequisites on **Windows** or **Linux**, cloning via `git clone`, compiling and adding the official **`bvnb` CLI** to your system `PATH`, launching the server, and exploring all interactive features.

---

## 🛠️ Step 1: Prerequisites & Cross-Platform Setup (Windows & Linux)

BlaiseNotebook is **100% cross-platform and portable**. It does **not** require any external Lazarus packages (`Python4Lazarus` is no longer needed) or hardcoded paths.

### Required Tools:
1. **Free Pascal Compiler (`fpc` 3.2.2+)** (or Lazarus IDE)
   - **Windows**: Install [Lazarus IDE](https://www.lazarus-ide.org/) or standalone Free Pascal.
   - **Linux (Ubuntu / Debian)**: `sudo apt update && sudo apt install fpc python3 python3-pip git`
2. **Python 3.9+** with `numpy`, `pandas`, and `scikit-learn`
3. **BlaiseVue CLI (`bv`)** available in your system `PATH` (or in a sibling `../BlaiseVue` directory).

---

## ⚡ Step 2: Cloning with `git clone`, Compiling `bvnb` & Configuring `PATH`

> **⚠️ Important:** Always download the project using **`git clone`** (instead of downloading a `.zip` file). This preserves the `.git` repository metadata required by the **`bvnb self-update`** and **`bvnb channel`** auto-updater commands!

```bash
git clone https://github.com/affonsoelias/BlaiseNotebook.git
cd BlaiseNotebook
```

### 2.1 Compile the `bvnb` CLI

From the root directory of `BlaiseNotebook`, compile the official **`bvnb`** CLI utility once using Free Pascal:

**On Windows (PowerShell / CMD):**
```powershell
fpc -MObjFPC -Sh bin\bvnb.pas
```

**On Linux / macOS:**
```bash
fpc -MObjFPC -Sh bin/bvnb.pas
```

### 2.2 Add `bvnb` to your System `PATH` & Refresh the Terminal

To invoke `bvnb` from **any directory** on your computer, add the `bin/` folder to your user `PATH` and reload your terminal environment:

**On Windows (PowerShell — Run inside the `BlaiseNotebook` folder):**
```powershell
# 1. Permanently add the bin\ folder to your Windows User PATH:
$BinPath = (Resolve-Path ".\bin").Path
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinPath", "User")
    Write-Host "Added $BinPath to User PATH!" -ForegroundColor Green
}

# 2. Refresh the current terminal session immediately (no need to close the window):
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
```

**On Linux / macOS (Bash / Zsh — Run inside the `BlaiseNotebook` folder):**
```bash
# 1. Permanently add the bin/ folder to your ~/.bashrc (or ~/.zshrc):
echo "export PATH=\"\$PATH:$(pwd)/bin\"" >> ~/.bashrc

# 2. Refresh the current terminal session immediately:
source ~/.bashrc
```

### 2.3 Diagnose, Build & Run with `bvnb`

Now you can run `bvnb` directly from any folder:

```bash
# 1. Verify your environment (FPC, Python 3, NumPy, Pandas, Scikit-Learn, BlaiseVue)
bvnb doctor

# 2. Install scientific Python dependencies automatically (if needed)
bvnb setup-python

# 3. Build the Frontend SPA and Native mORMot 2 Server
bvnb build

# 4. Start the server on http://localhost:8090/
bvnb run
```

> **💡 Keeping BlaiseNotebook Updated via Git:**
> Just like BlaiseVue's `bv self-update`, you can check for updates or upgrade BlaiseNotebook directly from GitHub anytime:
> - `bvnb self-update --check` — Check if new commits are available on GitHub.
> - `bvnb self-update` — Pull the latest changes and automatically recompile `bvnb`, the frontend, and the native server.
> - `bvnb channel use main` or `bvnb channel use develop` — Switch between the stable release channel and the development channel.

*(Alternatively, you can also run `cd frontend && bv mormot build && bv mormot run` directly).*

---

## 🏁 Step 3: Opening the Notebook Interface

Once `bvnb run` is running, open your browser and navigate to:
👉 **`http://localhost:8090/`**

> **💡 Status Check:** Look at the pill in the top-right corner of the screen. When it shows a green dot **`● Kernel Connected`**, your notebook is connected to the native Pascal engine!

---

## 🖥️ Step 4: Getting to Know the Interface

BlaiseNotebook is designed to be clean, intuitive, and distraction-free:

```text
+-----------------------------------------------------------------------------------------------+
| ▶▶ Run All | ⏹ Interrupt | 🔄 Restart Kernel | ➕ Code | ➕ Markdown | 🧹 Clear | 📊 Dashboard |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
| ⠿ [1] In: [ Pascal Code Cell ]                                                                |
|       uses BlaiseDataScience;                                                                 |
|       var DF: TPyDataFrame;                                                                   |
|       begin                                                                                   |
|         DF := TPyDataFrame.Create('sales');                                                   |
|         DF.AddColumn('Month', ['Jan', 'Feb', 'Mar']);                                         |
|         DF.AddColumn('Revenue', [12000, 18500, 24000]);                                       |
|         DF.ShowTable('Q1 Revenue', 10);                                                       |
|       end.                                                                                    |
|                                                                                               |
|       Out:                                                                                    |
|       [ 📋 Interactive DataGrid Pro with Sorting, Live Search, Pagination & CSV Export ]     |
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
- **⠿ Drag Handle:** Grab the `⠿` icon on the left of any cell header to smoothly drag and reorder cells with live animated slot previews.

---

## ✍️ Step 5: Writing & Running Code with Autocompletion

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

## 📋 Step 6: Exploring Tables with DataGrid Pro

When a cell calls `DF.ShowTable(...)`, it renders an interactive **DataGrid Pro** card:

- 🔼 **Column Sorting:** Click any column header to sort ascending (`▲`), descending (`▼`), or reset (`⇅`). Numbers and text sort accurately.
- 🔍 **Live Search:** Type in the `🔍 Search...` input to filter rows in real-time across all columns.
- 📄 **Pagination:** Select between 10, 25, 50, or 100 rows per page, and navigate smoothly with `⏮`, `◀`, `▶`, `⏭`.
- 📋 **One-Click CSV Export:**
  - Click **`📋 Copy CSV`** to copy the table directly to your clipboard.
  - Click **`💾 Download CSV`** to download a formatted `.csv` file.

---

## 📊 Step 7: Executive Presentation with Dashboard View

Want to present your findings to clients, colleagues, or stakeholders without showing lines of Pascal code?

1. Click **`📊 Dashboard View`** on the top toolbar.
2. Watch the notebook transform into an executive dashboard (Streamlit / Voila style):
   - Code editors, line gutters, cell action buttons, and technical prompts disappear.
   - Cells with purely internal code (like imports and variable assignments) are automatically hidden.
   - Markdown cells render as clean executive section headers and analytical reports.
   - Charts and DataGrid Pro tables expand into full-width responsive presentation cards.
3. Click **`✏️ Edit Mode`** (or the exit button on the purple dashboard banner) whenever you want to return to editing code.

---

## 🔄 Step 8: Stateful Kernel & Cross-Cell Variables

Variables created in previous cells persist throughout your entire session!

```pascal
// In Cell 1:
uses BlaiseDataScience;
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create('sales_data');
  DF.AddColumn('Product', ['Keyboard', 'Mouse', 'Monitor']);
  DF.AddColumn('Price',   [50.0, 17.0, 280.0]);
  Writeln('DataFrame initialized in memory!');
end.
```

```pascal
// In Cell 2 (executes immediately using the live DataFrame!):
uses BlaiseDataScience;
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create('sales_data');
  DF.ShowTable('Products Loaded from Cell 1', 10);
  DF.PlotBar('Prices by Product', 'Product', 'Price');
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
