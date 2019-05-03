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

public class ServerConnection : GLib.Object {

    private const uint16 DEFAULT_PORT = 6667;

    private bool should_exit = false;

    private string server;
    private string nickname;
    private string username;
    private string realname;

    public ServerConnection (string server, string nickname, string username,
                             string realname) {
        this.server = server;
        this.nickname = nickname;
        this.username = username;
        this.realname = realname;
    }

    public void do_connect () {
        new Thread<int> (@"Server connection [$server]", open_connection);
    }

    private int open_connection () {
        try {
            // Resolve the IP address for the server hostname
            Resolver resolver = Resolver.get_default ();
            List<InetAddress> addresses = resolver.lookup_by_name (server, null);
            InetAddress address = addresses.nth_data (0);
            print (@"Resolved $server to $address\n");

            // Connect to the server
            SocketClient client = new SocketClient ();
            SocketConnection connection = client.connect (new InetSocketAddress (address, DEFAULT_PORT));
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
            return 0;
        }
        return 1;
    }

    private void handle_message (string message) {
        if (message.index_of ("004") >= 0) {
            print ("Successfully connected. Exiting...\n");
            should_exit = true;
        }
    }

}
