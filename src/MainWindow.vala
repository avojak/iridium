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

    public unowned Iridium.Application app { get; construct; }

    private Iridium.Services.ActionManager action_manager;
    private Gtk.AccelGroup accel_group;

    private Iridium.Widgets.ServerConnectionDialog? connection_dialog = null;
    private Iridium.Widgets.ChannelJoinDialog? channel_join_dialog = null;
    private Iridium.Widgets.ChannelTopicEditDialog? channel_topic_edit_dialog = null;
    //  private Iridium.Widgets.ManageConnectionsDialog? manage_connections_dialog = null;
    private Iridium.Widgets.PreferencesDialog? preferences_dialog = null;
    private Iridium.Widgets.NicknameEditDialog? nickname_edit_dialog = null;

    private Iridium.Widgets.HeaderBar header_bar;
    private Iridium.Layouts.MainLayout main_layout;

    public MainWindow (Iridium.Application application) {
        Object (
            application: application,
            app: application,
            border_width: 0,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        accel_group = new Gtk.AccelGroup ();
        add_accel_group (accel_group);
        action_manager = new Iridium.Services.ActionManager (app, this);

        header_bar = new Iridium.Widgets.HeaderBar ();
        header_bar.set_channel_users_button_visible (false);
        set_titlebar (header_bar);

        main_layout = new Iridium.Layouts.MainLayout (this);
        add (main_layout);

        resize (1000, 600);

        // Connect to main layout signals
        main_layout.welcome_view_shown.connect (on_welcome_view_shown);
        main_layout.server_chat_view_shown.connect (on_server_chat_view_shown);
        main_layout.channel_chat_view_shown.connect (on_channel_chat_view_shown);
        main_layout.private_message_chat_view_shown.connect (on_private_message_chat_view_shown);
        main_layout.server_message_to_send.connect (on_server_message_to_send);
        main_layout.channel_message_to_send.connect (on_channel_message_to_send);
        main_layout.private_message_to_send.connect (on_private_message_to_send);
        main_layout.nickname_button_clicked.connect (on_nickname_button_clicked);
        main_layout.join_channel_button_clicked.connect (on_join_channel_button_clicked);
        main_layout.leave_channel_button_clicked.connect (on_leave_channel_button_clicked);
        main_layout.connect_to_server_button_clicked.connect (on_connect_to_server_button_clicked);
        main_layout.disconnect_from_server_button_clicked.connect (on_disconnect_from_server_button_clicked);
        main_layout.edit_channel_topic_button_clicked.connect (on_edit_channel_topic_button_clicked);

        // Connect to header signals
        header_bar.nickname_selected.connect (on_nickname_selected);

        // Connect to connection handler signals
        Iridium.Application.connection_manager.unacceptable_certificate.connect (on_unacceptable_certificate);
        Iridium.Application.connection_manager.server_connection_successful.connect (on_server_connection_successful);
        Iridium.Application.connection_manager.server_connection_failed.connect (on_server_connection_failed);
        Iridium.Application.connection_manager.server_connection_closed.connect (on_server_connection_closed);
        Iridium.Application.connection_manager.server_message_received.connect (on_server_message_received);
        Iridium.Application.connection_manager.server_error_received.connect (on_server_error_received);
        Iridium.Application.connection_manager.server_quit.connect (on_server_quit);
        Iridium.Application.connection_manager.user_quit_server.connect (on_user_quit_server);
        Iridium.Application.connection_manager.channel_users_received.connect (on_channel_users_received);
        Iridium.Application.connection_manager.channel_topic_received.connect (on_channel_topic_received);
        Iridium.Application.connection_manager.nickname_in_use.connect (on_nickname_in_use);
        Iridium.Application.connection_manager.erroneous_nickname.connect (on_erroneous_nickname);
        Iridium.Application.connection_manager.channel_joined.connect (on_channel_joined);
        Iridium.Application.connection_manager.channel_left.connect (on_channel_left);
        Iridium.Application.connection_manager.channel_message_received.connect (on_channel_message_received);
        Iridium.Application.connection_manager.user_joined_channel.connect (on_user_joined_channel);
        Iridium.Application.connection_manager.user_left_channel.connect (on_user_left_channel);
        Iridium.Application.connection_manager.private_message_received.connect (on_private_message_received);
        Iridium.Application.connection_manager.insufficient_privs_received.connect (on_insufficient_privs_received);
        Iridium.Application.connection_manager.nickname_changed.connect (on_nickname_changed);
        Iridium.Application.connection_manager.nickname_changed.connect (Iridium.Application.connection_repository.on_nickname_changed);
        Iridium.Application.connection_manager.user_changed_nickname.connect (on_user_changed_nickname);
        Iridium.Application.connection_manager.network_name_received.connect (on_network_name_received);
        Iridium.Application.connection_manager.network_name_received.connect (Iridium.Application.connection_repository.on_network_name_received);

        // Connect to the connection handler signal to make settings changes for new connections
        Iridium.Application.connection_manager.server_connection_successful.connect ((server_name, message) => {
            var connection_details = Iridium.Application.connection_manager.get_connection_details (server_name);
            Iridium.Application.connection_repository.on_server_connection_successful (connection_details);
        });

        // Connect to the connection handler signal to store the password as a secret for new connections
        Iridium.Application.connection_manager.server_connection_successful.connect ((server_name, message) => {
            var connection_details = Iridium.Application.connection_manager.get_connection_details (server_name);
            if (connection_details.auth_token == null) {
                return;
            }
            if (connection_details.auth_method == Iridium.Models.AuthenticationMethod.NONE) {
                return;
            }
            try {
                Iridium.Application.secret_manager.store_secret (connection_details.server, connection_details.port, connection_details.nickname, connection_details.auth_token);
            } catch (GLib.Error e) {
                warning ("Error while storing secret: %s", e.message);
            }
        });

        // Close connections when the window is closed
        this.destroy.connect (() => {
            //  // Disconnect this signal so that we don't modify the setting to
            //  // show servers as disabled, when in reality they were enabled prior
            //  // to closing the application.
            //  main_layout.side_panel.server_row_disabled.disconnect (Iridium.Application.connection_repository.on_server_row_disabled);

            // TODO: Not sure if this is right…
            Iridium.Application.connection_manager.close_all_connections ();
            GLib.Process.exit (0);
        });

        show_app ();
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }

    private Iridium.Services.ServerConnectionDetails? get_connection_details_for_server (string server_name) {
        foreach (Iridium.Services.Server server in Iridium.Application.connection_repository.get_servers ()) {
            if (server.connection_details.server == server_name) {
                return server.connection_details;
            }
        }
        return null;
    }

    // TODO: Restore private messages from the side panel
    public void initialize (Gee.List<Iridium.Services.Server> servers, Gee.List<Iridium.Services.Channel> channels, bool is_reconnecting) {
        main_layout.show_initialization_overlay ();

        // Handle case were there's nothing to initialize!
        if (servers.size == 0) {
            main_layout.hide_initialization_overlay ();
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
        if (!is_reconnecting) {
            debug ("Initializing side panel and chat views...");
            foreach (Iridium.Services.Server server in servers) {
                var server_id = server.id;
                var server_name = server.connection_details.server;
                Idle.add (() => {
                    main_layout.add_server_chat_view (server_name, server.connection_details.nickname, server.network_name != null ? server.network_name : null);
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
                        main_layout.add_channel_chat_view (server_name, channel_name, server.connection_details.nickname);
                        if (channel.favorite) {
                            main_layout.favorite_channel (server_name, channel_name);
                        }
                        return false;
                    });
                }
            }
        }

        if (is_reconnecting) {
            debug ("Attempting reconnection for %d servers", num_enabled_servers);
        }

        // Open connections to enabled servers
        debug ("Opening server connections...");
        foreach (Iridium.Services.Server server in servers) {
            var server_id = server.id;
            var connection_details = server.connection_details;
            var server_name = connection_details.server;
            var server_enabled = server.enabled;
            if (!server_enabled) {
                continue;
            }
            var server_connection = Iridium.Application.connection_manager.connect_to_server (connection_details);
            main_layout.updating_server (server_name);
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
                    Iridium.Application.connection_manager.join_channel (server_name, channel_name);
                    main_layout.updating_channel (server_name, channel_name);
                }

            });
            server_connection.open_successful.connect (() => {
                initialization_status.set (server_name, true);
                if (initialization_status.size == num_enabled_servers) {
                    main_layout.hide_initialization_overlay ();
                }
            });
            server_connection.open_failed.connect (() => {
                // TODO: Give some user feedback, maybe a toast? Don't want the UI to get too busy though
                initialization_status.set (server_name, false);
                if (initialization_status.size == num_enabled_servers) {
                    debug ("Initialization complete");
                    main_layout.hide_initialization_overlay ();
                }
            });
        }

        // We've initialized the UI, but if there aren't any connections to wait on, we're done
        if (num_enabled_servers == 0) {
            debug ("Initialization complete");
            main_layout.hide_initialization_overlay ();
            return;
        }

    }

    public void show_server_connection_dialog () {
        if (connection_dialog == null) {
            connection_dialog = new Iridium.Widgets.ServerConnectionDialog (this);
            connection_dialog.show_all ();
            connection_dialog.connect_button_clicked.connect ((server, nickname, realname, port, auth_method, tls, auth_token) => {
                // Prevent duplicate connections
                if (Iridium.Application.connection_manager.has_connection (server)) {
                    connection_dialog.display_error (_("Already connected to this server!"));
                    return;
                }

                // Create the connection details
                var connection_details = new Iridium.Services.ServerConnectionDetails ();
                connection_details.server = server;
                connection_details.port = port;
                connection_details.nickname = nickname;
                connection_details.username = nickname; // Keep these the same for now
                connection_details.realname = realname;
                connection_details.auth_method = auth_method;
                connection_details.auth_token = auth_token;
                connection_details.tls = tls;

                // Attempt the server connection
                Iridium.Application.connection_manager.connect_to_server (connection_details);
            });
            connection_dialog.destroy.connect (() => {
                connection_dialog = null;
            });
        }
        connection_dialog.present ();
    }

    public void show_channel_join_dialog (string? target_server) {
        if (channel_join_dialog == null) {
            var connected_servers = Iridium.Application.connection_manager.get_connected_servers ();
            var network_names = Iridium.Application.connection_manager.get_connected_server_network_names ();
            channel_join_dialog = new Iridium.Widgets.ChannelJoinDialog (this, connected_servers, network_names, target_server);
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

    private void show_channel_topic_edit_dialog (string server_name, string channel_name) {
        if (channel_topic_edit_dialog == null) {
            var current_topic = Iridium.Application.connection_manager.get_topic (server_name, channel_name);
            channel_topic_edit_dialog = new Iridium.Widgets.ChannelTopicEditDialog (this, current_topic);
            channel_topic_edit_dialog.show_all ();
            channel_topic_edit_dialog.submit_button_clicked.connect ((new_topic) => {
                var trimmed_topic = new_topic == null ? "" : new_topic.chomp ().chug ();
                Iridium.Application.connection_manager.set_channel_topic (server_name, channel_name, trimmed_topic);
            });
            channel_topic_edit_dialog.destroy.connect (() => {
                channel_topic_edit_dialog = null;
            });
        }
        channel_topic_edit_dialog.present ();
    }

    //  private void show_manage_connections_dialog () {
    //      if (manage_connections_dialog == null) {
    //          var servers = Iridium.Application.connection_repository.get_servers ();
    //          manage_connections_dialog = new Iridium.Widgets.ManageConnectionsDialog (this, servers);
    //          manage_connections_dialog.show_all ();
    //          manage_connections_dialog.destroy.connect (() => {
    //              manage_connections_dialog = null;
    //          });
    //      }
    //      manage_connections_dialog.present ();
    //  }

    public void show_preferences_dialog () {
        if (preferences_dialog == null) {
            preferences_dialog = new Iridium.Widgets.PreferencesDialog (this);
            preferences_dialog.show_all ();
            preferences_dialog.destroy.connect (() => {
                preferences_dialog = null;
            });
        }
        preferences_dialog.present ();
    }

    private void show_nickname_edit_dialog (string server_name, string current_nickname) {
        if (nickname_edit_dialog == null) {
            nickname_edit_dialog = new Iridium.Widgets.NicknameEditDialog (this, current_nickname);
            nickname_edit_dialog.show_all ();
            nickname_edit_dialog.submit_button_clicked.connect ((new_nickname) => {
                Iridium.Application.connection_manager.set_nickname (server_name, new_nickname);
            });
            nickname_edit_dialog.destroy.connect (() => {
                nickname_edit_dialog = null;
            });
        }
        nickname_edit_dialog.present ();
    }

    private void join_channel (string server_name, string channel_name) {
        // Check if we're already in this channel
        if (Iridium.Application.connection_manager.get_channels (server_name).index_of (channel_name) != -1) {
            channel_join_dialog.display_error (_("You've already joined this channel"));
            return;
        }

        // Validate channel name
        // TODO: Look into what other restrictions exist (https://tools.ietf.org/html/rfc1459#section-1.3)
        if (!channel_name.has_prefix ("#") && !channel_name.has_prefix ("&")) {
            // TODO: Eventually validate that the dialog is non-null, and handle accordingly
            channel_join_dialog.display_error (_("Channel must begin with '#' or '&'"));
            return;
        }
        if (channel_name.length < 2) {
            channel_join_dialog.display_error (_("Enter a channel name"));
            return;
        }

        // If we're not connected to the server yet, connect to it first before joining the channel
        if (!Iridium.Application.connection_manager.has_connection (server_name)) {
            var connection_details = get_connection_details_for_server (server_name);
            if (connection_details == null) {
                // TODO: Handle this
                return;
            }
            main_layout.updating_server (server_name);
            var server_connection = Iridium.Application.connection_manager.connect_to_server (connection_details);
            server_connection.open_successful.connect (() => {
                main_layout.updating_channel (server_name, channel_name);
                Iridium.Application.connection_manager.join_channel (server_name, channel_name);
            });
        } else {
            main_layout.updating_channel (server_name, channel_name);
            Iridium.Application.connection_manager.join_channel (server_name, channel_name);
        }
    }

    private void on_server_message_to_send (string server_name, string text) {
        if (text == null || text.strip ().length == 0) {
            return;
        }
        // Make sure the message text starts with a '/'
        if (text[0] != '/') {
            var message = new Iridium.Services.Message ();
            message.message = _("Start your message with a /");
            //  chat_view.display_server_error_msg (message);
            main_layout.display_server_error_message (server_name, null, message);
            return;
        }
        send_server_command (server_name, text.substring (1));
    }

    private void on_channel_message_to_send (string server_name, string channel_name, string text) {
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
        Iridium.Application.connection_manager.send_user_message (server_name, message_text);
        // Display the message in the chat view
        var message = new Iridium.Services.Message (message_text);
        message.nickname = Iridium.Application.connection_manager.get_nickname (server_name);
        main_layout.display_self_channel_message (server_name, channel_name, message);
    }

    private void on_private_message_to_send (string server_name, string nickname, string text) {
        if (text == null || text.strip ().length == 0) {
            return;
        }
        // Check if it's a server command
        if (text[0] == '/') {
            send_server_command (server_name, text.substring (1));
            return;
        }
        // Send the message
        var message_text = "PRIVMSG " + nickname + " :" + text;
        Iridium.Application.connection_manager.send_user_message (server_name, message_text);
        // Display the message in the chat view
        var message = new Iridium.Services.Message (message_text);
        message.nickname = Iridium.Application.connection_manager.get_nickname (server_name);
        main_layout.display_self_private_message (server_name, nickname, message);
    }

    private void send_server_command (string server_name, string text) {
        // TODO: Check for actions (eg. /me, etc.)
        Iridium.Application.connection_manager.send_user_message (server_name, text);
    }

    public void toggle_sidebar () {
        main_layout.toggle_sidebar ();
    }

    public void reset_marker_line () {
        main_layout.reset_marker_line ();
    }

    //
    // Respond to network connection changes
    //

    public void network_connection_lost () {
        main_layout.show_network_info_bar ();
        // TODO: Disable server and channel buttons in header bar
        Iridium.Application.connection_manager.close_all_connections ();
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
        main_layout.hide_network_info_bar ();
        // TODO: Enable server and channel buttons in header bar
    }

    //
    // HeaderBar Callbacks
    //

    private void on_nickname_selected (string nickname) {
        var server_name = main_layout.get_visible_server ();
        if (server_name == null) {
            return;
        }
        var self_nickname = main_layout.get_server_chat_view (server_name).nickname;
        var trimmed_nickname = strip_nickname_prefix (nickname);
        Idle.add (() => {
            main_layout.add_private_message_chat_view (server_name, trimmed_nickname, self_nickname);
            main_layout.enable_chat_view (server_name, trimmed_nickname);
            main_layout.show_chat_view (server_name, trimmed_nickname);
            return false;
        });
    }

    private string strip_nickname_prefix (string nickname) {
        var prefixes = new string[] { "@", "&" };
        foreach (string prefix in prefixes) {
            if (nickname.has_prefix (prefix)) {
                return nickname.substring (1, nickname.length - 1);
            }
        }
        return nickname;
    }

    //
    // ServerConnectionManager Callbacks
    //

    private bool on_unacceptable_certificate (TlsCertificate peer_cert, Gee.List<TlsCertificateFlags> errors, SocketConnectable connectable) {
        int result = -1;
        bool remember_decision = false;
        Idle.add (() => {
            var dialog = new Iridium.Widgets.CertificateWarningDialog (this, peer_cert, errors, connectable);
            dialog.remember_decision_toggled.connect ((remember) => {
                remember_decision = remember;
            });
            result = dialog.run ();
            dialog.dismiss ();
            return false;
        });
        while (result == -1) {
            // Block until a selection is made
        }
        var is_accepted = (result == Gtk.ResponseType.OK);
        if (remember_decision) {
            var server_identity = new Iridium.Models.ServerIdentity ();
            server_identity.host = Iridium.Services.CertificateManager.parse_host (connectable);
            server_identity.certificate_pem = peer_cert.certificate_pem;
            server_identity.is_accepted = is_accepted;
            Iridium.Application.certificate_manager.store_identity (server_identity);
        }
        return is_accepted;
    }

    private void on_server_connection_successful (string server_name, string nickname, Iridium.Services.Message message) {
        Idle.add (() => {
            main_layout.add_server_chat_view (server_name, nickname, null);
            main_layout.enable_chat_view (server_name, null);
            main_layout.display_server_message (server_name, null, message);
            // If we've just connected to the server that the dialog is for, close the dialog and set the focus on that view
            if (connection_dialog != null && connection_dialog.get_server () == server_name) {
                // Use the destroy signal to ensure that the channel dialog only shows
                // after the server connection dialog has closed
                connection_dialog.destroy.connect (() => {
                    show_channel_join_dialog (server_name);
                });
                connection_dialog.dismiss ();

                main_layout.show_chat_view (server_name, null);
            }

            return false;
        });
    }

    private void on_server_connection_failed (string server_name, string error_message, string? error_details) {
        Idle.add (() => {
            if (connection_dialog != null) {
                connection_dialog.display_error (error_message);
            }
            main_layout.disable_chat_view (server_name, null);
            // TODO: Improve messaging when this fails in the background on app initialization
            // TODO: Add message to the side panel?
            main_layout.error_chat_view (server_name, null, error_message, error_details);
            return false;
        });
    }

    private void on_server_connection_closed (string server_name) {
        // TODO: Implement - display disconnect message
        Idle.add (() => {
            main_layout.disable_chat_view (server_name, null);
            return false;
        });
    }

    private void on_server_message_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            main_layout.display_server_message (server_name, null, message);
            return false;
        });
    }

    private void on_server_error_received (string server_name, Iridium.Services.Message message) {
        Idle.add (() => {
            main_layout.display_server_error_message (server_name, null, message);
            return false;
        });
    }

    private void on_server_quit (string server_name, string message) {
        Iridium.Application.connection_manager.disconnect_from_server (server_name);
    }

    private void on_user_quit_server (string server_name, string nickname, Gee.List<string> channels, Iridium.Services.Message message) {
        // Display a message in any channel that the user was in
        Idle.add (() => {
            foreach (string channel in channels) {
                var message_to_display = new Iridium.Services.Message ();
                message_to_display.message = nickname + _(" has quit");
                if (message.message != null && message.message.strip () != "") {
                    message_to_display.message += " (" + message.message + ")";
                }
                main_layout.display_server_message (server_name, channel, message_to_display);
                update_channel_users_list (server_name, channel);
            }
            return false;
        });

        // If the user was in a private message chat view, display the message there
        Idle.add (() => {
            // Display a message in the channel chat view
            var message_to_display = new Iridium.Services.Message ();
            message_to_display.message = nickname + _(" has quit");
            if (message.message != null && message.message.strip () != "") {
                message_to_display.message += " (" + message.message + ")";
            }
            main_layout.display_server_message (server_name, nickname, message_to_display);
            return false;
        });
    }

    private void on_channel_users_received (string server_name, string channel_name) {
        update_channel_users_list (server_name, channel_name);
    }

    private void on_channel_topic_received (string server_name, string channel_name) {
        var topic = Iridium.Application.connection_manager.get_topic (server_name, channel_name);
        var network_name = Iridium.Application.connection_manager.get_network_name (server_name);
        if (main_layout.get_visible_server () == server_name && main_layout.get_visible_channel () == channel_name) {
            header_bar.update_title (channel_name, (topic == null || topic.length == 0) ? (network_name == null || network_name.length == 0 ? server_name : network_name) : topic);
            header_bar.set_tooltip_text ((topic == null || topic.length == 0) ? null : channel_name + ": " + topic);
        }

        // If we were editing the dialog, close it
        if (channel_topic_edit_dialog != null && channel_topic_edit_dialog.get_topic () == topic) {
            channel_topic_edit_dialog.dismiss ();
        }
    }

    private void on_nickname_in_use (string server_name, Iridium.Services.Message message) {
        if (connection_dialog != null) {
            // TODO: Should this be outside the if-statement?
            Iridium.Application.connection_manager.disconnect_from_server (server_name);
            connection_dialog.display_error (_("Nickname already in use."));
        } else {
            // TODO: This should be an error
            var chat_view = main_layout.get_server_chat_view (server_name);
            chat_view.display_server_error_msg (message);
            // TODO: Prompt for new nickname?
        }
    }

    private void on_erroneous_nickname (string server_name, string current_nickname, string requested_nickname) {
        var error_message = requested_nickname + _(" is not a valid nickname.");
        Idle.add (() => {
            if (connection_dialog != null) {
                connection_dialog.display_error (error_message);
                return false;
            }
            if (nickname_edit_dialog != null) {
                nickname_edit_dialog.display_error (error_message);
                return false;
            }
            return false;
        });
    }

    private void on_channel_joined (string server_name, string channel_name, string nickname) {
        Idle.add (() => {
            main_layout.add_channel_chat_view (server_name, channel_name, nickname);
            main_layout.enable_chat_view (server_name, channel_name);
            // If we've just joined the channel that the dialog is for, close the dialog and set the focus on that view
            if (channel_join_dialog != null && channel_join_dialog.get_server () == server_name && channel_join_dialog.get_channel () == channel_name) {
                var is_favorite = channel_join_dialog.is_favorite_button_selected ();
                channel_join_dialog.dismiss ();
                if (is_favorite) {
                    main_layout.favorite_channel (server_name, channel_name);
                }
                main_layout.show_chat_view (server_name, channel_name);
            }

            set_channel_users_button_enabled (server_name, channel_name, true);
            return false;
        });
    }

    private void on_channel_left (string server_name, string channel_name) {
        // TODO: Display a message that we've left the channel
        Idle.add (() => {
            main_layout.disable_chat_view (server_name, channel_name);
            return false;
        });
        set_channel_users_button_enabled (server_name, channel_name, false);
    }

    private void on_channel_message_received (string server_name, string channel_name, Iridium.Services.Message message) {
        Idle.add (() => {
            main_layout.display_channel_message (server_name, channel_name, message);
            return false;
        });
    }

    private void on_user_joined_channel (string server_name, string channel_name, string nickname) {
        Idle.add (() => {
            // Display a message in the channel chat view
            var message = new Iridium.Services.Message ();
            message.message = nickname + _(" has joined");
            main_layout.display_server_message (server_name, channel_name, message);
            return false;
        });
        update_channel_users_list (server_name, channel_name);
    }

    private void on_user_left_channel (string server_name, string channel_name, string nickname) {
        Idle.add (() => {
            // Display a message in the channel chat view
            var message = new Iridium.Services.Message ();
            message.message = nickname + _(" has left");
            main_layout.display_server_message (server_name, channel_name, message);
            return false;
        });
        update_channel_users_list (server_name, channel_name);
    }

    private void on_private_message_received (string server_name, string nickname, string self_nickname, Iridium.Services.Message message) {
        Idle.add (() => {
            main_layout.add_private_message_chat_view (server_name, nickname, self_nickname);
            main_layout.enable_chat_view (server_name, nickname);
            main_layout.display_private_message (server_name, nickname, message);
            return false;
        });
    }

    // Simply updates the UI based on changes that were already made to the underlying data model
    private void update_channel_users_list (string server_name, string channel_name) {
        var nicknames = Iridium.Application.connection_manager.get_users (server_name, channel_name);
        Idle.add (() => {
            main_layout.update_channel_users (server_name, channel_name, nicknames);
            if (main_layout.get_visible_server () == server_name && main_layout.get_visible_channel () == channel_name) {
                header_bar.set_channel_users (nicknames);
            }
            return false;
        });
    }

    private void set_channel_users_button_enabled (string server_name, string channel_name, bool enabled) {
        if (main_layout.get_visible_server () == server_name && main_layout.get_visible_channel () == channel_name) {
            header_bar.set_channel_users_button_enabled (enabled);
        }
    }

    private void on_insufficient_privs_received (string server_name, string channel_name, Iridium.Services.Message message) {
        //  Idle.add (() => {
        //      // Display a message in the channel chat view
        //      var channel_chat_view = main_layout.get_channel_chat_view (server_name, channel_name);
        //      if (channel_chat_view != null) {
        //          // TODO: Maybe make this more specific?
        //          channel_chat_view.display_channel_error_msg (message);
        //      }
        //      return false;
        //  });
    }

    private void on_nickname_changed (string server_name, string old_nickname, string new_nickname) {
        // Close dialog
        Idle.add (() => {
            if (nickname_edit_dialog != null) {
                nickname_edit_dialog.dismiss ();
            }
            return false;
        });

        main_layout.update_nickname (server_name, old_nickname, new_nickname);

        // Update channel user lists
        foreach (var channel_name in Iridium.Application.connection_manager.get_channels (server_name)) {
            update_channel_users_list (server_name, channel_name);
        }
    }

    private void on_user_changed_nickname (string server_name, string old_nickname, string new_nickname) {
        main_layout.update_user_nickname (server_name, old_nickname, new_nickname);

        if (main_layout.get_visible_server () == server_name && main_layout.get_visible_channel () == new_nickname) {
            header_bar.update_title (new_nickname, server_name);
        }

        // Update channel user lists
        foreach (var channel_name in Iridium.Application.connection_manager.get_channels (server_name)) {
            update_channel_users_list (server_name, channel_name);
        }
    }

    private void on_network_name_received (string server_name, string network_name) {
        Idle.add (() => {
            if (main_layout.get_visible_server () == server_name) {
                header_bar.update_title (network_name, null);
            }
            main_layout.update_network_name (server_name, network_name);
            return false;
        });
    }

    //
    // MainLayout callbacks
    //

    private void on_welcome_view_shown () {
        header_bar.update_title (Constants.APP_NAME, null);
        header_bar.set_channel_users_button_visible (false);
        header_bar.set_tooltip_text (null);
    }

    private void on_server_chat_view_shown (string server_name) {
        var network_name = Iridium.Application.connection_manager.get_network_name (server_name);
        header_bar.update_title (network_name != null ? network_name : server_name, null);
        header_bar.set_channel_users_button_visible (false);
        header_bar.set_tooltip_text (null);
    }

    private void on_channel_chat_view_shown (string server_name, string channel_name) {
        var network_name = Iridium.Application.connection_manager.get_network_name (server_name);
        header_bar.update_title (channel_name, network_name != null ? network_name : server_name);
        header_bar.set_channel_users_button_visible (true);
        header_bar.set_channel_users_button_enabled (main_layout.is_view_enabled (server_name, channel_name));
        update_channel_users_list (server_name, channel_name);
    }

    private void on_private_message_chat_view_shown (string server_name, string nickname) {
        var network_name = Iridium.Application.connection_manager.get_network_name (server_name);
        header_bar.update_title (nickname, network_name != null ? network_name : server_name);
        header_bar.set_channel_users_button_visible (false);
        header_bar.set_tooltip_text (null);
    }

    private void on_nickname_button_clicked (string server_name) {
        var connection_details = Iridium.Application.connection_manager.get_connection_details (server_name);
        show_nickname_edit_dialog (server_name, connection_details.nickname);
    }

    private void on_join_channel_button_clicked (string server_name, string? channel_name) {
        if (channel_name == null) {
            show_channel_join_dialog (server_name);
        } else {
            join_channel (server_name, channel_name);
        }
    }

    private void on_leave_channel_button_clicked (string server_name, string channel_name) {
        Iridium.Application.connection_manager.leave_channel (server_name, channel_name);
    }

    private void on_connect_to_server_button_clicked (string server_name) {
        var connection_details = get_connection_details_for_server (server_name);
        if (connection_details == null) {
            warning ("No connection details found for server %s", server_name);
            return;
        }

        main_layout.updating_server (server_name);
        var server_connection = Iridium.Application.connection_manager.connect_to_server (connection_details);
        // TODO: Maybe don't force the view to be shown in this case?
        server_connection.open_successful.connect (() => {
            Idle.add (() => {
                main_layout.show_chat_view (server_name, null);
                return false;
            });
        });
    }

    private void on_disconnect_from_server_button_clicked (string server_name) {
        Iridium.Application.connection_manager.disconnect_from_server (server_name);
    }

    private void on_edit_channel_topic_button_clicked (string server_name, string channel_name) {
        show_channel_topic_edit_dialog (server_name, channel_name);
    }

}
