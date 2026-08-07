---
name: teachflow-board
description: Gerenciar cards/tasks do Horizon CRM Activity Board e sincronizar o estado com os arquivos markdown do vault (`work/projects/horizonconsultoria/horizon-crm/_tasks.md` e `work/_tasks.md`). Use quando o usuário falar de tasks do Horizon CRM, Kanban `/team/activity-board`, atacar/pegar uma task, atualizar uma task, concluir uma task ou marcar item de checklist.
---

# Horizon CRM Tasks / Activity Board

Esta skill agora é **Horizon CRM only**. Ela não cria, move, conclui nem edita cards do Teachflow. O script legado ainda conhece o alvo Teachflow por compatibilidade técnica, mas o uso operacional desta skill é apenas o Kanban do Horizon CRM em `/team/activity-board`, backed pela API `.NET` do Horizon e schema Postgres `team.*`.

Contexto de projeto:

- `work/projects/horizonconsultoria/horizon-crm/_horizon-crm.md`
- `work/projects/horizonconsultoria/horizon-crm/_tasks.md`
- `work/_tasks.md` seção `## Horizon CRM (HorizonConsultoria)`
- `work/projects/horizonconsultoria/horizon-crm/session-2026-07-29-activity-board-port.md` quando precisar de histórico do port do board.

## Setup

O alvo padrão do script deve ser Horizon CRM:

```bash
export TEAM_BOARD_TARGET=horizon
export HORIZON_CRM_API_URL="http://localhost:5029"
export HORIZON_CRM_EMAIL="..."
export HORIZON_CRM_PASSWORD="..."
```

Nunca grave senha/token no vault nem cole segredo no chat. Se credenciais faltarem, peça para o usuário exportar no shell atual. `HORIZON_CRM_ACCESS_TOKEN` pode substituir email/senha quando já houver token válido.

`HORIZON_CRM_API_URL` defaulta para `http://localhost:5029`. Só aponte para staging/prod quando o usuário pedir explicitamente e o deploy/API tiverem sido verificados. Para produção, operações de status/checklist pedidas explicitamente pelo usuário contam como intenção suficiente; deleção e mudança de target continuam exigindo confirmação.

Cache de sessão:

- Horizon token response: `~/.cache/horizon-crm-board/token.json` (0600).

O script reautentica uma vez em `401`; quando há `refreshToken` no cache, tenta refresh proativo antes de expirar.

## Tool

`.claude/skills/teachflow-board/scripts/tb.sh <command> [args]` — thin curl client, JSON in/out, sem `jq` obrigatório. Run sem args mostra a lista completa de comandos.

Comandos principais para Horizon CRM:

| Command | Purpose |
|---|---|
| `list [query_string]` | Lista cards. Retorna `{cards,total,limit,offset,status}`. Use `"status=em_andamento&limit=20&offset=0"` para uma coluna. |
| `get <card_id>` | Detalhe completo: members, comments, checklists+items, attachments. |
| `create '<json>'` | Cria card com camelCase: `{title, description?, criticality?, dueDate?, status?, memberUserIds?}`. |
| `update <card_id> '<json>'` | Edita card ou move coluna: `{"status":"em_andamento"}`. |
| `comment '<json>'` | Adiciona comentário: `{cardId, content}`. |
| `checklist-add` / `checklist-update` / `checklist-delete` | Checklist: `{cardId, title}` / `{title?, orderIndex?}` / by id. |
| `item-add` / `item-update` / `item-delete` | Item de checklist: `{checklistId, title}` / `{title?, isCompleted?, orderIndex?}` / by id. |
| `users [query]` | Usuários internos do Horizon. |

Board columns (`status`, em ordem do Kanban): `backlog`, `priorizados`, `em_andamento`, `em_aprovacao`, `reprovados`, `aprovados`, `bloqueados`, `concluidos`.
`criticality`: `baixa` | `media` (default) | `alta`.

Exemplos:

```bash
bash .claude/skills/teachflow-board/scripts/tb.sh list "status=priorizados&limit=20&offset=0"
bash .claude/skills/teachflow-board/scripts/tb.sh update "$CARD_ID" '{"status":"em_andamento"}'
bash .claude/skills/teachflow-board/scripts/tb.sh item-update "$ITEM_ID" '{"isCompleted":true}'
```

