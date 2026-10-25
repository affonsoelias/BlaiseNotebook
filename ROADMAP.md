# 🗺️ BlaiseNotebook - Product Roadmap & Implementation Plan

> **Strategic Evolutionary Roadmap for BlaiseNotebook**  
> *Compiled Object Pascal (Free Pascal + Synopse mORMot 2) + Python Data Science Ecosystem (Python4Delphi) + Reactive Modern Frontend (BlaiseVue 4.0)*

---

## 🎯 Vision & Objectives

Transform **BlaiseNotebook** into a premier scientific computing and interactive notebook environment for Object Pascal developers, data scientists, and engineers. The plan is organized into progressive development milestones.

```mermaid
flowchart LR
    M1["Milestone 1<br/><b>Data Science API</b><br/><i>Concluído</i>"] --> M2["Milestone 2<br/><b>Modular Packages</b><br/><i>Concluído</i>"]
    M2 --> M3["Milestone 3<br/><b>Stateful Kernel</b><br/><i>Concluído</i>"]
    M3 --> M4["Milestone 4<br/><b>Frontend UX</b><br/><i>Concluído</i>"]
    M4 --> M5["Milestone 5<br/><b>Dashboard View</b><br/><i>Concluído</i>"]
    M5 --> M6["Milestone 6<br/><b>Editor DX & TOC</b><br/><i>Planejado</i>"]
    M6 --> M7["Milestone 7<br/><b>Widgets & 3D</b><br/><i>Planejado</i>"]
    M7 --> M8["Milestone 8<br/><b>Robustness & Export</b><br/><i>Planejado</i>"]
```

---

## 📅 Milestones & Feature Breakdown

### Milestone 1: Expansão da API Pascal para Data Science (`BlaiseDataScience.pas`) ✅ CONCLUÍDO
> **Goal:** Empower Pascal programmers with complete tabular analytics, statistical visualizations, and machine learning models without writing raw Python scripts.

#### 1.1 Novos Gráficos Científicos Nativos (Chart.js via Pascal)
- [x] **`DF.PlotPie(Title, LabelCol, ValueCol)`**: Gráficos de pizza e rosca com paleta moderna e porcentagens automáticas.
- [x] **`DF.PlotArea(Title, XCol, YCol)`**: Gráfico de área preenchida com transparência e gradientes.
- [x] **`DF.PlotHistogram(Title, Col, Bins)`**: Histograma de distribuição de frequências com cálculo automático de compartimentos (bins).
- [x] **`DF.PlotBoxPlot(Title, CategoryCol, ValueCol)`**: Boxplot para análise de dispersão e detecção de outliers.

#### 1.2 Manipulação Fluente de Dados (Pandas em Pascal)
- [x] **Filtragem de Expressão**: `DF.Filter('RevenueK > 25.0 and Month in ["Jan", "Mar"]')`.
- [x] **Ordenação Flexível**: `DF.SortBy('RevenueK', Ascending: Boolean)`.
- [x] **Eliminação de Colunas / Nulos**: `DF.DropColumns(['ColA', 'ColB'])` e `DF.DropNA`.
- [x] **Agrupamento e Agregação**: `DF.GroupBy('Category').Mean` e `DF.GroupBy('Category').Sum`.

#### 1.3 Novos Modelos de Inteligência Artificial & Métricas
- [x] **`TPyLogisticRegression`**: Classificação binária e multiclasse nativa.
- [x] **`TPyDecisionTreeClassifier`**: Árvores de decisão interpretáveis.
- [x] **Métricas de Avaliação de Modelos**:
  - `PyAccuracyScore(YTrue, YPred: TPySeries): Double`
  - `PyR2Score(YTrue, YPred: TPySeries): Double`
  - `PyConfusionMatrix(YTrue, YPred: TPySeries): TPyDataFrame` (renderizável diretamente como tabela).

---

### Milestone 2: Arquitetura Modular de Bibliotecas Desacopladas (`frontend/server/packages/`) ✅ CONCLUÍDO
> **Goal:** Desacoplar 100% as bibliotecas do servidor nativo (`server.exe`), modularizando cada biblioteca (Pandas, Scikit-Learn, Math, etc.) em sua própria pasta isolada em `packages/external/`, com auto-descoberta dinâmica no Free Pascal, suporte nativo a `uses` nas células e facilidade de criação/distribuição de novos pacotes.

