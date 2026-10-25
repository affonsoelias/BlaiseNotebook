# 🚀 Getting Started with BlaiseNotebook

Welcome to BlaiseNotebook! This friendly guide walks you through launching the tool, navigating the interface, writing code, and viewing interactive charts.

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

```
+------------------------------------------------------------------------------------+
| 📁 Project | ➕ Code | ➕ Markdown | ▶ Run All | ⏹ Stop | 🗑 Clear | 🌓 Dark | ● Online |
+------------------------------------------------------------------------------------+
|                                                                                    |
| [1] In: [ Code Cell ]                                                              |
|     begin                                                                          |
|       Writeln('Hello, World!');                                                    |
|     end.                                                                           |
|                                                                                    |
|     Out:                                                                           |
|     Hello, World!                                                                  |
|     [ 📈 Interactive Chart or Table renders directly here ]                        |
|                                                                                    |
+------------------------------------------------------------------------------------+
```

### The Top Toolbar:
- **📁 Project:** Opens the project sidebar to create a new notebook, open a `.bynb` file from your computer, or save your current notebook.
- **➕ Code:** Adds a new executable Object Pascal code cell.
- **➕ Markdown:** Adds a new formatted text cell for notes, instructions, or formulas.
- **▶ Run All:** Executes every cell in your notebook from top to bottom.
- **⏹ Stop (Interrupt):** Immediately halts long-running calculations.
- **🗑 Clear:** Clears execution counts and output areas so you can start fresh.
- **🌓 Theme Toggle:** Switches between clean Flatly Light mode and dark mode.

---

## ✍️ Step 3: Writing & Running Your First Code

1. Click on the first code cell.
2. Type a simple Pascal statement:
   ```pascal
   Writeln('Hello from BlaiseNotebook!');
   Writeln('2 + 2 = ', 2 + 2);
   ```
3. Press **`Shift + Enter`** on your keyboard (or click the green **▶ Run** button on the cell).
4. Watch the execution badge change:
   - `[ * ]` while running (with time elapsed in milliseconds).
   - `[ 1 ]` with a green checkmark when complete!
5. Your output appears immediately underneath the cell.

---

## ⌨️ Handy Keyboard Shortcuts

Save time and code faster with these built-in shortcuts:

| Shortcut | What it does |
| :--- | :--- |
| **`Shift + Enter`** | Run the current cell and select the next one. |
| **`Ctrl + Enter`** | Run the current cell and stay on it. |
| **`Tab`** | Smart indent code by 2 spaces. |
| **Double-Click** | Edit any Markdown cell to update notes. |

---

## 📊 Step 4: Drawing Your First Chart

Creating interactive charts is as easy as writing one line of Pascal:

```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Month', ['Jan', 'Feb', 'Mar', 'Apr', 'May']);
  DF.AddColumn('Sales', [120.0, 150.0, 180.0, 220.0, 310.0]);
  
  // Plot a beautiful line chart under the cell:
  DF.PlotLine('Monthly Sales Growth', 'Month', 'Sales');
end;
```

When you press `Shift + Enter`, a smooth Chart.js canvas appears right below your code, complete with tooltips when you hover over data points!

---

## 🎓 Next Steps: Take the Hands-On Course!

Ready to master all features of BlaiseNotebook? Head over to our **[Hands-On Course Guide](../examples/README.md)** with 7 complete progressive examples from beginner to advanced machine learning!
