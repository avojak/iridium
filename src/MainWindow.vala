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
    //  public Iridium.Widgets.PreferencesDialog? preferences_dialog = null;

    private Iridium.Views.Welcome welcome_view;
    private Iridium.Widgets.HeaderBar header_bar;
    private Iridium.Widgets.SidePanel.Panel side_panel;
    private Iridium.Widgets.StatusBar status_bar;
    private Iridium.Layouts.MainLayout main_layout;

    private Gtk.Overlay overlay;
    private Granite.Widgets.OverlayBar overlay_bar;

    private Iridium.Widgets.NetworkInfoBar network_info_bar;

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
        header_bar.set_channel_users_button_visible (false);
        set_titlebar (header_bar);

        network_info_bar = new Iridium.Widgets.NetworkInfoBar ();
        network_info_bar.show ();

        welcome_view = new Iridium.Views.Welcome ();
        side_panel = new Iridium.Widgets.SidePanel.Panel ();
        status_bar = new Iridium.Widgets.StatusBar ();
        main_layout = new Iridium.Layouts.MainLayout (welcome_view, side_panel, status_bar);

        var grid = new Gtk.Grid ();

        overlay = new Gtk.Overlay ();
        overlay.add (main_layout);
        overlay.show ();

        grid.attach (network_info_bar, 0, 0, 1, 1);
        grid.attach (overlay, 0, 1, 1, 1);

        add (grid);

        resize (1000, 600);

        // Connect to signals
        //  header_bar.server_connect_button_clicked.connect (() => {
        //      show_server_connection_dialog ();
        //  });
        //  header_bar.channel_join_button_clicked.connect (() => {
        //      show_channel_join_dialog ();
        //  });
        //  header_bar.preferences_button_clicked.connect (() => {
        //      show_preferences_dialog ();
        //  });
        header_bar.username_selected.connect (on_username_selected);
        //  header_bar.channel_topic_toggled.connect (on_channel_topic_toggled);
        side_panel.item_selected.connect ((item) => {
            // No item selected
            if (item == null) {
                //  header_bar.set_channel_join_button_enabled (false);
                main_layout.show_welcome_view ();
                return;
            }

            // Item selected
            unowned Iridium.Widgets.SidePanel.Row row = (Iridium.Widgets.SidePanel.Row) item;
            var server_name = row.get_server_name ();
            var channel_name = row.get_channel_name ();
            main_layout.show_chat_view (server_name, channel_name);

            // Update the header bar title
            if (channel_name != null) {
                header_bar.update_title (channel_name, server_name);
            } else {
                header_bar.update_title (server_name, null);
            }

            // Show or hide the channel users and topic buttons in the header
            if (item is Iridium.Widgets.SidePanel.ChannelRow) {
                header_bar.set_channel_users_button_visible (true);
                header_bar.set_channel_users_button_enabled (row.get_enabled ());

                // Update the channel users list
                update_channel_users_list (server_name, channel_name);
                update_channel_topic (server_name, channel_name);
                
                var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
                channel_chat_view.set_topic_edit_button_enabled (row.get_enabled ());
            } else {
                header_bar.set_channel_users_button_visible (false);
            }

            // We have enough context to join a channel
            // TODO: This should probably still be enabled as long as there's
            //       at least one open connection.
            //  header_bar.set_channel_join_button_enabled (true);
        });
        side_panel.connect_to_server.connect ((server_name) => {
            var connection_details = get_connection_details_for_server (server_name);
            if (connection_details == null) {
                return;
            }

            var server_connection = connection_handler.connect_to_server (connection_details);
            Idle.add (() => {
                side_panel.updating_server_row (server_name);
                return false;
            });
            server_connection.open_successful.connect (() => {
                Idle.add (() => {
                    side_panel.select_server_row (server_name);
                    return false;
                });
            });
        });
        side_panel.disconnect_from_server.connect ((server_name) => {
            // TODO: Might need to disable the join channel header button!
            connection_handler.disconnect_from_server (server_name);
        });
        side_panel.join_channel_for_server.connect ((server_name) => {
            show_channel_join_dialog (server_name);
        });
        side_panel.join_channel.connect ((server_name, channel_name) => {
            // If we're not connected to the server yet, connect to it first before joining the channel
            if (!connection_handler.has_connection (server_name)) {
                var connection_details = get_connection_details_for_server (server_name);
                if (connection_details == null) {
                    // TODO: Handle this
                    return;
                }
                var server_connection = connection_handler.connect_to_server (connection_details);
                Idle.add (() => {
                    side_panel.updating_server_row (server_name);
                    return false;
                });
                server_connection.open_successful.connect (() => {
                    Idle.add (() => {
                        side_panel.updating_channel_row (server_name, channel_name);
                        return false;
                    });
                    connection_handler.join_channel (server_name, channel_name);
                });
            } else {
                Idle.add (() => {
                    side_panel.updating_channel_row (server_name, channel_name);
                    return false;
                });
                connection_handler.join_channel (server_name, channel_name);
            }
        });
        side_panel.leave_channel.connect ((server_name, channel_name) => {
            connection_handler.leave_channel (server_name, channel_name);
        });
        status_bar.server_connect_button_clicked.connect (() => {
            show_server_connection_dialog ();
        });
        status_bar.channel_join_button_clicked.connect (() => {
            show_channel_join_dialog (side_panel.get_current_server ());
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
        connection_handler.channel_users_received.connect (on_channel_users_received);
        connection_handler.channel_topic_received.connect (on_channel_topic_received);
        connection_handler.nickname_in_use.connect (on_nickname_in_use);
        connection_handler.channel_joined.connect (on_channel_joined);
        connection_handler.channel_left.connect (on_channel_left);
        connection_handler.channel_message_received.connect (on_channel_message_received);
        connection_handler.user_joined_channel.connect (on_user_joined_channel);
        connection_handler.user_left_channel.connect (on_user_left_channel);
        connection_handler.private_message_received.connect (on_private_message_received);

        // Connect to all of the side panel signals to make settings changes
        side_panel.server_row_added.connect (Iridium.Application.connection_dao.on_server_row_added);
        side_panel.server_row_removed.connect (Iridium.Application.connection_dao.on_server_row_removed);
        side_panel.server_row_enabled.connect (Iridium.Application.connection_dao.on_server_row_enabled);
        side_panel.server_row_disabled.connect (Iridium.Application.connection_dao.on_server_row_disabled);
        side_panel.channel_row_added.connect (Iridium.Application.connection_dao.on_channel_row_added);
        side_panel.channel_row_removed.connect (Iridium.Application.connection_dao.on_channel_row_removed);
        side_panel.channel_row_enabled.connect (Iridium.Application.connection_dao.on_channel_row_enabled);
        side_panel.channel_row_disabled.connect (Iridium.Application.connection_dao.on_channel_row_disabled);
        side_panel.channel_favorite_added.connect (Iridium.Application.connection_dao.on_channel_favorite_added);
        side_panel.channel_favorite_removed.connect (Iridium.Application.connection_dao.on_channel_favorite_removed);

        // Connect to the connection handler signal to make settings changes for new connections
        connection_handler.server_connection_successful.connect ((server_name, message) => {
            var connection_details = connection_handler.get_connection_details (server_name);
            Iridium.Application.connection_dao.on_server_connection_successful (connection_details);
        });

        // Close connections when the window is closed
        this.destroy.connect (() => {
            // Disconnect this signal so that we don't modify the setting to
            // show servers as disabled, when in reality they were enabled prior
            // to closing the application.
            side_panel.server_row_disabled.disconnect (Iridium.Application.connection_dao.on_server_row_disabled);

            // TODO: Not sure if this is right...
            connection_handler.close_all_connections ();
            GLib.Process.exit (0);
        });
    }

    private Iridium.Services.ServerConnectionDetails? get_connection_details_for_server (string server_name) {
        foreach (Iridium.Services.Server server in Iridium.Application.connection_dao.get_servers ()) {
            if (server.connection_details.server == server_name) {
                return server.connection_details;
            }
        }
        return null;
    }

    // TODO: Restore private messages from the side panel
    public void initialize (Gee.List<Iridium.Services.Server> servers, Gee.List<Iridium.Services.Channel> channels) {
        begin_initialization ();

        // Handle case were there's nothing to initialize!
        if (servers.size == 0) {
            on_initialization_complete ();
            return;
        }

        // Map the server names to their initialization status (success or fail)
        Gee.Map<string, bool> initialization_status = new Gee.HashMap<string, bool> ();
        var num_enabled_servers = 0;
        foreach (Iridium.Services.Server server in servers) {
            if (server.enabled) {
                num_enabled_servers++;
            }
        }

        // Initialize the UI with disabled rows and chat views for everything
        foreach (Iridium.Services.Server server in servers) {
            var server_id = server.id;
            var server_name = server.connection_details.server;
            Idle.add (() => {
                side_panel.add_server (server_name);
                side_panel.disable_server_row (server_name);
                return false;
            });
            Idle.add (() => {
                var chat_view = create_and_add_server_chat_view (server_name);
                chat_view.set_enabled (false);
                return false;
            });
            foreach (Iridium.Services.Channel channel in channels) {
                //  var channel_id = channel.id;
                var channel_server_id = channel.server_id;
                var channel_name = channel.name;
                if (channel_server_id != server_id) {
                    // This channel isn't for the current server
                    continue;
                }
                Idle.add (() => {
                    side_panel.add_channel (server_name, channel_name);
                    side_panel.disable_channel_row (server_name, channel_name);
                    if (channel.favorite) {
                        side_panel.favorite_channel (server_name, channel_name);
                    }
                    return false;
                });
                Idle.add (() => {
                    var chat_view = create_and_add_channel_chat_view (server_name, channel_name);
                    chat_view.set_enabled (false);
                    return false;
                });
            }
        }

        // Open connections to enabled servers
        foreach (Iridium.Services.Server server in servers) {
            var server_id = server.id;
            var connection_details = server.connection_details;
            var server_name = connection_details.server;
            var server_enabled = server.enabled;
            if (!server_enabled) {
                continue;
            }
            var server_connection = connection_handler.connect_to_server (connection_details);
            Idle.add (() => {
                side_panel.updating_server_row (server_name);
                return false;
            });
            server_connection.open_successful.connect (() => {
                foreach (Iridium.Services.Channel channel in channels) {
                    //  var channel_id = channel.id;
                    var channel_server_id = channel.server_id;
                    var channel_name = channel.name;
                    var channel_enabled = channel.enabled;
                    if (channel_server_id != server_id) {
                        // This channel isn't for the current server
                        continue;
                    }
                    if (!channel_enabled) {
                        continue;
                    }
                    connection_handler.join_channel (server_name, channel_name);
                    Idle.add (() => {
                        side_panel.updating_channel_row (server_name, channel_name);
                        return false;
                    });
                }

            });
            server_connection.open_successful.connect (() => {
                initialization_status.set (server_name, true);
                if (initialization_status.size == num_enabled_servers) {
                    on_initialization_complete ();
                }
            });
            server_connection.open_failed.connect (() => {
                // TODO: Give some user feedback, maybe a toast? Don't want the UI to get too busy though
                initialization_status.set (server_name, false);
                if (initialization_status.size == num_enabled_servers) {
                    on_initialization_complete ();
                }
            });
        }

        // We've initialized the UI, but if there aren't any connections to wait on, we're done
        if (num_enabled_servers == 0) {
            on_initialization_complete ();
            return;
        }

    }

    private void begin_initialization () {
        if (overlay_bar == null) {
            overlay_bar = new Granite.Widgets.OverlayBar (overlay);
            overlay_bar.label = "Restoring server connections";
            overlay_bar.active = true;
            overlay.show_all ();
        }
    }

    private void on_initialization_complete () {
        Idle.add (() => {
            if (overlay_bar != null) {
                overlay_bar.destroy ();
            }
            return false;
        });
    }

    private Iridium.Views.ServerChatView create_and_add_server_chat_view (string server_name) {
        var chat_view = new Iridium.Views.ServerChatView ();
        main_layout.add_server_chat_view (chat_view, server_name);
        chat_view.message_to_send.connect ((message_to_send) => {
            send_server_message (server_name, message_to_send, chat_view);
        });
        return chat_view;
    }

    private Iridium.Views.ChannelChatView create_and_add_channel_chat_view (string server_name, string channel_name) {
        var chat_view = new Iridium.Views.ChannelChatView (this);
        main_layout.add_channel_chat_view (chat_view, server_name, channel_name);
        chat_view.message_to_send.connect ((user_message) => {
            send_channel_message (server_name, channel_name, user_message, chat_view);
        });
        chat_view.set_topic.connect ((new_topic) => {
            connection_handler.set_channel_topic (server_name, channel_name, new_topic);
        });
        return chat_view;
    }

    private Iridium.Views.PrivateMessageChatView create_and_add_private_message_chat_view (string server_name, string username) {
        var chat_view = new Iridium.Views.PrivateMessageChatView ();
        main_layout.add_private_message_chat_view (chat_view, server_name, username);
        chat_view.message_to_send.connect ((user_message) => {
            send_channel_message (server_name, username, user_message, chat_view);
        });
        return chat_view;
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

    private void show_channel_join_dialog (string? target_server) {
        if (channel_join_dialog == null) {
            var connected_servers = connection_handler.get_connected_servers ();
            //  var current_server = side_panel.get_current_server ();
            channel_join_dialog = new Iridium.Widgets.ChannelJoinDialog (this, connected_servers, target_server);
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

    //  private void show_preferences_dialog () {
    //      if (preferences_dialog == null) {
    //          preferences_dialog = new Iridium.Widgets.PreferencesDialog (this);
    //          preferences_dialog.show_all ();
    //          preferences_dialog.destroy.connect (() => {
    //              preferences_dialog = null;
    //          });
    //      }
    //      preferences_dialog.present ();
    //  }

    private void join_channel (string server_name, string channel_name) {
        // Check if we're already in this channel
        if (connection_handler.get_channels (server_name).index_of (channel_name) != -1) {
            channel_join_dialog.display_error ("You've already joined this channel");
            return;
        }
        // Validate channel name
        // TODO: Look into what other restrictions exist
        if (!channel_name.has_prefix ("#") && !channel_name.has_prefix ("&")) {
            // TODO: Eventually validate that the dialog is non-null, and handle accordingly
            channel_join_dialog.display_error ("Channel must begin with '#' or '&'");
            return;
        }
        if (channel_name.length < 2) {
            channel_join_dialog.display_error ("Enter a channel name");
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
            message.message = "Start your message with a /";
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
        chat_view.display_self_private_msg (message);
    }

    private void send_server_command (string server_name, string text) {
        // TODO: Check for actions (eg. /me, etc.)
        connection_handler.send_user_message (server_name, text);
    }

    //
    // Respond to network connection changes
    //

    public void network_connection_lost () {
        network_info_bar.revealed = true;
        // TODO: Disable server and channel buttons in header bar
        connection_handler.close_all_connections ();
    }

    public void network_connection_gained () {
        // We don't attempt to restore connections currently because of how the signals
        // are fired from the network monitor. When switching Wi-Fi access points, for
        // example, there are multiple signals fired in quick succession which show
        // the connection being quick gained, lost, and then gained again:
        //
        //      network available: G_NETWORK_CONNECTIVITY_LOCAL
        //      network not available: G_NETWORK_CONNECTIVITY_LOCAL
        //      network available: G_NETWORK_CONNECTIVITY_FULL
        // 
        // This makes it rather difficult to reliably restore server connections. 
        // Furthermore, if you lose a network connection then quickly regain it, you 
        // may not even need to reconnect to the IRC server.
        network_info_bar.revealed = false;
        // TODO: Enable server and channel buttons in header bar
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
        var trimmed_username = strip_username_prefix (username);
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            if (main_layout.get_private_message_chat_view (server_name, trimmed_username) == null) {
                create_and_add_private_message_chat_view (server_name, trimmed_username);
            }
            side_panel.add_private_message (server_name, trimmed_username);
            side_panel.select_private_message_row (server_name, trimmed_username);
            return false;
        });
    }

    private string strip_username_prefix (string username) {
        var prefixes = new string[] { "@", "&" };
        foreach (string prefix in prefixes) {
            if (username.has_prefix (prefix)) {
                return username.substring(1, username.length - 1);
            }
        }
        return username;
    }

    //  private void on_channel_topic_toggled (bool visible) {
    //      // Check if the current view matches the server and channel
    //      var selected_row = side_panel.get_selected_row ();
    //      if (selected_row == null) {
    //          return;
    //      }
    //      if (selected_row.get_channel_name () == null) {
    //          return;
    //      }
    //      var channel_chat_view = main_layout.get_channel_chat_view (selected_row.get_server_name (), selected_row.get_channel_name ());
    //      if (channel_chat_view == null) {
    //          return;
    //      }
    //      if (visible) {
    //          channel_chat_view.show_topic ();
    //      } else {
    //          channel_chat_view.hide_topic ();
    //      }
    //  }

    //
    // ServerConnectionHandler Callbacks
    //

    private void on_server_connection_successful (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_server_chat_view (server_name);
            if (chat_view == null) {
                chat_view = create_and_add_server_chat_view (server_name);
            }
            chat_view.set_enabled (true);
            chat_view.display_server_msg (message);

            side_panel.add_server (server_name);
            side_panel.enable_server_row (server_name);
            // TODO: Maybe only do these two things if the dialog was open?
            /* main_layout.show_chat_view (server_name);
            show_channel_join_dialog (); */
            if (connection_dialog != null) {
                connection_dialog.dismiss ();

                side_panel.select_server_row (server_name);
                show_channel_join_dialog (server_name);
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
        // TODO: Implement - display disconnect message
        Idle.add (() => {
            var chat_view = main_layout.get_server_chat_view (server_name);
            if (chat_view != null) {
                chat_view.set_enabled (false);
            }
            return false;
        });
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
                var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel);
                if (channel_chat_view != null) {
                    var message_to_display = new Iridium.Services.Message ();
                    message_to_display.message = username + " has quit";
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
            var private_message_chat_view = main_layout.get_private_message_chat_view (server_name, username);
            if (private_message_chat_view != null) {
                var message_to_display = new Iridium.Services.Message ();
                message_to_display.message = username + " has quit";
                if (message.message != null && message.message.strip () != "") {
                    message_to_display.message += " (" + message.message + ")";
                }
                private_message_chat_view.display_server_msg (message_to_display);
            }
            return false;
        });
    }

    private void on_channel_users_received (string server_name, string channel_name) {
        update_channel_users_list (server_name, channel_name);
    }

    private void on_channel_topic_received (string server_name, string channel_name) {
        update_channel_topic (server_name, channel_name);
    }

    private void on_nickname_in_use (string server_name, Iridium.Services.Message message) {
        if (connection_dialog != null) {
            // TODO: Should this be outside the if-statement?
            connection_handler.disconnect_from_server (server_name);
            connection_dialog.display_error ("Nickname already in use.");
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
            var chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
            if (chat_view == null) {
                chat_view = create_and_add_channel_chat_view (server_name, channel_name);
            }
            chat_view.set_enabled (true);
            chat_view.set_topic_edit_button_enabled (true);

            side_panel.add_channel (server_name, channel_name);
            side_panel.enable_channel_row (server_name, channel_name);
            // TODO: Maybe only do this if the dialog was open?
            //       Might also be able to surround this with an initializing
            //       boolean check (ie. only select if we're not initializing).
            /* side_panel.select_channel_row (server_name, channel_name); */
            if (channel_join_dialog != null) {
                var is_favorite = channel_join_dialog.is_favorite_button_selected ();
                channel_join_dialog.dismiss ();
                if (is_favorite) {
                    side_panel.favorite_channel (server_name, channel_name);
                }
                side_panel.select_channel_row (server_name, channel_name);
            }

            set_channel_users_button_enabled (server_name, channel_name, true);
            return false;
        });
    }

    private void on_channel_left (string server_name, string channel_name) {
        // TODO: Display a message that we've left the channel
        Idle.add (() => {
            var chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
            if (chat_view != null) {
                chat_view.set_enabled (false);
                chat_view.set_topic_edit_button_enabled (false);
            }
            return false;
        });

        side_panel.disable_channel_row (server_name, channel_name);
        //  update_channel_users_list (server_name, channel_name);
        set_channel_users_button_enabled (server_name, channel_name, false);
    }

    private void on_channel_message_received (string server_name, string channel_name, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
            if (chat_view == null) {
                chat_view = create_and_add_channel_chat_view (server_name, channel_name);
            }
            chat_view.set_enabled (true);
            side_panel.add_channel (server_name, channel_name);
            chat_view.display_private_msg (message);
            side_panel.increment_channel_badge (server_name, channel_name);
            return false;
        });
    }

    private void on_user_joined_channel (string server_name, string channel_name, string username) {
        Idle.add (() => {
            // Display a message in the channel chat view
            var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
            if (channel_chat_view != null) {
                var message = new Iridium.Services.Message ();
                message.message = username + " has joined";
                channel_chat_view.display_server_msg (message);
            }
            update_channel_users_list (server_name, channel_name);
            return false;
        });
    }

    private void on_user_left_channel (string server_name, string channel_name, string username) {
        Idle.add (() => {
            // Display a message in the channel chat view
            var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
            if (channel_chat_view != null) {
                var message = new Iridium.Services.Message ();
                message.message = username + " has left";
                channel_chat_view.display_server_msg (message);
            }
            update_channel_users_list (server_name, channel_name);
            return false;
        });
    }

    private void on_private_message_received (string server_name, string username, Iridium.Services.Message message) {
        Idle.add (() => {
            // Check if the chat view already exists before creating a new one
            var chat_view = main_layout.get_private_message_chat_view (server_name, username);
            if (chat_view == null) {
                chat_view = create_and_add_private_message_chat_view (server_name, username);
            }
            chat_view.set_enabled (true);
            side_panel.add_private_message (server_name, username);
            chat_view.display_private_msg (message);
            side_panel.increment_channel_badge (server_name, username);
            return false;
        });
    }

    private void update_channel_users_list (string server_name, string channel_name) {
        var usernames = connection_handler.get_users (server_name, channel_name);

        // Update the users for the channel chat view so it knows which usernames 
        // to display in a different style. Do this regardless of whether the view
        // is currently selected and displayed.
        var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
        if (channel_chat_view != null) {
            channel_chat_view.set_usernames (usernames);
        }

        // Check if the current view matches the server and channel
        var selected_row = side_panel.get_selected_row ();
        if (selected_row == null) {
            return;
        }
        if (selected_row.get_server_name () == server_name && selected_row.get_channel_name () == channel_name) {
            header_bar.set_channel_users (usernames);
        }
    }

    private void set_channel_users_button_enabled (string server_name, string channel_name, bool enabled) {
        var selected_row = side_panel.get_selected_row ();
        if (selected_row == null) {
            return;
        }
        if (selected_row.get_server_name () == server_name && selected_row.get_channel_name () == channel_name) {
            header_bar.set_channel_users_button_enabled (enabled);
        }
    }
    
    private void update_channel_topic (string server_name, string channel_name) {
        var topic = connection_handler.get_topic (server_name, channel_name);
        // Ensures that this runs only after the channel chat view has been created and added to the main layout
        Idle.add (() => {
            var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
            if (channel_chat_view != null) {
                channel_chat_view.set_channel_topic (topic);
            }
            return false;
        });
    }

}
