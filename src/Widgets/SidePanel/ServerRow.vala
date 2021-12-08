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

    private Iridium.Widgets.SidePanel.Row.State _state;

    public string server_name { get; construct; }
    public string? network_name { get; set; }

    public Iridium.Widgets.SidePanel.Row.State state {
        get {
            lock (_state) {
                return _state;
            }
        }
        set {
            lock (_state) {
                _state = value;
            }
        }
    }

    public unowned Iridium.MainWindow window { get; construct; }

    public ServerRow (string server_name, Iridium.MainWindow window, string? network_name) {
        Object (
            name: network_name == null ? server_name : network_name,
            network_name: network_name,
            server_name: server_name,
            window: window,
            icon: new GLib.ThemedIcon (Constants.APP_ID + ".network-server-disconnected"),
            state: Iridium.Widgets.SidePanel.Row.State.DISABLED
        );
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
            return pm_a.nickname.ascii_casecmp (pm_b.nickname);
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
        state = Iridium.Widgets.SidePanel.Row.State.ENABLED;
        update_icon (Constants.APP_ID + ".network-server-connected");
        markup = null;
    }

    public new void disable () {
        state = Iridium.Widgets.SidePanel.Row.State.DISABLED;
        update_icon (Constants.APP_ID + ".network-server-disconnected");
        markup = "<i>" + (network_name == null ? server_name : network_name) + "</i>";
    }

    public new void error (string error_message, string? error_details) {
        state = Iridium.Widgets.SidePanel.Row.State.ERROR;
        update_icon (Constants.APP_ID + ".network-server-error");
    }

    public new void updating () {
        state = Iridium.Widgets.SidePanel.Row.State.UPDATING;
        markup = "<i>" + (network_name == null ? server_name : network_name) + "</i>";
    }

    public new bool get_enabled () {
        return state == Iridium.Widgets.SidePanel.Row.State.ENABLED;
    }

    public new Iridium.Widgets.SidePanel.Row.State get_state () {
        return state;
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var join_item = new Gtk.MenuItem.with_label (_("Join a Channel…"));
        join_item.activate.connect (() => {
            join_channel ();
        });

        var edit_connection_item = new Gtk.MenuItem.with_label (_("Edit Connection…"));
        edit_connection_item.activate.connect (() => {
            edit_connection ();
        });

        var connect_item = new Gtk.MenuItem.with_label (_("Connect"));
        connect_item.activate.connect (() => {
            connect_to_server ();
        });

        var disconnect_item = new Gtk.MenuItem.with_label (_("Disconnect"));
        disconnect_item.activate.connect (() => {
            disconnect_from_server ();
        });

        var remove_item = new Gtk.MenuItem.with_label (_("Remove"));
        remove_item.activate.connect (() => {
            if (warn_before_remove ()) {
                if (get_enabled ()) {
                    disconnect_from_server ();
                }
                remove_server ();
            }
        });

        if (get_enabled ()) {
            menu.append (join_item);
            menu.append (new Gtk.SeparatorMenuItem ());
            menu.append (disconnect_item);
        } else {
            menu.append (connect_item);
        }
        menu.append (edit_connection_item);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (remove_item);

        menu.show_all ();

        return menu;
    }

    private bool warn_before_remove () {
        // First check the settings to see if the user has already opted to not be warned
        if (Iridium.Application.settings.get_boolean ("suppress-connection-close-warnings")) {
            return true;
        }

        bool should_close = false;
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Are you sure you want to proceed?"),
            _("By removing this connection you will be disconnected, and will not be able to recover the connection settings. If you wish to join this server again in the future, you will need to re-enter the connection settings."),
            "dialog-warning",
            Gtk.ButtonsType.CANCEL);
        message_dialog.transient_for = window;

        var suggested_button = new Gtk.Button.with_label (_("Yes, remove"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        var remember_decision_button = new Gtk.CheckButton.with_label (_("Don't warn me again"));
        message_dialog.custom_bin.add (remember_decision_button);

        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            Iridium.Application.settings.set_boolean ("suppress-connection-close-warnings", remember_decision_button.get_active ());
            should_close = true;
        };
        message_dialog.destroy ();
        return should_close;
    }

    public void update_network_name (string network_name) {
        this.network_name = network_name;
        this.name = network_name;
    }

    private void update_icon (string icon_name) {
        Idle.add (() => {
            icon = new GLib.ThemedIcon (icon_name);
            return false;
        });
    }

    public signal void join_channel ();
    public signal void edit_connection ();
    public signal void disconnect_from_server ();
    public signal void connect_to_server ();
    public signal void remove_server ();

}
