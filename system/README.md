# system/ — configs de `/etc` versionados

Espelha caminhos reais abaixo de `/etc`. **Não é um pacote Stow** — Stow só opera
dentro de `$HOME`. Estes arquivos são instalados manualmente com `install`, mesmo
padrão já usado por `reflector/`.

Por isso `system` fica fora de `STOW_PKGS` em `scripts/.local/bin/_dotfiles-lib.sh`,
declarado lá como exceção conhecida para o `dotfiles-doctor.sh` não acusar drift.

## Conteúdo

| Arquivo | Task | O que resolve |
|---|---|---|
| `etc/default/earlyoom` | ARCH-32 | earlyoom nunca disparava — condição `AND` com swap que nunca é satisfeita em zram |
| `etc/sysctl.d/99-zram.conf` | ARCH-34 | defaults de VM assumem swap em disco; zram precisa de `swappiness` alto e `page-cluster` 0 |
| `etc/systemd/zram-generator.conf` | ARCH-35 | sem `zram-size` explícito o default trava em 4 GB numa máquina de 16 GB |
| `etc/keyd/default.conf` | keyboard | CapsLock normal no tap; Caps+h/j/k/l como setas vim para teclados gerais |
| `etc/keyd/f75.conf` | keyboard | Mesmo layer de setas + correção Alt/Super para AULA F75/Compx (`3554:fa09`, `1d57:fa60`) |

## Instalação

```sh
cd ~/Projects/dotfiles

sudo install -Dm644 system/etc/default/earlyoom            /etc/default/earlyoom
sudo install -Dm644 system/etc/sysctl.d/99-zram.conf       /etc/sysctl.d/99-zram.conf
sudo install -Dm644 system/etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf
sudo install -Dm644 system/etc/keyd/default.conf             /etc/keyd/default.conf
sudo install -Dm644 system/etc/keyd/f75.conf                 /etc/keyd/f75.conf

sudo sysctl --system
sudo systemctl restart earlyoom
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
sudo systemctl enable --now keyd
sudo keyd reload
```

## Verificação

```sh
# earlyoom deve mostrar "swap free <= 100.00%" (condição neutralizada)
journalctl -u earlyoom -n 5 --no-pager

# devem retornar 180 / 0 / 125 / 0
sysctl vm.swappiness vm.page-cluster vm.watermark_scale_factor vm.watermark_boost_factor

# DISKSIZE deve ser ~8G
zramctl

# keyd deve estar ativo e configs válidas
systemctl is-active keyd
keyd check /etc/keyd/default.conf /etc/keyd/f75.conf
```

## Contexto

Auditoria de 2026-07-25. Diagnóstico completo e provas em
`wiki-ia/personal/projects/arch-migration/_tasks.md`, Fase 12 (ARCH-32 a ARCH-40).
