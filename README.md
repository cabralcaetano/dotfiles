# dotfiles — cabralcaetano

Configurações pessoais do ambiente Linux. Fedora 44 · Hyprland · Wayland.

O repo fica dentro do wiki-ia — GNU Stow cria symlinks diretamente de lá para o sistema.

---

## Sistema

| Componente | Valor |
|---|---|
| OS | Fedora 44 |
| Kernel | 7.0.10-201.fc44.x86_64 |
| CPU | Intel Core i7-13620H (13ª geração) |
| GPU | Intel UHD Graphics (Raptor Lake-P) |
| WM | Hyprland 0.55.2 (Wayland) |
| Shell | Zsh + Starship 1.24.2 |
| Terminal | Ghostty 1.3.1 (principal) · Kitty (backup) |
| Editor | VS Code 1.122.1 · Neovim v0.12.2 |
| Launcher | Fuzzel |
| Bar | Waybar 0.15.0 |
| Notificações | SwayNC |
| Lockscreen | Hyprlock |
| Wallpaper | swww (transições animadas) |
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
# O repo fica dentro do wiki-ia — não clonar separado
git clone https://github.com/cabralcaetano/wiki-ia ~/wiki-ia
cd ~/wiki-ia/personal/projects/dotfiles

# Instalação idempotente (pacotes + flatpaks + plugins zsh + stow + cargo + extensões)
bash bootstrap.sh
```

O `bootstrap.sh` é **idempotente** — pode rodar quantas vezes quiser, só faz o que falta. Ele:

1. Instala pacotes dnf de `packages/dnf.txt`
2. Garante o remote `flathub` e instala apps de `packages/flatpak.txt`
3. Clona os plugins Zsh em `~/.zsh` (não versionados no repo)
4. Aplica os symlinks com `stow --restow`
5. Instala crates de `packages/cargo.txt` e extensões de `packages/vscode-extensions.txt`

> **Atenção:** dois passos exigem ação manual:
> - **XKB customizado** (`xkb/`) — requer root, incompatível com stow: `cd xkb && bash install.sh`
> - **Nerd Fonts** (JetBrainsMono, FiraCode) — instalar manualmente

### Manifestos de pacote

As listas em `packages/` são a fonte da verdade reproduzível (as tabelas deste README são derivadas). Para regerar após instalar/remover algo:

```bash
flatpak list --app --columns=application | sort > packages/flatpak.txt
code --list-extensions | sort                > packages/vscode-extensions.txt
```

---

## Estrutura do repo

```
bootstrap.sh    → instalação idempotente (pacotes, flatpaks, plugins zsh, stow)
packages/       → manifestos reproduzíveis: dnf.txt, flatpak.txt, cargo.txt,
                  vscode-extensions.txt
hypr/           → hyprland.conf, hypridle.conf, hyprlock.conf, hyprpaper.conf,
                  autostart.sh, workspace-float.conf
waybar/         → config.jsonc, style.css
swaync/         → config.json, style.css
fuzzel/         → fuzzel.ini
ghostty/        → config
kitty/          → kitty.conf
zsh/            → .zshrc
starship/       → starship.toml
scripts/        → volume.sh, brightness.sh, kb-toggle.sh, power-profile.sh,
                  wifi-menu.sh, wallpaper.sh, wallpaper-toggle.sh,
                  screenshot.sh, workspace-float.sh, alttab.sh
