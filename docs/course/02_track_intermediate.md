# 📈 Track 2: Intermediate — Visualizations & Native Computing

> **Welcome to Track 2!** Here, you will learn how to turn plain text into rich scientific documentation with mathematical formulas, crunch numbers with high-performance native vectors, and render interactive **Chart.js** graphics directly under your code!
>
> ⏱️ **Estimated time:** 20 minutes  
> 🎯 **Level:** Intermediate (Built on Track 1)

---

## 📖 Lesson 2.1: Rich Notes & Mathematical Equations (KaTeX)

A great scientific notebook doesn't just show code — it tells a story! Switch a cell's type to **Markdown** to write headings, bullet lists, formatting, and mathematical equations.

### 1. Basic Markdown Cheat Sheet:
```markdown
# Big Main Heading (H1)
## Section Heading (H2)
### Small Subsection (H3)

**Bold text** or *italic text*.
- Bullet point 1
- Bullet point 2

> [!NOTE]
> This is a highlighted scientific callout note!
```

### 2. Beautiful LaTeX Math with KaTeX
BlaiseNotebook features native mathematical rendering powered by KaTeX:
- Use single dollar signs **`$...$`** for inline math (e.g. `$E = mc^2$`).
- Use double dollar signs **`$$...$$`** for centered formula blocks:

```markdown
### Standard Deviation Formula
The population standard deviation $\sigma$ is defined as:

$$ \sigma = \sqrt{\frac{1}{N} \sum_{i=1}^{N} (x_i - \mu)^2} $$

Where:
- $\mu$ is the mean of the population
- $N$ is the total number of observations
- $x_i$ represents each individual data point
```

When you click outside the cell or press `Shift + Enter`, the formula renders into book-quality typography instantly!

---

## 📖 Lesson 2.2: High-Speed Native Math with `TVector`

When working with scientific computations, you often need to generate hundreds or thousands of numbers and calculate averages, variances, and bounds.

BlaiseNotebook includes the built-in **`TVector`** class in `BlaiseMathKernel.pas`, compiled directly into native machine code:

```pascal
var
  SensorReadings: TVector;
begin
  // Generate 50 simulated sensor readings between 18.0°C and 32.0°C
  SensorReadings := TVector.CreateRandom(50, 18.0, 32.0);

  Writeln('=== SENSOR TELEMETRY METRICS ===');
  Writeln('Total Readings: ', SensorReadings.Tamanho);
  Writeln('Average Temp:   ', FormatFloat('0.00', SensorReadings.CalculaMedia), ' °C');
  Writeln('Std Deviation:  ', FormatFloat('0.00', SensorReadings.CalculaDesvioPadrao), ' °C');
  Writeln('Median Temp:    ', FormatFloat('0.00', SensorReadings.CalculaMediana), ' °C');
  Writeln('Minimum Temp:   ', FormatFloat('0.00', SensorReadings.Minimo), ' °C');
  Writeln('Maximum Temp:   ', FormatFloat('0.00', SensorReadings.Maximo), ' °C');
end;
```

---

## 📖 Lesson 2.3: Chart.js Visualizations in Pascal

Forget about static, pixelated images! BlaiseNotebook embeds hardware-accelerated **Chart.js** canvases directly in your notebook cells using the `ShowChart` function from `BlaiseOutput.pas`.

### 1. Drawing a Responsive Line Chart

```pascal
var
  ChartJson: string;
begin
  ChartJson := 
    '{' +
    '  "labels": ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],' +
    '  "datasets": [{' +
    '    "label": "Monthly Active Users (k)",' +
    '    "data": [45, 59, 80, 81, 120, 155],' +
    '    "borderColor": "#10b981",' +
    '    "backgroundColor": "rgba(16, 185, 129, 0.2)",' +
    '    "tension": 0.35,' +
    '    "fill": true' +
    '  }]' +
    '}';

  ShowChart('User Growth Curve (2026)', 'line', ChartJson);
end;
```

Hover your mouse over the points in the chart: you get animated tooltips, smooth bezier curves, and responsive resizing automatically!

---

### 2. Multi-Dataset Bar Chart (Comparing Categories)

```pascal
var
  ChartJson: string;
begin
  ChartJson := 
    '{' +
    '  "labels": ["Server A", "Server B", "Server C", "Server D"],' +
    '  "datasets": [' +
    '    {"label": "CPU Usage (%)", "data": [42, 68, 85, 33], "backgroundColor": "#3b82f6"},' +
    '    {"label": "RAM Usage (%)", "data": [55, 74, 91, 48], "backgroundColor": "#f59e0b"}' +
    '  ]' +
    '}';

  ShowChart('Datacenter Load Comparison', 'bar', ChartJson);
end;
```

---

## 📖 Lesson 2.4: Interactive Data Tables (`ShowTable`)

Need to show structured records to your users without overwhelming them with terminal text? Use `ShowTable`:

```pascal
var
  Headers: array of string;
  RecordsJson: string;
begin
  Headers := ['DeviceID', 'Location', 'Battery', 'Status'];
  
  RecordsJson := 
    '[' +
    '  {"DeviceID": "IOT-101", "Location": "Warehouse Alpha", "Battery": "98%", "Status": "Active"},' +
    '  {"DeviceID": "IOT-102", "Location": "Dock Beta",        "Battery": "45%", "Status": "Warning"},' +
    '  {"DeviceID": "IOT-103", "Location": "Cold Storage",     "Battery": "88%", "Status": "Active"}' +
    ']';

  ShowTable('Fleet IoT Devices Status', Headers, RecordsJson);
end;
```

---

## 🏆 Practice Challenge 2: Weather Station Daily Report

Create a notebook cell that:
1. Simulates 7 days of temperature readings (Monday to Sunday).
2. Calculates the weekly average and maximum temperature.
3. Renders a colorful bar chart showing the daily temperatures.

### Solution:

```pascal
var
  Days: array of string;
  Temps: array of Double;
  Total, Avg, MaxTemp: Double;
  i: Integer;
  ChartJson: string;
begin
  Days := ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  Temps := [22.4, 24.1, 28.5, 31.0, 29.2, 26.8, 23.5];

  Total := 0;
  MaxTemp := Temps[0];
  for i := 0 to High(Temps) do
  begin
    Total := Total + Temps[i];
    if Temps[i] > MaxTemp then MaxTemp := Temps[i];
  end;
  Avg := Total / Length(Temps);

  Writeln('=== WEATHER STATION REPORT ===');
  Writeln(Format('Weekly Average: %.2f °C', [Avg]));
  Writeln(Format('Peak High:      %.2f °C', [MaxTemp]));

  ChartJson := 
    '{' +
    '  "labels": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],' +
    '  "datasets": [{' +
    '    "label": "Daily Temperature (°C)",' +
    '    "data": [22.4, 24.1, 28.5, 31.0, 29.2, 26.8, 23.5],' +
    '    "backgroundColor": ["#3b82f6", "#3b82f6", "#f59e0b", "#ef4444", "#f59e0b", "#3b82f6", "#3b82f6"],' +
    '    "borderRadius": 5' +
    '  }]' +
    '}';

  ShowChart('7-Day Forecast & Historical Temperatures', 'bar', ChartJson);
end;
```

---

### 🎉 Milestone Complete!
You now know how to combine markdown formulas, native math routines, and responsive charts.

Next: Step into modern tabular data science with **Pandas in Pure Pascal**!  
👉 **[Proceed to Track 3: Data Science Master](03_track_datascience.md)**
