# dotfiles — cabralcaetano

Configurações pessoais do ambiente Linux. Arch Linux · Hyprland · Wayland.

O clone ativo fica em `~/Projects/dotfiles`. GNU Stow cria symlinks do repo para o `$HOME`; configs system-wide ficam documentadas como aplicação manual.

> Migrado de Fedora para Arch em 2026-07-09. Setup Fedora mantido como referência histórica em [`docs/system-setup-fedora.md`](docs/system-setup-fedora.md); diffs da migração em [`docs/arch-migration.md`](docs/arch-migration.md).

---

## Sistema

| Componente | Valor |
|---|---|
| OS | Arch Linux |
| Kernel | 7.1.3-arch1-1 |
| CPU | Intel Core i7-13620H (13ª geração) |
| GPU | Intel UHD Graphics (Raptor Lake-P) |
| WM | Hyprland 0.56.1 (Wayland) — config em Lua (`hyprland.lua`) desde 2026-08-07 |
| Shell | Zsh + Starship 1.24.2 |
| Terminal | Ghostty 1.3.1 (principal) · Kitty (backup) |
| Editor | VS Code 1.122.1 · Neovim v0.12.2 |
| Launcher | Fuzzel |
| Bar / painel | Waybar (git, r959+) + Quickshell 0.3.0 |
| Notificações | SwayNC |
| Lockscreen | Hyprlock |
| Wallpaper | awww (fork compatível com swww, transições animadas) |
| Áudio | PipeWire + WirePlumber |
| Cursor | capitaine-cursors |

---

## Conteúdo

