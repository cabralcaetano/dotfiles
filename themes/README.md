# themes/ — theme-set (paleta de cor system-wide)

**Status:** implementado — 5 temas ativos (`normal`, `matte-black`,
`tokyo-night`, `kanagawa`, `catppuccin`), aplicáveis via
`scripts/.local/bin/theme-set.sh <nome>` (symlinkado em
`~/.local/bin/theme-set.sh`) ou pelo seletor visual `theme-picker.sh`.

## Mecanismo (adaptado de `bin/omarchy-theme-set` do Omarchy)

1. **`themes/<tema>/colors.toml`** — fonte de verdade da paleta. Schema fixo
   (ver `themes/normal/colors.toml` como referência): `background`, `surface`,
   `surface_hover`, `foreground`, `accent`, `error`; `term_*`; `color0`–
   `color15`; integrações desktop (`gtk_theme`, `icon_theme`, `window_rounding`,
   gaps/bordas); e parâmetros de UI (`quick_*`) para Quickshell/SwayNC.
2. **`themes/templates/*.tpl`** — templates por app, com placeholders
   `{{ chave }}` (valor com `#`) e `{{ chave_strip }}` (sem `#`, para formatos
   hex-sem-hash como `rgba(a0a0a0ff)`).
3. **`theme-set.sh <tema>`** monta um `sed` dinâmico a partir do `colors.toml` e
   renderiza os arquivos reais do repo (que o Stow symlinka para `$HOME`):
   arquivos pequenos de cor quando o app suporta include e templates inteiros
   onde o visual é parte do tema (`swaync/style.css`, Quickshell clock-panel,
   Quickshell theme-picker).
4. **Reload em cascata**: `hyprctl reload`, Waybar, `swaync-client --reload-css`,
   btop, GTK/Qt/icon theme; o shell Quickshell ativo é reiniciado/preloaded
   quando necessário para evitar seletor frio na primeira abertura.

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
| btop | `theme-set.sh` escolhe `color_theme` no `btop.conf` | temas estáticos em `btop/.config/btop/themes/*.theme` |
| Quickshell | templates QML + JS renderizados | `clock-panel/shell.qml`, `theme-picker/shell.qml`, `theme.js` |

Cada config real (`waybar/style.css`, `swaync/style.css` etc.) foi refatorado
pra referenciar essas cores por nome (`@accent`, `$fg_color`, etc.) em vez de
hex literal — então o `.tpl` só precisa regenerar o arquivo pequeno, tudo
mais no config continua intocado.

## Temas disponíveis

- **`normal`** — Adwaita/cinza escuro, arredondado; preserva o visual histórico
  do sistema e os painéis Quickshell cinza.
- **`matte-black`** — preto fosco, quadrado, wallpaper próprio, ícones
  MatteBlack, clock-panel Quickshell em 75% (`quick_clock_scale = 0.75`).
- **`tokyo-night`** — paleta azul/roxa derivada do pacote Omarchy.
- **`kanagawa`** — paleta escura Kanagawa derivada do pacote Omarchy.
- **`catppuccin`** — flavor Mocha, paleta oficial (catppuccin.com/palette).

## Uso

```bash
theme-set.sh normal
theme-set.sh matte-black
theme-set.sh tokyo-night
theme-set.sh kanagawa
theme-set.sh catppuccin
```

Atalhos: `Super+T` e `Super+Ctrl+Shift+Space` abrem o theme-picker; `Super+R`
abre/fecha Fuzzel via `fuzzel-toggle.sh` (ignora processos zumbis).

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
