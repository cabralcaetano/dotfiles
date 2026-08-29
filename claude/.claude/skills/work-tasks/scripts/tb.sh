#!/usr/bin/env bash
# Thin client for the Horizon CRM Activity Board API.
# Legacy Teachflow support exists in code only; this skill defaults to Horizon and blocks
# Teachflow unless TEAM_BOARD_ALLOW_TEACHFLOW=1 is set explicitly.
set -euo pipefail

# Permanent credential resolution: if the caller's shell doesn't already export
# HORIZON_CRM_EMAIL/PASSWORD (or HORIZON_CRM_ACCESS_TOKEN), load them from an external
# 0600/0400 file outside the vault/repo. Same convention as HORIZON_OPS_SECRETS_FILE used
# by deploy/ops/lib/horizon-ops.sh — secrets never live in the vault, repo, or chat.
# Explicit env vars already set in the calling shell always win over the file.
HORIZON_CRM_SECRETS_FILE="${HORIZON_CRM_SECRETS_FILE:-$HOME/.config/horizon-crm/board.env}"
if [[ -z "${HORIZON_CRM_ACCESS_TOKEN:-}" && ( -z "${HORIZON_CRM_EMAIL:-}" || -z "${HORIZON_CRM_PASSWORD:-}" ) ]]; then
  if [[ -f "$HORIZON_CRM_SECRETS_FILE" ]]; then
    perm=$(stat -c '%a' "$HORIZON_CRM_SECRETS_FILE" 2>/dev/null || stat -f '%Lp' "$HORIZON_CRM_SECRETS_FILE" 2>/dev/null || echo '')
    if [[ -n "$perm" && "$perm" != "600" && "$perm" != "400" ]]; then
      echo "Erro: $HORIZON_CRM_SECRETS_FILE deve ter permissão 0600 ou 0400 (atual: $perm). Rode: chmod 600 '$HORIZON_CRM_SECRETS_FILE'" >&2
      exit 1
    fi
    set -a
    # shellcheck disable=SC1090
    source "$HORIZON_CRM_SECRETS_FILE"
    set +a
  fi
fi

BOARD_TARGET="${TEAM_BOARD_TARGET:-horizon}" # horizon | teachflow (legacy, guarded)

case "$BOARD_TARGET" in
  teachflow)
    API_URL="${TEACHFLOW_API_URL:-https://api-crm.codeup.dev.br}"
    SESSION_FILE="${TEACHFLOW_COOKIE_JAR:-$HOME/.cache/teachflow-board/cookies.txt}"
    mkdir -p "$(dirname "$SESSION_FILE")"
    chmod 700 "$(dirname "$SESSION_FILE")" 2>/dev/null || true
    ;;
  horizon)
    API_URL="${HORIZON_CRM_API_URL:-https://api-crm.consultoriahorizon.com.br}"
    SESSION_FILE="${HORIZON_CRM_TOKEN_FILE:-$HOME/.cache/horizon-crm-board/token.json}"
    mkdir -p "$(dirname "$SESSION_FILE")"
    chmod 700 "$(dirname "$SESSION_FILE")" 2>/dev/null || true
    ;;
  *)
    echo "Erro: TEAM_BOARD_TARGET deve ser 'teachflow' ou 'horizon'." >&2
    exit 1
    ;;
esac

if [[ "$BOARD_TARGET" == "teachflow" && "${TEAM_BOARD_ALLOW_TEACHFLOW:-}" != "1" ]]; then
  echo "Erro: esta skill agora é Horizon CRM only. Para uso legado Teachflow, defina TEAM_BOARD_ALLOW_TEACHFLOW=1 explicitamente." >&2
  exit 1
fi

login_teachflow() {
  if [[ -z "${TEACHFLOW_ADMIN_EMAIL:-}" || -z "${TEACHFLOW_ADMIN_PASSWORD:-}" ]]; then
    echo "Erro: defina TEACHFLOW_ADMIN_EMAIL e TEACHFLOW_ADMIN_PASSWORD no ambiente antes de usar tb.sh com TEAM_BOARD_TARGET=teachflow." >&2
    exit 1
  fi
  local status
  status=$(curl -sS -c "$SESSION_FILE" -o /dev/null -w '%{http_code}' \
    -X POST "$API_URL/api/auth/sign-in/email" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$TEACHFLOW_ADMIN_EMAIL\",\"password\":\"$TEACHFLOW_ADMIN_PASSWORD\"}")
  chmod 600 "$SESSION_FILE" 2>/dev/null || true
  if [[ "$status" != "200" ]]; then
    echo "Erro: login Teachflow falhou (HTTP $status)." >&2
    exit 1
  fi
}

