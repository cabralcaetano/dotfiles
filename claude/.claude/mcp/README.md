mcp/
├── README.md          este arquivo — índice
└── notebooklm.md       avaliação de MCP servers pra NotebookLM/Gemini Notebook

# MCP servers — inventário

Pasta irmã de `claude/.claude/skills/`. Guarda documentação de MCP servers de terceiros
avaliados ou usados nos harnesses de agente (Claude Code, Oh My Pi, OpenCode) — não são
skills próprias, são integrações externas que valem registro pra não re-pesquisar do zero
e pra manter rastro de por que uma opção foi escolhida sobre outra.

Cada arquivo aqui cobre um MCP server (ou um pequeno grupo de alternativas concorrentes
pro mesmo serviço) com:

- o que o serviço oferece de API/MCP oficial (se houver);
- as alternativas de terceiros avaliadas, com prós/contras;
- a recomendação e por quê;
- comando de instalação/setup pro harness usado neste ambiente;
- riscos conhecidos (ToS, dependência de scraping, dados sensíveis).

## Índice

| Arquivo | Serviço | Status |
|---|---|---|
| `notebooklm.md` | Google NotebookLM / Gemini Notebook | instalado no omp (user-level) |

## Regra

Igual `skills/`: nunca versionar token, cookie, sessão salva ou config com segredo — só a
documentação e, quando existir, script utilitário sem credencial embutida.
