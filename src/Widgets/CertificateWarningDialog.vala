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

    public unowned Iridium.MainWindow main_window { get; construct; }
    public unowned TlsCertificate peer_cert { get; construct; }
    public unowned Gee.List<TlsCertificateFlags> errors { get; construct; }

    public CertificateWarningDialog (Iridium.MainWindow main_window, TlsCertificate peer_cert, Gee.List<TlsCertificateFlags> errors) {
        Object (
            deletable: false,
            resizable: false,
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            peer_cert: peer_cert,
            errors: errors
        );
    }

    construct {
        image_icon = new ThemedIcon ("security-low");
        primary_text = _("Untrusted Connection");
        secondary_text = _("The identity of the server could not be verified. Connecting to the server may cause your username, password, and all messages to be transmitted insecurely.");

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

        int row_index = 0;
        if (TlsCertificateFlags.GENERIC_ERROR in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("An error has occurred processing the server's certificate"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        if (TlsCertificateFlags.INSECURE in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("The server's certificate is considered insecure"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        if (TlsCertificateFlags.REVOKED in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("The server's certificate has been revoked and is now invalid"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        if (TlsCertificateFlags.EXPIRED in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("The server's certificate has expired"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        if (TlsCertificateFlags.NOT_ACTIVATED in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("The server's certificate has not been activated"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        if (TlsCertificateFlags.BAD_IDENTITY in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("The server's identity does not match the identity in the certificate"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        if (TlsCertificateFlags.UNKNOWN_CA in errors) {
            grid.attach (new Gtk.Image.from_icon_name ("security-low-symbolic", Gtk.IconSize.BUTTON), 0, row_index);
            var label = new Gtk.Label(_("The server's certificate is not signed by a known authority"));
            label.halign = Gtk.Align.START;
            grid.attach (label, 1, row_index);
            row_index++;
        }
        return grid;
    }

    public void dismiss () {
        close ();
    }

}