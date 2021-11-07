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

public class Iridium.Services.FileUtils : GLib.Object {

    public static string? read_file (string uri, GLib.Cancellable? cancellable = null) throws GLib.Error {
        GLib.FileInputStream fis = GLib.File.new_for_uri (uri).read (cancellable);
        GLib.DataInputStream dis = new GLib.DataInputStream (fis);
        GLib.StringBuilder sb = new GLib.StringBuilder ();
        string? line = null;
        while ((line = dis.read_line (null, cancellable)) != null) {
            sb.append (line);
        }
        return (string) sb.data;
    }

}
