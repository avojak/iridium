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

public class Iridium.Models.ServerSupports : GLib.Object {

    // Models the 005 RPL_ISUPPORT numeric. This is based on a draft recommendation,
    // so we must be careful to not expect any of these values to exist.

    public string? network { get; set; }
    
    public void append_all (string[] parameters) {
        foreach (var parameter in parameters) {
            append (parameter);
        }
    }

    public string? append (string parameter) {
        string[] tokens = parameter.split ("=");
        if (tokens.length == 1 || tokens.length == 2) {
            switch (tokens[0]) {
                case Iridium.Models.ServerSupportsParameters.NETWORK:
                    this.network = tokens[1];
                    break;
                default:
                    //debug ("Unimplemented 005 RPL_ISUPPORT parameter: %s", tokens[0]);
                    break;
            }
            return tokens[0];
        } else {
            warning ("Unexpected number of tokens in 005 RPL_ISUPPORT parameter: '%s'", parameter);
        }
        return null;
    }

}