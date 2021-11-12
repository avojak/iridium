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

public abstract class Iridium.Widgets.ServerConnectionDialog : Granite.Dialog {

    private static GLib.Regex SERVER_REGEX; // vala-lint=naming-convention
    private static GLib.Regex NICKNAME_REGEX; // vala-lint=naming-convention

    protected Gee.Map<int, Iridium.Models.AuthenticationMethod> auth_methods;
    protected Gee.Map<int, string> auth_method_display_strings;

    protected Gtk.Label password_label;
    protected Gtk.Label certificate_file_label;

    protected Granite.ValidatedEntry server_entry;
    protected Granite.ValidatedEntry nickname_entry;
    protected Granite.ValidatedEntry realname_entry;
    protected Granite.ValidatedEntry password_entry;
    protected Iridium.Widgets.NumberEntry port_entry;
    protected Gtk.FileChooserButton certificate_file_entry;

    protected Gtk.Stack auth_token_label_stack;
    protected Gtk.Stack auth_token_entry_stack;

    protected Gtk.ComboBox auth_method_combo;

    protected Gtk.Switch ssl_tls_switch;

    public string primary_button_text { get; construct; }
    private Gtk.Button primary_button;

    public string header { get; construct; }
    private Gtk.Stack header_image_stack;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    enum AuthColumn {
        AUTH_METHOD
    }

    static construct {
        try {
            SERVER_REGEX = new GLib.Regex ("""^[a-zA-Z0-9\.]+$""", GLib.RegexCompileFlags.OPTIMIZE);
            // See RFC 2812 Section 2.3.1
            NICKNAME_REGEX = new GLib.Regex ("""^[a-zA-Z\[\]\\\`\_\^\{\|\}][a-zA-Z0-9\[\]\\\`\_\^\{\|\}]{0,8}$""", GLib.RegexCompileFlags.OPTIMIZE);
        } catch (GLib.Error e) {
            critical (e.message);
        }
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

        var header_title = new Gtk.Label (header);
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
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
        status_label.set_max_width_chars (50);
        status_label.set_line_wrap (true);
        status_label.margin_bottom = 10;
        status_label.margin_start = 8;
        status_label.margin_end = 8;

        body.add (spinner);
        body.add (status_label);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        primary_button = new Gtk.Button.with_label (primary_button_text);
        primary_button.get_style_context ().add_class ("suggested-action");
        primary_button.sensitive = false;
        primary_button.clicked.connect (do_primary_action);

        // Connect to signals to determine whether the connect button should be sensitive
        // Note: Can't use the preferred Granite.ValidatedEntry way, because that seems to limit
        //       one widget per button, not a set of widgets like in this case.
        server_entry.changed.connect (update_primary_button);
        nickname_entry.changed.connect (update_primary_button);
        realname_entry.changed.connect (update_primary_button);
        port_entry.changed.connect (update_primary_button);
        auth_method_combo.changed.connect (update_primary_button);
        password_entry.changed.connect (update_primary_button);
        certificate_file_entry.file_set.connect (update_primary_button);

        add_action_widget (cancel_button, 0);
        add_action_widget (primary_button, 1);

        load_settings ();
    }

    private void update_primary_button () {
        // Set the update button as sensitive only when all fields are marked as valid
        bool is_auth_token_valid = false;
        var auth_method = auth_methods.get (auth_method_combo.get_active ());
        switch (auth_method) {
            case Iridium.Models.AuthenticationMethod.NONE:
                is_auth_token_valid = true;
                break;
            case Iridium.Models.AuthenticationMethod.SERVER_PASSWORD:
            case Iridium.Models.AuthenticationMethod.NICKSERV_MSG:
            case Iridium.Models.AuthenticationMethod.SASL_PLAIN:
                is_auth_token_valid = password_entry.is_valid;
                break;
            case Iridium.Models.AuthenticationMethod.SASL_EXTERNAL:
                is_auth_token_valid = verify_certificate_file (certificate_file_entry.get_uri ());
                break;
            default:
                assert_not_reached ();
        }
        primary_button.sensitive = server_entry.is_valid &&
                nickname_entry.is_valid &&
                realname_entry.is_valid &&
                port_entry.is_valid &&
                is_auth_token_valid;
    }

