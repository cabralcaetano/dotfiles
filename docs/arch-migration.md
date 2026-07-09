# Migração Fedora → Arch Linux

O restante da documentação (README, `docs/system-setup.md`) ainda descreve o setup em Fedora — mantido como referência histórica. Este documento cobre só as diferenças e ajustes feitos na migração para Arch.

Aplicado em: Arch Linux · pacman · gh CLI para auth git.

---

## 1. Pacotes que trocaram de nome/origem

Alguns apps não têm o mesmo nome de pacote/binário no Arch. Os binds e scripts do Hyprland/Waybar/SwayNC apontavam pros nomes antigos (Fedora/dnf/flatpak) e silenciosamente não abriam.

| App | Fedora (antes) | Arch (agora) | Onde quebrava |
|---|---|---|---|
| Discord | binário `Discord` (maiúsculo) | pacote `discord` (AUR), binário `discord` minúsculo | `$discord` em `hyprland.conf`, exec-once do workspace 4 |
| Spotify | binário `spotify` direto | pacote `spotify-launcher`, binário `spotify-launcher` (baixa o client real em `~/.local/share/spotify-launcher/`) | `$spotify` em `hyprland.conf`, exec-once do workspace 3 |
| Overskride (bluetooth) | flatpak `io.github.kaii_lb.Overskride` | pacote nativo AUR `overskride-bin`, binário `overskride` | `on-click` do bluetooth na Waybar e no SwayNC |
| networkmanager-dmenu | binário `networkmanager-dmenu` (hífen) | binário `networkmanager_dmenu` (underscore) — mesmo pacote, nome do binário é diferente | `wifi-menu.sh` |
| pavucontrol | já vinha nos apps do sistema | **não instalado por padrão** — precisa `sudo pacman -S pavucontrol` | `on-click` do pulseaudio na Waybar |
| swww (wallpaper) | pacote `swww`, binários `swww`/`swww-daemon` | não existe no Arch — o pacote é `awww` (fork com CLI compatível), binários `awww`/`awww-daemon` | `exec-once` do daemon e do wallpaper inicial em `hyprland.conf`, `wallpaper.sh`, `wallpaper-toggle.sh` |
| Brave | pacote `brave-browser`, binário `brave-browser` | pacote `brave-bin` (AUR), binário `brave` (o `.desktop` até se chama `brave-browser.desktop`, mas o `Exec=` é `brave`) | `$browser` em `hyprland.conf`, exec-once do workspace 1 |

> Obsidian continua igual (flatpak `md.obsidian.Obsidian` funciona nos dois).

## 1.1 Pacotes que sumiram por completo (não vinham pré-instalados)

Esses não trocaram de nome — simplesmente não estavam instalados no Arch, então os `exec-once`/scripts que dependiam deles falhavam silenciosamente.

| Pacote | Pra que serve | Sintoma sem ele |
|---|---|---|
| `pavucontrol` | mixer de áudio gráfico | ícone de volume na Waybar não abria nada |
| `pyenv` | gerenciador de versões Python | `.zshrc` dava `command not found: pyenv` no login do shell (linha do `eval "$(pyenv init - zsh)"`) |
| `fcitx5-im` (grupo: `fcitx5`, `fcitx5-gtk`, `fcitx5-qt`, `fcitx5-configtool`) | input method — usado só pro compose key (`compose:rctrl` no `kb_options`) | Ctrl direito + tecla não compunha mais acentos/`ç` em nenhum app, principalmente GTK4 (Ghostty) |
| `bun` | runtime JS usado pra buildar plugins Obsidian (ex: `default-zoom-fixer`) | não tinha como buildar plugins Obsidian escritos em TS |
| `fd` | busca de arquivos usada pelo Telescope/LazyVim | Telescope caía pro `find` como fallback (mais lento) |

## 2. Autenticação Git

Fedora não tinha `gh` configurado; no Arch:

```bash
sudo pacman -S github-cli
gh auth login        # web browser, HTTPS
gh auth setup-git     # registra o gh como credential.helper do git
```

## 3. Coisas ainda pendentes de portar pra Arch

- `packages/dnf.txt` ainda é a única lista de pacotes versionada — falta um `packages/pacman.txt` equivalente.
- `bootstrap.sh` ainda assume `dnf`/`stow` a partir de `~/wiki-ia/personal/projects/dotfiles`; no Arch o repo está em `~/dotfiles` direto, sem stow (symlinks manuais em `~/.config`).
- `docs/system-setup.md` (dnf tuning, snapper, grub-btrfs) é Fedora-específico — layout de snapshots no Arch (se adotado) precisa de doc própria.
