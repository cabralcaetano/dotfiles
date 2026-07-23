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
| WM | Hyprland 0.55.2 (Wayland) |
| Shell | Zsh + Starship 1.24.2 |
| Terminal | Ghostty 1.3.1 (principal) · Kitty (backup) |
| Editor | VS Code 1.122.1 · Neovim v0.12.2 |
| Launcher | Fuzzel |
| Bar / painel | Waybar 0.15.0 + Quickshell 0.3.0 |
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
- [Wallpapers](#wallpapers)
- [Idle / Lock](#idle--lock)
- [Perfil de energia](#perfil-de-energia)
- [Audio Ducking](#audio-ducking)
- [Cursor](#cursor)
- [Teclado](#teclado)
- [Window Rules](#window-rules)
- [Scripts customizados](#scripts-customizados)
- [Waybar](#waybar)
- [Ferramentas instaladas](#ferramentas-instaladas)
- [Apps (Flatpak)](#apps-flatpak)
- [Stack de desenvolvimento](#stack-de-desenvolvimento)

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
> | **Network / DNS** | NetworkManager/Tailscale | ver [`docs/network.md`](docs/network.md) |
> | **Fedora legado** | dnf/grub-btrfs Fedora | ver [`docs/system-setup-fedora.md`](docs/system-setup-fedora.md); não é o caminho primário atual |
> | **Reflector (mirrorlist automático)** | `/etc/xdg/reflector/reflector.conf` | copiar `reflector/etc/xdg/reflector/reflector.conf`; depois `sudo systemctl enable --now reflector.timer` (ranqueia mirrors do Brasil por velocidade, semanalmente) |

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
hypr/           → hyprland.conf, hypridle.conf, hyprlock.conf,
                  autostart.sh, workspace-float.conf
waybar/         → config.jsonc, style.css
swaync/         → config.json, style.css
quickshell/     → clock-panel/shell.qml
fuzzel/         → fuzzel.ini
ghostty/        → config
kitty/          → kitty.conf
btop/           → btop.conf (`theme_background = false` para transparência do terminal)
zsh/            → .zshrc
starship/       → starship.toml
scripts/        → volume.sh, brightness.sh, kb-toggle.sh, power-profile.sh,
                  wifi-menu.sh, wallpaper.sh, wallpaper-toggle.sh,
                  screenshot.sh, workspace-float.sh, alttab.sh,
                  battery-conservation.sh, clock-panel.sh/clock-panel.py
gtk-3/          → settings.ini
gtk-4/          → settings.ini + accent_color cinza
qt6ct/          → qt6ct.conf + colors/dotfiles-dark.conf (tema dark para apps Qt6)
desktop-apps/   → stow manual: mimeapps.list + .desktop/ícones de apps extraídos manualmente
obsidian/       → configs de vault/plugin; não entra no bootstrap automático
wlogout/        → layout, style.css
sddm/           → referência system-wide manual do SDDM/SilentSDDM
greetd/         → legado/rollback system-wide manual
reflector/      → reflector.conf (mirrorlist Brasil, sort rate) + reflector.timer manual
legacy/         → configs antigas úteis, mas fora do fluxo ativo
ducking/        → guia completo do audio ducking
```

---

## Autostart

Ordem de inicialização definida no `hyprland.conf`:

| App | Workspace | Método |
|---|---|---|
| waybar, quickshell clock-panel, awww-daemon, swaync | — | exec-once imediato |
| hypridle | — | exec-once imediato |
| wallpaper_5.jpg | — | exec-once com sleep 0.5s |
| XDG portals | — | exec-once com sleep 1s |
| GTK dark theme | — | exec-once com sleep 2s |
| brave | 1 | `[workspace 1 silent]` |
| ghostty | 2 | `[workspace 2 silent]` |
| obsidian (flatpak) | 2 | `[workspace 2 silent]` |
| spotify | 3 | exec-once + `autostart.sh` move_when_ready |
| discord | 4 | exec-once + `autostart.sh` move_when_ready |

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
| Super+LMB | Move janela (mouse) |
| Super+RMB | Redimensiona janela (mouse) |

**Workspaces**

| Atalho | Ação |
|---|---|
| Super+1..0 | Vai para workspace 1–10 |
| Super+Shift+1..0 | Move janela para workspace 1–10 |
| Super+S | Toggle scratchpad |
| Super+Shift+S | Move janela para scratchpad |
| Super+Scroll | Navega entre workspaces |

**Sistema**

| Atalho | Ação |
|---|---|
| Super+L | Bloqueia tela (Hyprlock) |
| Super+Shift+Q | Menu de energia (wlogout; desligar/reiniciar pedem confirmação) |
| Super+N | Abre/fecha painel do relógio (Quickshell) |
| Super+Shift+N | Dismiss notificações |
| Super+W | Menu WiFi |
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

Alternância: botão `󰓅` no painel SwayNC (`Super+N`).

**Persistência no boot:** o `tuned` roda em modo `manual` (`profile_mode`) e grava o último perfil escolhido em `/etc/tuned/active_profile`, restaurando-o a cada boot — não há reset para um default. O `default=balanced` do `/etc/tuned/ppd.conf` só se aplica a clientes PPD (ex.: painel do GNOME), não ao toggle da Waybar, que usa `tuned-adm profile` direto. Para fixar o boot em Balanceado, aplique uma vez: `tuned-adm profile balanced`.

---

## Audio Ducking

Abaixa automaticamente o volume do Spotify quando áudio do Brave toca.

- **Serviço:** `brave-duck.service` (systemd user)
- **Implementação atual:** script PipeWire/Pulse com polling de áudio do Brave
- **Pendente:** reconciliar contrato desejado "somente WhatsApp Web" vs comportamento real "qualquer áudio do Brave" — task registrada em `personal/_tasks.md`

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
| Todas as janelas | suppress maximize events |
| XWayland float sem classe | no_focus (fix drag) |

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
| `wifi-menu.sh` | Menu WiFi via Fuzzel |
| `kb-toggle.sh` | Alterna layout de teclado ABNT2/ANSI |
| `workspace-float.sh` | Toggle workspace float mode — flota todas as janelas, desativa warp no Alt+Tab |
| `alttab.sh` | Alt+Tab via cyclenext+bringactivetotop, preserva cursor no float mode |

---

## Waybar

**Esquerda:** ícone custom (`format` vazio no momento — pendente escolher glyph do Arch, era Fedora antes da migração) → workspaces (i–x) → título da janela ativa

**Centro:** relógio (clique abre painel Quickshell com player, calendário, tempo e status; tooltip mantém calendário nativo)

**Direita:** CPU · RAM · rede · bluetooth · volume · perfil de energia · conservação da bateria · tray · hotspot invisível minúsculo no extremo direito para SwayNC

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

---

## Licença

MIT
