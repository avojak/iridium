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

public class Iridium.Models.Nickname : GLib.Object {

    private static string[] NICKNAME_PREFIXES = {
        "@", // Full operator
        "%", // Half operator
        "~", // Owners
        "+", // Voiced users
        "&"  // Admins
    };

    public string? prefix { get; set; }
    public string simple_name { get; set; }
    public string full_name { get; set; }

    public Nickname (string nickname = "") {
        this.full_name = nickname;
        parse_nickname ();
    }

    private void parse_nickname () {
        foreach (var _prefix in NICKNAME_PREFIXES) {
            if (full_name.has_prefix (_prefix)) {
                this.prefix = _prefix;
                this.simple_name = full_name.substring (1);
                return;
            }
        }
        this.simple_name = full_name;
    }

}