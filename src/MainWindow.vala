/*
 * Copyright (c) 2019 Andrew Vojak (https://avojak.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Andrew Vojak <andrew.vojak@gmail.com>
 */

public class Iridium.MainWindow : Gtk.ApplicationWindow {

    public Iridium.Widgets.ServerConnectionDialog? connection_dialog = null;

    private Iridium.Views.Welcome welcome_view;
    private Iridium.Widgets.ServerPanel server_panel;
    private Iridium.Layouts.MainLayout main_layout;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            border_width: 0,
            resizable: true,
            title: "Iridium",
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        var gtk_settings = Gtk.Settings.get_default ();

        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.primary_icon_tooltip_text = "Light background";
        mode_switch.secondary_icon_tooltip_text = "Dark background";
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");

        Iridium.Application.settings.bind ("prefer-dark-style", mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var header_bar = new Gtk.HeaderBar ();
        header_bar.show_close_button = true;
        header_bar.pack_end (mode_switch);
        header_bar.pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));

        set_titlebar (header_bar);

        welcome_view = new Iridium.Views.Welcome (this);
        server_panel = new Iridium.Widgets.ServerPanel ();

        main_layout = new Iridium.Layouts.MainLayout (welcome_view, server_panel);
        add (main_layout);

        resize (900, 600);
    }

    public void add_server_to_panel (string name) {
        server_panel.add_server (name);
    }

}
