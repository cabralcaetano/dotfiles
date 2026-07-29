#!/usr/bin/env bash
# Thin client for the Teachflow "Team Board" (Quadro de Atividades) admin API.
# Auth: better-auth email/password login, session cookie cached to disk and reused.
set -euo pipefail

API_URL="${TEACHFLOW_API_URL:-https://api-crm.codeup.dev.br}"
COOKIE_JAR="${TEACHFLOW_COOKIE_JAR:-$HOME/.cache/teachflow-board/cookies.txt}"
mkdir -p "$(dirname "$COOKIE_JAR")"
chmod 700 "$(dirname "$COOKIE_JAR")" 2>/dev/null || true

login() {
  if [[ -z "${TEACHFLOW_ADMIN_EMAIL:-}" || -z "${TEACHFLOW_ADMIN_PASSWORD:-}" ]]; then
    echo "Erro: defina TEACHFLOW_ADMIN_EMAIL e TEACHFLOW_ADMIN_PASSWORD no ambiente antes de usar tb.sh." >&2
    exit 1
  fi
  local status
  status=$(curl -sS -c "$COOKIE_JAR" -o /dev/null -w '%{http_code}' \
    -X POST "$API_URL/api/auth/sign-in/email" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$TEACHFLOW_ADMIN_EMAIL\",\"password\":\"$TEACHFLOW_ADMIN_PASSWORD\"}")
  chmod 600 "$COOKIE_JAR" 2>/dev/null || true
  if [[ "$status" != "200" ]]; then
    echo "Erro: login falhou (HTTP $status)." >&2
    exit 1
  fi
}

# req METHOD PATH [JSON_BODY]
# Prints response body on stdout. Retries once after a fresh login on 401.
req() {
  local method="$1" path="$2" body="${3:-}"
  [[ -s "$COOKIE_JAR" ]] || login

  _do() {
    local args=(-sS -b "$COOKIE_JAR" -c "$COOKIE_JAR" -X "$method" "$API_URL$path" -H 'Content-Type: application/json')
    [[ -n "$body" ]] && args+=(-d "$body")
    curl "${args[@]}" -w '\n%{http_code}'
  }

  local out status resp
  out=$(_do)
  status=$(tail -n1 <<<"$out")
  resp=$(sed '$d' <<<"$out")

  if [[ "$status" == "401" ]]; then
    login
    out=$(_do)
    status=$(tail -n1 <<<"$out")
    resp=$(sed '$d' <<<"$out")
  fi

  printf '%s\n' "$resp"
  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "HTTP $status — $path" >&2
    return 1
  fi
}

usage() {
  cat >&2 <<'EOF'
uso: tb.sh <comando> [args]

  login                                   força novo login e recria o cookie
  list [query_string]                     lista cards do board (bundle); filtra com "status=em_andamento&limit=10&offset=0"
  get <card_id>                           detalhe de um card (members/comments/checklists/attachments)
  create '<json>'                         cria card — {title, description?, criticality?, due_date?, status?, member_user_ids?}
  update <card_id> '<json>'               PATCH de um card — {title?, description?, status?, criticality?, due_date?, order_index?}
  delete <card_id>                        apaga o card (admin only; cascade de membros/comentários/checklists/anexos)
  member-add '<json>'                     {card_id, user_id} — adiciona membro aprovado a um card existente
  member-remove <member_id>               remove membro pelo id da linha em team_board_card_members (não é o user_id — pegue via `get`)
  comment '<json>'                        {card_id, content}
  checklist-add '<json>'                  {card_id, title}
  checklist-update <checklist_id> '<json>' {title?, order_index?}
  checklist-delete <checklist_id>
  item-add '<json>'                       {checklist_id, title}
  item-update <item_id> '<json>'          {title?, is_completed?, order_index?}
  item-delete <item_id>
  profiles [query_string]                  lista usuários p/ resolver nome -> user_id (ex: "positions=admin")

status válidos (ActivityBoard.tsx, colunas do kanban, nessa ordem):
  backlog, priorizados, em_andamento, em_aprovacao, reprovados, aprovados, bloqueados, concluidos
criticality: baixa, media, alta (default: media)
EOF
  exit 1
}

[[ $# -ge 1 ]] || usage
cmd="$1"; shift || true

case "$cmd" in
  login) login; echo "ok" ;;
  list) req GET "/api/admin/team-board-cards-bundle${1:+?$1}" ;;
  get) [[ $# -ge 1 ]] || usage; req GET "/api/admin/team-board-cards/$1/bundle" ;;
  create) [[ $# -ge 1 ]] || usage; req POST /api/admin/team-board-cards "$1" ;;
  update) [[ $# -ge 2 ]] || usage; req PATCH "/api/admin/team-board-cards/$1" "$2" ;;
  delete) [[ $# -ge 1 ]] || usage; req DELETE "/api/admin/team-board-cards/$1" ;;
  member-add) [[ $# -ge 1 ]] || usage; req POST /api/admin/team-board-card-members "$1" ;;
  member-remove) [[ $# -ge 1 ]] || usage; req DELETE "/api/admin/team-board-card-members/$1" ;;
  comment) [[ $# -ge 1 ]] || usage; req POST /api/admin/team-board-card-comments "$1" ;;
  checklist-add) [[ $# -ge 1 ]] || usage; req POST /api/admin/team-board-card-checklists "$1" ;;
  checklist-update) [[ $# -ge 2 ]] || usage; req PATCH "/api/admin/team-board-card-checklists/$1" "$2" ;;
  checklist-delete) [[ $# -ge 1 ]] || usage; req DELETE "/api/admin/team-board-card-checklists/$1" ;;
  item-add) [[ $# -ge 1 ]] || usage; req POST /api/admin/team-board-card-checklist-items "$1" ;;
  item-update) [[ $# -ge 2 ]] || usage; req PATCH "/api/admin/team-board-card-checklist-items/$1" "$2" ;;
  item-delete) [[ $# -ge 1 ]] || usage; req DELETE "/api/admin/team-board-card-checklist-items/$1" ;;
  profiles) req GET "/api/admin/profiles${1:+?$1}" ;;
  *) usage ;;
esac
