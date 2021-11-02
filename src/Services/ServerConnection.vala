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

    private Thread<int>? connection_thread;
    private Cancellable cancellable = new Cancellable ();

    private IOStream connection;
    private DataInputStream input_stream;
    private DataOutputStream output_stream;
    private bool should_exit = false;
    private bool is_registered = false;

    private Gee.List<string> joined_channels = new Gee.ArrayList<string> ();
    private Gee.Map<string, Gee.List<string>> channel_users = new Gee.HashMap<string, Gee.List<string>> ();
    private Gee.Map<string, Gee.List<string>> nickname_buffer = new Gee.HashMap<string, Gee.List<string>> ();
    private Gee.Map<string, Gee.List<string>> channel_operators = new Gee.HashMap<string, Gee.List<string>> ();
    private Gee.Map<string, Gee.List<string>> operators_buffer = new Gee.HashMap<string, Gee.List<string>> ();
    private Gee.List<Iridium.Models.ChannelListEntry> channel_list = new Gee.ArrayList<Iridium.Models.ChannelListEntry> ();
    private Gee.List<Iridium.Models.ChannelListEntry> channel_buffer = new Gee.ArrayList<Iridium.Models.ChannelListEntry> ();

    private Gee.Map<string, string> channel_topics = new Gee.HashMap<string, string> ();

    public Iridium.Models.ServerSupports server_supports = new Iridium.Models.ServerSupports ();

    private string? connection_error_message = null;
    private string? connection_error_details = null;

    public ServerConnection (Iridium.Services.ServerConnectionDetails connection_details) {
        Object (
            connection_details: connection_details
        );
    }

    public void open () {
        should_exit = false;
        var server = connection_details.server;
        connection_thread = new Thread<int> (@"Server connection [$server]", do_connect);
    }

    private int do_connect () {
        try {
            var host = connection_details.server;
            var port = connection_details.port;
            var tls = connection_details.tls;
            connection = connect_to_server (host, port, tls);

            input_stream = new DataInputStream (connection.input_stream);
            output_stream = new DataOutputStream (connection.output_stream);

            register ();

            string line = "";
            do {
                try {
                    line = input_stream.read_line (null, cancellable);
                    handle_line (line);
                } catch (GLib.IOError e) {
                    // TODO: Handle this differently on initialization (currently fails silently in the background)
                    critical ("IOError while reading: %s\n", e.message);
                }
            } while (should_keep_reading (line));
        } catch (GLib.Error e) {
            critical ("Error while connecting: %s\n", e.message);
            if (connection_error_message == null) {
                open_failed (_("Error while connecting"), e.message);
            } else {
                open_failed (connection_error_message, connection_error_details);
            }
            connection_error_message = null;
            connection_error_details = null;
            return 0;
        }
        return 1;
    }

    private bool should_keep_reading (string? line) {
        lock (should_exit) {
            return line != null && !should_exit;
        }
    }

    private IOStream connect_to_server (string host, uint16 port, bool tls) throws GLib.Error {
        SocketClient client = new SocketClient ();
        client.event.connect (on_socket_client_event);
        client.set_tls (tls);
        client.set_tls_validation_flags (TlsCertificateFlags.VALIDATE_ALL);
        return client.connect (new NetworkAddress (host, port));

        // TODO: Set a timeout on the client (Might already have a default?)

        // TODO: Could use the NetworkMonitor to check the InetSocketAddress prior to attempting a connection
    }

    private void on_socket_client_event (SocketClientEvent event, SocketConnectable connectable, IOStream? connection) {
        // See https://valadoc.org/gio-2.0/GLib.SocketClient.event.html for event definitions
        switch (event) {
            case SocketClientEvent.COMPLETE:
                debug ("[SocketClientEvent] %s COMPLETE", connectable.to_string ());
                break;
            case SocketClientEvent.CONNECTED:
                debug ("[SocketClientEvent] %s CONNECTED", connectable.to_string ());
                break;
            case SocketClientEvent.CONNECTING:
                debug ("[SocketClientEvent] %s CONNECTING", connectable.to_string ());
                break;
            case SocketClientEvent.PROXY_NEGOTIATED:
                debug ("[SocketClientEvent] %s PROXY_NEGOTIATED", connectable.to_string ());
                break;
            case SocketClientEvent.PROXY_NEGOTIATING:
                debug ("[SocketClientEvent] %s PROXY_NEGOTIATING", connectable.to_string ());
                break;
            case SocketClientEvent.RESOLVED:
                debug ("[SocketClientEvent] %s RESOLVED", connectable.to_string ());
                break;
            case SocketClientEvent.RESOLVING:
                debug ("[SocketClientEvent] %s RESOLVING", connectable.to_string ());
                break;
            case SocketClientEvent.TLS_HANDSHAKED:
                debug ("[SocketClientEvent] %s TLS_HANDSHAKED", connectable.to_string ());
                break;
            case SocketClientEvent.TLS_HANDSHAKING:
                debug ("[SocketClientEvent] %s TLS_HANDSHAKING", connectable.to_string ());
                ((TlsClientConnection) connection).accept_certificate.connect ((peer_cert, errors) => {
                    return on_invalid_certificate (peer_cert, errors, connectable);
                });
                break;
            default:
                // Do nothing - per documentation, unrecognized events should be ignored as there may be
                // additional event values in the future
                break;
        }
    }

    private bool on_invalid_certificate (TlsCertificate peer_cert, TlsCertificateFlags errors, SocketConnectable connectable) {
        // TODO: Also see https://github.com/jangernert/FeedReader/blob/master/src/Utils.vala#L212
        TlsCertificateFlags[] flags = new TlsCertificateFlags[] {
            TlsCertificateFlags.BAD_IDENTITY,
            TlsCertificateFlags.EXPIRED,
            TlsCertificateFlags.GENERIC_ERROR,
            TlsCertificateFlags.INSECURE,
            TlsCertificateFlags.NOT_ACTIVATED,
            TlsCertificateFlags.REVOKED,
            TlsCertificateFlags.UNKNOWN_CA
        };
        string error_string = "";
        string formatted_error_string = "";
        Gee.List<TlsCertificateFlags> encountered_errors = new Gee.ArrayList<TlsCertificateFlags> ();
        foreach (var flag in flags) {
            if (flag in errors) {
                encountered_errors.add (flag);
                error_string += @"$(flag), ";
                formatted_error_string += " • " + Iridium.Models.CertificateErrorMapping.get_description (flag) + "\n";
            }
        }
        warning (@"TLS certificate errors: $(error_string)");

        var cert_policy = Iridium.Application.settings.get_string ("certificate-validation-policy");
        switch (Iridium.Models.InvalidCertificatePolicy.get_value_by_short_name (cert_policy)) {
            case REJECT:
                debug ("Rejecting certificate per policy");
                connection_error_details = _("Certificate rejected:") + "\n\n" + formatted_error_string + "\n" + _("See the application preferences to configure the certificate validation policy.");
                return false;
            case WARN:
                debug (@"Warning about certificate per policy: $(error_string)");

                // First check if the user has already verified or rejected this certificate
                var host = Iridium.Services.CertificateManager.parse_host (connectable);
                var identity = Iridium.Application.certificate_manager.lookup_identity (peer_cert, host);
                if (identity != null) {
                    debug ("Known server identity (is accepted: %s)", identity.is_accepted.to_string ());
                    return identity.is_accepted;
                }

                // Identity is not known, so prompt the user
                if (unacceptable_certificate (peer_cert, encountered_errors, connectable)) {
                    return true;
                } else {
                    connection_error_details = _("Certificate was rejected by the user.");
                    return false;
                }

                // TODO: Need a way to retro-actively accept a certificate?

                // TODO: Add visual indication of the security of the connection?
            case ALLOW:
                debug ("Allowing certificate per policy");
                return true;
            default:
                assert_not_reached ();
        }

    }

    private void register () {
        var nickname = connection_details.nickname;
        var username = connection_details.nickname; // Use nickname for both
        var realname = connection_details.realname;
        var mode = "+i";

        // Handle the various auth methods
        switch (connection_details.auth_method) {
            case Iridium.Models.AuthenticationMethod.NONE:
                debug ("AuthenticationMethod is NONE");
                send_output (@"NICK $nickname");
                send_output (@"USER $username 0 * :$realname");
                send_output (@"MODE $nickname $mode");
                break;
            case Iridium.Models.AuthenticationMethod.SERVER_PASSWORD:
                debug ("AuthenticationMethod is SERVER_PASSWORD");
                string? password = get_auth_token ();
                send_output (@"PASS $password");
                send_output (@"NICK $nickname");
                send_output (@"USER $username 0 * :$realname");
                send_output (@"MODE $nickname $mode");
                break;
            case Iridium.Models.AuthenticationMethod.NICKSERV_MSG:
                debug ("AuthenticationMethod is NICKSERV_MSG");
                string? password = get_auth_token ();
                send_output (@"NICK $nickname");
                send_output (@"USER $username 0 * :$realname");
                send_output (@"MODE $nickname $mode");
                send_output (@"NickServ identify $password");
                break;
            case Iridium.Models.AuthenticationMethod.SASL_PLAIN:
                debug ("AuthenticationMethod is SASL_PLAIN");
                //  string? password = get_auth_token (connection_details);
                //  send_output ("CAP LS 302");
                send_output ("CAP REQ :sasl");
                send_output (@"NICK $nickname");
                send_output (@"USER $username 0 * :$realname");
                break;
            default:
                assert_not_reached ();
        }
    }

    private string? get_auth_token () {
        string? password = null;
        if (connection_details.auth_token != null) {
            debug ("Password passed with request to open connection");
            password = connection_details.auth_token;
        } else {
            debug ("Retrieving password from secret manager");
            var server = connection_details.server;
            var port = connection_details.port;
            var nickname = connection_details.nickname;
            password = Iridium.Application.secret_manager.retrieve_secret (server, port, nickname);
            if (password == null) {
                // TODO: Handle this better!
                warning ("No password found for server: " + server + ", port: " + port.to_string () + ", nickname: " + nickname + "\n");
            }
        }
        return password;
    }

    private void handle_line (string? line) {
        if (line == null) {
            close ();
            return;
        }
        var message = new Iridium.Services.Message (line);
        if (Iridium.Application.is_dev_mode ()) {
            print (@"$line\n");
        }
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
            case Iridium.Services.MessageCommands.CAP:
                string subcommand = message.params[1];
                switch (subcommand) {
                    case Iridium.Services.MessageCommands.CAPSubcommands.LS:
                    case Iridium.Services.MessageCommands.CAPSubcommands.LIST:
                    case Iridium.Services.MessageCommands.CAPSubcommands.NEW:
                    case Iridium.Services.MessageCommands.CAPSubcommands.DEL:
                        warning (@"Unhandled CAP subcommand response from the server: $subcommand");
                        break;
                    case Iridium.Services.MessageCommands.CAPSubcommands.ACK:
                        string capability = message.message;
                        debug (@"Capability accepted by the server: $capability");
                        if (!is_registered && (capability == "sasl")) {
                            string mechanism = "PLAIN";
                            send_output (@"AUTHENTICATE $mechanism");
                        }
                        break;
                    case Iridium.Services.MessageCommands.CAPSubcommands.NAK:
                        if (!is_registered) {
                            string capability = message.message;
                            open_failed (_(@"Capability was rejected by the server: $capability"));
                        }
                        server_error_received (message);
                        break;
                    default:
                        warning ("Unexpected CAP subcommand from server: " + subcommand);
                        break;
                }
                break;
            case Iridium.Services.MessageCommands.AUTHENTICATE:
                if (is_registered) {
                    warning ("Received AUTHENTICATE command while in a registered state");
                    break;
                }
                // Some servers send the + as a param rather than the message
                if (message.message == "+" || (message.params.length > 0 && message.params[0] == "+")) {
                    string nickname = connection_details.nickname;
                    string auth_token = get_auth_token ();
                    // Create an unencoded array with separators, because we can't use \0 with the string without breaking things
                    var sep = 0x0;
                    uint8[] unencoded = @"$nickname$sep$nickname$sep$auth_token".data;
                    // Now fill in the \0 separators in the data array
                    unencoded[nickname.length] = '\0';
                    unencoded[2 * nickname.length + 1] = '\0';
                    // Base64 encode the data
                    string encoded = GLib.Base64.encode (unencoded);
                    // Prevent free() errors
                    unencoded = null;
                    send_output (@"AUTHENTICATE $encoded");
                }
                break;
            case Iridium.Services.NumericCodes.RPL_SASLSUCCESS:
                send_output ("CAP END");
                break;
            case Iridium.Services.MessageCommands.NOTICE:
            case Iridium.Services.NumericCodes.RPL_CREATED:
            case Iridium.Services.NumericCodes.RPL_MOTD:
            case Iridium.Services.NumericCodes.RPL_MOTDSTART:
            case Iridium.Services.NumericCodes.RPL_YOURHOST:
            case Iridium.Services.NumericCodes.RPL_LUSERCLIENT:
            case Iridium.Services.NumericCodes.RPL_SERVLIST:
            case Iridium.Services.NumericCodes.RPL_ENDOFSTATS:
            case Iridium.Services.NumericCodes.RPL_STATSLINKINFO:
                server_message_received (message);
                break;
            case Iridium.Services.NumericCodes.RPL_WELCOME:
                is_registered = true;
                open_successful (connection_details.nickname, message);
                break;
            case Iridium.Services.NumericCodes.RPL_ISUPPORT:
                // Skip the first param because it's our nickname
                for (int i = 1; i < message.params.length; i++) {
                    // Append the new parameter to our model and then check for any
                    // signals that need to be sent
                    switch (server_supports.append (message.params[i])) {
                        case Iridium.Models.ServerSupportsParameters.NETWORK:
                            network_name_received (server_supports.network);
                            break;
                        default:
                            break;
                    }
                }
                // Display in the server chat view
                var display_message = new Iridium.Services.Message ();
                for (int i = 0; i < message.params.length; i++) {
                    if (i == 0) {
                        continue;
                    }
                    display_message.message += message.params[i] + " ";
                }
                display_message.message += message.message;
                server_message_received (display_message);
                break;
            case Iridium.Services.MessageCommands.QUIT:
                if (message.nickname == connection_details.nickname) {
                    server_quit (message.message);
                } else {
                    on_user_quit_server (message.nickname, message);
                }
                break;
            case Iridium.Services.MessageCommands.JOIN:
                // If the message nickname is our nickname, we're the one
                // joining. Otherwise, it's another user joining.
                if (message.nickname == connection_details.nickname) {
                    if (message.message == null || message.message.strip () == "") {
                        joined_channels.add (message.params[0]);
                        channel_joined (message.params[0], connection_details.nickname);
                    } else {
                        joined_channels.add (message.message);
                        channel_joined (message.message, connection_details.nickname);
                    }
                } else {
                    if (message.message == null || message.message.strip () == "") {
                        on_user_joined_channel (message.params[0], message.nickname);
                    } else {
                        on_user_joined_channel (message.message, message.nickname);
                    }
                }
                break;
            case Iridium.Services.MessageCommands.PART:
                // If the message nickname is our nickname, we're the one
                // leaving. Otherwise, it's another user leaving.
                if (message.nickname == connection_details.nickname) {
                    if (message.message == null || message.message.strip () == "") {
                        joined_channels.remove (message.params[0]);
                        channel_left (message.params[0]);
                    } else {
                        joined_channels.remove (message.message);
                        channel_left (message.message);
                    }
                } else {
                    on_user_left_channel (message.params[0], message.nickname);
                }
                break;
            case Iridium.Services.MessageCommands.PRIVMSG:
                // CTCP VERSION
                if ("\x01%s\x01".printf (Iridium.Services.MessageCommands.VERSION) == message.message) {
                    ctcp_version_query_received (message);
                    break;
                }
                // Action message
                if (message.message[0] == '\x01' && message.message[message.message.length - 1] == '\x01' && message.message.substring (1).has_prefix ("ACTION")) {
                    // If the first param is our nickname, it's an action in a private message not a channel
                    string channel = message.params[0] == connection_details.nickname ? message.nickname : message.params[0];
                    action_message_received (channel, message.nickname, connection_details.nickname, message.message.substring (8, message.message.length - 9));
                    break;
                }
                // If the first param is our nickname, it's a PM. Otherwise, it's
                // a general message on a channel
                if (message.params[0] == connection_details.nickname) {
                    //  print ("received message from %s to %s\n", message.nickname, connection_details.nickname);
                    private_message_received (message.nickname, connection_details.nickname, message);
                } else {
                    channel_message_received (message.params[0], message);
                }
                break;
            case Iridium.Services.MessageCommands.NICK:
                // If the nickname is our nickname, we've changed our nickname. Otherwise,
                // another use has changed their nickname.
                if (message.nickname == connection_details.nickname) {
                    on_nickname_changed (message.message);
                } else {
                    on_user_changed_nickname (message.nickname, message.message);
                }
                break;
            case Iridium.Services.NumericCodes.RPL_NAMREPLY:
                nicknames_received (message.params[2], message.message.split (" "));
                break;
            case Iridium.Services.NumericCodes.RPL_ENDOFNAMES:
                end_of_nicknames (message.params[1]);
                break;
            case Iridium.Services.MessageCommands.TOPIC:
                on_channel_topic_received (message.params[0], message.message);
                on_channel_topic_changed (message.params[0], message.prefix.split ("!")[0]);
                break;
            case Iridium.Services.NumericCodes.RPL_TOPIC:
                on_channel_topic_received (message.params[1], message.message);
                break;
            case Iridium.Services.NumericCodes.RPL_TOPICWHOTIME:
                // Some servers send the setat time string as the message, not a param
                string time_str = message.params[3] != null ? message.params[3] : message.message;
                channel_topic_whotime_received (message.params[1], message.params[2].split ("!")[0], int64.parse (time_str));
                break;
            case Iridium.Services.NumericCodes.RPL_NOTOPIC:
                on_channel_topic_received (message.params[1], "");
                break;
            case Iridium.Services.NumericCodes.RPL_LUSEROP:
            case Iridium.Services.NumericCodes.RPL_LUSERUNKNOWN:
            case Iridium.Services.NumericCodes.RPL_LUSERCHANNELS:
                var display_message = new Iridium.Services.Message ();
                display_message.message = message.params[1] + " " + message.message;
                server_message_received (display_message);
                break;
            case Iridium.Services.MessageCommands.MODE:
                // If the first param is our nickname, this is being set on the server rather than for a channel
                if (message.params[0] == connection_details.nickname) {
                    char modifier = message.message[0];
                    for (int i = 1; i < message.message.length; i++) {
                        var display_message = new Iridium.Services.Message ();
                        display_message.message = "%s sets mode %c%c on %s".printf (message.prefix, modifier, message.message[i], message.params[0]);
                        server_message_received (display_message);
                    }
                    break;
                }

                // params[0] = channel
                // params[1] = mode chars
                // params[2] = params
                string channel = message.params[0];
                string mode_chars = message.params[1];

                if (message.params[2] != null) {
                    string nickname = message.prefix.split ("!")[0];
                    string target_nickname = message.params[2];
                    if (mode_chars == "+o") {
                        // Only add the nickname to the operators list if not already present
                        if (channel_operators.has_key (channel) && !channel_operators.get (channel).contains (target_nickname)) {
                            channel_operators.get (channel).add (target_nickname);
                        }
                    } else if (mode_chars == "-o") {
                        // Only remove the nickname from the operators list if present
                        if (channel_operators.has_key (channel) && channel_operators.get (channel).contains (target_nickname)) {
                            channel_operators.get (channel).remove (target_nickname);
                        }
                    }
                    user_channel_mode_changed (channel, mode_chars, nickname, target_nickname);
                }

                break;
            case Iridium.Services.NumericCodes.RPL_ENDOFMOTD:
                // Do nothing
                break;
            case Iridium.Services.NumericCodes.RPL_UMODEIS:
                var display_message = new Iridium.Services.Message ();
                display_message.message = message.params[0] + " has modes: " + message.params[1];
                server_message_received (display_message);
                break;
            case Iridium.Services.NumericCodes.RPL_LISTSTART:
                channel_buffer.clear ();
                break;
            case Iridium.Services.NumericCodes.RPL_LIST:
                if (message.params[1] == null) {
                    break;
                }
                var channel_name = message.params[1];
                var num_visible_users = message.params[2] == null ? "0" : message.params[2];
                var topic = message.message == null ? "" : message.message.strip ();
                Iridium.Models.ChannelListEntry entry = new Iridium.Models.ChannelListEntry ();
                entry.channel_name = channel_name;
                entry.num_visible_users = num_visible_users;
                entry.topic = topic;
                channel_buffer.add (entry);
                break;
            case Iridium.Services.NumericCodes.RPL_LISTEND:
                channel_list.clear ();
                channel_list.add_all (channel_buffer);
                channel_buffer.clear ();
                channel_list_received (channel_list);
                break;
            case Iridium.Services.NumericCodes.RPL_TRYAGAIN:
                server_error_received (message);
                break;

            // Errors
            case Iridium.Services.NumericCodes.ERR_SASLFAIL:
                if (!is_registered) {
                    open_failed (message.message);
                }
                server_error_received (message);
                break;
            case Iridium.Services.NumericCodes.ERR_ERRONEOUSNICKNAME:
                // If this error occurs during the initial connection, the current
                // nickname will be an asterisk (*)
                var current_nickname = message.params[0];
                var requested_nickname = message.params[1];
                erroneous_nickname (current_nickname, requested_nickname);
                break;
            case Iridium.Services.NumericCodes.ERR_NICKNAMEINUSE:
                nickname_in_use (message);
                break;
            case Iridium.Services.NumericCodes.ERR_CHANOPRIVSNEEDED:
                insufficient_privs (message.params[1], message);
                // Can remove this once errors are implemented in the channel chat view
                server_error_received (message);
                break;
            case Iridium.Services.NumericCodes.ERR_NEEDMOREPARAMS:
                var display_message = new Iridium.Services.Message ();
                display_message.message = "%s for command: %s".printf (message.message, message.params[1]);
                server_error_received (display_message);
                break;
            case Iridium.Services.NumericCodes.ERR_BADCHANMASK:
            case Iridium.Services.NumericCodes.ERR_NOSUCHCHANNEL:
                // If the first character of the channel isn't '#', display a (possibly) helpful message
                if (message.params[1][0] != '#') {
                    var display_message = new Iridium.Services.Message ();
                    display_message.message = "%s: '%s' (Did you mean '#%s'?)".printf (message.message, message.params[1], message.params[1]);
                    server_error_received (display_message);
                } else {
                    server_error_received (message);
                }
                break;
            case Iridium.Services.NumericCodes.ERR_NORECIPIENT:
            case Iridium.Services.NumericCodes.ERR_NOTEXTTOSEND:
            case Iridium.Services.NumericCodes.ERR_UNKNOWNCOMMAND:
            case Iridium.Services.NumericCodes.ERR_NOSUCHNICK:
            case Iridium.Services.NumericCodes.ERR_CANNOTSENDTOCHAN:
                // TODO: Handle no such nick for sending a PM. Should display the server 
                //       error in the channel view, not the server view.
            case Iridium.Services.NumericCodes.ERR_NOMOTD:
            case Iridium.Services.NumericCodes.ERR_USERNOTINCHANNEL:
            case Iridium.Services.NumericCodes.ERR_NOTONCHANNEL:
            case Iridium.Services.NumericCodes.ERR_NOTREGISTERED:
            case Iridium.Services.NumericCodes.ERR_PASSWDMISMATCH:
            case Iridium.Services.NumericCodes.ERR_YOUREBANNEDCREEP:
            case Iridium.Services.NumericCodes.ERR_YOUWILLBEBANNED:
            case Iridium.Services.NumericCodes.ERR_UNKNOWNMODE:
            case Iridium.Services.NumericCodes.ERR_USERSDONTMATCH:
                server_error_received (message);
                break;
            default:
                warning ("Command or numeric code not implemented: %s", message.command);
                break;
        }
    }

    public void join_channel (string name) {
        send_output (Iridium.Services.MessageCommands.JOIN + " " + name);
    }

    public void close () {
        debug ("Closing connection for server: " + connection_details.server);
        lock (should_exit) {
            should_exit = true;
        }
        send_output (Iridium.Services.MessageCommands.QUIT + " :Iridium IRC Client");
        channel_users.clear ();
        do_close ();
    }

    private void do_close () {
        lock (should_exit) {
            should_exit = true;
        }

        try {
            connection.close ();
        } catch (GLib.IOError e) {
            warning ("Error while closing connection: %s", e.message);
        }
        cancellable.cancel ();

        foreach (var channel in joined_channels) {
            channel_left (channel);
        }
        joined_channels.clear ();
        connection_closed ();
    }

    public void send_user_message (string text) {
        send_output (text);
    }

    public void leave_channel (string channel_name) {
        send_output (Iridium.Services.MessageCommands.PART + " " + channel_name);
        // Clear out our list of channel users
        if (!channel_users.has_key (channel_name)) {
            // TODO: Might be better to initialize this to an empty list when we join the channel
            channel_users.set (channel_name, new Gee.LinkedList<string> ());
        }
    }

    public Gee.List<string> get_users (string channel_name) {
        if (!channel_users.has_key (channel_name)) {
            return new Gee.LinkedList<string> ();
        }
        return channel_users.get (channel_name);
    }

    public Gee.List<string> get_operators (string channel_name) {
        if (!channel_operators.has_key (channel_name)) {
            return new Gee.LinkedList<string> ();
        }
        return channel_operators.get (channel_name);
    }

    public Gee.List<string> get_joined_channels () {
        return joined_channels;
    }

    private void send_output (string output) {
        try {
            output_stream.put_string (@"$output\r\n");
        } catch (GLib.IOError e) {
            critical ("Error while sending output for server connection: %s", e.message);
            // TODO: Handle errors!!
        }
    }

    private void on_nickname_changed (string new_nickname) {
        debug ("We've changed our nickname to %s", new_nickname);
        string old_nickname = connection_details.nickname;

        // Update the data model for channel users
        foreach (var entry in channel_users.entries) {
            foreach (var user in entry.value) {
                var user_nickname = new Iridium.Models.Nickname (user);
                // Have to compare against the simple name, since the prefixes aren't
                // included in the NICK messages
                if (user_nickname.simple_name == old_nickname) {
                    channel_users.get (entry.key).remove (user);
                    var new_nick = (user_nickname.prefix == null ? "" : user_nickname.prefix) + new_nickname;
                    channel_users.get (entry.key).add (new_nick);
                }
            }
        }

        // Update connection details
        connection_details.nickname = new_nickname;

        // Send signal
        nickname_changed (old_nickname, new_nickname);
    }

    private void on_user_changed_nickname (string old_nickname, string new_nickname) {
        //  foreach (var channel_name in joined_channels) {
        //      request_updated_channel_users (channel_name);
        //  }

        // Update the data model for channel users
        foreach (var entry in channel_users.entries) {
            foreach (var user in entry.value) {
                var user_nickname = new Iridium.Models.Nickname (user);
                // Have to compare against the simple name, since the prefixes aren't
                // included in the NICK messages
                if (user_nickname.simple_name == old_nickname) {
                    channel_users.get (entry.key).remove (user);
                    var new_nick = (user_nickname.prefix == null ? "" : user_nickname.prefix) + new_nickname;
                    channel_users.get (entry.key).add (new_nick);
                }
            }
        }
        user_changed_nickname (old_nickname, new_nickname);
    }

    public void set_nickname (string new_nickname) {
        send_output (Iridium.Services.MessageCommands.NICK + " " + new_nickname);
    }

    private void nicknames_received (string channel_name, string[] nicknames) {
        // Initialize the buffers to an empty list
        if (!nickname_buffer.has_key (channel_name) || nickname_buffer.get (channel_name) == null) {
            nickname_buffer.set (channel_name, new Gee.LinkedList<string> ());
        }
        if (!operators_buffer.has_key (channel_name) || operators_buffer.get (channel_name) == null) {
            operators_buffer.set (channel_name, new Gee.LinkedList<string> ());
        }
        // Add each new nickname to the buffer
        foreach (string nickname in nicknames) {
            nickname_buffer.get (channel_name).add (nickname);
            if (nickname.has_prefix ("@")) {
                operators_buffer.get (channel_name).add (nickname);
            }
        }
    }

    private void end_of_nicknames (string channel_name) {
        // Copy the buffered nicknames over to the master map of users by channel
        channel_users.unset (channel_name);
        channel_users.set (channel_name, nickname_buffer.get (channel_name));
        channel_operators.unset (channel_name);
        channel_operators.set (channel_name, operators_buffer.get (channel_name));
        //  foreach (var user in channel_users.get (channel_name)) {
        //      print (user + ", ");
        //  }
        //  print ("\n");
        // Clear the buffered nicknames
        nickname_buffer.unset (channel_name);
        operators_buffer.unset (channel_name);
        // Send the signal
        channel_users_received (channel_name);
    }

    private void ctcp_version_query_received (Iridium.Services.Message message) {
        send_output (Iridium.Services.MessageCommands.VERSION + " " + Constants.APP_ID + " " + Constants.VERSION);
        var display_message = new Iridium.Services.Message ();
        display_message.message = "Received a CTCP VERSION query from " + message.nickname;
        server_message_received (display_message);
    }

    private void on_user_joined_channel (string channel_name, string nickname) {
        // Update our list of users in channels
        channel_users.get (channel_name).add (nickname);
        // Send the signal
        user_joined_channel (channel_name, nickname);
    }

    private void on_user_left_channel (string channel_name, string nickname) {
        // Update our list of users in channels
        channel_users.get (channel_name).remove (nickname);
        // Send the signal
        user_left_channel (channel_name, nickname);
    }

    private void on_user_quit_server (string nickname, Iridium.Services.Message message) {
        // Update our list of users in channels, and get the list of channels
        // that the user was in (that we care about)
        Gee.List<string> channels = new Gee.LinkedList<string> ();
        foreach (Gee.Map.Entry<string, Gee.List<string>> entry in channel_users.entries) {
            if (entry.value.remove (nickname)) {
                channels.add (entry.key);
            }
        }
        // Send the signal
        user_quit_server (nickname, channels, message);
    }

    private void on_channel_topic_received (string channel_name, string? topic) {
        channel_topics.set (channel_name, topic);
        channel_topic_received (channel_name);
    }

    private void on_channel_topic_changed (string channel_name, string nickname) {
        channel_topic_changed (channel_name, nickname);
    }

    //  private void request_updated_channel_users (string channel_name) {
    //      send_output (Iridium.Services.MessageCommands.NAMES + " " + channel_name);
    //  }

    public string? get_channel_topic (string channel_name) {
        if (!channel_topics.has_key (channel_name)) {
            return "";
        }
        return channel_topics.get (channel_name);
    }

    public void set_channel_topic (string channel_name, string topic) {
        send_output (Iridium.Services.MessageCommands.TOPIC + " " + channel_name + " :" + topic);
    }

    public Gee.List<Iridium.Models.ChannelListEntry> get_channel_list () {
        return channel_list;
    }

    public void request_channel_list () {
        // TODO: Add a parameter to force? This should be cached ideally, it's a large list that we don't want to re-fetch
        // ever time the dialog is opened.
        send_output (Iridium.Services.MessageCommands.LIST);
    }

    public signal bool unacceptable_certificate (TlsCertificate peer_cert, Gee.List<TlsCertificateFlags> errors, SocketConnectable connectable);
    public signal void open_successful (string nickname, Iridium.Services.Message message);
    public signal void open_failed (string error_message, string? error_details = null);
    public signal void connection_closed ();
    /* public signal void close_failed (string message); */
    public signal void server_message_received (Iridium.Services.Message message);
    public signal void server_error_received (Iridium.Services.Message message);
    public signal void server_quit (string message);
    public signal void user_quit_server (string nickname, Gee.List<string> channels, Iridium.Services.Message message);
    public signal void channel_users_received (string channel);
    public signal void channel_topic_received (string channel);
    public signal void channel_topic_changed (string channel, string nickname);
    public signal void channel_topic_whotime_received (string channel, string nickname, int64 unix_utc);
    public signal void nickname_in_use (Iridium.Services.Message message);
    public signal void erroneous_nickname (string current_nickname, string requested_nickname);
    public signal void channel_joined (string channel, string nickname);
    public signal void channel_left (string channel);
    public signal void channel_message_received (string channel_name, Iridium.Services.Message message);
    public signal void user_joined_channel (string channel_name, string nickname);
    public signal void user_left_channel (string channel_name, string nickname);
    public signal void private_message_received (string nickname, string self_nickname, Iridium.Services.Message message);
    public signal void insufficient_privs (string channel_name, Iridium.Services.Message message);
    public signal void nickname_changed (string old_nickname, string new_nickname);
    public signal void user_changed_nickname (string old_nickname, string new_nickname);
    public signal void network_name_received (string network_name);
    public signal void user_channel_mode_changed (string channel_name, string mode_chars, string nickname, string target_nickname);
    public signal void action_message_received (string channel_name, string nickname, string self_nickname, string action);
    public signal void channel_list_received (Gee.List<Iridium.Models.ChannelListEntry> channel_list);

}
