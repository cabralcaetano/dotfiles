#!/usr/bin/env bash
# backup-restic.sh — backup incremental e criptografado de $HOME para o VPS.
#
# Por que existe: snapshot Btrfs NÃO é backup. O filesystem raiz é um btrfs de
# DOIS dispositivos (nvme0n1p4 + nvme0n1p8) com perfil `Data, single` — perder
# qualquer uma das duas partições perde o filesystem inteiro, e os snapshots do
# Snapper junto. Esta é a única cópia que sobrevive a isso.
#
# Destino: repositório restic no VPS, via SFTP sobre SSH. O restic cifra tudo
# no cliente (AES-256 + Poly1305), então o servidor nunca vê conteúdo em claro;
# não é preciso ter restic instalado lá, só sftp-server.
#
# Config obrigatória, fora do Git (contém segredo):
#   ~/.config/restic/config    -> RESTIC_REPOSITORY=sftp:<host>:<caminho>
#   ~/.config/restic/password  -> senha do repositório, chmod 600
#
# Primeira vez:  backup-restic.sh init
# Uso do timer:  backup-restic.sh backup
# Restore:       backup-restic.sh mount   (navega os snapshots em ~/mnt/restic)
# Outros:        snapshots | check | stats | unlock | forget-dry
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/restic"
CONFIG_FILE="$CONFIG_DIR/config"
PASSWORD_FILE="$CONFIG_DIR/password"
EXCLUDE_FILE="$HOME/.local/share/restic/excludes.txt"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/restic"
LOG="$STATE_DIR/backup.log"
STAMP="$STATE_DIR/last-success"

# Avisa quando o último backup bem-sucedido passar disso (em dias).
STALE_DAYS="${BACKUP_STALE_DAYS:-3}"

mkdir -p "$STATE_DIR" "$CONFIG_DIR"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG" >&2; }

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name=backup "${2:-Backup}" "$1"
}

die() {
    log "ERRO: $*"
    notify "$*" "Backup falhou"
    exit 1
}

# `backup` é o modo do timer: falta de configuração, de rede ou do servidor
# vira aviso, não unit em estado failed. Os modos manuais exigem tudo pronto e
# morrem com mensagem precisa.
configured() {
    [ -f "$CONFIG_FILE" ] && [ -f "$PASSWORD_FILE" ] || return 1
    # shellcheck source=/dev/null
    . "$CONFIG_FILE"
    [ -n "${RESTIC_REPOSITORY:-}" ] || return 1
    [ "$(stat -c '%a' "$PASSWORD_FILE")" = "600" ] || return 1
}

require_config() {
    command -v restic >/dev/null 2>&1 || die "restic não instalado (sudo pacman -S restic)"
    [ -f "$CONFIG_FILE" ] || die "falta $CONFIG_FILE com RESTIC_REPOSITORY=sftp:host:/caminho"
    [ -f "$PASSWORD_FILE" ] || die "falta $PASSWORD_FILE com a senha do repositório"
    # shellcheck source=/dev/null
    . "$CONFIG_FILE"
    [ -n "${RESTIC_REPOSITORY:-}" ] || die "RESTIC_REPOSITORY não definido em $CONFIG_FILE"
    local perm
    perm="$(stat -c '%a' "$PASSWORD_FILE")"
    [ "$perm" = "600" ] || die "$PASSWORD_FILE está $perm; corrija com chmod 600"
    export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
}

# Extrai o host do RESTIC_REPOSITORY (sftp:HOST:/caminho) e testa o SSH antes
# de deixar o restic pendurar num timeout longo.
server_reachable() {
    local host="${RESTIC_REPOSITORY#sftp:}"
    host="${host%%:*}"
    [ -n "$host" ] || return 1
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" true 2>/dev/null
}

warn_if_stale() {
    local age_days
    if [ ! -f "$STAMP" ]; then
        notify "Nenhum backup concluído até agora." "Backup pendente"
        return
    fi
    age_days=$(( ( $(date +%s) - $(stat -c %Y "$STAMP") ) / 86400 ))
    if [ "$age_days" -ge "$STALE_DAYS" ]; then
        notify "Último backup há $age_days dias." "Backup atrasado"
    fi
}

case "${1:-backup}" in
init)
    require_config
    server_reachable || die "servidor de backup inacessível"
    restic init
    log "repositório criado em $RESTIC_REPOSITORY"
    ;;

backup)
    if ! command -v restic >/dev/null 2>&1; then
        log "restic não instalado; nada a fazer"
        warn_if_stale
        exit 0
    fi
    if ! configured; then
        log "restic ainda não configurado ($CONFIG_FILE); nada a fazer"
        warn_if_stale
        exit 0
    fi
    export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE="$PASSWORD_FILE"
    if ! server_reachable; then
        log "servidor de backup inacessível; nada a fazer"
        warn_if_stale
        exit 0
    fi
    [ -f "$EXCLUDE_FILE" ] || die "falta $EXCLUDE_FILE"

    log "iniciando backup para $RESTIC_REPOSITORY"
    if restic backup "$HOME" \
        --exclude-file="$EXCLUDE_FILE" \
        --exclude-caches \
        --one-file-system \
        --compression auto \
        --tag auto \
        >>"$LOG" 2>&1
    then
        touch "$STAMP"
        log "backup concluído"
    else
        die "restic backup falhou; veja $LOG"
    fi

    # Retenção: 7 diários, 4 semanais, 6 mensais, 1 anual.
    restic forget --prune \
        --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1 \
        >>"$LOG" 2>&1 || log "aviso: forget/prune falhou"
    ;;

forget-dry)
    require_config
    restic forget --dry-run \
        --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1
    ;;

snapshots|check|unlock|stats)
    require_config
    server_reachable || die "servidor de backup inacessível"
    restic "$1" "${@:2}"
    ;;

mount)
    require_config
    server_reachable || die "servidor de backup inacessível"
    mkdir -p "$HOME/mnt/restic"
    echo "Ctrl+C desmonta. Snapshots navegáveis em ~/mnt/restic"
    restic mount "$HOME/mnt/restic"
    ;;

*)
    echo "Uso: ${0##*/} {init|backup|snapshots|check|stats|forget-dry|unlock|mount}" >&2
    exit 1
    ;;
esac
