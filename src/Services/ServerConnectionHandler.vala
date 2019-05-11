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

    private Gee.Map<string, Iridium.Services.ServerConnection> connections;

    public ServerConnectionHandler () {
        connections = new Gee.HashMap<string, Iridium.Services.ServerConnection> ();
    }

    public Iridium.Services.ServerConnection connect_to_server (Iridium.Services.ServerConnectionDetails connection_details) {
        var server_connection = new Iridium.Services.ServerConnection (connection_details);
        connections.set (connection_details.server, server_connection);
        server_connection.open ();
        return server_connection;
    }

    public void disconnect_from_server (string server) {
        var connection = connections.get (server);
        connection.close ();
        connections.unset (server);
    }

    public string[] get_connected_servers () {
        string[] servers = { };
        foreach (string key in connections.keys) {
            servers += key;
        }
        return servers;
    }

    public bool has_connection (string server) {
        return connections.has_key (server);
    }

    public void close_all_connections () {
        foreach (var connection in connections.entries) {
            connection.value.close ();
        }
    }

}
