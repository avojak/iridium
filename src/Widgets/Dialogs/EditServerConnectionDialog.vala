/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
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

public class Iridium.Widgets.EditServerConnectionDialog : Iridium.Widgets.ServerConnectionDialog {

    public Iridium.Services.ServerConnectionDetails? connection_details { get; construct; }

    public EditServerConnectionDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Edit a Server Connection"),
            header: _("Edit Connection"),
            primary_button_text: _("Save"),
            transient_for: main_window,
            modal: true
        );
    }

    public EditServerConnectionDialog.from_connection_details (Iridium.MainWindow main_window, Iridium.Services.ServerConnectionDetails connection_details) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Edit a Server Connection"),
            header: _("Edit Connection"),
            primary_button_text: _("Save"),
            transient_for: main_window,
            connection_details: connection_details,
            modal: true
        );
    }

    construct {
        if (connection_details != null) {
            server_entry.set_text (connection_details.server);
            nickname_entry.set_text (connection_details.nickname);
            realname_entry.set_text (connection_details.realname);
            port_entry.set_text (connection_details.port.to_string ());
            auth_method_combo.set_active (get_auth_method_index (connection_details.auth_method));
            ssl_tls_switch.set_active (connection_details.tls);
            if (connection_details.auth_method == Iridium.Models.AuthenticationMethod.SASL_EXTERNAL) {
                if (connection_details.auth_token != null) {
                    verify_certificate_file (connection_details.auth_token);
                    certificate_file_entry.set_uri (connection_details.auth_token);
                }
                certificate_file_entry.sensitive = true;
                password_entry.sensitive = false;
                show_certificate_stack ();
            } else {
                if (connection_details.auth_token != null) {
                    password_entry.set_text (connection_details.auth_token);
                }
                certificate_file_entry.sensitive = false;
                password_entry.sensitive = true;
                show_password_stack ();
            }
        }
    }

}
