# Dotfiles

**Status:** active
**Stack:** Hyprland, Waybar, Ghostty, Zsh, Starship, Fuzzel, SwayNC, Hyprlock, Hypridle, swww, PipeWire
**Repo:** https://github.com/cabralcaetano/dotfiles
**Deploy:** Fedora 43 — `~/wiki-ia/personal/projects/dotfiles/` via GNU Stow

## Descrição

Configurações pessoais do ambiente Linux. O repo é a fonte da verdade — GNU Stow cria symlinks do repo para o sistema, então qualquer edição no repo reflete imediatamente nos arquivos do sistema. Para propagar mudanças do GitHub para o sistema é necessário `git pull` manual.

## Fluxo de instalação em máquina nova

```bash
git clone https://github.com/cabralcaetano/wiki-ia ~/wiki-ia
cd ~/wiki-ia/personal/projects/dotfiles
sudo dnf install stow swww
stow --target=$HOME hypr waybar swaync fuzzel scripts ghostty kitty zsh starship gtk-3 gtk-4
```

> O repo fica em `~/wiki-ia/personal/projects/dotfiles/` — não clonar separado em `~/dotfiles`.

## Stack

| Ferramenta | Função |
|---|---|
| Hyprland | Window manager Wayland |
| Waybar | Barra de status |
| SwayNC | Central de notificações |
| Hyprlock | Lockscreen |
| Hypridle | Daemon de idle |
| Fuzzel | App launcher |
| Ghostty | Terminal principal |
| Kitty | Terminal backup |
| Zsh + Starship | Shell + prompt |
| swww | Wallpaper com transições animadas |
| cliphist | Histórico de clipboard |
| rofimoji | Emoji picker via Fuzzel |
| PipeWire | Audio ducking automático |
| eza | `ls` moderno com ícones e suporte a git |
| fzf | Fuzzy finder — integrado ao Zsh (Ctrl+R, Ctrl+T) |
| zoxide | `cd` inteligente com histórico de diretórios |
| yazi | File manager TUI com navegação em colunas |
| lazygit | Git TUI |
| btop | Monitor de recursos |
| zsh-syntax-highlighting | Highlight de comandos em tempo real |
| zsh-autosuggestions | Sugestões baseadas em histórico |
| Spicetify | Customização do cliente Spotify |

## Estrutura do repo

```
hypr/           → hyprland.conf, hypridle.conf, hyprlock.conf, autostart.sh,
                  hyprpaper.conf (referência — sistema usa swww),
                  workspace-float.conf (estado do workspace 5 float mode)
waybar/         → config.jsonc, style.css
swaync/         → config.json, style.css
fuzzel/         → fuzzel.ini
ghostty/        → config
kitty/          → kitty.conf
zsh/            → .zshrc
starship/       → starship.toml
scripts/        → volume.sh, brightness.sh, kb-toggle.sh, power-profile.sh,
                  wifi-menu.sh, wallpaper.sh, wallpaper-toggle.sh, screenshot.sh,
                  workspace-float.sh, alttab.sh
hyprshell/      → config.ron (instalado mas inativo — incompatível com Hyprland 0.55 address format)
gtk-3/          → settings.ini
gtk-4/          → settings.ini
xkb/            → us-br.xkb, install.sh
udev/deprecated → configs antigas (não instalar)
```

## Autostart (boot)

Ordem de inicialização definida no `hyprland.conf`:

| App | Workspace | Método |
|---|---|---|
| waybar, swww-daemon, swaync | — | exec-once imediato |
| hypridle | — | exec-once imediato |
| wallpaper_2.jpg | — | exec-once com sleep 0.5s |
| XDG portals | — | exec-once com sleep 1s |
| GTK dark theme | — | exec-once com sleep 2s |
| brave-browser | 1 | exec-once `[workspace 1 silent]` |
| ghostty | 2 | exec-once `[workspace 2 silent]` |
| obsidian (flatpak) | 2 | exec-once `[workspace 2 silent]` |
| spotify | 3 | exec-once + `autostart.sh` move_when_ready |
| discord | 4 | exec-once + `autostart.sh` move_when_ready |

> Spotify e Discord usam `move_when_ready` no `autostart.sh` porque têm launchers/updaters que quebram o `[workspace X silent]` do exec-once.

