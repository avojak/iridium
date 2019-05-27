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

public class Iridium.Widgets.HeaderBar : Gtk.HeaderBar {

    private Gtk.Button channel_join_button;

    public HeaderBar () {
        Object (
            title: "Iridium",
            show_close_button: true
        );
    }

    construct {
        var server_connect_button = new Gtk.Button.from_icon_name ("com.github.avojak.iridium.network-server-new", Gtk.IconSize.LARGE_TOOLBAR);
        /* var server_connect_button = new Gtk.Button.from_icon_name ("network-server", Gtk.IconSize.LARGE_TOOLBAR); */
        server_connect_button.tooltip_text = "Connect to a server";
        // TODO: Support keyboard accelerator
        server_connect_button.clicked.connect (() => {
            server_connect_button_clicked ();
        });

        channel_join_button = new Gtk.Button.from_icon_name ("com.github.avojak.iridium.internet-chat-new", Gtk.IconSize.LARGE_TOOLBAR);
        /* var channel_join_button = new Gtk.Button.from_icon_name ("internet-chat", Gtk.IconSize.LARGE_TOOLBAR); */
        channel_join_button.tooltip_text = "Join a channel";
        // TODO: Support keyboard accelerator
        channel_join_button.sensitive = false;
        channel_join_button.clicked.connect (() => {
            channel_join_button_clicked ();
        });

        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.primary_icon_tooltip_text = "Light background";
        mode_switch.secondary_icon_tooltip_text = "Dark background";
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.bind_property ("active", Iridium.Application.settings, "prefer-dark-style");
        mode_switch.notify.connect (() => {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = Iridium.Application.settings.prefer_dark_style;
        });
        if (Iridium.Application.settings.prefer_dark_style) {
            mode_switch.active = true;
        }

        /* get_style_context ().add_class ("default-decoration"); */
        pack_start (server_connect_button);
        pack_start (channel_join_button);

        pack_end (mode_switch);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));

        // TODO: Update the header bar for the current channel and server being viewed
    }

    public void set_channel_join_button_enabled (bool enabled) {
        channel_join_button.sensitive = enabled;
    }

    public void update_title (string title, string? subtitle) {
        this.title = title;
        this.subtitle = subtitle;
    }

    public signal void server_connect_button_clicked ();
    public signal void channel_join_button_clicked ();

}
