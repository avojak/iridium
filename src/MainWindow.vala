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

    public Iridium.Widgets.ServerConnectionDialog? connection_dialog = null;
    public Iridium.Widgets.ChannelJoinDialog? channel_join_dialog = null;

    private Iridium.Views.Welcome welcome_view;
    private Iridium.Widgets.HeaderBar header_bar;
    private Iridium.Widgets.SidePanel.Panel side_panel;
    private Iridium.Layouts.MainLayout main_layout;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            border_width: 0,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        header_bar = new Iridium.Widgets.HeaderBar ();
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
        side_panel.item_selected.connect ((item) => {
            // No item selected
            if (item == null) {
                header_bar.set_channel_join_button_enabled (false);
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
            if (row.get_channel_name () != null) {
                header_bar.update_title (row.get_channel_name (), row.get_server_name ());
            } else {
                header_bar.update_title (row.get_server_name (), null);
            }

            // We have enough context to join a channel
            // TODO: This should probably still be enabled as long as there's
            //       at least one open connection.
            header_bar.set_channel_join_button_enabled (true);
        });
        welcome_view.new_connection_button_clicked.connect (() => {
            show_server_connection_dialog ();
        });

        // Close connections when the window is closed
        this.destroy.connect (() => {
            // TODO: Not sure if this is right...
            Iridium.Application.connection_handler.close_all_connections ();
            GLib.Process.exit (0);
        });
    }

    private void show_server_connection_dialog () {
        if (connection_dialog == null) {
            connection_dialog = new Iridium.Widgets.ServerConnectionDialog (this);
            connection_dialog.show_all ();
            connection_dialog.connect_button_clicked.connect ((server, nickname, username, realname) => {
                // Prevent duplicate connections
                if (Iridium.Application.connection_handler.has_connection (server)) {
                    connection_dialog.display_error ("Already connected to this server!");
                    return;
                }

                // Create the connection details
                var connection_details = new Iridium.Services.ServerConnectionDetails ();
                connection_details.server = server;
                connection_details.nickname = nickname;
                connection_details.username = username;
                connection_details.realname = realname;

                // Attempt the server connection
                // TODO: Should this be unowned?
                var server_connection = Iridium.Application.connection_handler.connect_to_server (connection_details);
                server_connection.open_successful.connect ((message) => {
                    server_connection_succcessful (server_connection, message);
                });
                // Server connection failed
                server_connection.open_failed.connect ((message) => {
                    server_connection_failed (message);
                });
                // Message received from the server
                server_connection.server_message_received.connect ((message) => {
                    server_message_received (server, message);
                });
                // Nickname already in use
                server_connection.nickname_in_use.connect ((message) => {
                    nickname_in_use (server, message);
                });
                // Channel has been joined
                server_connection.channel_joined.connect ((server_name, channel_name) => {
                    channel_joined (server_connection, channel_name);
                });
                // Channel message received
                server_connection.channel_message_received.connect ((channel_name, message) => {
                    channel_message_received (server_connection, channel_name, message);
                });
                // User has quit the server
                server_connection.server_quit.connect ((message) => {
                    server_connection.do_close ();
                    // TODO: Do we want to close the view or just show as disconnected??
                    // TODO: Remove chat views?
                    // TODO: Remove server from side panel?
                });
            });
            connection_dialog.destroy.connect (() => {
                connection_dialog = null;
            });
        }
        connection_dialog.present ();
    }

    private void show_channel_join_dialog () {
        if (channel_join_dialog == null) {
            var connected_servers = Iridium.Application.connection_handler.get_connected_servers ();
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

    private Iridium.Views.ChatView create_chat_view (string name) {
        var chat_view = new Iridium.Views.ChatView ();
        // Initialize the buffer I think? Get an error without this...
        chat_view.get_buffer ();
        return chat_view;
    }

    private void server_connection_succcessful (Iridium.Services.ServerConnection server_connection,
            Iridium.Services.Message message) {
        // TODO: Will need to eventually check if connection_dialog is null, etc.
        Idle.add (() => {
            var server_name = server_connection.connection_details.server;
            var chat_view = create_chat_view (server_name);
            chat_view.message_to_send.connect ((message_to_send) => {
                server_connection.send_user_message (message_to_send);
                send_user_message (server_connection, chat_view, server_name, message_to_send);
            });
            main_layout.add_chat_view (chat_view, server_name);
            chat_view.add_message (message, false);
            connection_dialog.dismiss ();
            side_panel.add_server (server_name);
            main_layout.show_chat_view (server_name);
            show_channel_join_dialog ();
            return false;
        });
    }

    private void server_connection_failed (string message) {
        // TODO: Will need to eventually check if connection_dialog is null, etc.
        Idle.add (() => {
            connection_dialog.display_error (message);
            return false;
        });
    }

    private void join_channel (string server_name, string channel_name) {
        // Validate channel name
        // TODO: Look into what other restrictions exist
        if (!channel_name.has_prefix ("#") && !channel_name.has_prefix ("&")) {
            // TODO: Eventually validate that the dialog is non-null, and handle accordingly
            channel_join_dialog.display_error ("Channel must begin with '#' or '&'");
            return;
        }

        Iridium.Application.connection_handler.get_connection (server_name).join_channel (channel_name);
    }

    private void channel_joined (Iridium.Services.ServerConnection server_connection, string channel_name) {
        Idle.add (() => {
            var server_name = server_connection.connection_details.server;
            var chat_view = create_chat_view (channel_name);
            main_layout.add_chat_view (chat_view, channel_name);
            chat_view.message_to_send.connect ((user_message) => {
                send_user_message (server_connection, chat_view, channel_name, user_message);
            });
            if (channel_join_dialog != null) {
                channel_join_dialog.dismiss ();
            }
            side_panel.add_channel (server_name, channel_name);
            main_layout.show_chat_view (channel_name);
            return false;
        });
    }

    private void server_message_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            var chat_view = main_layout.get_chat_view (server_name);
            // For some NOTICEs, the server ChatView has not yet been created,
            // because we haven't yet received the 001 WELCOME
            if (chat_view != null) {
                chat_view.add_message (message, false);
            }
            return false;
        });
    }

    private void channel_message_received (Iridium.Services.ServerConnection server_connection,
            string channel_name, Iridium.Services.Message message) {
        Idle.add (() => {
            var server_name = server_connection.connection_details.server;
            var chat_view = main_layout.get_chat_view (channel_name);
            if (chat_view == null) {
                chat_view = create_chat_view (channel_name);
                main_layout.add_chat_view (chat_view, channel_name);
                chat_view.message_to_send.connect ((user_message) => {
                    send_user_message (server_connection, chat_view, channel_name, user_message);
                });
                side_panel.add_channel (server_name, channel_name);
                // TODO: Remove this line, it's annoying!
                main_layout.show_chat_view (channel_name);
            }
            chat_view.add_message (message, false);
            return false;
        });
    }

    private void nickname_in_use (string server_name, Iridium.Services.Message message) {
        if (connection_dialog != null) {
            Iridium.Application.connection_handler.disconnect_from_server (server_name);
            connection_dialog.display_error ("Nickname already in use.");
        } else {
            main_layout.get_chat_view (server_name).add_message (message, false);
            // TODO: Prompt for new nickname?
        }
    }

    private void send_user_message (Iridium.Services.ServerConnection server_connection,
            Iridium.Views.ChatView chat_view, string channel_name, string text) {
        // Send the message
        var message_text = "PRIVMSG " + channel_name + " :" + text;
        server_connection.send_user_message (message_text);
        // Display the message in the chat view
        var message = new Iridium.Services.Message (message_text);
        message.username = server_connection.connection_details.nickname;
        chat_view.add_message (message, true);
    }

}
