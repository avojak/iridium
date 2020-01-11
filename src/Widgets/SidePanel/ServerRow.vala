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

public class Iridium.Widgets.SidePanel.ServerRow : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable, Iridium.Widgets.SidePanel.Row {

    public string server_name { get; construct; }

    private bool is_enabled = true;

    public ServerRow (string server_name) {
        Object (
            name: server_name,
            server_name: server_name
        );
    }

    construct {
        //  icon = new GLib.ThemedIcon ("user-available");
        icon = new GLib.ThemedIcon ("network-server");
    }

    public new bool allow_dnd_sorting () {
        return false;
    }

    public new int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        if (a is Iridium.Widgets.SidePanel.ChannelRow && b is Iridium.Widgets.SidePanel.ChannelRow) {
            var channel_a = a as Iridium.Widgets.SidePanel.ChannelRow;
            var channel_b = b as Iridium.Widgets.SidePanel.ChannelRow;
            return channel_a.channel_name.ascii_casecmp (channel_b.channel_name);
        } else if (a is Iridium.Widgets.SidePanel.ChannelRow && b is Iridium.Widgets.SidePanel.PrivateMessageRow) {
            return -1;
        } else if (a is Iridium.Widgets.SidePanel.PrivateMessageRow && b is Iridium.Widgets.SidePanel.ChannelRow) {
            return 1;
        } else if (a is Iridium.Widgets.SidePanel.PrivateMessageRow && b is Iridium.Widgets.SidePanel.PrivateMessageRow) {
            var pm_a = a as Iridium.Widgets.SidePanel.PrivateMessageRow;
            var pm_b = b as Iridium.Widgets.SidePanel.PrivateMessageRow;
            return pm_a.username.ascii_casecmp (pm_b.username);
        } else {
            // TODO: Log this undefined behavior that should never happen
            return 0;
        }
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
        //  icon = new GLib.ThemedIcon ("user-available");
        icon = new GLib.ThemedIcon ("network-server");
        markup = null;
        is_enabled = true;
    }

    public new void disable () {
        if (!is_enabled) {
            return;
        }
        //  icon = new GLib.ThemedIcon ("user-offline");
        markup = "<i>" + server_name + "</i>";
        is_enabled = false;
    }

    public new void updating () {
        //  icon = new GLib.ThemedIcon ("mail-unread");
        icon = new GLib.ThemedIcon (Constants.APP_ID + ".image-loading-symbolic");
        markup = "<i>" + server_name + "</i>";
        is_enabled = false;
    }

    public new bool get_enabled () {
        return is_enabled;
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var join_item = new Gtk.MenuItem.with_label (_("Join a Channel..."));
        join_item.activate.connect (() => {
            join_channel ();
        });

        var connect_item = new Gtk.MenuItem.with_label (_("Connect"));
        connect_item.activate.connect (() => {
            connect_to_server ();
        });

        var disconnect_item = new Gtk.MenuItem.with_label (_("Disconnect"));
        disconnect_item.activate.connect (() => {
            disconnect_from_server ();
        });

        var close_item = new Gtk.MenuItem.with_label (_("Close"));
        close_item.activate.connect (() => {
            if (is_enabled) {
                disconnect_from_server ();
            }
            remove_server ();
        });

        if (is_enabled) {
            menu.append (join_item);
            menu.append (new Gtk.SeparatorMenuItem ());
            menu.append (disconnect_item);
        } else {
            menu.append (connect_item);
        }
        menu.append (close_item);

        menu.show_all ();

        return menu;
    }

    public signal void join_channel ();
    public signal void disconnect_from_server ();
    public signal void connect_to_server ();
    public signal void remove_server ();

}
