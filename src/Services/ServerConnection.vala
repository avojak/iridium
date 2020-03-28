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
    private bool is_registered = false;

    private Gee.List<string> joined_channels = new Gee.ArrayList<string> ();
    private Gee.Map<string, Gee.List<string>> channel_users = new Gee.HashMap<string, Gee.List<string>> ();
    private Gee.Map<string, Gee.List<string>> username_buffer = new Gee.HashMap<string, Gee.List<string>> ();

    private Gee.Map<string, string> channel_topics = new Gee.HashMap<string, string> ();

    public ServerConnection (Iridium.Services.ServerConnectionDetails connection_details) {
        Object (
            connection_details: connection_details
        );
    }

    public void open () {
        should_exit = false;
        var server = connection_details.server;
        new Thread<int> (@"Server connection [$server]", do_connect);
    }

    private int do_connect () {
        try {
            InetAddress address = resolve_server_hostname (connection_details.server);
            var port = connection_details.port;
            SocketConnection connection = connect_to_server (address, port);

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
        // TODO: Could use the NetworkMonitor to check the InetSocketAddress prior to attempting a connection
        SocketConnection connection = client.connect (new InetSocketAddress (address, port));
        return connection;
    }

    private void register (Iridium.Services.ServerConnectionDetails connection_details) {
        var nickname = connection_details.nickname;
        var username = connection_details.username;
        var realname = connection_details.realname;
        var mode = "+i";

        // Handle the various auth methods
        switch (connection_details.auth_method) {
            case Iridium.Models.AuthenticationMethod.NONE:
                debug("AuthenticationMethod is NONE");
                break;
            case Iridium.Models.AuthenticationMethod.SERVER_PASSWORD:
                debug("AuthenticationMethod is SERVER_PASSWORD");
                string password = null;
                // Check if we're passed an auth token
                if (connection_details.auth_token != null) {
                    debug("Server password passed with request to open connection");
                    password = connection_details.auth_token;
                } else {
                    debug("Retrieving server password from secret manager");
                    var server = connection_details.server;
                    var port = connection_details.port;
                    password = Iridium.Application.secret_manager.retrieve_password (server, port, username);
                    if (password == null) {
                        // TODO: Handle this better!
                        debug ("No password found for server: " + server);
                    }
                }
                send_output (@"PASS $password");

                // TODO: This won't work because it's connecting the same signal many times...
                // Do we even need to do this here? Instead, retrieve the password on startup, and by this point
                // we should have a fully populated connection_details object.
                //  Iridium.Application.secret_manager.password_retrieved.connect ((server, port, user, password) => {
                //      if (server == connection_details.server && port == connection_details.port && user == connection_details.username) {
                //          if (password == null) {
                //              // TODO: Handle this better!
                //              debug ("No password found for server: " + server);
                //          }
                //          send_output (@"PASS $password");
                //          send_output (@"NICK $nickname");
                //          send_output (@"USER $username 0 * :$realname");
                //          send_output (@"MODE $username $mode");
                //      }
                //  });

                break;
            default:
                assert_not_reached ();
        }
        send_output (@"NICK $nickname");
        send_output (@"USER $username 0 * :$realname");
        send_output (@"MODE $username $mode");
    }

    //  private void authenticate (string password) {
    //      send_output (@"PASS $password");

    //      string line = "";
    //      do {
    //          try {
    //              line = input_stream.read_line (null);
    //          } catch (GLib.IOError e) {
    //              stderr.printf ("IOError while reading: %s\n", e.message);
    //          }
    //          var message = new Iridium.Services.Message (line);
    //          if (message.command == "ERROR") {
    //              throw new GLib.IOError.PERMISSION_DENIED(message.message);
    //          }
    //          handle_line (line);
    //      } while (line != null && !is_authenticated);
    //      print ("Authentication successful\n");
    //  }

    private void handle_line (string? line) {
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
            case "ERROR":
                if (!is_registered) {
                    open_failed (message.message);
                }
                server_error_received (message);
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
                server_message_received (message);
                break;
            case Iridium.Services.NumericCodes.RPL_WELCOME:
                is_registered = true;
                open_successful (message);
                break;
            case Iridium.Services.MessageCommands.QUIT:
                if (message.username == connection_details.nickname) {
                    server_quit (message.message);
                } else {
                    on_user_quit_server (message.username, message);
                }
                break;
            case Iridium.Services.MessageCommands.JOIN:
                if (message.username == connection_details.nickname) {
                    if (message.message == null || message.message.strip () == "") {
                        joined_channels.add (message.params[0]);
                        channel_joined (message.params[0]);
                    } else {
                        joined_channels.add (message.message);
                        channel_joined (message.message);
                    }
                } else {
                    if (message.message == null || message.message.strip () == "") {
                        on_user_joined_channel (message.params[0], message.username);
                    } else {
                        on_user_joined_channel (message.message, message.username);
                    }
                }
                break;
            case Iridium.Services.MessageCommands.PART:
                // If the the message username is our nickname, we're the one
                // leaving. Otherwise, it's another user leaving.
                if (message.username == connection_details.nickname) {
                    if (message.message == null || message.message.strip () == "") {
                        joined_channels.remove (message.params[0]);
                        channel_left (message.params[0]);
                    } else {
                        joined_channels.remove (message.message);
                        channel_left (message.message);
                    }
                } else {
                    on_user_left_channel (message.params[0], message.username);
                }
                break;
            case Iridium.Services.MessageCommands.PRIVMSG:
                // CTCP VERSION
                if (Iridium.Services.MessageCommands.VERSION == message.message) {
                    ctcp_version_query_received (message);
                    break;
                }
                // If the first param is our nickname, it's a PM. Otherwise, it's
                // a general message on a channel
                if (message.params[0] == connection_details.nickname) {
                    private_message_received (message.username, message);
                } else {
                    channel_message_received (message.params[0], message);
                }
                break;
            case Iridium.Services.NumericCodes.RPL_NAMREPLY:
                usernames_received (message.params[2], message.message.split (" "));
                break;
            case Iridium.Services.NumericCodes.RPL_ENDOFNAMES:
                end_of_usernames (message.params[1]);
                break;
            case Iridium.Services.MessageCommands.TOPIC:
                on_channel_topic_received (message.params[0], message.message);
                break;
            case Iridium.Services.NumericCodes.RPL_TOPIC:
                on_channel_topic_received (message.params[1], message.message);
                break;
            case Iridium.Services.NumericCodes.RPL_TOPICWHOTIME:
                // TODO: Implement
                break;
            case Iridium.Services.NumericCodes.RPL_NOTOPIC:
                on_channel_topic_received (message.params[1], "");
                break;
            
            // Errors
            case Iridium.Services.NumericCodes.ERR_NICKNAMEINUSE:
                nickname_in_use (message);
                break;
            case Iridium.Services.NumericCodes.ERR_CHANOPRIVSNEEDED:
                insufficient_privs (message.params[1], message);
                // Can remove this once errors are implemented in the channel chat view
                server_error_received (message);
                break;
            case Iridium.Services.NumericCodes.ERR_UNKNOWNCOMMAND:
            case Iridium.Services.NumericCodes.ERR_NOSUCHNICK: 
                // TODO: Handle no such nick for sending a PM. Should display the server 
                //       error in the channel view, not the server view.
            case Iridium.Services.NumericCodes.ERR_NOSUCHCHANNEL:
            case Iridium.Services.NumericCodes.ERR_NOMOTD:
            case Iridium.Services.NumericCodes.ERR_USERNOTINCHANNEL:
            case Iridium.Services.NumericCodes.ERR_NOTONCHANNEL:
            case Iridium.Services.NumericCodes.ERR_NOTREGISTERED:
            case Iridium.Services.NumericCodes.ERR_NEEDMOREPARAMS:
            case Iridium.Services.NumericCodes.ERR_UNKNOWNMODE:
                server_error_received (message);
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
        channel_users.clear ();
        do_close ();
    }

    private void do_close () {
        should_exit = true;

        try {
            if (input_stream != null) {
                if (input_stream is GLib.DataInputStream && !input_stream.is_closed ()) {
                    input_stream.clear_pending ();
                    input_stream.close ();
                }
                input_stream = null;
            }
        } catch (GLib.IOError e) {
            // TODO: Handle errors!
        }

        try {
            if (output_stream != null) {
                if (output_stream is GLib.DataOutputStream && !output_stream.is_closed ()) {
                    output_stream.clear_pending ();
                    output_stream.flush ();
                    output_stream.close ();
                }
                output_stream = null;
            }
        } catch (GLib.Error e) {
            // TODO: Handle errors!
        }

        connection_closed ();
    }

    public void send_user_message (string text) {
        send_output (text);
    }

    public void leave_channel (string channel_name) {
        send_output (Iridium.Services.MessageCommands.PART + " " + channel_name);
        // Clear out our list of channel users
        channel_users.set (channel_name, new Gee.LinkedList<string> ());
    }

    public Gee.List<string> get_users (string channel_name) {
        if (!channel_users.has_key (channel_name)) {
            return new Gee.LinkedList<string> ();
        }
        return channel_users.get (channel_name);
    }

    public Gee.List<string> get_joined_channels () {
        return joined_channels;
    }

    private void send_output (string output) {
        try {
            output_stream.put_string (@"$output\r\n");
        } catch (GLib.IOError e) {
            // TODO: Handle errors!!
        }
    }

    private void usernames_received (string channel_name, string[] usernames) {
        // Initialize the buffer to an empty list
        if (!username_buffer.has_key (channel_name) || username_buffer.get (channel_name) == null) {
            username_buffer.set (channel_name, new Gee.LinkedList<string> ());
        }
        // Add each new username to the buffer
        foreach (string username in usernames) {
            username_buffer.get (channel_name).add (username);
        }
    }

    private void end_of_usernames (string channel_name) {
        // Copy the buffered usernames over to the master map of users by channel
        channel_users.set (channel_name, username_buffer.get (channel_name));
        // Clear the buffered usernames
        username_buffer.unset (channel_name);
        // Send the signal
        channel_users_received (channel_name);
    }

    private void ctcp_version_query_received (Iridium.Services.Message message) {
        send_output (Iridium.Services.MessageCommands.VERSION + " " + Constants.APP_ID + " " + Constants.VERSION);
        var display_message = new Iridium.Services.Message ();
        display_message.message = "Received a CTCP VERSION query from " + message.username;
        server_message_received (display_message);
    }

    private void on_user_joined_channel (string channel_name, string username) {
        // Update our list of users in channels
        channel_users.get (channel_name).add (username);
        // Send the signal
        user_joined_channel (channel_name, username);
    }

    private void on_user_left_channel (string channel_name, string username) {
        // Update our list of users in channels
        channel_users.get (channel_name).remove (username);
        // Send the signal
        user_left_channel (channel_name, username);
    }

    private void on_user_quit_server (string username, Iridium.Services.Message message) {
        // Update our list of users in channels, and get the list of channels
        // that the user was in (that we care about)
        Gee.List<string> channels = new Gee.LinkedList<string> ();
        foreach (Gee.Map.Entry<string, Gee.List<string>> entry in channel_users.entries) {
            if (entry.value.remove (username)) {
                channels.add (entry.key);
            }
        }
        // Send the signal
        user_quit_server (username, channels, message);
    }

    private void on_channel_topic_received (string channel_name, string? topic) {
        channel_topics.set (channel_name, topic);
        channel_topic_received (channel_name);
    }

    public string? get_channel_topic (string channel_name) {
        if (!channel_topics.has_key (channel_name)) {
            return "";
        }
        return channel_topics.get (channel_name);
    }

    public void set_channel_topic (string channel_name, string topic) {
        send_output (Iridium.Services.MessageCommands.TOPIC + " " + channel_name + " :" + topic);
    }

    public signal void open_successful (Iridium.Services.Message message);
    public signal void open_failed (string error_message);
    public signal void connection_closed ();
    /* public signal void close_failed (string message); */
    public signal void server_message_received (Iridium.Services.Message message);
    public signal void server_error_received (Iridium.Services.Message message);
    public signal void server_quit (string message);
    public signal void user_quit_server (string username, Gee.List<string> channels, Iridium.Services.Message message);
    public signal void channel_users_received (string channel);
    public signal void channel_topic_received (string channel);
    public signal void nickname_in_use (Iridium.Services.Message message);
    public signal void channel_joined (string channel);
    public signal void channel_left (string channel);
    public signal void channel_message_received (string channel_name, Iridium.Services.Message message);
    public signal void user_joined_channel (string channel_name, string username);
    public signal void user_left_channel (string channel_name, string username);
    public signal void private_message_received (string username, Iridium.Services.Message message);
    public signal void insufficient_privs (string channel_name, Iridium.Services.Message message);

}
