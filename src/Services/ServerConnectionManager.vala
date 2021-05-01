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

public class Iridium.Services.ServerConnectionManager : GLib.Object {

    private Gee.Map<string, Iridium.Services.ServerConnection> open_connections;

    private static Iridium.Services.ServerConnectionManager _instance = null;
    public static Iridium.Services.ServerConnectionManager instance {
        get {
            if (_instance == null) {
                _instance = new Iridium.Services.ServerConnectionManager ();
            }
            return _instance;
        }
    }

    private ServerConnectionManager () {
        open_connections = new Gee.HashMap<string, Iridium.Services.ServerConnection> ();
    }

    public Iridium.Services.ServerConnection connect_to_server (Iridium.Services.ServerConnectionDetails connection_details) {
        var server = connection_details.server;
        // Check if we're already connected
        if (open_connections.has_key (server)) {
            return open_connections.get (server);
        }
        Iridium.Services.ServerConnection server_connection = new Iridium.Services.ServerConnection (connection_details);
        server_connection.unacceptable_certificate.connect (on_unacceptable_certificate);
        server_connection.open_successful.connect (on_server_connection_successful);
        server_connection.open_failed.connect (on_server_connection_failed);
        server_connection.connection_closed.connect (on_server_connection_closed);
        server_connection.server_message_received.connect (on_server_message_received);
        server_connection.server_error_received.connect (on_server_error_received);
        server_connection.server_quit.connect (on_server_quit);
        server_connection.user_quit_server.connect (on_user_quit_server);
        server_connection.channel_users_received.connect (on_channel_users_received);
        server_connection.channel_topic_received.connect (on_channel_topic_received);
        server_connection.channel_topic_changed.connect (on_channel_topic_changed);
        server_connection.channel_topic_whotime_received.connect (on_channel_topic_whotime_received);
        server_connection.nickname_in_use.connect (on_nickname_in_use);
        server_connection.erroneous_nickname.connect (on_erroneous_nickname);
        server_connection.channel_joined.connect (on_channel_joined);
        server_connection.channel_left.connect (on_channel_left);
        server_connection.channel_message_received.connect (on_channel_message_received);
        server_connection.user_joined_channel.connect (on_user_joined_channel);
        server_connection.user_left_channel.connect (on_user_left_channel);
        server_connection.private_message_received.connect (on_private_message_received);
        server_connection.insufficient_privs.connect (on_insufficient_privs_received);
        server_connection.nickname_changed.connect (on_nickname_changed);
        server_connection.user_changed_nickname.connect (on_user_changed_nickname);
        server_connection.network_name_received.connect (on_network_name_received);

        //  server_connection.open_successful.connect (() => {
        open_connections.set (server, server_connection);
        //  });
        server_connection.open_failed.connect (() => {
            open_connections.unset (server);
        });

        server_connection.open ();
        return server_connection;
    }

    public static Iridium.Services.ServerConnectionDetails create_connection_details (Iridium.Models.IRCURI uri) {
        var connection_details = new Iridium.Services.ServerConnectionDetails ();
        connection_details.server = uri.get_server ();
        connection_details.nickname = Iridium.Application.settings.get_string ("default-nickname");
        connection_details.username = connection_details.nickname; // Keep these the same for now
        connection_details.realname = Iridium.Application.settings.get_string ("default-realname");
        connection_details.auth_method = Iridium.Models.AuthenticationMethod.NONE;
        connection_details.tls = false;
        connection_details.port = Iridium.Services.ServerConnectionDetails.DEFAULT_INSECURE_PORT;
        return connection_details;
    }

    public void disconnect_from_server (string server) {
        var connection = open_connections.get (server);
        if (connection == null) {
            return;
        }
        connection.close ();
        open_connections.unset (server);
    }

    public void fail_server_connection (string server, string error_message, string? error_details) {
        var connection = open_connections.get (server);
        if (connection == null) {
            return;
        }
        connection.close ();
        open_connections.unset (server);
        connection.open_failed (error_message, error_details);
    }

