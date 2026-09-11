# Auditoria de sistema — 2026-09-10

Varredura completa do repo de dotfiles contra o estado real da máquina. O
sistema estava saudável em runtime (0 unidades falhando, boot userspace 3,2 s,
snapshots Btrfs ativos), mas tinha furos sérios de reprodutibilidade e defeitos
que falhavam em silêncio há meses.

Resultado: 5 commits (`513de39`, `fd6011a`, `7c0fad4`, `0c4ca7f`, `194142b`),
45 arquivos, +1207/−671 linhas.

---

## 1. Não existia backup

**Sintoma.** `snapper-timeline.timer` e `snapper-cleanup.timer` rodando,
`/etc/snapper/backup-configs/` vazio, nenhum `borg|restic|rclone` no sistema
nem nos docs. Dotfiles versionados; documentos, `~/dev`, chaves e bancos locais
em lugar nenhum.

**Por que era pior que o normal.** Snapshot Btrfs não é cópia, é ponteiro: CoW
compartilha os mesmos blocos no mesmo disco. E a raiz aqui é um btrfs de **dois
dispositivos** sem redundância:

```
$ btrfs filesystem show
Total devices 2 ... /dev/nvme0n1p8 ... /dev/nvme0n1p4
$ btrfs filesystem df /
Data, single: total=185.00GiB, used=119.31GiB
```

Os blocos de um mesmo arquivo podem estar divididos entre `nvme0n1p4` e
`nvme0n1p8`. Perder **qualquer uma** das duas partições destrói o filesystem
inteiro e leva os snapshots do Snapper junto.

**Correção.** `restic` para o VPS `contabo`, via SFTP sobre Tailscale. Sem disco
externo: o servidor já existe, está sempre ligado, e o timer diário não depende
de plugar nada. Detalhes em [`backup-restic.md`](backup-restic.md).

| | |
|---|---|
| Origem | 15,1 GiB de `$HOME` (40 GiB brutos, o resto é cache/build) |
| Armazenado | 7,3 GB — compressão de 52% |
| Incremental | 1m08s, 29 MB |
| Retenção | 7 diários, 4 semanais, 6 mensais, 1 anual |

**Verificação.** Não bastou configurar:

```
$ restic check
check snapshots, trees and blobs
[3:07] 100.00%  2 / 2 snapshots
no errors were found

$ restic restore latest --include ~/.ssh/config --include .../README.md
Summary: Restored 7 / 2 files/dirs (47.113 KiB) in 0:00

$ diff <restaurado> <original>
  .ssh/config: IDÊNTICO   (modo 600 preservado)
  README.md:   IDÊNTICO
```

**Dois detalhes que só apareceram rodando.** O primeiro backup saiu com `rc=3`:
o restic **cria** o snapshot e retorna 3 quando não consegue ler algum arquivo.
Eram 490 `permission denied` em `containers/storage` (podman rootless) e
`waydroid/data`, uid-mapped em user namespace e ilegíveis por design. Os dois
foram para o `excludes.txt` e o script passou a tratar `rc=3` como sucesso
parcial com aviso — snapshot válido não pode virar unit em `failed`, mas também
não pode passar em silêncio, porque arquivo ilegível novo significa exclusão
faltando. Segunda rodada: 0 erros, exit 0.

Consequência documentada: volume nomeado do podman com banco de dados precisa
de `podman volume export` para um caminho legível, senão fica silenciosamente
fora do backup.

**A senha** do repositório vive em `~/.config/restic/password` e está no
Bitwarden. Ela morre junto com o disco que o backup existe para substituir —
sem ela os 7,3 GB são ruído cifrado.

---

## 2. Os manifestos não reconstruíam a máquina

`packages/pacman.txt` tinha 123 entradas contra 175 pacotes explicitamente
instalados. Entre os 52 ausentes: **`base`, `base-devel`, `linux`,
`linux-firmware`, `linux-headers`, `intel-ucode`, `mkinitcpio`, `sudo`**.
`aur.txt` tinha 11 contra 15 — faltava o próprio **`yay`**, o instalador do AUR.

