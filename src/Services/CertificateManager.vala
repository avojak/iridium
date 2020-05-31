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

public class Iridium.Services.CertificateManager : GLib.Object {

    public Iridium.Services.SQLClient sql_client { get; set; }
    public unowned Iridium.MainWindow main_window { get; construct; }

    public bool verify_identity (TlsCertificate cert, string host) {
        // Check database to see if we've previously accepted/rejected the identity
        Gee.List<Iridium.Models.ServerIdentity> identities = sql_client.get_server_identities (host);
        foreach (var identity in identities) {
            if (identity.certificate_pem == cert.certificate_pem) {
                print ("Found identity match for " + host + " (accepted: " + identity.is_accepted.to_string () + ")\n");
                return identity.is_accepted;
            }
        }

        // No match, so prompt user for action
        //  int result = -1;
        //  Idle.add (() => {
        //      //  show_certificate_warning_dialog ();
        //      var dialog = new Iridium.Widgets.CertificateWarningDialog (this, peer_cert, errors, connectable);
        //      result = dialog.run ();
        //      dialog.dismiss ();
        //      return false;
        //  });
        //  while (result == -1) {
        //      // Block until a selection is made
        //  }
        //  return result == Gtk.ResponseType.OK;

        //  var dialog = new Iridium.Widgets.CertificateWarningDialog (this, peer_cert, errors, connectable);
        //  var result = (dialog.run () == Gtk.ResponseType.OK);
        //  dialog.dismiss ();
        var result = false;

        var identity = new Iridium.Models.ServerIdentity ();
        identity.host = host;
        identity.certificate_pem = cert.certificate_pem;
        identity.is_accepted = result;
        sql_client.insert_server_identity (identity);

        return result;
    }

}