- [Instalação](#instalação)
- [Estrutura do repo](#estrutura-do-repo)
- [Autostart](#autostart)
- [Keybindings](#keybindings)
- [Shell — Zsh](#shell--zsh)
- [Terminal — Ghostty](#terminal--ghostty)
- [Terminal — tmux](#terminal--tmux)
- [Wallpapers](#wallpapers)
- [Idle / Lock](#idle--lock)
- [Perfil de energia](#perfil-de-energia)
- [Audio Ducking](#audio-ducking)
- [Cursor](#cursor)
- [Temas](#temas)
- [Teclado](#teclado)
- [Window Rules](#window-rules)
- [Hyprland Super Workspaces](#hyprland-super-workspaces)
- [Scripts customizados](#scripts-customizados)
- [Waybar](#waybar)
- [Ferramentas instaladas](#ferramentas-instaladas)
- [Apps (Flatpak)](#apps-flatpak)
- [Stack de desenvolvimento](#stack-de-desenvolvimento)
- [Agent harnesses e skills](#agent-harnesses-e-skills)

---

## Instalação

```bash
git clone https://github.com/cabralcaetano/dotfiles ~/Projects/dotfiles
cd ~/Projects/dotfiles

# Instalação idempotente (pacotes + flatpaks + plugins zsh/tmux + stow + extensões)
bash bootstrap.sh
```

O `bootstrap.sh` é **idempotente por tolerância** — pode rodar mais de uma vez, mas ainda executa instaladores novamente quando eles próprios já são idempotentes. Ele:

1. Detecta a distro via `/etc/os-release` e instala `packages/pacman.txt` + `packages/aur.txt` (Arch) ou `packages/dnf.txt` (Fedora legado)
2. Garante o remote `flathub` e instala apps de `packages/flatpak.txt`
3. Clona/atualiza plugins Zsh em `~/.zsh` e TPM em `~/.tmux/plugins/tpm`
4. Valida e aplica symlinks com `stow --restow`
5. Instala extensões de `packages/vscode-extensions.txt`

> **Pós-bootstrap manual:** itens fora do `$HOME`, assets pessoais ou apps extraídos manualmente não entram no Stow automático:
>
> | Item | Destino | Aplicação |
> |---|---|---|
> | **Nerd Fonts** | sistema/usuário | Arch instala `ttf-jetbrains-mono-nerd`; se o pacote falhar, instalar manualmente antes de avaliar a aparência |
> | **Wallpapers reais** | `~/.config/wallpapers/` | copiar os arquivos pessoais; `wallpaper.sh` usa `wallpaper_5.jpg` como fallback |
> | **SDDM Silent theme** | `/etc/sddm.conf.d/`, `/usr/share/sddm/` | aplicar manualmente; ver `dotfiles.md`/`sddm/` |
> | **Battery conservation helper** | `/usr/local/sbin`, `/etc/systemd/system`, `/etc/sudoers.d` | `~/.local/bin/install-battery-conservation-root.sh` |
> | **Antigravity desktop entries** | `~/.local/share/applications`, `~/.config/mimeapps.list` | `stow --target="$HOME" desktop-apps` após extrair os apps em `~/.local/opt` |
> | **Snapshots Btrfs** | snapper + grub-btrfs | ver [`docs/arch-migration.md §1.2`](docs/arch-migration.md) |
> | **Windows VM / Incogniton** | libvirt/QEMU, Windows guest | ver [`docs/windows-vm-incogniton.md`](docs/windows-vm-incogniton.md) |
> | **Network / DNS** | NetworkManager/Tailscale | ver [`docs/network.md`](docs/network.md) |
> | **Fedora legado** | dnf/grub-btrfs Fedora | ver [`docs/system-setup-fedora.md`](docs/system-setup-fedora.md); não é o caminho primário atual |
> | **Reflector (mirrorlist automático)** | `/etc/xdg/reflector/reflector.conf` | copiar `reflector/etc/xdg/reflector/reflector.conf`; depois `sudo systemctl enable --now reflector.timer` (ranqueia mirrors do Brasil por velocidade, semanalmente) |
> | **Impressora (HP DeskJet 2774)** | CUPS + hplip, Wi-Fi da impressora | ver [`docs/printer-hp-deskjet-2774.md`](docs/printer-hp-deskjet-2774.md) — assistente gráfico da HP é instável, usar `scripts/.local/bin/hp-wifi-connect.py` |

### Manifestos de pacote

As listas em `packages/` são a fonte da verdade reproduzível (as tabelas deste README são derivadas): `pacman.txt`, `aur.txt`, `dnf.txt` (legado), `flatpak.txt`, `vscode-extensions.txt`. Para regerar após instalar/remover algo:

```bash
pacman -Qqe                                  | sort > packages/pacman.txt   # revisar antes de commitar — é o dump completo, não só o curado
flatpak list --app --columns=application | sort > packages/flatpak.txt
code --list-extensions | sort                > packages/vscode-extensions.txt
```

---

## Estrutura do repo

```
bootstrap.sh    → instalação idempotente (pacotes, flatpaks, plugins zsh/tmux, stow)
packages/       → manifestos reproduzíveis: pacman.txt, aur.txt, dnf.txt,
                  flatpak.txt, vscode-extensions.txt
hypr/           → hyprland.lua, hypridle.conf, hyprlock.conf,
                  autostart.sh, workspace-float.lua, super-workspaces.txt
                  (hyprland.lua migrado de hyprland.conf em 2026-08-07 — hyprlang
                  deprecated desde Hyprland 0.55, suporte removido no 0.57;
                  original em legacy/hyprland-conf/)
waybar/         → config.jsonc, style.css
swaync/         → config.json, style.css
quickshell/     → clock-panel/shell.qml
fuzzel/         → fuzzel.ini
ghostty/        → config
tmux/           → tmux.conf, plugins TPM/tmux-power; scrollback por mouse via copy-mode -e
kitty/          → kitty.conf
btop/           → btop.conf (`theme_background = false` para transparência do terminal)
zsh/            → .zshrc
starship/       → starship.toml
scripts/        → volume.sh, brightness.sh, kb-toggle.sh, power-profile.sh,
                  wifi-menu.sh, wallpaper.sh, wallpaper-toggle.sh,
                  screenshot.sh, workspace-float.sh, super-workspace.sh, alttab.sh,
                  battery-conservation.sh, clock-panel.sh/clock-panel.py,
                  theme-set.sh (ver themes/README.md)
gtk-3/          → settings.ini
gtk-4/          → settings.ini + accent_color cinza
qt6ct/          → qt6ct.conf + colors/dotfiles-dark.conf (tema dark para apps Qt6)
desktop-apps/   → stow manual: mimeapps.list + .desktop/ícones de apps extraídos manualmente
obsidian/       → configs de vault/plugin; não entra no bootstrap automático
wlogout/        → layout, style.css
sddm/           → referência system-wide manual do SDDM/SilentSDDM
greetd/         → legado/rollback system-wide manual
reflector/      → reflector.conf (mirrorlist Brasil, sort rate) + reflector.timer manual
ducking/        → guia completo do audio ducking
themes/         → theme-set (troca de paleta system-wide, normal/catppuccin); ver themes/README.md
claude/         → skills pessoais do Claude Code / harnesses de agente; ver docs/agent-harnesses-and-skills.md
```

---

## Autostart

Ordem de inicialização definida no `hyprland.lua`:

| App | Workspace | Método |
|---|---|---|
| waybar, quickshell clock-panel, awww-daemon, swaync | — | exec-once imediato |
| hypridle | — | exec-once imediato |
| wallpaper_5.jpg | — | exec-once com sleep 0.5s |
| XDG portals | — | exec-once com sleep 1s |
| GTK dark theme | — | exec-once com sleep 2s |
| brave | super workspace 1 / slot 1 (`name:super-1-1`) | `[workspace name:super-1-1 silent]` |
| ghostty | super workspace 1 / slot 2 (`name:super-1-2`) | `[workspace name:super-1-2 silent]` |
| obsidian (flatpak) | super workspace 1 / slot 2 (`name:super-1-2`) | `[workspace name:super-1-2 silent]` |
| spotify | super workspace 1 / slot 3 (`name:super-1-3`) | `[workspace name:super-1-3 silent]` |
| discord | super workspace 1 / slot 4 (`name:super-1-4`) | `[workspace name:super-1-4 silent]` |

> Spotify e Discord usam `move_when_ready` porque têm updaters que quebram o `[workspace X silent]`.

---

## Keybindings

**Aplicativos**

| Atalho | Ação |
|---|---|
| Super+Q | Terminal (Ghostty) |
| Super+B | Navegador (Brave) |
| Super+E | Gerenciador de arquivos (Nautilus) |
| Super+R | Launcher (Fuzzel) |
| Super+D | Discord |
| Super+M | Spotify |
| Super+O | Obsidian |
| Super+Shift+C | VS Code |

**Janelas**

| Atalho | Ação |
|---|---|
| Super+C | Fecha janela |
| Super+V | Toggle floating |
| Super+Shift+V | Toggle workspace float mode |
| Alt+Tab | Próxima janela (cyclenext + bringactivetotop) |
| Alt+Shift+Tab | Janela anterior |
| Super+P | Pseudo-tile |
| Super+J | Alterna split |
| Super+Setas | Move foco |
| Super+Shift+Setas | Swap janelas |
| Super+F | Tela cheia (toggle) |
| Super+LMB | Move janela (mouse) |
| Super+RMB | Redimensiona janela (mouse) |

**Workspaces**

| Atalho | Ação |
|---|---|
| Super+1..0 | Vai para workspace 1–10 dentro do super workspace ativo |
| Super+Shift+1..0 | Move janela para workspace 1–10 dentro do super workspace ativo |
| Super+Tab | Próximo super workspace |
| Super+Tab+1..2 | Vai direto para o super workspace 1–2 |
| Super+Shift+G | Super workspace anterior |
| Super+S | Toggle scratchpad do super workspace ativo |
| Super+Shift+S | Move janela para scratchpad do super workspace ativo |
| Super+Scroll | Navega globalmente entre workspaces (`e+1`/`e-1`) |

**Sistema**

| Atalho | Ação |
|---|---|
| Super+L | Bloqueia tela (Hyprlock) |
| Super+Shift+Q | Menu de energia (wlogout; desligar/reiniciar pedem confirmação) |
| Super+N | Abre/fecha painel do relógio (Quickshell) |
| Super+Shift+N | Dismiss notificações |
| Super+Shift+B | Alterna codec do fone Bluetooth |
| Super+Shift+W | Alterna wallpaper |
| Super+K | Alterna layout de teclado (ABNT2 ↔ ANSI) |
| Super+. | Emoji picker (rofimoji) |

**Clipboard**

| Atalho | Ação |
|---|---|
| Ctrl+Shift+S | Histórico de clipboard (cliphist + Fuzzel) |
| Ctrl+Shift+Del | Limpa histórico do clipboard |

**Screenshots**

| Atalho | Ação |
|---|---|
| Print | Screenshot fullscreen |
| Shift+Print | Screenshot de área → salva em ~/Pictures/Screenshots/ |
| Ctrl+Print | Screenshot de área → clipboard |

**Mídia e hardware**

| Atalho | Ação |
|---|---|
| XF86AudioRaiseVolume | Volume +5% |
| XF86AudioLowerVolume | Volume −5% |
| XF86AudioMute | Mute áudio |
| XF86AudioMicMute | Mute microfone |
| F6 / XF86MonBrightnessUp | Brilho + |
| F5 / XF86MonBrightnessDown | Brilho − |
| XF86AudioNext/Prev | Faixa seguinte/anterior |
| XF86AudioPlay/Pause | Play/pause |

---

## Hyprland Super Workspaces

Sistema local de bancos de workspaces: cada super workspace tem seus próprios slots `1..9/0` e seu próprio scratchpad, sem mudar a memória muscular dos atalhos.

| Peça | Caminho | Papel |
|---|---|---|
| Lista | `hypr/.config/hypr/super-workspaces.txt` | Uma linha por super workspace; ordem do ciclo `SUPER+Tab`. |
| Roteador | `scripts/.local/bin/super-workspace.sh` | Resolve `focus`, `move`, `switch`, `scratchpad`, `next/prev` e payload JSON da Waybar. |
| Binds | `hypr/.config/hypr/hyprland.lua` | `SUPER+1..0`, `SUPER+Tab`, `SUPER+Tab+1..2`, `SUPER+S` chamam o roteador. |
| Barra | `waybar/.config/waybar/config.jsonc` | Ícone do super workspace ativo + filtro `ignore-workspaces`. |

Nomes internos no Hyprland usam `name:super-<super>-<slot>` para evitar colisão com workspaces numéricos globais. Ex.: super workspace `1`, slot `4` vira `name:super-1-4`; scratchpad vira `special:super-1-magic`.

O script também lembra o último slot focado em cada super workspace. Se você sai de `super-1-2` e depois volta para o super workspace `1`, ele restaura `super-1-2` em vez de cair sempre no slot `1`.

Waybar mostra só os slots do super workspace ativo. O ícone da esquerda vem de `super-workspace.sh waybar` e usa `>`, `~` para os super workspaces `1..2`; o tooltip lista todos e click esquerdo/direito navega próximo/anterior.

Mapa salvo: `>` para o super workspace `1` e `~` para o `2`. Futuro planejado: expandir até `10` super workspaces mantendo esses dois símbolos.

Documentação completa: [`docs/hyprland-super-workspaces.md`](docs/hyprland-super-workspaces.md).

---

## Shell — Zsh

Plugins carregados manualmente de `~/.zsh/`:
- `zsh-syntax-highlighting` — highlight em tempo real
- `zsh-autosuggestions` — sugestões baseadas em histórico

**Aliases**

| Alias | Comando real |
|---|---|
| `ls` | `eza --icons` |
| `ll` | `eza -lah --icons --git` |
| `tree` | `eza --tree --icons` |
| `grep` | `grep --color=auto` |
| `python` / `pip` | `python3` / `pip3` |
| `lg` | `lazygit` |
| `top` | `btop` |
| `y` | `yazi` com `cd` automático ao sair |
| `copy <cmd>` | Redireciona stdout+stderr para clipboard via `wl-copy` |

**Integrações**

| Ferramenta | Integração |
|---|---|
| pyenv | `pyenv init - zsh` no PATH |
| starship | prompt |
| zoxide | `z <dir>` para navegar por histórico |
| fzf | Ctrl+R (histórico), Ctrl+T (arquivos); preview via `bat`; busca via `rg` |
| spicetify | `~/.spicetify` no PATH |

**Histórico**

- 10.000 entradas, `HIST_IGNORE_ALL_DUPS`, `SHARE_HISTORY` (compartilhado entre sessões)

---

## Terminal — Ghostty

| Config | Valor |
|---|---|
| Versão | 1.3.1 |
| Fonte | JetBrainsMono Nerd Font 13pt |
| Tema | Adwaita dark (customizado) |
| Opacidade | 0.85 |
| Blur | background-blur-radius = 20 |
| Cursor | barra piscante |
| Scrollback | 50.000 linhas |
| `gtk-single-instance` | true — novas janelas abrem como tabs na instância existente |
| Padding | 12px horizontal, 8px vertical |

---

## Terminal — tmux

`tmux/.config/tmux/tmux.conf` é aplicado via Stow em `~/.config/tmux/tmux.conf`.

### Scroll do mouse no Ghostty

Decisão ativa: `set -g mouse on` e `WheelUpPane` entra em `copy-mode -e` quando o app/pane não está tratando mouse.

Motivo: dentro do tmux, o scrollback do pane pertence ao tmux, não ao Ghostty. Para a rodinha rolar a tela/histórico do pane, o tmux precisa capturar o mouse; o mecanismo interno de scrollback do tmux é `copy-mode`. O `-e` mantém o comportamento de scroll: ao voltar para o final do histórico, o tmux sai do modo automaticamente.

Não trocar para `mouse off` para tentar evitar `copy-mode`: no Ghostty + tmux em `alternate screen`, isso faz a rodinha virar `Up/Down` no shell e navegar pelos últimos comandos em vez de rolar a tela.

Atalhos úteis:

| Atalho | Ação |
|---|---|
| Rodinha para cima | Rola o histórico do pane via `copy-mode -e` |
| Rodinha para baixo até o final | Volta ao final e sai automaticamente do modo |
| `Ctrl+B` `[` | Entra manualmente em copy-mode |
| `c` em copy-mode | Inicia seleção |
| `v` em copy-mode | Copia para `wl-copy` e continua em copy-mode |
| `y` em copy-mode | Copia para `wl-copy` e sai do copy-mode |
| `q` em copy-mode | Sai do copy-mode |

---

## Wallpapers

`~/.config/wallpapers/` não é versionado no repo porque contém assets pessoais. Os scripts descobrem imagens dinamicamente.

- **Wallpaper inicial:** `~/.config/wallpapers/wallpaper_5.jpg`
- **Trocar manualmente:** `wallpaper.sh ~/caminho/imagem.jpg`
- **Ciclar (Super+Shift+W):** percorre todos os `.jpg`, `.jpeg` e `.png` do diretório, ordenados por nome, com transição fade 1.5s/60fps via `awww`

---

## Idle / Lock

Sequência do `hypridle.conf`:

| Timeout | Ação |
|---|---|
| 5 min | Hyprlock (tela de bloqueio) |
| 5m30s | Monitor apaga (dpms off) |
| 15 min | Suspende sistema |
| Lid close | Hyprlock ao fechar tampa |

---

## Perfil de energia

`tuned-adm` via `tuned-ppd` alterna entre três modos:

| Perfil | Modo tuned | Ícone Waybar |
|---|---|---|
| Balanceado | balanced | oculto |
| Performance | latency-performance | `󱐋` |
| Economia | powersave | `󰌪` |

Alternância: clique no ícone de bateria na Waybar (`custom/battery-conservation`, ver [Waybar](#waybar)), ou no botão `󰓅` no painel SwayNC (`Super+N`).

**Persistência no boot:** o `tuned` roda em modo `manual` (`profile_mode`) e grava o último perfil escolhido em `/etc/tuned/active_profile`, restaurando-o a cada boot — não há reset para um default. O `default=balanced` do `/etc/tuned/ppd.conf` só se aplica a clientes PPD (ex.: painel do GNOME), não ao toggle da Waybar, que usa `tuned-adm profile` direto. Para fixar o boot em Balanceado, aplique uma vez: `tuned-adm profile balanced`.

---

## Audio Ducking

Abaixa automaticamente o volume do Spotify quando áudio do WhatsApp Web toca no Brave e restaura o volume exato que estava antes do ducking.

- **Serviço:** `brave-duck.service` (systemd user)
- **Implementação atual:** script PipeWire/Pulse com polling de áudio do Brave + filtro de janela WhatsApp no Hyprland
  - Outros sites com áudio no Brave não ativam ducking.

---

## Cursor

Tema: **capitaine-cursors** (`sudo pacman -S capitaine-cursors`).

Configurado em 5 lugares para consistência total (GTK 3, GTK 4, Hyprland env, `~/.icons/default/index.theme`, Flatpak override):

```bash
# Flatpak (Obsidian e outros apps Electron)
flatpak override --user \
  --socket=wayland --nosocket=x11 \
  --env=ELECTRON_OZONE_PLATFORM_HINT=wayland \
  --env=XCURSOR_THEME=capitaine-cursors \
  --env=XCURSOR_SIZE=24 \
  <app-id>
```

---

## Temas

`theme-set.sh <tema>` troca a paleta do sistema inteiro — Hyprland, Hyprlock,
Ghostty, Kitty, Fuzzel, Waybar, SwayNC, Quickshell, Neovim, tmux, GTK/Qt e btop
— regenerando templates a partir de `themes/<tema>/colors.toml`. Mecanismo
adaptado do `omarchy-theme-set`, mas standalone.

```bash
theme-set.sh normal       # cinza/Adwaita, redondo
theme-set.sh matte-black  # preto fosco, quadrado
theme-set.sh tokyo-night
theme-set.sh kanagawa
theme-set.sh catppuccin
```

Atalhos:

| Atalho | Ação |
|---|---|
| Super+T | Seletor visual de temas (Quickshell) |
| Super+Ctrl+Shift+Space | Mesmo seletor, compatível com o hábito do Omarchy |
| Super+Shift+W | Cicla wallpapers do diretório ativo |

`normal` preserva os painéis Quickshell cinza/arredondados; `matte-black` aplica
painéis pretos/quadrados mantendo o clock-panel no tamanho padrão
(`quick_clock_scale = 1.0`). Hyprland aplica blur nas layers `quickshell`,
`swaync-control-center` e `launcher` com `ignore_alpha` para não borrar a tela
inteira.

Registro de decisão/contexto em [`docs/theme-switching.md`](docs/theme-switching.md);
referência técnica de schema/templates em [`themes/README.md`](themes/README.md).

---

## Teclado

Toggle `Super+K` alterna entre ABNT2 (notebook) e ANSI US (teclado mecânico externo).

O setup ativo usa layouts padrão (`br,us`) com `kb_options = compose:rctrl`. O antigo layout customizado `us-br` foi preservado em `legacy/xkb/`, mas está fora do fluxo ativo e não deve ser instalado por padrão.

O teclado mecânico AULA F75/Compx recebe `altwin:swap_alt_win` só nos blocos `device {}` do Hyprland, porque o receptor enumera Alt/Super trocados. O teclado do notebook segue sem swap.

---

## Window Rules

| App | Regra |
|---|---|
| Overskride (Bluetooth) | Float, 800×500, centralizado |
| pavucontrol | Float, 800×500, centralizado |
| btop via Waybar | Ghostty dedicado, 80×24 efetivo (`window-width=84`, `window-height=25`), sem decoração, float, centralizado |
| GNOME Calendar (Quickshell) | Float, 882×575, centralizado |
| GNOME Calculator | Float, 380×540, centralizado |
| Bitwarden | Float, 1000×800, centralizado |
| Waydroid YouCine | Fullscreen, renderiza no tamanho lógico do monitor |
| Todas as janelas | suppress maximize events |
| XWayland float sem classe | no_focus (fix drag) |
| hyprland-run | Float, ancorado no canto inferior esquerdo do monitor |

---

## Scripts customizados

| Script | Função |
|---|---|
| `wallpaper.sh` | Troca wallpaper via awww com transição |
| `wallpaper-toggle.sh` | Cicla dinamicamente pelas imagens em `~/.config/wallpapers/` |
| `screenshot.sh` | Screenshots fullscreen/área/clipboard via grim+slurp |
| `volume.sh` | Controle de volume com notificação |
| `brightness.sh` | Controle de brilho |
| `power-profile.sh` | Alterna perfis tuned-adm |
| `power-confirm.sh` | Confirma desligamento/reinicialização via Fuzzel antes de chamar `systemctl` |
| `clock-panel-toggle.sh` | Toggle do painel Quickshell do relógio via IPC |
| `clock-panel-status.sh` | Métricas do painel Quickshell: CPU, MEM, DISK e GPU em barras |
| `clock-panel-weather.sh` | Tempo atual + previsão das próximas horas para o painel Quickshell |
| `media-volume-spotify.sh` | Controle do volume interno do Spotify (slider do app) para o painel Quickshell; durante ducking atualiza o volume desejado e mantém o stream PipeWire temporariamente limitado |
| `wifi-menu.sh` | Menu WiFi via Fuzzel |
| `kb-toggle.sh` | Alterna layout de teclado ABNT2/ANSI |
| `workspace-float.sh` | Toggle workspace float mode — flota todas as janelas, desativa warp no Alt+Tab |
| `alttab.sh` | Alt+Tab via cyclenext+bringactivetotop, preserva cursor no float mode |
| `super-workspace.sh` | Roteia bancos de workspaces: foco/move por slot, scratchpad por super workspace, ciclo `next/prev` e JSON da Waybar |

---

## Waybar

**Esquerda:** ícone do super workspace ativo (`custom/super-workspace`, tooltip com lista e click next/prev) → workspaces filtrados do banco ativo (i–x) → título da janela ativa

**Super workspaces:** `hyprland/workspaces` mostra apenas workspaces cujo nome bate com `super-<ativo>-*`; `super-workspace.sh` reescreve `ignore-workspaces` e recarrega a Waybar com `SIGUSR2` a cada troca de banco. Ver [`docs/hyprland-super-workspaces.md`](docs/hyprland-super-workspaces.md).

**Centro:** relógio (clique abre painel Quickshell com player, calendário, tempo e status; tooltip mantém calendário nativo)

**Direita:** CPU · RAM · rede · bluetooth · volume · indicador de perfil de energia (só aparece fora do Balanceado) · bateria/conservação · tray · hotspot invisível minúsculo no extremo direito para SwayNC

**Workspaces — clique/scroll (2026-08-10):** `hyprland/workspaces` no Waybar 0.15.0 estável não troca de workspace no clique com o dispatcher Lua do Hyprland (`hyprland.lua`) — o módulo manda `dispatch workspace N` no formato antigo, que essa build do Hyprland rejeita ([Waybar#5008](https://github.com/Alexays/Waybar/issues/5008)). Scroll funciona porque cai num caminho diferente. Fix está no `master` do Waybar (PR #5013), ainda não lançado em release estável → pacote trocado de `waybar` (pacman) para `waybar-git` (AUR). Config ajustado:
- `disable-scroll: false` — scroll também troca workspace.
- Removido `"on-click": "activate"` — é sintaxe do `sway/workspaces`; o `hyprland/workspaces` troca no clique nativamente (sem config extra), e deixar essa chave quebrava o handler.
- `#workspaces button { padding: 0 8px; min-width: 16px; }` em `style.css` — numeral romano sozinho tinha área de clique minúscula.

**Alcance maior que o Waybar:** o mesmo dispatch antigo (`hyprctl dispatch focuswindow "class:^(X)$"`) quebra em qualquer script, não só no Waybar. Achados e corrigidos: `scripts/.local/bin/media-open-spotify.sh` (clique na capa do álbum no painel Quickshell foca o Spotify) e `scripts/.local/bin/waybar-calendar.sh`. Forma correta: `hyprctl dispatch "hl.dsp.focus({ window = 'class:^(X)\$' })"`. Os dois arquivos em `~/.local/bin/` tinham virado cópias soltas (symlink do Stow quebrado) — restaurados.

**Bateria / perfil de energia (2026-08-10):** um ícone só de perfil (`custom/power-profile`, sem clique) causava mira errada — some quando não há nada ao lado pra empurrar, e o vizinho (`custom/battery-conservation`) desliza pro lugar e rouba o clique. Solução: o clique pra trocar perfil (Balanceado/Performance/Economia) foi pro ícone de bateria (`custom/battery-conservation`, sempre visível e largo — alvo fácil); o `custom/power-profile` virou indicador passivo, sem `on-click`, só aparece fora do Balanceado. `battery-conservation.sh waybar` agora usa `return-type: json` pra devolver `{"text": "...", "tooltip": "..."}` com tooltip curto e dinâmico (`Balanceado · Preservação`, `Performance · 100%` etc.) em vez de texto instrucional fixo. **Trade-off:** o toggle Long_Life/100% perdeu o clique dedicado na Waybar — agora só via terminal (`battery-conservation.sh toggle`), já que na prática raramente é trocado.

**Tooltips — tamanho de fonte:** `tooltip, tooltip * { font-size: ...px }` em `style.css` controla o tamanho. Gotcha: o hot-reload (`reload_on_style_change`) não repropaga pro popup de tooltip do GTK — precisa `pkill waybar && waybar &` (restart completo), CSS sozinho não basta.

---

## Ferramentas instaladas

**CLI essenciais (manifestos Arch/pacman; Fedora mantido como legado)**

| Ferramenta | Versão | Função |
|---|---|---|
| eza | — | `ls` moderno com ícones e suporte a git |
| bat | 0.26.1 | `cat` com syntax highlight |
| fzf | — | Fuzzy finder (Ctrl+R, Ctrl+T no Zsh) |
| ripgrep (rg) | 14.1.1 | Busca em arquivos (backend do fzf) |
| zoxide | 0.9.8 | `cd` inteligente com histórico |
| yazi | 25.5.31 | File manager TUI em colunas |
| lazygit | 0.47.2 | Git TUI |
| btop | 1.4.6 | Monitor de recursos |
| jq | — | Processador de JSON |
| podman | — | Containers (alternativa rootless ao Docker) |
| starship | 1.24.2 | Prompt configurável |
| zsh-syntax-highlighting | — | Highlight de comandos em tempo real |
| zsh-autosuggestions | — | Sugestões de histórico |

**Ferramentas de desenvolvimento**

| Ferramenta | Função |
|---|---|
| gh (v2.96.0) | GitHub CLI — pacote `github-cli` (pacman), autenticado via `gh auth setup-git` |
| pyenv (2.6.26) | Gerenciamento de versões Python |
| spicetify | Customização do cliente Spotify |
| matugen | Geração de paletas de cores (Material You) |
---

## Apps (Flatpak)

| App | ID |
|---|---|
| Zen Browser | app.zen_browser.zen |
| Obsidian | md.obsidian.Obsidian |
| GitHub Desktop | io.github.shiftey.Desktop |
| Bruno (API client) | com.usebruno.Bruno |
| ProtonVPN | com.protonvpn.www |
| Google Chrome | com.google.Chrome |
| Steam | com.valvesoftware.Steam |
| Stremio | com.stremio.Stremio |
| qBittorrent | org.qbittorrent.qBittorrent |
| VLC | org.videolan.vlc |
| mpv | io.mpv.Mpv |
| ncspot | io.github.hrkfdn.ncspot |
| Overskride (Bluetooth) | io.github.kaii_lb.Overskride |
| Flatseal | com.github.tchx84.Flatseal |
| TextSnatcher | com.github.rajsolai.textsnatcher |
| PCSX2 | net.pcsx2.PCSX2 |
| RetroArch | org.libretro.RetroArch |
| Déjà Dup | org.gnome.DejaDup |
| IRPF 2022–2025 | br.gov.fazenda.receita.irpf202X |

---

## Apps instalados manualmente (fora de dnf/flatpak)

Apps distribuídos como `.tar.gz` (sem pacote nativo), extraídos manualmente em `~/.local/opt/<nome>/`. Os `.desktop`, ícones e associações de URI scheme desses apps ficam no pacote stow `desktop-apps/`.

| App | Caminho do binário | URI scheme |
|---|---|---|
| Antigravity 2.0 (desktop) | `~/.local/opt/Antigravity-x64/antigravity` | `antigravity://` |
| Antigravity IDE | `~/.local/opt/Antigravity IDE/antigravity-ide` | `antigravity-ide://` |

Passos para reinstalar em máquina nova (o binário em si **não** é versionado no repo, só o `.desktop`/ícone/mimeapps):

```bash
# 1. Baixar os .tar.gz em antigravity.google e extrair
mkdir -p ~/.local/opt
tar -xzf Antigravity.tar.gz -C ~/.local/opt/
tar -xzf "Antigravity IDE.tar.gz" -C ~/.local/opt/

# 2. Os .desktop apontam pros caminhos acima — aplicar o stow manual
cd ~/Projects/dotfiles
stow --target="$HOME" desktop-apps

# 3. Login OAuth no primeiro uso usa o esquema x-scheme-handler/antigravity(-ide),
#    já registrado via mimeapps.list — não precisa reconfigurar
```

> Ícones extraídos manualmente do `.asar`/bundle de cada app (`code.png` no caso do IDE, `icon.png` dentro de `resources/app.asar` no caso do 2.0) e salvos em `desktop-apps/.local/share/icons/hicolor/512x512/apps/`.

---

## Stack de desenvolvimento

| Linguagem / Runtime | Versão | Gerenciador |
|---|---|---|
| Node.js | 22.22.2 (LTS) | sistema (pacman) |
| Python | 3.14.3 | pyenv 2.6.26 |
| Rust | 1.95.0 | rustup |
| Bun | 1.3.14 | sistema |

**Editores**

| Editor | Versão | Extensões notáveis |
|---|---|---|
| VS Code | 1.122.1 | Claude Code, Python, Prettier, ESLint, Error Lens, Live Server |
| Neovim | 0.12.2 | — |

**Neovim**

| Atalho | Ação |
|---|---|
| Alt+1..9 | Vai para a aba/buffer visível na `bufferline.nvim` |
| Ctrl+t | Cria uma aba/buffer vazio (`:enew`) |
| Ctrl+w | Fecha a aba/buffer atual sem fechar o split |
| Alt+h/j/k/l | Move foco entre splits do Neovim |
| Alt+Setas | Move foco entre splits do Neovim |
| Ctrl-w Ctrl-w | No terminal embutido, alterna para o próximo split |
| Ctrl-w h/j/k/l | No terminal embutido, move foco entre splits |
| Ctrl-w Setas | No terminal embutido, move foco entre splits |

---

## Agent harnesses e skills

Inventário e contrato operacional em [`docs/agent-harnesses-and-skills.md`](docs/agent-harnesses-and-skills.md).

| Harness / skill | Estado |
|---|---|
| Claude Code | Skills versionadas em `claude/.claude/skills/` |
| Oh My Pi (`omp`) | Harness principal neste ambiente; configs ativas em `~/.omp/agent/` |
| OpenCode (`opencode`) | PATH versionado no `zsh/.zshrc` (`~/.opencode/bin`) |
| `teachflow-board` | Nome técnico legado; agora opera só tasks/cards do Horizon CRM e sincroniza Kanban + `.md` locais |

---

## Decisões de design

| Decisão | Motivo |
|---|---|
| awww em vez de hyprpaper/swww | No Arch, `awww` substitui `swww` mantendo CLI compatível e transições animadas |
| Repo standalone em `~/Projects/dotfiles` | Evita depender do submodule dentro do `wiki-ia` para aplicar Stow no sistema |
| move_when_ready para Spotify/Discord | Updaters separados quebram `[workspace X silent]` |
| Alt+Tab via cyclenext (nativo) | hyprshell e hyprswitch incompatíveis com Hyprland 0.55 (formato de endereço IPC mudou de hex para decimal) |
| workspace-float.conf no repo | Estado inicial/atual de workspaces floating é preservado via Stow |
| Flatpaks em Wayland nativo | Resolve cursor inconsistente e melhora integração com compositor |
| brave-duck.service como systemd user | Persiste entre reinicializações sem intervenção manual |
| waybar-git em vez de waybar (pacman) | Fix do clique em `hyprland/workspaces` com o dispatcher Lua do Hyprland só existe no `master` (Waybar#5008/#5013), sem release estável ainda |

---

## Licença

MIT
