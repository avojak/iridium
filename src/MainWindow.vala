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
        connection_handler.nickname_in_use.connect (on_nickname_in_use);
        connection_handler.channel_joined.connect (on_channel_joined);
        connection_handler.channel_left.connect (on_channel_left);
        connection_handler.channel_message_received.connect (on_channel_message_received);

        // Close connections when the window is closed
        this.destroy.connect (() => {
            // TODO: Not sure if this is right...
            connection_handler.close_all_connections ();
            GLib.Process.exit (0);
        });
    }

    private void show_server_connection_dialog () {
        if (connection_dialog == null) {
            connection_dialog = new Iridium.Widgets.ServerConnectionDialog (this);
            connection_dialog.show_all ();
            connection_dialog.connect_button_clicked.connect ((server, nickname, username, realname) => {
                // Prevent duplicate connections
                if (connection_handler.has_connection (server)) {
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
            channel_join_dialog.display_error ("Channel must begin with '#' or '&'");
            return;
        }
        connection_handler.join_channel (server_name, channel_name);
    }

    private void send_user_message (string server_name, string channel_name, string text, Iridium.Views.ChatView chat_view) {
        // Send the message
        var message_text = "PRIVMSG " + channel_name + " :" + text;
        connection_handler.send_user_message (server_name, message_text);
        // Display the message in the chat view
        var message = new Iridium.Services.Message (message_text);
        message.username = connection_handler.get_nickname (server_name);
        chat_view.display_self_priv_msg (message);
    }

    //
    // ServerConnectionHandler Callbacks
    //

    private void on_server_connection_successful (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_chat_view (server_name);
            if (chat_view == null) {
                chat_view = new Iridium.Views.ChatView ();
                chat_view.message_to_send.connect ((message_to_send) => {
                    send_user_message (server_name, server_name, message_to_send, chat_view);
                });
                main_layout.add_chat_view (chat_view, server_name);
            }

            chat_view.display_server_msg (message);
            if (connection_dialog != null) {
                connection_dialog.dismiss ();
            }
            side_panel.add_server (server_name);
            main_layout.show_chat_view (server_name);
            show_channel_join_dialog ();
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
    }

    private void on_server_message_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            var chat_view = main_layout.get_chat_view (server_name);
            // For some NOTICEs, the server ChatView has not yet been created,
            // because we haven't yet received the 001 WELCOME
            if (chat_view != null) {
                chat_view.display_server_msg (message);
            }
            return false;
        });
    }

    private void on_server_error_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            var chat_view = main_layout.get_chat_view (server_name);
            // For some NOTICEs, the server ChatView has not yet been created,
            // because we haven't yet received the 001 WELCOME
            if (chat_view != null) {
                chat_view.display_server_error_msg (message);
            }
            return false;
        });
    }

    private void on_server_quit (string server_name, string message) {
        connection_handler.disconnect_from_server (server_name);
    }

    private void on_nickname_in_use (string server_name, Iridium.Services.Message message) {
        if (connection_dialog != null) {
            // TODO: Should this be outside the if-statement?
            connection_handler.disconnect_from_server (server_name);
            connection_dialog.display_error ("Nickname already in use.");
        } else {
            // TODO: This should be an error
            /* main_layout.get_chat_view (server_name).add_message (message, false); */
            main_layout.get_chat_view (server_name).display_server_error_msg (message);
            // TODO: Prompt for new nickname?
        }
    }

    private void on_channel_joined (string server_name, string channel_name) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_chat_view (channel_name);
            if (chat_view == null) {
                chat_view = new Iridium.Views.ChatView ();
                main_layout.add_chat_view (chat_view, channel_name);
                chat_view.message_to_send.connect ((user_message) => {
                    /* send_user_message (server_connection, chat_view, channel_name, user_message); */
                    send_user_message (server_name, channel_name, user_message, chat_view);
                });
            }

            if (channel_join_dialog != null) {
                channel_join_dialog.dismiss ();
            }
            side_panel.add_channel (server_name, channel_name);
            main_layout.show_chat_view (channel_name);
            return false;
        });
    }

    private void on_channel_left (string server_name, string channel_name) {
        // TODO: Display a message that we've left the channel
        // TODO: Disable the channel row
    }

    private void on_channel_message_received (string server_name, string channel_name, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_chat_view (channel_name);
            if (chat_view == null) {
                chat_view = new Iridium.Views.ChatView ();
                main_layout.add_chat_view (chat_view, channel_name);
                chat_view.message_to_send.connect ((user_message) => {
                    /* send_user_message (server_connection, chat_view, channel_name, user_message); */
                    send_user_message (server_name, channel_name, user_message, chat_view);
                });
                side_panel.add_channel (server_name, channel_name);
                // TODO: Remove this line eventually - it's annoying!
                main_layout.show_chat_view (channel_name);
            }
            chat_view.display_priv_msg (message);
            return false;
        });
    }

}
