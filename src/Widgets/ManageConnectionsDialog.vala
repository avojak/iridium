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

public class Iridium.Widgets.ManageConnectionsDialog : Gtk.Dialog {

    public unowned Iridium.MainWindow main_window { get; construct; }
    public Gee.List<Iridium.Services.Server> servers { get; construct; }

    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    public ManageConnectionsDialog (Iridium.MainWindow main_window, Gee.List<Iridium.Services.Server> servers) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Manage Connections"),
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            servers: servers
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

        var header_image = new Gtk.Image.from_icon_name ("network-server", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("Manage Connections"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

        body.add (header_grid);

        // Create the form
        var form_grid = new Gtk.Grid ();
        form_grid.margin = 30;
        form_grid.row_spacing = 12;
        form_grid.column_spacing = 20;

        var list_store = new Gtk.ListStore (1, typeof (string));
        foreach (var server in servers) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, 0, server.connection_details.server);
        }
        var server_combo = new Gtk.ComboBox.with_model (list_store);
        var server_cell = new Gtk.CellRendererText ();
        server_combo.pack_start (server_cell, false);
        server_combo.set_attributes (server_cell, "text", 0);
        //  server_combo.set_active (servers.size == 0 ? -1 : 0);
        server_combo.set_active (-1);

        var nickname_label = new Gtk.Label (_("Nickname"));
        nickname_label.halign = Gtk.Align.END;

        var nickname_entry = new Gtk.Entry ();
        nickname_entry.hexpand = true;

        var username_label = new Gtk.Label (_("Username"));
        username_label.halign = Gtk.Align.END;

        var username_entry = new Gtk.Entry ();
        username_entry.hexpand = true;

        var realname_label = new Gtk.Label (_("Real Name"));
        realname_label.halign = Gtk.Align.END;

        var realname_entry = new Gtk.Entry ();
        realname_entry.hexpand = true;

        form_grid.attach (server_combo, 0, 0, 2, 1);
        form_grid.attach (nickname_label, 0, 1, 1, 1);
        form_grid.attach (nickname_entry, 1, 1, 1, 1);
        form_grid.attach (username_label, 0, 2, 1, 1);
        form_grid.attach (username_entry, 1, 2, 1, 1);
        form_grid.attach (realname_label, 0, 3, 1, 1);
        form_grid.attach (realname_entry, 1, 3, 1, 1);

        body.add (form_grid);

        spinner = new Gtk.Spinner ();
        body.add (spinner);

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_line_wrap (true);
        status_label.margin_bottom = 10;
        body.add (status_label);

       // Add action buttons
       var close_button = new Gtk.Button.with_label (_("Close"));
       close_button.clicked.connect (() => {
           close ();
       });

       var save_button = new Gtk.Button.with_label (_("Save"));
       save_button.get_style_context ().add_class ("suggested-action");
       save_button.clicked.connect (() => {
           spinner.start ();
           status_label.label = "";
           // TODO: Implement
           save_button_clicked ();
       });

       save_button.sensitive = server_combo.get_active () != -1;
       server_combo.changed.connect (() => {
           save_button.sensitive = server_combo.get_active () != -1;

           var server = servers.get (server_combo.get_active ());
           nickname_entry.set_text (server.connection_details.nickname);
           username_entry.set_text (server.connection_details.username);
           realname_entry.set_text (server.connection_details.realname);
       });

       add_action_widget (close_button, 0);
       add_action_widget (save_button, 1);
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

    public signal void save_button_clicked ();

}
