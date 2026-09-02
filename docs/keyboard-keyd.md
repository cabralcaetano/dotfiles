# Teclado — keyd, Caps navigation e AULA F75

Este setup separa duas responsabilidades:

1. **Hyprland/XKB** mantém layout, Compose e atalhos do compositor.
2. **keyd** faz remap system-wide de teclas físicas antes do Hyprland.

O objetivo é ter navegação por `CapsLock+h/j/k/l` sem quebrar:

- `CapsLock` normal no tap, incluindo LED de ligado/desligado;
- `Super+h/j/k/l` do Hyprland para foco de janelas;
- correção Alt/Super do teclado mecânico AULA F75/Compx.

## Arquivos versionados

| Arquivo | Destino real | Papel |
|---|---|---|
| `system/etc/keyd/default.conf` | `/etc/keyd/default.conf` | Regra geral para teclados normais; exclui receptores que precisam correção própria. |
| `system/etc/keyd/f75.conf` | `/etc/keyd/f75.conf` | Regra específica para AULA F75/Compx e receptor compatível `2.4G Wireless Device`. |
| `hypr/.config/hypr/hyprland.lua` | `~/.config/hypr/hyprland.lua` | Layouts `br,us`, `compose:rctrl`, atalhos `Super+h/j/k/l`; `altwin:swap_alt_win` fica como fallback por device. |

`system/` não é pacote Stow. Arquivos abaixo de `/etc` precisam ser instalados manualmente com `sudo install`.

## Comportamento ativo

### Teclados normais

`system/etc/keyd/default.conf`:

```ini
[ids]
*
-k:3554:fa09
-k:1d57:fa60

[main]
capslock = overload(nav, capslock)

[nav]
h = left
j = down
k = up
l = right
```

Resultado:

- tap em `CapsLock` → CapsLock real (`capslock`), LED alterna normalmente;
- hold `CapsLock+h` → `Left`;
- hold `CapsLock+j` → `Down`;
- hold `CapsLock+k` → `Up`;
- hold `CapsLock+l` → `Right`.

Os IDs `k:3554:fa09` e `k:1d57:fa60` são excluídos daqui para não receberem duas configs do keyd.

### AULA F75 / Compx 2.4G

`system/etc/keyd/f75.conf`:

```ini
[ids]
k:3554:fa09
k:1d57:fa60

[main]
capslock = overload(nav, capslock)
leftalt = layer(meta)
leftmeta = layer(alt)

[nav]
h = left
j = down
k = up
l = right
```

Resultado adicional:

- tecla física `Alt` → `Super/Meta` lógico;
- tecla física `Super` → `Alt` lógico;
- corrige o bug de firmware em que o receptor emite Alt/Super trocados.

Uso de `layer(meta)` e `layer(alt)` é intencional. O `keyd check` alerta contra atribuir `leftmeta`/`leftalt` diretamente; camadas preservam semântica de modificador.

## Por que não XKB custom para Caps+h/j/k/l

Foi testado XKB local com:

- `lv3:caps_switch`;
- símbolos customizados em `~/.config/xkb/symbols/caetano`;
- opções `caetano:hjkl_arrows` e `caetano:hjkl_arrows2`.

Funcionou para setas, mas transformou `CapsLock` em tecla de nível/camada. Efeito colateral: `CapsLock` deixou de alternar estado e LED. Como o requisito é manter o LED, XKB custom foi descartado.

## Por que a correção Alt/Super saiu do Hyprland para o keyd

Antes do `keyd`, o Hyprland via o teclado físico e aplicava `altwin:swap_alt_win` por device no AULA F75/Compx.

Depois do `keyd`, o fluxo muda:

```mermaid
flowchart LR
  K[Teclado físico] --> D[keyd]
  D --> V[keyd-virtual-keyboard]
  V --> H[Hyprland]
```

O Hyprland passa a receber o `keyd-virtual-keyboard`, então a correção por `hl.device({ name = ... kb_options = "altwin:swap_alt_win" })` deixa de ser a fonte confiável da correção. A troca Alt/Super precisa acontecer no `keyd`, no config que casa com o vendor/product físico.

A regra do Hyprland continua como fallback documentado caso o `keyd` seja desativado.

## Instalação em máquina nova

```bash
cd ~/Projects/dotfiles

sudo pacman -S --needed keyd
sudo install -Dm644 system/etc/keyd/default.conf /etc/keyd/default.conf
sudo install -Dm644 system/etc/keyd/f75.conf /etc/keyd/f75.conf
sudo systemctl enable --now keyd
sudo keyd reload
```

## Verificação

```bash
systemctl is-active keyd
keyd check /etc/keyd/default.conf /etc/keyd/f75.conf
hyprctl devices -j | jq '.keyboards[] | select(.name == "keyd-virtual-keyboard")'
```

Checks comportamentais:

1. Tap `CapsLock` → LED liga/desliga.
2. Hold `CapsLock+h/j/k/l` → cursor navega por esquerda/baixo/cima/direita.
3. `Super+h/j/k/l` → Hyprland muda foco das janelas.
4. No AULA F75/Compx, tecla física `Super` dispara atalhos `Super`; tecla física `Alt` dispara atalhos `Alt`.

## Troubleshooting

### Alt/Super ficaram trocados

Causa provável: `keyd` ativo sem `f75.conf`, ou ID do receptor mudou.

Verificar dispositivos:

```bash
cat /proc/bus/input/devices
hyprctl devices -j | jq '.keyboards[].name'
```

IDs conhecidos:

- `3554:fa09` — `Compx 2.4G Wireless Receiver` / AULA F75;
- `1d57:fa60` — `2.4G Wireless Device`, receptor compatível observado na mesma máquina.

Se surgir outro vendor/product para o mesmo teclado, adicionar em `system/etc/keyd/f75.conf` e excluir em `system/etc/keyd/default.conf`.

### Caps+h/j/k/l não funciona

Verificar se o serviço está ativo e se a config carrega:

```bash
systemctl is-active keyd
sudo keyd reload
keyd check /etc/keyd/default.conf /etc/keyd/f75.conf
```

### Teclado ficou inutilizável

`keyd` tem sequência de emergência: segurar `Backspace+Escape+Enter` encerra o daemon.

Alternativa via shell/TTY:

```bash
sudo systemctl stop keyd
```

## Decisão atual

- **keyd** é o mecanismo ativo para `CapsLock+h/j/k/l` e correção Alt/Super do AULA F75.
- **Hyprland** continua dono de `Super+h/j/k/l`, troca de layout (`Super+I`) e `compose:rctrl`.
- **XKB custom local** não faz parte do setup ativo porque quebra o LED do CapsLock.
