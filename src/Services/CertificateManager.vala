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

    public static string parse_host (SocketConnectable connectable) {
        return connectable.to_string ().split (":")[0]; // e.g.: chat.freenode.net:6697 -> chat.freenode.net
    }

    public Iridium.Models.ServerIdentity? lookup_identity (TlsCertificate cert, string host) {
        // Check database to see if we've previously accepted/rejected the identity
        Gee.List<Iridium.Models.ServerIdentity> identities = sql_client.get_server_identities (host);
        foreach (var identity in identities) {
            if (identity.certificate_pem.chomp ().chug () == cert.certificate_pem.chomp ().chug ()) {
                return identity;
            }
        }
        return null;
    }

    public void store_identity (Iridium.Models.ServerIdentity identity) {
        sql_client.insert_server_identity (identity);
    }

}
