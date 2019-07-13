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

public class Iridium.Services.ServerConnectionHandler : GLib.Object {

    private Gee.Map<string, Iridium.Services.ServerConnection> open_connections;

    public ServerConnectionHandler () {
        open_connections = new Gee.HashMap<string, Iridium.Services.ServerConnection> ();
    }

    public Iridium.Services.ServerConnection connect_to_server (Iridium.Services.ServerConnectionDetails connection_details) {
        var server = connection_details.server;
        // Check if we're already connected
        if (open_connections.has_key (server)) {
            return open_connections.get (server);
        }
        Iridium.Services.ServerConnection server_connection = new Iridium.Services.ServerConnection (connection_details);
        server_connection.open_successful.connect (on_server_connection_successful);
        server_connection.open_failed.connect (on_server_connection_failed);
        server_connection.connection_closed.connect (on_server_connection_closed);
        server_connection.server_message_received.connect (on_server_message_received);
        server_connection.server_error_received.connect (on_server_error_received);
        server_connection.server_quit.connect (on_server_quit);
        server_connection.user_quit_server.connect (on_user_quit_server);
        server_connection.channel_users_received.connect (on_channel_users_received);
        server_connection.channel_topic_received.connect (on_channel_topic_received);
        server_connection.nickname_in_use.connect (on_nickname_in_use);
        server_connection.channel_joined.connect (on_channel_joined);
        server_connection.channel_left.connect (on_channel_left);
        server_connection.channel_message_received.connect (on_channel_message_received);
        server_connection.user_joined_channel.connect (on_user_joined_channel);
        server_connection.user_left_channel.connect (on_user_left_channel);
        server_connection.private_message_received.connect (on_private_message_received);

        // TODO: This may cause a bug since we're not yet sure whether the
        //       connection attempt was successful. Maybe do this in the
        //       callback instead?
        open_connections.set (server, server_connection);

        server_connection.open ();
        return server_connection;
    }

    public void disconnect_from_server (string server) {
        var connection = open_connections.get (server);
        if (connection == null) {
            return;
        }
        connection.close ();
        open_connections.unset (server);
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

    public bool has_connection (string server) {
        return open_connections.has_key (server);
    }

    public void close_all_connections () {
        foreach (var connection in open_connections.entries) {
            connection.value.close ();
        }
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

    public string get_topic (string server_name, string channel_name) {
        var connection = open_connections.get (server_name);
        if (connection == null) {
            return "";
        }
        return connection.get_channel_topic (channel_name);
    }

    //
    // ServerConnection Callbacks
    //

    private void on_server_connection_successful (Iridium.Services.ServerConnection source, Iridium.Services.Message message) {
        server_connection_successful (source.connection_details.server, message);
    }

    private void on_server_connection_failed (Iridium.Services.ServerConnection source, string error_message) {
        server_connection_failed (source.connection_details.server, error_message);
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

    private void on_user_quit_server (Iridium.Services.ServerConnection source, string username, Gee.List<string> channels, Iridium.Services.Message message) {
        user_quit_server (source.connection_details.server, username, channels, message);
    }

    private void on_channel_users_received (Iridium.Services.ServerConnection source, string channel_name) {
        channel_users_received (source.connection_details.server, channel_name);
    }

    private void on_channel_topic_received (Iridium.Services.ServerConnection source, string channel_name) {
        channel_topic_received (source.connection_details.server, channel_name);
    }

    private void on_nickname_in_use (Iridium.Services.ServerConnection source, Iridium.Services.Message message) {
        nickname_in_use (source.connection_details.server, message);
    }

    private void on_channel_joined (Iridium.Services.ServerConnection source, string channel_name) {
        channel_joined (source.connection_details.server, channel_name);
    }

    private void on_channel_left (Iridium.Services.ServerConnection source, string channel_name) {
        channel_left (source.connection_details.server, channel_name);
    }

    private void on_channel_message_received (Iridium.Services.ServerConnection source, string channel_name, Iridium.Services.Message message) {
        channel_message_received (source.connection_details.server, channel_name, message);
    }

    private void on_user_joined_channel (Iridium.Services.ServerConnection source, string channel_name, string username) {
        user_joined_channel (source.connection_details.server, channel_name, username);
    }

    private void on_user_left_channel (Iridium.Services.ServerConnection source, string channel_name, string username) {
        user_left_channel (source.connection_details.server, channel_name, username);
    }

    private void on_private_message_received (Iridium.Services.ServerConnection source, string username, Iridium.Services.Message message) {
        private_message_received (source.connection_details.server, username, message);
    }

    //
    // Signals
    //

    public signal void server_connection_successful (string server_name, Iridium.Services.Message message);
    public signal void server_connection_failed (string server_name, string error_message);
    public signal void server_connection_closed (string server_name);
    public signal void server_message_received (string server_name, Iridium.Services.Message message);
    public signal void server_error_received (string server_name, Iridium.Services.Message message);
    public signal void server_quit (string server_name, string message);
    public signal void user_quit_server (string server_name, string username, Gee.List<string> channels, Iridium.Services.Message message);
    public signal void channel_users_received (string server_name, string channel_name);
    public signal void channel_topic_received (string server_name, string channel_name);
    public signal void nickname_in_use (string server_name, Iridium.Services.Message message);
    public signal void channel_joined (string server_name, string channel_name);
    public signal void channel_left (string server_name, string channel_name);
    public signal void channel_message_received (string server_name, string channel_name, Iridium.Services.Message message);
    public signal void user_joined_channel (string server_name, string channel_name, string username);
    public signal void user_left_channel (string server_name, string channel_name, string username);
    public signal void private_message_received (string server_name, string username, Iridium.Services.Message message);

}
