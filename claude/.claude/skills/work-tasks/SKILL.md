---
name: work-tasks
description: Criar, modificar, mover, concluir e listar tasks da camada `/work` do vault `wiki-ia`, sincronizando `_tasks.md` locais com o Horizon CRM Activity Board quando o projeto usa o board. Use sempre que o usuário pedir para criar/alterar/concluir/listar task de trabalho, tasks do Horizon, tasks de cliente, Kanban `/team/activity-board`, espaço Nádia, DOCS, Suelen ou task interna da Horizon.
---

# Work Tasks / Horizon Activity Board

Esta skill é o ponto único para tasks de **trabalho** no `wiki-ia`.

Use quando o pedido tocar:

- `work/_tasks.md`;
- `work/projects/**/_tasks.md`;
- tasks/cards do Horizon CRM Activity Board (`/team/activity-board`);
- tasks de clientes em espaços do Horizon (`Nádia`, `DOCS Membros`, `Suelen`, etc.);
- tasks internas da própria Horizon.

Para `personal/`, use a skill `wiki-tasks`. Para pesquisa/wiki sem task operacional, use o router/wiki workflow normal.

## Regra nova do operador — 2026-08-28

Quando o operador pedir para criar ou modificar uma task de `/work`, esta skill deve decidir o destino completo:

1. arquivo `_tasks.md` detalhado do projeto;
2. resumo em `work/_tasks.md`;
3. card/checklist no Horizon CRM Activity Board quando o projeto usa o board;
4. `clientSpaceId` correto quando o card é de cliente.

Não espere o operador dizer "joga no espaço da Nádia", "joga no espaço DOCS" ou "é interno". Inferir pelo projeto/cliente e registrar a decisão. Pergunte só se dois destinos forem realmente plausíveis e tiverem efeitos diferentes.

Essa regra substitui a regra antiga de 2026-08-04 que exigia pedido explícito para qualquer card novo. A versão atual é:

- pedido de task de `/work` com projeto/cliente claro → criar/sincronizar task local e board no destino inferido;
- achado técnico ou follow-up dentro de card pai óbvio → adicionar item de checklist no card pai, não criar card solto;
- pedido genérico sem projeto/cliente e sem card pai óbvio → perguntar o destino antes de criar no board.

## Contexto mínimo

Leia por camadas, sem varrer o vault:

1. `work/_tasks.md`;
2. `_tasks.md` do projeto citado;
3. página principal do projeto (`_{project}.md`) se precisar entender contexto;
4. `work/projects/horizonconsultoria/horizon-crm/_tasks.md` quando houver board/card;
5. board real via `tb.sh` para verificar ou criar card/checklist.

Para listagem aberta de tasks, leia `work/_tasks.md` inteiro e percorra todas as seções. Para detalhe de projeto, abra também o `_tasks.md` específico.

## Mapa atual de espaços do Horizon

Use `clientSpaceId` no card do Activity Board:

| Destino inferido | `clientSpaceId` | Exemplos de gatilho |
|---|---:|---|
| Nádia Contabilidade Ltda | `71d7cfd0-573e-4741-a28c-dd1b0293aeda` | Nádia, Contabil OS, Contabilidade, `contabil-*`, site institucional Nádia |
| DOCS Membros | `a05535b5-9782-49a9-b4d9-ae40b0b4dcef` | DOCS Membros, área de membros da DOCS, `docs-membros-*` |
| Suelen França Óculo's | `54adc036-4172-4b4d-a48c-328986dabfa7` | Suelen, Óculos, receita gratuita, grupos Suelen |
| Interno · equipe | omitir `clientSpaceId` ou enviar `null` | Horizon CRM interno, infra KVM2, WhatsApp/Instagram API da Horizon, tarefas administrativas da Horizon |

Antes de usar um ID fora desse mapa, rode `tb.sh spaces` e escolha pelo nome real. Se um espaço existir no Horizon e ainda não estiver no mapa, atualize esta tabela na mesma sessão.

## Tool

Script:

```bash
~/.omp/agent/skills/work-tasks/scripts/tb.sh <command> [args]
```

Alvo default: Horizon CRM produção real.

```bash
export TEAM_BOARD_TARGET=horizon
```

`HORIZON_CRM_API_URL` defaulta para `https://api-crm.consultoriahorizon.com.br`.

Credenciais vivem fora do vault/repo/chat:

- arquivo default: `~/.config/horizon-crm/board.env`;
- permissões obrigatórias: `0600` ou `0400`;
- variáveis aceitas: `HORIZON_CRM_EMAIL`/`HORIZON_CRM_PASSWORD` ou `HORIZON_CRM_ACCESS_TOKEN`.

Nunca peça senha no chat. Se faltar credencial, oriente o operador a criar/ajustar o arquivo externo.

Comandos principais:

| Command | Purpose |
|---|---|
| `spaces` | Lista espaços de cliente (`/api/v1/client-spaces/`) para resolver `clientSpaceId`. |
| `users` | Lista usuários internos para resolver responsáveis. |
| `list [query_string]` | Lista cards. Aceita `status`, `clientSpaceId`, `limit`, `offset`. |
| `get <card_id>` | Detalhe completo: card, members, comments, checklists+items, attachments. |
| `create '<json>'` | Cria card com camelCase. |
| `update <card_id> '<json>'` | Edita card ou move coluna. |
| `member-add '<json>'` / `member-remove <member_id>` | Gerencia membros. |
| `checklist-add` / `checklist-update` / `checklist-delete` | Gerencia checklists. |
| `item-add` / `item-update` / `item-delete` | Gerencia itens de checklist. |
| `comment '<json>'` | Adiciona comentário. |

