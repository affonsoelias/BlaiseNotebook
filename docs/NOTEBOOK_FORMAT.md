# 💾 Notebook File Format (.bynb)

BlaiseNotebook stores your work in a clean, human-readable format with the extension **`.bynb`** (*BlaiseVue Notebook*).

---

## 📄 What is a `.bynb` File?

A `.bynb` file is a standard JSON file that saves:
1. **Metadata**: The title, author, and runtime configuration of your notebook.
2. **Cells**: The code and Markdown notes you've written.
3. **Outputs**: Text outputs (`stdout`), error messages (`stderr`), and interactive visual payloads (Chart.js graphs and data tables).

Because it is standard JSON, you can easily:
- Store notebooks in **Git** repositories.
- Share them via email, Slack, or GitHub.
- Open them on any machine running BlaiseNotebook.

---

## 🗂️ How to Save and Open Notebooks

### Saving Your Work:
1. Click the **📁 Project** button in the top toolbar to open the sidebar.
2. Click **💾 Export Notebook (.bynb)**.
3. Your browser will download the `.bynb` file directly to your computer.

### Opening an Existing Notebook:
1. Click the **📁 Project** button.
2. Click **📂 Open Project (.bynb)** and choose the file from your computer.
3. All your cells, code, notes, and previous charts will load instantly!

---

## 🔍 Structure of a Notebook File

For developers and technical users, here is what a `.bynb` looks like inside:

```json
{
  "metadata": {
    "name": "my_analysis",
    "framework": "BlaiseVue",
    "engine": "Synopse mORMot 2 + Free Pascal + Python4Delphi",
    "version": "1.0.0"
  },
  "cells": [
    {
      "id": "cell_1",
      "type": "markdown",
      "source": "# My First Analysis\nThis is a note."
    },
    {
      "id": "cell_2",
      "type": "code",
      "source": "Writeln('Hello World');",
      "execution_count": 1,
      "status": "success",
      "outputs": [
        {
          "type": "stream",
          "stream": "stdout",
          "text": "Hello World\n"
        }
      ]
    }
  ]
}
```
