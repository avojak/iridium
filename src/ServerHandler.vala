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

public class ServerHandler : GLib.Object {

    private MainWindow main_window;

    public ServerHandler (MainWindow main_window) {
        this.main_window = main_window;
    }

    public void handle (string server, string nick, string login,
                        string channel) {
        try {
            // Resolve the IP address for the server hostname
            var resolver = Resolver.get_default ();
            var addresses = resolver.lookup_by_name (server, null);
            var address = addresses.nth_data (0);
            print (@"Resolved $server to $address\n");

            // Connect to the server
            var client = new SocketClient ();
            var connection = client.connect (new InetSocketAddress (address, 6667));
            print (@"Connected to $server\n");

            // Login to the server
            connection.output_stream.write (@"NICK $nick\r\n".data);
            connection.output_stream.write (@"USER $login 8 * : Iridium IRC Bot\r\n".data);

            // Read from the server until it tells us that we have connected
            var response = new DataInputStream (connection.input_stream);
            var line = response.read_line (null).strip ();
            while (line != null) {
                print ("Received line: %s\n", line);
                main_window.add_message (@"$line\n");

                if (line.index_of ("004") >= 0) {
                    break;
                } else if (line.index_of ("433") >= 0) {
                    stderr.printf (@"Nickname $nick is already in use\n");
                }

                line = response.read_line (null).strip ();
            }

            // Join the channel
            connection.output_stream.write (@"JOIN $channel\r\n".data);

            // Keep reading from the server
            line = response.read_line (null).strip ();
            while (line != null) {
                if (line.has_prefix ("PING ")) {
                    // We must respond to PINGs to avoid being disconnected
                    var pong = line.substring(5);
                    connection.output_stream.write (@"PONG $pong\r\n".data);
                    connection.output_stream.write (@"PRIVMSG $channel : I got pinged!\r\n".data);
                } else {
                    print (@"$line\n");
                    main_window.add_message (@"$line\n");
                }
            }
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
            main_window.add_message (e.message);
        }
    }

}
