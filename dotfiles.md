# Dotfiles

**Status:** histórico / operacional — não é o source of truth atual
**Stack atual:** Arch Linux, Hyprland, Waybar, Quickshell, Ghostty, Zsh, Starship, Fuzzel, SwayNC, Hyprlock, Hypridle, awww, PipeWire
**Repo:** https://github.com/cabralcaetano/dotfiles
**Deploy atual:** `~/Projects/dotfiles` via GNU Stow

> Source of truth atual: `README.md`. Este arquivo preserva contexto histórico, decisões e incidentes antigos; se houver conflito entre os dois, preferir o `README.md`.

## Descrição

Configurações pessoais do ambiente Linux. O repo é a fonte da verdade — GNU Stow cria symlinks do repo para o sistema, então qualquer edição no repo reflete imediatamente nos arquivos do sistema. Para propagar mudanças do GitHub para o sistema é necessário `git pull` manual.

## Fluxo de instalação em máquina nova

```bash
git clone https://github.com/cabralcaetano/wiki-ia ~/wiki-ia
cd ~/wiki-ia/personal/projects/dotfiles
sudo dnf install stow swww
stow --target=$HOME hypr waybar swaync fuzzel scripts ghostty kitty zsh starship gtk-3 gtk-4 desktop-apps
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
| tmux | copy-mode — seleção/cópia de texto via teclado |
| Zsh + Starship | Shell + prompt |
| swww | Wallpaper com transições animadas |
| cliphist | Histórico de clipboard |
| rofimoji | Emoji picker via Fuzzel |
| PipeWire | Audio ducking automático |
| eza | `ls` moderno com ícones e suporte a git |
| fzf | Fuzzy finder — integrado ao Zsh (Ctrl+R, Ctrl+T/Ctrl+F, Alt+C/Alt+G) |
| zoxide | `cd` inteligente com histórico de diretórios |
| yazi | File manager TUI com navegação em colunas |
| lazygit | Git TUI |
| btop | Monitor de recursos |
| neofetch | System info no terminal — ASCII aleatório + info completa (config versionada) |
| fastfetch | System info alternativo (mais rápido) — instalado, usado junto com neofetch |
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
quickshell/     → clock-panel/shell.qml
fuzzel/         → fuzzel.ini
ghostty/        → config
kitty/          → kitty.conf
zsh/            → .zshrc
starship/       → starship.toml
neofetch/       → config.conf + ascii/ (skull, char, arch — sorteados a cada run)
scripts/        → volume.sh, brightness.sh, kb-toggle.sh, power-profile.sh,
                  wifi-menu.sh, wallpaper.sh, wallpaper-toggle.sh, screenshot.sh,
                  workspace-float.sh, alttab.sh
hyprshell/      → config.ron (instalado mas inativo — incompatível com Hyprland 0.55 address format)
gtk-3/          → settings.ini
gtk-4/          → settings.ini
qt6ct/          → qt6ct.conf + colors/dotfiles-dark.conf (tema dark para apps Qt6)
desktop-apps/   → mimeapps.list + .desktop/ícones de apps instalados manualmente
                  (fora do dnf/flatpak), ex: Antigravity IDE/2.0
xkb/            → us-br.xkb, install.sh
udev/deprecated → configs antigas (não instalar)
```

## Autostart (boot)

Ordem de inicialização definida no `hyprland.conf`:

| App | Workspace | Método |
|---|---|---|
| waybar, quickshell clock-panel, swww-daemon, swaync | — | exec-once imediato |
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
| Super+N | Abre/fecha painel do relógio (Quickshell) |
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
| Scroll via teclado | `Ctrl+Shift+↑/↓` (linha a linha); `Shift+PageUp/PageDown` (página, default) |
| Seleção via teclado | `Shift+Setas` — estende seleção a partir do cursor (default do Ghostty, `adjust_selection`). Só ajusta seleção existente, não cria uma do zero — para seleção livre iniciada 100% via teclado, ver tmux abaixo |

## Terminal — tmux (copy-mode)

Camada opcional dentro do Ghostty/Kitty para selecionar e copiar texto de qualquer trecho da tela/scrollback **100% via teclado**, sem mouse e sem abrir nenhum app externo (nvim, etc.). Motivo: nem Ghostty nem Kitty têm um "copy-mode" nativo capaz de iniciar seleção livre do zero pelo teclado — é uma limitação conhecida de ambos os terminais.

