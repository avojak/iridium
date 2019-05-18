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

public class Iridium.Widgets.SidePanel.Panel : Granite.Widgets.SourceList {

    private Granite.Widgets.SourceList.ExpandableItem favorites_category;
    private Granite.Widgets.SourceList.ExpandableItem others_category;

    private Granite.Widgets.SourceList.Item favorites_dummy;
    private Granite.Widgets.SourceList.Item others_dummy;

    private Gee.Map<string, Granite.Widgets.SourceList.ExpandableItem> server_items;

    public Panel () {
        favorites_category = new Granite.Widgets.SourceList.ExpandableItem ("Favorite Channels");
        favorites_dummy = new Granite.Widgets.SourceList.Item ("");
        favorites_category.add (favorites_dummy);
        favorites_category.child_added.connect ((item) => {
            favorites_category.expanded = true;
        });

        others_category = new Granite.Widgets.SourceList.ExpandableItem ("Servers");
        others_dummy = new Granite.Widgets.SourceList.Item ("");
        others_category.add (others_dummy);
        others_category.child_added.connect ((item) => {
            others_category.expanded = true;
        });

        root.add (favorites_category);
        root.add (others_category);

        server_items = new Gee.HashMap<string, Granite.Widgets.SourceList.ExpandableItem> ();
    }

    public void add_server (string name) {
        others_dummy.visible = false;
        var server_item = new Iridium.Widgets.SidePanel.ServerRow (name);
        server_items.set (name, server_item);
        others_category.add (server_item);

        selected = server_item;
    }

    public void add_channel (string server, string name) {
        var channel_item = new Iridium.Widgets.SidePanel.ChannelRow (name, server);
        /* channel_item.markup = "#irchacks <small>" + name + "</small>"; */
        channel_item.leave_channel.connect (() => {
            leave_channel (server, name);
        });

        var server_item = server_items.get (server);
        server_item.add (channel_item);
        server_item.expanded = true;

        selected = channel_item;
    }

    public void remove_channel (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        foreach (var channel_item in server_item.children) {
            if (channel_item.name == channel_name) {
                server_item.remove (channel_item);
                return;
            }
        }
    }

    public string? get_current_server () {
        if (selected == null) {
            return null;
        }
        // Don't consider the dummy rows
        if (selected.name == "") {
            return null;
        }
        // TODO: This feels wrong...
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) selected;
        return row.get_server_name ();
    }

    public signal void server_added ();
    public signal void leave_channel (string server_name, string channel_name);

}
