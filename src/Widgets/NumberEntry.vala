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

public class Iridium.Widgets.NumberEntry : Granite.ValidatedEntry {

    private static GLib.Regex? NUMBER_REGEX = null;

    static construct {
        try {
            NUMBER_REGEX = new GLib.Regex ("^[0-9]*$", GLib.RegexCompileFlags.OPTIMIZE);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }

    construct {
        // Force input to be strictly numeric
        this.insert_text.connect ((new_text, new_text_length, ref position) => {
            try {
                if (!NUMBER_REGEX.match_full (new_text)) {
                    GLib.Signal.stop_emission_by_name (this, "insert-text");
                }
            } catch (GLib.Error e) {
                warning (e.message);
            }
        });
    }

}
