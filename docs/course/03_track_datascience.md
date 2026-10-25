# 📊 Track 3: Data Science Master — Fluent Pandas in Pure Pascal

> **Welcome to Track 3!** This is where BlaiseNotebook truly shines. You will manipulate tabular data, analyze complex series, filter rows using natural queries, and plot statistical distributions — all with **100% strongly-typed Object Pascal classes** powered under the hood by **Pandas** and **NumPy**!
>
> ⏱️ **Estimated time:** 25 minutes  
> 🎯 **Level:** Advanced Data Science (Built on Tracks 1 & 2)

---

## 📖 Lesson 3.1: Meet `TPyDataFrame` (Your Digital Spreadsheet)

Think of a **`TPyDataFrame`** like an in-memory Excel spreadsheet or database table:
- It has **columns** with names (e.g. `'Product'`, `'Price'`, `'Quantity'`).
- It has **rows** containing your observations.

### 1. Creating a DataFrame from Scratch in Pascal

```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  
  // Add columns fluently:
  DF.AddColumn('Month',       ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']);
  DF.AddColumn('Visitors',    [1250, 1420, 1890, 2100, 2650, 3100]);
  DF.AddColumn('Conversions', [65, 78, 112, 145, 198, 240]);
  DF.AddColumn('RevenueK',    [12.4, 15.8, 22.1, 28.5, 39.2, 48.0]);

  Writeln(Format('Loaded DataFrame: %d rows by %d columns', [DF.RowCount, DF.ColumnCount]));

  // Display the dataset as a sleek interactive table:
  DF.ShowTable('H1 E-Commerce Growth Data', 10);
end;
```

---

### 2. Loading and Saving CSV Files

Working with real-world files on your disk takes just a single method call:

```pascal
var
  DF: TPyDataFrame;
begin
  // 1. Load any CSV file:
  // DF := TPyDataFrame.FromCSV('sales_data.csv');

  // 2. Export your DataFrame to a new CSV file:
  DF := TPyDataFrame.Create;
  DF.AddColumn('City', ['New York', 'London', 'Tokyo']);
  DF.AddColumn('OfficeRevenueM', [45.2, 38.6, 52.1]);
  
  DF.ToCSV('global_offices.csv');
  Writeln('Dataset saved successfully to global_offices.csv! 📁');
end;
```

---

## 📖 Lesson 3.2: Column Analytics with `TPySeries`

Every column in your DataFrame is a **`TPySeries`**. You can inspect its statistics directly without writing formulas:

```pascal
var
  DF: TPyDataFrame;
  Rev: TPySeries;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Customer', ['Acme', 'Stark', 'Wayne', 'Cyberdyne', 'Umbrella']);
  DF.AddColumn('DealSizeK', [120.0, 450.0, 310.0, 85.0, 215.0]);

  // Extract the 'DealSizeK' column:
  Rev := DF.Column('DealSizeK');

  Writeln('=== DEALS STATISTICAL PROFILE ===');
  Writeln('Number of Deals: ', Rev.Count);
  Writeln('Average Deal:    $', FormatFloat('0.00', Rev.Mean), 'k');
  Writeln('Median Deal:     $', FormatFloat('0.00', Rev.Median), 'k');
  Writeln('Std Deviation:   $', FormatFloat('0.00', Rev.StdDev), 'k');
  Writeln('Smallest Deal:   $', FormatFloat('0.00', Rev.Min), 'k');
  Writeln('Largest Deal:    $', FormatFloat('0.00', Rev.Max), 'k');
  Writeln('Total Pipeline:  $', FormatFloat('0.00', Rev.Sum), 'k');
end;
```

---

## 📖 Lesson 3.3: Modern Statistical Visualizations

You no longer have to manually construct JSON for charts! `TPyDataFrame` includes native one-liner charting methods:

### 1. Pie & Doughnut Charts (Market Share & Distribution)
```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Category',    ['Laptops', 'Smartphones', 'Audio', 'Accessories']);
  DF.AddColumn('QuarterSales', [420.0, 680.0, 190.0, 110.0]);

  // Pie chart with automatic palettes and hover offsets:
  DF.PlotPie('Product Revenue Share', 'Category', 'QuarterSales');

  // Doughnut chart view:
  DF.PlotDoughnut('Product Revenue Breakdown (Donut)', 'Category', 'QuarterSales');
end;
```

---

### 2. Frequency Histograms (Binning Distributions)
```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Age', [19.0, 22.0, 25.0, 28.0, 31.0, 34.0, 35.0, 42.0, 45.0, 50.0, 58.0, 65.0]);

  // Automatically partitions continuous data into 4 frequency bins:
  DF.PlotHistogram('Customer Age Distribution', 'Age', 4);
end;
```

