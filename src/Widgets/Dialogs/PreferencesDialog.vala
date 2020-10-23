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

public class Iridium.Widgets.PreferencesDialog : Gtk.Dialog {

    private static Gtk.CssProvider provider;

    public unowned Iridium.MainWindow main_window { get; construct; }
    
    private Gtk.Entry default_nickname_entry;
    private Gtk.Entry default_realname_entry;
    private Gee.Map<int, Iridium.Models.InvalidCertificatePolicy> cert_policies;
    private Gtk.ComboBox cert_validation_policy_combo;
    private Gtk.Stack security_posture_stack;

    enum CertColumn {
        CERT_POLICY
    }

    public PreferencesDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Preferences"),
            transient_for: main_window,
            modal: false,
            main_window: main_window
        );
    }

    static construct {
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/avojak/iridium/PreferencesDialog.css");
    }

    construct {
        var body = get_content_area ();

        // Create the header
        var header_grid = new Gtk.Grid ();
        header_grid.margin_start = 30;
        header_grid.margin_end = 30;
        header_grid.margin_bottom = 10;
        header_grid.column_spacing = 10;

        var header_image = new Gtk.Image.from_icon_name ("preferences-system", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("Preferences"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

        // Create the form
        var form_grid = new Gtk.Grid ();
        form_grid.margin = 30;
        form_grid.row_spacing = 6;
        form_grid.column_spacing = 12;

        var general_header_label = new Granite.HeaderLabel (_("General"));

        var default_nickname_label = new Gtk.Label (_("Default Nickname:"));
        default_nickname_label.halign = Gtk.Align.END;

        default_nickname_entry = new Gtk.Entry ();
        default_nickname_entry.hexpand = true;
        default_nickname_entry.changed.connect (() => {
            Iridium.Application.settings.set_string ("default-nickname", default_nickname_entry.text.chomp ().chug ());
        });

        var default_realname_label = new Gtk.Label (_("Default Real Name:"));
        default_realname_label.halign = Gtk.Align.END;

        default_realname_entry = new Gtk.Entry ();
        default_realname_entry.hexpand = true;
        default_realname_entry.changed.connect (() => {
            Iridium.Application.settings.set_string ("default-realname", default_realname_entry.text.chomp ().chug ());
        });

        var security_header_label = new Granite.HeaderLabel (_("Security and Privacy"));

        var cert_validation_policy_label = new Gtk.Label (_("Unacceptable SSL/TLS Certificates:"));
        cert_validation_policy_label.halign = Gtk.Align.END;

        var cert_policies_list_store = new Gtk.ListStore (1, typeof (string));
        // TODO: This can be handled better
        cert_policies = new Gee.HashMap<int, Iridium.Models.InvalidCertificatePolicy> ();
        var cert_policies_display_strings = new Gee.HashMap<int, string> ();
        cert_policies.set (0, Iridium.Models.InvalidCertificatePolicy.REJECT);
        cert_policies_display_strings.set (0, Iridium.Models.InvalidCertificatePolicy.REJECT.get_display_string ());
        cert_policies.set (1, Iridium.Models.InvalidCertificatePolicy.WARN);
        cert_policies_display_strings.set (1, Iridium.Models.InvalidCertificatePolicy.WARN.get_display_string ());
        cert_policies.set (2, Iridium.Models.InvalidCertificatePolicy.ALLOW);
        cert_policies_display_strings.set (2, Iridium.Models.InvalidCertificatePolicy.ALLOW.get_display_string ());
        for (int i = 0; i < cert_policies_display_strings.size; i++) {
            Gtk.TreeIter iter;
            cert_policies_list_store.append (out iter);
            cert_policies_list_store.set (iter, CertColumn.CERT_POLICY, cert_policies_display_strings[i]);
        }
        cert_validation_policy_combo = new Gtk.ComboBox.with_model (cert_policies_list_store);
        var cert_validation_policy_cell = new Gtk.CellRendererText ();
        cert_validation_policy_combo.hexpand = true;
        cert_validation_policy_combo.pack_start (cert_validation_policy_cell, false);
        cert_validation_policy_combo.set_attributes (cert_validation_policy_cell, "text", 0);
        //  cert_validation_policy_combo.set_active (0);

        cert_validation_policy_combo.changed.connect (() => {
            on_security_posture_changed ();
            var short_name = cert_policies.get (cert_validation_policy_combo.get_active ()).get_short_name ();
            Iridium.Application.settings.set_string ("certificate-validation-policy", short_name);
        });

        security_posture_stack = new Gtk.Stack ();
        security_posture_stack.expand = true;
        security_posture_stack.hhomogeneous = true;
        security_posture_stack.vhomogeneous = true;
        security_posture_stack.margin_bottom = 10;
        security_posture_stack.halign = Gtk.Align.END;

        var tls_cert_reject_grid = new Gtk.Grid ();
        tls_cert_reject_grid.column_spacing = 10;
        var tls_cert_reject_image = new Gtk.Image.from_icon_name ("security-high-symbolic", Gtk.IconSize.BUTTON);
        tls_cert_reject_image.yalign = 0;
        unowned Gtk.StyleContext tls_cert_reject_image_style_context = tls_cert_reject_image.get_style_context ();
        tls_cert_reject_image_style_context.add_class ("security-high");
        tls_cert_reject_image_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        var tls_cert_reject_label = new Gtk.Label (null);
        tls_cert_reject_label.set_markup (_("<i>If a server presents an unacceptable SSL/TLS certificate, no connection will be made.</i> <b>(Recommended)</b>"));
        tls_cert_reject_label.use_markup = true;
        tls_cert_reject_label.wrap_mode = Pango.WrapMode.WORD;
        tls_cert_reject_label.wrap = true;
        tls_cert_reject_label.xalign = 0;
        tls_cert_reject_label.max_width_chars = 50;
        tls_cert_reject_grid.attach (tls_cert_reject_image, 0, 0, 1);
        tls_cert_reject_grid.attach (tls_cert_reject_label, 1, 0, 1);

        var tls_cert_warn_grid = new Gtk.Grid ();
        tls_cert_warn_grid.column_spacing = 10;
        var tls_cert_warn_image = new Gtk.Image.from_icon_name ("security-medium-symbolic", Gtk.IconSize.BUTTON);
        tls_cert_warn_image.yalign = 0;
        unowned Gtk.StyleContext tls_cert_warn_image_style_context = tls_cert_warn_image.get_style_context ();
        tls_cert_warn_image_style_context.add_class ("security-medium");
        tls_cert_warn_image_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        var tls_cert_warn_label = new Gtk.Label (null);
        tls_cert_warn_label.set_markup (_("<i>If a server presents an unacceptable SSL/TLS certificate, the user will be warned and can choose whether or not to proceed.</i>"));
        tls_cert_warn_label.use_markup = true;
        tls_cert_warn_label.wrap_mode = Pango.WrapMode.WORD;
        tls_cert_warn_label.wrap = true;
        tls_cert_warn_label.xalign = 0;
        tls_cert_warn_label.max_width_chars = 50;
        tls_cert_warn_grid.attach (tls_cert_warn_image, 0, 0, 1);
        tls_cert_warn_grid.attach (tls_cert_warn_label, 1, 0, 1);

        var tls_cert_allow_grid = new Gtk.Grid ();
        tls_cert_allow_grid.column_spacing = 10;
        var tls_cert_allow_image = new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON);
        tls_cert_allow_image.yalign = 0;
        unowned Gtk.StyleContext tls_cert_allow_image_style_context = tls_cert_allow_image.get_style_context ();
        tls_cert_allow_image_style_context.add_class ("security-low");
        tls_cert_allow_image_style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        var tls_cert_allow_label = new Gtk.Label (null);
        tls_cert_allow_label.set_markup (_("<i>If a server presents an unacceptable SSL/TLS certificate, the connection will still be made.</i> <b>(Not recommended)</b>"));
        tls_cert_allow_label.use_markup = true;
        tls_cert_allow_label.wrap_mode = Pango.WrapMode.WORD;
        tls_cert_allow_label.wrap = true;
        tls_cert_allow_label.xalign = 0;
        tls_cert_allow_label.max_width_chars = 50;
        tls_cert_allow_grid.attach (tls_cert_allow_image, 0, 0, 1);
        tls_cert_allow_grid.attach (tls_cert_allow_label, 1, 0, 1);

        security_posture_stack.add_named (tls_cert_reject_grid, "cert-reject");
        security_posture_stack.add_named (tls_cert_warn_grid, "cert-warn");
        security_posture_stack.add_named (tls_cert_allow_grid, "cert-allow");
        security_posture_stack.show_all (); // Required in order to set the visible child from preferences

        var remember_connections_label = new Gtk.Label (_("Remember connections between sessions:"));
        var remember_connections_switch = new Gtk.Switch ();
        remember_connections_switch.halign = Gtk.Align.START;
        remember_connections_switch.valign = Gtk.Align.CENTER;
        Iridium.Application.settings.bind ("remember-connections", remember_connections_switch, "active", SettingsBindFlags.DEFAULT);

        remember_connections_switch.notify["active"].connect (() => {
            if (!remember_connections_switch.get_active ()) {
                Idle.add (() => {
                    var dialog = new Iridium.Widgets.ForgetConnectionsWarningDialog (this);
                    int result = dialog.run ();
                    dialog.dismiss ();
                    if (result == Gtk.ResponseType.CANCEL) {
                        remember_connections_switch.set_active (true);
                    } else {
                        Iridium.Application.connection_repository.clear ();
                    }
                    return false;
                });
            }
        });

        form_grid.attach (general_header_label, 0, 0, 1);
        form_grid.attach (default_nickname_label, 0, 1, 1);
        form_grid.attach (default_nickname_entry, 1, 1, 1);
        form_grid.attach (default_realname_label, 0, 2, 1);
        form_grid.attach (default_realname_entry, 1, 2, 1);
        form_grid.attach (security_header_label, 0, 3, 1);
        form_grid.attach (cert_validation_policy_label, 0, 4, 1);
        form_grid.attach (cert_validation_policy_combo, 1, 4, 1);
        form_grid.attach (security_posture_stack, 0, 5, 2);
        form_grid.attach (remember_connections_label, 0, 6, 1);
        form_grid.attach (remember_connections_switch, 1, 6, 1);

        body.add (header_grid);
        body.add (form_grid);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect (() => {
            close ();
        });

        add_action_widget (close_button, 0);

        load_settings ();
    }

    private void load_settings () {
        default_nickname_entry.text = Iridium.Application.settings.get_string ("default-nickname");
        default_realname_entry.text = Iridium.Application.settings.get_string ("default-realname");
        var cert_policy = Iridium.Application.settings.get_string ("certificate-validation-policy");
        switch (Iridium.Models.InvalidCertificatePolicy.get_value_by_short_name (cert_policy)) {
            case REJECT:
                security_posture_stack.set_visible_child_name ("cert-reject");
                cert_validation_policy_combo.set_active (0);
                break;
            case WARN:
                security_posture_stack.set_visible_child_name ("cert-warn");
                cert_validation_policy_combo.set_active (1);
                break;
            case ALLOW:
                security_posture_stack.set_visible_child_name ("cert-allow");
                cert_validation_policy_combo.set_active (2);
                break;
            default:
                assert_not_reached ();
        }
    }

    private void on_security_posture_changed () {
        switch (cert_policies.get (cert_validation_policy_combo.get_active ())) {
            case REJECT:
                security_posture_stack.set_visible_child_name ("cert-reject");
                break;
            case WARN:
                security_posture_stack.set_visible_child_name ("cert-warn");
                break;
            case ALLOW:
                security_posture_stack.set_visible_child_name ("cert-allow");
                break;
            default:
                assert_not_reached ();
        }
    }

}
