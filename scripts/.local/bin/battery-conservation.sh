#!/usr/bin/env bash
set -uo pipefail

CHARGE_TYPES_PATH="/sys/class/power_supply/BAT0/charge_types"
MODE_PATH="/sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/conservation_mode"
SERVICE="battery-conservation.service"
ROOT_HELPER="/usr/local/sbin/battery-conservation-root"
TITLE="Conservação da bateria"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$TITLE" "$1"
    fi
}

fail() {
    notify "$1"
    echo "$1" >&2
    exit 1
}

require_control_path() {
    [ -e "$CHARGE_TYPES_PATH" ] || [ -e "$MODE_PATH" ] || fail "Nenhum controle de conservação encontrado neste notebook"
}

current_mode() {
    require_control_path

    if [ -e "$CHARGE_TYPES_PATH" ]; then
        case "$(cat "$CHARGE_TYPES_PATH")" in
            *"[Long_Life]"*) echo "conservation" ;;
            *"[Standard]"*)  echo "full" ;;
            *)               echo "unknown" ;;
        esac
        return
    fi

    case "$(cat "$MODE_PATH")" in
        1) echo "conservation" ;;
        0) echo "full" ;;
        *) echo "unknown" ;;
    esac
}

service_available() {
    systemctl list-unit-files "$SERVICE" --no-legend >/dev/null 2>&1
}

run_root() {
    local askpass="$HOME/.local/bin/sudo-askpass-fuzzel.sh"

    if command -v sudo >/dev/null 2>&1 && [ -x "$askpass" ] && command -v fuzzel >/dev/null 2>&1; then
        SUDO_ASKPASS="$askpass" sudo -A "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail "sudo/pkexec não encontrado para alterar o modo"
    fi
}

run_root_helper() {
    [ -x "$ROOT_HELPER" ] || return 1
    sudo -n "$ROOT_HELPER" "$1"
}

write_mode_direct() {
    case "$1" in
        1)
            if [ -e "$CHARGE_TYPES_PATH" ]; then
                run_root /bin/sh -c "printf 'Long_Life' > '$CHARGE_TYPES_PATH'"
            else
                run_root /bin/sh -c "printf '1' > '$MODE_PATH'"
            fi
            ;;
        0)
            if [ -e "$CHARGE_TYPES_PATH" ]; then
                run_root /bin/sh -c "printf 'Standard' > '$CHARGE_TYPES_PATH'"
            else
                run_root /bin/sh -c "printf '0' > '$MODE_PATH'"
            fi
            ;;
        *)
            fail "Modo inválido"
            ;;
    esac
}

enable_conservation() {
    if service_available; then
        if run_root_helper enable; then
            notify "Modo conservação ativado"
            return
        fi

        run_root systemctl enable --now "$SERVICE" || fail "Falha ao ativar o service de conservação"
        notify "Modo conservação ativado"
    else
        if run_root_helper enable; then
            notify "Modo conservação ativado até o próximo boot"
            return
        fi

        write_mode_direct 1 || fail "Falha ao ativar conservação"
        notify "Modo conservação ativado até o próximo boot"
    fi
}

disable_conservation() {
    if service_available; then
        if run_root_helper disable; then
            notify "Carregamento até 100% liberado"
            return
        fi

        run_root systemctl disable --now "$SERVICE" || fail "Falha ao desativar o service de conservação"
        notify "Carregamento até 100% liberado"
    else
        if run_root_helper disable; then
            notify "Carregamento até 100% liberado até o próximo boot"
            return
        fi

        write_mode_direct 0 || fail "Falha ao liberar carregamento"
        notify "Carregamento até 100% liberado até o próximo boot"
    fi
}

case "${1:-toggle}" in
    status)
        current_mode
        ;;
    waybar)
        capacity="$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")"
        battery_status="$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")"
        case "$(current_mode)" in
            conservation) echo "󱈏 ${capacity}%" ;;
            full)
                if [ "$battery_status" = "Charging" ]; then
                    echo "󰂄 ${capacity}%"
                else
                    echo "󰁹 ${capacity}%"
                fi
                ;;
            *)            echo "󰂑 ${capacity}%" ;;
        esac
        ;;
    waybar-check)
        require_control_path
        ;;
    toggle)
        case "$(current_mode)" in
            conservation) disable_conservation ;;
            full)         enable_conservation ;;
            *)            fail "Estado inesperado no controle de conservação" ;;
        esac
        ;;
    *)
        echo "Uso: ${0##*/} [toggle|status|waybar|waybar-check]" >&2
        exit 2
        ;;
esac
