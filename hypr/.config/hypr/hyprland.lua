-- =================================================
-- HYPRLAND CONFIG — cabralcaetano
-- Migrado de hyprland.conf (hyprlang) para Lua em 2026-08-07.
-- Motivo: hyprlang/.conf deprecated desde 0.55, suporte removido no 0.57.
-- Original preservado em legacy/hyprland-conf/hyprland.conf (referência).
-- =================================================

-- === MONITOR =====================================
hl.monitor({ output = "", mode = "1920x1200@60", position = "0x0", scale = 1.25 })

-- === VARIÁVEIS ====================================
local terminal    = "ghostty"
local fileManager = "nautilus"
local menu        = "fuzzel"
local browser     = "brave"
local mainMod     = "SUPER"
local vscode      = "code"
local discord     = "discord"
local spotify     = "spotify-launcher"
local obsidian    = "flatpak run md.obsidian.Obsidian"
local waterReminder = "~/.local/bin/water-reminder"

-- === TEMA (cores) — gerado por theme-set.sh, ver themes/ no root do repo ===
local theme_colors = dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")

-- === AUTOSTART — SISTEMA E APLICATIVOS ===========
hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5 --replace -d")
    hl.exec_cmd("waybar & qs -c clock-panel --daemonize & awww-daemon & swaync")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("sleep 0.5 && awww img ~/.config/wallpapers/wallpaper_5.jpg --transition-type fade --transition-duration 1.5 --transition-fps 60")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("/usr/libexec/xdg-desktop-portal-hyprland")
    hl.exec_cmd("/usr/libexec/xdg-desktop-portal-gtk")
    hl.exec_cmd("sleep 1 && /usr/libexec/xdg-desktop-portal")
    hl.exec_cmd("sleep 2 && gsettings set org.gnome.desktop.interface gtk-theme \"adw-gtk3-dark\"")
    hl.exec_cmd("sleep 2 && gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")
    hl.exec_cmd(waterReminder)

    -- aplicativos com workspace fixo, no super workspace 1 (padrão do boot)
    hl.dispatch(hl.dsp.exec_cmd(browser, { workspace = "name:super-1-1 silent" }))
    hl.dispatch(hl.dsp.exec_cmd(terminal .. " -e zsh -lc \"tmux new-session -A -s wiki-ia -c ~/Projects/wiki-ia\"", { workspace = "name:super-1-2 silent" }))
    hl.dispatch(hl.dsp.exec_cmd(obsidian, { workspace = "name:super-1-2 silent" }))
    hl.dispatch(hl.dsp.exec_cmd(spotify, { workspace = "name:super-1-3 silent" }))
    hl.dispatch(hl.dsp.exec_cmd(discord, { workspace = "name:super-1-4 silent" }))

    hl.exec_cmd("bash ~/.config/hypr/autostart.sh")
    hl.exec_cmd("~/.local/bin/super-workspace-urgent-watch.sh")
end)

-- === VARIÁVEIS DE AMBIENTE =======================
hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_SCALE", "1.25")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("AWT_TOOLKIT", "MToolkit")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XMODIFIERS", "@im=fcitx")