Rodar `bootstrap.sh` numa máquina limpa não produzia um sistema que desse boot,
e não havia como instalar o AUR depois.

| Manifesto | Antes | Depois |
|---|---|---|
| `pacman.txt` | 123 | 180 |
| `aur.txt` | 11 | 14 |
| `flatpak.txt` | 28 | 11 |
| `vscode-extensions.txt` | 16 | 25 |

O cabeçalho do `pacman.txt` dizia "não é o dump completo do sistema". Agora é, e
traz o comando de conferência embutido:

```sh
comm -23 <(pacman -Qqen | sort) \
         <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' packages/pacman.txt | sort -u)
```

Sete pacotes seguem no manifesto sem estarem marcados como explícitos (`curl`,
`iproute2`, `iptables`, `libisoburn`, `libvirt`, `edk2-ovmf`, `spice-gtk`):
estão instalados como dependência, são requisitos diretos e documentados
(GoLiveBypass/WireGuard, stack de VM) e listá-los é o que garante que
sobrevivam à remoção do pacote pai.

---

## 3. `~/.zshrc` estava fora do Stow

```
$ stow -n --target=$HOME zsh
WARNING! stowing zsh would cause conflicts:
  * cannot stow .../zsh/.zshrc over existing target .zshrc since neither a link nor a directory
```

Arquivo real, não symlink. Divergia do repo: o home tinha `wdopen`/`wdclose`/
`wdstop` (Waydroid) e `QT_SCALE_FACTOR=1.3`; o repo tinha, no lugar, um
`export OMP_ZSHRC_PROBE=hit` de debug esquecido. Qualquer `stow --restow`
abortava, e um deploy limpo perderia as funções.

O mesmo problema existia no pacote `scripts`: onze arquivos em `~/.local/bin` e
`~/.local/share` sombreavam o repo — seis como arquivo real (`golivebypass`,
`golivebypass-tui`, `media-volume-spotify.sh`, `memhog-watch.sh`, e os dois do
`zen-tab-mover`) e cinco como symlink **absoluto** criado à mão, que o stow se
recusa a gerenciar (`theme-set.sh`, `theme-picker.sh`, `theme-picker-list.sh`,
`fuzzel-toggle.sh`, `hp-wifi-connect.py`). Todos idênticos ao repo exceto
`memhog-watch.sh`. Resolvidos com `--adopt` e restow; `dotfiles-doctor.sh`
passou a dar `tudo certo`.

`zsh/.zshenv` também passou a ser versionado — o `.zshrc` dependia dele para o
PATH base e ele não estava no repo.

---

## 4. Zsh sem sistema de completion

```
$ zsh -i -c 'print ${+functions[compdef]} ${#_comps}'
0 0
```

Não havia `compinit` nenhum. Tab-completion estava degradado a nome de arquivo
puro: sem completar flag de `git`, `systemctl`, `pacman`, `docker`. O
`zsh-autosuggestions` mascarava parte da dor.

Custo medido de cada `eval` de inicialização:

| | |
|---|---|
| `pyenv init - zsh` | **40,1 ms** |
| `fzf --zsh` | 5,8 ms |
| `starship init zsh` | 4,2 ms |
| `zoxide init zsh` | 2,4 ms |
| `_zsh_highlight_load_highlighters` | 12,6 ms (zprof) |

Adicionado `compinit` com cache diário (`-C` quando o dump tem menos de 24 h) e
o `pyenv` virou lazy: `PYENV_ROOT/bin` e `shims` entram no PATH de forma
estática, e `pyenv init` só roda na primeira chamada real de `pyenv`, via
função wrapper que se auto-substitui. Mais `typeset -U path` (havia `~/.bun/bin`
duplicado entre `.zshenv` e `.zshrc`).

| | Antes | Depois |
|---|---|---|
| Startup (mediana) | 145 ms | **101 ms** |
| `_comps` | 0 | **1713** |

Ganho líquido apesar de o `compinit` ser custo novo.