gtk-3/          → settings.ini
gtk-4/          → settings.ini
xkb/            → us-br.xkb, install.sh  (instalação manual, requer root)
hyprshell/      → config.ron  (instalado mas inativo — incompatível com Hyprland 0.55)
obsidian/       → config do Obsidian (via stow)
wlogout/        → layout, style.css
udev/deprecated → configs antigas (não instalar)
ducking/        → guia completo do audio ducking
```

---

## Autostart

Ordem de inicialização definida no `hyprland.conf`:

| App | Workspace | Método |
|---|---|---|
| waybar, swww-daemon, swaync | — | exec-once imediato |
| hypridle | — | exec-once imediato |
| wallpaper_2.jpg | — | exec-once com sleep 0.5s |
| XDG portals | — | exec-once com sleep 1s |
| GTK dark theme | — | exec-once com sleep 2s |
| brave-browser | 1 | `[workspace 1 silent]` |
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
| Super+Shift+Q | Menu de energia (wlogout) |
| Super+N | Toggle notificações (SwayNC) |
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
| Shift+Print | Screenshot de área → salva em ~/Imagens/Screenshots/ |
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

```
~/.config/wallpapers/
├── wallpaper_1.jpg   — dark waves (preto, abstrato)
├── wallpaper_2.jpg   — default no boot
└── wallpaper_3.png   — terceiro wallpaper no ciclo
```

- **Trocar manualmente:** `wallpaper.sh ~/caminho/imagem.jpg`
- **Ciclar (Super+Shift+W):** alterna 1→2→3→1 com transição fade 1.5s/60fps via swww

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

---

## Audio Ducking

Abaixa automaticamente o volume do Spotify quando áudio do WhatsApp Web toca no Brave — comportamento igual ao iPhone.

- **Serviço:** `brave-duck.service` (systemd user, rodando em produção)
- **Implementação:** script PipeWire + detecção de janela com "whatsapp" no título via Hyprland IPC
- **Guia completo:** `ducking/ducking.md`

---

## Cursor

Tema: **capitaine-cursors** (`sudo dnf install capitaine-cursors`).

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

Toggle `Super+K` alterna entre ABNT2 (notebook) e ANSI (teclado mecânico externo).

**Layout ANSI customizado (`us-br`)** — instalação manual em `/usr/share/X11/xkb/symbols/us`:

| Combo (RCtrl = AltGr) | Saída |
|---|---|
| RCtrl + ; | ç |
| RCtrl + Q | / |
| RCtrl + W | ? |
| RCtrl + [ + vogal | acento agudo (á, é, í, ó, ú) |
| RCtrl + ' + vogal | til (ã, õ) |

```bash
cd xkb && bash install.sh
```

---

## Window Rules

| App | Regra |
|---|---|
| Overskride (Bluetooth) | Float, 800×500, centralizado |
| pavucontrol | Float, 800×500, centralizado |
| Todas as janelas | suppress maximize events |
| XWayland float sem classe | no_focus (fix drag) |

---

## Scripts customizados

| Script | Função |
|---|---|
| `wallpaper.sh` | Troca wallpaper via swww com transição |
| `wallpaper-toggle.sh` | Cicla entre wallpaper_1, _2, _3 |
| `screenshot.sh` | Screenshots fullscreen/área/clipboard via grim+slurp |
| `volume.sh` | Controle de volume com notificação |
| `brightness.sh` | Controle de brilho |
| `power-profile.sh` | Alterna perfis tuned-adm |
| `wifi-menu.sh` | Menu WiFi via Fuzzel |
| `kb-toggle.sh` | Alterna layout de teclado ABNT2/ANSI |
| `workspace-float.sh` | Toggle workspace float mode — flota todas as janelas, desativa warp no Alt+Tab |
| `alttab.sh` | Alt+Tab via cyclenext+bringactivetotop, preserva cursor no float mode |

---

## Waybar

**Esquerda:** ícone Fedora → workspaces (i–x) → título da janela ativa

**Centro:** relógio (clique abre SwayNC, tooltip calendário)

**Direita:** CPU · RAM · rede · bluetooth · volume · perfil de energia · bateria · tray

---

## Ferramentas instaladas

**CLI essenciais (dnf)**

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
| gh (v2.92.0) | GitHub CLI — instalado em `~/.local/bin` |
| pyenv (2.6.26) | Gerenciamento de versões Python |
| spicetify | Customização do cliente Spotify |
| matugen | Geração de paletas de cores (Material You) |

**Cargo (Rust)**

| Binário | Função |
|---|---|
| hyprshell | Switcher de janelas (inativo — incompatível com Hyprland 0.55) |
| window_switcher | Switcher alternativo |
| rustup + toolchain | Rust 1.95.0 |

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

## Stack de desenvolvimento

| Linguagem / Runtime | Versão | Gerenciador |
|---|---|---|
| Node.js | 22.22.2 (LTS) | sistema (dnf) |
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
| swww em vez de hyprpaper | Suporte a transições animadas (fade 1.5s/60fps) |
| Repo dentro do wiki-ia | Centraliza tudo em um único repositório versionado |
| move_when_ready para Spotify/Discord | Updaters separados quebram `[workspace X silent]` |
| Alt+Tab via cyclenext (nativo) | hyprshell e hyprswitch incompatíveis com Hyprland 0.55 (formato de endereço IPC mudou de hex para decimal) |
| workspace-float.conf no repo | Estado inicial (`workspace = 5, defaultFloating:1`) propagado via stow em máquina nova |
| Flatpaks em Wayland nativo | Resolve cursor inconsistente e melhora integração com compositor |
| brave-duck.service como systemd user | Persiste entre reinicializações sem intervenção manual |

---

## Licença

MIT
