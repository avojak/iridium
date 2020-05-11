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

public class Iridium.Widgets.StatusBar : Gtk.ActionBar {

    private Gtk.MenuItem channel_join_menu_item;

    construct {
        var server_connect_menu_item = new Gtk.MenuItem.with_label (_("Connect to a Server…"));
        channel_join_menu_item = new Gtk.MenuItem.with_label (_("Join a Channel…"));
        
        var menu = new Gtk.Menu ();
        menu.append (server_connect_menu_item);
        menu.append (channel_join_menu_item);
        menu.show_all ();

        var add_menu_button = new Gtk.MenuButton ();
        add_menu_button.direction = Gtk.ArrowType.UP;
        add_menu_button.popup = menu;
        add_menu_button.tooltip_text = _("Join a Server or Channel");
        add_menu_button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));
        add_menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var manage_connections_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        manage_connections_button.tooltip_text = _("Manage connections…");
        manage_connections_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        pack_start (add_menu_button);
        //  pack_end (manage_connections_button);

        server_connect_menu_item.activate.connect (() => {
            server_connect_button_clicked ();
        });

        channel_join_menu_item.activate.connect (() => {
            channel_join_button_clicked ();
        });

        manage_connections_button.clicked.connect (() => {
            manage_connections_button_clicked ();
        });
    }

    public void enable_channel_join_item () {
        channel_join_menu_item.sensitive = true;
    }

    public void disable_channel_join_item () {
        channel_join_menu_item.sensitive = false;
    }

    public signal void server_connect_button_clicked ();
    public signal void channel_join_button_clicked ();
    public signal void manage_connections_button_clicked ();
    
}
