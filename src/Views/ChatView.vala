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

    // TODO: Should toggle these colors slightly depending on whether user is in dark mode or not
    // Colors defined by the elementary OS Human Interface Guidelines
    private static string COLOR_STRAWBERRY = "#ed5353"; // "#c6262e";
    private static string COLOR_ORANGE = "#ffa154"; // "#f37329";
    private static string COLOR_LIME = "#9bdb4d"; // "#68b723";
    private static string COLOR_BLUEBERRY = "#64baff"; // "#3689e6";
    //  private static string COLOR_GRAPE = "#a56de2";

    protected Gtk.TextView text_view;

    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Entry entry;

    private Gdk.Cursor cursor_pointer;
    private Gdk.Cursor cursor_text;

    public ChatView () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        // TODO: WHY CANT YOU CLICK AND DRAG TO SELECT TEXT???
        text_view = new Gtk.TextView ();
        text_view.set_pixels_below_lines (3);
        text_view.set_border_width (12);
        text_view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        /* text_view.left_margin = 140; */
        text_view.set_indent (get_indent ());
        text_view.set_monospace (true);
        text_view.set_editable (false);
        text_view.set_cursor_visible (false);
        text_view.set_vexpand (true);
        text_view.set_hexpand (true);

        // Initialize the buffer iterator
        Gtk.TextIter iter;
        text_view.get_buffer ().get_end_iter (out iter);

        scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled_window.add (text_view);

        var event_box = new Gtk.EventBox ();
        event_box.add (scrolled_window);
        event_box.set_events (Gdk.EventMask.ENTER_NOTIFY_MASK);
        event_box.set_events (Gdk.EventMask.LEAVE_NOTIFY_MASK);

        entry = new Gtk.Entry ();
        entry.hexpand = true;
        entry.margin = 6;
        entry.secondary_icon_tooltip_text = _("Clear");

        attach (event_box, 0, 0, 1, 1);
        attach (entry, 0, 1, 1, 1);

        create_text_tags ();

        cursor_pointer = new Gdk.Cursor.from_name (text_view.get_display (), "pointer");
        cursor_text = new Gdk.Cursor.from_name (text_view.get_display (), "text");

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

        // This approach for detecting the mouse motion over a TextTag and changing the cursor
        // was adapted from: 
        // https://www.kksou.com/php-gtk2/sample-codes/insert-links-in-GtkTextView-Part-4-Change-Cursor-over-Link.php
        text_view.motion_notify_event.connect ((event) => {
            int buffer_x;
            int buffer_y;
            text_view.window_to_buffer_coords (Gtk.TextWindowType.TEXT, (int) event.x, (int) event.y, out buffer_x, out buffer_y);

            Gtk.TextIter pos;
            text_view.get_iter_at_location (out pos, buffer_x, buffer_y);

            var selectable_tag = text_view.get_buffer ().get_tag_table ().lookup ("selectable");

            var window = text_view.get_window (Gtk.TextWindowType.TEXT);
            if (window != null) {
                if (selectable_tag != null && pos.has_tag (selectable_tag)) {
                    window.set_cursor (cursor_pointer);
                } else {
                    window.set_cursor (cursor_text);
                }
            }

            // Handle the selectable underline
            Gtk.TextIter tag_start = pos;
            tag_start.backward_to_tag_toggle (selectable_tag);
            Gtk.TextIter tag_end = pos;
            tag_end.forward_to_tag_toggle (selectable_tag);

            var selectable_underline_tag = text_view.get_buffer ().get_tag_table ().lookup ("selectable-underline");
            if (selectable_tag != null && pos.has_tag (selectable_tag)) {
                // Make sure we're not over a 'word' that has a spaces in it
                if (!text_view.get_buffer ().get_text (tag_start, tag_end, false).contains (" ")) {
                    // Don't repeatedly apply the tag, and clear other underlines first to ensure that
                    // we don't have multiple strings underlined at the same time
                    if (!pos.has_tag (selectable_underline_tag)) {
                        clear_selectable_underlining ();
                        text_view.get_buffer ().apply_tag_by_name ("selectable-underline", tag_start, tag_end);
                    }
                }
            } else {
                clear_selectable_underlining ();
            }
            
        });

        // Clear the underlining when the mouse leaves the event box around the text view
        event_box.leave_notify_event.connect ((event) => {
            clear_selectable_underlining ();
        });
    }

    private void create_text_tags () {
        var buffer = text_view.get_buffer ();
        var color = Gdk.RGBA ();

        // Other usernames
        color.parse (COLOR_BLUEBERRY);
        unowned Gtk.TextTag username_tag = buffer.create_tag ("username");
        username_tag.foreground_rgba = color;
        username_tag.weight = Pango.Weight.SEMIBOLD;
        username_tag.event.connect (on_username_clicked);

        // Self username
        color.parse (COLOR_LIME);
        unowned Gtk.TextTag self_username_tag = buffer.create_tag ("self-username");
        self_username_tag.foreground_rgba = color;
        self_username_tag.weight = Pango.Weight.SEMIBOLD;
        self_username_tag.event.connect (on_username_clicked);

        // Errors
        color.parse (COLOR_STRAWBERRY);
        unowned Gtk.TextTag error_tag = buffer.create_tag ("error");
        error_tag.foreground_rgba = color;
        error_tag.weight = Pango.Weight.SEMIBOLD;

        // Inline usernames
        color.parse (COLOR_ORANGE);
        unowned Gtk.TextTag inline_username_tag = buffer.create_tag ("inline-username");
        inline_username_tag.foreground_rgba = color;
        inline_username_tag.event.connect (on_username_clicked);

        // Inline self username
        color.parse (COLOR_LIME);
        unowned Gtk.TextTag inline_self_username_tag = buffer.create_tag ("inline-self-username");
        inline_self_username_tag.foreground_rgba = color;

        // Selectable
        buffer.create_tag ("selectable");

        // Selectable underline
        unowned Gtk.TextTag selectable_underline_tag = buffer.create_tag ("selectable-underline");
        selectable_underline_tag.underline = Pango.Underline.SINGLE;

        // Hyperlinks
        color.parse (COLOR_BLUEBERRY);
        unowned Gtk.TextTag hyperlink_tag = buffer.create_tag ("hyperlink");
        hyperlink_tag.foreground_rgba = color;
        hyperlink_tag.event.connect (on_hyperlink_clicked);
    }

    private void clear_selectable_underlining () {
        Gtk.TextIter buffer_start;
        text_view.get_buffer ().get_start_iter (out buffer_start);
        Gtk.TextIter buffer_end;
        text_view.get_buffer ().get_end_iter (out buffer_end);
        text_view.get_buffer ().remove_tag_by_name ("selectable-underline", buffer_start, buffer_end);
    }

    // TODO: Need to figure out a good way to lock scrolling… Might be annoying
    //       to experience the auto-scroll when you're looking back at old
    //       messages…
    protected void do_autoscroll () {
        var buffer_end_mark = text_view.get_buffer ().get_mark ("buffer-end");
        if (buffer_end_mark != null) {
            text_view.scroll_mark_onscreen (buffer_end_mark);
        }
    }

    public void set_entry_focus () {
        if (entry.get_can_focus ()) {
            entry.grab_focus_without_selecting ();
            entry.set_position (-1);
        }
    }

    public void set_enabled (bool enabled) {
        entry.set_can_focus (enabled);
        entry.set_editable (enabled);
        entry.set_text ("");
        entry.set_placeholder_text (enabled ? "" : get_disabled_message ());
        if (!enabled) {
            text_view.grab_focus ();
        }
        // TODO: Would be nice to auto-grab focus back to the entry if enabled,
        //       but I'm having issues where it will grab focus even if this
        //       chat view isn't currently visible. This means you would be
        //       typing in a view that isn't visible.
    }

    private bool on_username_clicked (Gtk.TextTag source, GLib.Object event_object, Gdk.Event event, Gtk.TextIter iter) {
        // TODO: Check for right click and show some options in a popup menu (eg. block, PM, etc.)
        if (event.type == Gdk.EventType.BUTTON_RELEASE) {
            var username = get_selectable_text (iter);
            if (username == null) {
                // TODO: Log this - it shouldn't happen
                return false;
            }
            if (entry.text.length == 0) {
                entry.text = username + ": ";
                set_entry_focus ();
            } else {
                entry.text += username;
                set_entry_focus ();
            }
        }
        return false;
    }

    private bool on_hyperlink_clicked (Gtk.TextTag source, GLib.Object event_object, Gdk.Event event, Gtk.TextIter iter) {
        if (event.type == Gdk.EventType.BUTTON_RELEASE) {
            var hyperlink = get_selectable_text (iter);
            if (hyperlink == null) {
                // TODO: Log this - it shouldn't happen
                return false;
            }
            try {
                AppInfo.launch_default_for_uri (hyperlink, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }
        return false;
    }

    private string? get_selectable_text (Gtk.TextIter pos) {
        var selectable_tag = text_view.get_buffer ().get_tag_table ().lookup ("selectable");

        if (!pos.has_tag (selectable_tag)) {
            return null;
        }
            
        Gtk.TextIter tag_start = pos;
        tag_start.backward_to_tag_toggle (selectable_tag);
        Gtk.TextIter tag_end = pos;
        tag_end.forward_to_tag_toggle (selectable_tag);

        return tag_start.get_text (tag_end);
    }

    public abstract void display_self_private_msg (Iridium.Services.Message message);
    public abstract void display_server_msg (Iridium.Services.Message message);

    protected abstract int get_indent ();

    protected abstract string get_disabled_message ();

    public signal void message_to_send (string message);

}
