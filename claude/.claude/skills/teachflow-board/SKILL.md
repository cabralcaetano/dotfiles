---
name: teachflow-board
description: Create, edit, move, and assign cards on the Teachflow internal "Team Board" (Quadro de Atividades — the CodeUp team's own kanban, distinct from the CRM leads kanban). Use when the user wants to reconcile real work with what's tracked there, open/update/move a card between columns, check who a card is assigned to, or add comments/checklists to a card. Also use to spot discrepancies between `work/_tasks.md` / `work/projects/codeup/teachflow/_tasks.md` and the live board.
---

# Teachflow Team Board

Wraps the Teachflow backend's admin API for `team_board_cards` (the internal "Quadro de Atividades" at `/team` → Activity Board in `teachflow-grid`, backed by `teachflow-backend`). This is **not** the CRM/leads kanban (`whatsapp_conversations.crm_status`) — do not confuse the two.

Full project context: `work/projects/codeup/teachflow/_teachflow.md`.

## Setup (one time, per shell)

The user authenticates with their own admin credentials via better-auth email/password login. Export before use:

```bash
export TEACHFLOW_ADMIN_EMAIL="..."
export TEACHFLOW_ADMIN_PASSWORD="..."
```

Never write these to a file in this repo or echo the password back. If they're missing, ask the user to export them in the current shell (or via `! export ...`) rather than typing the password into chat.

Default API base is prod (`https://api-crm.codeup.dev.br`). Override with `TEACHFLOW_API_URL` for preprod (`https://api-crm-preprod.codeup.dev.br`) when the user says so explicitly — default to prod otherwise, since that's where the real team board lives.

The session cookie is cached at `~/.cache/teachflow-board/cookies.txt` (0600) and reused across calls; the script re-logs-in once on a 401.

## Tool

`.claude/skills/teachflow-board/scripts/tb.sh <command> [args]` — thin curl+jq-free client, JSON in/out. Run `bash .claude/skills/teachflow-board/scripts/tb.sh` with no args for the full command list. Key ones:

| Command | Purpose |
|---|---|
| `list [query_string]` | All cards + members + profiles in one call — use this to see current board state. Now paginated: pass `"status=em_andamento&limit=10&offset=0"` to page through one column (default 10 per column when filtered by status, max 100) |
| `get <card_id>` | Full card detail: members, comments, checklists+items, attachments |
| `create '<json>'` | New card: `{title, description?, criticality?, due_date?, status?, member_user_ids?}` |
| `update <card_id> '<json>'` | Edit or **move column** (that's just `{"status": "..."}`): `{title?, description?, status?, criticality?, due_date?, order_index?}` |
| `delete <card_id>` | Deletes the card — admin-only (`canAdmin(actor)`), FK cascade removes members/comments/checklists+items/attachments. No undo. |
| `member-add '<json>'` | `{card_id, user_id}` — add an approved user to an existing card |
| `member-remove <member_id>` | Remove a member by the membership row id (from `get`'s member list, **not** the user's `user_id`) |
| `comment '<json>'` | `{card_id, content}` |
| `checklist-add` / `checklist-update` / `checklist-delete` | `{card_id, title}` / `{title?, order_index?}` / by id |
| `item-add` / `item-update` / `item-delete` | `{checklist_id, title}` / `{title?, is_completed?, order_index?}` / by id |
| `profiles [query]` | Resolve a person's name to `user_id` before assigning, e.g. `profiles "positions=admin"` |

Board columns (`status`, in kanban order): `backlog`, `priorizados`, `em_andamento`, `em_aprovacao`, `reprovados`, `aprovados`, `bloqueados`, `concluidos`.
`criticality`: `baixa` | `media` (default) | `alta`.

Pipe output through `jq` for readability, e.g.:

```bash
bash .claude/skills/teachflow-board/scripts/tb.sh list | jq '.cards[] | {id, title, status}'
```

## Reassigning members and deleting cards (as of 2026-07-29)

`teachflow-backend#219` (`cbfcfed`) + `teachflow-grid#216` (`d498a77`) closed the old gap: it's no longer true that members are create-only or that cards can't be deleted.

- `member-add` / `member-remove` now exist (`POST`/`DELETE /api/admin/team-board-card-members`) for approved users; the card's `updated_at` is touched on change. The frontend `ActivityCardDialog` exposes the same via an approved-member selector and a remove button, but only after clicking **Editar** — add/remove/attach/checklist/delete actions are hidden until then.
- `delete` now exists (`DELETE /api/admin/team-board-cards/:id`), admin-only, with FK cascade over members/comments/checklists+items/attachments. The UI's **Apagar** button is small, bottom-right of the dialog, admin+edit-mode only, and confirms via `window.confirm`.
- Still never fall back to raw SQL against the mirror DB for any of this — the API's actor/audit path is the only sanctioned write path now that it fully covers members and delete.

## Reconciling with `work/`

When the user wants to close the gap between what they're actually doing and what the board shows:

1. `list` the board, filter to columns that aren't `concluidos`/`aprovados`.
2. Compare titles/content against open items in `work/_tasks.md` (`## Teachflow (CRM)` section) and `work/projects/codeup/teachflow/_tasks.md`.
3. Report concretely: cards with no matching task, tasks with no matching card, and cards whose column looks stale versus the task's real `[~]`/`[x]` state — then propose the specific `update`/`create` calls rather than doing them silently, since this changes a shared team board other people see.
4. Do not auto-apply — this workflow's writes are visible to the whole team; confirm before creating/moving/closing cards, same bar as any other shared-system action.

## Safety

- Card `create`/`update`/comments/`member-add`/`member-remove` are visible to the whole Teachflow team immediately — confirm intent before writing, same as any shared-system action (per the global operating rules), especially for status moves into `aprovados`/`concluidos` or anything that reads as "done."
- `delete` is irreversible and cascades (members, comments, checklists+items, attachments) — always confirm with the user before calling it, never use it just to "clean up" test cards without asking (that's exactly how the two 2026-07-29 test cards should have been handled instead of parking them in `concluidos`).