## Wallpapers

```
~/.config/wallpapers/
├── wallpaper_1.jpg   — dark waves (preto, abstrato)
├── wallpaper_2.jpg   — default no boot
└── wallpaper_3.png   — terceiro wallpaper no ciclo
```

- **Trocar manualmente:** `wallpaper.sh ~/caminho/imagem.jpg`
- **Ciclar entre os três:** `Super+Shift+W` — alterna 1→2→3→1

## Idle / Lock

Sequência do `hypridle.conf`:

| Timeout | Ação |
|---|---|
| 5 min | hyprlock (tela de bloqueio) |
| 5m30s | monitor apaga (dpms off) |
| 15 min | suspende sistema |
| sleep (lid) | hyprlock ao fechar tampa |

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
| Super+Shift+C | VSCode |

**Janelas**

| Atalho | Ação |
|---|---|
| Super+C | Fecha janela |
| Super+V | Toggle floating |
| Super+Shift+V | Toggle workspace float mode (todas as janelas flutuam + cursor não segue ao Alt+Tab) |
| Alt+Tab | Próxima janela (traz para frente) |
| Alt+Shift+Tab | Janela anterior |
| Super+P | Pseudo-tile |
| Super+J | Alterna split |
| Super+Setas | Move foco |
| Super+Shift+Setas | Swap janelas |

**Sistema**

| Atalho | Ação |
|---|---|
| Super+L | Bloqueia tela |
| Super+Shift+Q | wlogout (menu de energia) |
| Super+M | Sai do Hyprland |
| Super+N | Toggle notificações (SwayNC) |
| Super+Shift+N | Dismiss notificações |
| Super+W | Menu WiFi |
| Super+Shift+W | Alterna wallpaper |
| Super+K | Alterna layout de teclado (ABNT2 ↔ ANSI) |
| Super+. | Emoji picker (rofimoji) |
| Super+S | Toggle scratchpad |
| Super+Shift+S | Move janela para scratchpad |

**Clipboard**

| Atalho | Ação |
|---|---|
| Ctrl+Shift+S | Histórico de clipboard (cliphist + fuzzel) |
| Ctrl+Shift+Del | Limpa histórico do clipboard |

**Screenshots**

| Atalho | Ação |
|---|---|
| Print | Screenshot fullscreen |
| Shift+Print | Screenshot de área selecionada |
| Ctrl+Print | Screenshot para clipboard |

**Workspaces**

| Atalho | Ação |
|---|---|
| Super+1..0 | Vai para workspace 1–10 |
| Super+Shift+1..0 | Move janela para workspace 1–10 |
| Super+Scroll | Navega entre workspaces |

**Mídia e hardware**

| Atalho | Ação |
|---|---|
| XF86AudioRaiseVolume | Volume +5% |
| XF86AudioLowerVolume | Volume −5% |
| XF86AudioMute | Mute áudio |
| XF86AudioMicMute | Mute microfone |
| XF86MonBrightnessUp / F6 | Brilho + |
| XF86MonBrightnessDown / F5 | Brilho − |
| XF86AudioNext/Prev | Faixa seguinte/anterior |
| XF86AudioPlay/Pause | Play/pause |

## Terminal — Ghostty

| Config | Valor |
|---|---|
| Fonte | JetBrainsMono Nerd Font 13pt |
| Tema | Adwaita dark (customizado) |
| Opacidade | 0.85 |
| Blur | `background-blur-radius = 20` |
| Cursor | barra piscante |
| Scrollback | 50.000 linhas |
| `gtk-single-instance` | true — uma única instância, novas janelas abrem como tabs |
| Padding | 12px horizontal, 8px vertical |

## Shell — Zsh

Aliases e ferramentas configuradas no `.zshrc`:

| Alias / Comando | Substitui / Função |
|---|---|
| `ls` | `eza --icons` |
| `ll` | `eza -lah --icons --git` |
| `tree` | `eza --tree --icons` |
| `top` | `btop` |
| `lg` | `lazygit` |
| `python` / `pip` | `python3` / `pip3` |
| `y` | `yazi` com `cd` automático ao sair |
| `copy <cmd>` | Redireciona stdout+stderr para clipboard via `wl-copy` |

