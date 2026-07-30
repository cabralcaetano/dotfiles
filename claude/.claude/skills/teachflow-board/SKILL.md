---
name: teachflow-board
description: Create, edit, move, and assign cards on the Teachflow internal "Team Board" or the Horizon CRM Activity Board. Use when the user wants to create/update/move a shared work card, assign members, add comments/checklists, reconcile board state with `work/_tasks.md`, or specifically manage Horizon CRM `/team/activity-board` cards.
---

# Teachflow / Horizon CRM Activity Board

Wraps two related internal kanban APIs:

- **Teachflow Team Board** — the CodeUp team's live internal "Quadro de Atividades" at `/team` → Activity Board in `teachflow-grid`, backed by `teachflow-backend`. This is **not** the CRM/leads kanban (`whatsapp_conversations.crm_status`) — do not confuse the two.
- **Horizon CRM Activity Board** — the ported board at `/team/activity-board` in `horizon-crm`, backed by the Horizon `.NET` API and Postgres schema `team.*`.

Full Teachflow context: `work/projects/codeup/teachflow/_teachflow.md`.
Full Horizon CRM context: `work/projects/horizonconsultoria/horizon-crm/_horizon-crm.md` and `work/projects/horizonconsultoria/horizon-crm/session-2026-07-29-activity-board-port.md`.

## Setup (one time, per shell)

Default target is Teachflow because it is the shared production team board:

```bash
export TEAM_BOARD_TARGET=teachflow
export TEACHFLOW_ADMIN_EMAIL="..."
export TEACHFLOW_ADMIN_PASSWORD="..."
```

For Horizon CRM, switch the target and authenticate against the Horizon API:

```bash
export TEAM_BOARD_TARGET=horizon
export HORIZON_CRM_API_URL="http://localhost:5029"
export HORIZON_CRM_EMAIL="..."
export HORIZON_CRM_PASSWORD="..."
```

Never write passwords to a file in this repo or echo them back. If credentials are missing, ask the user to export them in the current shell rather than typing the password into chat. For Horizon, `HORIZON_CRM_ACCESS_TOKEN` may be supplied instead of email/password when an access token is already available.

Teachflow API base defaults to prod (`https://api-crm.codeup.dev.br`). Override with `TEACHFLOW_API_URL` for preprod only when the user says so explicitly.

Horizon CRM API base defaults to local (`http://localhost:5029`). Override with `HORIZON_CRM_API_URL` for staging/prod only when the user says so explicitly and the deployment has been verified.

Session cache:

- Teachflow cookie: `~/.cache/teachflow-board/cookies.txt` (0600).
- Horizon token response: `~/.cache/horizon-crm-board/token.json` (0600).

The script re-authenticates once on a 401.

## Tool

`.claude/skills/teachflow-board/scripts/tb.sh <command> [args]` — thin curl client, JSON in/out, no jq required. Run `bash .claude/skills/teachflow-board/scripts/tb.sh` with no args for the full command list. Key ones:

| Command | Purpose |
|---|---|
| `list [query_string]` | Lists cards. Teachflow returns the board bundle; Horizon returns `{cards,total,limit,offset,status}`. Pass `"status=em_andamento&limit=10&offset=0"` to page through one column. |
| `get <card_id>` | Full card detail: members, comments, checklists+items, attachments. |
| `create '<json>'` | New card. Teachflow uses `{title, description?, criticality?, due_date?, status?, member_user_ids?}`; Horizon uses `{title, description?, criticality?, dueDate?, status?, memberUserIds?}`. |
| `update <card_id> '<json>'` | Edit or **move column**. Teachflow uses snake_case (`due_date`, `order_index`); Horizon uses camelCase (`dueDate`, `orderIndex`). |
| `delete <card_id>` | Deletes the card with FK cascade over members/comments/checklists+items/attachments. No undo. |
| `member-add '<json>'` | Teachflow: `{card_id, user_id}`. Horizon: `{cardId, userId}`. |
| `member-remove <member_id>` | Remove a member by the membership row id from `get`, **not** the user's `user_id`. |
| `comment '<json>'` | Teachflow: `{card_id, content}`. Horizon: `{cardId, content}`. |
| `checklist-add` / `checklist-update` / `checklist-delete` | Teachflow `{card_id, title}` / `{title?, order_index?}` / by id. Horizon `{cardId, title}` / `{title?, orderIndex?}` / by id. |
| `item-add` / `item-update` / `item-delete` | Teachflow `{checklist_id, title}` / `{title?, is_completed?, order_index?}` / by id. Horizon `{checklistId, title}` / `{title?, isCompleted?, orderIndex?}` / by id. |
| `profiles [query]` | Teachflow approved profiles. In Horizon, alias for `users`. |
| `users [query]` | Horizon internal users. In Teachflow, alias for `profiles`. |

Board columns (`status`, in kanban order): `backlog`, `priorizados`, `em_andamento`, `em_aprovacao`, `reprovados`, `aprovados`, `bloqueados`, `concluidos`.
`criticality`: `baixa` | `media` (default) | `alta`.

Optional readability with `jq`:

```bash
bash .claude/skills/teachflow-board/scripts/tb.sh list | jq '.cards[] | {id, title, status}'
```

## Target differences

Teachflow:

- Auth is better-auth cookie via `/api/auth/sign-in/email`.
- Board endpoints are under `/api/admin/team-board-*`.
- JSON write payloads are snake_case.
- `teachflow-backend#219` (`cbfcfed`) + `teachflow-grid#216` (`d498a77`) added member removal and card deletion; do not fall back to raw SQL against the mirror DB.

Horizon CRM:

- Auth is JWT via `/api/v1/auth/login`.
- Board endpoints are under `/api/v1/team-board/*`.
- JSON write payloads are camelCase.
- The board currently exists in the local/development Horizon CRM implementation unless a verified deploy target is explicitly supplied through `HORIZON_CRM_API_URL`.
- Attachment metadata endpoints exist, but real file upload/storage is not implemented yet.

## Reconciling with `work/`

When the user wants to close the gap between actual work and a board:

1. Pick the target first:
   - Teachflow/CodeUp work → `TEAM_BOARD_TARGET=teachflow`.
   - Horizon CRM work → `TEAM_BOARD_TARGET=horizon`.
2. `list` the board, filter to columns that aren't `concluidos`/`aprovados`.
3. Compare titles/content against the matching operational task files:
   - Teachflow: `work/_tasks.md` (`## Teachflow (CRM)` section) and `work/projects/codeup/teachflow/_tasks.md`.
   - Horizon CRM: `work/projects/horizonconsultoria/horizon-crm/_tasks.md` and, when needed, the master `work/_tasks.md` Horizon section.
4. Report concretely: cards with no matching task, tasks with no matching card, and cards whose column looks stale versus the task's real state.
5. Propose the specific `update`/`create` calls rather than doing them silently when the write affects a shared board other people see.

## Safety

- Board writes (`create`/`update`/comments/`member-add`/`member-remove`) are visible immediately in the selected system. Confirm intent before writing to any shared production board, especially for status moves into `aprovados`/`concluidos` or anything that reads as "done."
- `delete` is irreversible and cascades (members, comments, checklists+items, attachments) — always confirm with the user before calling it, never use it just to "clean up" test cards without asking.
- For Horizon CRM, default to local `http://localhost:5029`; do not point the skill at production unless the user explicitly asks and the API/deploy has been verified.
