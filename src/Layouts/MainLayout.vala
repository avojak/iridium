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

public class Iridium.Layouts.MainLayout : Gtk.Paned {

    public weak Iridium.Views.Welcome welcome_view { get; construct; }
    public unowned Iridium.Widgets.SidePanel.Panel side_panel { get; construct; }
    public unowned Iridium.Widgets.StatusBar status_bar { get; construct; }

    private Gee.Map<string, Gee.Map<string, string>> nickname_mapping;

    private Gtk.Stack main_stack;

    public MainLayout (Iridium.Views.Welcome welcome_view, Iridium.Widgets.SidePanel.Panel side_panel, Iridium.Widgets.StatusBar status_bar) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            welcome_view: welcome_view,
            side_panel: side_panel,
            status_bar: status_bar
        );
    }

    construct {
        position = 240;

        main_stack = new Gtk.Stack ();
        main_stack.add_named (welcome_view, "welcome");

        var side_grid = new Gtk.Grid ();
        side_grid.orientation = Gtk.Orientation.VERTICAL;
        side_grid.add (side_panel);
        side_grid.add (status_bar);

        pack1 (side_grid, false, false);
        pack2 (main_stack, true, false);

        nickname_mapping = new Gee.HashMap<string, Gee.Map<string, string>> ();
    }

    public void add_server_chat_view (Iridium.Views.ServerChatView view, string server_name) {
        if (get_server_chat_view (server_name) != null) {
            return;
        }
        main_stack.add_named (view, server_name);
    }

    public void add_channel_chat_view (Iridium.Views.ChatView view, string server_name, string channel_name) {
        if (get_channel_chat_view (server_name, channel_name) != null) {
            return;
        }
        main_stack.add_named (view, server_name + ";" + channel_name);
    }

    public void add_private_message_chat_view (Iridium.Views.PrivateMessageChatView view, string server_name, string username) {
        if (get_private_message_chat_view (server_name, username) != null) {
            return;
        }
        if (!nickname_mapping.has_key (server_name)) {
            nickname_mapping.set (server_name, new Gee.HashMap<string, string> ());
        }
        var uuid = GLib.Uuid.string_random ();
        nickname_mapping.get (server_name).set (username, uuid);
        main_stack.add_named (view, uuid);
    }

    public void show_welcome_view () {
        main_stack.get_child_by_name ("welcome").show_all ();
        main_stack.set_visible_child_full ("welcome", Gtk.StackTransitionType.SLIDE_RIGHT);
    }

    public Iridium.Views.ChannelChatView? get_channel_chat_view (string server_name, string channel_name) {
        var name = server_name + ";" + channel_name;
        return main_stack.get_child_by_name (name) as Iridium.Views.ChannelChatView;
    }

    public Iridium.Views.ServerChatView? get_server_chat_view (string server_name) {
        return main_stack.get_child_by_name (server_name) as Iridium.Views.ServerChatView;
    }

    public Iridium.Views.PrivateMessageChatView? get_private_message_chat_view (string server_name, string username) {
        if (!nickname_mapping.has_key (server_name)) {
            return null;
        }
        if (!nickname_mapping.get (server_name).has_key (username)) {
            return null;
        }
        var uuid = nickname_mapping.get (server_name).get (username);
        return main_stack.get_child_by_name (uuid) as Iridium.Views.PrivateMessageChatView;
    }

    public void show_chat_view (string server_name, string? channel_name) {
        var chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            return;
        }
        chat_view.show_all ();
        main_stack.set_visible_child_full (get_child_name (server_name, channel_name), Gtk.StackTransitionType.SLIDE_RIGHT);
        // Set focus on the text entry
        Idle.add (() => {
            chat_view.set_entry_focus ();
            return false;
        });
    }

    private Iridium.Views.ChatView? get_chat_view (string server_name, string? channel_name) {
        var child_name = get_child_name (server_name, channel_name);
        return (Iridium.Views.ChatView) main_stack.get_child_by_name (child_name);
    }

    private string get_child_name (string server_name, string? channel_name) {
        if (channel_name == null) {
            return server_name;
        } else if (channel_name.has_prefix ("#")) {
            return server_name + ";" + channel_name;
        } else {
            return nickname_mapping.get (server_name).get (channel_name);
        }
    }

    public void rename_private_message_chat_view (string server_name, string old_nickname, string new_nickname) {
        if (!nickname_mapping.has_key (server_name)) {
            return;
        }
        if (!nickname_mapping.get (server_name).has_key (old_nickname)) {
            return;
        }
        var uuid = nickname_mapping.get (server_name).get (old_nickname);
        debug ("rename: found uuid %s for old nickname %s", uuid, old_nickname);
        nickname_mapping.get (server_name).set (new_nickname, uuid);
        nickname_mapping.get (server_name).unset (old_nickname);
    }

}
