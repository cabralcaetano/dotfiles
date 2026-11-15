#!/usr/bin/env bash
# Supervisor do Waybar: relança se ele cair.
#
# Por quê: no boot o Waybar (waybar-git) segfaulta no módulo tray —
# dbusmenu_menuitem_get_children (libdbusmenu-glib), disparado quando um item
# StatusNotifier (fcitx5, etc.) registra/atualiza o menu enquanto o tray ainda
# está inicializando. Bug upstream/race; o segundo start já passa limpo.
# Coredumps: `coredumpctl list waybar`.
#
# Uma instância só; saída 0 (SIGTERM/`pkill waybar` limpo) encerra o loop.

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/waybar-run.lock"
flock -n 9 || exit 0

fails=0
while true; do
    start=$SECONDS
    waybar "$@"
    rc=$?
    [ "$rc" -eq 0 ] && exit 0
    # SIGTERM/SIGINT/SIGKILL = encerrado de propósito
    case "$rc" in 130|137|143) exit 0 ;; esac

    # crash rápido repetido: recua para não girar em loop apertado
    if (( SECONDS - start < 10 )); then fails=$((fails + 1)); else fails=0; fi
    (( fails >= 5 )) && sleep 10 || sleep 1
done
