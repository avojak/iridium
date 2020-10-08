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

public class Iridium.Layouts.MainLayout : Gtk.Grid {

    public unowned Iridium.MainWindow window { get; construct; }

    public Iridium.Views.Welcome welcome_view { get; construct; }
    public Iridium.Widgets.SidePanel.Panel side_panel { get; construct; }
    public Iridium.Widgets.StatusBar status_bar { get; construct; }

    private Gee.Map<string, Gee.Map<string, string>> nickname_mapping;
    //  private Gee.Map<string, Gee.Map<string, string>> view_mapping;
    private Gee.List<Iridium.Views.ChatView> chat_views;

    private Gtk.Paned paned;

    private Iridium.Widgets.NetworkInfoBar network_info_bar;
    private Gtk.Overlay overlay;
    private Granite.Widgets.OverlayBar? overlay_bar;
    private Gtk.Stack main_stack;

    public MainLayout (Iridium.MainWindow window) {
        Object (
            window: window
        );
    }

    construct {
        side_panel = new Iridium.Widgets.SidePanel.Panel (window);
        welcome_view = new Iridium.Views.Welcome (window);
        main_stack = new Gtk.Stack ();
        main_stack.add_named (welcome_view, "welcome");

        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.position = 240;
        paned.pack1 (side_panel, false, false);
        paned.pack2 (main_stack, true, false);

        network_info_bar = new Iridium.Widgets.NetworkInfoBar ();

        overlay = new Gtk.Overlay ();
        overlay.add (paned);

        attach (network_info_bar, 0, 0, 1, 1);
        attach (overlay, 0, 1, 1, 1);

        nickname_mapping = new Gee.HashMap<string, Gee.Map<string, string>> ();
        //  view_mapping = new Gee.HashMap<string, Gee.Map<string, string>> ();
        chat_views = new Gee.ArrayList<Iridium.Views.ChatView> ();

        // Connect to side panel signals
        side_panel.item_selected.connect (on_side_panel_item_selected);
        side_panel.join_channel.connect ((server_name, channel_name) => {
            join_channel_button_clicked (server_name, channel_name);
        });
        side_panel.leave_channel.connect ((server_name, channel_name) => {
            leave_channel_button_clicked (server_name, channel_name);
        });
        side_panel.connect_to_server.connect ((server_name) => {
            connect_to_server_button_clicked (server_name);
        });
        side_panel.disconnect_from_server.connect ((server_name) => {
            disconnect_from_server_button_clicked (server_name);
        });
        side_panel.edit_channel_topic.connect ((server_name, channel_name) => {
            edit_channel_topic_button_clicked (server_name, channel_name);
        });

        // Add signal connections to maintain state
        // TODO: Should these connect to the connection handler signals rather than the side panel...?
        side_panel.server_row_added.connect (Iridium.Application.connection_repository.on_server_row_added);
        side_panel.server_row_removed.connect (Iridium.Application.connection_repository.on_server_row_removed);
        side_panel.server_row_enabled.connect (Iridium.Application.connection_repository.on_server_row_enabled);
        side_panel.server_row_disabled.connect (Iridium.Application.connection_repository.on_server_row_disabled);
        side_panel.channel_row_added.connect (Iridium.Application.connection_repository.on_channel_row_added);
        side_panel.channel_row_removed.connect (Iridium.Application.connection_repository.on_channel_row_removed);
        side_panel.channel_row_enabled.connect (Iridium.Application.connection_repository.on_channel_row_enabled);
        side_panel.channel_row_disabled.connect (Iridium.Application.connection_repository.on_channel_row_disabled);
        side_panel.channel_favorite_added.connect (Iridium.Application.connection_repository.on_channel_favorite_added);
        side_panel.channel_favorite_removed.connect (Iridium.Application.connection_repository.on_channel_favorite_removed);

        this.destroy.connect (() => {
            // Disconnect this signal so that we don't modify the setting to
            // show servers as disabled, when in reality they were enabled prior
            // to closing the application.
            side_panel.server_row_disabled.disconnect (Iridium.Application.connection_repository.on_server_row_disabled);
        });

        show_all ();
    }

