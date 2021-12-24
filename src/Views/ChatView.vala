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

    private const int DATETIME_DISPLAY_THRESHOLD_MINUTES = 15;

    public unowned Iridium.MainWindow window { get; construct; }
    public string nickname { get; construct; }

    protected Iridium.Widgets.TextView text_view;
    protected string? last_sender = null;

    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Button nickname_button;
    private Gtk.Entry entry;
    private Granite.Widgets.Toast toast;

    private Gdk.Cursor cursor_pointer;
    private Gdk.Cursor cursor_text;

    private bool is_view_in_focus = false;
    private bool is_window_in_focus = true;
    private bool is_enabled = true;
    private bool has_unread_messages = false;

    private double prev_upper_adj = 0;
    private DateTime? last_message_time = null;

    protected ChatView (Iridium.MainWindow window, string nickname) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            window: window,
            nickname: nickname
        );
    }

    construct {
        text_view = new Iridium.Widgets.TextView (get_indent ());

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

        toast = new Granite.Widgets.Toast (_("You have unread messages!"));
        toast.set_default_action (_("Take me there"));
        toast.default_action.connect (() => {
            do_autoscroll ();
        });

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (event_box);
        overlay.add_overlay (toast);

        var entry_grid = new Gtk.Grid ();

        nickname_button = new Gtk.Button.with_label (nickname);
        nickname_button.relief = Gtk.ReliefStyle.NONE;
        nickname_button.clicked.connect (() => {
            nickname_button_clicked ();
        });

        entry = new Gtk.Entry ();
        entry.hexpand = true;
        entry.margin = 6;
        entry.secondary_icon_tooltip_text = _("Clear");

        entry_grid.attach (nickname_button, 0, 0, 1, 1);
        entry_grid.attach (entry, 1, 0, 1, 1);

        attach (overlay, 0, 0, 1, 1);
        attach (entry_grid, 0, 1, 1, 1);

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
        text_view.size_allocate.connect (() => {
            attempt_autoscroll ();
        });

        // Clear the underlining when the mouse leaves the event box around the text view
        event_box.leave_notify_event.connect ((event) => {
            clear_selectable_underlining ();
        });

        window.focus_in_event.connect (() => {
            is_window_in_focus = true;
            if (is_view_in_focus) {
                on_focus_gained ();
            }
            return false;
        });
        window.focus_out_event.connect (() => {
            is_window_in_focus = false;
            if (is_view_in_focus) {
                on_focus_lost ();
            }
            return false;
        });

        Granite.Settings.get_default ().notify["prefers-color-scheme"].connect (update_tag_colors);

        show_all ();
    }

    private void create_text_tags () {
        var buffer = text_view.get_buffer ();

        // Other nicknames
        unowned Gtk.TextTag nickname_tag = buffer.create_tag ("nickname");
        nickname_tag.weight = Pango.Weight.SEMIBOLD;
        nickname_tag.event.connect (on_nickname_clicked);

        // Self nickname
        unowned Gtk.TextTag self_nickname_tag = buffer.create_tag ("self-nickname");
        self_nickname_tag.weight = Pango.Weight.SEMIBOLD;
        self_nickname_tag.event.connect (on_nickname_clicked);

        // Errors
        unowned Gtk.TextTag error_tag = buffer.create_tag ("error");
        error_tag.weight = Pango.Weight.SEMIBOLD;

        // Inline nicknames
        unowned Gtk.TextTag inline_nickname_tag = buffer.create_tag ("inline-nickname");
        inline_nickname_tag.event.connect (on_nickname_clicked);

        // Inline self nickname
        buffer.create_tag ("inline-self-nickname");

        // Selectable
        buffer.create_tag ("selectable");

        // Selectable underline
        unowned Gtk.TextTag selectable_underline_tag = buffer.create_tag ("selectable-underline");
        selectable_underline_tag.underline = Pango.Underline.SINGLE;

        // Hyperlinks
        unowned Gtk.TextTag hyperlink_tag = buffer.create_tag ("hyperlink");
        hyperlink_tag.event.connect (on_hyperlink_clicked);

        // Datetime
        unowned Gtk.TextTag datetime_tag = buffer.create_tag ("datetime");
        datetime_tag.style = Pango.Style.ITALIC;
        datetime_tag.justification = Gtk.Justification.CENTER;

        update_tag_colors ();
    }

    private void update_tag_colors () {
        var tag_table = text_view.get_buffer ().get_tag_table ();
        var color = Gdk.RGBA ();

        // Other nicknames
        color.parse (Iridium.Models.ColorPalette.COLOR_BLUEBERRY.get_value ());
        tag_table.lookup ("nickname").foreground_rgba = color;

        // Self nickname
        color.parse (Iridium.Models.ColorPalette.COLOR_LIME.get_value ());
        tag_table.lookup ("self-nickname").foreground_rgba = color;

        // Errors
        color.parse (Iridium.Models.ColorPalette.COLOR_STRAWBERRY.get_value ());
        tag_table.lookup ("error").foreground_rgba = color;

        // Inline nicknames
        color.parse (Iridium.Models.ColorPalette.COLOR_ORANGE.get_value ());
        tag_table.lookup ("inline-nickname").foreground_rgba = color;

        // Inline self nickname
        color.parse (Iridium.Models.ColorPalette.COLOR_LIME.get_value ());
        tag_table.lookup ("inline-self-nickname").foreground_rgba = color;

        // Hyperlinks
        color.parse (Iridium.Models.ColorPalette.COLOR_BLUEBERRY.get_value ());
        tag_table.lookup ("hyperlink").foreground_rgba = color;
    }

    private void clear_selectable_underlining () {
        Gtk.TextIter buffer_start;
        text_view.get_buffer ().get_start_iter (out buffer_start);
        Gtk.TextIter buffer_end;
        text_view.get_buffer ().get_end_iter (out buffer_end);
        text_view.get_buffer ().remove_tag_by_name ("selectable-underline", buffer_start, buffer_end);
    }

    public void set_entry_focus () {
        if (entry.get_can_focus ()) {
            entry.grab_focus_without_selecting ();
            entry.set_position (-1);
        }
    }

    public void set_enabled (bool enabled) {
        this.is_enabled = enabled;
        nickname_button.sensitive = enabled;
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

    public bool get_enabled () {
        return is_enabled;
    }

    public void reset_marker_line () {
        var last_read_message_mark = text_view.get_buffer ().get_mark ("last-read-message");
        if (last_read_message_mark != null) {
            text_view.get_buffer ().delete_mark (last_read_message_mark);
        }

        // Force the view to immediately be redrawn without the marker line
        text_view.queue_draw ();
    }

    private bool on_nickname_clicked (Gtk.TextTag source, GLib.Object event_object, Gdk.Event event, Gtk.TextIter iter) {
        // TODO: Check for right click and show some options in a popup menu (eg. block, PM, etc.)
        if (event.type == Gdk.EventType.BUTTON_RELEASE) {
            var nickname = get_selectable_text (iter);
            if (nickname == null) {
                warning ("Encountered click of null nickname");
                return false;
            }
            if (entry.text.length == 0) {
                entry.text = nickname + ": ";
                set_entry_focus ();
            } else {
                entry.text += nickname;
                set_entry_focus ();
            }
        }
        return false;
    }

    private bool on_hyperlink_clicked (Gtk.TextTag source, GLib.Object event_object, Gdk.Event event, Gtk.TextIter iter) {
        if (event.type == Gdk.EventType.BUTTON_RELEASE) {
            var hyperlink = get_selectable_text (iter);
            if (hyperlink == null) {
                warning ("Encountered click of null hyperlink");
                return false;
            }
            try {
                AppInfo.launch_default_for_uri (hyperlink, null);
            } catch (Error e) {
                warning ("Failed to launch default application for URI: %s", e.message);
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

    public void update_nickname (string new_nickname) {
        nickname_button.set_label (new_nickname);
    }

    public void display_self_private_msg (Iridium.Services.Message message) {
        if (should_display_datetime ()) {
            do_display_datetime ();
        }
        last_message_time = new DateTime.now_utc ();
        do_display_self_private_msg (message);
        // Always auto-scroll after the user sends a message
        do_autoscroll ();
    }

    public void display_server_msg (Iridium.Services.Message message) {
        if (should_display_datetime ()) {
            do_display_datetime ();
        }
        last_message_time = new DateTime.now_utc ();
        do_display_server_msg (message);
    }

    public void display_server_error_msg (Iridium.Services.Message message) {
        if (should_display_datetime ()) {
            do_display_datetime ();
        }
        last_message_time = new DateTime.now_utc ();
        do_display_server_error_msg (message);
    }

    public void display_private_msg (Iridium.Services.Message message) {
        if (!is_in_focus ()) {
            update_last_read_message_mark ();
            has_unread_messages = true;
        }
        if (should_display_datetime ()) {
            do_display_datetime ();
        }
        last_message_time = new DateTime.now_utc ();
        do_display_private_msg (message);
    }

    public void focus_gained () {
        is_view_in_focus = true;
        on_focus_gained ();
    }

    public void focus_lost () {
        is_view_in_focus = false;
        on_focus_lost ();
    }

    private void on_focus_gained () {
        if (has_unread_messages) {
            // Check if the end of the buffer is in view, and show the toast if not
            if (!at_bottom_of_screen ()) {
                toast.send_notification ();
            }
        }
        has_unread_messages = false;
    }

    private void on_focus_lost () {
        // Do nothing... yet...
    }

    private bool is_in_focus () {
        return is_view_in_focus && is_window_in_focus;
    }

    private void attempt_autoscroll () {
        var adj = scrolled_window.get_vadjustment ();
        var units_from_end = prev_upper_adj - adj.page_size - adj.value;
        var view_size_difference = adj.upper - prev_upper_adj;
        if (view_size_difference < 0) {
            view_size_difference = 0;
        }
        if (prev_upper_adj <= adj.page_size || units_from_end <= 50) {
            do_autoscroll ();
        }
        prev_upper_adj = adj.upper;
    }

    private void do_autoscroll () {
        var buffer_end_mark = text_view.get_buffer ().get_mark ("buffer-end");
        if (buffer_end_mark != null) {
            text_view.scroll_mark_onscreen (buffer_end_mark);
        }
    }

    private bool at_bottom_of_screen () {
        // Not ideal, but it works...
        var adjustment = scrolled_window.get_vadjustment ();
        double page_size = adjustment.get_page_size ();
        double max_view_size = adjustment.get_upper ();
        double current_position = adjustment.get_value ();
        int padding = text_view.get_pixels_below_lines ();
        if (current_position < max_view_size - page_size - padding) {
            return false;
        }
        return true;
    }

    private void update_last_read_message_mark () {
        // If there's nothing in the buffer, there's nothing to do
        if (text_view.get_buffer ().text.length == 0) {
            return;
        }

        if (text_view.get_buffer ().get_line_count () < 2) {
            return;
        }

        // There are already unread messages, don't move the mark further down the buffer
        if (has_unread_messages) {
            return;
        }

        // Add/move the mark in the text buffer to indicate the last read message
        Gtk.TextIter iter;
        text_view.get_buffer ().get_end_iter (out iter);
        iter.backward_line ();
        if (text_view.get_buffer ().get_mark ("last-read-message") == null) {
            text_view.get_buffer ().create_mark ("last-read-message", iter, true);
        } else {
            text_view.get_buffer ().move_mark_by_name ("last-read-message", iter);
        }

        // If the application window is not in focus, we need to force a redraw of the text view,
        // otherwise the changes won't be redrawn until the mouse moves over the window again
        text_view.queue_draw ();
    }

    private bool should_display_datetime () {
        if (last_message_time == null || !does_display_datetime ()) {
            return false;
        }
        return new DateTime.now_utc ().difference (last_message_time) >= (DATETIME_DISPLAY_THRESHOLD_MINUTES * TimeSpan.MINUTE);
    }

    private void do_display_datetime () {
        var message = new Iridium.Services.Message ();
        message.message = new DateTime.now_local ().format ("%x %X");
        var rich_text = new Iridium.Models.Text.DateTimeMessageText (message);
        rich_text.display (text_view.get_buffer ());
        last_sender = null;
    }

    public abstract void do_display_self_private_msg (Iridium.Services.Message message);
    public abstract void do_display_server_msg (Iridium.Services.Message message);
    public abstract void do_display_server_error_msg (Iridium.Services.Message message);
    public abstract void do_display_private_msg (Iridium.Services.Message message);
    public abstract bool does_display_datetime ();

    protected abstract int get_indent ();
    protected abstract string get_disabled_message ();

    public signal void message_to_send (string message);
    public signal void nickname_button_clicked ();

}
