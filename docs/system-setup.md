# System Setup — configs de sistema (fora do stow)

Estes ajustes vivem em `/etc`, no bootloader e no `fstab` — são **system-wide**, exigem root e **não** são gerenciados pelo `stow` nem pelo `bootstrap.sh`. Este documento existe para reproduzi-los numa máquina nova.

Aplicado em: Fedora 44 · Btrfs · GRUB 2.12 (UEFI) · dnf5.

---

## 1. dnf tuning

Acelera downloads e remove prompts repetitivos.

```bash
sudo cp -n /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
sudo tee -a /etc/dnf/dnf.conf >/dev/null <<'EOF'
max_parallel_downloads=10
fastestmirror=True
defaultyes=True
EOF
```

| Opção | Efeito |
|---|---|
| `max_parallel_downloads=10` | Até 10 downloads simultâneos |
| `fastestmirror=True` | Ordena mirrors por latência |
| `defaultyes=True` | Prompts assumem `yes` por padrão |

---

## 2. Btrfs snapshots — rede de segurança

Snapshots automáticos do subvolume raiz + boot direto num snapshot pelo menu do GRUB. Inspirado no comportamento padrão do openSUSE / CachyOS.

**Pré-requisito:** raiz em Btrfs. No nosso layout a raiz é o subvol `root` (não `@`):

```
UUID=… / btrfs subvol=root,compress=zstd:1 0 0
UUID=… /home btrfs subvol=home,compress=zstd:1 0 0
```

### 2.1 snapper

```bash
sudo dnf install -y snapper
sudo snapper -c root create-config /          # cria /etc/snapper/configs/root + subvol /.snapshots

# Limites para não encher o disco
sudo snapper -c root set-config \
  TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes \
  TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
  TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0 \
  NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5

# Snapshots automáticos (timeline) + limpeza
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

# Snapshot inicial
sudo snapper -c root create -d "baseline" -c important
```

### 2.2 grub-btrfs (boot num snapshot)

Não está nos repos base do Fedora — vem de um COPR adaptado para os paths do Fedora (`/boot/grub2`, `grub2-mkconfig`).

```bash
sudo dnf install -y dnf5-plugins
sudo dnf copr enable -y kylegospo/grub-btrfs
sudo dnf install -y grub-btrfs

sudo cp -n /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
sudo grub2-mkconfig -o /boot/grub2/grub.cfg     # adiciona submenu "Fedora Linux snapshots"
```

> **Boot do Fedora é BLS:** as entradas de kernel ficam em `/boot/loader/entries/*.conf`, não como `menuentry` no `grub.cfg`. Regenerar o grub.cfg **não** mexe nelas — apenas adiciona o submenu de snapshots.

### 2.3 fstab + grub-btrfs.path

O `grub-btrfs.path` monitora `/.snapshots` e regenera o menu a cada snapshot, mas o systemd exige que `/.snapshots` seja um mountpoint declarado. No layout do Fedora ele é um subvol *aninhado*, então é preciso declará-lo no fstab (mesma solução do openSUSE):

```bash
sudo cp /etc/fstab /etc/fstab.bak
echo 'UUID=<UUID-DA-RAIZ> /.snapshots btrfs subvol=root/.snapshots,compress=zstd:1,nofail 0 0' \
  | sudo tee -a /etc/fstab
sudo findmnt --verify --fstab     # validar ANTES de confiar (fstab quebrado trava o boot)
sudo systemctl daemon-reload
sudo mount /.snapshots

sudo systemctl enable --now grub-btrfs.path
```

> Pegue o UUID com `findmnt -no UUID /`. O subvol é `root/.snapshots` porque `/.snapshots` foi criado dentro do subvol `root`.
>
> A opção **`nofail`** é importante: se o `/.snapshots` falhar ao montar no boot, o sistema continua normalmente em vez de cair em *emergency mode*.

---

## 3. Uso no dia a dia

```bash
# Snapshot manual antes de algo arriscado
sudo snapper -c root create -d "antes do upgrade do kernel" -c important

# Listar
sudo snapper -c root list

# Comparar mudanças entre dois snapshots
sudo snapper -c root status 1..2

# Remover
sudo snapper -c root delete <id>
```

**Recuperação:** se um update quebrar o boot, reinicie → menu do GRUB → **Fedora Linux snapshots** → boote num snapshot (read-only) para recuperar arquivos ou fazer rollback.

> ⚠️ O `snapper rollback` completo foi desenhado para o layout do openSUSE (subvol `.snapshots` separado da raiz). No layout aninhado do Fedora ele serve principalmente como **rede de segurança para recuperar arquivos / bootar num estado anterior**, não como rollback atômico de uma transação.

---

## 4. Reverter

```bash
# dnf
sudo cp /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf

# snapshots
sudo systemctl disable --now snapper-timeline.timer snapper-cleanup.timer grub-btrfs.path
sudo cp /etc/fstab.bak /etc/fstab && sudo systemctl daemon-reload
sudo cp /boot/grub2/grub.cfg.bak /boot/grub2/grub.cfg
# (opcional) sudo dnf remove snapper grub-btrfs
```