#### 2.1 Estrutura de Pastas e Separação Modular Granular
- [x] **`packages/core/`**: Núcleo mínimo essencial do notebook (`BlaiseOutput.pas`, metadados de I/O, tabelas e gráficos).
- [x] **`packages/external/python_bridge/`**: Ponte isolada de comunicação com CPython/Python4Delphi (`BlaisePyKernel.pas`).
- [x] **`packages/external/pandas/`**: Wrapper oficial do Pandas (`BlaisePandas.pas`, `requirements.txt`, `package.json`).
- [x] **`packages/external/sklearn/`**: Wrapper oficial do Scikit-Learn (`BlaiseSklearn.pas`, `requirements.txt`, `package.json`).
- [x] **`packages/external/math/`**: Pacote oficial de álgebra e estatística nativa Pascal (`BlaiseMathKernel.pas`, `package.json`).
- [x] **`packages/external/datascience/`**: Unit de compatibilidade retroativa (`BlaiseDataScience.pas` agregando `BlaisePandas` e `BlaiseSklearn`) garantindo que nenhum notebook existente quebre.

#### 2.2 Auto-Descoberta Dinâmica no `uCodeRunner.pas`
- [x] **Descoberta Automática de Subpastas (`DiscoverPackageUnits`)**: Varredura em tempo de execução de todas as subpastas em `packages/core/` e `packages/external/*`, adicionando os caminhos ao `-Fu` do FPC sem necessidade de reiniciar o servidor.
- [x] **Parser Inteligente de `uses` na Célula**: Suporte a declaração explícita de `uses MinhaLib, BlaisePandas;` nas células, preservando os imports do usuário e mesclando com o núcleo mínimo do sistema.
- [x] **Fallback de Compatibilidade para Iniciantes**: Injeção automática das bibliotecas padrão quando a célula não declarar `uses`.

#### 2.3 Suporte ao Comando Mágico `%pip install` Direto na Célula
- [x] **Execução e Stream em Tempo Real**: Interceptar `%pip install <pacote>` no `uCodeRunner` e despachar para o `pip` do Python configurado, transmitindo a saída em tempo real no console da célula.

#### 2.4 Documentação e Template de Criação de Bibliotecas
- [x] Guia na documentação explicando o fluxo para criar, empacotar e distribuir novas bibliotecas em `packages/external/`.
- [x] Template inicial pronto em `packages/external/_template/` com Unit Pascal, `package.json`, `requirements.txt` e README.

---

### Milestone 3: Arquitetura do Kernel e Desempenho (Backend Pascal) ✅ CONCLUÍDO
> **Goal:** Deliver instant compilation, variable continuity across cells, and support for multi-output cells.

#### 3.1 Sessão Persistente entre Células (Stateful Kernel)
- [x] **Shared Session Daemon**: Manter o interpretador Python (`CPython 3.13`) e variáveis Pascal/Python em execução contínua no processo do servidor (`kernel/blaise_kernel_daemon.py`).
- [x] **Preservação de Contexto**: Variáveis e DataFrames gerados na Célula 1 (ex: `DF.SaveAs('dados_vendas')`) ficam imediatamente disponíveis na Célula 2 via `DF.Attach('dados_vendas')` sem necessidade de recarregamento.
- [x] **Reset de Sessão**: Comando `Restart Kernel` (via botão na toolbar e WebSocket action `restart_kernel`) limpa completamente a memória do workspace e reinicia o estado do daemon.

#### 3.2 Cache Inteligente de Compilação (Zero-Delay Re-run)
- [x] **Hash Criptográfico de Código**: Assinatura rápida e precisa via SHA-1/SHA-256 no `uCodeRunner.pas`.
- [x] **Pular Compilação FPC (0ms Compilation)**: Se o código está inalterado e o executável correspondente existe, despacha a execução imediatamente sem invocar o compilador (latência reduzida de ~400ms para ~30ms).
- [x] **Invalidação Automática de Cache**: Recompilação automática assim que qualquer caractere do código for modificado ou após um "Restart Kernel".

#### 3.3 Múltiplas Saídas em uma Única Célula
- [x] **Multiplexação de Payloads**: Uma única execução emite múltiplos gráficos e tabelas sequenciais (`DF.ShowTable(...)`, `DF.PlotLine(...)`, `DF.PlotBar(...)`) através de delimitadores `@@BLAISE_PAYLOAD@@:` sem sobreposição.
- [x] **Stacking Ordenado**: As saídas são organizadas e empilhadas de forma fluida no componente `BvOutput.bv`, com espaçamento uniforme e isolamento visual de cada card.

---

### Milestone 4: Experiência de Uso e Produtividade (Frontend & UX) ✅ CONCLUÍDO
> **Goal:** Provide a rich, professional, and accessible notebook editing experience.

