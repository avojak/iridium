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

public abstract class Iridium.Models.PrivateMessageText : Iridium.Models.RichText {

    private static uint16 USERNAME_SPACING = 20;

    public PrivateMessageText (Iridium.Services.Message message) {
        Object (
            message: message
        );
    }

    public override void do_display (Gtk.TextBuffer buffer) {
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);

        // Display username
        // TODO: Check if the last username displayed is the same username. If so,
        //       don't display it again.
        var username = message.username;
        if (username.length > USERNAME_SPACING) {
            username = username.substring (0, USERNAME_SPACING - 3);
            username += "...";
        } else {
            username += string.nfill (USERNAME_SPACING - username.length, ' ');
        }
        buffer.insert_text (ref iter, username, username.length);

        // Format the username
        Gtk.TextIter username_start = iter;
        username_start.backward_chars (username.length);
        buffer.apply_tag_by_name (get_tag_name (), username_start, iter);
        buffer.insert_text (ref iter, message.message, message.message.length);
        buffer.insert (ref iter, "\n", 1);
    }

    public abstract string get_tag_name ();

}
