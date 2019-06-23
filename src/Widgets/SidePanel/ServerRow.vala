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

public class Iridium.Widgets.SidePanel.ServerRow : Granite.Widgets.SourceList.ExpandableItem, Iridium.Widgets.SidePanel.Row {

    public string server_name { get; construct; }

    private bool is_enabled = true;

    public ServerRow (string server_name) {
        Object (
            name: server_name,
            server_name: server_name
        );
    }

    construct {
        icon = new GLib.ThemedIcon ("user-available");
    }

    public new string get_server_name () {
        return server_name;
    }

    public new string? get_channel_name () {
        return null;
    }

    public new void enable () {
        if (is_enabled) {
            return;
        }
        icon = new GLib.ThemedIcon ("user-available");
        markup = null;
        is_enabled = true;
    }

    public new void disable () {
        if (!is_enabled) {
            return;
        }
        icon = new GLib.ThemedIcon ("user-offline");
        markup = "<i>" + server_name + "</i>";
        is_enabled = false;
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var edit_item = new Gtk.MenuItem.with_label ("Edit settings...");
        edit_item.activate.connect (() => {
            // TODO: Implement
        });

        var connect_item = new Gtk.MenuItem.with_label ("Connect");
        connect_item.activate.connect (() => {
            connect_to_server ();
        });

        var disconnect_item = new Gtk.MenuItem.with_label ("Disconnect");
        disconnect_item.activate.connect (() => {
            disconnect_from_server ();
        });

        var close_item = new Gtk.MenuItem.with_label ("Close");
        close_item.activate.connect (() => {
            if (is_enabled) {
                disconnect_from_server ();
            }
            remove_server ();
        });

        menu.append (edit_item);
        menu.append (new Gtk.SeparatorMenuItem ());
        if (is_enabled) {
            menu.append (disconnect_item);
        } else {
            menu.append (connect_item);
        }
        menu.append (close_item);

        menu.show_all ();

        return menu;
    }

    public signal void disconnect_from_server ();
    public signal void connect_to_server ();
    public signal void remove_server ();

}
