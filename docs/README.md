# 📘 BlaiseNotebook User Guide & Documentation

Welcome to **BlaiseNotebook** — the friendly, interactive notebook for **Object Pascal**! If you've ever used Jupyter Notebook or Google Colab, you'll feel right at home. 

BlaiseNotebook lets you write code, explore data, draw beautiful charts, and train AI models — all in real time directly from your browser!

---

## 🌟 What Can You Do with BlaiseNotebook?

- ⚡ **Write & Run Pascal in the Browser**: No complex IDE setup needed. Write Object Pascal code in cells, press `Shift + Enter`, and see results instantly!
- 📊 **Pure Pascal Data Science**: Use powerful Python libraries like **Pandas** and **Scikit-Learn** using native Pascal classes (`TPyDataFrame`, `TPySeries`, `TPyRandomForestRegressor`) — **no Python knowledge required**!
- 📈 **Interactive Charts Under Your Code**: Hardware-accelerated Chart.js line graphs, bar charts, and scatter plots appear right below each code block.
- 📝 **Rich Documentation**: Mix code with beautiful Markdown notes, bullet lists, tables, and LaTeX math formulas.
- 🌓 **Day & Night Themes**: Toggle between a clean, bright Flatly theme and an eye-friendly Dark mode with a single click.
- 💾 **Easy Project Files**: Save and load your work as portable `.bynb` notebook files to share with colleagues or students.
- 📦 **Modular Extensibility**: Install packages with `%pip`, consume libraries with `uses`, and drop new libraries into `packages/external/` with instant zero-restart discovery!

---

## 🧭 Documentation Map

| Guide | Description |
| :--- | :--- |
| 🎓 **[Complete Learning Tracks (Course)](course/README.md)** | **Start here!** A comprehensive 4-track course from absolute beginner to Machine Learning & AI master. |
| 🚀 **[Getting Started Guide](GETTING_STARTED.md)** | Step-by-step beginner guide: launching the app, understanding the toolbar, and running your first cell. |
| 🧪 **[Hands-On Notebooks (Examples 1 to 9)](../examples/README.md)** | Pre-built interactive .bynb notebooks progressing from fundamentals to AI pipelines. |
| 📊 **[Data Science & Machine Learning Guide](SCIENTIFIC_COMPUTING.md)** | How to load datasets, compute statistics, plot charts, and train AI models using pure Pascal. |
| 📦 **[Modular Packages & Extensibility](PACKAGES.md)** | How to install Python packages with `%pip`, consume libraries with `uses`, and build custom Pascal packages. |
| 📖 **[Quick Reference & Cheat Sheet](API_REFERENCE.md)** | Handy copy-paste snippets and summary of all Pascal functions and classes. |
| 💾 **[Notebook Format Guide](NOTEBOOK_FORMAT.md)** | How `.bynb` files store code, outputs, and visual charts. |
| 🏗️ **[System Architecture](ARCHITECTURE.md)** | For curious minds: how the browser frontend communicates with the native Free Pascal kernel. |

---

## ⚡ Quick 30-Second Start

1. Start the BlaiseNotebook server:
   ```bash
   cd frontend
   bv mormot run
   ```
2. Open your browser at **`http://localhost:8090/`**.
3. Click on any code cell and press **`Shift + Enter`** to run it!
4. Check the **[Examples Course](../examples/README.md)** to learn all features step by step!
