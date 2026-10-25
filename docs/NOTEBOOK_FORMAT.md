# 📄 BlaiseNotebook File Format (.bynb)

BlaiseNotebook persists computational notebooks in a clean, human-readable JSON-based specification with the `.bynb` file extension.

---

## 📐 Top-Level Document Structure

A `.bynb` file consists of two primary root keys: `metadata` and `cells`.

```json
{
  "metadata": {
    "name": "analysis_experiment",
    "framework": "BlaiseVue",
    "engine": "Synopse mORMot 2 + Free Pascal + Python4Delphi",
    "license": "Modified LGPL v2.1 with Static Linking Exception",
    "version": "1.0.0",
    "created_at": "2026-10-25T01:00:00.000Z"
  },
  "cells": [
    ...
  ]
}
```

---

## 🧱 Cell Schema

Each element in the `cells` array conforms to the following schema:

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `string` | Unique identifier (e.g., `"cell_9a8f2c"`). |
| `type` | `string` | `"code"` or `"markdown"`. |
| `source` | `string` | Code or Markdown text. Line breaks are encoded as `\n`. |
| `execution_count`| `integer` | Sequence order index (`In [ 1 ]:`). `0` indicates not yet executed. |
| `status` | `string` | `"idle"`, `"running"`, `"success"`, `"error"`, `"aborted"`. |
| `execution_time_ms`| `integer` | Wall-clock execution duration in milliseconds. |
| `outputs` | `array` | Array of output objects produced during execution (code cells only). |

---

## 📤 Output Schemas

Outputs in `cell.outputs` are polymorphic and identified by the `type` property:

### 1. Standard Output (`stdout`)
Captures console text printed via `Writeln` or Python `print()`:
```json
{
  "type": "stdout",
  "text": "Vector generated: N=100 observations | Mean=48.72\n"
}
```

### 2. Standard Error & Diagnostics (`stderr`)
Captures Free Pascal compilation errors or runtime exception backtraces:
```json
{
  "type": "stderr",
  "text": "Error: Identifier not found \"MyVariable\"\nFatal: Compilation aborted\n"
}
```

### 3. Tabular Data (`table`)
Encapsulates structured 2D matrices, NumPy tables, or Pandas DataFrames:
```json
{
  "type": "table",
  "title": "Descriptive Statistics Summary",
  "columns": ["Metric", "Value", "Confidence Interval"],
  "rows": [
    ["Mean", "48.720", "[47.89, 49.54]"],
    ["StdDev", "4.192", "[3.65, 4.88]"],
    ["R²", "0.962", "[0.94, 0.98]"]
  ]
}
```

### 4. Interactive Chart.js Plot (`chart`)
Encapsulates hardware-accelerated charting configurations rendered by `<bv-chart>`:
```json
{
  "type": "chart",
  "title": "Model Accuracy vs Epoch",
  "chartType": "line",
  "data": {
    "labels": ["Epoch 1", "Epoch 2", "Epoch 3", "Epoch 4"],
    "datasets": [
      {
        "label": "Training Accuracy",
        "data": [0.65, 0.78, 0.89, 0.96],
        "borderColor": "#10b981",
        "backgroundColor": "rgba(16, 185, 129, 0.1)",
        "tension": 0.3,
        "fill": true
      }
    ]
  },
  "options": {
    "responsive": true,
    "maintainAspectRatio": false
  }
}
```
