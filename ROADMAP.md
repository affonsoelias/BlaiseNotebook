# 🗺️ BlaiseNotebook - Product Roadmap & Implementation Plan

> **Strategic Evolutionary Roadmap for BlaiseNotebook**  
> *Compiled Object Pascal (Free Pascal + Synopse mORMot 2) + Python Data Science Ecosystem (Python4Delphi) + Reactive Modern Frontend (BlaiseVue 4.0)*

---

## 🎯 Vision & Objectives

Transform **BlaiseNotebook** into a premier scientific computing and interactive notebook environment for Object Pascal developers, data scientists, and engineers. The plan is organized into **5 core development milestones** approved for implementation.

```mermaid
flowchart LR
    M1["Milestone 1<br/><b>Data Science API</b><br/><i>Concluído</i>"] --> M2["Milestone 2<br/><b>Modular Packages</b><br/><i>Desacoplamento</i>"]
    M2 --> M3["Milestone 3<br/><b>Stateful Kernel</b><br/><i>Backend & Cache</i>"]
    M3 --> M4["Milestone 4<br/><b>Frontend UX</b><br/><i>IntelliSense & DataGrid</i>"]
    M4 --> M5["Milestone 5<br/><b>Dashboard View</b><br/><i>Presentation Mode</i>"]
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

### Milestone 2: Arquitetura Modular de Bibliotecas Desacopladas (`frontend/server/packages/`) 🚀 PRÓXIMO A IMPLEMENTAR
> **Goal:** Desacoplar 100% as bibliotecas do servidor nativo (`server.exe`), modularizando cada biblioteca (Pandas, Scikit-Learn, Math, etc.) em sua própria pasta isolada em `packages/external/`, com auto-descoberta dinâmica no Free Pascal, suporte nativo a `uses` nas células e facilidade de criação/distribuição de novos pacotes.

#### 2.1 Estrutura de Pastas e Separação Modular Granular
- [ ] **`packages/core/`**: Núcleo mínimo essencial do notebook (`BlaiseOutput.pas`, metadados de I/O, tabelas e gráficos).
- [ ] **`packages/external/python_bridge/`**: Ponte isolada de comunicação com CPython/Python4Delphi (`BlaisePyKernel.pas`).
- [ ] **`packages/external/pandas/`**: Wrapper oficial do Pandas (`BlaisePandas.pas`, `requirements.txt`, `package.json`).
- [ ] **`packages/external/sklearn/`**: Wrapper oficial do Scikit-Learn (`BlaiseSklearn.pas`, `requirements.txt`, `package.json`).
- [ ] **`packages/external/math/`**: Pacote oficial de álgebra e estatística nativa Pascal (`BlaiseMathKernel.pas`, `package.json`).
- [ ] **`packages/external/datascience/`**: Unit de compatibilidade retroativa (`BlaiseDataScience.pas` agregando `BlaisePandas` e `BlaiseSklearn`) garantindo que nenhum notebook existente quebre.

#### 2.2 Auto-Descoberta Dinâmica no `uCodeRunner.pas`
- [ ] **Descoberta Automática de Subpastas (`DiscoverPackageUnits`)**: Varredura em tempo de execução de todas as subpastas em `packages/core/` e `packages/external/*`, adicionando os caminhos ao `-Fu` do FPC sem necessidade de reiniciar o servidor.
- [ ] **Parser Inteligente de `uses` na Célula**: Suporte a declaração explícita de `uses MinhaLib, BlaisePandas;` nas células, preservando os imports do usuário e mesclando com o núcleo mínimo do sistema.
- [ ] **Fallback de Compatibilidade para Iniciantes**: Injeção automática das bibliotecas padrão quando a célula não declarar `uses`.

#### 2.3 Suporte ao Comando Mágico `%pip install` Direto na Célula
- [ ] **Execução e Stream em Tempo Real**: Interceptar `%pip install <pacote>` no `uCodeRunner` e despachar para o `pip` do Python configurado, transmitindo a saída em tempo real no console da célula.

#### 2.4 Documentação e Template de Criação de Bibliotecas
- [ ] Guia na documentação explicando o fluxo para criar, empacotar e distribuir novas bibliotecas em `packages/external/`.

---

### Milestone 3: Arquitetura do Kernel e Desempenho (Backend Pascal)
> **Goal:** Deliver instant compilation, variable continuity across cells, and support for multi-output cells.

#### 3.1 Sessão Persistente entre Células (Stateful Kernel)
- [ ] **Shared Session Daemon**: Manter o interpretador Python (`CPython 3.13`) e variáveis Pascal/Python em execução contínua no processo do servidor.
- [ ] **Preservação de Contexto**: Variáveis geradas na Célula 1 (ex: `DF := TPyDataFrame.FromCSV(...)`) ficam imediatamente disponíveis na Célula 2 sem necessidade de recarregamento.
- [ ] **Reset de Sessão**: Comando `Restart Kernel` limpa completamente a memória do workspace.

#### 3.2 Cache Inteligente de Compilação (Zero-Delay Re-run)
- [ ] **Hash de Código SHA-256**: Gerar assinatura única do código-fonte da célula.
- [ ] **Pular Compilação FPC**: Se a célula não foi alterada e o binário correspondente existe, despachar diretamente a execução sem passar pelo compilador.
- [ ] **Invalidação Automática de Cache**: Recompilar apenas quando houver alteração de texto ou mudança nos módulos importados.

#### 3.3 Múltiplas Saídas em uma Única Célula
- [ ] **Multiplexação de Payloads**: Permitir que uma única execução emita múltiplos gráficos e tabelas sequenciais (ex: `DF.ShowTable(...)` seguido de `DF.PlotLine(...)` e `DF.PlotBar(...)`).
- [ ] **Stacking Ordenado**: As saídas são empilhadas de forma organizada abaixo da célula correspondente.

---

### Milestone 4: Experiência de Uso e Produtividade (Frontend & UX)
> **Goal:** Provide a rich, professional, and accessible notebook editing experience.

#### 4.1 Autocompletion & Destaque de Sintaxe Inteligente
- [ ] **Sugestões Contextuais no Editor**:
  - Palavras-chave Object Pascal: `begin`, `end`, `var`, `procedure`, `function`, `Format`, `Writeln`.
  - Métodos fluentes de Data Science: `.AddColumn`, `.Column`, `.ShowTable`, `.PlotLine`, `.PlotBar`, `.ToCSV`, `.FromCSV`.
  - Atalho de gatilho `Ctrl + Space` ou digitação do caractere ponto (`.`).
- [ ] **Colorização Aprimorada**: Destacar strings, comentários, palavras-chave e tipos científicos (`TPyDataFrame`, `TPySeries`, `TVector`).

#### 4.2 Tabelas de Dados Interativas (DataGrid Pro)
- [ ] **Ordenação de Colunas**: Clique no cabeçalho da coluna para ordenar ascendente/descendente no frontend.
- [ ] **Filtro / Busca Rápida**: Barra de pesquisa para filtrar linhas instantaneamente em memória.
- [ ] **Paginação Inteligente**: Paginação de 10, 25, 50 ou 100 linhas por página com navegação fluida.
- [ ] **Exportação Rápida**: Botão "Copiar CSV" ou "Download CSV" direto no cabeçalho da tabela gerada.

---

### Milestone 5: Modo Dashboard / Apresentação (Estilo Streamlit / Voila)
> **Goal:** Transform analytical notebooks into executive presentations and interactive dashboards with a single click.

#### 5.1 Modo "Apenas Saídas" (Dashboard View)
- [ ] **Toggle Button na Toolbar**: Botão `📊 Dashboard View` no topo da tela.
- [ ] **Ocultação de Código**: Esconder editores de código, gutters de linha e indicadores técnicos de compilação.
- [ ] **Layout de Apresentação**:
  - Textos em Markdown/LaTeX renderizados como seções executivas.
  - Tabelas e gráficos em largura total ou cards responsivos lado a lado.
- [ ] **Modo Leitura / Apresentação**: Ideal para compartilhamento em telas de reunião e demonstrações para stakeholders.

---

## 🛠️ Arquitetura Técnica & Tecnologias Envolvidas

| Componente | Tecnologia | Papel |
|---|---|---|
| **Servidor / Kernel** | Free Pascal Compiler (FPC 3.2.2) + Synopse mORMot 2 | Compilação AOT, servidor WebSocket assíncrono e gerenciador de processos |
| **Gerenciador de Pacotes** | Sistema de pacotes modulares (`packages/core/` e `packages/external/`) | Desacoplamento de bibliotecas, auto-descoberta dinâmica de units e wrappers |
| **Ponte de Dados & AI** | Python4Delphi / CPython 3.13 + Pandas + Scikit-Learn | Execução otimizada de Data Science e Machine Learning |
| **Frontend Reativo** | BlaiseVue 4.0 SPA (Transpilador Pascal-to-JS) | Virtual DOM, reatividade por proxy, componentes Single-File (`.bv`) |
| **Visualização** | Chart.js 4.x + Canvas 2D | Gráficos científicos responsivos acelerados por hardware |
| **Formato de Arquivo** | `.bynb` (JSON Schema) | Compatibilidade e persistência completa de metadados, código e saídas |

---

## 📌 Ordem de Execução Atualizada

1. **Fase 1 (Base Científica - CONCLUÍDO)**: Milestone 1 (Novos gráficos, métodos fluentes e modelos no `BlaiseDataScience.pas`).
2. **Fase 2 (Arquitetura Modular - PRÓXIMO)**: Milestone 2 (Desacoplamento em `packages/core/` e `packages/external/`, modularização de Pandas, Sklearn, Math, suporte a `uses` dinâmico e `%pip`).
3. **Fase 3 (Velocidade e Continuidade)**: Milestone 3 (Cache de compilação, múltiplas saídas e sessão persistente).
4. **Fase 4 (Interface Avançada)**: Milestone 4 (Autocompletion de Pascal e DataGrid Pro com paginação/ordenação).
5. **Fase 5 (Apresentação Final)**: Milestone 5 (Dashboard View executivo).

---

*Documento gerado e mantido pela equipe de engenharia do BlaiseNotebook.*
