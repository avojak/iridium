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

public class Iridium.MainWindow : Gtk.ApplicationWindow {

    public Iridium.Services.ServerConnectionHandler connection_handler { get; construct; }

    public Iridium.Widgets.ServerConnectionDialog? connection_dialog = null;
    public Iridium.Widgets.ChannelJoinDialog? channel_join_dialog = null;

    private Iridium.Views.Welcome welcome_view;
    private Iridium.Widgets.HeaderBar header_bar;
    private Iridium.Widgets.SidePanel.Panel side_panel;
    private Iridium.Layouts.MainLayout main_layout;

    public MainWindow (Gtk.Application application, Iridium.Services.ServerConnectionHandler connection_handler) {
        Object (
            application: application,
            border_width: 0,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER,
            connection_handler: connection_handler
        );
    }

    construct {
        header_bar = new Iridium.Widgets.HeaderBar ();
        header_bar.hide_channel_users_button ();
        set_titlebar (header_bar);

        // TODO: Show an info bar across the top of the window area when internet connection is lost

        welcome_view = new Iridium.Views.Welcome ();
        side_panel = new Iridium.Widgets.SidePanel.Panel ();

        main_layout = new Iridium.Layouts.MainLayout (welcome_view, side_panel);
        add (main_layout);

        resize (1000, 600);

        // Connect to signals
        header_bar.server_connect_button_clicked.connect (() => {
            show_server_connection_dialog ();
        });
        header_bar.channel_join_button_clicked.connect (() => {
            show_channel_join_dialog ();
        });
        header_bar.username_selected.connect (on_username_selected);
        side_panel.item_selected.connect ((item) => {
            // No item selected
            if (item == null) {
                header_bar.set_channel_join_button_enabled (false);
                main_layout.show_welcome_view ();
                return;
            }
            // Dummy selected
            if (item.name.strip ().length == 0) {
                header_bar.set_channel_join_button_enabled (false);
                return;
            }
            // Item selected
            main_layout.show_chat_view (item.name);

            // Update the header bar title
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) item;
            var server_name = row.get_server_name ();
            var channel_name = row.get_channel_name ();
            if (channel_name != null) {
                header_bar.update_title (channel_name, server_name);
            } else {
                header_bar.update_title (server_name, null);
            }

            // Show or hide the channel users button in the header
            if (item is Iridium.Widgets.SidePanel.ChannelRow) {
                header_bar.show_channel_users_button ();
                // Update the channel users list
                update_channel_users_list (server_name, channel_name);                
            } else {
                header_bar.hide_channel_users_button ();
            }

            // We have enough context to join a channel
            // TODO: This should probably still be enabled as long as there's
            //       at least one open connection.
            header_bar.set_channel_join_button_enabled (true);
        });
        side_panel.disconnect_from_server.connect ((server_name) => {
            // TODO: Might need to disable the join channel header button!
            connection_handler.disconnect_from_server (server_name);
        });
        side_panel.leave_channel.connect ((server_name, channel_name) => {
            connection_handler.leave_channel (server_name, channel_name);
        });
        welcome_view.new_connection_button_clicked.connect (() => {
            show_server_connection_dialog ();
        });

        // Connect to all of the connection handler signals
        connection_handler.server_connection_successful.connect (on_server_connection_successful);
        connection_handler.server_connection_failed.connect (on_server_connection_failed);
        connection_handler.server_connection_closed.connect (on_server_connection_closed);
        connection_handler.server_message_received.connect (on_server_message_received);
        connection_handler.server_error_received.connect (on_server_error_received);
        connection_handler.server_quit.connect (on_server_quit);
        connection_handler.user_quit_server.connect (on_user_quit_server);
        connection_handler.nickname_in_use.connect (on_nickname_in_use);
        connection_handler.channel_joined.connect (on_channel_joined);
        connection_handler.channel_left.connect (on_channel_left);
        connection_handler.channel_message_received.connect (on_channel_message_received);
        connection_handler.user_joined_channel.connect (on_user_joined_channel);
        connection_handler.user_left_channel.connect (on_user_left_channel);
        connection_handler.direct_message_received.connect (on_direct_message_received);