| Atalho (dentro do tmux) | Ação |
|---|---|
| `Ctrl+B` `[` | Entra em copy-mode (default do tmux) |
| `Alt+C` | Atalho direto pra copy-mode, sem prefixo |
| `h/j/k/l` ou setas | Navega |
| `c` | Inicia seleção |
| `v` | Copia seleção para o clipboard sem sair do copy-mode |
| `y` | Copia seleção para o clipboard do sistema (`wl-copy`) e sai do copy-mode |
| Scroll do mouse (rodinha) | Sobe/desce o histórico do pane igual navegador — entra em copy-mode por baixo dos panos (`copy-mode -e -H`) mas volta sozinho ao normal no final; indicador de posição escondido |
| Arrastar o mouse + soltar | Marca a seleção **dentro do tmux** (copy-mode, via `MouseDrag1Pane` — indicador de posição escondido com `-H`); não copia sozinho, aperta `y` (ou `v`) depois |
| `Shift` + arrastar | Seleção **nativa do Ghostty**, sem passar pelo tmux/copy-mode em nenhum momento — `Shift` é o modificador universal que os terminais (Ghostty incluso) usam pra ignorar o app e fazer seleção própria, mesmo com `mouse on` no tmux. Copiar com `Ctrl+Shift+C` (atalho nativo do Ghostty). Não precisou mudar nada na config — já funciona assim por padrão. |

`mode-keys vi` ativo — usa os motions padrão do vim dentro do copy-mode. Config em `tmux/.config/tmux/tmux.conf`. Não inicia automaticamente — rodar `tmux` manualmente quando precisar.

**Persistência de sessão (resurrect/continuum):** plugins `tmux-resurrect` + `tmux-continuum` instalados (`continuum-restore on`, `resurrect-capture-pane-contents on`) e testados — `save.sh` rodado direto (sem precisar de `prefix + I` na sessão real) confirmou snapshot criado com sucesso, incluindo captura do conteúdo dos panes. Salva a sessão a cada 15min e restaura automaticamente ao abrir o tmux de novo (ex.: depois de desligamento inesperado). Path de instalação real é `~/.config/tmux/plugins/` (XDG), não `~/.tmux/plugins/` — há uma variável de ambiente `TMUX_PLUGIN_MANAGER_PATH` redirecionando, origem não rastreada; resurrect também salva em `~/.local/share/tmux/resurrect/` (XDG data), não no `~/.tmux/resurrect` clássico.

### Navegação/gestão de janelas (abas)

| Atalho | Ação |
|---|---|
| `Ctrl+T` | Nova janela |
| `Ctrl+W` | Fecha a janela atual |
| `Ctrl+Shift+T` | Reabre a última janela fechada — restaura diretório e reroda o comando em foreground, **só se ele ainda estivesse rodando** no momento do `Ctrl+W` (não recupera comandos rápidos já terminados, tipo `neofetch`; funciona bem com `htop`, `vim`, `sleep`, `ssh` etc.) |
| `Alt+1..9,0` | Vai direto pra janela 1–10 |
| `Alt+Shift+1..9,0` | Reordena: move/troca a janela atual pro slot N |

**Trade-off aceito:** `Ctrl+T`/`Ctrl+W` sem shift tomam o lugar do `unix-word-rubout` do readline (apagar palavra anterior no prompt) — decisão consciente do usuário, que não usa esse atalho.

**Conflito confirmado com fzf:** `Ctrl+T` (file widget) e `Alt+C` (cd fuzzy, este último criado nesta mesma sessão pelo bind de copy-mode) do fzf ficam presos pelo `-n` do tmux e nunca chegam no shell. Resolvido com atalhos extras no `.zshrc`: `Ctrl+F` (file widget) e `Alt+G` (cd fuzzy) — aliases pros mesmos widgets, os originais continuam intactos fora do tmux.

**Mecanismo do reabrir (`Ctrl+Shift+T`):** `Ctrl+W` roda `tmux-close-window.sh` (empilha diretório + comando completo, lido de `/proc/<pid>/cmdline` já que `#{pane_current_command}` só dá o nome do processo sem argumentos) antes do `kill-window`; `Ctrl+Shift+T` roda `tmux-reopen-window.sh`, que desempilha e recria a janela. Pilha em `~/.tmux/closed-windows.stack`, delimitador `\x1f` (unit separator) — **não usar `\t`**: bash trata tab como "IFS whitespace" e colapsa campos vazios entre delimitadores repetidos, quebrando o caso de janela idle (sem comando).