**Plugins ativos:**
- `zsh-syntax-highlighting` — highlight de comandos em tempo real
- `zsh-autosuggestions` — sugestões de histórico ao digitar

**Integrações:**
- `pyenv` — gerenciamento de versões Python
- `starship` — prompt
- `zoxide` — `z <dir>` para navegar por histórico de diretórios
- `fzf` — `Ctrl+R` (histórico), `Ctrl+T` (arquivos); preview com `bat`
- `Spicetify` — `~/.spicetify` no PATH

## Perfil de energia

Usa `tuned-adm` via `tuned-ppd` para alternar entre três modos:

| Perfil | Modo tuned |
|---|---|
| Balanceado | balanced |
| Performance | latency-performance |
| Economia | powersave |

Alternância: botão `󰓅` no painel SwayNC (`Super+N`). Indicador aparece na Waybar apenas quando fora do modo balanceado.

## Teclado — Alternância ABNT2 / ANSI

Toggle via `Super+K` entre teclado do notebook (BR ABNT2) e teclado mecânico externo (ANSI US). Ambos usam layout padrão, sem customizações XKB.

## Audio Ducking

Abaixa automaticamente o volume do Spotify quando áudio do navegador toca — comportamento igual ao iPhone. Implementado via script PipeWire + serviço `systemd --user`. Funciona com qualquer app que declare `media.role=phone` (WhatsApp Web, Google Meet, etc.).

Ver guia completo: [[ducking]]

## Window Rules

| App | Regra |
|---|---|
| Overskride (Bluetooth) | Float, 800×500, centralizado |
| pavucontrol (áudio) | Float, 800×500, centralizado |
| Todas as janelas | suppress maximize events |
| XWayland float sem classe | no_focus (fix drag) |

## Scripts customizados

| Script | Função |
|---|---|
| `workspace-float.sh` | Toggle de workspace float mode — flota todas as janelas abertas, novas janelas entram como float, e desativa warp do cursor no Alt+Tab. Lê/escreve `~/.config/hypr/workspace-float.conf` e recarrega o Hyprland. |
| `alttab.sh` | Alt+Tab com `cyclenext` + `bringactivetotop`. Quando workspace float está ativo, preserva a posição do cursor em vez de deixar o Hyprland warpá-lo para o centro da janela. |

## Waybar — módulos ativos

**Esquerda:** ícone Fedora, workspaces (i–x), nome da janela ativa

**Centro:** relógio com calendário no tooltip (clique abre SwayNC)

**Direita:** CPU, RAM, rede, bluetooth, volume, perfil de energia, bateria, tray

## Decisões

- **swww em vez de hyprpaper** — suporte a transições animadas (fade 1.5s/60fps)
- **GNU Stow a partir de `~/wiki-ia/...`** — repo dentro do wiki-ia para centralizar tudo em um único lugar versionado
- **move_when_ready para Spotify/Discord** — `[workspace X silent]` não funciona com apps que têm updater/launcher separado
- **Sem windowrulev2 de workspace** — workspace rules no `exec-once` são apenas para o boot; depois o usuário tem controle total
- **Sem autostart via `~/.config/autostart/`** — os `.desktop` do GNOME foram deletados, tudo gerenciado pelo Hyprland
- **Alt+Tab via cyclenext em vez de hyprshitch/hyprswitch** — hyprshell e hyprswitch incompatíveis com Hyprland 0.55 (formato de endereço de janela mudou de hex para decimal na IPC); cyclenext é nativo e confiável
- **workspace-float.conf versionado no repo** — contém o estado inicial (`workspace = 5, defaultFloating:1`); em máquina nova o stow o instala automaticamente

## Notas abertas

- `gesture = 3, horizontal, workspace` no hyprland.conf — sintaxe aparentemente não padrão mas funcionando; investigar se há forma correta
- Starship sem `format` definido — usa default verboso (a discutir em sessão futura)
- `hyprpaper.conf` no repo referencia `default_2.jpg` que não existe — arquivo criado como referência, sistema usa `swww`; ajustar path ou remover se não for usar hyprpaper
- hyprshell `filter_by: [current_workspace]` atualizado mas ainda inativo (incompatibilidade Hyprland 0.55)