## Fluxo operacional

O estado de task do Horizon CRM vive em dois lugares e deve ficar coerente:

1. Kanban Horizon CRM (`/team/activity-board`) — estado colaborativo visível.
2. Markdown local — `work/projects/horizonconsultoria/horizon-crm/_tasks.md` e resumo em `work/_tasks.md`.

Quando o usuário perguntar "quais tasks tem", "o que tem on", "tasks do Horizon", ou equivalente:

1. Liste o board Horizon, pelo menos as colunas abertas (`backlog`, `priorizados`, `em_andamento`, `bloqueados`, `em_aprovacao`, `reprovados`), paginando se necessário.
2. Leia `work/projects/horizonconsultoria/horizon-crm/_tasks.md` e a seção Horizon de `work/_tasks.md`.
3. Mostre as opções com `card_id`, título, status do Kanban, ID local (`HCRM-xx`) quando houver, checklist pendente relevante e divergências board↔markdown.

Quando o usuário disser "vou atacar essa", "pego essa", "vou trabalhar nessa", ou equivalente:

1. Resolva a task pelo último card listado, `card_id`, ID `HCRM-xx` ou título. Se houver ambiguidade real, pergunte qual card.
2. Mova o card para `em_andamento`: `update <card_id> '{"status":"em_andamento"}'`.
3. Marque a task local correspondente como `[~]` no `_tasks.md` do projeto e sincronize o resumo em `work/_tasks.md` quando a task aparecer lá.
4. Verifique com `get <card_id>` e releitura das linhas markdown alteradas antes de responder.

Quando o usuário concluir uma task:

1. Mova o card para `concluidos`.
2. Marque a task local como `[x]` no arquivo de projeto e no master quando existir.
3. Se a conclusão for parcial ou depender de aprovação/review, use `em_aprovacao` ou mantenha `[~]` em vez de `[x]`; não declarar concluído sem sinal explícito do usuário ou evidência verificada.
4. Verifique board + markdown.

Quando o usuário concluir parte da checklist:

1. Use `get <card_id>` para localizar o checklist item exato.
2. Rode `item-update <item_id> '{"isCompleted":true}'` ou `false` para desfazer.
3. Atualize o checklist/subitem equivalente no markdown local quando existir. Se o markdown ainda não tiver espelho do checklist e a informação for operacionalmente útil, adicione sub-bullet sob a task `HCRM-xx`.
4. Verifique com `get <card_id>` e releitura do markdown.

## Reconciliação

Mapeie board↔markdown nesta ordem:

1. ID explícito `HCRM-xx` no título, descrição, comentário ou checklist.
2. Título praticamente idêntico.
3. Conteúdo/checklist que aponta para a mesma entrega.

Se board e markdown divergirem:

- Corrija ambos na mesma sessão quando a intenção do usuário for clara.
- Se só um lado puder ser atualizado (API offline, credenciais ausentes, conflito no arquivo), reporte a divergência concreta e deixe claro qual lado ficou pendente.
- Não apague task local só porque não há card correspondente; proponha criar card ou manter local-only.

## Segurança

- Operações explícitas do usuário sobre task do Horizon (`vou atacar`, `atualiza`, `marca checklist`, `concluí`) autorizam `update`, `comment`, `checklist-*` e `item-*` no Horizon CRM e a edição dos `.md` locais.
- Sempre confirme antes de `delete`, mudança de `HORIZON_CRM_API_URL` para produção/staging não verificada, ação destrutiva em banco ou qualquer operação que altere segredo/webhook real.
- Nunca mova card para `aprovados`/`concluidos` sem pedido explícito ou prova objetiva de conclusão.
- Nunca use esta skill para alterar cards do Teachflow/CodeUp. Se o pedido for Teachflow, use o fluxo de tasks local ou outra skill apropriada.

## Fechamento

Toda resposta após alteração deve dizer, de forma curta:

- card alterado (`card_id`, título, status final);
- linhas/arquivos markdown sincronizados;
- checklist item alterado, quando houver;
- verificação executada (`get`, `list`, releitura dos `.md`);
- bloqueio restante, se houver.
