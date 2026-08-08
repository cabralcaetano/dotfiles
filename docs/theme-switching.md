# Theme switching — troca de paleta system-wide

**Status:** implementado e verificado (2026-08-07) — 2 temas ativos (`normal`, `catppuccin`), aplicados via CLI.
**Contexto:** Hyprland + Waybar + SwayNC + Ghostty + Fuzzel + Hyprlock + btop, sem nenhuma distro/rice completa (Omarchy, HyDE etc.) instalada.

## Descrição

Troca a paleta de cor do sistema inteiro com um comando (`theme-set.sh <tema>`), mecanismo adaptado do `bin/omarchy-theme-set` real do [Omarchy](https://github.com/basecamp/omarchy) (lido direto do código-fonte, não de resumo de terceiro), mas **standalone** — sem Walker/Elephant/CLI de outra distro, sem instalar rice nenhuma.

Motivação: usuário perguntou como ricers fazem seletor de wallpaper/tema com preview (fuzzel vs rofi vs waypaper), pesquisamos os padrões reais (JaKooLit/Hyprland-Dots, HyDE, Omarchy), e por decisão explícita **o seletor visual ficou pra depois** — o pedido concreto virou "copia o método do Omarchy de troca de tema" primeiro, sem UI ainda.

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
- **btop não foi templatizado** — o tema "normal" usa o `color_theme = "Default"` builtin do próprio btop (zero risco de divergência), e o "catppuccin" usa o tema oficial `catppuccin/btop` copiado literal, em vez de eu tentar re-derivar a paleta a partir do schema genérico (evita erro de mapeamento).
- **Sem bind ainda** — decisão consciente, pendente da escolha do seletor visual (fuzzel vs rofi vs waypaper — ver discussão de sessão sobre como ricers fazem preview de wallpaper/tema). O script funciona 100% via CLI nesse meio tempo.

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
theme-set.sh normal        # paleta monocromática atual (Adwaita dark)
theme-set.sh catppuccin    # Catppuccin Mocha
```

Detalhes de schema, templates e como adicionar um tema novo em [`themes/README.md`](../themes/README.md) — este doc é o registro de decisão/contexto, aquele é a referência técnica.
