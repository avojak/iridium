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

public class Iridium.Widgets.SidePanel.ChannelRow : Granite.Widgets.SourceList.Item, Iridium.Widgets.SidePanel.Row {

    public string server_name { get; construct; }

    private Gtk.Menu context_menu;

    public ChannelRow (string name, string server_name) {
        Object (
            name: name,
            server_name: server_name
        );
    }

    construct {
        context_menu = new Gtk.Menu ();

        var favorite_item = new Gtk.MenuItem.with_label ("Add to favorites");
        favorite_item.activate.connect (() => {

        });

        var leave_item = new Gtk.MenuItem.with_label ("Leave channel");
        leave_item.activate.connect (() => {
            leave_channel ();
        });

        context_menu.append (favorite_item);
        context_menu.append (new Gtk.SeparatorMenuItem ());
        context_menu.append (leave_item);

        context_menu.show_all ();
    }

    public new string get_server_name () {
        return server_name;
    }

    public new string? get_channel_name () {
        return name;
    }

    public override Gtk.Menu? get_context_menu () {
        return context_menu;
    }

    public signal void leave_channel ();

}
