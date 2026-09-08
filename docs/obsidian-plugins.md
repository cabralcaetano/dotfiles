# Obsidian — plugins e config

**Escopo:** `obsidian/` guarda só as configs (`.obsidian/*.json` + `snippets/`) de referência do vault principal (`~/Projects/wiki-ia`). Não entra no `bootstrap.sh` — é manual, aplicado copiando/stow desses arquivos pro `.obsidian/` do vault.

Plugins em si **não são vendorizados** aqui (ver `.gitignore`: `obsidian/plugins/*`). Todos são de terceiros, reinstaláveis pela loja de community plugins do Obsidian a partir de `obsidian/community-plugins.json`. Histórico: `default-zoom-fixer` chegou a ter o source completo vendorizado por engano (removido em `e095c17`/`8784be0`) — não é plugin próprio, é do [mcavallo](https://github.com/mcavallo).

## Community plugins (`community-plugins.json`)

| Plugin | Autor | Uso |
|---|---|---|
| `default-zoom-fixer` | mcavallo | Fixa o zoom padrão do Obsidian no startup (evita reabrir com zoom herdado de outra tela/sessão). |
| `dataview` | blacksmithgu | Queries dinâmicas sobre notas (listas/tabelas geradas a partir de frontmatter e links) — usado nos hubs e dashboards do vault `wiki-ia`. |
| `homepage` | mirnovov | Abre o vault sempre numa nota fixa (dashboard) em vez da última nota editada. |
| `obsidian-kanban` | mgmeyers | Boards Kanban em Markdown — usado pra tracking visual pontual fora do `_tasks.md`. |

## Core plugins (`core-plugins.json`)

A maioria dos core plugins do Obsidian fica ligada (file explorer, search, graph, backlinks, canvas, daily notes, templates, bookmarks, outline, bases, sync...). Desligados em `core-plugins.json`:

`footnotes`, `slash-command`, `markdown-importer`, `zk-prefixer`, `random-note`, `slides`, `audio-recorder`, `workspaces`, `publish`, `webviewer`.

## Appearance e snippets

- Tema: `obsidian` (padrão), sem tema de terceiros.
- `enabledCssSnippets`: `github-dark-chart` (`obsidian/snippets/github-dark-chart.css`).
- `obsidian/snippets/home-dashboard.css` existe no repo mas não está em `enabledCssSnippets` — não habilitado atualmente.

## Grafo (`graph.json`)

Filtro do Global Graph configurado sem tags/attachments/unresolved, com órfãos visíveis (`showOrphans: true`, mostra notas sem link de entrada). Regra do vault `wiki-ia` (`AGENTS.md`): não alterar esse filtro nem criar bridge link só pra forçar conectividade.

## Como reaplicar num vault novo

1. Instalar os 4 community plugins pela loja do Obsidian (ou copiar `community-plugins.json` pro `.obsidian/` do vault e reiniciar — Obsidian baixa automaticamente os que faltam).
2. Copiar `core-plugins.json`, `appearance.json`, `app.json`, `graph.json`, `hotkeys.json`, `bookmarks.json` e `snippets/` pro `.obsidian/` do vault alvo.
3. Ajustar `bookmarks.json` — os paths (`work/_tasks.md`, `wiki/index.md`, etc.) são específicos do vault `wiki-ia`.
