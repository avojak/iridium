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

    public static uint16 USERNAME_SPACING = 20;

    // Colors defined by the elementary OS Human Interface Guidelines
    private static string COLOR_STRAWBERRY = "#c6262e";
    private static string COLOR_LIME = "#68b723";
    private static string COLOR_BLUEBERRY = "#3689e6";

    private Gtk.TextView text_view;

    public ChatView () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        text_view = new Gtk.TextView ();
        text_view.pixels_below_lines = 3;
        text_view.border_width = 12;
        text_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        /* text_view.left_margin = 140; */
        text_view.indent = -140; // TODO: Figure out how to compute this
        text_view.monospace = true;
        text_view.editable = false;
        text_view.cursor_visible = false;
        text_view.vexpand = true;
        text_view.hexpand = true;

        // Initialize the buffer iterator
        Gtk.TextIter iter;
        text_view.get_buffer ().get_end_iter (out iter);

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.add (text_view);

        var entry = new Gtk.Entry ();
        entry.hexpand = true;

        attach (scroll, 0, 0, 1, 1);
        attach (entry, 0, 1, 1, 1);

        create_text_tags ();

        entry.activate.connect (() => {
            message_to_send (entry.get_text ());
            entry.set_text ("");
        });
    }

    private void create_text_tags () {
        var buffer = text_view.get_buffer ();
        var color = Gdk.RGBA ();

        // Username
        color.parse (COLOR_BLUEBERRY);
        unowned Gtk.TextTag username_tag = buffer.create_tag ("username");
        username_tag.foreground_rgba = color;
        username_tag.weight = Pango.Weight.SEMIBOLD;

        // Self username
        color.parse (COLOR_LIME);
        unowned Gtk.TextTag self_username_tag = buffer.create_tag ("self-username");
        self_username_tag.foreground_rgba = color;
        self_username_tag.weight = Pango.Weight.SEMIBOLD;
    }

    public void add_message (Iridium.Services.Message message, bool is_user_message) {
        var rich_text = new Iridium.Services.RichText (message, is_user_message);
        rich_text.display (text_view.get_buffer ());
    }

    public signal void message_to_send (string message);

}
