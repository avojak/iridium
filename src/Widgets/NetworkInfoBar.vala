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

public class Iridium.Widgets.NetworkInfoBar : Gtk.InfoBar {

    private const string SETTINGS_URI = "settings://network";

    public NetworkInfoBar () {
        Object (
            message_type: Gtk.MessageType.WARNING,
            show_close_button: false,
            revealed: false
        );
    }

    construct {
        var network_info_label = new Gtk.Label (_("Network is not available"));
        get_content_area ().add (network_info_label);
        get_style_context ().add_class ("inline");
        add_button (_("Network Settings…"), 0);

        this.response.connect ((response) => {
            if (response == 0) {
                try {
                    AppInfo.launch_default_for_uri (SETTINGS_URI, null);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }
        });
    }

}
