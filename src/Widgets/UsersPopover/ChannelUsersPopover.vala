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
    
    private Gtk.Box box;
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

        Gtk.ScrolledWindow scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.min_content_height = 50;
        scrolled_window.max_content_height = 250;
        scrolled_window.propagate_natural_height = true;
        scrolled_window.margin_bottom = 6;

        tree_view = new Iridium.Widgets.UsersPopover.ChannelUsersList ();
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
        //  list_box.row_selected.connect ((row) => {
        //      if (row == null) {
        //          return;
        //      }
        //      Iridium.Widgets.UsersPopover.UserListBoxRow user_row = (Iridium.Widgets.UsersPopover.UserListBoxRow) row;
        //      nickname_selected (user_row.nickname);
        //      popdown ();
        //  });
        this.closed.connect (() => {
            search_entry.set_text ("");
            //  list_box.select_row (null);
        });
    }

    

    public void set_users (Gee.List<string> nicknames, Gee.List<string> operators) {
        //  list_box.foreach ((widget) => {
        //      widget.destroy ();
        //  });
        //  foreach (string nickname in nicknames) {
        //      if (nickname == null || nickname.chomp ().length == 0) {
        //          continue;
        //      }
        //      bool is_op = operators.contains (nickname);
        //      var row = new Iridium.Widgets.UsersPopover.UserListBoxRow (nickname, is_op);
        //      list_box.insert (row, -1);
        //  }
        //  list_box.show_all ();
        //  list_box.invalidate_sort ();
        //  list_box.invalidate_filter ();
        //  scrolled_window.check_resize ();
        // For performance reasons, unset the data model before populating it, then re-add to the tree view once fully populated
        nicknames.sort ((a, b) => {
            return a.down ().ascii_casecmp (b.down ());
        });
        search_entry.sensitive = false;
        update_user_count (tree_view.set_users (nicknames, operators));
        search_entry.sensitive = true;
    }

    private void update_user_count (int num_users) {
        if (num_users == 1) {
            label.set_text ("%d user".printf (num_users));
        } else {
            label.set_text ("%d users".printf (num_users));
        }
    }

    public signal void nickname_selected (string nickname);

}
