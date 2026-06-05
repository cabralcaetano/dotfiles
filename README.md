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
| SUPER + R | Launcher (Fuzzel) |
| SUPER + D | Discord |
| SUPER + O | Obsidian |
| SUPER + M | Spotify |
| SUPER + K | Alterna layout de teclado (ABNT2 / ANSI) |
| SUPER + W | Menu de Wi-Fi |
| SUPER + N | Toggle painel de notificacoes (SwayNC) |
| SUPER + . | Seletor de emoji (rofimoji) |
| SUPER + L | Bloqueia tela (Hyprlock) |
| SUPER SHIFT + C | VS Code |
| SUPER SHIFT + W | Alterna wallpaper |
| SUPER SHIFT + N | Do Not Disturb (SwayNC) |
| SUPER SHIFT + Q | Menu de energia (wlogout) |
| ALT + Tab | Alt-tab (janela anterior) |
| ALT SHIFT + Tab | Alt-tab (janela seguinte) |

**Janelas**

| Atalho | Acao |
|---|---|
| SUPER + C | Fecha janela ativa |
| SUPER + V | Toggle floating |
| SUPER + P | Pseudo-tile (dwindle) |
| SUPER + J | Alterna direcao do split |
| SUPER + Setas | Move foco entre janelas |
| SUPER SHIFT + Setas | Troca janela de posicao |
| SUPER SHIFT + V | Flutua janela no workspace atual |

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
| XF86MonBrightnessUp / Down | Brilho +/- 5% |
| SUPER + F6 / F5 | Brilho +/- (alternativa) |
| XF86AudioNext / Prev | Proxima/anterior faixa |
| XF86AudioPlay / Pause | Play/pause |

**Screenshot**

| Atalho | Acao |
|---|---|
| Print | Screenshot tela inteira |
| SHIFT + Print | Screenshot de area (salva em ~/Imagens/Screenshots/) |
| CTRL + Print | Screenshot de area para clipboard |

**Clipboard**

| Atalho | Acao |
|---|---|
| CTRL SHIFT + S | Historico de clipboard (cliphist + Fuzzel) |
| CTRL SHIFT + Delete | Limpa historico de clipboard |

---

## Audio Ducking

Abaixa automaticamente o volume da música (Spotify) quando áudio do navegador toca — igual ao comportamento do iPhone.

Implementado via script PipeWire + serviço `systemd --user`. Funciona com qualquer app que declare `media.role=phone` (WhatsApp Web, Google Meet, etc.).

Ver guia completo: [[ducking]]

---

## Cursor

Tema: **capitaine-cursors** (`dnf install capitaine-cursors`).

Para o cursor ficar consistente em todos os apps (GTK, Electron, Flatpak):

**1. Hyprland** — `hypr/hyprland.conf`:

    env = XCURSOR_THEME,capitaine-cursors
    env = XCURSOR_SIZE,24

**2. GTK 3** — `gtk-3/.config/gtk-3.0/settings.ini`:

    gtk-cursor-theme-name=capitaine-cursors
    gtk-cursor-theme-size=24

**3. GTK 4** — `gtk-4/.config/gtk-4.0/settings.ini`:

    gtk-cursor-theme-name=capitaine-cursors
    gtk-cursor-theme-size=24

**4. `~/.icons/default/index.theme`** (fallback X11/Electron):

    [Icon Theme]
    Name=Default
    Comment=Default Cursor Theme
    Inherits=capitaine-cursors

**5. Flatpak com XWayland** (ex: Obsidian) — rodar em Wayland nativo resolve o cursor inconsistente:

    flatpak override --user \
      --socket=wayland \
      --nosocket=x11 \
      --env=ELECTRON_OZONE_PLATFORM_HINT=wayland \
      --env=XCURSOR_THEME=capitaine-cursors \
      --env=XCURSOR_SIZE=24 \
      <app-id>

---

## Licenca

MIT