---

## 5. Os portais XDG falhavam em todo login

`hyprland.lua:39-41` executava três binários em `/usr/libexec/`:

```
$ ls -d /usr/libexec
ls: cannot access '/usr/libexec': No such file or directory
```

Arch não tem `/usr/libexec` — os binários estão em `/usr/lib/`. Os três
comandos falhavam silenciosamente desde sempre; screenshare e file picker
funcionavam por acidente, via ativação D-Bus tardia.

As três linhas foram **removidas**, não corrigidas para `/usr/lib/...`: iniciar
o daemon à mão concorre com os units `Type=dbus`. A `hyprland-portals.conf` já
resolvia o backend. Verificação:

```
$ busctl --user call ... org.freedesktop.portal.ScreenCast version   → v u 6
$ busctl --user call ... org.freedesktop.portal.FileChooser version  → v u 4
```

---

## 6. Dois firewalls, e o resultado dependia de ordem de boot

```
ufw        enabled  active
nftables   enabled  inactive (oneshot)
```

`/etc/nftables.conf` não era o default do Arch — foi escrito à mão, com regras
de `virbr0`/`waydroid0`. Ele sobe às 15:54:13, **depois** do ufw às 15:54:12, e
faz `destroy table inet filter`: na prática já era ele que vencia, mas por
acidente de ordenação de unit.

Decisão: ficar só com nftables, ruleset versionado em `system/etc/nftables.conf`.

A regra de SSH era `tcp dport ssh accept`, sem restrição de interface — se o
`sshd` fosse habilitado, ficaria exposto em qualquer rede, inclusive Wi-Fi
público. Virou `iifname "tailscale0" tcp dport ssh accept`.

**Erro cometido e corrigido na mesma sessão.** A primeira versão da regra tinha
`iifname "tailscale0" accept`, confiando na tailnet inteira. A tailnet é
**compartilhada** com outra conta (`r.almeidagustavo@`, dois hosts). Testado a
partir do VPS:

```
antes:  ssh contabo 'bash -c "</dev/tcp/100.106.1.25/8080"'  →  ALCANÇÁVEL
depois: ssh contabo 'bash -c "</dev/tcp/100.106.1.25/8080"'  →  BLOQUEADO
```

Um dev server Vite do `contabil-frontend` estava acessível aos peers. Ficou só
`41641/udp` — sem essa porta o Tailscale não fecha caminho direto e cai no relay
DERP, o que derruba a banda do backup — e SSH por `tailscale0`. O backup é
conexão de saída e passa por `ct state established,related`.

---

## 7. Timer habilitado chamando script não versionado

`memhog-watch.timer` estava commitado, habilitado e disparando a cada 30 s, mas
o `ExecStart=%h/.local/bin/memhog-watch.sh` não existia no repo — só no home.
Um deploy limpo herdaria um timer habilitado falhando duas vezes por minuto.
O script foi versionado.

---

## 8. `bootstrap.sh`

- **TPM duplicado.** O bloco de instalação aparecia duas vezes: uma dentro de
  `if command -v git`, outra fora. Com `set -euo pipefail`, máquina sem git
  abortava ali — apesar de a mensagem anterior dizer que só pularia os plugins.
  O segundo bloco foi deletado.
- **Ramo Fedora.** `detect_distro()` ainda executava `dnf install` consumindo
  `packages/dnf.txt`. Virou `require_arch()`, que falha com ponteiro para o
  histórico. Manifesto movido para `legacy/fedora/dnf.txt`.
- **`--system`** (nova): aplica os arquivos de `/etc` versionados em `system/`
  via sudo. Sem a flag, imprime o bloco pendente. Antes esses ajustes
  (earlyoom, sysctl/zram, keyd) só existiam como comandos manuais no
  `system/README.md` — uma máquina nova ficava sem eles.
- **`--system-only`** (nova): aplica só `/etc` e sai. `--system` roda o
  bootstrap inteiro antes, o que é caro e arriscado numa máquina já
  configurada quando a intenção é só propagar uma mudança em `system/`.

