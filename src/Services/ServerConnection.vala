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

public class Iridium.Services.ServerConnection : GLib.Object {

    public Iridium.Services.ServerConnectionDetails connection_details { get; construct; }
    private bool should_exit = false;

    public ServerConnection (Iridium.Services.ServerConnectionDetails connection_details) {
        Object (
            connection_details: connection_details
        );
    }

    public void open () {
        var server = connection_details.server;
        new Thread<int> (@"Server connection [$server]", do_connect);
    }

    private int do_connect () {
        try {
            var server = connection_details.server;
            var nickname = connection_details.nickname;
            var username = connection_details.username;
            var realname = connection_details.realname;
            var port = Iridium.Services.ServerConnectionDetails.DEFAULT_PORT;

            // Resolve the IP address for the server hostname
            Resolver resolver = Resolver.get_default ();
            List<InetAddress> addresses = resolver.lookup_by_name (server, null);
            InetAddress address = addresses.nth_data (0);
            print (@"Resolved $server to $address\n");

            // Connect to the server
            SocketClient client = new SocketClient ();
            SocketConnection connection = client.connect (new InetSocketAddress (address, port));
            print (@"Connected to $server\n");

            // Login to the server
            connection.output_stream.write (@"NICK $nickname\r\n".data);
            connection.output_stream.write (@"USER $username 0 * :$realname\r\n".data);
            //connection.output_stream.write (@"MODE $username +i");
            DataInputStream input_stream = new DataInputStream (connection.input_stream);

            string line = "";
            do {
                try {
                    line = input_stream.read_line (null).strip ();
                    handle_message (line);
                } catch (GLib.IOError e) {
                    stderr.printf ("IOError while reading: %s\n", e.message);
                }
            } while (line != null && !should_exit);
        } catch (GLib.Error e) {
            stderr.printf ("Error while connecting: %s\n", e.message);
            open_failed (e.message);
            return 0;
        }
        return 1;
    }

    private void close () {
        // TODO: Gracefully disconnect
        should_exit = true;
        close_successful ();
    }

    private void handle_message (string message) {
        if (message.index_of ("004") >= 0) {
            open_successful ();
            print ("Successfully connected. Exiting...\n");
            should_exit = true;
        }
    }

    public signal void open_successful ();
    public signal void open_failed (string message);
    public signal void close_successful ();
    public signal void close_failed (string message);

}
