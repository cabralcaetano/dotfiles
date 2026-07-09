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

## 1.2 Snapshots Btrfs — snapper + grub-btrfs (já configurado, layout diferente do Fedora)

Ao contrário do que o item 3 antigo deste doc dizia, isso **já foi feito** durante a instalação do Arch — não ficou pendente. Layout mais simples que o do Fedora (`docs/system-setup.md`), porque o Arch não aninha `.snapshots` dentro do subvolume raiz.

**Layout Btrfs** (`nvme0n1p8`):

```
findmnt -no SOURCE,TARGET,OPTIONS /
/dev/nvme0n1p8[/@]      /       subvol=/@
/dev/nvme0n1p8[/@home]  /home   subvol=/@home
```

`@` e `@home` são subvolumes irmãos (não aninhados como o `root`/`root/.snapshots` do Fedora) — por isso `/.snapshots` não precisa de entrada própria no `fstab` nem da opção `nofail` que o Fedora exigia.

**snapper:**

```bash
sudo pacman -S snapper
sudo snapper -c root create-config /
sudo snapper -c root set-config \
  TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
  TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0 \
  NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo snapper -c root create -d "baseline pos-install SDDM+desktop" -c important
```

**grub-btrfs:**

```bash
sudo pacman -S grub-btrfs
sudo systemctl enable --now grub-btrfsd.service   # daemon — não é grub-btrfs.path como no Fedora
sudo grub-mkconfig -o /boot/grub/grub.cfg          # gera o submenu "Arch Linux snapshots"
```

No Arch o pacote `grub-btrfs` já vem com o serviço certo pronto (`grub-btrfsd.service`, monitora `/.snapshots` e regenera `/boot/grub/grub-btrfs.cfg` sozinho a cada novo snapshot) — não precisa do COPR nem dos ajustes de path que o Fedora (`docs/system-setup.md`) exigia.

**Status atual** (verificado em produção):

```
$ sudo snapper -c root list
0 │ single │ current
1 │ single │ 2026-07-09 00:57:44 │ important │ baseline pos-install SDDM+desktop
2 │ single │ 2026-07-09 01:00:02 │ timeline  │ timeline
3 │ single │ 2026-07-09 02:00:00 │ timeline  │ timeline

$ systemctl is-active snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service
active
active
active
```

**Recuperação:** reinicie → menu do GRUB → submenu **"Arch Linux snapshots"** → escolhe o snapshot. Como o layout é flat (sem aninhamento), o rollback aqui tem menos ressalvas que o do Fedora.

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
- `docs/system-setup.md` (dnf tuning) é Fedora-específico — não tem equivalente Arch ainda (snapper/grub-btrfs já documentados na seção 1.2 acima).
