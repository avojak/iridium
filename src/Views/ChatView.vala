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

public class Iridium.Views.ChatView : Gtk.Grid {

    public string name { get; construct; }

    public ChatView (string name) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            name: name
        );
    }

    construct {
        var text_view = new Gtk.TextView ();
        text_view.pixels_below_lines = 3;
        text_view.border_width = 12;
        text_view.wrap_mode = Gtk.WrapMode.WORD;
        text_view.monospace = true;
        text_view.editable = false;
        text_view.cursor_visible = false;
        text_view.vexpand = true;
        text_view.hexpand = true;

        var entry = new Gtk.Entry ();
        entry.hexpand = true;

        attach (text_view, 0, 0, 1, 1);
        attach (entry, 0, 1, 1, 1);
    }

}