    public void add_server_chat_view (string server_name, string nickname, string? network_name) {
        // Ensure that we're not adding a view which already exists.
        // This can happen if the view was already created during initialization,
        // and then this method is called when the server is actually connected.
        if (get_server_chat_view (server_name) != null) {
            //  warning ("A server chat view with the name %s already exists", server_name);
            // Create the side panel row - unlike the chat view, it is removed upon disconnect
            side_panel.add_server_row (server_name, network_name);
            side_panel.disable_server_row (server_name); // TODO: Should be disabled by default?
            return;
        }

        // Create the new chat view and add it to the stack
        var chat_view = new Iridium.Views.ServerChatView (window, nickname);
        chat_view.set_enabled (false); // TODO: Should be disabled by default?
        //  if (!view_mapping.has_key (server_name)) {
        //      view_mapping.set (server_name, new Gee.HashMap<string, string> ());
        //  }
        main_stack.add_named (chat_view, server_name);
        chat_views.add (chat_view);

        // Connect to signals
        chat_view.message_to_send.connect ((message) => {
            server_message_to_send (server_name, message);
        });
        chat_view.nickname_button_clicked.connect (() => {
            nickname_button_clicked (server_name);
        });

        // Create the side panel row
        side_panel.add_server_row (server_name, network_name);
        side_panel.disable_server_row (server_name); // TODO: Should be disabled by default?
    }

    public void add_channel_chat_view (string server_name, string channel_name, string nickname) {
        // Ensure that we're not adding a view which already exists.
        // This can happen if the view was already created during initialization,
        // and then this method is called when the channel is actually joined.
        if (get_channel_chat_view (server_name, channel_name) != null) {
            //  warning ("A channel chat view with the name %s already exists", server_name);
            // Create the side panel row - unlike the chat view, it is removed
            side_panel.add_channel_row (server_name, channel_name);
            side_panel.disable_channel_row (server_name, channel_name); // TODO: Should be disabled by default?
            return;
        }

        // Create the new chat view and add it to the stack
        var chat_view = new Iridium.Views.ChannelChatView (window, nickname);
        chat_view.set_enabled (false); // TODO: Should be disabled by default?
        //  if (!view_mapping.has_key (server_name)) {
        //      view_mapping.set (server_name, new Gee.HashMap<string, string> ());
        //  }
        //  var uuid = GLib.Uuid.string_random ();
        //  view_mapping.get (server_name).set (channel_name, uuid);
        main_stack.add_named (chat_view, server_name + ":" + channel_name);
        //  main_stack.add_named (chat_view, uuid);
        chat_views.add (chat_view);

        // Connect to signals
        chat_view.message_to_send.connect ((message) => {
            channel_message_to_send (server_name, channel_name, message);
        });
        chat_view.nickname_button_clicked.connect (() => {
            nickname_button_clicked (server_name);
        });

        // Create the side panel row
        side_panel.add_channel_row (server_name, channel_name);
        side_panel.disable_channel_row (server_name, channel_name); // TODO: Should be disabled by default?
    }

    public void add_private_message_chat_view (string server_name, string username, string self_nickname) {
        // Ensure that we're not adding a view which already exists
        if (get_private_message_chat_view (server_name, username) != null) {
            //  warning ("A private message chat view with the name %s already exists", server_name);
            // Create the side panel row - unlike the chat view, it is removed
            side_panel.add_private_message_row (server_name, username);
            return;
        }

        // Create the new chat view and add it to the stack
        var chat_view = new Iridium.Views.PrivateMessageChatView (window, self_nickname, username);
        chat_view.set_enabled (false); // TODO: Should be disabled by default?
        if (!nickname_mapping.has_key (server_name)) {
            nickname_mapping.set (server_name, new Gee.HashMap<string, string> ());
        }
        //  if (!view_mapping.has_key (server_name)) {
        //      view_mapping.set (server_name, new Gee.HashMap<string, string> ());
        //  }
        var uuid = GLib.Uuid.string_random ();
        nickname_mapping.get (server_name).set (username, uuid);
        //  view_mapping.get (server_name).set (username, uuid);
        main_stack.add_named (chat_view, server_name + ":" + uuid);
        chat_views.add (chat_view);

        // Connect to signals
        chat_view.message_to_send.connect ((message) => {
            private_message_to_send (server_name, chat_view.username, message);
        });
        chat_view.nickname_button_clicked.connect (() => {
            nickname_button_clicked (server_name);
        });

        // Create the side panel row
        side_panel.add_private_message_row (server_name, username);
    }

