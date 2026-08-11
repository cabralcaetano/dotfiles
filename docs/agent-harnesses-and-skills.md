# Agent Harnesses & Skills

**Status:** ativo — inventário operacional dos harnesses de agente e skills pessoais.
**Escopo:** Claude Code, Oh My Pi (`omp`), OpenCode (`opencode`) e skills versionadas no dotfiles.

## Objetivo

Guardar no dotfiles o contrato mínimo dos agentes que eu uso para programar e operar projetos. A documentação aqui não substitui os arquivos de configuração reais de cada harness; ela registra onde eles vivem, o que é versionado, o que não pode entrar no repo e como evitar drift entre cópia instalada e cópia versionada.

## Inventário dos harnesses

| Harness | Uso principal | Binário/config local | Estado no dotfiles |
|---|---|---|---|
| `Claude Code` | agente de código com skills `.claude` e integração no fluxo de editor/terminal | configs em `~/.claude/` quando instaladas | skills versionadas em `claude/.claude/skills/`; MCP servers de terceiros documentados em `claude/.claude/mcp/` |
| `Oh My Pi` / `omp` | harness principal neste ambiente; expõe ferramentas de leitura, edição, browser, LSP, subagentes e processos | binário em `~/.bun/bin/omp`; configs/skills em `~/.omp/agent/` | documentado aqui; não stowar secrets/cache |
| `OpenCode` / `opencode` | harness mais enxuto para tarefas de código convencionais | PATH em `zsh/.zshrc`: `~/.opencode/bin` | só o PATH está versionado por enquanto |

Regras:

- Nunca versionar token, cookie, senha, cache de sessão ou transcript privado.
- Versionar apenas skill, script utilitário, template, README e regra que seja segura para máquina nova.
- Se uma skill instalada mudar em `~/.omp/agent/skills/` ou `~/.claude/skills/`, copiar a mudança para `claude/.claude/skills/` quando ela virar contrato estável.
- O clone ativo de aplicação é `~/Projects/dotfiles`; o submodule em `wiki-ia/personal/projects/dotfiles/` deve ser mantido sincronizado quando a mudança for operacional.

```text
claude/.claude/skills/
└── teachflow-board/
    ├── SKILL.md
    └── scripts/tb.sh

claude/.claude/mcp/
├── README.md
└── notebooklm.md
```

Apesar do nome histórico `teachflow-board`, essa skill foi redefinida em 2026-07-30 para operar **somente tasks/cards do Horizon CRM**. O nome técnico permaneceu porque já era o mount carregado pelos harnesses.

## Skill atual — Horizon CRM Tasks / Activity Board

Nome técnico: `teachflow-board`.

Gatilhos naturais:

- "quais tasks do Horizon tem abertas?"
- "o que tem on no Horizon CRM?"
- "vou atacar essa task"
- "move essa task para em andamento"
- "concluí essa task"
- "marca esse item da checklist como concluído"
- "sincroniza o Kanban do Horizon com os `.md`"

Contrato atual:

1. O Kanban do Horizon CRM em `/team/activity-board` e os arquivos markdown locais devem ficar coerentes.
2. Ao listar tasks, o agente lê o board e os arquivos:
   - `work/projects/horizonconsultoria/horizon-crm/_tasks.md`
   - `work/_tasks.md` seção Horizon
3. Ao "atacar" uma task, move o card para `em_andamento` e marca o item local como `[~]`.
4. Ao concluir uma task, move o card para `concluidos` e marca o item local como `[x]`.
5. Ao concluir checklist parcial, usa `item-update` no board e espelha o subitem no markdown quando houver valor operacional.
6. Toda escrita deve ser verificada com `get/list` do board e releitura das linhas `.md` alteradas.

Segurança:

- A skill não deve alterar cards do Teachflow/CodeUp.
- `tb.sh` defaulta para Horizon CRM.
- `TEAM_BOARD_TARGET=teachflow` é bloqueado salvo override explícito com `TEAM_BOARD_ALLOW_TEACHFLOW=1`.
- `delete`, mudança para target de produção não verificado, banco, webhook e segredo exigem confirmação explícita.

## Scripts de skill

`claude/.claude/skills/teachflow-board/scripts/tb.sh` é um `curl` client fino para o Activity Board. Ele fala JSON in/out e não depende de `jq` para funcionar.

Comandos relevantes no Horizon:

| Comando | Uso |
|---|---|
| `list [query_string]` | listar cards por status/página |
| `get <card_id>` | abrir bundle completo do card |
| `update <card_id> '<json>'` | mover coluna ou editar card |
| `comment '<json>'` | adicionar comentário |
| `checklist-*` | criar/editar/remover checklist |
| `item-update <item_id> '<json>'` | marcar/desmarcar item de checklist |
| `users` | listar usuários internos |

Payload Horizon usa `camelCase`: `cardId`, `memberUserIds`, `orderIndex`, `isCompleted`.

## Como promover ou editar uma skill minha

Checklist de manutenção:

1. Definir gatilho natural em linguagem do usuário.
2. Definir escopo negativo: o que a skill **não** pode tocar.
3. Registrar arquivos de contexto que devem ser lidos antes de agir.
4. Registrar ações permitidas sem nova confirmação e ações que exigem confirmação.
5. Guardar scripts junto da skill quando forem parte do contrato.
6. Rodar validação mínima: sintaxe dos scripts e leitura do `SKILL.md` pelo harness alvo.
7. Sincronizar cópia instalada e cópia versionada no dotfiles.
8. Atualizar este documento quando a mudança virar rotina.

## Diferença prática entre os harnesses

- `Oh My Pi` é o harness mais amplo e carregado de ferramentas. Usar quando a tarefa mistura repo, docs, browser, LSP, arquivos variados, subagentes ou verificação mais pesada.
- `OpenCode` é o caminho enxuto para edição comum de código quando não precisa de muita superfície extra.
- `Claude Code` continua útil quando a skill/fluxo está no ecossistema `.claude` ou quando a integração com o editor for o caminho mais direto.

Não tratar harness como religião. Escolher pelo atrito da tarefa e pela ferramenta que dá melhor verificação com menor risco.
