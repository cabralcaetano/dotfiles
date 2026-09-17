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
