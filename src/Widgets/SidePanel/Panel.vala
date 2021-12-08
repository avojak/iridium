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

public class Iridium.Widgets.SidePanel.Panel : Gtk.Grid {

    // TODO: Look into custom implementation of SourceList to add CellRendererSpinner as an option for
    //       the row items. Might allow us to display a spinner while connecting to a server or joining
    //       a channel.

    private const int NUM_SPINNER_IMAGES = 12;

    private Granite.Widgets.SourceList source_list;
    public Iridium.Widgets.StatusBar status_bar;

    private Granite.Widgets.SourceList.ExpandableItem favorites_category;
    private Granite.Widgets.SourceList.ExpandableItem servers_category;

    private Granite.Widgets.SourceList.Item favorites_dummy;
    private Granite.Widgets.SourceList.Item servers_dummy;

    private Gee.Map<string, Granite.Widgets.SourceList.ExpandableItem> server_items;

    // TODO: May need to use this list as the source of truth once items start moving around for favorites
    private Gee.Map<string, Gee.List<Iridium.Widgets.SidePanel.ChannelRow>> channel_items;
    private Gee.Map<string, Gee.List<Iridium.Widgets.SidePanel.PrivateMessageRow>> private_message_items;

    private Thread<void> spinner_thread;
    private Cancellable spinner_cancellable = new Cancellable ();
    private Gee.Map<int, GLib.ThemedIcon> spinner_images;

    public unowned Iridium.MainWindow window { get; construct; }

