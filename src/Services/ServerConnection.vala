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

    private DataInputStream input_stream;
    private DataOutputStream output_stream;
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
            InetAddress address = resolve_server_hostname (connection_details.server);
            var port = Iridium.Services.ServerConnectionDetails.DEFAULT_PORT;
            SocketConnection connection = connect_to_server (address, port);

            print ("Connected to server\n");

            input_stream = new DataInputStream (connection.input_stream);
            output_stream = new DataOutputStream (connection.output_stream);

            register (connection_details);

            string line = "";
            do {
                try {
                    line = input_stream.read_line (null);
                    handle_line (line);
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

    private InetAddress resolve_server_hostname (string hostname) throws GLib.Error {
        Resolver resolver = Resolver.get_default ();
        List<InetAddress> addresses = resolver.lookup_by_name (hostname, null);
        InetAddress address = addresses.nth_data (0);
        return address;
    }

    private SocketConnection connect_to_server (InetAddress address, uint16 port) throws GLib.Error {
        SocketClient client = new SocketClient ();
        SocketConnection connection = client.connect (new InetSocketAddress (address, port));
        return connection;
    }

    private void register (Iridium.Services.ServerConnectionDetails connection_details) {
        var nickname = connection_details.nickname;
        var username = connection_details.username;
        var realname = connection_details.realname;
        var mode = "+i";

        // TODO: Password?
        send_output (@"NICK $nickname");
        send_output (@"USER $username 0 * :$realname");
        send_output (@"MODE $username $mode");
    }

    private void handle_line (string line) {
        if (line == null) {
            close ();
            return;
        }
        var message = new Iridium.Services.Message (line);
        print (@"$line\n");
        switch (message.command) {
            case "PING":
                send_output ("PONG " + message.message);
                break;
            case Iridium.Services.MessageCommands.NOTICE:
            case Iridium.Services.NumericCodes.RPL_MOTD:
            case Iridium.Services.NumericCodes.RPL_MOTDSTART:
            case Iridium.Services.NumericCodes.RPL_YOURHOST:
            case Iridium.Services.NumericCodes.RPL_LUSERCLIENT:
            case Iridium.Services.NumericCodes.RPL_LUSEROP:
            case Iridium.Services.NumericCodes.RPL_LUSERUNKNOWN:
            case Iridium.Services.NumericCodes.RPL_LUSERCHANNELS:
            case Iridium.Services.NumericCodes.RPL_UMODEIS:
            case Iridium.Services.NumericCodes.RPL_SERVLIST:
            case Iridium.Services.NumericCodes.RPL_ENDOFSTATS:
            case Iridium.Services.NumericCodes.RPL_STATSLINKINFO:
                server_message_received (message.message);
                break;
            case Iridium.Services.NumericCodes.RPL_WELCOME:
                open_successful (message.message);
                break;
            case Iridium.Services.MessageCommands.QUIT:
                server_quit (message.message);
                break;
            case Iridium.Services.MessageCommands.JOIN:
                if (message.message == null || message.message.strip () == "") {
                    channel_joined (connection_details.server, message.params[0]);
                } else {
                    // TODO: Handle message for another user joining a channel
                }
                break;
            case Iridium.Services.MessageCommands.PART:
                // TODO: Implement
                break;
            case Iridium.Services.MessageCommands.PRIVMSG:
                // CTCP VERSION
                if (Iridium.Services.MessageCommands.VERSION == message.message) {
                    // TODO: Respond to CTCP VERSION
                    /* send_output ("VERSION Iridium IRC Client 1.0"); */
                    server_message_received ("Received a CTCP VERSION from " + message.username);
                    break;
                }
                channel_message_received (message.username, message.message);
                break;
            // Errors
            case Iridium.Services.NumericCodes.ERR_NICKNAMEINUSE:
                nickname_in_use (message.message);
                break;
            default:
                break;
        }
    }

    public void join_channel (string name) {
        send_output (Iridium.Services.MessageCommands.JOIN + " " + name);
    }

    public void close () {
        debug ("Closing connection for server: " + connection_details.server);
        should_exit = true;
        send_output (Iridium.Services.MessageCommands.QUIT + " :Iridium IRC Client");
        do_close ();
    }

    public void do_close () {
        should_exit = true;

        try {
            input_stream.clear_pending ();
            input_stream.close ();
        } catch (GLib.IOError e) {
            // TODO: Handle errors!
        }

        try {
            output_stream.clear_pending ();
            output_stream.flush ();
            output_stream.close ();
        } catch (GLib.Error e) {
            // TODO: Handle errors!
        }

        close_successful ();
    }

    public void send_user_message (string text) {
        /* var message = new Message ();
        message.username = connection_details.username;
        message.message = text;
        message.command = Iridium.Services.MessageCommands.PRIVMSG; */
        send_output (text);
    }

    private void send_output (string response) {
        try {
            output_stream.put_string (@"$response\r\n");
        } catch (GLib.IOError e) {
            // TODO: Handle erros!!
        }
    }

    public signal void open_successful (string message);
    public signal void open_failed (string message);
    public signal void close_successful ();
    /* public signal void close_failed (string message); */
    public signal void server_message_received (string message);
    public signal void channel_message_received (string channel_name, string message);
    public signal void channel_joined (string server, string channel);
    public signal void nickname_in_use (string message);
    public signal void server_quit (string message);

}
