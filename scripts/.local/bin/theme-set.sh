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

add_template_value() {
    local key="$1" value="$2"
    printf 's|{{ %s }}|%s|g\n' "$key" "$value" >>"$sed_script"
    printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}" >>"$sed_script"
}

theme_get() {
    local key="$1" default="${2:-}"
    local value
    value=$(awk -F= -v wanted="$key" '
        {
            key=$1
            gsub(/[[:space:]]/, "", key)
            if (key != wanted) next
            value=$2
            sub(/[[:space:]]+#.*/, "", value)
            gsub(/^[[:space:]"]+|[[:space:]"]+$/, "", value)
            print value
        }
    ' "$COLORS_FILE" | tail -n 1)
    printf '%s' "${value:-$default}"
}

mode=$(theme_get mode dark)
if [[ $mode == light ]]; then
    prefer_dark=0
    gtk_theme=$(theme_get gtk_theme Adwaita)
    gtk4_theme=$(theme_get gtk4_theme Adwaita)
else
    prefer_dark=1
    gtk_theme=$(theme_get gtk_theme adw-gtk3-dark)
    gtk4_theme=$(theme_get gtk4_theme Adwaita-dark)
fi

add_template_value mode "$mode"
add_template_value prefer_dark "$prefer_dark"
add_template_value gtk_theme "$gtk_theme"
add_template_value gtk4_theme "$gtk4_theme"
add_template_value icon_theme "$(theme_get icon_theme Adwaita)"
add_template_value cursor_theme "$(theme_get cursor_theme capitaine-cursors)"
add_template_value cursor_size "$(theme_get cursor_size 24)"
add_template_value border_size "$(theme_get border_size 2)"
add_template_value gaps_in "$(theme_get gaps_in 3.5)"
add_template_value gaps_out "$(theme_get gaps_out 6.5)"
window_rounding=$(theme_get window_rounding 10)
background_default=$(theme_get background "#1d1d20")
surface_default=$(theme_get surface "#2a2a2e")
surface_hover_default=$(theme_get surface_hover "#323236")
add_template_value window_rounding "$window_rounding"
add_template_value rounding_power "$(theme_get rounding_power 2)"
add_template_value quick_panel_background "$(theme_get quick_panel_background "$background_default")"
add_template_value quick_card_background "$(theme_get quick_card_background "$surface_default")"
add_template_value quick_hover_background "$(theme_get quick_hover_background "$surface_hover_default")"
add_template_value quick_panel_opacity "$(theme_get quick_panel_opacity 0.90)"
add_template_value quick_card_opacity "$(theme_get quick_card_opacity 0.80)"
add_template_value quick_hover_opacity "$(theme_get quick_hover_opacity 0.92)"
add_template_value quick_panel_radius "$(theme_get quick_panel_radius "$window_rounding")"
add_template_value quick_card_radius "$(theme_get quick_card_radius "$window_rounding")"
add_template_value quick_button_radius "$(theme_get quick_button_radius "$window_rounding")"
add_template_value quick_switch_radius "$(theme_get quick_switch_radius 20)"
add_template_value quick_box_shadow "$(theme_get quick_box_shadow "0 4px 24px rgba(0, 0, 0, 0.5)")"
add_template_value quick_clock_width "$(theme_get quick_clock_width 650)"
add_template_value quick_clock_height "$(theme_get quick_clock_height 400)"
add_template_value quick_clock_scale "$(theme_get quick_clock_scale 1.0)"
add_template_value quick_clock_margin "$(theme_get quick_clock_margin 14)"
add_template_value quick_clock_spacing "$(theme_get quick_clock_spacing 10)"
add_template_value quick_clock_left_width "$(theme_get quick_clock_left_width 315)"
add_template_value quick_clock_right_width "$(theme_get quick_clock_right_width 297)"
add_template_value quick_clock_top_height "$(theme_get quick_clock_top_height 180)"
add_template_value quick_clock_bottom_height "$(theme_get quick_clock_bottom_height 180)"
add_template_value quick_clock_art_size "$(theme_get quick_clock_art_size 88)"
add_template_value quick_clock_control_height "$(theme_get quick_clock_control_height 28)"
add_template_value browser_color "$(theme_get browser_color "$background_default")"

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
render kitty-colors.tpl      "$DOTFILES_DIR/kitty/.config/kitty/current-theme.conf"
render gtk-3-settings.ini.tpl "$DOTFILES_DIR/gtk-3/.config/gtk-3.0/settings.ini"
render gtk-4-settings.ini.tpl "$DOTFILES_DIR/gtk-4/.config/gtk-4.0/settings.ini"
render gtk.css.tpl            "$DOTFILES_DIR/gtk-3/.config/gtk-3.0/gtk.css"
render gtk.css.tpl            "$DOTFILES_DIR/gtk-4/.config/gtk-4.0/gtk.css"
render qt6ct.conf.tpl         "$DOTFILES_DIR/qt6ct/.config/qt6ct/qt6ct.conf"
render qt6ct-colors.conf.tpl  "$DOTFILES_DIR/qt6ct/.config/qt6ct/colors/dotfiles-theme.conf"
render tmux-theme.conf.tpl    "$DOTFILES_DIR/tmux/.config/tmux/theme.conf"
render nvim-system-theme.lua.tpl "$DOTFILES_DIR/nvim/.config/nvim/lua/config/system_theme_generated.lua"
render quickshell-theme.js.tpl "$DOTFILES_DIR/quickshell/.config/quickshell/theme.js"
render quickshell-clock-panel.qml.tpl "$DOTFILES_DIR/quickshell/.config/quickshell/clock-panel/shell.qml"
render quickshell-theme-picker.qml.tpl "$DOTFILES_DIR/quickshell/.config/quickshell/theme-picker/shell.qml"
render swaync-style.css.tpl "$DOTFILES_DIR/swaync/.config/swaync/style.css"

link_config() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    [[ -e $dest && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]] && return 0
    ln -sfn "$src" "$dest"
}

link_config "$DOTFILES_DIR/kitty/.config/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
link_config "$DOTFILES_DIR/gtk-3/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
link_config "$DOTFILES_DIR/qt6ct/.config/qt6ct/colors/dotfiles-theme.conf" "$HOME/.config/qt6ct/colors/dotfiles-theme.conf"
link_config "$DOTFILES_DIR/tmux/.config/tmux/theme.conf" "$HOME/.config/tmux/theme.conf"
link_config "$DOTFILES_DIR/nvim/.config/nvim/lua/config/system_theme.lua" "$HOME/.config/nvim/lua/config/system_theme.lua"
link_config "$DOTFILES_DIR/nvim/.config/nvim/lua/config/system_theme_generated.lua" "$HOME/.config/nvim/lua/config/system_theme_generated.lua"
if [[ -d "$DOTFILES_DIR/icons/.local/share/icons/MatteBlack" ]]; then
    link_config "$DOTFILES_DIR/icons/.local/share/icons/MatteBlack" "$HOME/.local/share/icons/MatteBlack"
    command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q -f -t "$HOME/.local/share/icons/MatteBlack" >/dev/null 2>&1 || true
fi

# btop usa tema estático quando existir em btop/.config/btop/themes/<tema>.theme.
# Os temas Omarchy portados precisam disso para btop ficar igual ao preview.
BTOP_THEME="Default"
if [[ -f "$DOTFILES_DIR/btop/.config/btop/themes/$THEME_NAME.theme" ]]; then
    BTOP_THEME="$THEME_NAME"
elif [[ $THEME_NAME == catppuccin ]]; then
    BTOP_THEME="catppuccin-mocha"
fi
sed -i "s/^color_theme = .*/color_theme = \"$BTOP_THEME\"/" \
    "$DOTFILES_DIR/btop/.config/btop/btop.conf"

# === GTK / Nautilus / Qt ============================================
# Libadwaita/Nautilus seguem gsettings para dark mode, gtk-theme e icon-theme.
if command -v gsettings >/dev/null && [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    if [[ $mode == light ]]; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light" || true
    else
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true
    fi
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk4_theme" || true
    gsettings set org.gnome.desktop.interface icon-theme "$(theme_get icon_theme Adwaita)" || true
    gsettings set org.gnome.desktop.interface cursor-theme "$(theme_get cursor_theme capitaine-cursors)" || true
    gsettings set org.gnome.desktop.interface cursor-size "$(theme_get cursor_size 24)" || true
fi

# === Browser chrome color ===========================================
# Compatível com o mecanismo do Omarchy quando as policy dirs são graváveis.
browser_hex=$(theme_get browser_color "$background_default")
browser_policy_json="{\"BrowserThemeColor\":\"$browser_hex\",\"BrowserColorScheme\":\"device\"}"
for policy_dir in /etc/chromium/policies/managed /etc/opt/chrome/policies/managed /etc/opt/edge/policies/managed /etc/brave/policies/managed; do
    if [[ -d $policy_dir && -w $policy_dir ]]; then
        printf '%s\n' "$browser_policy_json" >"$policy_dir/color.json"
    fi
done
command -v chromium >/dev/null && pgrep -x chromium >/dev/null && chromium --refresh-platform-policy --no-startup-window >/dev/null 2>&1 || true


# === Wallpaper ======================================================
# Se o tema tiver themes/<tema>/wallpaper.*, aplica. Caso contrário, volta para
# o wallpaper padrão do setup; evita sair de um tema com wallpaper próprio e
# deixar esse wallpaper "vazar" para normal/catppuccin.
WALLPAPER=$(find "$THEME_DIR" -maxdepth 1 -type f \( -iname "wallpaper.*" \) -print -quit 2>/dev/null || true)
if [[ -z $WALLPAPER && -f "$HOME/.config/wallpapers/wallpaper_3.png" ]]; then
    WALLPAPER="$HOME/.config/wallpapers/wallpaper_3.png"
fi
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


if pgrep -x kitty >/dev/null; then
    pkill -SIGUSR1 kitty 2>/dev/null || true
fi

if pgrep -x ghostty >/dev/null; then
    pkill -SIGUSR2 ghostty 2>/dev/null || true
fi

if command -v tmux >/dev/null && tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$HOME/.config/tmux/theme.conf" 2>/dev/null || true
    tmux set-environment -g COLORFGBG "$([[ $mode == light ]] && printf '0;15' || printf '15;0')" 2>/dev/null || true
fi
pkill -SIGUSR2 btop 2>/dev/null || true

# Guarda o tema atual para seletores visuais/atalhos sem acoplar o estado ao
# formato interno dos arquivos gerados.
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/theme-picker"
printf '%s\n' "$THEME_NAME" >"${XDG_STATE_HOME:-$HOME/.local/state}/theme-picker/current-theme"


echo "Tema '$THEME_NAME' aplicado."
