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

    private Gtk.Entry server_entry;
    private Gtk.Entry nickname_entry;
    //  private Gtk.Entry username_entry;
    private Gtk.Entry realname_entry;
    private Gee.Map<int, Iridium.Models.AuthenticationMethod> auth_methods;
    private Gee.Map<int, string> auth_method_display_strings;
    private Gtk.ComboBox auth_method_combo;
    private Gtk.Entry password_entry;
    private Gtk.Switch ssl_tls_switch;
    private Gtk.Entry port_entry;
    private Gtk.Button connect_button;

    private Gtk.Stack header_image_stack;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    enum AuthColumn {
        AUTH_METHOD
    }

    public ServerConnectionDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Connect to a Server"),
            transient_for: main_window,
            modal: true
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

        header_image_stack = new Gtk.Stack ();
        var tls_reject_header_image = new Gtk.Image.from_icon_name (Constants.APP_ID + ".network-server-security-high", Gtk.IconSize.DIALOG);
        tls_reject_header_image.tooltip_text = _("Connection secure");
        var tls_warn_header_image = new Gtk.Image.from_icon_name (Constants.APP_ID + ".network-server-security-medium", Gtk.IconSize.DIALOG);
        tls_warn_header_image.tooltip_text = _("Connection secure, provided only trusted certificates are accepted when prompted");
        var tls_allow_header_image = new Gtk.Image.from_icon_name (Constants.APP_ID + ".network-server-security-low", Gtk.IconSize.DIALOG);
        tls_allow_header_image.tooltip_text = _("Connection may be insecure. Consider rejecting unacceptable certificates from the application preferences.");
        var no_tls_header_image = new Gtk.Image.from_icon_name (Constants.APP_ID + ".network-server-security-low", Gtk.IconSize.DIALOG);
        no_tls_header_image.tooltip_text = _("Connection insecure. Consider enabling SSL/TLS from the Advanced tab.");
        header_image_stack.add_named (tls_reject_header_image, "tls-reject");
        header_image_stack.add_named (tls_warn_header_image, "tls-warn");
        header_image_stack.add_named (tls_allow_header_image, "tls-allow");
        header_image_stack.add_named (no_tls_header_image, "no-tls");
        header_image_stack.show_all (); // Required in order to set the visible child from preferences


        var header_title = new Gtk.Label (_("New Connection"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        //  header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image_stack, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

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

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_line_wrap (true);
        status_label.margin_bottom = 10;

        body.add (spinner);
        body.add (status_label);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        connect_button = new Gtk.Button.with_label (_("Connect"));
        connect_button.get_style_context ().add_class ("suggested-action");
        connect_button.sensitive = false;
        connect_button.clicked.connect (() => {
            do_connect ();
        });

        // Connect to signals to determine whether the connect button should be sensitive
        server_entry.changed.connect (update_connect_button);
        nickname_entry.changed.connect (update_connect_button);
        realname_entry.changed.connect (update_connect_button);
        port_entry.changed.connect (update_connect_button);


        add_action_widget (cancel_button, 0);
        add_action_widget (connect_button, 1);

        load_settings ();
    }

    private void update_connect_button () {
        if (server_entry.get_text ().chomp ().chug () != "" &&
                nickname_entry.get_text ().chomp ().chug () != "" &&
                realname_entry.get_text ().chomp ().chug () != "" &&
                port_entry.get_text ().chomp ().chug () != "") {
            connect_button.sensitive = true;
        } else {
            connect_button.sensitive = false;
        }
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
        server_entry.placeholder_text = "irc.example.com";

        var nickname_label = new Gtk.Label (_("Nickname:"));
        nickname_label.halign = Gtk.Align.END;

        nickname_entry = new Gtk.Entry ();
        nickname_entry.hexpand = true;
        nickname_entry.placeholder_text = "iridium";

        //  var username_label = new Gtk.Label (_("Username:"));
        //  username_label.halign = Gtk.Align.END;

        //  username_entry = new Gtk.Entry ();
        //  username_entry.hexpand = true;
        //  username_entry.placeholder_text = "iridium";

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
        auth_methods.set (0, Iridium.Models.AuthenticationMethod.NONE);
        auth_method_display_strings.set (0, Iridium.Models.AuthenticationMethod.NONE.get_display_string ());
        auth_methods.set (1, Iridium.Models.AuthenticationMethod.SERVER_PASSWORD);
        auth_method_display_strings.set (1, Iridium.Models.AuthenticationMethod.SERVER_PASSWORD.get_display_string ());
        auth_methods.set (2, Iridium.Models.AuthenticationMethod.NICKSERV_MSG);
        auth_method_display_strings.set (2, Iridium.Models.AuthenticationMethod.NICKSERV_MSG.get_display_string ());
        for (int i = 0; i < auth_method_display_strings.size; i++) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, AuthColumn.AUTH_METHOD, auth_method_display_strings[i]);
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
        //  basic_form_grid.attach (username_label, 0, 2, 1, 1);
        //  basic_form_grid.attach (username_entry, 1, 2, 1, 1);
        basic_form_grid.attach (realname_label, 0, 2, 1, 1);
        basic_form_grid.attach (realname_entry, 1, 2, 1, 1);
        basic_form_grid.attach (auth_method_label, 0, 3, 1, 1);
        basic_form_grid.attach (auth_method_combo, 1, 3, 1, 1);
        basic_form_grid.attach (password_label, 0, 4, 1, 1);
        basic_form_grid.attach (password_entry, 1, 4, 1, 1);

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
            port_entry.text = ssl_tls_switch.get_active ()
                ? Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT.to_string ()
                : Iridium.Services.ServerConnectionDetails.DEFAULT_INSECURE_PORT.to_string ();
        });
        ssl_tls_switch.notify["active"].connect (on_security_posture_changed);

        var port_label = new Gtk.Label (_("Port:"));
        port_label.halign = Gtk.Align.END;

        // TODO: Force numeric input
        port_entry = new Gtk.Entry ();
        port_entry.hexpand = true;
        port_entry.text = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT.to_string ();

        advanced_form_grid.attach (ssl_tls_label, 0, 0, 1, 1);
        advanced_form_grid.attach (ssl_tls_switch_container, 1, 0, 1, 1);
        advanced_form_grid.attach (port_label, 0, 1, 1, 1);
        advanced_form_grid.attach (port_entry, 1, 1, 1, 1);

        return advanced_form_grid;
    }

    private void on_security_posture_changed () {
        if (ssl_tls_switch.get_active ()) {
            var cert_policy = Iridium.Application.settings.get_string ("certificate-validation-policy");
            switch (Iridium.Models.InvalidCertificatePolicy.get_value_by_short_name (cert_policy)) {
                case REJECT:
                    header_image_stack.set_visible_child_name ("tls-reject");
                    break;
                case WARN:
                    header_image_stack.set_visible_child_name ("tls-warn");
                    break;
                case ALLOW:
                    header_image_stack.set_visible_child_name ("tls-allow");
                    break;
                default:
                    assert_not_reached ();
            }
        } else {
            header_image_stack.set_visible_child_name ("no-tls");
        }
    }

    private void load_settings () {
        on_security_posture_changed ();
        nickname_entry.text = Iridium.Application.settings.get_string ("default-nickname");
        //  username_entry.text = Iridium.Application.settings.get_string ("default-nickname");
        realname_entry.text = Iridium.Application.settings.get_string ("default-realname");
    }

    private void do_connect () {
        // TODO: Validate entries first!
        spinner.start ();
        status_label.label = "";
        var server_name = server_entry.get_text ().chomp ().chug ();
        var nickname = nickname_entry.get_text ().chomp ().chug ();
        //  var username = username_entry.get_text ().chomp ().chug ();
        var realname = realname_entry.get_text ().chomp ().chug ();
        var port = (uint16) int.parse (port_entry.get_text ().chomp ().chug ());
        if (port == 0) {
            port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT;
        }
        var auth_method = auth_methods.get (auth_method_combo.get_active ());
        var auth_token = password_entry.get_text ();
        var tls = ssl_tls_switch.get_active ();
        connect_button_clicked (server_name, nickname, realname, port, auth_method, tls, auth_token);
    }

    public string get_server () {
        return server_entry.get_text ().chomp ().chug ();
    }

    public void dismiss () {
        spinner.stop ();
        close ();
    }

    public void display_error (string message, string? details = null) {
        // TODO: We can make the error messaging better (wrap text!)
        spinner.stop ();
        status_label.label = message;
        if (details != null) {
            status_label.label += "\n";
            status_label.label += details;
        }
    }

    public signal void connect_button_clicked (string server, string nickname, string realname,
        uint16 port, Iridium.Models.AuthenticationMethod auth_method, bool tls, string auth_token);

}