login_horizon() {
  if [[ -z "${HORIZON_CRM_EMAIL:-}" || -z "${HORIZON_CRM_PASSWORD:-}" ]]; then
    echo "Erro: defina HORIZON_CRM_EMAIL e HORIZON_CRM_PASSWORD no ambiente antes de usar tb.sh com TEAM_BOARD_TARGET=horizon." >&2
    exit 1
  fi
  local tmp status
  tmp=$(mktemp)
  status=$(curl -sS -o "$tmp" -w '%{http_code}' \
    -X POST "$API_URL/api/v1/auth/login" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$HORIZON_CRM_EMAIL\",\"password\":\"$HORIZON_CRM_PASSWORD\"}")
  if [[ "$status" != "200" ]]; then
    rm -f "$tmp"
    echo "Erro: login Horizon CRM falhou (HTTP $status)." >&2
    exit 1
  fi
  mv "$tmp" "$SESSION_FILE"
  chmod 600 "$SESSION_FILE" 2>/dev/null || true
}

login() {
  case "$BOARD_TARGET" in
    teachflow) login_teachflow ;;
    horizon) login_horizon ;;
  esac
}

horizon_access_token() {
  if [[ -n "${HORIZON_CRM_ACCESS_TOKEN:-}" ]]; then
    printf '%s\n' "$HORIZON_CRM_ACCESS_TOKEN"
    return
  fi
  [[ -s "$SESSION_FILE" ]] || login_horizon
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["accessToken"])' "$SESSION_FILE"
}

# req METHOD PATH [JSON_BODY]
# Prints response body on stdout. Retries once after a fresh login on 401.
req_teachflow() {
  local method="$1" path="$2" body="${3:-}"
  [[ -s "$SESSION_FILE" ]] || login_teachflow

  _do() {
    local args=(-sS -b "$SESSION_FILE" -c "$SESSION_FILE" -X "$method" "$API_URL$path" -H 'Content-Type: application/json')
    [[ -n "$body" ]] && args+=(-d "$body")
    curl "${args[@]}" -w '\n%{http_code}'
  }

  local out status resp
  out=$(_do)
  status=$(tail -n1 <<<"$out")
  resp=$(sed '$d' <<<"$out")

  if [[ "$status" == "401" ]]; then
    login_teachflow
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

req_horizon() {
  local method="$1" path="$2" body="${3:-}"

  _do() {
    local token
    token=$(horizon_access_token)
    local args=(-sS -X "$method" "$API_URL$path" -H 'Content-Type: application/json' -H "Authorization: Bearer $token")
    [[ -n "$body" ]] && args+=(-d "$body")
    curl "${args[@]}" -w '\n%{http_code}'
  }

  local out status resp
  out=$(_do)
  status=$(tail -n1 <<<"$out")
  resp=$(sed '$d' <<<"$out")

  if [[ "$status" == "401" ]]; then
    rm -f "$SESSION_FILE"
    login_horizon
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

req() {
  case "$BOARD_TARGET" in
    teachflow) req_teachflow "$@" ;;
    horizon) req_horizon "$@" ;;
  esac
}

usage() {
  cat >&2 <<'EOF'
uso: tb.sh <comando> [args]

  TEAM_BOARD_TARGET=horizon    usa o Activity Board do Horizon CRM (default)
  TEAM_BOARD_TARGET=teachflow  legado Teachflow/CodeUp; bloqueado sem TEAM_BOARD_ALLOW_TEACHFLOW=1


  login                                   força novo login e recria cookie/token
  spaces                                  Horizon: lista espaços de cliente para resolver clientSpaceId
  list [query_string]                     lista cards do board; filtra com "status=em_andamento&limit=10&offset=0"
  get <card_id>                           detalhe de um card (members/comments/checklists/attachments)
  create '<json>'                         cria card
  update <card_id> '<json>'               PATCH de um card; mover coluna = {"status":"em_andamento"}
  delete <card_id>                        apaga o card (cascade de membros/comentários/checklists/anexos)
  member-add '<json>'                     adiciona membro a um card existente
  member-remove <member_id>               remove membro pelo id da linha de membership (não é o user_id — pegue via `get`)
  comment '<json>'                        cria comentário
  checklist-add '<json>'                  cria checklist
  checklist-update <checklist_id> '<json>' atualiza checklist
  checklist-delete <checklist_id>
  item-add '<json>'                       cria item de checklist
  item-update <item_id> '<json>'          atualiza item de checklist
  item-delete <item_id>
  profiles [query_string]                 Teachflow: perfis aprovados; Horizon: alias de users
  users [query_string]                    Horizon: usuários internos; Teachflow: alias de profiles

JSON Horizon CRM usa camelCase:
  create {"title":"...","description":"...","criticality":"media","status":"backlog","clientSpaceId":"...","memberUserIds":["..."]}
  member-add {"cardId":"...","userId":"..."}
  checklist-add {"cardId":"...","title":"..."}
  item-add {"checklistId":"...","title":"..."}

JSON Teachflow legado usa snake_case e só deve ser usado fora desta skill, com TEAM_BOARD_ALLOW_TEACHFLOW=1:
  create {"title":"...","description":"...","criticality":"media","status":"backlog","member_user_ids":["..."]}
  member-add {"card_id":"...","user_id":"..."}
  checklist-add {"card_id":"...","title":"..."}
  item-add {"checklist_id":"...","title":"..."}

status válidos (colunas do kanban, nessa ordem):
  backlog, priorizados, em_andamento, em_aprovacao, reprovados, aprovados, bloqueados, concluidos
criticality: baixa, media, alta (default: media)
EOF
  exit 1
}

