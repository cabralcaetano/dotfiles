# Waybar crasha no boot (módulo tray) — bug conhecido, mitigado

Status: **aberto, mitigado por supervisor**. Decisão (2026-11-15): continuar no
`waybar-git` porque o pacote `waybar` estável não tem funcionalidades usadas aqui.

## Sintoma

Waybar some no boot do Hyprland (barra não aparece). `coredumpctl list waybar`
mostra SIGSEGV (ocorrências em 14/11 14:49, 15/11 08:43 e 15/11 08:52).

## Causa

Use-after-free no módulo SNI/tray. Upstream: Alexays/Waybar
[#5438](https://github.com/Alexays/Waybar/issues/5438).

- Desde o PR #5375 (10/10/2026), `~Item()` destrói o `DbusmenuGtkMenu`.
- `libdbusmenu-gtk` liga `root_changed()` ao `root-changed` do client e nunca
  desconecta. Um `GetLayout` em voo mantém o client vivo.
- Quando o app do tray (ex.: fcitx5 "Input Method") responde, `root_changed()`
  roda sobre o menu já liberado: SIGSEGV em `dbusmenu_menuitem_get_children`.
- Gatilho: barra destruída/recriada com `GetLayout` pendente. No boot,
  provavelmente reconfiguração de monitores do Hyprland [inferência, não
  verificada nos eventos].

Assinatura no core (`coredumpctl gdb <pid>`): `root_changed` em
`libdbusmenu-gtk3.so` → `dbusmenu_menuitem_get_children`, `rdi` com lixo.

## Fix upstream

Commits `37a6b944` e `692d62a0` (5/11/2026), incluídos no `waybar` 0.16.0 (`extra`).
O build instalado, `waybar-git 0.15.0.r1100.gf6f73c8` (2/11), é anterior ao fix.

Para resolver de vez, qualquer um dos dois:
- atualizar o `waybar-git` (rebuild do master, que já tem o fix);
- ou `sudo pacman -S waybar` (0.16.0; conflita com `waybar-git`), se as features
  exclusivas do `-git` deixarem de ser necessárias.

Ao atualizar, validar nos próximos boots (`coredumpctl list waybar` sem novas
entradas) e então remover o supervisor.

## Mitigação atual

`scripts/.local/bin/waybar-run.sh` (symlink em `~/.local/bin`) roda o `waybar` em
loop e o relança após crash (lock via `flock`; recua 10 s após 5 crashes rápidos;
não relança em saída limpa/SIGTERM). Chamado no autostart em
`hypr/.config/hypr/hyprland.lua` (`hyprland.start`).

Remoção quando o fix entrar: voltar a linha do autostart para `waybar & ...` e
apagar `waybar-run.sh` e o symlink.