#### 4.1 Autocompletion & Destaque de Sintaxe Inteligente
- [x] **Sugestões Contextuais no Editor**:
  - Palavras-chave Object Pascal: `begin`, `end`, `var`, `procedure`, `function`, `Format`, `Writeln`.
  - Métodos fluentes de Data Science: `.AddColumn`, `.Column`, `.ShowTable`, `.PlotLine`, `.PlotBar`, `.ToCSV`, `.FromCSV`.
  - Atalho de gatilho `Ctrl + Space` ou digitação do caractere ponto (`.`).
- [x] **Colorização Aprimorada**: Destacar strings, comentários, palavras-chave e tipos científicos (`TPyDataFrame`, `TPySeries`, `TVector`).

#### 4.2 Tabelas de Dados Interativas (DataGrid Pro)
- [x] **Ordenação de Colunas**: Clique no cabeçalho da coluna para ordenar ascendente/descendente no frontend.
- [x] **Filtro / Busca Rápida**: Barra de pesquisa para filtrar linhas instantaneamente em memória.
- [x] **Paginação Inteligente**: Paginação de 10, 25, 50 ou 100 linhas por página com navegação fluida.
- [x] **Exportação Rápida**: Botão "Copiar CSV" ou "Download CSV" direto no cabeçalho da tabela gerada.

---

### Milestone 5: Modo Dashboard / Apresentação (Estilo Streamlit / Voila) ✅ CONCLUÍDO
> **Goal:** Transform analytical notebooks into executive presentations and interactive dashboards with a single click.

#### 5.1 Modo "Apenas Saídas" (Dashboard View)
- [x] **Toggle Button na Toolbar**: Botão `📊 Dashboard View` no topo da tela e atalho `Ctrl + Shift + D`.
- [x] **Ocultação de Código**: Esconder editores de código, gutters de linha e indicadores técnicos de compilação.
- [x] **Layout de Apresentação**:
  - Textos em Markdown/LaTeX renderizados como seções executivas.
  - Tabelas e gráficos em largura total ou cards responsivos lado a lado.
- [x] **Modo Leitura / Apresentação**: Ideal para compartilhamento em telas de reunião, apresentações executivas e impressão/PDF (`window.print()`).

---

### Milestone 6: Produtividade Avançada & Navegação no Editor (Frontend DX) 📋 PLANEJADO
> **Goal:** Expand user productivity with intuitive notebook navigation, command history, and reusable snippet templates.

#### 6.1 Histórico de Ações e Undo/Redo no Nível do Notebook
- [ ] **Desfazer/Refazer Global (`Ctrl+Z` / `Ctrl+Y`)**: Manter histórico de ações estruturais no notebook (adição, deleção e reordenação de células).
- [ ] **Lixeira de Células (Recuperação Rápida)**: Capacidade de restaurar células deletadas acidentalmente via atalho `Z` no modo de comando ou banner de restauração rápida.

#### 6.2 Reordenação de Células via Drag & Drop
- [ ] **Alça Visual de Arrasto (`⠿`)**: Handle visual na lateral esquerda de cada célula permitindo arrastar e soltar para reposicionar células na ordem desejada.
- [ ] **Feedback Visual de Posicionamento**: Linha indicadora animada mostrando exatamente onde a célula será solta.

#### 6.3 Tabela de Conteúdos Automática (Outline / TOC)
- [ ] **Painel Lateral Recolhível**: Drawer lateral que extrai automaticamente títulos Markdown (`#`, `##`, `###`) do notebook.
- [ ] **Navegação com Rolagem Suave**: Clicar em um item do outline rola a página suavemente até a célula correspondente.

#### 6.4 Snippets & Catálogo de Receitas de Código
- [ ] **Menu de Inserção Rápida de Templates**: Modal ou submenu na toolbar para inserir receitas prontas (ex: *Carregar CSV & Resumo*, *Split Treino/Teste com Random Forest*, *Histograma + BoxPlot*).

---

### Milestone 7: Visualizações Avançadas & Widgets Interativos (Data Science Pro) 📋 PLANEJADO
> **Goal:** Enhance data exploration with interactive visual controls, 3D representations, and automated data profiling.

#### 7.1 Widgets e Filtros Interativos Inline
- [ ] **Controles Visuais Reativos**: Sliders numéricos, caixas de seleção e dropdowns inseríveis nas células que atualizam parâmetros de execução dinamicamente.
- [ ] **Auto-Reexecução Vinculada**: Ao mover um slider, a célula vinculada recalcula automaticamente o gráfico ou tabela.

#### 7.2 Gráficos 3D e Mapas Geoespaciais
- [ ] **Superfícies e Dispersão 3D**: Renderização tridimensional interativa via WebGL (Plotly / Three.js) para dados multivariados.
- [ ] **Mapas Geoespaciais Interativos**: Visualização de pontos geográficos (latitude/longitude), mapas de calor (heatmaps) e clusters geográficos.

