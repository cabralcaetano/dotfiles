# EasyEffects — QCY H3 Pro

**Status:** instalado, config de EQ/presets ainda pendente
**Contexto:** fone Bluetooth QCY H3 Pro, LDAC

## Descrição

Config do EasyEffects (`8.2.7-1`, Qt6/Kirigami — não é mais GTK, ver `docs/gtk-qt-theming.md`) aplicada especificamente ao fone QCY H3 Pro.

## Decisões tomadas

- **Tema visual:** tentativa de aproximar de GNOME (Material style, Kvantum) testada e **revertida**. Ficou preso no visual Breeze/Kirigami padrão — sem solução limpa, ver `docs/gtk-qt-theming.md` pra detalhes técnicos.
- **Roteamento de microfone (Discord):** LDAC é perfil A2DP **só de saída** — Bluetooth clássico não permite LDAC (saída) + mic (entrada) simultâneos no mesmo dispositivo. Ao usar o mic do fone, o WirePlumber troca o perfil pra `headset-head-unit` (mSBC), derrubando a qualidade da saída também. Solução aplicada: **Discord configurado para usar o microfone do notebook** (`Digital Microphone`) em vez do mic do QCY H3 Pro — assim o perfil do fone nunca sai de `a2dp-sink` (LDAC), mesmo em call.

## Vesktop — teste em andamento (2026-08-14)

Avaliado como alternativa mais leve ao Discord oficial (~2,5x menos RAM). Instalado desde 16/jul (`vesktop 1.6.5-1`, AUR), mas ficou "bugado" e voltou pro Discord oficial. Causas encontradas ao investigar de novo:

- **Screen share:** sem `~/.config/xdg-desktop-portal/*-portals.conf`, o `ScreenCast` do `xdg-desktop-portal` não tinha backend preferido explícito entre `xdg-desktop-portal-hyprland` e `xdg-desktop-portal-gtk` rodando juntos. Fix: pacote stow novo `xdg-desktop-portal/` (`STOW_PKGS` em `_dotfiles-lib.sh`) com `hyprland-portals.conf` fixando `ScreenCast`/`Screenshot` em `hyprland` e `FileChooser` em `gtk`. Aplicado e portais reiniciados — **pendente confirmar em call real**.
- **Renderização (janela preta/flicker):** `~/.config/vesktop/settings/settings.json` tinha `"transparent": true`. É bug conhecido de Electron+transparência em compositores wlroots (Hyprland) com GPU Intel iGPU. Confirmado também 1 crash de GPU no `coredumpctl` (`SIGTRAP`, 16/jul, logo após instalar). Fix: `transparent` setado pra `false` diretamente no JSON.
- **Áudio em call:** mesma causa raiz já documentada acima pro Discord oficial — troca de perfil Bluetooth pra `headset-head-unit` ao abrir o mic. A correção de "usar `Digital Microphone` do notebook" foi aplicada só no Discord oficial (linha acima), **nunca replicada no Vesktop** (é config por app, cada instalação tem sua própria lista de dispositivo de voz). Provável causa do "áudio não funcionava" — precisa configurar o mesmo device em Vesktop → User Settings → Voice & Video → Input Device.

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
- [ ] **Confirmar fix do Vesktop em call real**: testar screen share (portal) e áudio (configurar `Digital Microphone` em Voice & Video) numa call de teste. Se áudio ainda falhar mesmo com o mic certo, investigar se é bug específico do Vesktop/Electron 144 com WebRTC + PipeWire (não só o profile switch do Bluetooth).
