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

public abstract class Iridium.Models.RichText : GLib.Object {

    public Iridium.Services.Message message { get; construct; }

    public RichText (Iridium.Services.Message message) {
        Object (
            message: message
        );
    }

    public void display (Gtk.TextBuffer buffer) {
        // Display the rich text in the buffer
        do_display (buffer);

        // Update the "buffer-end" mark to be at the end of the buffer
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);
        if (buffer.get_mark ("buffer-end") == null) {
            buffer.create_mark ("buffer-end", iter, false);
        } else {
            buffer.move_mark_by_name ("buffer-end", iter);
        }
    }

    public abstract void do_display (Gtk.TextBuffer buffer);

}