[[ $# -ge 1 ]] || usage
cmd="$1"; shift || true

case "$cmd" in
  login) login; echo "ok" ;;
  spaces)
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      echo "Erro: spaces existe apenas no Horizon CRM." >&2
      exit 1
    else
      req GET "/api/v1/client-spaces/"
    fi
    ;;
  list)
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req GET "/api/admin/team-board-cards-bundle${1:+?$1}"
    else
      req GET "/api/v1/team-board/cards${1:+?$1}"
    fi
    ;;
  get)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req GET "/api/admin/team-board-cards/$1/bundle"
    else
      req GET "/api/v1/team-board/cards/$1/bundle"
    fi
    ;;
  create)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req POST /api/admin/team-board-cards "$1"
    else
      req POST /api/v1/team-board/cards "$1"
    fi
    ;;
  update)
    [[ $# -ge 2 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req PATCH "/api/admin/team-board-cards/$1" "$2"
    else
      req PATCH "/api/v1/team-board/cards/$1" "$2"
    fi
    ;;
  delete)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req DELETE "/api/admin/team-board-cards/$1"
    else
      req DELETE "/api/v1/team-board/cards/$1"
    fi
    ;;
  member-add)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req POST /api/admin/team-board-card-members "$1"
    else
      req POST /api/v1/team-board/card-members "$1"
    fi
    ;;
  member-remove)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req DELETE "/api/admin/team-board-card-members/$1"
    else
      req DELETE "/api/v1/team-board/card-members/$1"
    fi
    ;;
  comment)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req POST /api/admin/team-board-card-comments "$1"
    else
      req POST /api/v1/team-board/card-comments "$1"
    fi
    ;;
  checklist-add)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req POST /api/admin/team-board-card-checklists "$1"
    else
      req POST /api/v1/team-board/card-checklists "$1"
    fi
    ;;
  checklist-update)
    [[ $# -ge 2 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req PATCH "/api/admin/team-board-card-checklists/$1" "$2"
    else
      req PATCH "/api/v1/team-board/card-checklists/$1" "$2"
    fi
    ;;
  checklist-delete)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req DELETE "/api/admin/team-board-card-checklists/$1"
    else
      req DELETE "/api/v1/team-board/card-checklists/$1"
    fi
    ;;
  item-add)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req POST /api/admin/team-board-card-checklist-items "$1"
    else
      req POST /api/v1/team-board/card-checklist-items "$1"
    fi
    ;;
  item-update)
    [[ $# -ge 2 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req PATCH "/api/admin/team-board-card-checklist-items/$1" "$2"
    else
      req PATCH "/api/v1/team-board/card-checklist-items/$1" "$2"
    fi
    ;;
  item-delete)
    [[ $# -ge 1 ]] || usage
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req DELETE "/api/admin/team-board-card-checklist-items/$1"
    else
      req DELETE "/api/v1/team-board/card-checklist-items/$1"
    fi
    ;;
  profiles)
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req GET "/api/admin/profiles${1:+?$1}"
    else
      req GET "/api/v1/team-board/users"
    fi
    ;;
  users)
    if [[ "$BOARD_TARGET" == "teachflow" ]]; then
      req GET "/api/admin/profiles${1:+?$1}"
    else
      req GET "/api/v1/team-board/users"
    fi
    ;;
  *) usage ;;
esac
