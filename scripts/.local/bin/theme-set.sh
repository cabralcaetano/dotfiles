#!/usr/bin/env bash
# Aplica um tema (paleta de cor) no sistema inteiro, adaptado do mecanismo do
# Omarchy (bin/omarchy-theme-set): lê themes/<tema>/colors.toml, expande cada
# themes/templates/*.tpl substituindo {{ chave }} / {{ chave_strip }} (sem "#")
# pelo valor, escreve direto nos arquivos reais do repo (stow já symlinka pro
# $HOME) e dispara o reload de cada app afetado.
#
# Uso: theme-set.sh <normal|catppuccin>
set -euo pipefail

THEME_NAME="${1:?Uso: theme-set.sh <normal|catppuccin>}"

# Resolve o diretório real do repo a partir do próprio script (funciona
# mesmo chamado via symlink do stow em ~/.local/bin/theme-set.sh).
SCRIPT_REAL="$(readlink -f "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(cd "$(dirname "$SCRIPT_REAL")/../../.." && pwd)"

THEME_DIR="$DOTFILES_DIR/themes/$THEME_NAME"
COLORS_FILE="$THEME_DIR/colors.toml"
TEMPLATES_DIR="$DOTFILES_DIR/themes/templates"

[[ -f $COLORS_FILE ]] || { echo "Tema '$THEME_NAME' não existe ($COLORS_FILE)"; exit 1; }

# === Monta o script sed a partir do colors.toml ===================
# {{ chave }}       -> valor literal ("#1e1e2e")
# {{ chave_strip }} -> valor sem o "#" ("1e1e2e")
sed_script=$(mktemp)
trap 'rm -f "$sed_script"' EXIT

while IFS='=' read -r key value; do
    key="${key// /}"
    [[ $key && $key != \#* ]] || continue
    value="${value#*\"}"
    value="${value%%\"*}"

    printf 's|{{ %s }}|%s|g\n' "$key" "$value" >>"$sed_script"
    printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}" >>"$sed_script"
done <"$COLORS_FILE"

render() {
    local tpl="$1" out="$2"
    sed -f "$sed_script" "$TEMPLATES_DIR/$tpl" >"$out"
}

# === Renderiza cada app a partir do template =======================
render hyprland-colors.lua.tpl "$DOTFILES_DIR/hypr/.config/hypr/colors.lua"
render ghostty-colors.tpl      "$DOTFILES_DIR/ghostty/.config/ghostty/colors.ghostty"
render hyprlock-colors.tpl     "$DOTFILES_DIR/hypr/.config/hypr/colors.conf"
render fuzzel-colors.tpl       "$DOTFILES_DIR/fuzzel/.config/fuzzel/colors.ini"
render waybar-colors.css.tpl   "$DOTFILES_DIR/waybar/.config/waybar/colors.css"
render swaync-colors.css.tpl   "$DOTFILES_DIR/swaync/.config/swaync/colors.css"

# btop não usa template — troca só o color_theme entre o "Default" builtin
# (normal) e o arquivo estático catppuccin-mocha.theme (ver themes/README.md).
BTOP_THEME="Default"
[[ $THEME_NAME == catppuccin ]] && BTOP_THEME="catppuccin-mocha"
sed -i "s/^color_theme = .*/color_theme = \"$BTOP_THEME\"/" \
    "$DOTFILES_DIR/btop/.config/btop/btop.conf"

# === Wallpaper (opcional) ==========================================
# Se o tema tiver themes/<tema>/wallpaper.*, aplica via awww.
WALLPAPER=$(find "$THEME_DIR" -maxdepth 1 -type f \( -iname "wallpaper.*" \) -print -quit 2>/dev/null || true)
if [[ -n $WALLPAPER ]]; then
    awww img "$WALLPAPER" --transition-type fade --transition-duration 1.5 --transition-fps 60
fi

# === Reload em cascata ==============================================
hyprctl reload

if pgrep -x waybar >/dev/null; then
    pkill -x waybar
    setsid waybar >/dev/null 2>&1 &
    disown
fi

command -v swaync-client >/dev/null && swaync-client --reload-css >/dev/null 2>&1 || true

pkill -SIGUSR2 btop 2>/dev/null || true

echo "Tema '$THEME_NAME' aplicado."
