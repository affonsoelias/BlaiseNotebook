# 📐 BlaiseNotebook

**BlaiseNotebook** é uma plataforma pioneira no ecossistema Object Pascal para Ciência de Dados, Inteligência Artificial e Computação Científica Interativa — combinando a produtividade de notebooks interativos (como Jupyter / Colab) com a extrema performance compilada do **Free Pascal**, a reatividade do **BlaiseVue**, o poder dos servidores assíncronos **Synopse mORMot 2** e o ecossistema científico do **Python** via **Python4Delphi / Python4Lazarus**.

---

## 📜 Licença

O projeto segue rigorosamente o modelo de licenciamento oficial do **Lazarus IDE**, **Free Pascal** e **BlaiseVue**:

- **Core Framework, Componentes e Runtime Científico**:
  Licenciado sob a **Modified GNU LGPL v2.1 com Static Linking Exception**.
  Permite o desenvolvimento de aplicações, bibliotecas e rotinas proprietárias ou de código aberto sem impor a abertura do código-fonte do utilizador final.
- **Kernel / Binários e Ferramentas CLI**:
  Licenciados sob a **GNU General Public License v2 (GPL v2)**.

Consulte o arquivo [LICENSE](LICENSE) para detalhes legais completos.

---

## 🌟 Funcionalidades da Etapa 1 (Frontend BlaiseVue & Visualização)

1. **Workspace Interativo `<bv-notebook>`**:
   - Barra de ferramentas global: Executar Todas (`▶▶ Run All`), Adicionar Célula de Código Pascal (`+ Code`), Adicionar Markdown (`+ Markdown`), Limpar Saídas, Salvar/Exportar (`.bynb`) e Abrir.
   - Status reativo do Kernel WebSocket (`🟢 Conectado`, `🟡 Executando`, `⚪ Standalone`).
   - Divisores interativos entre células para inserção ágil.

2. **Célula Polimórfica `<bv-cell>`**:
   - Alternância em tempo real entre **Código Pascal** e **Documentação Markdown**.
   - Indicador de execução clássico (`In [ 1 ]:`, `In [ * ]:` com animação de execução, `In [ ]:`).
   - Ações por célula: Executar (`Shift + Enter`), mover para cima/baixo, duplicar, excluir.

3. **Editor de Código Pascal `<bv-code-editor>`**:
   - Gutter com numeração de linhas sincronizada.
   - Realce visual e indentação inteligente (`Tab` = 2 espaços).
   - Atalhos: `Shift + Enter` para executar, `Ctrl + Enter` para executar sem avançar.

4. **Documentação Markdown `<bv-markdown>`**:
   - Renderização rica de cabeçalhos (`#`, `##`), listas, negrito, itálico, citações, blocos de código e fórmulas matemáticas (`$ ... $`, `$$ ... $$`).
   - Modo de edição ao dar duplo clique, com retorno rápido via `Ctrl + Enter`.

5. **Área de Saída Multiformato `<bv-output>`**:
   - **Terminal Console (`stdout`/`stderr`)**: Logs de execução e depuração.
   - **Tabelas de Dados**: Visualizador responsivo para DataFrames e datasets.
   - **Gráficos Reativos com Chart.js (`<bv-chart>`)**: Suporte nativo a gráficos de Linhas, Barras, Pizza e Dispersão alimentados diretamente pelo Pascal/Python.
   - **Figuras Python**: Visualização de plots Base64 do Matplotlib/Seaborn.

---

## 🚀 Como Executar o Frontend

```bash
cd frontend
bv run dev
# ou para servidor de desenvolvimento com HMR:
bv dev
```
