# 🛠️ Official Tool Template

Standard scaffold for creating official auxiliary tools for BlaiseNotebook in `frontend/server/packages/tools/`.

## Usage in Notebook

```pascal
uses
  BlaiseOutput,
  uToolTemplate;

begin
  Writeln('Tool: ', GetToolName(), ' (v', GetToolVersion(), ')');
end;
```
