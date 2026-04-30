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
| Kitty | Terminal |
| Hyprpaper | Wallpaper |

---

## Estrutura

    dotfiles/
    hypr/       -> hyprland.conf, hyprlock.conf, hypridle.conf
    waybar/     -> config.jsonc, style.css
    swaync/     -> config.json, style.css
    fuzzel/     -> fuzzel.ini
    scripts/    -> screenshot.sh, volume.sh, brightness.sh
    udev/       -> regras hwdb de teclado

---

## Instalacao com GNU Stow

    git clone https://github.com/cabralcaetano/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    sudo dnf install stow
    stow hypr waybar swaync fuzzel scripts

---

## Teclado — Right Ctrl como AltGr (AULA F75)

O teclado AULA F75 (Compx 2.4G Wireless Receiver) nao possui tecla AltGr dedicada.
A solucao usa udev hwdb para remap no nivel do kernel, funcionando em Wayland/Hyprland sem depender de XKB.

**Instalacao manual** (requer root, nao compativel com stow):

    sudo cp udev/90-aula-rctrl-altgr.hwdb /etc/udev/hwdb.d/
    sudo systemd-hwdb update
    sudo udevadm trigger --action=change --subsystem-match=input

Reconecte o receptor USB apos aplicar. O Right Ctrl passara a funcionar como AltGr.

---

## Keybinds principais

| Atalho | Acao |
|---|---|
| SUPER + R | Launcher (Fuzzel) |
| SUPER + Q | Terminal (Kitty) |
| SUPER + B | Navegador (Brave) |
| SUPER + N | Central de notificacoes |
| SUPER + L | Bloqueia a tela |
| SUPER + C | Fecha janela |
| SUPER + V | Toggle floating |
| SUPER + S | Scratchpad |
| Print | Screenshot tela inteira |
| SHIFT + Print | Screenshot de area |
| CTRL + Print | Screenshot para clipboard |
| CTRL SHIFT + S | Historico de clipboard |

---

## Licenca

MIT
