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

public abstract class Iridium.Models.Text.PrivateMessageText : Iridium.Models.Text.RichText {

    private static uint16 NICKNAME_SPACING = 20; // vala-lint=naming-convention

    public bool suppress_sender_nickname { get; set; }

    protected PrivateMessageText (Iridium.Services.Message message) {
        Object (
            message: message,
            suppress_sender_nickname: false
        );
    }

    public override void do_display (Gtk.TextBuffer buffer) {
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);

        // Display nickname
        var nickname = message.nickname;
        if (suppress_sender_nickname) {
            nickname = string.nfill (NICKNAME_SPACING, ' ');
        } else if (nickname.length > NICKNAME_SPACING) {
            nickname = nickname.substring (0, NICKNAME_SPACING - 3);
            nickname += "…";
        } else {
            nickname += string.nfill (NICKNAME_SPACING - nickname.length, ' ');
        }
        buffer.insert (ref iter, nickname, nickname.length);

        // Format the nickname
        Gtk.TextIter nickname_start = iter;
        nickname_start.backward_chars (nickname.length);
        Gtk.TextIter nickname_end = nickname_start;
        nickname_end.forward_chars (message.nickname.length);
        buffer.apply_tag_by_name (get_tag_name (), nickname_start, nickname_end);
        buffer.apply_tag_by_name ("selectable", nickname_start, nickname_end);
        buffer.insert (ref iter, message.message, message.message.length);
        buffer.insert (ref iter, "\n", 1);
    }

    public abstract string get_tag_name ();

}
