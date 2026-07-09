# EasyEffects — QCY H3 Pro

**Status:** instalado, config de EQ/presets ainda pendente
**Contexto:** fone Bluetooth QCY H3 Pro, LDAC

## Descrição

Config do EasyEffects (`8.2.7-1`, Qt6/Kirigami — não é mais GTK, ver `docs/gtk-qt-theming.md`) aplicada especificamente ao fone QCY H3 Pro.

## Decisões tomadas

- **Tema visual:** tentativa de aproximar de GNOME (Material style, Kvantum) testada e **revertida**. Ficou preso no visual Breeze/Kirigami padrão — sem solução limpa, ver `docs/gtk-qt-theming.md` pra detalhes técnicos.
- **Roteamento de microfone (Discord):** LDAC é perfil A2DP **só de saída** — Bluetooth clássico não permite LDAC (saída) + mic (entrada) simultâneos no mesmo dispositivo. Ao usar o mic do fone, o WirePlumber troca o perfil pra `headset-head-unit` (mSBC), derrubando a qualidade da saída também. Solução aplicada: **Discord configurado para usar o microfone do notebook** (`Digital Microphone`) em vez do mic do QCY H3 Pro — assim o perfil do fone nunca sai de `a2dp-sink` (LDAC), mesmo em call.

## Pendente

- [ ] Forçar LDAC em qualidade máxima (`hq`, 990kbps) em vez do modo adaptativo padrão. Ainda **não aplicado** — recomendação:
  ```
  # ~/.config/wireplumber/wireplumber.conf.d/51-bluez-ldac.conf
  monitor.bluez.properties = {
    bluez5.a2dp.ldac.quality = "hq"
  }
  ```
  Trade-off: mais glitches em ambiente com interferência 2.4GHz — se acontecer, reverter pra `auto`.
- [ ] Configurar EQ/presets no EasyEffects (checar se existe preset AutoEQ pro QCY H3 Pro — incerto, é TWS meio nicho)
- [ ] Excluir Discord da cadeia de efeitos do EasyEffects (latência em call) caso efeitos sejam aplicados globalmente
