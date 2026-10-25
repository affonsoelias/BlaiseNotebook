# 📦 BlaiseNotebook Package Template

This template shows how easy it is to create, distribute, and consume modular libraries in **BlaiseNotebook**.

---

## 🚀 How to Create Your Own Library

1. **Duplicate this directory**:
   Copy the `_template/` folder and give it your library name (e.g., `packages/external/finance/`).
2. **Rename the `.pas` file**:
   Rename `MyLibrary.pas` to your unit name (e.g., `BlaiseFinance.pas`) and update the `unit` statement at the top.
3. **Configure `package.json`**:
   Update `name`, `version`, `description`, and `main` filename.
4. **(Optional) Add Python Dependencies in `requirements.txt`**:
   If your library wraps Python modules, list them here.
5. **Use it immediately in any notebook cell**:
   ```pascal
   uses BlaiseFinance;

   begin
     ShowText(TMyCustomService.Greet('Finance'));
   end;
   ```

No server restart or recompilation is required! The dynamic runner automatically discovers your library folder and registers it with the Free Pascal Compiler (`-Fu`).
