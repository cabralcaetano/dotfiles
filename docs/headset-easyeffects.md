# QCY H3 Pro — áudio Bluetooth e EasyEffects

**Status:** saída Bluetooth automática validada; preset de EQ pendente
**Contexto:** fone Bluetooth QCY H3 Pro; PipeWire + WirePlumber + BlueZ

## Operação atual

- **Saída padrão:** ao conectar um headset Bluetooth com sink disponível, o WirePlumber o seleciona; ao desconectar, volta para o speaker. A preferência persistida do speaker foi desativada em `~/.config/wireplumber/wireplumber.conf.d/50-auto-switch-headset-profile.conf`.
- **Mídia:** usar A2DP/AAC (ou LDAC quando disponível), perfil de alta fidelidade sem microfone do fone.
- **Chamadas:** usar HSP/HFP com codec mSBC; ele fornece reprodução e captura pelo QCY, em mono/baixa taxa de amostragem. A escolha do perfil é separada da troca automática de saída.
- **Aplicativos:** após reiniciar PipeWire, Chrome/Discord podem precisar recriar a captura. Confirmar no app que o dispositivo de entrada é o QCY quando a chamada usar o microfone do fone.

## Diagnóstico e recuperação

1. Se o QCY conecta mas não aparece em **Dispositivos de saída** do `pavucontrol`, não é falha de prioridade: o Bluetooth não criou um sink A2DP/HFP.
2. Confirmar o estado com `wpctl status`, `pactl get-default-sink` e `pactl get-default-source`. Com chamada ativa, a fonte e o sink devem ser `bluez_input.84:AC:60:E7:7B:5E` e `bluez_output.84_AC_60_E7_7B_5E.1`.
3. Em 2026-11-04, `bluez 5.87-2` falhou a negociação A2DP do QCY (`load_remote_sep(): Unable to load LastUsed: rseid … not found`): o fone conectava, mas não havia saída. O workaround validado foi `bluez 5.86-6`, seguido de reinício de `bluetooth`, PipeWire e WirePlumber.
4. Depois da recuperação, validar os dois sentidos: desconectar → speaker; reconectar → `bluez_output.84_AC_60_E7_7B_5E.1`. Se o microfone ainda falhar, confirmar HSP/HFP mSBC, fonte padrão QCY e recriar a captura no aplicativo.

> Não há pin de pacote. Uma atualização completa pode restaurar a versão regressiva; quando houver release com o fix upstream, atualizar BlueZ e repetir a validação.

## Decisões tomadas

- **Tema visual:** tentativa de aproximar de GNOME (Material style, Kvantum) testada e **revertida**. Ficou preso no visual Breeze/Kirigami padrão — sem solução limpa, ver `docs/gtk-qt-theming.md` pra detalhes técnicos.
- **Roteamento de microfone (chamadas):** Bluetooth clássico não oferece A2DP/LDAC de alta fidelidade e mic do mesmo fone simultaneamente. Para usar o mic do QCY, selecionar `headset-head-unit` com mSBC; isso reduz a qualidade da saída por limite do HSP/HFP. O antigo workaround que fixava o `Digital Microphone` do notebook no Discord não é a regra atual.
- **Microfone interno restaurado (2026-10-26):** a regra local não versionada `~/.config/wireplumber/wireplumber.conf.d/51-disable-internal-microphones.conf` definia `node.disabled = true` para `Mic1` e `Mic2`, removendo todas as entradas internas do PipeWire. A regra foi removida e o WirePlumber reiniciado; `Raptor Lake-P/U/H cAVS Digital Microphone` voltou como fonte disponível.

## Vesktop — teste em andamento (2026-08-14)

Avaliado como alternativa mais leve ao Discord oficial (~2,5x menos RAM). Instalado desde 16/jul (`vesktop 1.6.5-1`, AUR), mas ficou "bugado" e voltou pro Discord oficial. Causas encontradas ao investigar de novo:

- **Screen share:** sem `~/.config/xdg-desktop-portal/*-portals.conf`, o `ScreenCast` do `xdg-desktop-portal` não tinha backend preferido explícito entre `xdg-desktop-portal-hyprland` e `xdg-desktop-portal-gtk` rodando juntos. Fix: pacote stow novo `xdg-desktop-portal/` (`STOW_PKGS` em `_dotfiles-lib.sh`) com `hyprland-portals.conf` fixando `ScreenCast`/`Screenshot` em `hyprland` e `FileChooser` em `gtk`. Aplicado e portais reiniciados — **pendente confirmar em call real**.
- **Renderização (janela preta/flicker):** `~/.config/vesktop/settings/settings.json` tinha `"transparent": true`. É bug conhecido de Electron+transparência em compositores wlroots (Hyprland) com GPU Intel iGPU. Confirmado também 1 crash de GPU no `coredumpctl` (`SIGTRAP`, 16/jul, logo após instalar). Fix: `transparent` setado pra `false` diretamente no JSON.
- **Áudio em call:** para usar o mic do QCY, Vesktop precisa selecionar o QCY como entrada e saída; o perfil esperado é `headset-head-unit` com mSBC. A orientação antiga de fixar o `Digital Microphone` do notebook era um workaround de qualidade e não é a regra atual. Testar em call real depois de qualquer reinício do PipeWire.

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
- [ ] **Confirmar fix do Vesktop em call real**: testar screen share (portal) e áudio selecionando o QCY como entrada/saída e HSP/HFP com mSBC. Se áudio ainda falhar, conferir o sink/source BlueZ no `pavucontrol` antes de atribuir o problema ao Vesktop/Electron.
