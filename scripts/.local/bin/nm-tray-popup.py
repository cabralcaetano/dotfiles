#!/usr/bin/env python3
"""Abre o menu nativo do nm-applet (libdbusmenu-gtk, mesma lib que o tray do
Waybar usa por baixo) como popup solto — pro clique no ícone de wifi da
Waybar (módulo "network") abrir o mesmo menu que aparece clicando no
nm-applet dentro do tray, sem precisar passar pela seta "<" que esconde o
tray atrás de um drawer.

No Wayland, um GtkMenu (xdg_popup) exige uma xdg_surface pai já mapeada;
por isso o script cria uma janela host de 1x1 (ver regra hyprland.lua
"nm-tray-popup-host": floating, movida pro canto onde fica o ícone de wifi
na Waybar) e ancora o menu nela via popup_at_widget — evita depender de
posição de mouse (popup_at_pointer não funciona sem evento de clique real
no GTK/Wayland, dá "no trigger event for menu popup").

Requer nm-applet rodando (autostart no hyprland.lua) e registrado no
StatusNotifierWatcher.

Uso:
    python3 ~/.local/bin/nm-tray-popup.py
"""
import sys

import dbus
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("DbusmenuGtk3", "0.4")
from gi.repository import DbusmenuGtk3, Gdk, GLib, Gtk  # noqa: E402

GLib.set_prgname("nm-tray-popup")

# Paleta já usada no Ghostty/Waybar/Hyprlock (ver tmux.conf): fundo #1d1d20,
# texto #deddda, borda/separador #3a3a3e (tmux_power_g2), destaque #a0a0a0.
# CssProvider fica só na tela deste processo — não afeta o tema GTK3 global
# nem o ícone/menu nativo do nm-applet renderizado pelo próprio Waybar.
_POPUP_CSS = b"""
menu {
    background-color: #1d1d20;
    color: #deddda;
    border: 1px solid #3a3a3e;
    border-radius: 8px;
    padding: 4px;
}
menu menuitem {
    color: #deddda;
    border-radius: 4px;
    padding: 4px 8px;
}
menu menuitem:hover {
    background-color: #a0a0a0;
    color: #1d1d20;
}
menu separator {
    background-color: #3a3a3e;
    min-height: 1px;
    margin: 4px 0;
}
"""


def apply_theme():
    provider = Gtk.CssProvider()
    provider.load_from_data(_POPUP_CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER
    )


def find_nm_applet_menu():
    bus = dbus.SessionBus()
    watcher = bus.get_object("org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher")
    props = dbus.Interface(watcher, "org.freedesktop.DBus.Properties")
    items = props.Get("org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems")
    for item in items:
        if "nm_applet" in item or "nm-applet" in item:
            bus_name, _, obj_path = item.partition("/")
            sni = bus.get_object(bus_name, "/" + obj_path)
            sni_props = dbus.Interface(sni, "org.freedesktop.DBus.Properties")
            menu_path = sni_props.Get("org.kde.StatusNotifierItem", "Menu")
            return bus_name, str(menu_path)
    sys.exit("nm-tray-popup: nm-applet não registrado no StatusNotifierWatcher (rodando?)")


def main():
    apply_theme()
    bus_name, menu_path = find_nm_applet_menu()
    menu = DbusmenuGtk3.Menu.new(bus_name, menu_path)

    host = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
    host.set_title("nm-tray-popup")
    host.set_decorated(False)
    host.set_default_size(1, 1)
    host.set_skip_taskbar_hint(True)
    host.set_skip_pager_hint(True)
    host.show()

    def do_popup():
        menu.attach_to_widget(host, None)
        menu.connect("hide", lambda _w: Gtk.main_quit())
        menu.show_all()
        menu.popup_at_widget(host, Gdk.Gravity.SOUTH_WEST, Gdk.Gravity.NORTH_WEST, None)
        return False

    # dá tempo do host ser mapeado pelo Hyprland (regra float+move) antes de
    # ancorar o popup nele
    GLib.timeout_add(300, do_popup)
    GLib.timeout_add(10000, Gtk.main_quit)
    Gtk.main()


if __name__ == "__main__":
    main()
