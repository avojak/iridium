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

public class Iridium.Widgets.ChannelJoinDialog : Gtk.Dialog {

    public unowned Iridium.MainWindow main_window { get; construct; }
    public string[] servers { get; construct; }
    public string[] network_names { get; construct; }
    public string? current_server { get; construct; }

    private bool is_favorite = false;

    private Gtk.ComboBox server_combo;
    private Gtk.Entry channel_entry;

    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    public ChannelJoinDialog (Iridium.MainWindow main_window, string[] servers, string[] network_names, string? current_server) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Join a Channel"),
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            servers: servers,
            network_names: network_names,
            current_server: current_server
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

        var header_image = new Gtk.Image.from_icon_name ("internet-chat", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("Join a Channel"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        var favorite_event_box = new Gtk.EventBox ();
        var favorite_image = new Gtk.Image.from_icon_name ("non-starred", Gtk.IconSize.DIALOG);
        favorite_event_box.add (favorite_image);
        favorite_event_box.button_press_event.connect (() => {
            if (is_favorite) {
                favorite_image.icon_name = "non-starred";
                is_favorite = false;
            } else {
                favorite_image.icon_name = "starred";
                is_favorite = true;
            }
        });

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);
        header_grid.attach (favorite_event_box, 2, 0, 1, 1);

        body.add (header_grid);

        // Create the form
        var form_grid = new Gtk.Grid ();
        form_grid.margin = 30;
        form_grid.row_spacing = 12;
        form_grid.column_spacing = 20;

        var list_store = new Gtk.ListStore (1, typeof (string));
        var active_index = -1;
        for (int i = 0; i < servers.length; i++) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
            var display_string = network_names[i] == null ? servers[i] : network_names[i];
            list_store.set (iter, 0, display_string);
            if (current_server != null && servers[i] == current_server) {
                active_index = i;
            }
        }
        server_combo = new Gtk.ComboBox.with_model (list_store);
        var server_cell = new Gtk.CellRendererText ();
        server_combo.pack_start (server_cell, false);
        server_combo.set_attributes (server_cell, "text", 0);
        server_combo.set_active (active_index);

        var channel_label = new Gtk.Label (_("Channel:"));
        channel_label.halign = Gtk.Align.END;

        channel_entry = new Gtk.Entry ();
        channel_entry.hexpand = true;
        /* channel_entry.placeholder_text = "#"; */
        channel_entry.text = "#";
        channel_entry.sensitive = server_combo.get_active () != -1;

        var browse_button = new Gtk.Button.with_label (_("Browse…"));
        browse_button.sensitive = server_combo.get_active () != -1;
        browse_button.clicked.connect (() => {
            var server_name = servers[server_combo.get_active ()];
            browse_button_clicked (server_name);
        });

        form_grid.attach (server_combo, 0, 0, 3, 1);
        form_grid.attach (channel_label, 0, 1, 1, 1);
        form_grid.attach (channel_entry, 1, 1, 1, 1);
        form_grid.attach (browse_button, 2, 1, 1, 1);

        body.add (form_grid);

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
        var not_now_button = new Gtk.Button.with_label (_("Not Now"));
        not_now_button.clicked.connect (() => {
            close ();
        });

        var join_button = new Gtk.Button.with_label (_("Join"));
        join_button.get_style_context ().add_class ("suggested-action");
        join_button.clicked.connect (() => {
            // TODO: Validate entries first!
            spinner.start ();
            status_label.label = "";
            var server_name = servers[server_combo.get_active ()];
            var channel_name = channel_entry.get_text ().chug ().chomp ();
            join_button_clicked (server_name, channel_name);
        });

        join_button.sensitive = server_combo.get_active () != -1;
        server_combo.changed.connect (() => {
            join_button.sensitive = server_combo.get_active () != -1;
            browse_button.sensitive = server_combo.get_active () != -1;
            channel_entry.sensitive = server_combo.get_active () != -1;
        });

        add_action_widget (not_now_button, 0);
        add_action_widget (join_button, 1);
    }

    public bool is_favorite_button_selected () {
        return is_favorite;
    }

    public string? get_server () {
        if (servers.length == 0) {
            return null;
        }
        if (server_combo.get_active () == -1) {
            return null;
        }
        return servers[server_combo.get_active ()];
    }

    public string? get_channel () {
        return channel_entry.get_text ().chug ().chomp ();
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

    public signal void join_button_clicked (string server, string channel);
    public signal void browse_button_clicked (string server);

}
