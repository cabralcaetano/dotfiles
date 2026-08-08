# themes/ — theme-set (paleta de cor system-wide)

**Status:** implementado — 2 temas ativos (`normal`, `catppuccin`), aplicáveis via
`scripts/.local/bin/theme-set.sh <nome>` (symlinkado em `~/.local/bin/theme-set.sh`).

## Mecanismo (adaptado de `bin/omarchy-theme-set` do Omarchy)

1. **`themes/<tema>/colors.toml`** — fonte de verdade da paleta. Schema fixo
   (ver `themes/normal/colors.toml` como referência): `background`, `surface`,
   `surface_hover`, `foreground`, `accent`, `error` (paleta de UI); `term_*`
   (paleta específica do terminal, off-white mais suave que a UI); `color0`–
   `color15` (paleta ANSI de 16 cores, usada por Ghostty e btop).
2. **`themes/templates/*.tpl`** — um template por app, com placeholders
   `{{ chave }}` (valor com `#`) e `{{ chave_strip }}` (sem `#`, pra formatos
   hex-sem-hash como `rgba(a0a0a0ff)`).
3. **`theme-set.sh <tema>`** monta um sed dinâmico a partir do `colors.toml` e
   renderiza cada `.tpl` direto no arquivo real do repo (que o Stow já
   symlinka pro `$HOME`) — sem diretório intermediário/swap atômico como o
   Omarchy faz, porque aqui cada app tem só um arquivo pequeno **dedicado**
   à cor (ver tabela abaixo), então regenerar o arquivo inteiro já é atômico
   o bastante (a escrita do `sed` é para um arquivo só, sem tocar no resto
   da config do app).
4. **Reload em cascata**: `hyprctl reload` (Hyprland + hyprlock, que relê o
   `colors.conf` na próxima chamada), restart do Waybar (não tem hot-reload
   de CSS), `swaync-client --reload-css`, `pkill -SIGUSR2 btop`. Fuzzel e
   Hyprlock não têm daemon — leem o config na hora que abrem.

## Por que cada app é um arquivo `.tpl` isolado, e não a config inteira

Diferente do Omarchy (que isola *todo* o config themável de cada app dentro
do próprio pacote de tema), aqui os configs reais (`hyprland.lua`, `ghostty
config`, `hyprlock.conf`, `waybar/style.css`, `swaync/style.css`,
`fuzzel.ini`) misturam cor com o resto da configuração (binds, layout,
transparência etc). Pra não arriscar o template regenerar/sobrescrever
configuração não-relacionada a tema, cada app tem um arquivo **só de cor**,
incluído/importado pelo config real:

| App | Mecanismo de inclusão | Arquivo gerado |
|---|---|---|
| Hyprland | `dofile()` (Lua) retornando uma tabela | `hypr/.config/hypr/colors.lua` |
| Hyprlock | `source = ~/.config/hypr/colors.conf` (hyprlang) + `$vars` | `hypr/.config/hypr/colors.conf` |
| Ghostty | `config-file = colors.ghostty` (nativo do Ghostty ≥ suporte a includes) | `ghostty/.config/ghostty/colors.ghostty` |
| Fuzzel | `include=~/.config/fuzzel/colors.ini` (fuzzel ≥ 1.10) | `fuzzel/.config/fuzzel/colors.ini` |
| Waybar | `@import url("colors.css");` + `@define-color` (GTK CSS) | `waybar/.config/waybar/colors.css` |
| SwayNC | mesmo mecanismo do Waybar (GTK CSS) | `swaync/.config/swaync/colors.css` |
| btop | não usa template — troca só `color_theme` no `btop.conf` entre `"Default"` (builtin, tema normal) e `"catppuccin-mocha"` (arquivo estático oficial do catppuccin/btop) | — |

Cada config real (`waybar/style.css`, `swaync/style.css` etc.) foi refatorado
pra referenciar essas cores por nome (`@accent`, `$fg_color`, etc.) em vez de
hex literal — então o `.tpl` só precisa regenerar o arquivo pequeno, tudo
mais no config continua intocado.

## Temas disponíveis

- **`normal`** — paleta monocromática atual (Adwaita dark), extraída 1:1 dos
  configs em 2026-08-07. Aplicar este tema é byte-idêntico ao estado anterior
  à existência do theme-set (verificado via `git diff` vazio).
- **`catppuccin`** — flavor Mocha, paleta oficial (catppuccin.com/palette),
  conferida contra catppuccin/btop.

## Uso

```bash
theme-set.sh normal        # volta pro monocromático
theme-set.sh catppuccin    # aplica Catppuccin Mocha
```

Sem bind ainda — decisão consciente, pendente de escolher o seletor visual
(fuzzel vs rofi vs waypaper, discutido em sessão anterior). O script já
funciona standalone via CLI.

## Como adicionar um tema novo

1. `themes/<slug>/colors.toml` — preencher todas as chaves do schema (usar
   `themes/catppuccin/colors.toml` como molde).
2. Rodar `theme-set.sh <slug>` — os `.tpl` em `themes/templates/` já cobrem
   todo o stack, não precisa tocar em mais nada.
3. (Opcional) `themes/<slug>/wallpaper.<ext>` — se existir, o script aplica
   via `awww` automaticamente.
4. Se o tema precisar de um btop dedicado (não reaproveitável via paleta
   genérica), adicionar `btop/.config/btop/themes/<slug>.theme` e um `elif`
   no bloco `BTOP_THEME` do `theme-set.sh`.