## tmux-animated (experimental)

Fork do tmux com animações reais (github.com/jonaburg/tmux-animated) — patch em cima do tmux upstream que anima troca de janela (conteúdo desliza + destaque da aba na status bar), split, resize e close de pane. Instalado como binário **separado** em `~/.local/bin/tmux-animated` (não substitui o `tmux` normal, sem alias — decisão consciente do usuário: roda manualmente por enquanto, `tmux` continua sendo o binário padrão pro dia a dia).

**Riscos conhecidos, aceitos pelo usuário:** projeto pequeno (25 estrelas, 0 forks), última atualização de código real mais de um mês atrás na data da instalação; sync automático com upstream tmux estava quebrado pras últimas 3 releases (3.7, 3.7a, 3.7b) — o binário instalado roda sobre uma base ~3.6b, atrás da versão oficial 3.7b do sistema. Já teve um bug de seg fault no `kill-window` (fechado/corrigido, mas mostra instabilidade histórica justamente na ação mais usada do fluxo, o `Ctrl+W`).

**Config separada:** `tmux/.config/tmux/tmux-animated.conf` — carregada só via `tmux-animated -f ~/.config/tmux/tmux-animated.conf ...`, nunca pelo `tmux` normal. Faz `source-file` do `tmux.conf` principal (todo bind compartilhado já vale nos dois automaticamente) e:

- Desliga animação por padrão (`animation-window-switch off`, `animation-status-highlight off`) — `Alt+N` (troca de janela normal) fica sem efeito, igual o tmux normal.
- `Alt+Shift+N` (reordenar) roda `tmux-swap-window-animated.sh <slot>`: liga a animação, faz o swap, dá uma "espiada" rápida na janela que foi deslocada (que ficou no índice antigo) e volta, desliga a animação de novo. Necessário porque `swap-window`/`move-window` só realocam índice — o conteúdo exibido não muda, então o tmux-animated não tem "troca" pra animar sozinho; a espiada força esse "troca" artificialmente.
- **Por que não ficou tudo dentro de `if-shell` no `tmux.conf` direto:** `#{window_index}` (e formatos em geral) só expandem dentro de comandos com expansão explícita (`run-shell`, `display-message -F`, a condição `-F` do próprio `if-shell`) — dentro da *ação* de um `if-shell`/`se-shell`, o `#{}` não expande e vira "syntax error" em runtime (não no load da config, só ao disparar o bind). Por isso virou um script dedicado.

**Teste:** sessão isolada com socket próprio, pra não misturar com a sessão real: `tmux-animated -L test -f ~/.config/tmux/tmux-animated.conf new-session`.

**Iniciar no boot:** `tmux-continuum` tem `@continuum-boot`, mas resolve o binário via `command -v tmux` fixo — não dá pra apontar pro `tmux-animated`. Em vez disso, service systemd user dedicado: `scripts/.config/systemd/user/tmux-animated.service`, habilitado via symlink versionado em `default.target.wants/` (mesmo padrão do `brave-duck.service`). Sobe uma sessão `main` detached no socket `-L animated` com `tmux-animated.conf`, testado com `systemctl --user start` (confirmado `active (running)`, sessão criada). Anexar: `tmux-animated -L animated attach`.

## System info — neofetch + fastfetch

Ambos instalados e em uso. `fastfetch` fica no default (mais rápido, sem config versionada). O `neofetch` é o customizado — config versionada em `neofetch/.config/neofetch/`.

**ASCII aleatório:** a cada execução o `neofetch` sorteia uma arte de `~/.config/neofetch/ascii/`:

| Arquivo | Arte |
|---|---|
| `skull.ascii` | Caveira |
| `char.ascii` | Personagem em braille |
| `arch.ascii` | Logo padrão do Arch |

O sorteio é feito por uma função `neofetch()` no `.zshrc` que passa `--source` com um arquivo aleatório da pasta. Motivo de não usar o suporte nativo do neofetch a diretório em `image_source`: no backend `ascii` ele não sorteia — pega sempre o primeiro em ordem alfabética. `image_source="auto"` fica como fallback (logo do Arch) para quem chamar `command neofetch`.