    public Panel (Iridium.MainWindow window) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            window: window
        );
    }

    construct {
        source_list = new Granite.Widgets.SourceList ();
        status_bar = new Iridium.Widgets.StatusBar ();

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

        source_list.root.add (favorites_category);
        source_list.root.add (servers_category);

        server_items = new Gee.HashMap<string, Granite.Widgets.SourceList.ExpandableItem> ();
        channel_items = new Gee.HashMap<string, Gee.List<Iridium.Widgets.SidePanel.ChannelRow>> ();
        private_message_items = new Gee.HashMap<string, Gee.List<Iridium.Widgets.SidePanel.PrivateMessageRow>> ();

        // Reset the badge when an item is selected
        source_list.item_selected.connect ((item) => {
            if (item != null) {
                item.badge = "";
            }
            item_selected (item);
        });

        attach (source_list, 0, 0);
        attach (status_bar, 0, 1);

        spinner_images = new Gee.HashMap<int, GLib.ThemedIcon> ();
        for (int i = 0; i < NUM_SPINNER_IMAGES; i++) {
            spinner_images.set (i, new GLib.ThemedIcon ("%s.process-working-%d-symbolic".printf (Constants.APP_ID, i + 1)));
        }
        spinner_thread = new Thread<void> (@"Side panel spinner", do_spin);

        this.destroy.connect (() => {
            spinner_cancellable.cancel ();
        });
    }

    private void do_spin () {
        int image_index = 0;
        while (!spinner_cancellable.is_cancelled ()) {
            foreach (var server_entry in server_items.entries) {
                var server_row = (Iridium.Widgets.SidePanel.Row) server_entry.value;
                if (server_row.get_state () == Iridium.Widgets.SidePanel.Row.State.UPDATING) {
                    Idle.add (() => {
                        ((Granite.Widgets.SourceList.Item) server_entry.value).icon = spinner_images.get(image_index);
                        return false;
                    });
                }
                foreach (var channel_item in channel_items.get (server_entry.key)) {
                    var channel_row = (Iridium.Widgets.SidePanel.Row) channel_item;
                    if (channel_row.get_state () == Iridium.Widgets.SidePanel.Row.State.UPDATING) {
                        Idle.add (() => {
                            ((Granite.Widgets.SourceList.Item) channel_item).icon = spinner_images.get(image_index);
                            return false;
                        });
                    }
                }
            }
            image_index++;
            if (image_index == NUM_SPINNER_IMAGES) {
                image_index = 0;
            }
            GLib.Thread.usleep (50000);
        }
    }

    public void add_server_row (string server_name, string? network_name) {
        // Check if this server row already exists
        if (server_items.has_key (server_name)) {
            return;
        }

        var server_item = new Iridium.Widgets.SidePanel.ServerRow (server_name, window, network_name);
        server_item.join_channel.connect (() => {
            join_channel (server_name, null);
        });
        server_item.edit_connection.connect (() => {
            edit_connection (server_name);
        });
        server_item.disconnect_from_server.connect ((should_close) => {
            disconnect_from_server (server_name);
        });
        server_item.connect_to_server.connect (() => {
            connect_to_server (server_name);
        });
        server_item.remove_server.connect (() => {
            remove_server_row (server_item, server_name);
        });
        server_items.set (server_name, server_item);
        channel_items.set (server_name, new Gee.ArrayList<Iridium.Widgets.SidePanel.ChannelRow> ());
        private_message_items.set (server_name, new Gee.ArrayList<Iridium.Widgets.SidePanel.PrivateMessageRow> ());
        servers_category.add (server_item);

        /* selected = server_item; */

        server_row_added (server_name);
    }

    private void remove_server_row (Iridium.Widgets.SidePanel.ServerRow server_item, string server_name) {
        servers_category.remove (server_item);

        foreach (var channel_item in channel_items.get (server_name)) {
            if (channel_item.get_server_name () == server_name) {
                favorites_category.remove (channel_item);
            }
        }

        server_items.unset (server_name);
        channel_items.unset (server_name);
        private_message_items.unset (server_name);

        // If there aren't anymore servers to show, set selected to null
        if (server_items.is_empty) {
            source_list.selected = null;
        }

        server_row_removed (server_name);
    }

    public void add_channel_row (string server_name, string channel_name) {
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
            remove_channel_row (server_name, channel_name);
        });

        var server_item = server_items.get (server_name);
        server_item.add (channel_item);
        server_item.expanded = true;
        channel_items.get (server_name).add (channel_item);

        string? network_name = ((Iridium.Widgets.SidePanel.ServerRow) server_item).network_name;
        if (network_name != null) {
            channel_item.update_network_name (network_name);
        }

        /* selected = channel_item; */
        channel_row_added (server_name, channel_name);
    }

    public void favorite_channel (string server_name, string channel_name) {
        foreach (var channel_item in channel_items.get (server_name)) {
            if (channel_item.get_channel_name () == channel_name) {
                bool preserve_focus = source_list.selected == channel_item;
                var server_item = server_items.get (server_name);
                server_item.remove (channel_item);
                favorites_category.add (channel_item);
                channel_item.set_favorite (true);
                // We've favorited the item that's currently selected, so we want to maintain focus
                if (preserve_focus) {
                    // XXX: This is a little hacky, and causes another view to become briefly available
                    //      during the transition. I'm not sure of a better way to do this currently.
                    select_channel_row (server_name, channel_name);
                }
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

    public void remove_channel_row (string server_name, string channel_name) {
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
                    // If we've just removed the only favorited channel, select its server
                    if (favorites_category.n_children == 1) {
                        source_list.selected = server_item;
                    }
                    // If we've just removed the last item (not the only item) in the list, we 
                    // need to manually select the new last item because the source list does 
                    // not automatically select another item in this case
                    if (favorites_category.n_children > 1) {
                        source_list.selected = favorites_category.children.to_array ()[favorites_category.n_children - 1];
                    }
                    break;
                }
            }
        }
        channel_row_removed (server_name, channel_name);
    }

    // TODO: Lots of refactoring can be done here. Lots of code is shared
    //       with the channel functions!
    public void add_private_message_row (string server_name, string nickname) {
        // Check if this private message row already exists
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            if (child is Iridium.Widgets.SidePanel.PrivateMessageRow) {
                unowned Iridium.Widgets.SidePanel.PrivateMessageRow private_message_item = (Iridium.Widgets.SidePanel.PrivateMessageRow) child;
                if (private_message_item.nickname == nickname) {
                    return;
                }
            }
        }

        var private_message_item = new Iridium.Widgets.SidePanel.PrivateMessageRow (nickname, server_name);
        private_message_item.close_private_message.connect (() => {
            remove_private_message_row (server_name, private_message_item.get_channel_name ());
        });

        server_item.add (private_message_item);
        server_item.expanded = true;
        private_message_items.get (server_name).add (private_message_item);
    }

    private void remove_private_message_row (string server_name, string nickname) {
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            if (child is Iridium.Widgets.SidePanel.PrivateMessageRow) {
                unowned Iridium.Widgets.SidePanel.PrivateMessageRow private_message_row = (Iridium.Widgets.SidePanel.PrivateMessageRow) child;
                if (private_message_row.get_channel_name () == nickname) {
                    server_item.remove (child);
                    private_message_items.get (server_name).remove (private_message_row);
                    return;
                }
            }
        }
    }

    public string? get_current_server () {
        if (source_list.selected == null) {
            return null;
        }
        // Don't consider the dummy rows
        if (source_list.selected.name == "") {
            return null;
        }
        // TODO: This feels wrong…
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) source_list.selected;
        return row.get_server_name ();
    }

    public void enable_server_row (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) server_item;
        row.enable ();
        // Private message rows are directly tied to the server row
        foreach (var private_message_row in private_message_items.get (server_name)) {
            private_message_row.enable ();
        }
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
        foreach (var private_message_row in private_message_items.get (server_name)) {
            private_message_row.disable ();
        }
        server_row_disabled (server_name);
    }

    public void error_server_row (string server_name, string error_message, string? error_details) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        unowned Iridium.Widgets.SidePanel.Row server_row = (Iridium.Widgets.SidePanel.Row) server_item;
        server_row.error (error_message, error_details);
    }

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
        source_list.selected = server_item;
    }

    public void select_channel_row (string server_name, string channel_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_row in channel_items.get (server_name)) {
            if (channel_row.get_channel_name () == channel_name) {
                source_list.selected = channel_row;
                return;
            }
        }
    }

    public void select_private_message_row (string server_name, string nickname) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        foreach (var channel_item in server_item.children) {
            // TODO: Apply this type check in other places
            if (channel_item is Iridium.Widgets.SidePanel.PrivateMessageRow) {
                unowned Iridium.Widgets.SidePanel.PrivateMessageRow row = (Iridium.Widgets.SidePanel.PrivateMessageRow) channel_item;
                if (row.get_channel_name () == nickname) {
                    source_list.selected = channel_item;
                    return;
                }
            }
        }
    }

    public Iridium.Widgets.SidePanel.Row? get_selected_row () {
        if (source_list.selected == null) {
            return null;
        }
        // Don't consider the dummy rows
        if (source_list.selected.name == "") {
            return null;
        }
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) source_list.selected;
        return row;
    }

    public void increment_server_badge (string server_name) {
        var server_item = server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        // Don't increment if the item is currently selected
        if (source_list.selected == server_item) {
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
                if (source_list.selected == channel_row) {
                    return;
                }
                var current_count = int.parse (channel_row.badge);
                channel_row.badge = (current_count + 1).to_string ();
                return;
            }
        }
        foreach (var private_message_row in private_message_items.get (server_name)) {
            if (private_message_row.get_channel_name () == channel_name) {
                // Don't increment if the item is currently selected
                if (source_list.selected == private_message_row) {
                    return;
                }
                var current_count = int.parse (private_message_row.badge);
                private_message_row.badge = (current_count + 1).to_string ();
                return;
            }
        }
        warning ("No row found for server %s and channel/user %s", server_name, channel_name);
    }

    public void update_nickname (string server_name, string old_nickname, string new_nickname) {
        var server_item = server_items.get (server_name);
        foreach (var child in server_item.children) {
            if (child is Iridium.Widgets.SidePanel.PrivateMessageRow) {
                unowned Iridium.Widgets.SidePanel.PrivateMessageRow private_message_item = (Iridium.Widgets.SidePanel.PrivateMessageRow) child;
                if (private_message_item.nickname == old_nickname) {
                    private_message_item.update_nickname (new_nickname);
                }
            }
        }
    }

    public void update_network_name (string server_name, string network_name) {
        // Update the server item
        Iridium.Widgets.SidePanel.ServerRow? server_item = (Iridium.Widgets.SidePanel.ServerRow) server_items.get (server_name);
        if (server_item == null) {
            return;
        }
        server_item.update_network_name (network_name);

        // Update the channel items
        foreach (var channel_row in channel_items.get (server_name)) {
            if (channel_row.get_server_name () == server_name) {
                channel_row.update_network_name (network_name);
            }
        }
        foreach (var child in favorites_category.children) {
            if (child is Iridium.Widgets.SidePanel.ChannelRow) {
                unowned Iridium.Widgets.SidePanel.ChannelRow channel_row = (Iridium.Widgets.SidePanel.ChannelRow) child;
                if (channel_row.get_server_name () == server_name) {
                    channel_row.update_network_name (network_name);
                }
            }
        }
    }

    //  public void display_server_error (string server_name, string error_message) {
    //      Iridium.Widgets.SidePanel.ServerRow? server_item = (Iridium.Widgets.SidePanel.ServerRow) server_items.get (server_name);
    //      if (server_item == null) {
    //          return;
    //      }
    //      server_item.error ();
    //  }

    public signal void item_selected (Granite.Widgets.SourceList.Item item);

    public signal void join_channel (string server_name, string? channel_name);
    public signal void leave_channel (string server_name, string channel_name);
    public signal void channel_favorite_added (string server_name, string channel_name);
    public signal void channel_favorite_removed (string server_name, string channel_name);
    public signal void connect_to_server (string server_name);
    public signal void disconnect_from_server (string server_name);
    public signal void edit_channel_topic (string server_name, string channel_name);
    public signal void edit_connection (string server_name);

    public signal void server_row_added (string server_name);
    public signal void server_row_removed (string server_name);
    public signal void server_row_enabled (string server_name);
    public signal void server_row_disabled (string server_name);
    public signal void channel_row_added (string server_name, string channel_name);
    public signal void channel_row_removed (string server_name, string channel_name);
    public signal void channel_row_enabled (string server_name, string channel_name);
    public signal void channel_row_disabled (string server_name, string channel_name);
    public signal void private_message_row_added (string server_name, string nickname);
    public signal void private_message_row_removed (string server_name, string nickname);
    public signal void private_message_row_enabled (string server_name, string nickname);
    public signal void private_message_row_disabled (string server_name, string nickname);

}
