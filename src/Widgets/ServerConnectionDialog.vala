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

public class Iridium.Widgets.ServerConnectionDialog : Gtk.Dialog {

    public unowned Iridium.MainWindow main_window { get; construct; }

    private Gtk.Entry server_entry;
    private Gtk.Entry nickname_entry;
    private Gtk.Entry username_entry;
    private Gtk.Entry realname_entry;
    private Gee.Map<int, Iridium.Models.AuthenticationMethod> auth_methods;
    private Gee.Map<int, string> auth_method_display_strings;
    private Gtk.ComboBox auth_method_combo;
    private Gtk.Entry password_entry;
    private Gtk.Switch ssl_tls_switch;
    private Gee.Map<int, Iridium.Models.InvalidCertificatePolicy> invalid_cert_policies;
    private Gee.Map<int, string> invalid_cert_policies_display_strings;
    private Gtk.ComboBox cert_validation_policy_combo;
    private Gtk.Entry port_entry;

    private Gtk.Image security_image;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    enum Column {
        AUTH_METHOD
    }

    public ServerConnectionDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Connect to a Server"),
            transient_for: main_window,
            modal: true,
            main_window: main_window
        );
    }

    construct {
        var body = get_content_area ();

        // Create the header
        var header_grid = new Gtk.Grid ();
		header_grid.margin_start = 30;
		header_grid.margin_end = 30;
		header_grid.margin_bottom = 10;
        header_grid.column_spacing = 10;

        var header_image = new Gtk.Image.from_icon_name ("network-server", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("New Connection"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        security_image = new Gtk.Image.from_icon_name ("security-high", Gtk.IconSize.DIALOG);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);
        header_grid.attach (security_image, 2, 0, 1, 1);

        body.add (header_grid);

        var stack_grid = new Gtk.Grid ();
        stack_grid.expand = true;
        stack_grid.margin_top = 20;

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_grid.attach (stack_switcher, 0, 0, 1, 1);

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack_switcher.stack = stack;

        stack.add_titled (create_basic_form (), "basic", _("Basic"));
        stack.add_titled (create_advanced_form (), "advanced", _("Advanced"));
        stack_grid.attach (stack, 0, 1, 1, 1);

        body.add (stack_grid);

        spinner = new Gtk.Spinner ();
        body.add (spinner);

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_line_wrap (true);
        status_label.margin_bottom = 10;
        body.add (status_label);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        var connect_button = new Gtk.Button.with_label (_("Connect"));
        connect_button.get_style_context ().add_class ("suggested-action");
        connect_button.clicked.connect (() => {
            // TODO: Validate entries first!
            spinner.start ();
            status_label.label = "";
            var server_name = server_entry.get_text ().chomp ().chug ();
            var nickname = nickname_entry.get_text ().chomp ().chug ();
            var username = username_entry.get_text ().chomp ().chug ();
            var realname = realname_entry.get_text ().chomp ().chug ();
            var port = (uint16) port_entry.get_text ().chomp ().chug ().to_int ();
            if (port == 0) {
                port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT;
            }
            var auth_method = auth_methods.get (auth_method_combo.get_active ());
            var auth_token = password_entry.get_text ();
            var tls = ssl_tls_switch.get_active ();
            var invalid_cert_policy = invalid_cert_policies.get (cert_validation_policy_combo.get_active ());
            connect_button_clicked (server_name, nickname, username, realname, port, auth_method, tls, invalid_cert_policy, auth_token);
        });

        add_action_widget (cancel_button, 0);
        add_action_widget (connect_button, 1);
    }

    private Gtk.Grid create_basic_form () {
        var basic_form_grid = new Gtk.Grid ();
        basic_form_grid.margin = 30;
        basic_form_grid.row_spacing = 12;
        basic_form_grid.column_spacing = 20;

        var server_label = new Gtk.Label (_("Server:"));
        server_label.halign = Gtk.Align.END;

        server_entry = new Gtk.Entry ();
        server_entry.hexpand = true;
        server_entry.placeholder_text = "irc.freenode.net";

        var nickname_label = new Gtk.Label (_("Nickname:"));
        nickname_label.halign = Gtk.Align.END;

        nickname_entry = new Gtk.Entry ();
        nickname_entry.hexpand = true;
        nickname_entry.placeholder_text = "iridium";

        var username_label = new Gtk.Label (_("Username:"));
        username_label.halign = Gtk.Align.END;

        username_entry = new Gtk.Entry ();
        username_entry.hexpand = true;
        username_entry.placeholder_text = "iridium";

        var realname_label = new Gtk.Label (_("Real Name:"));
        realname_label.halign = Gtk.Align.END;

        realname_entry = new Gtk.Entry ();
        realname_entry.hexpand = true;
        realname_entry.placeholder_text = _("Iridium IRC Client");

        var auth_method_label = new Gtk.Label (_("Authentication Method:"));
        auth_method_label.halign = Gtk.Align.END;

        var list_store = new Gtk.ListStore (1, typeof (string));
        // TODO: This can be handled better
        auth_methods = new Gee.HashMap<int, Iridium.Models.AuthenticationMethod> ();
        auth_method_display_strings = new Gee.HashMap<int, string> ();
        auth_methods.set(0, Iridium.Models.AuthenticationMethod.NONE);
        auth_method_display_strings.set (0, Iridium.Models.AuthenticationMethod.NONE.get_display_string ());
        auth_methods.set(1, Iridium.Models.AuthenticationMethod.SERVER_PASSWORD);
        auth_method_display_strings.set (1, Iridium.Models.AuthenticationMethod.SERVER_PASSWORD.get_display_string ());
        auth_methods.set(2, Iridium.Models.AuthenticationMethod.NICKSERV_MSG);
        auth_method_display_strings.set (2, Iridium.Models.AuthenticationMethod.NICKSERV_MSG.get_display_string ());
        for (int i = 0; i < auth_method_display_strings.size; i++) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, Column.AUTH_METHOD, auth_method_display_strings[i]);
        }
        auth_method_combo = new Gtk.ComboBox.with_model (list_store);
        var auth_method_cell = new Gtk.CellRendererText ();
        auth_method_combo.pack_start (auth_method_cell, false);
        auth_method_combo.set_attributes (auth_method_cell, "text", 0);
        auth_method_combo.set_active (0);

        auth_method_combo.changed.connect (() => {
            password_entry.set_sensitive (auth_methods.get (auth_method_combo.get_active ()) != Iridium.Models.AuthenticationMethod.NONE);
        });

        var password_label = new Gtk.Label (_("Password:"));
        password_label.halign = Gtk.Align.END;

        password_entry = new Gtk.Entry ();
        password_entry.hexpand = true;
        password_entry.visibility = false;
        password_entry.sensitive = false;
        password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "changes-prevent-symbolic");
        password_entry.icon_press.connect ((pos, event) => {
            if (pos == Gtk.EntryIconPosition.SECONDARY) {
                password_entry.visibility = !password_entry.visibility;
            }
            if (password_entry.visibility) {
                password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "changes-allow-symbolic");
            } else {
                password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "changes-prevent-symbolic");
            }
        });

        basic_form_grid.attach (server_label, 0, 0, 1, 1);
        basic_form_grid.attach (server_entry, 1, 0, 1, 1);
        basic_form_grid.attach (nickname_label, 0, 1, 1, 1);
        basic_form_grid.attach (nickname_entry, 1, 1, 1, 1);
        basic_form_grid.attach (username_label, 0, 2, 1, 1);
        basic_form_grid.attach (username_entry, 1, 2, 1, 1);
        basic_form_grid.attach (realname_label, 0, 3, 1, 1);
        basic_form_grid.attach (realname_entry, 1, 3, 1, 1);
        basic_form_grid.attach (auth_method_label, 0, 4, 1, 1);
        basic_form_grid.attach (auth_method_combo, 1, 4, 1, 1);
        basic_form_grid.attach (password_label, 0, 5, 1, 1);
        basic_form_grid.attach (password_entry, 1, 5, 1, 1);

        return basic_form_grid;
    }

    private Gtk.Grid create_advanced_form () {
        var advanced_form_grid = new Gtk.Grid ();
        advanced_form_grid.margin = 30;
        advanced_form_grid.row_spacing = 12;
        advanced_form_grid.column_spacing = 20;

        var ssl_tls_label = new Gtk.Label (_("Use SSL/TLS:"));
        ssl_tls_label.halign = Gtk.Align.END;

        ssl_tls_switch = new Gtk.Switch ();
        var ssl_tls_switch_container = new Gtk.Grid ();
        ssl_tls_switch_container.add (ssl_tls_switch);
        ssl_tls_switch.state = true;
        ssl_tls_switch.active = true;

        ssl_tls_switch.notify["active"].connect (() => {
            cert_validation_policy_combo.set_sensitive (ssl_tls_switch.get_active ());
            port_entry.placeholder_text = ssl_tls_switch.get_active ()
                ? Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT.to_string ()
                : Iridium.Services.ServerConnectionDetails.DEFAULT_INSECURE_PORT.to_string ();
        });
        ssl_tls_switch.notify["active"].connect (on_security_posture_changed);

        var cert_validation_policy_label = new Gtk.Label (_("Invalid Certificates:"));
        cert_validation_policy_label.halign = Gtk.Align.END;

        var invalid_cert_policies_list_store = new Gtk.ListStore (1, typeof (string));
        // TODO: This can be handled better
        invalid_cert_policies = new Gee.HashMap<int, Iridium.Models.InvalidCertificatePolicy> ();
        invalid_cert_policies_display_strings = new Gee.HashMap<int, string> ();
        invalid_cert_policies.set(0, Iridium.Models.InvalidCertificatePolicy.REJECT);
        invalid_cert_policies_display_strings.set (0, Iridium.Models.InvalidCertificatePolicy.REJECT.get_display_string ());
        invalid_cert_policies.set(1, Iridium.Models.InvalidCertificatePolicy.WARN);
        invalid_cert_policies_display_strings.set (1, Iridium.Models.InvalidCertificatePolicy.WARN.get_display_string ());
        invalid_cert_policies.set(2, Iridium.Models.InvalidCertificatePolicy.ALLOW);
        invalid_cert_policies_display_strings.set (2, Iridium.Models.InvalidCertificatePolicy.ALLOW.get_display_string ());
        for (int i = 0; i < invalid_cert_policies_display_strings.size; i++) {
            Gtk.TreeIter iter;
            invalid_cert_policies_list_store.append (out iter);
            invalid_cert_policies_list_store.set (iter, Column.AUTH_METHOD, invalid_cert_policies_display_strings[i]);
        }
        cert_validation_policy_combo = new Gtk.ComboBox.with_model (invalid_cert_policies_list_store);
        var cert_validation_policy_cell = new Gtk.CellRendererText ();
        cert_validation_policy_combo.pack_start (cert_validation_policy_cell, false);
        cert_validation_policy_combo.set_attributes (cert_validation_policy_cell, "text", 0);
        cert_validation_policy_combo.set_active (0);

        cert_validation_policy_combo.changed.connect (on_security_posture_changed);

        var port_label = new Gtk.Label (_("Port:"));
        port_label.halign = Gtk.Align.END;

        // TODO: Force numeric input
        port_entry = new Gtk.Entry ();
        port_entry.hexpand = true;
        port_entry.placeholder_text = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT.to_string ();

        advanced_form_grid.attach (ssl_tls_label, 0, 0, 1, 1);
        advanced_form_grid.attach (ssl_tls_switch_container, 1, 0, 1, 1);
        advanced_form_grid.attach (cert_validation_policy_label, 0, 1, 1, 1);
        advanced_form_grid.attach (cert_validation_policy_combo, 1, 1, 1, 1);
        advanced_form_grid.attach (port_label, 0, 2, 1, 1);
        advanced_form_grid.attach (port_entry, 1, 2, 1, 1);

        return advanced_form_grid;
    }

    private void on_security_posture_changed () {
        // TODO: Display text with a recommendation
        if (ssl_tls_switch.get_active ()) {
            switch (invalid_cert_policies.get (cert_validation_policy_combo.get_active ())) {
                case REJECT:
                    security_image.icon_name = "security-high";
                    break;
                case WARN:
                    security_image.icon_name = "security-medium";
                    break;
                case ALLOW:
                    security_image.icon_name = "security-low";
                    break;
                default:
                    assert_not_reached ();
            }
        } else {
            security_image.icon_name = "security-low";
        }
    }

    public void dismiss () {
        spinner.stop ();
        close ();
    }

    public void display_error (string message) {
        // TODO: We can make the error messaging better (wrap text!)
        spinner.stop ();
        status_label.label = message;
    }

    public signal void connect_button_clicked (string server, string nickname, string username, string realname, 
        uint16 port, Iridium.Models.AuthenticationMethod auth_method, bool tls, 
        Iridium.Models.InvalidCertificatePolicy invalid_cert_policy, string auth_token);

}
