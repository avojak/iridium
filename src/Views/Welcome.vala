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

public class Iridium.Views.Welcome : Granite.Widgets.Welcome {

    public unowned Iridium.MainWindow main_window { get; construct; }

    public Welcome (Iridium.MainWindow main_window) {
        Object (
            title: "Welcome to Iridium",
            subtitle: "Connect to Any IRC Server",
            main_window: main_window
        );
    }

    construct {
        valign = Gtk.Align.FILL;
        halign = Gtk.Align.FILL;
        vexpand = true;

        // TODO: Instead, simply have an option to connect to a new server. We
        //       can maybe have a separate star icon for favoriting?
        append ("bookmark-new", "Add a New Server", "Connect to a Server and Save It in Your Library");

        activated.connect (index => {
            switch (index) {
                case 0:
                    create_new_connection ();
                break;
            }
        });
    }

    // TODO: Move this somewhere else
    private void create_new_connection () {
        if (main_window.connection_dialog == null) {
            main_window.connection_dialog = new Iridium.Widgets.ServerConnectionDialog (main_window);
            main_window.connection_dialog.show_all ();
            main_window.connection_dialog.destroy.connect (() => {
                main_window.connection_dialog = null;
            });
        }
        main_window.connection_dialog.present ();
    }

}
