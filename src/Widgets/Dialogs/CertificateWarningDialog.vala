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

public class Iridium.Widgets.CertificateWarningDialog : Granite.MessageDialog {

    private static Gtk.CssProvider provider;

    public unowned Iridium.MainWindow main_window { get; construct; }
    public unowned TlsCertificate peer_cert { get; construct; }
    public unowned Gee.List<TlsCertificateFlags> errors { get; construct; }
    public unowned SocketConnectable connectable { get; construct; }

    public CertificateWarningDialog (Iridium.MainWindow main_window, TlsCertificate peer_cert, Gee.List<TlsCertificateFlags> errors, SocketConnectable connectable) {
        Object (
            deletable: false,
            resizable: false,
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            peer_cert: peer_cert,
            errors: errors,
            connectable: connectable
        );
    }

    static construct {
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/avojak/iridium/CertificateWarningDialog.css");
    }

    construct {
        image_icon = new ThemedIcon ("security-low");
        primary_text = _("Untrusted Connection");
        string server = connectable.to_string ().split (":")[0];
        secondary_text = _(@"The identity of the server \"$server\" could not be verified. Connecting to the server may cause your username, password, and all messages to be transmitted insecurely.");

        add_button (_("Don't Connect"), Gtk.ResponseType.CANCEL);
        add_button (_("Connect Anyway"), Gtk.ResponseType.OK);

        custom_bin.add (construct_details_grid ());
        custom_bin.show_all ();
    }

    private Gtk.Grid construct_details_grid () {
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.column_spacing = 6;
        grid.row_spacing = 12;

        var error_grid = new Gtk.Grid ();
        error_grid.orientation = Gtk.Orientation.VERTICAL;
        error_grid.column_spacing = 6;
        error_grid.row_spacing = 12;

        int row_index = 0;
        foreach (var error in errors) {
            error_grid.attach (create_error_icon (), 0, row_index);
            var label = new Gtk.Label(Iridium.Models.CertificateErrorMapping.get_description (error));
            label.halign = Gtk.Align.START;
            error_grid.attach (label, 1, row_index);
            row_index++;
        }

        var text_view = new Gtk.TextView ();
        text_view.set_pixels_below_lines (3);
        text_view.set_border_width (6);
        text_view.set_wrap_mode (Gtk.WrapMode.NONE);
        text_view.set_monospace (true);
        text_view.set_editable (false);
        text_view.set_cursor_visible (false);
        text_view.set_vexpand (false);
        text_view.set_hexpand (true);

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        scroll_box.margin_top = 12;
        scroll_box.min_content_height = 140;
        scroll_box.add (text_view);

        text_view.buffer.text = peer_cert.certificate_pem;

        var expander = new Gtk.Expander (_("View certificate"));
        expander.add (scroll_box);

        var check_box = new Gtk.CheckButton.with_label (_("Remember my decision"));
        check_box.toggled.connect (() => {
            remember_decision_toggled (check_box.get_active ());
        });

        grid.attach (error_grid, 0, 0);
        grid.attach (expander, 0, 1);
        grid.attach (check_box, 0, 2);

        return grid;
    }

    private Gtk.Image create_error_icon () {
        var icon = new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON);
        unowned Gtk.StyleContext style_context = icon.get_style_context ();
        style_context.add_class ("error");
        style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        return icon;
    }

    public void dismiss () {
        close ();
    }

    public signal void remember_decision_toggled (bool remember_decision);

}
