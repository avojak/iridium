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

    // TODO: Need to handle nicknames for OPs and other special cases where the
    //       nickname starts with a symbol (e.g. @)

    private Gtk.SearchEntry search_entry;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.ListBox list_box;

    public ChannelUsersPopover (Gtk.Widget? relative_to) {
        Object (
            relative_to: relative_to
        );
    }

    construct {
        var placeholder = new Gtk.Label (_("No users"));
        placeholder.margin_top = 4;
        placeholder.margin_bottom = 4;
        placeholder.show_all ();

        scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.max_content_height = 250;
        scrolled_window.propagate_natural_height = true;

        list_box = new Gtk.ListBox ();
        list_box.expand = true;
        list_box.activate_on_single_click = true;
        list_box.selection_mode = Gtk.SelectionMode.SINGLE;
        list_box.set_placeholder (placeholder);
        scrolled_window.add (list_box);

        list_box.set_filter_func (filter_func);
        list_box.set_sort_func (sort_func);
        // TODO: User header_func to add header for Ops/Owners/Others?
        // list_box.set_header_func ();

        search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 6;

        var users_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        users_box.pack_start (search_entry, true, false, 0);
        users_box.pack_start (scrolled_window, true, false, 0);

        add (users_box);

        users_box.show_all ();

        search_entry.search_changed.connect (() => {
            list_box.invalidate_filter ();
        });
        list_box.row_selected.connect ((row) => {
            if (row == null) {
                return;
            }
            Iridium.Widgets.UsersPopover.UserListBoxRow user_row = (Iridium.Widgets.UsersPopover.UserListBoxRow) row;
            nickname_selected (user_row.nickname);
            popdown ();
        });
        this.closed.connect (() => {
            search_entry.set_text ("");
            list_box.select_row (null);
        });
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        if (search_entry.text == null || search_entry.text.length == 0) {
            return true;
        }
        Iridium.Widgets.UsersPopover.UserListBoxRow user_row = (Iridium.Widgets.UsersPopover.UserListBoxRow) row;
        return user_row.nickname.contains (search_entry.text);
    }

    private int sort_func (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        Iridium.Widgets.UsersPopover.UserListBoxRow user_row1 = (Iridium.Widgets.UsersPopover.UserListBoxRow) row1;
        Iridium.Widgets.UsersPopover.UserListBoxRow user_row2 = (Iridium.Widgets.UsersPopover.UserListBoxRow) row2;
        return user_row1.nickname.collate (user_row2.nickname);
    }

    public void set_users (Gee.List<string> nicknames, Gee.List<string> operators) {
        list_box.foreach ((widget) => {
            widget.destroy ();
        });
        foreach (string nickname in nicknames) {
            if (nickname == null || nickname.chomp ().length == 0) {
                continue;
            }
            bool is_op = operators.contains (nickname);
            var row = new Iridium.Widgets.UsersPopover.UserListBoxRow (nickname, is_op);
            list_box.insert (row, -1);
        }
        list_box.show_all ();
        list_box.invalidate_sort ();
        list_box.invalidate_filter ();
        scrolled_window.check_resize ();
    }

    public signal void nickname_selected (string nickname);

}
