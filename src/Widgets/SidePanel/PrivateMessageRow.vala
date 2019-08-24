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

public class Iridium.Widgets.SidePanel.PrivateMessageRow : Granite.Widgets.SourceList.ExpandableItem, Iridium.Widgets.SidePanel.Row {

    public string username { get; construct; }
    public string server_name { get; construct; }

    private bool is_enabled = true;

    public PrivateMessageRow (string username, string server_name) {
        Object (
            name: username,
            username: username,
            server_name: server_name
        );
    }

    construct {
        //  icon = new GLib.ThemedIcon ("user-available");
        icon = new GLib.ThemedIcon ("system-users");
    }

    public new string get_server_name () {
        return server_name;
    }

    public new string? get_channel_name () {
        return username;
    }

    public new void enable () {
        if (is_enabled) {
            return;
        }
        //  icon = new GLib.ThemedIcon ("user-available");
        icon = new GLib.ThemedIcon ("system-users");
        markup = null;
        is_enabled = true;
    }

    public new void disable () {
        if (!is_enabled) {
            return;
        }
        //  icon = new GLib.ThemedIcon ("user-offline");
        markup = "<i>" + username + "</i>";
        is_enabled = false;
    }

    public new void updating () {
        //  icon = new GLib.ThemedIcon ("mail-unread");
        icon = new GLib.ThemedIcon (Constants.APP_ID + ".image-loading-symbolic");
        markup = "<i>" + username + "</i>";
        is_enabled = false;
    }

    public new bool get_enabled () {
        return is_enabled;
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var close_item = new Gtk.MenuItem.with_label ("Close");
        close_item.activate.connect (() => {
            close_private_message ();
        });

        menu.append (close_item);
        menu.show_all ();

        return menu;
    }

    public signal void close_private_message ();

}
