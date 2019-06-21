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

public abstract class Iridium.Views.ChatView : Gtk.Grid {

    // TODO: Disable or somehow indicate that you are disconnected from a server
    //       and cannot send messages.

    // Colors defined by the elementary OS Human Interface Guidelines
    private static string COLOR_STRAWBERRY = "#c6262e";
    private static string COLOR_LIME = "#68b723";
    private static string COLOR_BLUEBERRY = "#3689e6";

    protected Gtk.TextView text_view;

    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Entry entry;

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
        text_view.indent = get_indent ();
        text_view.monospace = true;
        text_view.editable = false;
        text_view.cursor_visible = false;
        text_view.vexpand = true;
        text_view.hexpand = true;

        // Initialize the buffer iterator
        Gtk.TextIter iter;
        text_view.get_buffer ().get_end_iter (out iter);

        scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled_window.add (text_view);

        entry = new Gtk.Entry ();
        entry.hexpand = true;
        entry.margin = 6;
        entry.secondary_icon_tooltip_text = "Clear";

        // TODO: Support emojis instead of having the clear button?
        //       Maybe find a way to do both cleanly?
        //       We already get the right-click emoji menu for free...
        //  entry.show_emoji_icon = true;

        attach (scrolled_window, 0, 0, 1, 1);
        attach (entry, 0, 1, 1, 1);

        create_text_tags ();

        entry.activate.connect (() => {
            message_to_send (entry.get_text ());
            entry.set_text ("");
        });
        entry.changed.connect (() => {
            if (entry.text != "") {
                entry.secondary_icon_name = "edit-clear-symbolic";
            } else {
                entry.secondary_icon_name = null;
            }
        });
        entry.icon_release.connect ((icon_pos, event) => {
            if (icon_pos == Gtk.EntryIconPosition.SECONDARY) {
                entry.set_text ("");
            }
        });

        /* scrolled_window.get_vadjustment ().value_changed.connect (() => {
            print (scrolled_window.get_vadjustment ().value.to_string () + "\n");
        }); */
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

        // Errors
        color.parse (COLOR_STRAWBERRY);
        unowned Gtk.TextTag error_tag = buffer.create_tag ("error");
        error_tag.foreground_rgba = color;
        error_tag.weight = Pango.Weight.SEMIBOLD;
    }

    // TODO: Need to figure out a good way to lock scrolling... Might be annoying
    //       to experience the auto-scroll when you're looking back at old
    //       messages...
    protected void do_autoscroll () {
        var buffer_end_mark = text_view.get_buffer ().get_mark ("buffer-end");
        if (buffer_end_mark != null) {
            text_view.scroll_mark_onscreen (buffer_end_mark);
        }
    }

    public void display_self_priv_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.SelfPrivMessageText (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
    }

    public void display_server_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.ServerMessageText (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
    }

    public void set_entry_focus () {
        entry.grab_focus_without_selecting ();
    }

    protected abstract int get_indent ();

    public signal void message_to_send (string message);

}
