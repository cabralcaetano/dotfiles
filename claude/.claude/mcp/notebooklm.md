# NotebookLM (Gemini Notebook) — MCP servers

**Status:** avaliado em 2026-08-10, **instalado e autenticado no Oh My Pi** nesta máquina
(`~/.omp/agent/mcp.json`, servidor `notebooklm`). Não instalado no Claude Code por enquanto.

## API/MCP oficial

Google **não** oferece API pública nem MCP oficial pro NotebookLM (renomeado
"Gemini Notebook"). Só existe API Enterprise via Google Cloud, sem uso individual.
Tudo abaixo é automação de terceiros: um browser real (Chromium/Chrome via
Playwright/Patchright) dirigido com a sessão logada do usuário, ou chamada direta
à RPC interna (`batchexecute`) que o próprio webapp usa.

## Alternativas avaliadas

| Critério | `roomi-fields/notebooklm-mcp` | `PleasePrompto/notebooklm-mcp` |
|---|---|---|
| Transporte | RPC interna `batchexecute` (mesma do webapp) + fallback DOM | Só scraping de DOM via browser |
| Velocidade | 10-100× mais rápido (listar notebooks ~1s vs ~30s) | Mais lento, depende de render de página |
| Resiliência a redesign de UI | Alta — RPC não muda com rebrand visual | Baixa — quebra quando o Google muda a UI |
| Studio (áudio/vídeo/infográfico/relatório/apresentação/flashcards/quiz/mindmap) | Completo | Só áudio |
| Integração | MCP + REST API (33 endpoints — n8n/Zapier/Make) | Só MCP (stdio/HTTP) |
| Multi-conta | Sim, com auto-reauth (inclusive Google Workspace) | Sim, sem auto-reauth |
| RTFM (vault offline pesquisável) | Sim (`/batch-to-vault`) | Não |
| Maturidade | v3.0.1, 148★, releases recentes | Mais maduro (3.2k★), escopo mais estreito |

**Recomendação: `roomi-fields/notebooklm-mcp`.** Cobre tudo que o `PleasePrompto` cobre
mais REST API, Studio completo e integração RTFM, sem custo extra de complexidade de
setup (comando de instalação equivalente).

Repos:
- https://github.com/roomi-fields/notebooklm-mcp
- https://github.com/PleasePrompto/notebooklm-mcp

## Capacidades (roomi-fields)

- **Q&A com citação** — pergunta grounded nas fontes do notebook, sessão multi-turno,
  citação em 4 formatos (inline, footnote, JSON, expandido).
- **Fontes** — adicionar PDF/DOCX/TXT/URL/texto/YouTube/Drive; listar/organizar;
  descoberta de fontes novas via pesquisa web/Drive.
- **Studio** — Audio Overview, vídeo (6 estilos), infográfico, relatório, apresentação,
  data table, flashcards, quiz, mind map; download de tudo (WAV/MP4/PNG).
- **Notebooks** — criar/listar/renomear/deletar; biblioteca local com metadados e busca;
  compartilhamento; labels.
- **Automação** — REST API (33 endpoints) pra n8n/Zapier/Make/curl; batch de milhares de
  perguntas overnight; multi-conta com rotação.
- **RTFM** — `/batch-to-vault` grava respostas citadas como markdown + JSON sidecar
  (`nblm-answer-v1`), indexável por FTS5/semântica — base de conhecimento offline.

## Setup (Claude Code)

```bash
claude mcp add notebooklm -- npx @roomi-fields/notebooklm-mcp@latest
```

ou via plugin marketplace:

```bash
/plugin marketplace add roomi-fields/claude-plugins
/plugin install notebooklm@roomi-fields
```

Login único **num terminal**, não pedindo pro agente fazer — abre Chrome visível e pode
estourar o timeout de tool-call de alguns clientes MCP (Claude Desktop, por exemplo):

```bash
npx -y -p @roomi-fields/notebooklm-mcp notebooklm-mcp-setup-auth
```

Cookies ficam persistidos em `~/.local/share/notebooklm-mcp/chrome_profile/` (Linux);
runs seguintes já autenticados sem novo login.

## Setup (Oh My Pi / `omp`)

MCP no omp é declarado em `~/.omp/agent/mcp.json` (escopo user, todos os projetos) ou
`.omp/mcp.json` (escopo projeto). Ver `omp://mcp-config.md` pra referência completa.

1. Registrar o server em `~/.omp/agent/mcp.json`:

   ```json
   {
     "$schema": "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json",
     "mcpServers": {
       "notebooklm": {
         "command": "npx",
         "args": ["-y", "@roomi-fields/notebooklm-mcp@latest"]
       }
     }
   }
   ```

2. Instalar o browser que o Patchright (dependência do server) precisa — passo que o
   `npx` sozinho não resolve:

   ```bash
   npx -y patchright install chromium
   ```

3. Rodar o login **num terminal separado**, não pela conversa com o agente (abre Chrome
   visível, esperando login manual até 10 min):

   ```bash
   npx -y -p @roomi-fields/notebooklm-mcp notebooklm-mcp-setup-auth
   ```

   Ao final: `Google session valid for ~399 days`. Cookies persistidos em
   `~/.local/share/notebooklm-mcp/chrome_profile/`.

4. Dentro do omp, recarregar a config de MCP e verificar:

   ```text
   /mcp reload
   /mcp list
   /mcp test notebooklm
   ```

   `/mcp reload` é necessário porque a sessão já ativa carregou o `mcp.json` no boot —
   editar o arquivo em runtime não muda os servers disponíveis até recarregar (ou
   reiniciar a sessão).

Validado nesta máquina em 2026-08-10: binário sobe, expõe as tools (`ask_question`
substituído por `notebook_ask`, `source_add`, `content_generate`, `vault_batch`,
`notebook_list`, etc. — nomenclatura namespaced da v3), auth persistida.

## Riscos

- Não é ToS-sanctioned pelo Google — é automação de browser/RPC reversa da conta pessoal,
  não uma API pública. Ambos os projetos recomendam **conta Google dedicada** pra
  automação, não a principal, por risco de flag/detecção.
- `batchexecute` é endpoint interno não documentado; pode mudar sem aviso (o projeto
  mantém fallback DOM justamente por isso).

## Aplicação prática (vault `wiki-ia`)

- Ingest assistido: jogar fonte densa (PDF, paper, vídeo longo) no NotebookLM, perguntar
  pontos-chave com citação, usar a resposta como rascunho estruturado pra virar página
  wiki (`raw/` → resumo grounded → `wiki/`).
- Fact-check antes de escrever afirmação técnica na wiki.
- Batch de research sobre corpus grande (curso, dossiê de projeto) trazendo tudo já citado.

## Fontes

- https://github.com/roomi-fields/notebooklm-mcp
- https://github.com/PleasePrompto/notebooklm-mcp
- https://mcpservers.org/servers/roomi-fields/notebooklm-mcp
