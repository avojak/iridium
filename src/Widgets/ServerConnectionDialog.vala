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

public class Iridium.Widgets.ServerConnectionDialog : Gtk.Dialog {

    public unowned Iridium.MainWindow main_window { get; construct; }

    private Gee.Map<int, Iridium.Models.AuthenticationMethod> auth_methods;
    private Gee.Map<int, string> auth_method_display_strings;
    private Gtk.ComboBox auth_method_combo;
    private Gtk.Entry password_entry;
    private Gtk.Entry port_entry;

    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    enum Column {
        AUTH_METHOD
    }

    public ServerConnectionDialog (Iridium.MainWindow main_window) {
        Object (
            deletable: false,
            resizable: false,
            title: "Connect to a Server",
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

        var header_image = new Gtk.Image.from_icon_name ("network-server", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label ("New Connection");
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        /* header_title.margin_end = 10; */
        header_title.set_line_wrap (true);

        /* var favorite_image = new Gtk.Image.from_icon_name ("non-starred", Gtk.IconSize.DIALOG); */

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);
        /* header_grid.attach (favorite_image, 2, 0, 1, 1); */

        body.add (header_grid);

        // Create the form
        var form_grid = new Gtk.Grid ();
        form_grid.margin = 30;
        form_grid.row_spacing = 12;
        form_grid.column_spacing = 20;

        var server_label = new Gtk.Label ("Server:");
        server_label.halign = Gtk.Align.END;

        var server_entry = new Gtk.Entry ();
        server_entry.hexpand = true;
        server_entry.placeholder_text = "irc.freenode.net";

        var nickname_label = new Gtk.Label ("Nickname:");
        nickname_label.halign = Gtk.Align.END;

        var nickname_entry = new Gtk.Entry ();
        nickname_entry.hexpand = true;
        nickname_entry.placeholder_text = "iridium";

        var username_label = new Gtk.Label ("Username:");
        username_label.halign = Gtk.Align.END;

        var username_entry = new Gtk.Entry ();
        username_entry.hexpand = true;
        username_entry.placeholder_text = "iridium";

        var realname_label = new Gtk.Label ("Real Name:");
        realname_label.halign = Gtk.Align.END;

        var realname_entry = new Gtk.Entry ();
        realname_entry.hexpand = true;
        realname_entry.placeholder_text = "Iridium IRC Client";

        // TODO: It would be nice to do some sizing work here so that the
        //       dialog doesn't resize horizontally the section expands
        var expander = new Gtk.Expander ("Advanced");
        expander.add (create_advanced_settings_view ());

        form_grid.attach (server_label, 0, 0, 1, 1);
        form_grid.attach (server_entry, 1, 0, 1, 1);
        form_grid.attach (nickname_label, 0, 1, 1, 1);
        form_grid.attach (nickname_entry, 1, 1, 1, 1);
        form_grid.attach (username_label, 0, 2, 1, 1);
        form_grid.attach (username_entry, 1, 2, 1, 1);
        form_grid.attach (realname_label, 0, 3, 1, 1);
        form_grid.attach (realname_entry, 1, 3, 1, 1);
        form_grid.attach (expander, 0, 4, 2, 1);

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
        var cancel_button = new Gtk.Button.with_label ("Cancel");
        cancel_button.clicked.connect (() => {
            close ();
        });

        var connect_button = new Gtk.Button.with_label ("Connect");
        connect_button.get_style_context ().add_class ("suggested-action");
        connect_button.clicked.connect (() => {
            // TODO: Validate entries first!
            spinner.start ();
            status_label.label = "";
            var server_name = server_entry.get_text ().chomp ().chug ();
            var nickname = nickname_entry.get_text ().chomp ().chug ();
            var username = username_entry.get_text ().chomp ().chug ();
            var realname = realname_entry.get_text ().chomp ().chug ();
            var port = (uint16) port_entry.get_text ().chomp ().chug ().to_int ();
            if (port == 0) {
                port = Iridium.Services.ServerConnectionDetails.DEFAULT_PORT;
            }
            var auth_method = auth_methods.get (auth_method_combo.get_active ());
            var auth_token = password_entry.get_text ();
            connect_button_clicked (server_name, nickname, username, realname, port, auth_method, auth_token);
        });

        add_action_widget (cancel_button, 0);
        add_action_widget (connect_button, 1);
    }

    private Gtk.Grid create_advanced_settings_view () {
        var advanced_settings_view = new Gtk.Grid ();
        advanced_settings_view.margin = 0;
        advanced_settings_view.margin_top = 12;
        advanced_settings_view.row_spacing = 12;
        advanced_settings_view.column_spacing = 20;

        var port_label = new Gtk.Label ("Port:");
        port_label.halign = Gtk.Align.END;

        // TODO: Force numeric input
        port_entry = new Gtk.Entry ();
        port_entry.hexpand = true;
        port_entry.placeholder_text = "6667";

        var auth_method_label = new Gtk.Label ("Authentication Method:");
        auth_method_label.halign = Gtk.Align.END;

        var list_store = new Gtk.ListStore (1, typeof (string));
        // TODO: This can be handled better
        auth_methods = new Gee.HashMap<int, Iridium.Models.AuthenticationMethod> ();
        auth_method_display_strings = new Gee.HashMap<int, string> ();
        auth_methods.set(0, Iridium.Models.AuthenticationMethod.NONE);
        auth_method_display_strings.set (0, Iridium.Models.AuthenticationMethod.NONE.get_display_string ());
        auth_methods.set(1, Iridium.Models.AuthenticationMethod.SERVER_PASSWORD);
		auth_method_display_strings.set (1, Iridium.Models.AuthenticationMethod.SERVER_PASSWORD.get_display_string ());
        for (int i = 0; i < auth_method_display_strings.size; i++) {
            Gtk.TreeIter iter;
            list_store.append (out iter);
            list_store.set (iter, Column.AUTH_METHOD, auth_method_display_strings[i]);
        }
        auth_method_combo = new Gtk.ComboBox.with_model (list_store);
        var auth_method_cell = new Gtk.CellRendererText ();
        auth_method_combo.pack_start (auth_method_cell, false);
        auth_method_combo.set_attributes (auth_method_cell, "text", 0);
        auth_method_combo.set_active (0);

        var password_label = new Gtk.Label ("Password:");
        password_label.halign = Gtk.Align.END;

        // TODO: Disable entry when the dropdown is set to None
        password_entry = new Gtk.Entry ();
        password_entry.hexpand = true;
        password_entry.visibility = false;
		password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "changes-prevent-symbolic");
		password_entry.icon_press.connect ((pos, event) => {
			if (pos == Gtk.EntryIconPosition.SECONDARY) {
				password_entry.visibility = !password_entry.visibility;
			}
 			if (password_entry.visibility) {
				password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "changes-allow-symbolic");
			} else {
				password_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "changes-prevent-symbolic");
			}
		});

        advanced_settings_view.attach (port_label, 0, 0, 1, 1);
        advanced_settings_view.attach (port_entry, 1, 0, 1, 1);
        advanced_settings_view.attach (auth_method_label, 0, 1, 1, 1);
        advanced_settings_view.attach (auth_method_combo, 1, 1, 1, 1);
        advanced_settings_view.attach (password_label, 0, 2, 1, 1);
        advanced_settings_view.attach (password_entry, 1, 2, 1, 1);

        return advanced_settings_view;
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

    public signal void connect_button_clicked (string server, string nickname, string username, string realname, 
        uint16 port, Iridium.Models.AuthenticationMethod auth_method, string auth_token);

}
