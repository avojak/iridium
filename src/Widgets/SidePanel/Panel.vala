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

    // TODO: Look into custom implementation of SourceList to add CellRendererSpinner as an option for
    //       the row items. Might allow us to display a spinner while connecting to a server or joining
    //       a channel.

    private Granite.Widgets.SourceList.ExpandableItem favorites_category;
    private Granite.Widgets.SourceList.ExpandableItem servers_category;

    private Granite.Widgets.SourceList.Item favorites_dummy;
    private Granite.Widgets.SourceList.Item servers_dummy;

    private Gee.Map<string, Granite.Widgets.SourceList.ExpandableItem> server_items;

    // TODO: May need to use this list as the source of truth once items start moving around for favorites
    private Gee.Map<string, Gee.List<Iridium.Widgets.SidePanel.ChannelRow>> channel_items;

    public Panel () {
        // TODO: Refactor these ExpandableItems to be a subclass that implements the sortable interface
        //       so that we can sort servers and favorite channels.
        favorites_category = new Granite.Widgets.SourceList.ExpandableItem (_("Favorite Channels"));
        favorites_dummy = new Granite.Widgets.SourceList.Item ("");
        favorites_dummy.selectable = false;
        favorites_category.add (favorites_dummy);
        favorites_category.child_added.connect ((item) => {
            favorites_category.expanded = true;
            favorites_dummy.visible = false;
        });
        favorites_category.child_removed.connect ((item) => {
            if (favorites_category.n_children == 1) {
                favorites_category.expanded = false;
                favorites_dummy.visible = true;
            }
        });

        servers_category = new Granite.Widgets.SourceList.ExpandableItem (_("Servers"));
        servers_dummy = new Granite.Widgets.SourceList.Item ("");
        servers_dummy.selectable = false;
        servers_category.add (servers_dummy);
        servers_category.child_added.connect ((item) => {
            servers_category.expanded = true;
            servers_dummy.visible = false;
        });
        servers_category.child_removed.connect ((item) => {
            if (servers_category.n_children == 1) {
                servers_category.expanded = false;
                servers_dummy.visible = true;
            }
        });

        root.add (favorites_category);
        root.add (servers_category);

        server_items = new Gee.HashMap<string, Granite.Widgets.SourceList.ExpandableItem> ();
        channel_items = new Gee.HashMap<string, Gee.List<Iridium.Widgets.SidePanel.ChannelRow>> ();

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
        server_item.join_channel.connect (() => {
            join_channel_for_server (server_name);
        });
        server_item.disconnect_from_server.connect ((should_close) => {
            disconnect_from_server (server_name);
        });
        server_item.connect_to_server.connect (() => {
            connect_to_server (server_name);
        });
        server_item.remove_server.connect (() => {
            remove_server (server_item, server_name);
        });
        server_items.set (server_name, server_item);
        channel_items.set (server_name, new Gee.ArrayList<Iridium.Widgets.SidePanel.ChannelRow> ());
        servers_category.add (server_item);

        /* selected = server_item; */

        server_row_added (server_name);
    }

    private void remove_server (Iridium.Widgets.SidePanel.ServerRow server_item, string server_name) {
        servers_category.remove (server_item);

        foreach (var channel_item in channel_items.get (server_name)) {
            if (channel_item.get_server_name () == server_name) {
                favorites_category.remove (channel_item);
            }
        }

        server_items.unset (server_name);
        channel_items.unset (server_name);

        // If there aren't anymore servers to show, set selected to null
        if (server_items.is_empty) {
            selected = null;
        }

        server_row_removed (server_name);
    }

    public void add_channel (string server_name, string channel_name) {
        // Check if this channel row already exists
        foreach (var channel_item in channel_items.get (server_name)) {
            if (channel_item.channel_name == channel_name) {
                return;
            }
        }

        var channel_item = new Iridium.Widgets.SidePanel.ChannelRow (channel_name, server_name);
        channel_item.edit_topic.connect (() => {
            edit_channel_topic (server_name, channel_name);
        });
        channel_item.favorite_channel.connect (() => {
            favorite_channel (server_name, channel_name);
        });
        channel_item.remove_favorite_channel.connect (() => {
            remove_favorite_channel (server_name, channel_name);
        });
        channel_item.join_channel.connect (() => {
            join_channel (server_name, channel_name);
        });
        channel_item.leave_channel.connect (() => {
            leave_channel (server_name, channel_name);
        });
        channel_item.remove_channel.connect (() => {
            remove_channel (server_name, channel_name);
        });

        var server_item = server_items.get (server_name);
        server_item.add (channel_item);
        server_item.expanded = true;
        channel_items.get (server_name).add (channel_item);

        /* selected = channel_item; */
        channel_row_added (server_name, channel_name);
    }

    public void favorite_channel (string server_name, string channel_name) {
        foreach (var channel_item in channel_items.get (server_name)) {
            if (channel_item.get_channel_name () == channel_name) {
                var server_item = server_items.get (server_name);
                server_item.remove (channel_item);
                favorites_category.add (channel_item);
                channel_item.set_favorite (true);
                break;
            }
        }
        channel_favorite_added (server_name, channel_name);
    }

    private void remove_favorite_channel (string server_name, string channel_name) {
        foreach (var channel_item in channel_items.get (server_name)) {
            if (channel_item.get_channel_name () == channel_name) {
                var server_item = server_items.get (server_name);
                favorites_category.remove (channel_item);
                server_item.add (channel_item);
                channel_item.set_favorite (false);
                break;
            }
        }
        channel_favorite_removed (server_name, channel_name);
    }

    public void remove_channel (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            if (child is Iridium.Widgets.SidePanel.ChannelRow) {
                unowned Iridium.Widgets.SidePanel.ChannelRow channel_row = (Iridium.Widgets.SidePanel.ChannelRow) child;
                if (channel_row.get_channel_name () == channel_name) {
                    server_item.remove (child);
                    channel_items.get (server_name).remove (channel_row);
                    break;
                }
            }
        }
        foreach (var child in favorites_category.children) {
            if (child is Iridium.Widgets.SidePanel.ChannelRow) {
                unowned Iridium.Widgets.SidePanel.ChannelRow channel_row = (Iridium.Widgets.SidePanel.ChannelRow) child;
                if (channel_row.get_server_name () == server_name && channel_row.get_channel_name () == channel_name) {
                    favorites_category.remove (child);
                    channel_items.get (server_name).remove (channel_row);
                    break;
                }
            }
        }
        channel_row_removed (server_name, channel_name);
    }

    // TODO: Lots of refactoring can be done here. Lots of code is shared
    //       with the channel functions!
    public void add_private_message (string server_name, string username) {
        // Check if this private message row already exists
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            if (child is Iridium.Widgets.SidePanel.PrivateMessageRow) {
                unowned Iridium.Widgets.SidePanel.PrivateMessageRow private_message_item = (Iridium.Widgets.SidePanel.PrivateMessageRow) child;
                if (private_message_item.username == username) {
                    return;
                }
            }
        }

        var private_message_item = new Iridium.Widgets.SidePanel.PrivateMessageRow (username, server_name);
        private_message_item.close_private_message.connect (() => {
            remove_private_message (server_name, username);
        });

        server_item.add (private_message_item);
        server_item.expanded = true;

        // TODO: Automatically showing a PM when it's received was kinda annoying, 
        //       but maybe not to everyone will feel that way. Maybe instead show
        //       some indication/styling in the side panel to show that the PM is new?
        //  selected = private_message_item;
    }

    private void remove_private_message (string server_name, string username) {
        var server_item = server_items.get (server_name);
        foreach (var private_message_item in server_item.children) {
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) private_message_item;
            if (row.get_channel_name () == username) {
                server_item.remove (private_message_item);
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
        // TODO: This feels wrong…
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
        foreach (var channel_row in channel_items.get (server_name)) {
            channel_row.disable ();
        }
        server_row_disabled (server_name);
    }

    //  public void error_server_row (string server_name) {
    //      var server_item = server_items.get (server_name);
    //      if (server_item == null) {
    //          return;
    //      }
    //      unowned Iridium.Widgets.SidePanel.Row server_row = (Iridium.Widgets.SidePanel.Row) server_item;
    //      server_row.error ();
    //  }

    public void updating_server_row (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) server_item;
        row.updating ();
    }

    public void enable_channel_row (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_row in channel_items.get (server_name)) {
            if (channel_row.get_channel_name () == channel_name) {
                channel_row.enable ();
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
        foreach (var channel_row in channel_items.get (server_name)) {
            if (channel_row.get_channel_name () == channel_name) {
                channel_row.disable ();
                break;
            }
        }
        channel_row_disabled (server_name, channel_name);
    }

    public void updating_channel_row (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_row in channel_items.get (server_name)) {
            if (channel_row.get_channel_name () == channel_name) {
                channel_row.updating ();
                break;
            }
        }
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
        foreach (var channel_row in channel_items.get(server_name)) {
            if (channel_row.get_channel_name () == channel_name) {
                selected = channel_row;
                return;
            }
        }
    }

    public void select_private_message_row (string server_name, string username) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_item in server_item.children) {
            // TODO: Apply this type check in other places
            if (channel_item is Iridium.Widgets.SidePanel.PrivateMessageRow) {
                unowned Iridium.Widgets.SidePanel.PrivateMessageRow row = (Iridium.Widgets.SidePanel.PrivateMessageRow) channel_item;
                if (row.get_channel_name () == username) {
                    selected = channel_item;
                    return;
                }
            }
        }
    }

    public Iridium.Widgets.SidePanel.Row? get_selected_row () {
        if (selected == null) {
            return null;
        }
        // Don't consider the dummy rows
        if (selected.name == "") {
            return null;
        }
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) selected;
        return row;
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
        foreach (var channel_row in channel_items.get (server_name)) {
            if (channel_row.get_channel_name () == channel_name) {
                // Don't increment if the item is currently selected
                if (selected == channel_row) {
                    return;
                }
                var current_count = int.parse (channel_row.badge);
                channel_row.badge = (current_count + 1).to_string ();
                break;
            }
        }
    }

    public signal void join_channel_for_server (string server_name);
    public signal void join_channel (string server_name, string channel_name);
    public signal void leave_channel (string server_name, string channel_name);
    public signal void channel_favorite_added (string server_name, string channel_name);
    public signal void channel_favorite_removed (string server_name, string channel_name);
    public signal void connect_to_server (string server_name);
    public signal void disconnect_from_server (string server_name);
    public signal void edit_channel_topic (string server_name, string channel_name);

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
