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

public class Iridium.Widgets.UsersPopover.ChannelUsersPopover : Gtk.Popover {

    private Gtk.SearchEntry search_entry;

    private Gtk.Box box;
    private Gtk.ScrolledWindow scrolled_window;
    private Iridium.Widgets.UsersPopover.ChannelUsersList tree_view;
    private Gtk.Label label;

    public ChannelUsersPopover (Gtk.Widget? relative_to) {
        Object (
            relative_to: relative_to
        );
    }

    construct {
        search_entry = new Gtk.SearchEntry ();
        search_entry.margin_bottom = 6;

        scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.min_content_height = 50;
        scrolled_window.max_content_height = 250;
        scrolled_window.propagate_natural_height = true;
        scrolled_window.margin_bottom = 6;

        tree_view = new Iridium.Widgets.UsersPopover.ChannelUsersList ();
        tree_view.initiate_private_message.connect ((nickname) => {
            initiate_private_message (nickname);
        });
        scrolled_window.add (tree_view);

        label = new Gtk.Label ("");
        label.get_style_context ().add_class ("h4");
        label.halign = Gtk.Align.CENTER;
        label.valign = Gtk.Align.CENTER;
        label.justify = Gtk.Justification.CENTER;
        label.set_max_width_chars (50);
        label.set_line_wrap (true);

        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin = 6;
        box.pack_start (search_entry, true, false, 0);
        box.pack_start (scrolled_window, true, false, 0);
        box.pack_start (label, true, false, 0);

        add (box);

        show_all ();

        search_entry.search_changed.connect (() => {
            var search_text = search_entry.get_text ();
            var num_users = tree_view.update_search_text (search_text == null ? "" : search_text.strip ().down ());
            update_user_count (num_users);
        });
        this.closed.connect (() => {
            search_entry.set_text ("");
        });
    }

    public void set_users (Gee.List<string> nicknames, Gee.List<string> operators) {
        nicknames.sort ((a, b) => {
            return a.down ().ascii_casecmp (b.down ());
        });
        search_entry.sensitive = false;
        double scroll_offset = scrolled_window.vadjustment.get_value ();
        update_user_count (tree_view.set_users (nicknames, operators));
        Idle.add (() => {
            scrolled_window.vadjustment.set_value (scroll_offset);
            return false;
        });
        search_entry.sensitive = true;
    }

    private void update_user_count (int num_users) {
        if (num_users == 1) {
            label.set_text (_("%d user").printf (num_users));
        } else {
            label.set_text (_("%d users").printf (num_users));
        }
    }

    public signal void initiate_private_message (string nickname);

}
