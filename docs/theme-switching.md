# Theme switching — troca de paleta system-wide

**Status:** implementado e verificado — 5 temas ativos (`normal`, `matte-black`, `tokyo-night`, `kanagawa`, `catppuccin`), aplicados via CLI ou theme-picker.
**Contexto:** Hyprland + Waybar + SwayNC + Ghostty/Kitty + Fuzzel + Hyprlock + btop + Quickshell + Neovim + tmux, sem instalar Omarchy/HyDE.

## Descrição

Troca a paleta de cor do sistema inteiro com `theme-set.sh <tema>` ou pelo
seletor visual Quickshell (`Super+T` / `Super+Ctrl+Shift+Space`). O mecanismo
foi adaptado do `bin/omarchy-theme-set` real do Omarchy, mas permanece
standalone — sem Walker/Elephant/CLI de outra distro.

## Decisões tomadas

- **Schema de cor único (`colors.toml`)**, copiado do formato real do Omarchy: `background`, `surface`, `surface_hover`, `foreground`, `accent`, `error` (paleta de UI) + `term_*` (paleta do terminal, deliberadamente separada da UI — ver "Por que dois foregrounds" abaixo) + `color0`–`color15` (ANSI, Ghostty/btop).
- **Um arquivo de cor dedicado por app**, não o config inteiro regenerado. Diferença consciente do Omarchy: lá cada app já tem um `.tpl` isolado dentro do *pacote de tema* porque o config real já é modular; aqui os configs reais (`hyprland.lua`, `ghostty config`, `hyprlock.conf`, `waybar/style.css`, `swaync/style.css`, `fuzzel.ini`) misturam cor com bind/layout/transparência etc. — regenerar o arquivo inteiro arriscaria sobrescrever configuração não relacionada a tema. Solução: cada app passou a **importar/incluir** um arquivo pequeno só de cor, gerado pelo `theme-set.sh`:

  | App | Mecanismo | Arquivo gerado |
  |---|---|---|
  | Hyprland | `dofile()` (Lua) | `hypr/.config/hypr/colors.lua` |
  | Hyprlock | `source =` (hyprlang) + `$vars` | `hypr/.config/hypr/colors.conf` |
  | Ghostty | `config-file =` (suporte nativo confirmado) | `ghostty/.config/ghostty/colors.ghostty` |
  | Fuzzel | `include=` (fuzzel ≥ 1.10, instalado é 1.14.1) | `fuzzel/.config/fuzzel/colors.ini` |
  | Waybar | `@import` + `@define-color` (GTK CSS) | `waybar/.config/waybar/colors.css` |
  | SwayNC | mesmo mecanismo do Waybar | `swaync/.config/swaync/colors.css` |
  | btop | sem template — troca `color_theme` entre `"Default"` (builtin) e `"catppuccin-mocha"` (arquivo estático oficial do `catppuccin/btop`, copiado literal) | — |

- **Por que dois "foreground" (`foreground` vs `term_*`)**: no estado real do sistema antes desse trabalho, Waybar/Hyprlock/Fuzzel usavam branco puro (`#ffffff`) mas o Ghostty usava um off-white mais suave (`#deddda`, convenção Adwaita). Forçar os dois a convergir pra um valor só teria mudado a aparência real do terminal — inaceitável, já que o tema "normal" precisa ser **byte-idêntico** ao estado anterior. Schema ficou com dois campos em vez de um.
- **CSS refatorado pra usar variáveis nomeadas** (`@accent`, `@foreground` etc. via `@define-color`, confirmado que Waybar e SwayNC suportam — ambos GTK3 CSS) em vez de hex literal espalhado pelas regras. Author verificou: `alpha()`/`shade()` do GTK funcionam em cima de `@named-color`, não só hex — usado pra opacidades variáveis (ex: `alpha(@accent, 0.2)`).
- **`fail_color` do Hyprlock virou campo `error` dedicado**, não reaproveitou `color1` — o hex real (`#ff6464`) não batia com o vermelho da paleta ANSI (`#ed333b`), e forçar igualdade teria mudado a cor de erro do lockscreen.
- **`outer_color` (borda do campo de senha) precisou de alpha diferente do `check_color`** (mesmo accent, alphas `33` vs `ff`) — motivo de existir `$accent_color` *e* `$accent_faint` no `colors.conf` gerado, em vez de uma variável só.
- **btop segue sem template genérico** — `theme-set.sh` alterna `color_theme`
  no `btop.conf`; temas que precisam de mapeamento próprio entram como arquivos
  estáticos em `btop/.config/btop/themes/*.theme`.
