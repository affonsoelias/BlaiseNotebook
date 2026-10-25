# BlaiseNotebook Component Suite (`blaise-notebook`)

Interactive Scientific Notebook & Computation Canvas for **BlaiseVue**.

`blaise-notebook` is an extensible, reactive component library designed for Object Pascal data science, scientific visualization, AI workflows, and live interactive coding.

---

## 📦 Installed Components

| Component | Tag | Description |
|---|---|---|
| **Notebook Canvas** | `<bv-notebook />` | Orchestrates notebook state, persistence, cell management, and kernel execution. |
| **Cell Container** | `<bv-cell />` | Renders an individual reactive cell (code block or markdown section) with gutter and controls. |
| **Pascal Code Editor** | `<bv-code-editor />` | Monaco / Ace syntax-highlighted editor with Pascal auto-indentation and shortcuts. |
| **Markdown Renderer** | `<bv-markdown />` | High-fidelity Markdown renderer with math KaTeX formula support (`$..$` and `$$..$$`). |
| **Execution Output** | `<bv-output />` | Reactive outputs: Console logs, HTML widgets, DataFrames, and Chart.js visuals. |

---

## 🚀 Usage

Simply import or drop `<bv-notebook />` into your view:

```html
<template>
  <div class="notebook-container">
    <bv-notebook></bv-notebook>
  </div>
</template>
```

---

## ⚙️ Architecture

- **`BlaiseNotebook.pas`**: Central Object Pascal unit exposing strongly-typed helpers, DOM scroll management, and reactive event bridging.
- **Backend Kernel**: Communicates with the native Pascal backend (`/api/execute`) via HTTP/REST.
- **License**: Modified LGPL v2.1 with Static Linking Exception.