-- === APARÊNCIA / INPUT / XWAYLAND / MISC =========
hl.config({
    general = {
        gaps_in  = 3.5,
        gaps_out = 6.5,

        border_size = 2,
        ["col.active_border"]   = theme_colors.active_border,
        ["col.inactive_border"] = theme_colors.inactive_border,

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true, -- "yes, please :)" no original hyprlang
    },

    dwindle = {
        -- pseudotile = true,
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    input = {
        kb_layout  = "br,us",
        kb_variant = "abnt2,",
        kb_model   = "",
        kb_options = "compose:rctrl",
        -- NOTA: altwin:swap_alt_win NÃO fica no global — senão trocaria Alt/Super
        -- também no teclado do notebook. O swap é aplicado só no Aula F75 via
        -- hl.device() abaixo (o receptor enumera Alt/Super trocados).

        -- Key repeat — defaults do Hyprland são 25/600 (lento demais).
        repeat_rate  = 45,  -- teclas por segundo enquanto segura
        repeat_delay = 250, -- ms até começar a repetir

        accel_profile = "flat",
        follow_mouse  = 1,
        sensitivity   = -0.4,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

hl.device({
    name          = "gxtp5100:00-27c6:01e0-touchpad",
    accel_profile = "adaptive",
    sensitivity   = 0.3,
})

-- === Aula F75 (receptor Compx 2.4G) — swap Alt/Super só neste teclado ===
-- O receptor enumera as teclas Alt/Super trocadas (ver dotfiles.md, bug
-- "Alt/Super trocados"). Aplica altwin:swap_alt_win apenas aqui; o teclado
-- do notebook (at-translated-set-2-keyboard) segue o global, sem swap.
-- Cobre todas as interfaces HID do receptor (ambos os nomes que ele expõe)
-- para garantir que a interface que emite os modificadores seja corrigida.
local f75_devices = {
    "compx-2.4g-wireless-receiver",
    "compx-2.4g-wireless-receiver-keyboard",
    "compx-2.4g-wireless-receiver-consumer-control",
    "compx-2.4g-wireless-receiver-system-control",
    "2.4g-wireless-device",
    "2.4g-wireless-device-2",
    "2.4g-wireless-device-consumer-control",
    "2.4g-wireless-device-system-control",
}
for _, name in ipairs(f75_devices) do
    hl.device({ name = name, kb_options = "compose:rctrl, altwin:swap_alt_win" })
end

-- === KEYBINDINGS =================================

-- — Alt+Tab —
hl.bind("ALT + Tab", hl.dsp.exec_cmd("~/.local/bin/alttab.sh"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("~/.local/bin/alttab.sh prev"))

-- — Aplicativos —
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("pkill fuzzel || " .. menu))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(discord))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(obsidian))

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(vscode))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.local/bin/workspace-float.sh"))

-- — Janelas —
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(spotify))

-- Tela cheia
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({
    mode   = "fullscreen",
    action = "toggle",
}))

-- Trocar posição das janelas
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }))

-- — Foco —
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- — Workspaces (dentro do super workspace ativo, ver super-workspaces.txt) —
-- SUPER+Tab troca em ciclo; SUPER+Tab+1..2 pula direto para o super workspace.
-- Os mesmos 1-9/0 abaixo passam a apontar pro banco do super workspace ativo.
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh focus " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh move " .. i))
end
hl.bind(mainMod .. " + 0", hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh focus 10"))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh move 10"))

hl.bind(mainMod .. " + Tab", function()
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh next"))
    hl.dispatch(hl.dsp.submap("super-workspace-select"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c 'sleep 1; hyprctl dispatch submap reset' &"))
end)
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh move-super next"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh prev"))

hl.define_submap("super-workspace-select", function()
    for i = 1, 2 do
        local switch_super = function()
            hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh switch " .. i))
            hl.dispatch(hl.dsp.submap("reset"))
        end
        hl.bind("" .. i, switch_super)
        hl.bind(mainMod .. " + " .. i, switch_super)
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- — Scratchpad (também por super workspace) —
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh scratchpad"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/super-workspace.sh scratchpad-move"))