- **Theme-picker local em Quickshell**: carousel filtrável de previews, inspirado
  no Omarchy. O namespace real da layer do Fuzzel é `launcher`; o bind `Super+R`
  chama `fuzzel-toggle.sh` para ignorar processos zumbis que antes impediam o
  launcher de reabrir.
- **Quickshell/SwayNC também entram no tema**: `quick_*` no `colors.toml` controla
  fundo, opacidade, radius e dimensões do clock-panel. `normal` mantém painéis
  cinza/arredondados; `matte-black` aplica painéis pretos/quadrados e escala o
  clock-panel para 75%.
- **Blur por layer no Hyprland**: `quickshell`, `swaync-control-center` e
  `launcher` têm `hl.layer_rule({ blur = true, ignore_alpha = 0.10 })`, para
  borrar só atrás das superfícies semi-transparentes e não a tela inteira.

## Verificação feita

- **Idempotência do tema "normal"**: arquivos de cor gerados foram commitados (`git add`) e o script rodado de novo com `normal` — `git diff` ficou **vazio**, confirmando que a regeneração é byte-idêntica ao estado manual original.
- **Aplicação do "catppuccin"**: `git diff --stat` mostrou os 7 arquivos mudando; `hyprctl configerrors` sem erros; screenshot da barra do Waybar + borda da janela confirmou visualmente o roxo/mauve do Catppuccin Mocha aplicado.
- **Reversão pro "normal"**: rodado de novo, `git diff` voltou a ficar vazio — reversão também byte-perfeita.
- **Hyprlock não foi testado ao vivo** (rodar travaria a sessão de verdade, não tem modo de teste como o `sddm-greeter-qt6 --test-mode` usado noutro doc). Verificação estática: as 5 variáveis usadas no `hyprlock.conf` (`$bg_color`, `$fg_color`, `$accent_color`, `$accent_faint`, `$error_color`) batem exatamente com as definidas no `colors.conf` gerado. Testar manualmente com `Super+L` quando conveniente.

## Gap conhecido — conflito de stow pré-existente

Ao tentar `stow --restow scripts` pra symlinkar o `theme-set.sh` novo, o Stow recusou o pacote inteiro:

```
cannot stow .../scripts/.local/bin/media-open-spotify.sh over existing target .local/bin/media-open-spotify.sh
cannot stow .../scripts/.local/bin/waybar-calendar.sh over existing target .local/bin/waybar-calendar.sh
```

Esses dois arquivos existem como **arquivos reais** em `~/.local/bin/` (não symlink) — provavelmente resíduo de alguma instalação manual anterior, não relacionado a este trabalho. Contornado com `ln -s` manual só do `theme-set.sh`, sem tentar resolver o conflito dos outros dois (fora de escopo). Fica registrado aqui pra investigar depois: decidir se adota (`stow --adopt`, sobrescreve o repo com o conteúdo do `$HOME`) ou remove os arquivos reais em duplicidade.

## Uso

```bash
theme-set.sh normal
theme-set.sh matte-black
theme-set.sh tokyo-night
theme-set.sh kanagawa
theme-set.sh catppuccin
```

Detalhes de schema, templates e como adicionar tema novo em [`themes/README.md`](../themes/README.md) — este doc é o registro de decisão/contexto, aquele é a referência técnica.