    public Iridium.Services.ServerConnectionDetails? get_connection_details (string server_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return null;
        }
        return connection.connection_details;
    }

    public void join_channel (string server_name, string channel_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return;
        }
        connection.join_channel (channel_name);
    }

    public void leave_channel (string server, string channel) {
        var connection = open_connections.get (server);
        if (connection == null) {
            return;
        }
        connection.leave_channel (channel);
    }

    public string[] get_connected_servers () {
        string[] servers = { };
        foreach (string key in open_connections.keys) {
            servers += key;
        }
        return servers;
    }

    public string[] get_connected_server_network_names () {
        string[] network_names = { };
        foreach (var key in open_connections.keys) {
            var server_connection = open_connections.get (key);
            network_names += server_connection.server_supports.network;
        }
        return network_names;
    }

    public string? get_network_name (string server_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return null;
        }
        return connection.server_supports.network;
    }

    public Gee.List<string> get_channels (string server_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return new Gee.ArrayList<string> ();
        }
        return connection.get_joined_channels ();
    }

    public bool has_connection (string server) {
        return open_connections.has_key (server);
    }

    public void close_all_connections () {
        debug ("Closing all connections…");
        foreach (var connection in open_connections.entries) {
            connection.value.close ();
        }
        open_connections.clear ();
    }

    public void send_user_message (string server_name, string message) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return;
        }
        connection.send_user_message (message);
    }

    public string? get_nickname (string server_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return null;
        }
        return connection.connection_details.nickname;
    }

    public Gee.List<string> get_users (string server_name, string channel_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return new Gee.LinkedList<string> ();
        }
        return connection.get_users (channel_name);
    }

    public Gee.List<string> get_operators (string server_name, string channel_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return new Gee.LinkedList<string> ();
        }
        return connection.get_operators (channel_name);
    }

    public string get_topic (string server_name, string channel_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return "";
        }
        var topic = connection.get_channel_topic (channel_name);
        return topic == null ? "" : topic;
    }

    public void set_channel_topic (string server_name, string channel_name, string topic) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return;
        }
        connection.set_channel_topic (channel_name, topic);
    }

    public void set_nickname (string server_name, string new_nickname) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return;
        }
        connection.set_nickname (new_nickname);
    }

    //
    // ServerConnection Callbacks
    //

    private bool on_unacceptable_certificate (TlsCertificate peer_cert, Gee.List<TlsCertificateFlags> errors, SocketConnectable connectable) {
        return unacceptable_certificate (peer_cert, errors, connectable);
    }

    private void on_server_connection_successful (Iridium.Services.ServerConnection source, string nickname, Iridium.Services.Message message) {
        server_connection_successful (source.connection_details.server, nickname, message);
    }

    private void on_server_connection_failed (Iridium.Services.ServerConnection source, string error_message, string? error_details) {
        server_connection_failed (source.connection_details.server, error_message, error_details);
    }

    private void on_server_connection_closed (Iridium.Services.ServerConnection source) {
        server_connection_closed (source.connection_details.server);
    }

    private void on_server_message_received (Iridium.Services.ServerConnection source, Iridium.Services.Message message) {
        server_message_received (source.connection_details.server, message);
    }

    private void on_server_error_received (Iridium.Services.ServerConnection source, Iridium.Services.Message message) {
        server_error_received (source.connection_details.server, message);
    }

    private void on_server_quit (Iridium.Services.ServerConnection source, string message) {
        server_quit (source.connection_details.server, message);
    }

    private void on_user_quit_server (Iridium.Services.ServerConnection source, string nickname, Gee.List<string> channels, Iridium.Services.Message message) {
        user_quit_server (source.connection_details.server, nickname, channels, message);
    }

    private void on_channel_users_received (Iridium.Services.ServerConnection source, string channel_name) {
        channel_users_received (source.connection_details.server, channel_name);
    }

    private void on_channel_topic_received (Iridium.Services.ServerConnection source, string channel_name) {
        channel_topic_received (source.connection_details.server, channel_name);
    }

    private void on_channel_topic_changed (Iridium.Services.ServerConnection source, string channel_name, string nickname) {
        channel_topic_changed (source.connection_details.server, channel_name, nickname);
    }

    private void on_channel_topic_whotime_received (Iridium.Services.ServerConnection source, string channel_name, string nickname, int64 unix_utc) {
        channel_topic_whotime_received (source.connection_details.server, channel_name, nickname, unix_utc);
    }

    private void on_nickname_in_use (Iridium.Services.ServerConnection source, Iridium.Services.Message message) {
        nickname_in_use (source.connection_details.server, message);
    }

    private void on_erroneous_nickname (Iridium.Services.ServerConnection source, string current_nickname, string requested_nickname) {
        erroneous_nickname (source.connection_details.server, current_nickname, requested_nickname);
    }

    private void on_channel_joined (Iridium.Services.ServerConnection source, string channel_name, string nickname) {
        channel_joined (source.connection_details.server, channel_name, nickname);
    }

    private void on_channel_left (Iridium.Services.ServerConnection source, string channel_name) {
        channel_left (source.connection_details.server, channel_name);
    }

    private void on_channel_message_received (Iridium.Services.ServerConnection source, string channel_name, Iridium.Services.Message message) {
        channel_message_received (source.connection_details.server, channel_name, message);
    }

    private void on_user_joined_channel (Iridium.Services.ServerConnection source, string channel_name, string nickname) {
        user_joined_channel (source.connection_details.server, channel_name, nickname);
    }

    private void on_user_left_channel (Iridium.Services.ServerConnection source, string channel_name, string nickname) {
        user_left_channel (source.connection_details.server, channel_name, nickname);
    }

    private void on_private_message_received (Iridium.Services.ServerConnection source, string nickname, string self_nickname, Iridium.Services.Message message) {
        private_message_received (source.connection_details.server, nickname, self_nickname, message);
    }

    private void on_insufficient_privs_received (Iridium.Services.ServerConnection source, string channel_name, Iridium.Services.Message message) {
        insufficient_privs_received (source.connection_details.server, channel_name, message);
    }

    private void on_nickname_changed (Iridium.Services.ServerConnection source, string old_nickname, string new_nickname) {
        nickname_changed (source.connection_details.server, old_nickname, new_nickname);
    }

    private void on_user_changed_nickname (Iridium.Services.ServerConnection source, string old_nickname, string new_nickname) {
        user_changed_nickname (source.connection_details.server, old_nickname, new_nickname);
    }

    private void on_network_name_received (Iridium.Services.ServerConnection source, string network_name) {
        network_name_received (source.connection_details.server, network_name);
    }

    //
    // Signals
    //

    public signal bool unacceptable_certificate (TlsCertificate peer_cert, Gee.List<TlsCertificateFlags> errors, SocketConnectable connectable);
    public signal void server_connection_successful (string server_name, string nickname, Iridium.Services.Message message);
    public signal void server_connection_failed (string server_name, string error_message, string? error_details);
    public signal void server_connection_closed (string server_name);
    public signal void server_message_received (string server_name, Iridium.Services.Message message);
    public signal void server_error_received (string server_name, Iridium.Services.Message message);
    public signal void server_quit (string server_name, string message);
    public signal void user_quit_server (string server_name, string nickname, Gee.List<string> channels, Iridium.Services.Message message);
    public signal void channel_users_received (string server_name, string channel_name);
    public signal void channel_topic_received (string server_name, string channel_name);
    public signal void channel_topic_changed (string server_name, string channel_name, string nickname);
    public signal void channel_topic_whotime_received (string server_name, string channel_name, string nickname, int64 unix_utc);
    public signal void nickname_in_use (string server_name, Iridium.Services.Message message);
    public signal void erroneous_nickname (string server_name, string current_nickname, string requested_nickname);
    public signal void channel_joined (string server_name, string channel_name, string nickname);
    public signal void channel_left (string server_name, string channel_name);
    public signal void channel_message_received (string server_name, string channel_name, Iridium.Services.Message message);
    public signal void user_joined_channel (string server_name, string channel_name, string nickname);
    public signal void user_left_channel (string server_name, string channel_name, string nickname);
    public signal void private_message_received (string server_name, string nickname, string self_nickname, Iridium.Services.Message message);
    public signal void insufficient_privs_received (string server_name, string channel_name, Iridium.Services.Message message);
    public signal void nickname_changed (string server_name, string old_nickname, string new_nickname);
    public signal void user_changed_nickname (string server_name, string old_nickname, string new_nickname);
    public signal void network_name_received (string server_name, string network_name);

}