Para adicionar mais artes: jogar um `.ascii` novo na pasta (com `${c1}` na primeira linha para herdar a cor do tema) — entra no sorteio automaticamente.

**Info exibida** (`print_info` em `config.conf`), além dos defaults: `Init` (system), `CPU Usage`, temperatura da CPU, `GPU Driver`, `Swap`, `Disk`, `Battery`, `Locale`, `Local IP`, `Users`. Memória e swap em GiB com porcentagem; refresh rate junto da resolução.

`Init` e `Swap` são campos custom via `prin` (não existem como módulo nativo). O `Swap` lê `/proc/meminfo` direto em vez de `free` — o `free` retorna vazio dentro do ambiente do neofetch, e `/proc/meminfo` é independente de locale.

O neofetch detecta `WM: sway` por causa do socket wlroots. O `print_info` corrige isso: quando `HYPRLAND_INSTANCE_SIGNATURE` está setada, força `WM: Hyprland`; fora da sessão Hyprland cai na detecção nativa, então a config continua portátil.

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
- `fzf` — `Ctrl+R` (histórico), `Ctrl+T`/`Ctrl+F` (arquivos), `Alt+C`/`Alt+G` (cd fuzzy); preview com `bat`. `Ctrl+F`/`Alt+G` existem porque `Ctrl+T`/`Alt+C` ficam presos pelo tmux quando dentro de uma sessão (ver seção tmux) — os originais continuam funcionando fora do tmux.
- `Spicetify` — `~/.spicetify` no PATH

## Perfil de energia

Usa `tuned-adm` via `tuned-ppd` para alternar entre três modos:

| Perfil | Modo tuned |
|---|---|
| Balanceado | balanced |
| Performance | latency-performance |
| Economia | powersave |

Alternância: botão `󰓅` no painel SwayNC (`Super+N`). Indicador aparece na Waybar apenas quando fora do modo balanceado.

**Persistência no boot:** `tuned` em modo `manual` grava o último perfil em `/etc/tuned/active_profile` e restaura no boot (sem reset para default). O `default=balanced` de `/etc/tuned/ppd.conf` vale só para clientes PPD, não para o toggle. Fixar boot em Balanceado: `tuned-adm profile balanced`.

## Teclado — Alternância ABNT2 / ANSI

Toggle via `Super+K` entre teclado do notebook (BR ABNT2) e teclado mecânico externo (ANSI US). Ambos usam layout padrão, sem customizações XKB.

## Display manager — greetd + tuigreet

Substituiu o GDM (03/07/2026) — GDM era pesado e o usuário não gostava da experiência. `greetd` + `tuigreet` é o padrão minimalista da comunidade Hyprland: TUI puro, sem dependências GNOME, roda direto na VT.

Config em `greetd/etc/greetd/config.toml` (fora do `$HOME`, não gerenciado pelo Stow — copiar manualmente para `/etc/greetd/config.toml`):

```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --sessions /usr/share/wayland-sessions --theme '...'"
user = "greetd"
```

- `--remember` / `--remember-session` — lembra último usuário e sessão escolhida
- `--sessions /usr/share/wayland-sessions` — lista Hyprland, Hyprland-UWSM, GNOME e GNOME Classic (**F3** abre o menu de sessões, **F2** o de comando, **F12** o de power — defaults do tuigreet)
- `--theme` — **só aceita nomes de cor ANSI, não hex** (`#RRGGBB` é ignorado silenciosamente — foi por isso que o tema não aparecia na primeira versão da config). Paleta monocromática inspirada no `hyprlock.conf`: `border`/`title`/`prompt`/`action`/`button` = `gray` (equivalente mais próximo do cinza `#a0a0a0` do hyprlock), `container` = `black` (equivalente do `#1d1d20`), `text`/`input`/`time`/`greet` = `white`

Rollback: `sudo systemctl enable gdm.service --now && sudo systemctl disable greetd.service --now`

### Incidente — boot travado na primeira tentativa de troca (03/07/2026)

**Sintoma:** ao rodar `systemctl disable gdm.service --now` + `systemctl enable greetd.service --now` em produção, o boot seguinte parou num prompt `fedora login:` clássico (getty). A senha era aceita, mas nenhum shell aparecia depois — só mensagens de kernel rolando na tela.

