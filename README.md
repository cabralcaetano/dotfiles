# Dotfiles — cabralcaetano

Configurações pessoais para ambiente Linux com Hyprland no Fedora.

---

## Setup

| Ferramenta | Funcao |
|---|---|
| Hyprland | Window manager Wayland |
| Waybar | Barra de status |
| SwayNC | Central de notificacoes |
| Hyprlock | Lockscreen |
| Hypridle | Daemon de inatividade |
| Fuzzel | App launcher |
| Ghostty | Terminal |
| Hyprpaper | Wallpaper |

---

## Estrutura

    dotfiles/
    hypr/       -> hyprland.conf, hyprlock.conf, hypridle.conf
    waybar/     -> config.jsonc, style.css
    swaync/     -> config.json, style.css
    fuzzel/     -> fuzzel.ini
    scripts/    -> screenshot.sh, volume.sh, brightness.sh, power-profile.sh
    udev/deprecated/ -> configs antigas (nao instalar)

---

## Instalacao com GNU Stow

    git clone https://github.com/cabralcaetano/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    sudo dnf install stow
    stow hypr waybar swaync fuzzel scripts ghostty

---

## Perfil de energia

Usa `tuned-adm` (via `tuned-ppd`, ja instalado no Fedora) para alternar entre tres modos:

| Perfil | Modo tuned |
|---|---|
| Balanceado | balanced |
| Performance | latency-performance |
| Economia | powersave |

**Alternancia:** botao `󰓅` no painel do SwayNC (`SUPER + N`) — clica para ciclar entre os modos.

**Indicador na waybar:** icone aparece ao lado da bateria apenas quando o perfil nao e o balanceado (`󱐋` performance, `󰌪` economia).

---

## Teclado — Alternancia ABNT2 / ANSI

Toggle via `SUPER + K` entre teclado do notebook (BR ABNT2) e teclado mecanico (ANSI US).

**Layout ANSI customizado (`us-br`):**

| Combo (RCtrl = AltGr) | Saida |
|---|---|
| RCtrl + ; | ç |
| RCtrl + Q | / |
| RCtrl + W | ? |
| RCtrl + [ + vogal | acento agudo (á, é, í, ó, ú) |
| RCtrl + ' + vogal | til (ã, õ) |

**Instalacao do variant XKB** (requer root, nao compativel com stow):

    cd xkb/
    bash install.sh

Ou manualmente:

    sudo tee -a /usr/share/X11/xkb/symbols/us < xkb/us-br.xkb

---

## [DEPRECATED] Teclado — Right Ctrl como AltGr (AULA F75)

> **Deprecated.** O teclado AULA F75 nao esta mais em uso. A config foi movida para
> `udev/deprecated/90-aula-rctrl-altgr.hwdb` e removida do sistema.
> Nao instalar.

---

## Keybinds principais

**Aplicativos**

| Atalho | Acao |
|---|---|
| SUPER + Q | Terminal (Ghostty) |
| SUPER + B | Navegador (Brave) |
| SUPER + E | Gerenciador de arquivos (Nautilus) |
| SUPER + R | Launcher (Hyprlauncher) |
| SUPER + M | Menu de energia (sair do Hyprland) |

**Janelas**

| Atalho | Acao |
|---|---|
| SUPER + C | Fecha janela ativa |
| SUPER + V | Toggle floating |
| SUPER + P | Pseudo-tile (dwindle) |
| SUPER + J | Alterna direcao do split |
| SUPER + Setas | Move foco entre janelas |

**Workspaces**

| Atalho | Acao |
|---|---|
| SUPER + 1..0 | Vai para workspace 1-10 |
| SUPER SHIFT + 1..0 | Move janela para workspace 1-10 |
| SUPER + S | Toggle scratchpad |
| SUPER SHIFT + S | Move janela para scratchpad |
| SUPER + Scroll | Navega entre workspaces |

**Mouse**

| Atalho | Acao |
|---|---|
| SUPER + Botao esquerdo | Move janela |
| SUPER + Botao direito | Redimensiona janela |

**Media e hardware**

| Atalho | Acao |
|---|---|
| XF86AudioRaiseVolume | Volume +5% |
| XF86AudioLowerVolume | Volume -5% |
| XF86AudioMute | Mute audio |
| XF86AudioMicMute | Mute microfone |
| XF86MonBrightnessUp | Brilho +5% |
| XF86MonBrightnessDown | Brilho -5% |
| XF86AudioNext/Prev | Proxima/anterior faixa |
| XF86AudioPlay/Pause | Play/pause |

**Screenshot**

| Atalho | Acao |
|---|---|
| Print | Screenshot de area (salva em ~/Imagens/Screenshots/) |

---

## Licenca

MIT
