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

    public unowned Iridium.MainWindow main_window { get; construct; }
    public string server_name { get; construct; }

    private Gtk.TreeView tree_view;
    private Gtk.ListStore list_store;
    private Gtk.TreeModelFilter filter;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;
    private Gtk.Entry search_entry;

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
        //  search_entry.activate.connect (() => {
        //      message_to_send (search_entry.get_text ());
        //      search_entry.set_text ("");
        //  });
        search_entry.changed.connect (filter.refilter);
        search_entry.changed.connect (() => {
            if (search_entry.text != "") {
                search_entry.secondary_icon_name = "edit-clear-symbolic";
            } else {
                search_entry.secondary_icon_name = null;
            }
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
        join_button.get_style_context ().add_class ("suggested-action");
        join_button.clicked.connect (() => {
            // TODO: Validate entries first!
            spinner.start ();
            status_label.label = "";
            //  var server_name = servers[server_combo.get_active ()];
            //  var channel_name = channel_entry.get_text ().chug ().chomp ();
            //  join_button_clicked (server_name, channel_name);
        });

        //  join_button.sensitive = server_combo.get_active () != -1;
        //  server_combo.changed.connect (() => {
        //      join_button.sensitive = server_combo.get_active () != -1;
        //      browse_button.sensitive = server_combo.get_active () != -1;
        //      channel_entry.sensitive = server_combo.get_active () != -1;
        //  });

        add_action_widget (cancel_button, 0);
        add_action_widget (join_button, 1);
    }

    public string get_server () {
        return server_name;
    }

    public void set_channels (Gee.List<Iridium.Models.ChannelListEntry> channels) {
        // For performance reasons, unset the data model before populating it, then re-add to the tree view once fully populated
        tree_view.set_model (null);
        search_entry.sensitive = false;
        list_store.clear ();
        foreach (var entry in channels) {
            //  if (entry == null || entry.channel_name == null || entry.num_visible_users == null || entry.topic == null) {
            //      continue;
            //  }
            Gtk.TreeIter iter;
            list_store.append (out iter);
			list_store.set (iter, Column.NAME, entry.channel_name,
                                 Column.USERS, entry.num_visible_users,
                                 Column.TOPIC, entry.topic);
        }
        
        //  Gtk.TreeModelFilterVisibleFunc tree_view_filter_func = filter_func;
        tree_view.set_model (filter);
        spinner.stop ();
        status_label.label = "%s channels found".printf (channels.size.to_string ());
        search_entry.sensitive = true;
    }

    private bool filter_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
        debug ("filter func");
        if (search_entry == null) {
            debug ("null entry");
            return true;
        }
        string search_string = search_entry.get_text () == null ? "" : search_entry.get_text ().strip ().down ();
        debug ("search string: %s", search_string);
        if (search_string == "") {
            return true;
        }
        string name = "";
        string topic = "";
        //  model.get (iter, Column.NAME, &name, -1);
        //  model.get (iter, Column.TOPIC, &topic, -1);
        if (name == null || topic == null) {
            return true;
        }
        //  if (name == null) {
        //      debug ("name is null");
        //      return false;
        //  }
        //  if (topic == null) {
        //      debug ("topic is null");
        //      return false;
        //  }
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
    }

    public void show_loading () {
        spinner.start ();
        status_label.label = _("Retrieving channels, this may take a minute…");
    }

    public signal void join_button_clicked (string channel);
    public signal void refresh_button_clicked ();

}