    public void show_welcome_view () {
        main_stack.get_child_by_name ("welcome").show_all ();
        main_stack.set_visible_child_full ("welcome", Gtk.StackTransitionType.SLIDE_RIGHT);
        welcome_view_shown ();
    }

    public Iridium.Views.ChannelChatView? get_channel_chat_view (string server_name, string channel_name) {
        var name = server_name + ":" + channel_name;
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
        return main_stack.get_child_by_name (server_name + ":" + uuid) as Iridium.Views.PrivateMessageChatView;
    }

    public void enable_chat_view (string server_name, string? channel_name) {
        Iridium.Views.ChatView? chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for server name %s and channel name %s", server_name, channel_name);
            return;
        }
        chat_view.set_enabled (true);

        // Enable the side panel row
        if (chat_view is Iridium.Views.ServerChatView) {
            side_panel.enable_server_row (server_name);
        } else if (chat_view is Iridium.Views.ChannelChatView) {
            side_panel.enable_channel_row (server_name, channel_name);
        } else if (chat_view is Iridium.Views.PrivateMessageChatView) {
            // Do nothing
        } else {
            assert_not_reached ();
        }
    }

    public void disable_chat_view (string server_name, string? channel_name) {
        Iridium.Views.ChatView? chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for server name %s and channel name %s", server_name, channel_name);
            return;
        }
        chat_view.set_enabled (false);

        // Disable the side panel row
        if (chat_view is Iridium.Views.ServerChatView) {
            side_panel.disable_server_row (server_name);
        } else if (chat_view is Iridium.Views.ChannelChatView) {
            side_panel.disable_channel_row (server_name, channel_name);
        } else if (chat_view is Iridium.Views.PrivateMessageChatView) {
            // Do nothing
        } else {
            assert_not_reached ();
        }
    }

    public void error_chat_view (string server_name, string? channel_name, string error_message, string? error_details) {
        Iridium.Views.ChatView? chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for server name %s and channel name %s", server_name, channel_name);
            return;
        }

        // Display the error on the side panel row
        if (chat_view is Iridium.Views.ServerChatView) {
            side_panel.error_server_row (server_name, error_message, error_details);
        } else if (chat_view is Iridium.Views.ChannelChatView) {
            // TODO
        } else if (chat_view is Iridium.Views.PrivateMessageChatView) {
            // TODO
        } else {
            assert_not_reached ();
        }
    }

    public bool is_view_enabled (string server_name, string? channel_name) {
        Iridium.Views.ChatView? chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for server name %s and channel name %s", server_name, channel_name);
            return false;
        }
        return chat_view.get_enabled ();
    }

    public void show_chat_view (string server_name, string? channel_name) {
        var chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for server name %s and channel name %s", server_name, channel_name);
            return;
        }

        // Notify the currently visible chat view that it is losing focus
        Gtk.Widget? visible_child = main_stack.get_visible_child ();
        if (visible_child != null && visible_child is Iridium.Views.ChatView) {
            ((Iridium.Views.ChatView) visible_child).focus_lost ();
        }

        // Show the chat view
        chat_view.show_all ();
        main_stack.set_visible_child_full (get_child_name (server_name, channel_name), Gtk.StackTransitionType.SLIDE_RIGHT);

        // Notify the chat view that it has gained focus
        chat_view.focus_gained ();

        // Select side panel row and call signals
        if (chat_view is Iridium.Views.ServerChatView) {
            side_panel.select_server_row (server_name);
            server_chat_view_shown (server_name);
        } else if (chat_view is Iridium.Views.ChannelChatView) {
            side_panel.select_channel_row (server_name, channel_name);
            channel_chat_view_shown (server_name, channel_name);
        } else if (chat_view is Iridium.Views.PrivateMessageChatView) {
            side_panel.select_private_message_row (server_name, channel_name);
            private_message_chat_view_shown (server_name, channel_name);
        } else {
            assert_not_reached ();
        }

        Idle.add (() => {
            // Set focus on the text entry
            chat_view.set_entry_focus ();
            return false;
        });
    }

    public string? get_visible_server () {
        string? child_name = main_stack.get_visible_child_name ();
        if (child_name == null || child_name == "welcome") {
            return null;
        }
        if (!child_name.contains (":")) {
            return child_name;
        } else {
            return child_name.split (":")[0];
        }
    }

    public string? get_visible_channel () {
        string? child_name = main_stack.get_visible_child_name ();
        if (child_name == null || child_name == "welcome") {
            return null;
        }
        if (!child_name.contains (":")) {
            return null;
        } else {
            return child_name.split (":")[1];
        }
    }

    public Gee.List<Iridium.Views.ChatView> get_chat_views () {
        return chat_views;
    }

    public void show_initialization_overlay () {
        if (overlay_bar == null) {
            overlay_bar = new Granite.Widgets.OverlayBar (overlay);
            overlay_bar.label = _("Restoring server connections…");
            overlay_bar.active = true;
            overlay.show_all ();
        }
    }

    public void hide_initialization_overlay () {
        Idle.add (() => {
            if (overlay_bar != null) {
                overlay_bar.destroy ();
            }
            return false;
        });
    }

    public void show_network_info_bar () {
        network_info_bar.revealed = true;
    }

    public void hide_network_info_bar () {
        network_info_bar.revealed = false;
    }

    public void display_server_message (string server_name, string? channel_name, Iridium.Services.Message message) {
        Iridium.Views.ChatView? chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for %s, %s", server_name, channel_name);
            return;
        }

        chat_view.display_server_msg (message);

        if (chat_view is Iridium.Views.ServerChatView) {
            side_panel.increment_server_badge (server_name);
        } else if (chat_view is Iridium.Views.ChannelChatView) {
            side_panel.increment_channel_badge (server_name, channel_name);
        } else if (chat_view is Iridium.Views.PrivateMessageChatView) {
            side_panel.increment_channel_badge (server_name, channel_name);
        } else {
            assert_not_reached ();
        }
    }

    public void display_server_error_message (string server_name, string? channel_name, Iridium.Services.Message message) {
        Iridium.Views.ChatView? chat_view = get_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No chat view exists for %s, %s", server_name, channel_name);
            return;
        }

        chat_view.display_server_error_msg (message);

        if (chat_view is Iridium.Views.ServerChatView) {
            side_panel.increment_server_badge (server_name);
        } else if (chat_view is Iridium.Views.ChannelChatView) {
            side_panel.increment_channel_badge (server_name, channel_name);
        } else if (chat_view is Iridium.Views.PrivateMessageChatView) {
            side_panel.increment_channel_badge (server_name, channel_name);
        } else {
            assert_not_reached ();
        }
    }

    public void display_channel_message (string server_name, string channel_name, Iridium.Services.Message message) {
        Iridium.Views.ChannelChatView? chat_view = get_channel_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No channel chat view exists for %s, %s", server_name, channel_name);
            return;
        }
        chat_view.display_private_msg (message);
        side_panel.increment_channel_badge (server_name, channel_name);
    }

    public void display_self_channel_message (string server_name, string channel_name, Iridium.Services.Message message) {
        Iridium.Views.ChannelChatView? chat_view = get_channel_chat_view (server_name, channel_name);
        if (chat_view == null) {
            warning ("No channel chat view exists for %s, %s", server_name, channel_name);
            return;
        }
        chat_view.display_self_private_msg (message);
    }

    public void display_private_message (string server_name, string username, Iridium.Services.Message message) {
        Iridium.Views.PrivateMessageChatView? chat_view = get_private_message_chat_view (server_name, username);
        if (chat_view == null) {
            warning ("No private message chat view exists for %s, %s", server_name, username);
            return;
        }
        chat_view.display_private_msg (message);
        side_panel.increment_channel_badge (server_name, username);
    }

    public void display_self_private_message (string server_name, string username, Iridium.Services.Message message) {
        Iridium.Views.PrivateMessageChatView? chat_view = get_private_message_chat_view (server_name, username);
        if (chat_view == null) {
            warning ("No private message chat view exists for %s, %s", server_name, username);
            return;
        }
        chat_view.display_self_private_msg (message);
    }

    public void updating_server (string server_name) {
        Idle.add (() => {
            side_panel.updating_server_row (server_name);
            return false;
        });
    }

    public void updating_channel (string server_name, string channel_name) {
        Idle.add (() => {
            side_panel.updating_channel_row (server_name, channel_name);
            return false;
        });
    }

    // Update our nickname
    public void update_nickname (string server_name, string old_nickname, string new_nickname) {
        // Update chat views
        Idle.add (() => {
            foreach (var chat_view in get_chat_views ()) {
                chat_view.update_nickname (new_nickname);
            }
            return false;
        });
    }

    // Update another users nickname
    public void update_user_nickname (string server_name, string old_nickname, string new_nickname) {
        // Update private message view
        rename_private_message_chat_view (server_name, old_nickname, new_nickname);
        var chat_view = get_private_message_chat_view (server_name, new_nickname);
        if (chat_view != null) {
            chat_view.username = new_nickname;
        }

        // Update private message side panel row
        side_panel.update_nickname (server_name, old_nickname, new_nickname);
    }

    public void update_network_name (string server_name, string network_name) {
        // Update side panel
        Idle.add (() => {
            side_panel.update_network_name (server_name, network_name);
            return false;
        });
    }

    public void favorite_channel (string server_name, string channel_name) {
        side_panel.favorite_channel (server_name, channel_name);
    }

    public void update_channel_users (string server_name, string channel_name, Gee.List<string> usernames) {
        var channel_chat_view = get_channel_chat_view (server_name, channel_name);
        if (channel_chat_view != null) {
            channel_chat_view.set_usernames (usernames);
        }
    }

    private Iridium.Views.ChatView? get_chat_view (string server_name, string? channel_name) {
        var child_name = get_child_name (server_name, channel_name);
        return (Iridium.Views.ChatView) main_stack.get_child_by_name (child_name);
    }

    private string get_child_name (string server_name, string? channel_name) {
        if (channel_name == null) {
            return server_name;
        } else if (channel_name.has_prefix ("#") || channel_name.has_prefix ("&")) {
            return server_name + ":" + channel_name;
        } else {
            return server_name + ":" + nickname_mapping.get (server_name).get (channel_name);
        }
    }

    private void rename_private_message_chat_view (string server_name, string old_nickname, string new_nickname) {
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

    public void toggle_sidebar () {
        side_panel.visible = !side_panel.visible;
    }

    /*
     * Handlers for the side panel signals
     */

    private void on_side_panel_item_selected (Granite.Widgets.SourceList.Item? item) {
        // No item selected
        if (item == null) {
            show_welcome_view ();
            return;
        }

        // Item selected
        unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) item;
        var server_name = row.get_server_name ();
        var channel_name = row.get_channel_name ();
        show_chat_view (server_name, channel_name);
    }

    /*
     * Signals
     */

    public signal void welcome_view_shown ();
    public signal void server_chat_view_shown (string server_name);
    public signal void channel_chat_view_shown (string server_name, string channel_name);
    public signal void private_message_chat_view_shown (string server_name, string username);

    public signal void server_message_to_send (string server_name, string message);
    public signal void channel_message_to_send (string server_name, string channel_name, string message);
    public signal void private_message_to_send (string server_name, string username, string message);
    public signal void nickname_button_clicked (string server_name);

    public signal void join_channel_button_clicked (string server_name, string? channel_name);
    public signal void leave_channel_button_clicked (string server_name, string channel_name);
    public signal void connect_to_server_button_clicked (string server_name);
    public signal void disconnect_from_server_button_clicked (string server_name);
    public signal void edit_channel_topic_button_clicked (string server_name, string channel_name);
}