**Recuperação:** GRUB → editar entrada de boot (tecla `e`) → adicionar `rw init=/bin/bash` ao final da linha `linux`, contornando o systemd. Modo rescue/emergency não funcionou (`sulogin` recusava por causa da conta `root` vir bloqueada por padrão no Fedora Workstation — comportamento normal, não é bug). Também foi possível bootar um snapshot do Timeshift anterior à mudança direto pelo menu do GRUB. No fim, o acesso real que resolveu foi trocar de TTY (`Ctrl+Alt+F2`/`F3`) — outros TTYs funcionavam normalmente com login e sudo, só a TTY1 (onde o greetd/tuigreet estava configurado, `vt = 1`) que travava. Rollback aplicado: `systemctl enable gdm.service --now` + `systemctl disable greetd.service --now`.

**Investigação pós-incidente:**
- Descartado: nenhum script em `.bash_profile`, `.zprofile`, `.bashrc`, `.zshrc` ou `.profile` do usuário tenta iniciar Hyprland automaticamente — não é a causa.
- `journalctl` mostrou 6 reboots em ~47 minutos durante o ciclo de troubleshooting, com `getty@tty1.service` iniciando e parando sozinho em dois deles — consistente com uma **janela sem nenhum display manager ativo na TTY1** durante a troca (o `disable gdm --now` e o `enable greetd --now` não são atômicos; se não emendam no mesmo instante, o systemd sobe o getty clássico nessa lacuna).
- Não há evidência de crash-loop do `tuigreet`/`greetd` em si nos logs (nenhuma entrada de erro repetida da unit `greetd`).
- Conta `root` sem senha (`!` no `/etc/shadow`) é padrão do Fedora Workstation (usa sudo, não login root direto) — não é a causa, só atrapalhou o acesso ao modo rescue/emergency durante o diagnóstico.

**Resolvido (03/07/2026):** segunda tentativa funcionou trocando os dois `--now` separados por `isolate`, que registra os serviços antes de trocar de target, evitando a janela vazia. Ordem importa: `gdm.service` e `greetd.service` compartilham o alias `Alias=display-manager.service` no `[Install]` — `enable` não sobrescreve um alias já existente, então é preciso **desabilitar o GDM antes** de habilitar o greetd (senão dá `Failed to enable unit: File '/etc/systemd/system/display-manager.service' already exists`):

```bash
sudo systemctl disable gdm.service
sudo systemctl enable greetd.service
sudo systemctl isolate multi-user.target
sudo systemctl isolate graphical.target
```

`disable`/`enable` sozinhos (sem `--now`) só mexem no que inicia no próximo boot — não derrubam a sessão atual. A troca de fato só acontece nos dois `isolate` finais.

**Status atual:** greetd + tuigreet em produção, funcionando. Tema aplicado, F3 troca entre sessões (Hyprland, Hyprland-UWSM, GNOME, GNOME Classic), `--remember-session` lembra a escolha.

### Explorando troca para SDDM (em andamento, 03/07/2026)

`tuigreet` é TUI puro — teto de "bonito" baixo (só cores ANSI, sem imagem de fundo/blur). Usuário quer algo mais visual. Avaliado: SDDM (repo oficial Fedora, recomendado), ReGreet (GTK4, mais parecido com a identidade Adwaita do sistema, mas só disponível via COPR de terceiro não confiável — `psoldunov/regreet`, cuja própria página avisa "todo mundo deveria evitar esse repo"; descartado dado o incidente de boot já registrado acima).

**Instalado:** `sddm`, `sddm-breeze`, `sddm-themes` (via dnf, repo oficial — ainda **não** é o display manager ativo, `greetd` continua em produção).

**Config rascunhada** (versionada, ainda não é a definitiva — tema Breeze padrão testado e considerado ruim pelo usuário):
- `sddm/etc/sddm.conf.d/wiki-ia.conf` — `DisplayServer=wayland`, tema `breeze`, `SessionDir=/usr/share/wayland-sessions`, lembra último usuário/sessão
- `sddm/usr/share/sddm/themes/breeze/theme.conf.user` — override sem sobrescrever o pacote: sem logo, relógio visível, cor de destaque `#a0a0a0`, fundo = wallpaper do sistema copiado para `/usr/share/backgrounds/wiki-ia-wallpaper.jpg` (necessário porque o usuário `sddm` não consegue ler `$HOME`, que é `710`)

**Testado com segurança:** `sddm-greeter-qt6 --test-mode --theme <path>` abre o greeter como uma janela normal dentro da sessão Wayland atual — não precisa trocar de VT nem tocar no display manager ativo pra pré-visualizar. Bem mais seguro que o método usado para testar o tuigreet (`greetd --config ... --vt N` numa VT livre).