#### 7.3 Data Profiler Automático para DataFrames
- [ ] **Resumo Exploratório com 1 Clique**: Botão no cabeçalho do DataGrid Pro para exibir visão geral de qualidade dos dados: contagem de nulos, tipos inferidos, estatísticas sumárias e mini-gráficos de distribuição (sparklines).

---

### Milestone 8: Robustez do Kernel, Monitoramento & Exportação para Produção 📋 PLANEJADO
> **Goal:** Deliver bulletproof execution control, real-time resource telemetry, and production-ready export targets.

#### 8.1 Interrupção Segura de Execução (Interrupt Kernel)
- [ ] **Botão "Parar Execução" (Interrupt)**: Capacidade de abortar uma execução em andamento (loops infinitos, modelos demorados) sem matar o processo do daemon nem perder variáveis da memória.

#### 8.2 Monitor de Recursos em Tempo Real (Telemetry)
- [ ] **Indicador de Consumo no Header**: Widget discreto na barra superior mostrando consumo de RAM e CPU do daemon Python e latência de compilação FPC.

#### 8.3 Exportação Autossuficiente para Produção
- [ ] **Exportação para HTML Standalone**: Gerar um único arquivo `.html` autossuficiente com gráficos Chart.js e tabelas embutidas (sem dependência do servidor para visualização).
- [ ] **Exportação para Script Executável (`.pas` / `.py`)**: Concatenação limpa de todas as células de código em um script executável para automações batch em linha de comando.

#### 8.4 Múltiplos Kernels / Isolamento por Workspace
- [ ] **Sessões Isoladas por Aba/Workspace**: Permitir que diferentes abas do navegador ou diferentes notebooks rodem com instâncias de daemon e portas dedicadas para evitar colisão de variáveis.

---

## 🛠️ Arquitetura Técnica & Tecnologias Envolvidas

| Componente | Tecnologia | Papel |
|---|---|---|
| **Servidor / Kernel** | Free Pascal Compiler (FPC 3.2.2) + Synopse mORMot 2 | Compilação AOT, servidor WebSocket assíncrono e gerenciador de processos |
| **Gerenciador de Pacotes** | Sistema de pacotes modulares (`packages/core/` e `packages/external/`) | Desacoplamento de bibliotecas, auto-descoberta dinâmica de units e wrappers |
| **Ponte de Dados & AI** | Python4Delphi / CPython 3.13 + Pandas + Scikit-Learn | Execução otimizada de Data Science e Machine Learning |
| **Frontend Reativo** | BlaiseVue 4.0 SPA (Transpilador Pascal-to-JS) | Virtual DOM, reatividade por proxy, componentes Single-File (`.bv`) |
| **Visualização** | Chart.js 4.x + Canvas 2D / WebGL | Gráficos científicos responsivos acelerados por hardware |
| **Formato de Arquivo** | `.bynb` (JSON Schema) | Compatibilidade e persistência completa de metadados, código e saídas |

---

## 📌 Ordem de Execução Atualizada

1. **Fase 1 (Base Científica - CONCLUÍDO)**: Milestone 1 (Novos gráficos, métodos fluentes e modelos no `BlaiseDataScience.pas`).
2. **Fase 2 (Arquitetura Modular - CONCLUÍDO)**: Milestone 2 (Desacoplamento em `packages/core/` e `packages/external/`, modularização de Pandas, Sklearn, Math, suporte a `uses` dinâmico e `%pip`).
3. **Fase 3 (Velocidade e Continuidade - CONCLUÍDO)**: Milestone 3 (Cache de compilação, múltiplas saídas e sessão persistente).
4. **Fase 4 (Interface Avançada - CONCLUÍDO)**: Milestone 4 (Autocompletion de Pascal e DataGrid Pro com paginação/ordenação).
5. **Fase 5 (Apresentação Final - CONCLUÍDO)**: Milestone 5 (Dashboard View executivo).
6. **Fase 6 (Produtividade e Navegação - PRÓXIMO)**: Milestone 6 (Undo/Redo global, Drag & Drop de células, Outline/TOC e catálogo de snippets).
7. **Fase 7 (Widgets e 3D - PLANEJADO)**: Milestone 7 (Widgets interativos inline, gráficos 3D/mapas e Data Profiler).
8. **Fase 8 (Robustez e Produção - PLANEJADO)**: Milestone 8 (Interrupt de execução, telemetria de recursos e exportação HTML/script standalone).

---

*Documento gerado e mantido pela equipe de engenharia do BlaiseNotebook.*
