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

public class Iridium.Widgets.BrowseChannelsDialog : Gtk.Dialog {

    // TODO: At some point it might be nice to add the ability to sort the columns

    public unowned Iridium.MainWindow main_window { get; construct; }
    public string server_name { get; construct; }

    // I'm not 100% sure why this needs to be static - but they did it over
    // here: https://github.com/xfce-mirror/xfmpc/blob/921fa89585d61b7462e30bac5caa9b2f583dd491/src/playlist.vala
    // And it doesn't work otherwise...
    private static Gtk.Entry search_entry;

    private Gtk.TreeView tree_view;
    private Gtk.ListStore placeholder_list_store;
    private Gtk.ListStore list_store;
    private Gtk.TreeModelFilter filter;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    private string? joining_channel;

    enum Column {
		NAME,
		USERS,
		TOPIC
	}

    public BrowseChannelsDialog (Iridium.MainWindow main_window, string server_name) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Browse Channels"),
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            server_name: server_name
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

        var header_title = new Gtk.Label (_("Browse Channels"));
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
        search_entry.sensitive = false;
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
        scrolled_window.max_content_height = 250;
        scrolled_window.max_content_width = 250;
        scrolled_window.height_request = 250;
        scrolled_window.width_request = 500;
        scrolled_window.propagate_natural_height = true;

        tree_view = new Gtk.TreeView ();
        tree_view.expand = true;
        tree_view.headers_visible = true;
        tree_view.enable_tree_lines = true;
        tree_view.fixed_height_mode = true;

        placeholder_list_store = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (string));
        list_store = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (string));
        filter = new Gtk.TreeModelFilter (list_store, null);
        filter.set_visible_func ((Gtk.TreeModelFilterVisibleFunc) filter_func);

        Gtk.CellRendererText name_column_renderer = new Gtk.CellRendererText ();
        name_column_renderer.ellipsize = Pango.EllipsizeMode.END;

        tree_view.insert_column_with_attributes (-1, _("Name"), name_column_renderer, "text", Column.NAME);
        tree_view.insert_column_with_attributes (-1, _("Users"), new Gtk.CellRendererText (), "text", Column.USERS);
        tree_view.insert_column_with_attributes (-1, _("Topic"), new Gtk.CellRendererText (), "text", Column.TOPIC);

        foreach (var column in tree_view.get_columns ()) {
            column.resizable = true;
        }
        tree_view.get_column (Column.NAME).min_width = 150;

        // Use a placeholder list store with no data to ensure that the tree view will render the column
        // headers and the proper size while the real data is being loaded in the background.
        tree_view.set_model (placeholder_list_store);

        scrolled_window.add (tree_view);

        main_grid.attach (search_label, 0, 0, 1, 1);
        main_grid.attach (search_entry, 1, 0, 1, 1);
        main_grid.attach (scrolled_window, 0, 1, 2, 1);

        body.add (main_grid);

        spinner = new Gtk.Spinner ();

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_line_wrap (true);
        status_label.margin_bottom = 10;

        body.add (spinner);
        body.add (status_label);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        var join_button = new Gtk.Button.with_label (_("Join"));
        join_button.sensitive = false;
        join_button.get_style_context ().add_class ("suggested-action");
        join_button.clicked.connect (() => {
            string? channel_name = get_selection ();
            if (channel_name == null) {
                return;
            }
            
            // Hold onto the channel that we're trying to join so that we can better
            // respond to successful channel joins in the MainWindow
            joining_channel = channel_name;

            spinner.start ();
            status_label.label = "";
            
            join_button_clicked (channel_name);
        });

        tree_view.get_selection ().changed.connect (() => {
            join_button.sensitive = tree_view.get_selection ().count_selected_rows () > 0;
        });

        add_action_widget (cancel_button, 0);
        add_action_widget (join_button, 1);
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
            string channel_name = "";
            filter.get (iter, Column.NAME, out channel_name, -1);
            return channel_name;
        }
        return null;
    }

    public string get_server () {
        return server_name;
    }

    public string? get_channel () {
        return joining_channel;
    }

    public void set_channels (Gee.List<Iridium.Models.ChannelListEntry> channels) {
        // For performance reasons, unset the data model before populating it, then re-add to the tree view once fully populated
        tree_view.set_model (placeholder_list_store);
        search_entry.sensitive = false;
        list_store.clear ();
        foreach (var entry in channels) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
			list_store.set (iter, Column.NAME, entry.channel_name,
                                 Column.USERS, entry.num_visible_users,
                                 Column.TOPIC, entry.topic);
        }
        // With the model fully populated, we can now update the view
        tree_view.set_model (filter);
        spinner.stop ();
        status_label.label = "%s channels found".printf (channels.size.to_string ());
        search_entry.sensitive = true;
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
        string topic = "";
        model.get (iter, Column.NAME, out name, -1);
        model.get (iter, Column.TOPIC, out topic, -1);
        if (name == null || topic == null) {
            return true;
        }
        if (name.down ().contains (search_string) || topic.down ().contains (search_string)) {
            return true;
        }
        return false;
    }

    public void dismiss () {
        spinner.stop ();
        close ();
    }

    public void display_error (string message) {
        // TODO: We can make the error messaging better
        spinner.stop ();
        status_label.label = message;
        joining_channel = null;
    }

    public void show_loading () {
        spinner.start ();
        status_label.label = _("Retrieving channels, this may take a minute…");
    }

    public signal void join_button_clicked (string channel);
    public signal void refresh_button_clicked ();

}