---

## 9. Cutover do roteamento de browser por super workspace

O caminho **ativo** do navegador ainda era o modelo abandonado:
`hyprland.lua:15` definia `browser = "~/.local/bin/browser-super-workspace.sh"`
e `Super+B` usava isso. O `brave-super-workspace.desktop` distribuía um handler
MIME com `Icon=brave-browser` que na verdade executava Zen, e o
`mimeinfo.cache` listava os dois launchers antigos **antes** do `zen.desktop`.

Removidos: `brave-profile.sh`, `chromium-profile.sh`, `brave-super-workspace.sh`,
`browser-super-workspace.sh` e os dois `.desktop`. `Super+B` e o autostart
apontam direto para `~/.local/bin/zen`.

**Brave permanece instalado e em uso** — `brave-bin` segue no `aur.txt`, cache
intacto, lançado pelo `.desktop` do próprio pacote. O que morreu foi só o
roteamento por super workspace, cujos wrappers tinham nome e ícone de Brave mas
executavam Zen.

---

## 10. Display manager duplicado

`display-manager.service` → `sddm.service`. `greetd` e `greetd-tuigreet`
estavam instalados, no manifesto e com config própria em `greetd/`, sem unit
habilitada. Cutover para SDDM: diretório removido do repo, pacotes fora do
manifesto e desinstalados.

---

## 11. Monitor rígido

`hyprland.lua:9` tinha uma regra genérica `output = ""` forçando
`1920x1200@60`, `position 0x0` e `scale 1.25` em **qualquer** saída — quebra ao
conectar HDMI ou dock. Virou regra específica de `eDP-1` com esses valores mais
um fallback genérico `preferred`/`auto`/`scale 1`.

---

## 12. `dotfiles-doctor.sh` acusava drift falso

`known_manual` não listava `browser-extensions/`, `nextdns/`, `themes/`,
`icons/` e `tuned/`, que também não estão em `STOW_PKGS`. Toda execução
reportava módulos legítimos como não declarados, e o verificador de drift virou
ruído. Os cinco foram adicionados com comentário do motivo; `greetd` e `xkb`
(que só existe dentro de `legacy/`) saíram.

---

## 13. Higiene

| Item | Antes | Depois |
|---|---|---|
| Pacotes órfãos | 26 | 0 |
| Pacotes `-debug` | 8 | 0 |
| Journal | 371 MB | 163 MB (`SystemMaxUse=200M`) |
| `libvirtd` | enabled+active, 0 VMs | disabled |
| Conteúdo versionado | 29,5 MB | 21,6 MB |

`libvirtd` custava 622 ms de boot e mantinha um `dnsmasq` em `192.168.122.1:53`
para zero VMs (`virsh list --all` vazio). Reativável com
`systemctl enable --now libvirtd`.

Os 40 pacotes removidos foram simulados antes com `pacman -Rs --print`: zero
quebra de dependência.

**Blobs.** `themes/matte-black/wallpaper.bmp` (6,6 MB) e `preview.bmp` (1,4 MB)
eram bitmap sem compressão. Convertidos para WebP **lossless** (20 KB + 8 KB).
`theme-set.sh:208` usa `find -iname "wallpaper.*"`, então é agnóstico à
extensão, e o `awww` renderiza WebP (testado, exit 0). Os JPEGs grandes ficaram
como estão — já são formato comprimido, e as duplicatas byte a byte entre
`wallpaper.jpg` e `backgrounds/*.jpg` não custam nada no Git, que deduplica
blobs idênticos por SHA.

---

## 14. Paths com identidade do dono

- `clock-panel-status.sh` usava `"$HOME/.local/bin/ai-usagebar"`; substituído por `omp usage --json` no card `sistema`.
- `9router.service` → `%h/.npm-global/bin` no `Environment=PATH` e `ExecStart`
- `install-battery-conservation-root.sh` gravava literalmente `caetano ALL=(root)`
  no sudoers. Agora deriva o usuário de `$1` ou `$SUDO_USER`, recusa root e nome
  com caractere fora de `[a-zA-Z0-9._-]`, e **valida a regra com `visudo -cf`**
  num arquivo temporário antes de instalar — um sudoers inválido quebra o `sudo`
  da máquina inteira.

