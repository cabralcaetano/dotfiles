#!/bin/bash
# Bloqueia Bluetooth no Super Economia só se não houver nada conectado
# (não derruba mouse/fone em uso). tuned chama stop() sozinho ao trocar
# de perfil (rollback automático) — sempre desbloqueia, mesmo que start()
# não tenha bloqueado (rfkill unblock é idempotente).

. /usr/lib/tuned/functions

start() {
    if [ -z "$(bluetoothctl devices Connected 2>/dev/null)" ]; then
        rfkill block bluetooth
    fi
    return 0
}

stop() {
    rfkill unblock bluetooth
    return 0
}

process $@