    private Gtk.Grid create_basic_form () {
        var basic_form_grid = new Gtk.Grid ();
        basic_form_grid.margin = 30;
        basic_form_grid.row_spacing = 12;
        basic_form_grid.column_spacing = 20;

        var server_label = new Gtk.Label (_("Server:"));
        server_label.halign = Gtk.Align.END;

        server_entry = new Granite.ValidatedEntry.from_regex (SERVER_REGEX);
        server_entry.hexpand = true;
        server_entry.placeholder_text = "irc.example.com";

        var nickname_label = new Gtk.Label (_("Nickname:"));
        nickname_label.halign = Gtk.Align.END;

        nickname_entry = new Granite.ValidatedEntry.from_regex (NICKNAME_REGEX);
        nickname_entry.hexpand = true;
        nickname_entry.placeholder_text = "iridium";

        var realname_label = new Gtk.Label (_("Real Name:"));
        realname_label.halign = Gtk.Align.END;

        realname_entry = new Granite.ValidatedEntry ();
        realname_entry.hexpand = true;
        realname_entry.placeholder_text = _("Iridium IRC Client");
        realname_entry.changed.connect (() => {
            realname_entry.is_valid = realname_entry.get_text ().strip ().length > 0;
        });

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
        auth_methods.set (3, Iridium.Models.AuthenticationMethod.SASL_PLAIN);
        auth_method_display_strings.set (3, Iridium.Models.AuthenticationMethod.SASL_PLAIN.get_display_string ());
        auth_methods.set (4, Iridium.Models.AuthenticationMethod.SASL_EXTERNAL);
        auth_method_display_strings.set (4, Iridium.Models.AuthenticationMethod.SASL_EXTERNAL.get_display_string ());
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
            var auth_method = auth_methods.get (auth_method_combo.get_active ());
            if (!ssl_tls_switch.get_active () && (auth_method == Iridium.Models.AuthenticationMethod.SASL_EXTERNAL)) {
                // Alert user to the SSL/TLS requirement for SASL External
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("SASL External requires SSL/TLS"), _("To use SASL External authentication, you must enable SSL/TLS for this server connection."), "dialog-information", Gtk.ButtonsType.CLOSE);
                message_dialog.run ();
                message_dialog.destroy ();
                // Fall back to SASL Plain in the dialog
                auth_method_combo.set_active (auth_method_combo.get_active () - 1);
                return;
            }
            // Update auth token entry sensitivity
            password_entry.set_sensitive ((auth_method != Iridium.Models.AuthenticationMethod.NONE) && (auth_method != Iridium.Models.AuthenticationMethod.SASL_EXTERNAL));
            certificate_file_entry.set_sensitive (auth_method == Iridium.Models.AuthenticationMethod.SASL_EXTERNAL);
            // Update the visible auth token label and entry
            if (auth_method == Iridium.Models.AuthenticationMethod.SASL_EXTERNAL) {
                show_certificate_stack ();
            } else {
                show_password_stack ();
            }
        });

        password_label = new Gtk.Label (_("Password:"));
        password_label.halign = Gtk.Align.END;

        password_entry = new Granite.ValidatedEntry ();
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
        password_entry.changed.connect (() => {
            password_entry.is_valid = password_entry.get_text ().strip ().length > 0;
        });

        certificate_file_label = new Gtk.Label (_("Identity File:"));
        certificate_file_label.halign = Gtk.Align.END;

        certificate_file_entry = new Gtk.FileChooserButton (_("Select Your Identity File\u2026"), Gtk.FileChooserAction.OPEN);
        certificate_file_entry.hexpand = true;
        certificate_file_entry.sensitive = false;
        certificate_file_entry.set_uri (GLib.Environment.get_home_dir ());

        auth_token_label_stack = new Gtk.Stack ();
        auth_token_label_stack.add (password_label);
        auth_token_label_stack.add (certificate_file_label);

        auth_token_entry_stack = new Gtk.Stack ();
        auth_token_entry_stack.add (password_entry);
        auth_token_entry_stack.add (certificate_file_entry);

        show_password_stack ();

        basic_form_grid.attach (server_label, 0, 0, 1, 1);
        basic_form_grid.attach (server_entry, 1, 0, 1, 1);
        basic_form_grid.attach (nickname_label, 0, 1, 1, 1);
        basic_form_grid.attach (nickname_entry, 1, 1, 1, 1);
        basic_form_grid.attach (realname_label, 0, 2, 1, 1);
        basic_form_grid.attach (realname_entry, 1, 2, 1, 1);
        basic_form_grid.attach (auth_method_label, 0, 3, 1, 1);
        basic_form_grid.attach (auth_method_combo, 1, 3, 1, 1);
        basic_form_grid.attach (auth_token_label_stack, 0, 4, 1, 1);
        basic_form_grid.attach (auth_token_entry_stack, 1, 4, 1, 1);

        return basic_form_grid;
    }

    protected void show_password_stack () {
        Idle.add (() => {
            auth_token_label_stack.set_visible_child (password_label);
            auth_token_entry_stack.set_visible_child (password_entry);
            return false;
        });
    }

    protected void show_certificate_stack () {
        Idle.add (() => {
            auth_token_label_stack.set_visible_child (certificate_file_label);
            auth_token_entry_stack.set_visible_child (certificate_file_entry);
            return false;
        });
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
        ssl_tls_switch.notify["active"].connect (() => {
            // If the user has selected SASL External, fall back to SASL Plain
            var auth_method = auth_methods.get (auth_method_combo.get_active ());
            if (!ssl_tls_switch.get_active () && (auth_method == Iridium.Models.AuthenticationMethod.SASL_EXTERNAL)) {
                auth_method_combo.set_active (auth_method_combo.get_active () - 1);
            }
        });
        ssl_tls_switch.notify["active"].connect (on_security_posture_changed);

        var port_label = new Gtk.Label (_("Port:"));
        port_label.halign = Gtk.Align.END;

        port_entry = new Iridium.Widgets.NumberEntry ();
        port_entry.is_valid = true;
        port_entry.hexpand = true;
        port_entry.text = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT.to_string ();
        port_entry.changed.connect (() => {
            int port = int.parse (port_entry.get_text ().strip ());
            port_entry.is_valid = port >= 1 && port <= 65535;
        });

        advanced_form_grid.attach (ssl_tls_label, 0, 0, 1, 1);
        advanced_form_grid.attach (ssl_tls_switch_container, 1, 0, 1, 1);
        advanced_form_grid.attach (port_label, 0, 1, 1, 1);
        advanced_form_grid.attach (port_entry, 1, 1, 1, 1);

        return advanced_form_grid;
    }

    protected bool verify_certificate_file (string? uri) {
        if (uri == null) {
            return false;
        }
        display_error ("");
        try {
            new GLib.TlsCertificate.from_file (GLib.File.new_for_uri (uri).get_path ());
            return true;
        } catch (GLib.Error e) {
            display_error (_("Invalid identity file"), e.message);
            return false;
        }
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
        realname_entry.text = Iridium.Application.settings.get_string ("default-realname");
    }

    private void do_primary_action () {
        spinner.start ();
        status_label.label = "";
        var server_name = server_entry.get_text ().strip ();
        var nickname = nickname_entry.get_text ().strip ();
        var realname = realname_entry.get_text ().strip ();
        var port = (uint16) int.parse (port_entry.get_text ().strip ());
        if (port == 0) {
            port = Iridium.Services.ServerConnectionDetails.DEFAULT_SECURE_PORT;
        }
        var auth_method = auth_methods.get (auth_method_combo.get_active ());
        var auth_token = (auth_method == Iridium.Models.AuthenticationMethod.SASL_EXTERNAL) ? certificate_file_entry.get_uri () : password_entry.get_text ();
        var tls = ssl_tls_switch.get_active ();
        primary_button_clicked (server_name, nickname, realname, port, auth_method, tls, auth_token);
    }

    public string get_server () {
        return server_entry.get_text ().strip ();
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

    public signal void primary_button_clicked (string server, string nickname, string realname,
        uint16 port, Iridium.Models.AuthenticationMethod auth_method, bool tls, string auth_token);

}