---

### 3. BoxPlots (Outliers & 5-Number Summaries)
```pascal
var
  DF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Department', ['Sales', 'Sales', 'Sales', 'Dev', 'Dev', 'Dev']);
  DF.AddColumn('HoursWorked', [40.0, 48.0, 55.0, 38.0, 42.0, 44.0]);

  // Computes Min, Q1, Median, Q3, and Max per department:
  DF.PlotBoxPlot('Workload Dispersion by Department', 'Department', 'HoursWorked');
end;
```

---

## 📖 Lesson 3.4: Fluent Data Manipulation (Filter, Sort, Drop)

Want to clean and query your data using natural expressions? Use fluent methods:

```pascal
var
  DF, FilteredDF, SortedDF, CleanDF: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('City',     ['New York', 'Boston', 'Chicago', 'Miami', 'Seattle']);
  DF.AddColumn('SalesK',   [180.0, 65.0, 140.0, 95.0, 210.0]);
  DF.AddColumn('GrowthPct', [18.5, 4.2, 12.0, 8.4, 25.0]);

  // 1. Fluent Filter (Query string):
  FilteredDF := DF.Filter('SalesK >= 100.0 and GrowthPct > 10.0');
  FilteredDF.ShowTable('High-Growth Flagship Cities', 10);

  // 2. Fluent Sorting (Descending):
  SortedDF := DF.SortBy('SalesK', False); // False = Descending
  SortedDF.ShowTable('Ranked by Sales (Top Cities First)', 10);

  // 3. Drop unwanted columns:
  CleanDF := DF.DropColumns(['GrowthPct']);
end;
```

---

## 📖 Lesson 3.5: Analytical Grouping (`.GroupBy`)

Grouping rows by category and calculating aggregations (averages, totals, counts) is the heart of business intelligence:

```pascal
var
  DF, CategoryAverages, CategoryTotals: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Region',   ['North', 'North', 'South', 'South', 'East', 'East']);
  DF.AddColumn('RevenueK', [50.0, 65.0, 40.0, 45.0, 80.0, 95.0]);
  DF.AddColumn('ExpensesK', [30.0, 38.0, 22.0, 25.0, 45.0, 52.0]);

  // Calculate average Revenue and Expenses for each Region:
  CategoryAverages := DF.GroupBy('Region').Mean;
  CategoryAverages.ShowTable('Average Performance per Region', 10);

  // Calculate total Revenue and Expenses per Region:
  CategoryTotals := DF.GroupBy('Region').Sum;
  CategoryTotals.ShowTable('Total Revenue & Expenses per Region', 10);
end;
```

---

## 🏆 Practice Challenge 3: Sales Executive Dashboard

Create a notebook cell that:
1. Builds a DataFrame of 6 quarterly product lines (`'Sector'`, `'Quarter'`, `'RevenueM'`).
2. Filters out any lines with revenue under `$15.0M`.
3. Renders a Pie Chart showing the revenue share of the qualifying products.
4. Groups by `'Sector'` to display the average revenue table.

### Solution:

```pascal
var
  DF, QualifiedDF, SectorSummary: TPyDataFrame;
begin
  DF := TPyDataFrame.Create;
  DF.AddColumn('Sector',   ['Cloud', 'Hardware', 'Cloud', 'Hardware', 'AI Services', 'AI Services']);
  DF.AddColumn('Quarter',  ['Q1', 'Q1', 'Q2', 'Q2', 'Q1', 'Q2']);
  DF.AddColumn('RevenueM', [28.5, 12.0, 34.2, 14.5, 45.0, 58.2]);

  // 1. Filter:
  QualifiedDF := DF.Filter('RevenueM >= 15.0');
  QualifiedDF.ShowTable('Qualified Strategic Products (>= $15M)', 10);

  // 2. Pie Chart:
  QualifiedDF.PlotPie('Revenue Share of Strategic Products', 'Sector', 'RevenueM');

  // 3. Sector GroupBy:
  SectorSummary := QualifiedDF.GroupBy('Sector').Mean;
  SectorSummary.ShowTable('Mean Revenue by Sector', 10);
end;
```

---

### 🎉 Milestone Complete!
You have mastered modern data science and tabular analytics in Object Pascal!

Next: Train predictive Artificial Intelligence and Machine Learning models!  
👉 **[Proceed to Track 4: AI & Machine Learning Expert](04_track_machine_learning.md)**