**Próximo passo (superado):** escolher um preset pronto em vez de customizar o Breeze na mão. Opções levantadas: [Sugar Candy](https://github.com/MarianArlt/sddm-sugar-candy), [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme), [pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm). Catálogos: [KDE Store](https://store.kde.org/browse?cat=101&ord=latest), [awesome-sddm](https://github.com/nulladmin1/awesome-sddm). Usuário escolheu **[SilentSDDM](https://github.com/uiriansan/SilentSDDM)** (uiriansan) — tema QML, Qt6, altamente customizável (200+ opções), presets prontos (Nord, Catppuccin, Everforest, etc.), blur nativo no fundo.

### SilentSDDM — tema escolhido e instalado (03/07/2026)

**Instalação** (manual, fora do dnf — repo clonado e copiado para `/usr/share/sddm/themes/silent/`, não gerenciado por pacote):

```bash
sudo dnf install -y qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia qt6-qtimageformats git
git clone -b main --depth=1 https://github.com/uiriansan/SilentSDDM
sudo mkdir -p /usr/share/sddm/themes/silent
sudo cp -rf SilentSDDM/. /usr/share/sddm/themes/silent/
sudo cp -r /usr/share/sddm/themes/silent/fonts/{redhat,redhat-vf} /usr/share/fonts/
```

**Config** (`sddm/etc/sddm.conf.d/wiki-ia.conf`, atualizada — substitui a versão com tema `breeze`):
- `Theme.Current = silent`
- `General.InputMethod = qtvirtualkeyboard` + `GreeterEnvironment = QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard` (exigido pelo tema — `InputMethod` sozinho não seta `QT_IM_MODULE` automaticamente)

**Switch de produção concluído (03/07/2026):** `greetd` → `sddm`, mesmo procedimento seguro já validado (`disable greetd` antes de `enable sddm` por causa do conflito de `Alias=display-manager.service`, seguido de `systemctl isolate multi-user.target` + `graphical.target`). Sem incidentes dessa vez — SDDM é o display manager ativo.

**Customização do tema — versão final** (preset `default.conf`, editado direto em `/usr/share/sddm/themes/silent/configs/default.conf` — cópia de referência versionada em `sddm/silent-theme/default.conf`), buscando reproduzir o visual do `hyprlock.conf`:

- Background do `LockScreen` e `LoginScreen`: `wallpaper_3.png` (wallpaper do próprio usuário, copiado para `/usr/share/sddm/themes/silent/backgrounds/wallpaper_3.png`). `blur = 24`, `brightness`/`saturation = 0.0` — **cuidado:** valores altos de blur (testado com 64) numa imagem escura/baixo contraste borram tudo até virar preto sólido, parece que "não tem imagem" quando na verdade só está sobre-borrada.
- Cores: cinza `#A0A0A0` (igual ao `col.active_border`/`check_color` do hyprlock) pra bordas/labels, `#1D1D20` (igual ao `inner_color`) pros fundos dos painéis, branco puro pro texto/relógio — sem nenhum azul (paleta 100% monocromática, como o hyprlock)
- Fonte: `JetBrainsMono Nerd Font` em todos os componentes
- Clock (`LockScreen.Clock`): `font-size = 64`, branco — igual ao label `$TIME` do hyprlock. **Só aparece na "lock screen" inicial** (tela de "pressione qualquer tecla"), antes de qualquer input — clicar na janela pra focar já conta como tecla pressionada e pula direto pra "login screen" (avatar+senha, sem relógio). Isso é uma limitação estrutural do tema (duas telas), não um bug.
- `PasswordInput`: `width=280, height=48` (idêntico ao `input-field` do hyprlock), `border-radius-left/right=24` (pill), borda cinza 1px, fundo `#1D1D20` com `background-opacity=0.5` (mais translúcido que o padrão do tema, que era `0.93`)
- `Avatar`: `active-size=140, inactive-size=100` — bem maior que o padrão do tema (120/80), a pedido do usuário
- `WarningMessage`: `error-color = #FF6464` (vermelho, igual ao `fail_color` do hyprlock), `warning-color = #FFCC00` (amarelo, igual ao `capslock_color`)
- Senha mascarada: dots (`●`) com `font.letterSpacing: 4` — **exige patch direto no QML** (`components/Input.qml`, linha do `font.pixelSize`), não é exposto em `default.conf`. Cópia de referência versionada em `sddm/silent-theme/components/Input.qml`.

**Ícones — trocados para Tabler Icons** (`sddm/silent-theme/icons/`), a pedido do usuário (estilo, não só tamanho/cor):

- Baixados de `github.com/tabler/tabler-icons` (outline set) substituindo os SVGs originais do tema com **o mesmo nome de arquivo** (`password.svg`, `arrow-right.svg`, `keyboard.svg`, `language.svg`, `power.svg`, etc.) — não precisou tocar em QML pra isso.
- **Bug encontrado e corrigido:** os SVGs do Tabler usam `stroke="currentColor"`, que o Qt resolve para **preto puro** (luminância 0) por padrão. O efeito de colorização do tema (`MultiEffect.colorization`) preserva a luminância da imagem original e só substitui o matiz — luminância zero não vira branco não importa a cor de destino, então os ícones ficavam pretos/invisíveis sobre fundo escuro. Fix: `sed -i 's/stroke="currentColor"/stroke="#ffffff"/'` em todos os SVGs baixados (e `fill="currentColor"` → `fill="#ffffff"` no único ícone do estilo "filled", `shift-fill.svg`).
- **Ícone de sessão do GNOME trocado** (`icons/sessions/gnome.svg`) — Tabler não tem logos de distro/DE, usado o ícone `layout-grid` (grade 2x2) como substituto neutro, mesmo formato dos demais ícones de sessão (`fill="#fff"`, `width/height=15`, `viewBox 0 0 24 24`).

**Sessões filtradas — sem Plasma:** instalar `sddm-breeze`/`sddm-themes` puxou o **KDE Plasma inteiro** como dependência (pacotes `plasma-desktop`, `plasma-workspace`, etc.), incluindo `plasma.desktop` em `/usr/share/wayland-sessions/`, que passou a aparecer na lista de sessões sem o usuário ter pedido. Resolvido sem desinstalar Plasma (risco desnecessário) — criada uma pasta `/usr/share/sddm/wiki-ia-sessions/` com symlinks só para as sessões desejadas (`hyprland.desktop`, `hyprland-uwsm.desktop`, `gnome.desktop`, `gnome-classic.desktop`), e `Wayland.SessionDir` em `sddm/etc/sddm.conf.d/wiki-ia.conf` apontado pra lá em vez de `/usr/share/wayland-sessions` diretamente.

**Testado em cada iteração com `--test-mode`** (`sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/silent`, com `QML2_IMPORT_PATH` setado) — abre como janela normal na sessão Wayland atual, sem precisar trocar de VT nem mexer no display manager ativo. Método seguro usado durante toda a iteração de design.

**Status atual:** SDDM + SilentSDDM em produção, validado visualmente pelo usuário. Nenhum incidente na troca desta vez.

### Bug — Alt/Super trocados (teclado mecânico Compx/AULA F75)

**Sintoma (03/07/2026):** no teclado mecânico externo (receptor `Compx 2.4G Wireless Receiver`, vendor `3554` product `FA09` — mesmo hardware do AULA F75), a tecla física Alt passou a gerar o scancode de Super (`Super_L`) e vice-versa. Apareceu do nada, sem mudança de config prévia — `kb_options` estava só com `compose:rctrl` e não havia nenhuma regra `udev`/`hwdb` ou variant XKB customizado instalado no sistema (`/etc/udev/hwdb.d/` vazio, variant `us-br` não instalado). Causa raiz não identificada — suspeita de firmware do receptor 2.4G ou da própria mecânica (já houve outro remap de firmware nesse mesmo hardware, ver `udev/deprecated/90-aula-rctrl-altgr.hwdb`, hoje sem uso).

**Diagnóstico:** confirmado via `wev` — tecla física Alt emitindo `sym: Super_L` (keycode 133 / evdev `KEY_LEFTMETA`).

**Fix:** adicionada opção XKB padrão `altwin:swap_alt_win` em `kb_options`, que troca Alt↔Super em nível de software (compositor), efetiva independentemente da causa real ser firmware ou não.

```
kb_options = compose:rctrl, altwin:swap_alt_win
```

**Notas abertas:** se o bug reaparecer trocado de novo (ex: firmware "corrigir" sozinho após reconexão do receptor), essa opção passaria a *causar* o problema em vez de corrigi-lo — reavaliar com `wev` antes de assumir que a causa é a mesma.

**Histórico:**
- **03/07/2026** — bug detectado, `altwin:swap_alt_win` adicionado (commit `29ae784`).
- **05/07/2026** — opção removida **acidentalmente** dentro de um commit de docs sobre `tuned` (`586578e`), cuja mensagem não menciona teclado. O sintoma de Alt/Super trocados voltou.
- **06/07/2026** — `altwin:swap_alt_win` readicionado após confirmação de que as teclas estavam trocadas novamente. Fix ativo de novo.

## Tema — GTK e Qt

**GTK:** `adw-gtk3-dark` + `color-scheme: prefer-dark`, aplicado por `gtk-3/settings.ini`, `gtk-4/settings.ini` e dois `gsettings` no autostart do Hyprland.

**Qt6:** `QT_QPA_PLATFORMTHEME=qt6ct` já vinha setado em `hyprland.conf`, mas **sem `~/.config/qt6ct/qt6ct.conf` o qt6ct cai no default claro** — era por isso que o `hyprland-share-picker` (o seletor de tela do `xdg-desktop-portal-hyprland`, que é Qt6 Widgets) abria em branco no meio de um desktop todo dark. O pacote stow `qt6ct/` corrige:

- `qt6ct.conf` — `style=Fusion`, `custom_palette=true`, `icon_theme=Adwaita`, apontando para a paleta abaixo.
- `colors/dotfiles-dark.conf` — paleta dark própria (window `#181819`, base `#1c1c1f`, texto `#e8e8e8`, highlight `#5e81ac`), no formato de 21 roles do qt6ct.

Vale para qualquer app Qt6 sem tema próprio, não só o picker. Kvantum está instalado mas não é usado — `Fusion` + paleta custom resolve sem uma camada extra.

Para testar sem abrir um compartilhamento de tela real: `hyprland-share-picker` roda standalone.

> Qt5 não tem config equivalente aqui (`qt5ct` não instalado). Se algum app Qt5 aparecer claro, é esse o gap.

## Audio Ducking

Abaixa automaticamente o volume do Spotify quando áudio do WhatsApp Web toca no Brave — comportamento igual ao iPhone. Implementado via script PipeWire + serviço `systemd --user`. O ducking só dispara quando o Brave tem áudio ativo **e** há uma janela com "whatsapp" no título visível no Hyprland (outros sites com áudio no Brave não ativam).

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
| `clock-panel-toggle.sh` | Toggle do painel Quickshell do relógio via IPC. |
| `clock-panel-status.sh` | Métricas do painel Quickshell: CPU, MEM, DISK e GPU em barras. |
| `clock-panel-weather.sh` | Tempo atual + previsão das próximas horas para o painel Quickshell. |
| `battery-conservation.sh` | Alterna `Long_Life`/`Standard`; em modo conservação o Lenovo para de carregar em 80%. |
| `tmux-close-window.sh` | Bind de `Ctrl+W` no tmux — empilha diretório + comando completo (via `/proc/<pid>/cmdline`) + nome da janela em `~/.tmux/closed-windows.stack` antes do `kill-window`. |
| `tmux-reopen-window.sh` | Bind de `Ctrl+Shift+T` no tmux — desempilha a última janela fechada e recria no mesmo diretório, rerodando o comando se ainda estava ativo. |
| `tmux-swap-window-animated.sh` | Só em `tmux-animated.conf` (tmux-animated) — bind de `Alt+Shift+N`: liga a animação, faz swap-window com espiada na janela deslocada (força a animação de troca), desliga de novo. |

## Waybar — módulos ativos

**Esquerda:** ícone Fedora, workspaces (i–x), nome da janela ativa

**Centro:** relógio com calendário no tooltip; clique abre painel Quickshell com player, calendário, tempo e status

**Direita:** CPU, RAM, rede, bluetooth, volume, perfil de energia, conservação da bateria, tray, hotspot invisível minúsculo no extremo direito para SwayNC

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
- **Falta o comando `hostname`** — `tmux-resurrect` imprime `hostname: comando não encontrado` (stderr, inofensivo) a cada save, porque `resurrect_dir()` roda `$(hostname)` incondicionalmente. Instalar `inetutils` (`sudo pacman -S inetutils`) resolve, se incomodar.
