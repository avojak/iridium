/*
 * Copyright (c) 2021 Andrew Vojak (https://avojak.com)
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

public class Iridium.Widgets.BrowseServersDialog : Granite.Dialog {

    // TODO: At some point it might be nice to add the ability to sort the columns

    public unowned Iridium.MainWindow main_window { get; construct; }
    public string server_name { get; construct; }

    // I'm not 100% sure why this needs to be static - but they did it over
    // here: https://github.com/xfce-mirror/xfmpc/blob/921fa89585d61b7462e30bac5caa9b2f583dd491/src/playlist.vala
    // And it doesn't work otherwise...
    private static Gtk.Entry search_entry;

    private Gtk.TreeView tree_view;
    private Gtk.ListStore list_store;
    private Gtk.TreeModelFilter filter;

    enum Column {
        NAME,
        HOST
    }

    public BrowseServersDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Browse Servers"),
            transient_for: main_window,
            modal: true,
            main_window: main_window
        );
    }

    construct {
        var body = get_content_area ();

        // Create the header
        var header_grid = new Gtk.Grid ();
        header_grid.margin_start = 30;
        header_grid.margin_end = 30;
        header_grid.margin_bottom = 10;
        header_grid.column_spacing = 10;

        var header_image = new Gtk.Image.from_icon_name ("system-search", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("Browse Servers"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

        body.add (header_grid);

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 30;
        main_grid.row_spacing = 12;
        main_grid.column_spacing = 10;

        var search_label = new Gtk.Label (_("Search:"));
        search_label.halign = Gtk.Align.START;

        search_entry = new Gtk.Entry ();
        search_entry.sensitive = true;
        search_entry.hexpand = true;
        search_entry.secondary_icon_tooltip_text = _("Clear");
        search_entry.changed.connect (() => {
            if (search_entry.text != "") {
                search_entry.secondary_icon_name = "edit-clear-symbolic";
            } else {
                search_entry.secondary_icon_name = null;
            }
            filter.refilter ();
        });
        search_entry.icon_release.connect ((icon_pos, event) => {
            if (icon_pos == Gtk.EntryIconPosition.SECONDARY) {
                search_entry.set_text ("");
            }
        });

        Gtk.ScrolledWindow scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.max_content_height = 250;
        scrolled_window.max_content_width = 250;
        scrolled_window.height_request = 250;
        scrolled_window.width_request = 350;
        scrolled_window.propagate_natural_height = true;

        tree_view = new Gtk.TreeView ();
        tree_view.expand = true;
        tree_view.headers_visible = true;
        tree_view.enable_tree_lines = true;
        tree_view.fixed_height_mode = true;

        list_store = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (string));
        filter = new Gtk.TreeModelFilter (list_store, null);
        filter.set_visible_func ((Gtk.TreeModelFilterVisibleFunc) filter_func);

        Gtk.CellRendererText name_column_renderer = new Gtk.CellRendererText ();
        name_column_renderer.ellipsize = Pango.EllipsizeMode.END;
        Gtk.CellRendererText host_column_renderer = new Gtk.CellRendererText ();
        host_column_renderer.ellipsize = Pango.EllipsizeMode.END;

        tree_view.insert_column_with_attributes (-1, _("Network"), name_column_renderer, "text", Column.NAME);
        tree_view.insert_column_with_attributes (-1, _("Host"), host_column_renderer, "text", Column.HOST);

        foreach (var column in tree_view.get_columns ()) {
            column.resizable = true;
        }
        tree_view.get_column (Column.NAME).min_width = 150;

        scrolled_window.add (tree_view);

        main_grid.attach (search_label, 0, 0, 1, 1);
        main_grid.attach (search_entry, 1, 0, 1, 1);
        main_grid.attach (scrolled_window, 0, 1, 2, 1);

        body.add (main_grid);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        var connect_button = new Gtk.Button.with_label (_("Connect"));
        connect_button.sensitive = false;
        connect_button.get_style_context ().add_class ("suggested-action");
        connect_button.clicked.connect (() => {
            string? network_name = get_selection ();
            if (network_name == null) {
                return;
            }

            Iridium.Models.CuratedServer.Servers? server = Iridium.Models.CuratedServer.Servers.get_for_network_name (network_name);
            if (server != null) {
                connect_button_clicked (server.get_details ());
            }
        });

        tree_view.get_selection ().changed.connect (() => {
            connect_button.sensitive = tree_view.get_selection ().count_selected_rows () > 0;
        });

        add_action_widget (cancel_button, 0);
        add_action_widget (connect_button, 1);

        set_servers ();
    }

    private void set_servers () {
        foreach (var entry in Iridium.Models.CuratedServer.Servers.all ()) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, Column.NAME, entry.get_details ().network_name,
                                  Column.HOST, entry.get_details ().server_host);
        }
        tree_view.set_model (filter);
    }

    private string? get_selection () {
        var selection = tree_view.get_selection ();
        if (selection.count_selected_rows () > 1) {
            // This should never happen
            return null;
        }
        Gtk.TreeModel model = filter;
        var list = selection.get_selected_rows (out model);
        if (list.length () == 0) {
            return null;
        }
        Gtk.TreeIter iter;
        var path = list.nth_data (0);
        if (filter.get_iter (out iter, path)) {
            string network_name = "";
            filter.get (iter, Column.NAME, out network_name, -1);
            return network_name;
        }
        return null;
    }

    // I'm not 100% sure why this needs to be static - but they did it over
    // here: https://github.com/xfce-mirror/xfmpc/blob/921fa89585d61b7462e30bac5caa9b2f583dd491/src/playlist.vala
    // And it doesn't work otherwise...
    private static bool filter_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
        if (search_entry == null) {
            return true;
        }
        string search_string = search_entry.get_text () == null ? "" : search_entry.get_text ().strip ().down ();
        if (search_string == "") {
            return true;
        }
        string name = "";
        string host = "";
        model.get (iter, Column.NAME, out name, -1);
        model.get (iter, Column.HOST, out host, -1);
        if (name == null || host == null) {
            return true;
        }
        if (name.down ().contains (search_string) || host.down ().contains (search_string)) {
            return true;
        }
        return false;
    }

    public void dismiss () {
        close ();
    }

    public signal void connect_button_clicked (Iridium.Models.CuratedServer server);

}
