#!/usr/bin/env bash
set -uo pipefail

notify() {
    notify-send \
      -h string:x-canonical-private-synchronous:bt-codec \
      -i audio-headset-bluetooth \
      -t "${2:-1500}" \
      "Fone Bluetooth" "$1"
}

CARD=$(pactl list cards short | awk '/bluez_card/ {print $2; exit}')

if [ -z "$CARD" ]; then
    notify "Nenhum fone Bluetooth conectado" 2000
    exit 0
fi

# Bloco do card: nome ativo + perfis disponíveis
CARD_BLOCK=$(pactl list cards | awk -v card="$CARD" '
  $0 ~ "Name: " card {found=1}
  found && /^\tName: / && $0 !~ "Name: " card {exit}
  found {print}
')

CURRENT=$(printf '%s\n' "$CARD_BLOCK" | awk '/Active Profile:/ {print $3; exit}')
PROFILES=$(printf '%s\n' "$CARD_BLOCK" | awk '/available: yes/ {gsub(/:$/, "", $1); print $1}')

has_profile() { printf '%s\n' "$PROFILES" | grep -qx "$1"; }

if [[ "$CURRENT" == a2dp-sink* ]]; then
    TARGET=$(printf '%s\n' "$PROFILES" | grep -m1 '^headset-head-unit$' || true)
    LABEL="mSBC (chamada/mic)"
else
    TARGET=$(printf '%s\n' "$PROFILES" | grep -m1 '^a2dp-sink' || true)
    LABEL="LDAC (alta-fidelidade)"
fi

if [ -z "$TARGET" ]; then
    # A2DP some quando algum app segura o microfone (HFP forçado)
    APP=$(pactl list source-outputs | awk -F'"' '/application.process.binary/ {print $2; exit}')
    if [ -n "$APP" ]; then
        notify "A2DP indisponível — $APP está usando o microfone" 3000
    else
        notify "Perfil alvo indisponível neste fone" 3000
    fi
    exit 1
fi

if ! ERR=$(pactl set-card-profile "$CARD" "$TARGET" 2>&1); then
    notify "Falha ao trocar perfil: $ERR" 3000
    exit 1
fi

notify "$LABEL"
