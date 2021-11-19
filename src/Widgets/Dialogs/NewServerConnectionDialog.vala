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

public class Iridium.Widgets.NewServerConnectionDialog : Iridium.Widgets.ServerConnectionDialog {

    public Iridium.Models.CuratedServer? curated_server { get; construct; }

    public NewServerConnectionDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Connect to a Server"),
            header: _("New Connection"),
            primary_button_text: _("Connect"),
            transient_for: main_window,
            modal: true
        );
    }

    public NewServerConnectionDialog.from_curated_server (Iridium.MainWindow main_window, Iridium.Models.CuratedServer curated_server) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Connect to a Server"),
            header: _("Open Connection"),
            primary_button_text: _("Connect"),
            transient_for: main_window,
            curated_server: curated_server,
            modal: true
        );
    }

    construct {
        // Set placeholder text
        server_entry.placeholder_text = "irc.example.com";
        nickname_entry.placeholder_text = "iridium";
        realname_entry.placeholder_text = _("Iridium IRC Client");

        if (curated_server != null) {
            server_entry.set_text (curated_server.server_host);
            port_entry.set_text (curated_server.port.to_string ());
            ssl_tls_switch.set_active (curated_server.tls);
            auth_method_combo.set_active (get_auth_method_index (curated_server.auth_method));
        }
    }

}
