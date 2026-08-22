#!/bin/bash
# Cópia exata de /usr/lib/tuned/profiles/powersave/script.sh — precisa existir
# aqui porque o override do tuned.conf no mesmo diretório substitui o perfil
# stock inteiro (sem merge), e a linha [script] referencia ${i:PROFILE_DIR}.

. /usr/lib/tuned/functions

start() {
    [ "$USB_AUTOSUSPEND" = 1 ] && enable_usb_autosuspend
    enable_wifi_powersave
    return 0
}

stop() {
    [ "$USB_AUTOSUSPEND" = 1 ] && disable_usb_autosuspend
    disable_wifi_powersave
    return 0
}

process $@