JSON Horizon CRM usa camelCase:

```json
{
  "title": "Analisar Linktree/link-in-bio — Nádia",
  "description": "Tracking local: CONTABIL-57.",
  "criticality": "media",
  "status": "backlog",
  "dueDate": "2026-08-31",
  "clientSpaceId": "71d7cfd0-573e-4741-a28c-dd1b0293aeda",
  "memberUserIds": ["ceaa8bb9-b8b2-4054-a76d-cfce9f67ccdb"]
}
```

Para card interno, omita `clientSpaceId` ou envie `null`.

Status válidos: `backlog`, `priorizados`, `em_andamento`, `em_aprovacao`, `reprovados`, `aprovados`, `bloqueados`, `concluidos`.

Criticidade: `baixa`, `media`, `alta`.

Exemplos:

```bash
bash ~/.omp/agent/skills/work-tasks/scripts/tb.sh spaces
bash ~/.omp/agent/skills/work-tasks/scripts/tb.sh list "clientSpaceId=71d7cfd0-573e-4741-a28c-dd1b0293aeda&status=backlog&limit=20&offset=0"
bash ~/.omp/agent/skills/work-tasks/scripts/tb.sh create '{"title":"...","status":"backlog","criticality":"media","clientSpaceId":"..."}'
bash ~/.omp/agent/skills/work-tasks/scripts/tb.sh item-update "$ITEM_ID" '{"isCompleted":true}'
```

## Fluxo — criar task de `/work`

1. Identifique projeto e prefixo local:
   - Contabil OS/Nádia → `CONTABIL-xx`, arquivo `work/projects/horizonconsultoria/contabil/_tasks.md`;
   - DOCS Membros → `DOCS-xx`, arquivo `work/projects/horizonconsultoria/docs-membros/_tasks.md`;
   - Horizon CRM interno → `HCRM-xx`, arquivo `work/projects/horizonconsultoria/horizon-crm/_tasks.md`;
   - outros projetos → siga o prefixo já usado no `_tasks.md` do projeto.
2. Escolha o próximo ID livre no arquivo detalhado do projeto. Não reutilize ID concluído.
3. Escreva a task granular com: objetivo, contexto suficiente, aceite observável e, se houver board, card/checklist associado.
4. Sincronize `work/_tasks.md` na seção do projeto.
5. Se o projeto usa Horizon Activity Board, crie card ou item de checklist:
   - card novo quando a task for entrega top-level ou o operador pedir uma task separada;
   - item de checklist quando houver card pai óbvio;
   - `clientSpaceId` inferido pela tabela de espaços;
   - membros inferidos por padrão do projeto ou de cards semelhantes. Se incerto, use o criador/operador como responsável e registre que dono final falta definir.
6. Atualize `work/projects/horizonconsultoria/horizon-crm/_tasks.md` quando criar/mover/alterar card no board.
7. Registre `wiki/log.md` quando a sessão alterar board, múltiplos arquivos, ou criar/fechar task relevante.

## Fluxo — modificar, mover, concluir

Ao modificar task existente:

1. Resolva por ID local (`CONTABIL-57`, `HCRM-162`), `card_id`, título ou último item citado.
2. Leia o card real com `get` quando existir board.
3. Atualize board e markdown na mesma sessão:
   - status board ↔ `[ ]`/`[~]`/`[x]`;
   - título/descrição/checklist ↔ texto local;
   - `clientSpaceId` corrigido se a task estiver em espaço errado.
4. Nunca mova para `aprovados`/`concluidos` sem pedido explícito ou prova objetiva.
5. Verifique com `get`/`list` e releitura dos trechos markdown alterados.

## Reconciliação board ↔ markdown

Mapeie nesta ordem:

1. ID explícito (`HCRM-xx`, `CONTABIL-xx`, `DOCS-xx`) no título, descrição, comentário ou checklist;
2. `card_id` registrado no markdown;
3. título praticamente idêntico;
4. checklist/conteúdo apontando para a mesma entrega.

Divergência clara deve ser corrigida dos dois lados. Se API/credencial falhar, deixe claro qual lado foi atualizado e qual ficou pendente.

## Segurança

- Produção Horizon CRM é o alvo default permitido para operações de task.
- Confirmar antes de `delete`, mudança de `HORIZON_CRM_API_URL` para staging/local, ação destrutiva em banco, segredo/webhook real ou merge/deploy.
- Não alterar cards Teachflow/CodeUp por esta skill; o modo Teachflow no script é legado técnico e bloqueado sem `TEAM_BOARD_ALLOW_TEACHFLOW=1`.
- Nunca registrar tokens, senhas ou API keys no vault.

## Fechamento obrigatório

Após alteração, responder curto com:

- card alterado/criado (`card_id`, título, status, espaço);
- task local alterada (`ID`, arquivo);
- checklist alterado, quando houver;
- arquivos markdown sincronizados;
- verificação executada (`get`, `list`, releitura);
- bloqueio restante, se houver.
