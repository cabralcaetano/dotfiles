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

> Obsidian continua igual (flatpak `md.obsidian.Obsidian` funciona nos dois).

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