Os cinco `/home/caetano` restantes ficaram de propósito, em `Exec=`/`Icon=` de
arquivos `.desktop`: a spec freedesktop não expande variável de ambiente.

---

## 15. Documentação contraditória

`dotfiles.md` (59,6 KB) se declarava histórico no cabeçalho mas, vinte linhas
abaixo, mandava clonar o vault `wiki-ia`, entrar em
`~/wiki-ia/personal/projects/dotfiles` e rodar `dnf install ... swww` — distro,
caminho e wallpaper daemon que não existem mais. Virou
[`history/dotfiles-historico.md`](history/dotfiles-historico.md), sem nenhum
bloco de comando executável.

`browser-memory-profiles.md` dizia que os helpers Brave "não foram aplicados";
`hyprland-super-workspaces.md` dizia "implementada e verificada (2026-08-25)".
Os dois no mesmo repo, sobre os mesmos arquivos. O primeiro virou post-mortem
fechado; do segundo saiu a subseção que descrevia os helpers como vigentes.

`system-setup-fedora.md` foi para `history/`. O `.gitignore` ganhou rede de
proteção contra segredos (`*.env`, `*.pem`, `*.key`, `*_rsa`, `*_ed25519`,
`*token*`, `*secret*`, `*credential*`, `*cookies*`, `*session*`) — nenhum
segredo estava versionado, mas não havia barreira nenhuma contra o próximo.

---

## O que foi verificado e estava certo

Não vale só listar o que quebrou:

- **Waybar + Quickshell** não são barras duplicadas — o `qs -c clock-panel` é um
  painel sob `Super+N`, com responsabilidade diferente.
- **Nenhum daemon de notificação concorrente**: só `swaync` instalado, e ele
  detém `org.freedesktop.Notifications`.
- **Theming coerente** entre GTK3/GTK4/Qt6ct/Waybar/Fuzzel/SwayNC/Quickshell via
  `theme-set.sh`.
- **`reflector.timer` e `paccache.timer`** ativos, e `reflector.conf` no repo é
  idêntico ao de `/etc`. Os 369 MB de cache do pacman estão sob controle.
- **`archlinux-keyring-wkd-sync`** leva 6min45, mas é assíncrono e fora do
  caminho crítico do boot. Desabilitar não melhora nada e degrada a validação de
  chaves PGP. **Mantido.**
- **Sem variáveis NVIDIA** inúteis numa Intel; blur em `size=3, passes=1`,
  adequado à UHD.
- **Crashes** de quickshell (15) e waybar (4) são de 19-20/ago, sessão de
  desenvolvimento de tema. Não recorrentes.

---

## Pendências conhecidas

| Item | Nota |
|---|---|
| `rtsx_pci` falha no resume | `Unable to change power state from D3cold to D0`, 33× em 7 dias. Leitor de cartão SD; blacklistar o módulo se não for usado. |
| ACPI `_Q37`/`_Q38` não resolvem | Bug de BIOS, todo boot e resume. Só checar update de firmware. |
| Plugins de tmux/zsh sem pin | `bootstrap.sh` faz `git pull` de TPM e dos três plugins zsh; instalações em datas diferentes resolvem HEADs diferentes. Um lockfile com SHA resolveria. |
| Volumes nomeados do podman | Fora do backup por serem ilegíveis. Precisam de `podman volume export` se guardarem banco de dados. |

---

## Estado final

```
órfãos:             0
pacotes -debug:     0
journal:            163 MB
ufw:                disabled
libvirtd:           disabled
unidades falhando:  0 sistema / 0 usuário
zsh startup:        101 ms
dotfiles-doctor:    tudo certo
backup:             2 snapshots, 7,3 GB no VPS, check sem erros, restore testado
```
