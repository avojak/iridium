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

public class Iridium.Models.CertificateErrorMapping : GLib.Object {

    public static string get_description (TlsCertificateFlags flag) {
        switch (flag) {
            case GENERIC_ERROR:
                return _("An error has occurred processing the server's certificate");
            case INSECURE:
                return _("The server's certificate is considered insecure");
            case REVOKED:
                return _("The server's certificate has been revoked and is now invalid");
            case EXPIRED:
                return _("The server's certificate has expired");
            case NOT_ACTIVATED:
                return _("The server's certificate has not been activated");
            case BAD_IDENTITY:
                return _("The server's identity does not match the identity in the certificate");
            case UNKNOWN_CA:
                return _("The server's certificate is not signed by a known authority");
            default:
                assert_not_reached ();
        }
    }

}
