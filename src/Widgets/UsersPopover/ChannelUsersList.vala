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

public class Iridium.Widgets.UsersPopover.ChannelUsersList : Gtk.TreeView {

    // This class is heavily influenced by the Granite.Widgets.SourceList, but contains
    // some optimization to allow efficiently adding a large number of items.
    // https://github.com/elementary/granite/blob/master/lib/Widgets/SourceList.vala

    enum Column {
        //  STATUS_ICON,
        NICKNAME,
        OP_BADGE,
        IS_OP
    }

    private const string DEFAULT_STYLESHEET = """
        .sidebar.badge {
            border-radius: 10px;
            border-width: 0;
            padding: 1px 2px 1px 2px;
            font-weight: bold;
        }
    """;

    private static string search_text = "";

    private Gtk.ListStore list_store;
    private Gtk.TreeModelFilter filter;

    public ChannelUsersList () {
        Object (
            expand: true,
            headers_visible: false,
            enable_tree_lines: false,
            fixed_height_mode: true
        );
    }

    construct {
        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_SIDEBAR);
        style_context.add_class (Granite.STYLE_CLASS_SOURCE_LIST);

        var css_provider = new Gtk.CssProvider ();
        try {
            css_provider.load_from_data (DEFAULT_STYLESHEET, -1);
            style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, DEFAULT_STYLESHEET);
        }

        list_store = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (bool));
        filter = new Gtk.TreeModelFilter (list_store, null);
        filter.set_visible_func ((Gtk.TreeModelFilterVisibleFunc) filter_func);

        var nickname_renderer = new Gtk.CellRendererText ();
        nickname_renderer.ellipsize = Pango.EllipsizeMode.END;

        var badge_renderer = new Granite.Widgets.CellRendererBadge ();

        //  insert_column_with_attributes (-1, null, new Gtk.CellRendererPixbuf (), "icon-name", Column.STATUS_ICON);
        insert_column_with_attributes (-1, null, nickname_renderer, "text", Column.NICKNAME);
        insert_column_with_attributes (-1, null, badge_renderer, "text", Column.OP_BADGE);
        insert_column_with_attributes (-1, null, new Gtk.CellRendererToggle (), "active", Column.IS_OP);

        set_tooltip_column (Column.NICKNAME);

        for (int i = 0; i < get_n_columns (); i++) {
            unowned var column = get_column (i);
            column.expand = (i == Column.NICKNAME);
            column.sizing = Gtk.TreeViewColumnSizing.FIXED;
            column.visible = (i != Column.IS_OP);
        }

        get_column (Column.OP_BADGE).set_cell_data_func (badge_renderer, badge_cell_data_func);

        button_press_event.connect ((event) => {
            if ((event.type == Gdk.EventType.BUTTON_PRESS) && (event.button == Gdk.BUTTON_SECONDARY)) {
                // Get the path within the tree where the click event occurred
                Gtk.TreePath? path;
                Gtk.TreeViewColumn? column;
                int cell_x;
                int cell_y;
                get_path_at_pos ((int) event.x, (int) event.y, out path, out column, out cell_x, out cell_y);
                if (path == null) {
                    return false;
                }
                // Get the iter for the path
                Gtk.TreeIter iter;
                if (!filter.get_iter (out iter, path)) {
                    return false;
                }
                // Determine the nickname that was selected based on the iter
                string nickname = "";
                filter.get (iter, Column.NICKNAME, out nickname, -1);

                var menu = create_popover (nickname);
                menu.popup_at_pointer (event);
                return true;
            }
            return false;
        });

        // TODO: Fix scrolling when repopulating list
    }

    private Gtk.Menu create_popover (string nickname) {
        var menu = new Gtk.Menu ();
        menu.attach_widget = this;
        var private_message_item = new Gtk.MenuItem.with_label (_("Send private message"));
        private_message_item.activate.connect (() => {
            initiate_private_message (nickname);
        });
        menu.append (private_message_item);
        menu.show_all ();
        return menu;
    }

    private void badge_cell_data_func (Gtk.CellLayout layout, Gtk.CellRenderer renderer, Gtk.TreeModel model, Gtk.TreeIter iter) {
        var badge_renderer = renderer as Granite.Widgets.CellRendererBadge;
        assert (badge_renderer != null);

        string op_badge = "";
        model.get (iter, Column.OP_BADGE, out op_badge, -1);
        bool is_visible = (op_badge != null) && (op_badge.strip () != "");

        badge_renderer.visible = is_visible;
        badge_renderer.text = is_visible ? op_badge : "";
    }

    private static bool filter_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
        if (search_text == "") {
            return true;
        }
        string nickname = "";
        model.get (iter, Column.NICKNAME, out nickname, -1);
        if (nickname == null) {
            return true;
        }
        if (nickname.down ().contains (search_text)) {
            return true;
        }
        return false;
    }

    public int update_search_text (string _search_text) {
        search_text = _search_text;
        filter.refilter ();
        // Return the number of visible children
        return filter.iter_n_children (null);
    }

    public int set_users (Gee.List<string> nicknames, Gee.List<string> operators) {
        set_model (null);
        list_store.clear ();
        foreach (var nickname in nicknames) {
            bool is_op = operators.contains (nickname);
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, /*Column.STATUS_ICON, "user-available",*/
                                     Column.NICKNAME, nickname,
                                     Column.OP_BADGE, is_op ? _("OP") : null,
                                        Column.IS_OP, is_op);
        }
        // With the model fully populated, we can now update the view
        set_model (filter);
        // Return the number of visible children
        return filter.iter_n_children (null);
    }

    public signal void initiate_private_message (string nickname);

}
