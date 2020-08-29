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
    public string? network_name { get; set; }
    public Iridium.Widgets.SidePanel.Row.State state { get; set; }

    public unowned Iridium.MainWindow window { get; construct; }

    private string? error_message = null;
    private string? error_details = null;

    public ServerRow (string server_name, Iridium.MainWindow window, string? network_name) {
        Object (
            name: network_name == null ? server_name : network_name,
            network_name: network_name,
            server_name: server_name,
            window: window,
            icon: new GLib.ThemedIcon ("user-available"),
            state: Iridium.Widgets.SidePanel.Row.State.DISABLED
        );
    }

    construct {
        action_activated.connect (() => {
            if (error_message != null) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    activatable_tooltip,
                    error_details == null ? "" : error_details,
                    "network-server",
                    Gtk.ButtonsType.CANCEL
                );
                message_dialog.badge_icon = new ThemedIcon ("dialog-error");
                message_dialog.transient_for = window;

                var suggested_button = new Gtk.Button.with_label (_("Dismiss"));
                suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();
                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    activatable = null;
                    activatable_tooltip = null;
                    error_message = null;
                    error_details = null;
                };
                message_dialog.destroy ();
            }
        });
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
        //  if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
        //      return;
        //  }
        icon = new GLib.ThemedIcon ("user-available");
        //  icon = new GLib.ThemedIcon ("network-server");
        markup = null;

        clear_error ();

        state = Iridium.Widgets.SidePanel.Row.State.ENABLED;
    }

    public new void disable () {
        icon = new GLib.ThemedIcon ("user-offline");
        //  icon = new GLib.ThemedIcon ("network-server");
        markup = "<i>" + (network_name == null ? server_name : network_name) + "</i>";

        clear_error ();

        state = Iridium.Widgets.SidePanel.Row.State.DISABLED;
    }

    public new void error (string error_message, string? error_details) {
        //  icon = new GLib.ThemedIcon ("dialog-error");
        //  markup = "<i>" + server_name + "</i>";

        activatable = new GLib.ThemedIcon ("dialog-error");
        activatable_tooltip = error_message;
        this.error_message = error_message;
        this.error_details = error_details;
    }

    public new void updating () {
        icon = new GLib.ThemedIcon ("mail-unread");
        //  icon = new GLib.ThemedIcon (Constants.APP_ID + ".image-loading-symbolic");
        markup = "<i>" + (network_name == null ? server_name : network_name) + "</i>";

        clear_error ();

        state = Iridium.Widgets.SidePanel.Row.State.UPDATING;
    }

    public new bool get_enabled () {
        return state == Iridium.Widgets.SidePanel.Row.State.ENABLED;
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var join_item = new Gtk.MenuItem.with_label (_("Join a Channel…"));
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
            if (get_enabled ()) {
                disconnect_from_server ();
            }
            remove_server ();
        });

        if (get_enabled ()) {
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

    public void update_network_name (string network_name) {
        this.network_name = network_name;
        this.name = network_name;
    }

    private void clear_error () {
        activatable = null;
        activatable_tooltip = null;
        error_message = null;
        error_details = null;
    }

    public signal void join_channel ();
    public signal void disconnect_from_server ();
    public signal void connect_to_server ();
    public signal void remove_server ();

}
