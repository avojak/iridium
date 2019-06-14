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
            others_dummy.visible = false;
        });
        others_category.child_removed.connect ((item) => {
            if (others_category.n_children == 1) {
                others_category.expanded = false;
                others_dummy.visible = true;
            }
        });

        root.add (favorites_category);
        root.add (others_category);

        server_items = new Gee.HashMap<string, Granite.Widgets.SourceList.ExpandableItem> ();

        // Reset the badge when an item is selected
        item_selected.connect ((item) => {
            item.badge = "";
        });
    }

    public void add_server (string server_name) {
        // Check if this server row already exists
        if (server_items.has_key (server_name)) {
            return;
        }

        var server_item = new Iridium.Widgets.SidePanel.ServerRow (server_name);
        // Disconnect from the server
        server_item.disconnect_from_server.connect ((should_close) => {
            disconnect_from_server (server_name);
        });
        // Remove the server item and its associated channel items
        server_item.remove_server.connect (() => {
            remove_server (server_item, server_name);
        });
        server_items.set (server_name, server_item);
        others_category.add (server_item);

        /* selected = server_item; */

        server_row_added (server_name);
    }

    private void remove_server (Iridium.Widgets.SidePanel.ServerRow server_item, string server_name) {
        others_category.remove (server_item);
        server_items.unset (server_name);

        // If there aren't anymore servers to show, set selected to null
        if (server_items.is_empty) {
            selected = null;
        }

        server_row_removed (server_name);
    }

    public void add_channel (string server_name, string channel_name) {
        // Check if this channel row already exists
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            unowned Iridium.Widgets.SidePanel.ChannelRow channel_item = (Iridium.Widgets.SidePanel.ChannelRow) child;
            if (channel_item.channel_name == channel_name) {
                return;
            }
        }

        var channel_item = new Iridium.Widgets.SidePanel.ChannelRow (channel_name, server_name);
        /* channel_item.markup = "#irchacks <small>" + channel_name + "</small>"; */
        channel_item.leave_channel.connect (() => {
            leave_channel (server_name, channel_name);
            channel_item.disable ();
        });
        channel_item.remove_channel.connect (() => {
            remove_channel (server_name, channel_name);
        });

        server_item.add (channel_item);
        server_item.expanded = true;

        /* selected = channel_item; */
        channel_row_added (server_name, channel_name);
    }

    public void remove_channel (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        foreach (var channel_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) channel_item;
            if (row.get_channel_name () == channel_name) {
                server_item.remove (channel_item);
                break;
            }
        }
        channel_row_removed (server_name, channel_name);
    }

    // TODO: Lots of refactoring can be done here. Lots of code is shared
    //       with the channel functions!
    public void add_direct_message (string server_name, string username) {
        // Check if this direct message row already exists
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            if (child is Iridium.Widgets.SidePanel.DirectMessageRow) {
                unowned Iridium.Widgets.SidePanel.DirectMessageRow direct_message_item = (Iridium.Widgets.SidePanel.DirectMessageRow) child;
                if (direct_message_item.username == username) {
                    return;
                }
            }
        }

        var direct_message_item = new Iridium.Widgets.SidePanel.DirectMessageRow (username, server_name);
        /* direct_message_item.markup = "#irchacks <small>" + username + "</small>"; */
        direct_message_item.close_direct_message.connect (() => {
            remove_direct_message (server_name, username);
        });

        server_item.add (direct_message_item);
        server_item.expanded = true;

        // TODO: Automatically showing a PM when it's received was kinda annoying, 
        //       but maybe not to everyone will feel that way. Maybe instead show
        //       some indication/styling in the side panel to show that the PM is new?
        //  selected = direct_message_item;
    }

    private void remove_direct_message (string server_name, string username) {
        var server_item = server_items.get (server_name);
        foreach (var direct_message_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) direct_message_item;
            if (row.get_channel_name () == username) {
                server_item.remove (direct_message_item);
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

    public void enable_server_row (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) server_item;
        row.enable ();
        server_row_enabled (server_name);
    }

    public void disable_server_row (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        unowned Iridium.Widgets.SidePanel.Row server_row = (Iridium.Widgets.SidePanel.Row) server_item;
        server_row.disable ();
        // Disable all of the children
        foreach (var channel_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row channel_row = (Iridium.Widgets.SidePanel.Row) channel_item;
            channel_row.disable ();
        }
        server_row_disabled (server_name);
    }

    public void enable_channel_row (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) channel_item;
            if (row.get_channel_name () == channel_name) {
                row.enable ();
                break;
            }
        }
        channel_row_enabled (server_name, channel_name);
    }

    public void disable_channel_row (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) channel_item;
            if (row.get_channel_name () == channel_name) {
                row.disable ();
                break;
            }
        }
        channel_row_disabled (server_name, channel_name);
    }

    public void select_server_row (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        selected = server_item;
    }

    public void select_channel_row (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) channel_item;
            if (row.get_channel_name () == channel_name) {
                selected = channel_item;
                return;
            }
        }
    }

    public void increment_server_badge (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        // Don't increment if the item is currently selected
        if (selected == server_item) {
            return;
        }
        var current_count = int.parse (server_item.badge);
        server_item.badge = (current_count + 1).to_string ();
    }

    public void increment_channel_badge (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        // TODO: Refactor out the 'channel row finding' logic
        foreach (var channel_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) channel_item;
            if (row.get_channel_name () == channel_name) {
                // Don't increment if the item is currently selected
                if (selected == channel_item) {
                    return;
                }
                var current_count = int.parse (channel_item.badge);
                channel_item.badge = (current_count + 1).to_string ();
                break;
            }
        }
    }

    public signal void leave_channel (string server_name, string channel_name);
    public signal void disconnect_from_server(string server_name);

    public signal void server_row_added (string server_name);
    public signal void server_row_removed (string server_name);
    public signal void server_row_enabled (string server_name);
    public signal void server_row_disabled (string server_name);
    public signal void channel_row_added (string server_name, string channel_name);
    public signal void channel_row_removed (string server_name, string channel_name);
    public signal void channel_row_enabled (string server_name, string channel_name);
    public signal void channel_row_disabled (string server_name, string channel_name);
    public signal void dm_row_added (string server_name, string username);
    public signal void dm_row_removed (string server_name, string username);
    public signal void dm_row_enabled (string server_name, string username);
    public signal void dm_row_disabled (string server_name, string username);

}
