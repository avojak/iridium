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

public class Iridium.Services.RichText : GLib.Object {

    public Iridium.Services.Message message { get; construct; }

    public RichText (Iridium.Services.Message message) {
        Object (
            message: message
        );
    }

    public void display (Gtk.TextBuffer buffer) {
        switch (message.command) {
            case Iridium.Services.MessageCommands.PRIVMSG:
                display_priv_msg (buffer);
                break;
            case Iridium.Services.MessageCommands.NOTICE:
            case Iridium.Services.NumericCodes.RPL_MOTD:
            case Iridium.Services.NumericCodes.RPL_MOTDSTART:
                display_server_msg (buffer);
                break;
            // TODO: Error messages?
            default:
                display_server_msg (buffer);
                break;
        }
    }

    private void display_priv_msg (Gtk.TextBuffer buffer) {
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);

        // Display username
        var username = message.username;
        if (username.length > Iridium.Views.ChatView.USERNAME_SPACING) {
            username = username.substring (0, Iridium.Views.ChatView.USERNAME_SPACING - 3);
            username += "...";
        } else {
            username += string.nfill (Iridium.Views.ChatView.USERNAME_SPACING - username.length, ' ');
        }
        buffer.insert_text (ref iter, username, username.length);

        // Add spacing after username and before the start of the message
        Gtk.TextIter username_start = iter;
        username_start.backward_chars (username.length);
        buffer.apply_tag_by_name ("username", username_start, iter);
        buffer.insert_text (ref iter, message.message, message.message.length);
        buffer.insert (ref iter, "\n", 1);
    }

    private void display_server_msg (Gtk.TextBuffer buffer) {
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);

        // Add a placeholder for the username since it's a server message
        var username = "*";
        username += string.nfill (Iridium.Views.ChatView.USERNAME_SPACING - username.length, ' ');
        buffer.insert_text (ref iter, username, username.length);
        
        // Add spacing after username and before the start of the message
        Gtk.TextIter username_start = iter;
        username_start.backward_chars (username.length);
        buffer.apply_tag_by_name ("username", username_start, iter);
        buffer.insert_text (ref iter, message.message, message.message.length);
        buffer.insert (ref iter, "\n", 1);
    }

}
