# 🌱 Track 1: Absolute Beginner — Welcome to BlaiseNotebook & Pascal

> **Welcome to Track 1!** In this track, you will take your very first steps in **BlaiseNotebook**. By the end of this track, you will comfortably write Pascal statements, execute code blocks, and control the notebook interface with keyboard shortcuts.
>
> ⏱️ **Estimated time:** 15 minutes  
> 🎯 **Level:** Absolute Beginner (No prior coding experience required!)

---

## 📖 Lesson 1.1: What is a Cell and How to Run It?

A notebook is composed of vertical blocks called **Cells**. There are two types of cells:

1. **Code Cells**: Contain Object Pascal code that your computer runs.
2. **Markdown Cells**: Contain formatted notes, explanations, checklists, and images.

```text
┌────────────────────────────────────────────────────────┐
│ [Code Cell]                                            │
│   Writeln('Hello, World!');                            │
└────────────────────────────────────────────────────────┘
                           ▼ Press Shift + Enter
┌────────────────────────────────────────────────────────┐
│ [Output Area]                                          │
│   Hello, World!                                        │
└────────────────────────────────────────────────────────┘
```

### Try Your First Code Cell!

1. Click inside any code cell on your screen.
2. Type the following line:

```pascal
Writeln('Hello, World! Welcome to BlaiseNotebook 🚀');
```

3. Now, press **`Shift + Enter`** on your keyboard (or click the green **▶ Run** button on the cell toolbar).

### What just happened?
- The notebook sent your Pascal code to the background compiler.
- It ran in a split second.
- The output printed right under the cell:
  ```text
  Hello, World! Welcome to BlaiseNotebook 🚀
  ```
- Notice the badge on the left side of the cell: `[ 1 ]` with a green checkmark `✓` and an execution time (e.g. `12ms`). That tells you it was the 1st executed cell in your session!

---

## 📖 Lesson 1.2: Variables and Basic Math

Think of a **variable** like a labeled storage box where you can put numbers or text.

In Pascal, we declare variables inside a `var` block before using them:

```pascal
var
  ProductName: string;
  Price, Discount, FinalPrice: Double;
  Quantity: Integer;
begin
  ProductName := 'Wireless Mechanical Keyboard';
  Price := 89.90;
  Quantity := 2;
  Discount := 0.15; // 15% discount

  FinalPrice := (Price * Quantity) * (1.0 - Discount);

  Writeln('Order Summary:');
  Writeln('Item:     ', ProductName);
  Writeln('Quantity: ', Quantity);
  Writeln('Total:    $', FormatFloat('0.00', FinalPrice));
end;
```

### 💡 Golden Rules of Pascal Variables:
- **`:=`** is used for assigning a value (e.g., `Price := 89.90;`).
- **`;` (semicolon)** must end every statement in Pascal.
- Common Types:
  - **`Integer`**: Whole numbers like `1`, `42`, `-7`.
  - **`Double`**: Decimal numbers like `3.14`, `99.95`.
  - **`string`**: Text surrounded by single quotes: `'Hello'`.
  - **`Boolean`**: Either `True` or `False`.

---

## 📖 Lesson 1.3: Making Decisions and Repeating Actions

### 1. If / Then / Else (Making Decisions)

Want your notebook to react differently based on a condition? Use `if`:

```pascal
var
  StudentScore: Double;
begin
  StudentScore := 84.5;

  if StudentScore >= 90.0 then
    Writeln('Grade: A - Outstanding achievement! 🌟')
  else if StudentScore >= 80.0 then
    Writeln('Grade: B - Great job! 👍')
  else if StudentScore >= 70.0 then
    Writeln('Grade: C - Satisfactory. Keep practicing!')
  else
    Writeln('Grade: F - Needs review.');
end;
```

> [!TIP]
> Notice there is **no semicolon before `else`** in Pascal: `Writeln(...) else`.

---

### 2. For Loops (Repeating an Action)

Want to calculate something for each month or day? Use a `for` loop:

```pascal
var
  Month: Integer;
  MonthlyRevenue: Double;
begin
  Writeln('Month-by-Month Projected Revenue:');
  Writeln('----------------------------------');

  for Month := 1 to 6 do
  begin
    MonthlyRevenue := Month * 1250.00;
    Writeln(Format('Month %d: $%s', [Month, FormatFloat('#,##0.00', MonthlyRevenue)]));
  end;
end;
```

When you run this cell, Pascal will loop from `1` to `6` and print the calculated revenue for each month!

---

## 📖 Lesson 1.4: Mastering the Notebook Interface

Here is a quick visual guide to the controls around every cell:

```text
┌─────────────────────────────────────────────────────────────┐
│ Code ▾  [Cell 1]    [ ▶ Run ]  [ ▲ ] [ ▼ ]  [ + Code ] [ + Md ]  [ 🗑️ ] │
├─────────────────────────────────────────────────────────────┤
│  Writeln('Explore Pascal!');                                │
└─────────────────────────────────────────────────────────────┘
```

- **Type Selector (`Code ▾` / `Markdown ▾`)**: Switch between executable code and formatted text notes.
- **`[ + Code ]` & `[ + Md ]`**: Click these buttons right next to the trash icon to insert a brand new cell **immediately below** the current one.
- **`[ ▲ ]` and `[ ▼ ]`**: Move the cell up or down in your notebook.
- **`[ 🗑️ ]` (Trash Can)**: Deletes the current cell.
- **Top Toolbar Buttons**:
  - **`▶ Run All`**: Runs every cell in your notebook from top to bottom.
  - **`⏹ Stop`**: Interrupts long-running calculations.
  - **`🌓 Theme`**: Toggles between Flatly (bright light theme) and Darkly (sleek dark mode).
  - **`📁 Project`**: Save your notebook as a `.bynb` file or load existing project files.

---

## 🏆 Practice Challenge 1: The Smart Currency Converter

Let's test what you learned! Create a new code cell and write a small currency converter that:
1. Takes an amount in USD (e.g. `$250.00`).
2. Converts it to EUR (rate `0.92`), GBP (rate `0.78`), and BRL (rate `5.70`).
3. Prints a clean, formatted receipt.

### Solution:

```pascal
var
  AmountUSD: Double;
  EUR, GBP, BRL: Double;
const
  USD_TO_EUR = 0.92;
  USD_TO_GBP = 0.78;
  USD_TO_BRL = 5.70;
begin
  AmountUSD := 250.00;

  EUR := AmountUSD * USD_TO_EUR;
  GBP := AmountUSD * USD_TO_GBP;
  BRL := AmountUSD * USD_TO_BRL;

  Writeln('====================================');
  Writeln('       GLOBAL CURRENCY CONVERTER    ');
  Writeln('====================================');
  Writeln(Format('Initial USD:   $%.2f', [AmountUSD]));
  Writeln(Format('Equivalent EUR: €%.2f', [EUR]));
  Writeln(Format('Equivalent GBP: £%.2f', [GBP]));
  Writeln(Format('Equivalent BRL: R$%.2f', [BRL]));
  Writeln('====================================');
end;
```

---

### 🎉 Milestone Complete!
You have successfully mastered the fundamentals of Object Pascal notebooks!

Next up: Learn how to draw hardware-accelerated graphs and format mathematical formulas!  
👉 **[Proceed to Track 2: Intermediate — Visualizations & Math](02_track_intermediate.md)**
