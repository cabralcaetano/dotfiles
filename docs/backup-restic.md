# Backup off-site com restic

Estabelecido em 2026-09-10, depois de uma auditoria constatar que **não existia
nenhuma cópia dos dados fora do disco**.

## Por que snapshot não bastava

O `snapper` já roda (`snapper-timeline.timer`, `snapper-cleanup.timer`) e cobre
erro lógico: update ruim, `rm` errado, rollback de pacote. Ele não cobre perda
do dispositivo — e aqui esse risco é maior que o normal:

```
$ btrfs filesystem show
Total devices 2 ... path /dev/nvme0n1p8 / path /dev/nvme0n1p4
$ btrfs filesystem df /
Data, single: total=185.00GiB, used=119.31GiB
```

A raiz é um btrfs de **dois dispositivos** com perfil `Data, single`: não há
redundância, e perder qualquer uma das duas partições destrói o filesystem
inteiro, levando junto todos os snapshots do Snapper.

## Destino

Repositório restic no VPS `contabo`, via SFTP sobre SSH, alcançado pela
Tailscale. O restic cifra no cliente (AES-256 + Poly1305), então o servidor
nunca vê conteúdo em claro e **não precisa ter restic instalado** — basta o
`sftp-server`, que já existe lá.

| Item | Valor |
|---|---|
| Repositório | `sftp:contabo-backup:/srv/backup/restic-archlinux` |
| Host SSH | alias `contabo-backup` em `~/.ssh/config` → `100.122.38.111` (Tailscale) |
| Espaço livre no destino | 51 GB de 96 GB |
| Volume do backup | ~15,5 GiB antes da compressão (de 40 GiB de `$HOME`) |
| Retenção | 7 diários, 4 semanais, 6 mensais, 1 anual |
| Cadência | `restic-backup.timer`, diário, `Persistent=true` |

O alias `contabo-backup` é separado de `contabo` de propósito: mexer no alias
de deploy não pode derrubar o backup.

## Arquivos

| Caminho | Papel |
|---|---|
| `scripts/.local/bin/backup-restic.sh` | Script único: `init`, `backup`, `snapshots`, `check`, `stats`, `forget-dry`, `unlock`, `mount` |
| `scripts/.local/share/restic/excludes.txt` | O que fica de fora (caches, `node_modules`, `.venv`, build, imagens de VM) |
| `scripts/.config/systemd/user/restic-backup.service` | `oneshot`, `Nice=10`, `IOSchedulingClass=idle` |
| `scripts/.config/systemd/user/restic-backup.timer` | `OnCalendar=daily`, `Persistent=true`, jitter de 30 min |
| `~/.config/restic/config` | `RESTIC_REPOSITORY=...` — **não versionado** |
| `~/.config/restic/password` | Senha do repositório, `chmod 600` — **não versionado** |

O script trata "servidor fora do ar", "restic ausente" e "ainda não
configurado" como aviso, não como falha: o timer não fica em estado `failed` só
porque o notebook estava sem rede. Se passarem 3 dias sem backup bem-sucedido,
dispara um `notify-send`.

## Operação

```sh
backup-restic.sh backup       # o que o timer roda
backup-restic.sh snapshots    # lista os pontos de restauração
backup-restic.sh stats        # tamanho real no servidor
backup-restic.sh check        # verifica integridade do repositório
backup-restic.sh forget-dry   # o que a política de retenção apagaria
backup-restic.sh mount        # monta os snapshots em ~/mnt/restic para navegar
```

Restaurar um arquivo é `backup-restic.sh mount` e copiar de `~/mnt/restic`.
Restaurar tudo, numa máquina nova:

```sh
sudo pacman -S restic
mkdir -p ~/.config/restic
echo 'RESTIC_REPOSITORY=sftp:contabo-backup:/srv/backup/restic-archlinux' > ~/.config/restic/config
# recuperar a senha do Bitwarden e gravar em ~/.config/restic/password (chmod 600)
restic restore latest --target /
```

## A senha

A senha do repositório foi gerada localmente e vive só em
`~/.config/restic/password`. **Perder a senha é perder o backup** — não existe
recuperação. Ela precisa estar no Bitwarden (já instalado) ou em outro lugar que
sobreviva à morte deste notebook; o arquivo local não conta, porque ele morre
junto com o disco que o backup existe para substituir.

## Verificação periódica

Backup que nunca foi restaurado não é backup. A cada alguns meses:

```sh
backup-restic.sh check        # integridade
backup-restic.sh mount        # e conferir que um arquivo real abre
```