        // Connect to all of the side panel signals to make settings changes
        side_panel.server_row_added.connect (Iridium.Application.settings.on_server_row_added);
        side_panel.server_row_removed.connect (Iridium.Application.settings.on_server_row_removed);
        side_panel.server_row_enabled.connect (Iridium.Application.settings.on_server_row_enabled);
        side_panel.server_row_disabled.connect (Iridium.Application.settings.on_server_row_disabled);
        side_panel.channel_row_added.connect (Iridium.Application.settings.on_channel_row_added);
        side_panel.channel_row_removed.connect (Iridium.Application.settings.on_channel_row_removed);
        side_panel.channel_row_enabled.connect (Iridium.Application.settings.on_channel_row_enabled);
        side_panel.channel_row_disabled.connect (Iridium.Application.settings.on_channel_row_disabled);

        // Connect to the connection handler signal to make settings changes for new connections
        connection_handler.server_connection_successful.connect ((server_name, message) => {
            var connection_details = connection_handler.get_connection_details (server_name);
            Iridium.Application.settings.on_server_connection_successful (connection_details);
        });

        // Close connections when the window is closed
        this.destroy.connect (() => {
            // Disconnect this signal so that we don't modify the setting to
            // show servers as disabled, when in reality they were enabled prior
            // to closing the application.
            side_panel.server_row_disabled.disconnect (Iridium.Application.settings.on_server_row_disabled);

            // TODO: Not sure if this is right...
            connection_handler.close_all_connections ();
            GLib.Process.exit (0);
        });
    }

    // TODO: Restore private messages from the side panel
    public void initialize (Gee.List<string> servers_list, Gee.List<string> channels_list, Gee.List<string> connection_details_list) {
        Gee.List<string> server_rows = new Gee.ArrayList<string> ();
        Gee.List<string> enabled_servers = new Gee.ArrayList<string> ();
        foreach (string entry in servers_list) {
            string[] tokens = entry.split ("\n");
            var server_name = tokens[0].split ("=")[1];
            var enabled = bool.parse (tokens[1].split ("=")[1]);
            server_rows.add (server_name);
            if (enabled) {
                enabled_servers.add (server_name);
            }
        }

        Gee.Map<string, Gee.List<string>> channel_rows = new Gee.HashMap<string, Gee.ArrayList<string>> ();
        Gee.Map<string, Gee.List<string>> enabled_channels = new Gee.HashMap<string, Gee.ArrayList<string>> ();
        Gee.Map<string, Gee.List<string>> disabled_channels = new Gee.HashMap<string, Gee.ArrayList<string>> ();
        foreach (string entry in channels_list) {
            string[] tokens = entry.split ("\n");
            var server_name = tokens[0].split ("=")[1];
            var channel_name = tokens[1].split ("=")[1];
            var enabled = bool.parse (tokens[2].split ("=")[1]);

            if (!channel_rows.has_key (server_name)) {
                channel_rows.set (server_name, new Gee.ArrayList<string> ());
                enabled_channels.set (server_name, new Gee.ArrayList<string> ());
                disabled_channels.set (server_name, new Gee.ArrayList<string> ());
            }

            channel_rows.get (server_name).add (channel_name);
            if (enabled) {
                enabled_channels.get (server_name).add (channel_name);
            } else {
                disabled_channels.get (server_name).add (channel_name);
            }
        }

        Idle.add (() => {
            foreach (string server_name in server_rows) {
                side_panel.add_server (server_name);
                side_panel.disable_server_row (server_name);
            }
            foreach (Gee.Map.Entry<string, Gee.List<string>> entry in channel_rows.entries) {
                var server_name = entry.key;
                foreach (string channel_name in entry.value) {
                    side_panel.add_channel (server_name, channel_name);
                    side_panel.disable_channel_row (server_name, channel_name);
                }
            }
            return false;
        });

        Gee.Map<string, Iridium.Services.ServerConnectionDetails> connection_details_map = new Gee.HashMap<string, Iridium.Services.ServerConnectionDetails> ();
        foreach (string entry in connection_details_list) {
            string[] tokens = entry.split ("\n");
            var connection_details = new Iridium.Services.ServerConnectionDetails ();
            connection_details.server = tokens[0].split ("=")[1];
            connection_details.username = tokens[2].split ("=")[1];
            connection_details.nickname = tokens[3].split ("=")[1];
            connection_details.realname = tokens[4].split ("=")[1];
            connection_details_map.set (connection_details.server, connection_details);
        }

        foreach (string server_name in enabled_servers) {
            var connection_details = connection_details_map.get (server_name);
            var server_connection = connection_handler.connect_to_server (connection_details);
            server_connection.open_successful.connect (() => {
                foreach (string channel_name in enabled_channels.get (server_name)) {
                    connection_handler.join_channel (server_name, channel_name);
                }
                // Still add chat views for channels that aren't joined yet.
                // This is needed in case a user clicks a channel item in the
                // side panel when the channel hasn't been joined yet.

                // TODO: This causes a bug when initializing and a server is
                //       present in the side bar, but not connected. Selecting
                //       the item will not show a view because it hasn't been
                //       created here. Maybe make the panel item not selectable?

                Idle.add (() => {
                    foreach (string channel_name in disabled_channels.get (server_name)) {
                        var chat_view = new Iridium.Views.ChannelChatView ();
                        main_layout.add_chat_view (chat_view, channel_name);
                    }
                    return false;
                });
            });
        }
    }

    private void show_server_connection_dialog () {
        if (connection_dialog == null) {
            connection_dialog = new Iridium.Widgets.ServerConnectionDialog (this);
            connection_dialog.show_all ();
            connection_dialog.connect_button_clicked.connect ((server, nickname, username, realname) => {
                // Prevent duplicate connections
                if (connection_handler.has_connection (server)) {
                    connection_dialog.display_error (_("Already connected to this server!"));
                    return;
                }

                // Create the connection details
                var connection_details = new Iridium.Services.ServerConnectionDetails ();
                connection_details.server = server;
                connection_details.nickname = nickname;
                connection_details.username = username;
                connection_details.realname = realname;

                // Attempt the server connection
                connection_handler.connect_to_server (connection_details);
            });
            connection_dialog.destroy.connect (() => {
                connection_dialog = null;
            });
        }
        connection_dialog.present ();
    }

    private void show_channel_join_dialog () {
        if (channel_join_dialog == null) {
            var connected_servers = connection_handler.get_connected_servers ();
            var current_server = side_panel.get_current_server ();
            channel_join_dialog = new Iridium.Widgets.ChannelJoinDialog (this, connected_servers, current_server);
            channel_join_dialog.show_all ();
            channel_join_dialog.join_button_clicked.connect ((server_name, channel_name) => {
                join_channel (server_name, channel_name);
            });
            channel_join_dialog.destroy.connect (() => {
                channel_join_dialog = null;
            });
        }
        channel_join_dialog.present ();
    }

    private void join_channel (string server_name, string channel_name) {
        // Validate channel name
        // TODO: Look into what other restrictions exist
        if (!channel_name.has_prefix ("#") && !channel_name.has_prefix ("&")) {
            // TODO: Eventually validate that the dialog is non-null, and handle accordingly
            channel_join_dialog.display_error (_("Channel must begin with '#' or '&'"));
            return;
        }
        connection_handler.join_channel (server_name, channel_name);
    }

    private void send_server_message (string server_name, string text, Iridium.Views.ServerChatView chat_view) {
        if (text == null || text.strip ().length == 0) {
            return;
        }
        // Make sure the message text starts with a '/'
        if (text[0] != '/') {
            var message = new Iridium.Services.Message ();
            message.message = _("Start your message with a /");
            chat_view.display_server_error_msg (message);
            return;
        }
        send_server_command (server_name, text.substring (1));
    }

    private void send_channel_message (string server_name, string channel_name, string text, Iridium.Views.ChatView chat_view) {
        if (text == null || text.strip ().length == 0) {
            return;
        }
        // Check if it's a server command
        if (text[0] == '/') {
            send_server_command (server_name, text.substring (1));
            return;
        }
        // Send the message
        var message_text = "PRIVMSG " + channel_name + " :" + text;
        connection_handler.send_user_message (server_name, message_text);
        // Display the message in the chat view
        var message = new Iridium.Services.Message (message_text);
        message.username = connection_handler.get_nickname (server_name);
        chat_view.display_self_priv_msg (message);
    }

    private void send_server_command (string server_name, string text) {
        // TODO: Check for commands (eg. /me, etc.)
        connection_handler.send_user_message (server_name, text);
    }

    //
    // HeaderBar Callbacks
    //

    private void on_username_selected (string username) {
        var selected_row = side_panel.get_selected_row ();
        if (selected_row == null) {
            return;
        }
        var server_name = selected_row.get_server_name ();
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_direct_message_chat_view (username);
            if (chat_view == null) {
                chat_view = new Iridium.Views.DirectMessageChatView ();
                main_layout.add_chat_view (chat_view, username);
                chat_view.message_to_send.connect ((user_message) => {
                    send_channel_message (server_name, username, user_message, chat_view);
                });
            }
            side_panel.add_direct_message (server_name, username);
            side_panel.select_direct_message_row (server_name, username);
            return false;
        });
    }

    //
    // ServerConnectionHandler Callbacks
    //

    private void on_server_connection_successful (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_server_chat_view (server_name);
            if (chat_view == null) {
                chat_view = new Iridium.Views.ServerChatView ();
                chat_view.message_to_send.connect ((message_to_send) => {
                    send_server_message (server_name, message_to_send, chat_view);
                });
                main_layout.add_chat_view (chat_view, server_name);
            }

            chat_view.display_server_msg (message);

            side_panel.add_server (server_name);
            side_panel.enable_server_row (server_name);
            // TODO: Maybe only do these two things if the dialog was open?
            /* main_layout.show_chat_view (server_name);
            show_channel_join_dialog (); */
            if (connection_dialog != null) {
                connection_dialog.dismiss ();

                side_panel.select_server_row (server_name);
                show_channel_join_dialog ();
            }

            return false;
        });
    }

    private void on_server_connection_failed (string server_name, string error_message) {
        Idle.add (() => {
            if (connection_dialog != null) {
                connection_dialog.display_error (error_message);
            }
            return false;
        });
    }

    private void on_server_connection_closed (string server_name) {
        // TODO: Implement - display disconnect message and disable the server
        //       and all associated channel rows
        side_panel.disable_server_row (server_name);
    }

    private void on_server_message_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            var chat_view = main_layout.get_server_chat_view (server_name);
            // For some NOTICEs, the server ChatView has not yet been created,
            // because we haven't yet received the 001 WELCOME
            if (chat_view != null) {
                chat_view.display_server_msg (message);
            }
            side_panel.increment_server_badge (server_name);
            return false;
        });
    }

    private void on_server_error_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            var chat_view = main_layout.get_server_chat_view (server_name);
            // For some NOTICEs, the server ChatView has not yet been created,
            // because we haven't yet received the 001 WELCOME
            if (chat_view != null) {
                chat_view.display_server_error_msg (message);
            }
            side_panel.increment_server_badge (server_name);
            return false;
        });
    }

    private void on_server_quit (string server_name, string message) {
        connection_handler.disconnect_from_server (server_name);
    }

    private void on_user_quit_server (string server_name, string username, Gee.List<string> channels, Iridium.Services.Message message) {
        // Display a message in any channel that the user was in
        Idle.add (() => {
            foreach (string channel in channels) {
                var channel_chat_view = main_layout.get_channel_chat_view (channel);
                if (channel_chat_view != null) {
                    var message_to_display = new Iridium.Services.Message ();
                    message_to_display.message = username + _(" has quit");
                    if (message.message != null && message.message.strip () != "") {
                        message_to_display.message += " (" + message.message + ")";
                    }
                    channel_chat_view.display_server_msg (message_to_display);
                }
                update_channel_users_list (server_name, channel);
            }
            return false;
        });

        // If the user was in a private message chat view, display the message there
        Idle.add (() => {
            // Display a message in the channel chat view
            var direct_message_chat_view = main_layout.get_direct_message_chat_view (username);
            if (direct_message_chat_view != null) {
                var message_to_display = new Iridium.Services.Message ();
                message_to_display.message = username + _(" has quit");
                if (message.message != null && message.message.strip () != "") {
                    message_to_display.message += " (" + message.message + ")";
                }
                direct_message_chat_view.display_server_msg (message_to_display);
            }
            return false;
        });
    }

    private void on_nickname_in_use (string server_name, Iridium.Services.Message message) {
        if (connection_dialog != null) {
            // TODO: Should this be outside the if-statement?
            connection_handler.disconnect_from_server (server_name);
            connection_dialog.display_error (_("Nickname already in use."));
        } else {
            // TODO: This should be an error
            var chat_view = main_layout.get_server_chat_view (server_name);
            chat_view.display_server_error_msg (message);
            // TODO: Prompt for new nickname?
        }
    }

    private void on_channel_joined (string server_name, string channel_name) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_channel_chat_view (channel_name);
            if (chat_view == null) {
                chat_view = new Iridium.Views.ChannelChatView ();
                main_layout.add_chat_view (chat_view, channel_name);
                chat_view.message_to_send.connect ((user_message) => {
                    send_channel_message (server_name, channel_name, user_message, chat_view);
                });
            }

            side_panel.add_channel (server_name, channel_name);
            side_panel.enable_channel_row (server_name, channel_name);
            // TODO: Maybe only do this if the dialog was open?
            //       Might also be able to surround this with an initializing
            //       boolean check (ie. only select if we're not initializing).
            /* side_panel.select_channel_row (server_name, channel_name); */
            if (channel_join_dialog != null) {
                channel_join_dialog.dismiss ();

                side_panel.select_channel_row (server_name, channel_name);
            }
            return false;
        });
    }

    private void on_channel_left (string server_name, string channel_name) {
        // TODO: Display a message that we've left the channel

        side_panel.disable_channel_row (server_name, channel_name);
    }

    private void on_channel_message_received (string server_name, string channel_name, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_channel_chat_view (channel_name);
            if (chat_view == null) {
                chat_view = new Iridium.Views.ChannelChatView ();
                main_layout.add_chat_view (chat_view, channel_name);
                chat_view.message_to_send.connect ((user_message) => {
                    send_channel_message (server_name, channel_name, user_message, chat_view);
                });
            }
            side_panel.add_channel (server_name, channel_name);
            chat_view.display_priv_msg (message);
            side_panel.increment_channel_badge (server_name, channel_name);
            return false;
        });
    }

    private void on_user_joined_channel (string server_name, string channel_name, string username) {
        Idle.add (() => {
            // Display a message in the channel chat view
            var channel_chat_view = main_layout.get_channel_chat_view (channel_name);
            if (channel_chat_view != null) {
                var message = new Iridium.Services.Message ();
                message.message = username + _(" has joined");
                channel_chat_view.display_server_msg (message);
            }
            update_channel_users_list (server_name, channel_name);
            return false;
        });
    }

    private void on_user_left_channel (string server_name, string channel_name, string username) {
        Idle.add (() => {
            // Display a message in the channel chat view
            var channel_chat_view = main_layout.get_channel_chat_view (channel_name);
            if (channel_chat_view != null) {
                var message = new Iridium.Services.Message ();
                message.message = username + _(" has left");
                channel_chat_view.display_server_msg (message);
            }
            update_channel_users_list (server_name, channel_name);
            return false;
        });
    }

    private void on_direct_message_received (string server_name, string username, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_direct_message_chat_view (username);
            if (chat_view == null) {
                chat_view = new Iridium.Views.DirectMessageChatView ();
                main_layout.add_chat_view (chat_view, username);
                chat_view.message_to_send.connect ((user_message) => {
                    send_channel_message (server_name, username, user_message, chat_view);
                });
            }
            side_panel.add_direct_message (server_name, username);
            chat_view.display_priv_msg (message);
            side_panel.increment_channel_badge (server_name, username);
            return false;
        });
    }

    private void update_channel_users_list (string server_name, string channel_name) {
        // Check if the current view matches the server and channel
        var selected_row = side_panel.get_selected_row ();
        if (selected_row == null) {
            return;
        }
        if (selected_row.get_server_name () == server_name && selected_row.get_channel_name () == channel_name) {
            var usernames = connection_handler.get_users (server_name, channel_name);
            header_bar.set_channel_users (usernames);
        }
    }

}
