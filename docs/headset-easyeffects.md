# EasyEffects — QCY H3 Pro

**Status:** instalado, config de EQ/presets ainda pendente
**Contexto:** fone Bluetooth QCY H3 Pro, LDAC

## Descrição

Config do EasyEffects (`8.2.7-1`, Qt6/Kirigami — não é mais GTK, ver `docs/gtk-qt-theming.md`) aplicada especificamente ao fone QCY H3 Pro.

## Decisões tomadas

- **Tema visual:** tentativa de aproximar de GNOME (Material style, Kvantum) testada e **revertida**. Ficou preso no visual Breeze/Kirigami padrão — sem solução limpa, ver `docs/gtk-qt-theming.md` pra detalhes técnicos.
- **Roteamento de microfone (Discord):** LDAC é perfil A2DP **só de saída** — Bluetooth clássico não permite LDAC (saída) + mic (entrada) simultâneos no mesmo dispositivo. Ao usar o mic do fone, o WirePlumber troca o perfil pra `headset-head-unit` (mSBC), derrubando a qualidade da saída também. Solução aplicada: **Discord configurado para usar o microfone do notebook** (`Digital Microphone`) em vez do mic do QCY H3 Pro — assim o perfil do fone nunca sai de `a2dp-sink` (LDAC), mesmo em call.

## Presets — tentativa com pacote da comunidade (revertida)

- Instalado `easyeffects-m0rf30-presets` (AUR) — 72 presets (EQ, bass, loudness, HRTF/virtualização). **Incompatível**: o pacote usa o schema JSON do EasyEffects **GTK antigo** (chaves `snake_case`, ex: `exciter#0`, `plugins_order`). A versão instalada (`8.2.7`, Qt6/Kirigami) usa outro sistema de config (`~/.config/easyeffects/db/easyeffectsrc`, formato KConfig) — não escaneia/importa esses arquivos automaticamente.
- Pacote **desinstalado** (`sudo pacman -R easyeffects-m0rf30-presets`), arquivos locais em `~/.config/easyeffects/output/` removidos. Não ficou nenhum preset de terceiros no sistema.

## Pendente

- [ ] **Criar presets próprios por estilo musical** (prioridade — Caetano ouve principalmente rock). Como não há preset de comunidade compatível com o Qt6 atual, precisa ser montado manualmente na UI (Output → `+` → plugins como Equalizer/Bass Enhancer/Limiter → salvar em Presets). Ponto de partida sugerido pra rock (curva "sorriso + presença", banda 10x):
  | Freq | Ganho |
  |---|---|
  | 31 Hz | 0 dB |
  | 62 Hz | +3 dB |
  | 125 Hz | +2 dB |
  | 250 Hz | -1 dB |
  | 500 Hz | -1 dB |
  | 1 kHz | 0 dB |
  | 2 kHz | +2 dB |
  | 4 kHz | +3 dB |
  | 8 kHz | +2 dB |
  | 16 kHz | +1 dB |
  Ainda não testado/salvo — validar ouvindo e ajustar antes de fixar como preset "Rock".
- [ ] Depois do Rock, expandir pra outros estilos musicais conforme o gosto (perguntar quais gêneros além de rock antes de criar mais presets)
- [ ] Investigar se o Qt6 EasyEffects tem algum mecanismo de import compatível com presets externos (não confirmado — checar release notes/GitHub do `wwmm/easyeffects` se relevante no futuro)
- [ ] Forçar LDAC em qualidade máxima (`hq`, 990kbps) em vez do modo adaptativo padrão. Ainda **não aplicado** — recomendação:
  ```
  # ~/.config/wireplumber/wireplumber.conf.d/51-bluez-ldac.conf
  monitor.bluez.properties = {
    bluez5.a2dp.ldac.quality = "hq"
  }
  ```
  Trade-off: mais glitches em ambiente com interferência 2.4GHz — se acontecer, reverter pra `auto`.
- [ ] Excluir Discord da cadeia de efeitos do EasyEffects (latência em call) caso efeitos sejam aplicados globalmente