-- — Mouse —
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- — Volume —
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.local/bin/volume.sh up"),   { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.local/bin/volume.sh down"), { repeating = true, locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("~/.local/bin/volume.sh mute"), { repeating = true, locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { repeating = true, locked = true })

-- — Brilho —
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("~/.local/bin/brightness.sh up"),   { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.local/bin/brightness.sh down"), { repeating = true, locked = true })
hl.bind(mainMod .. " + F6", hl.dsp.exec_cmd("~/.local/bin/brightness.sh up"),   { repeating = true, locked = true })
hl.bind(mainMod .. " + F5", hl.dsp.exec_cmd("~/.local/bin/brightness.sh down"), { repeating = true, locked = true })

-- — Mídia —
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"),      { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- — Teclado —
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("~/.local/bin/kb-toggle.sh"))

-- — Fone Bluetooth —
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.local/bin/bt-codec-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.local/bin/wallpaper-toggle.sh"))

-- — Sistema —
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("wlogout --layout ~/.config/wlogout/layout.json --css ~/.config/wlogout/style.css"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.local/bin/clock-panel-toggle.sh"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -d"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("pkill fuzzel || rofimoji --selector fuzzel --action clipboard"))

-- — Clipboard —
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("pkill fuzzel || cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))
hl.bind("CTRL + SHIFT + Delete", hl.dsp.exec_cmd("cliphist wipe && rm -f ~/.cache/cliphist/db && notify-send \"Clipboard\" \"Histórico limpo\""))

-- — Screenshots —
hl.bind("Print",           hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind("SHIFT + Print",   hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area"))
hl.bind("CTRL + Print",    hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh clipboard"))
hl.bind("ALT + S",         hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh full"))
hl.bind("ALT + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh area"))

-- Regras de float dinâmico por workspace (gerenciado por workspace-float.sh)
dofile(os.getenv("HOME") .. "/.config/hypr/workspace-float.lua")

-- === WINDOW RULES ================================

-- Overskride abre flutuante no workspace atual (sem fixar workspace)
hl.window_rule({
    name   = "overskride-float",
    match  = { class = "^(io.github.kaii_lb.Overskride)$" },
    float  = true,
    size   = {800, 500},
    center = true,
})

-- pavucontrol abre flutuante no workspace atual
hl.window_rule({
    name   = "pavucontrol-float",
    match  = { class = "^(org.pulseaudio.pavucontrol)$" },
    float  = true,
    size   = {800, 500},
    center = true,
})

-- btop aberto pela Waybar usa janela dedicada do Ghostty
hl.window_rule({
    name   = "waybar-btop-float",
    match  = { class = "^(com.mitchellh.ghostty)$", title = "^btop$" },
    float  = true,
    center = true,
})

-- GNOME Calendar aberto pelo painel Quickshell usa tamanho próximo do btop
hl.window_rule({
    name   = "gnome-calendar-float",
    match  = { class = "^(org.gnome.Calendar)$" },
    float  = true,
    size   = {882, 575},
    center = true,
})

-- GNOME Calculator abre compacta e flutuante
hl.window_rule({
    name   = "gnome-calculator-float",
    match  = { class = "^(org.gnome.Calculator)$" },
    float  = true,
    size   = {380, 540},
    center = true,
})

-- Bitwarden abre flutuante por padrão, 1000x800
hl.window_rule({
    name   = "bitwarden-float",
    match  = { class = "^(Bitwarden)$" },
    float  = true,
    size   = {1000, 800},
    center = true,
})

-- Waydroid/YouCine: força janela fullscreen e faz o Android renderizar no
-- tamanho lógico do monitor (1920x1200 / scale 1.25 = 1536x960).
hl.window_rule({
    name       = "waydroid-youcine-fullscreen",
    match      = { class = "^(waydroid.com.world.(youcinetv|youcinemobile))$" },
    fullscreen = true,
})

-- Suprime eventos de maximizar em todas as janelas
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Evita foco em janelas XWayland flutuantes sem classe (fix drag)
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Posiciona o runner do hyprland-run na parte inferior
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = {20, "monitor_h-120"},
    float = true,
})

-- === ANIMAÇÕES (curvas + árvore) =================
hl.curve("easeOutQuint",   { type = "bezier", points = {{0.23, 1},    {0.32, 1}} })
hl.curve("easeInOutCubic", { type = "bezier", points = {{0.65, 0.05}, {0.36, 1}} })
hl.curve("linear",         { type = "bezier", points = {{0, 0},      {1, 1}} })
hl.curve("almostLinear",   { type = "bezier", points = {{0.5, 0.5},  {0.75, 1}} })
hl.curve("quick",          { type = "bezier", points = {{0.15, 0},   {0.1, 1}} })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })
