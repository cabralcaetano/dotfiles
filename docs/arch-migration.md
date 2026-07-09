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

## 3. Assets com dummies/placeholders esquecidos

Alguns arquivos binários (não versionados no git, ou versionados mas nunca reaplicados) ficaram como placeholder de 4KB depois da migração — as configs apontavam certo, só o conteúdo real nunca foi copiado do Fedora.

| Asset | Onde | Sintoma |
|---|---|---|
| `~/.config/wallpapers/wallpaper_{1,2,3}.{jpg,png}` | não versionado no dotfiles (fica fora do repo) | Wallpapers reais copiados do Fedora via `/mnt/fedora-home` (ver §5) |
| `/usr/share/sddm/themes/silent/backgrounds/wallpaper_3.png` | asset do tema SDDM, fora do repo (`/usr/share`) | Tela de login usava um placeholder cinza de 4KB em vez do wallpaper real — corrigido copiando `~/.config/wallpapers/wallpaper_3.png` pro tema |

## 4. Repo movido pra `~/Projects/dotfiles`

O repo não fica mais direto em `~/dotfiles` — está em `~/Projects/dotfiles` (pasta `Projects` criada pelo `xdg-user-dirs-update` em inglês, ver §6). Os symlinks foram recriados com `stow --restow --target="$HOME"` rodando de dentro do novo caminho — o `stow` recalcula os caminhos relativos sozinho, não precisa editar cada symlink manualmente.

> Atenção: se o `~/.config/hypr/hyprland.conf` for removido enquanto o Hyprland está rodando, ele regenera sozinho um stub (`autogenerated = 1`) no lugar quase instantaneamente. Ao recriar o symlink manualmente, faça `rm` seguido de `ln -sf` no mesmo comando (sem gap) pra não perder a corrida.

## 5. GRUB não lista mais o Fedora (sem apagar nada)

Depois da migração, rodamos `grub-mkconfig` com o `os-prober` ativo (`GRUB_DISABLE_OS_PROBER=false`) — ele só detectou o **Windows Boot Manager**, não o Fedora (motivo exato não investigado, possivelmente o layout de subvolumes Btrfs do Fedora confunde o prober). Resultado: o menu do GRUB ficou limpo (Arch + Windows) sem precisar apagar a partição do Fedora, que continua intacta em disco. `GRUB_TIMEOUT_STYLE` trocado de `menu` pra `countdown` — boot automático no Arch, `ESC` mostra o menu completo se precisar.

## 6. Pastas XDG recriadas em inglês

O sistema nunca teve `~/Imagens`, `~/Documentos` etc. criados (só `~/Downloads` existia). Rodamos `LC_ALL=C xdg-user-dirs-update --force` pra gerar tudo em inglês (`Desktop`, `Documents`, `Downloads`, `Music`, `Pictures`, `Projects`, `Public`, `Templates`, `Videos`) + `~/Pictures/Screenshots` manual. `screenshot.sh` atualizado de `~/Imagens/Screenshots` pra `~/Pictures/Screenshots`.

## 7. Bug achado no caminho: `sed -i` quebra symlinks

`scripts/.local/bin/workspace-float.sh` usava `sed -i` (sem `--follow-symlinks`) pra editar `workspace-float.conf`. Como esse arquivo é um symlink pro dotfiles, o `sed -i` padrão do GNU sed recria o arquivo (grava num temp + `rename`) em vez de escrever através do link — isso **desconecta o symlink**, virando um arquivo real desincronizado do repo. Corrigido com `sed -i --follow-symlinks`. Vale revisar outros scripts do repo que usam `sed -i` em arquivos que são symlinks.

## 8. Coisas ainda pendentes de portar pra Arch

- `docs/system-setup.md` (dnf tuning) é Fedora-específico — não tem equivalente Arch ainda (snapper/grub-btrfs já documentados na seção 1.2 acima).
- `packages/pacman.txt` e `packages/aur.txt` existem mas não são regenerados automaticamente — atualizar manualmente quando instalar algo novo relevante.
