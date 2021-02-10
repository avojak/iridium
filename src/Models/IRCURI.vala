/*
 * Copyright (c) 2021 Andrew Vojak (https://avojak.com)
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

public class Iridium.Models.IRCURI : GLib.Object {

    //  private const string REGEX_STR = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$""";
    private const string REGEX_STR = """^(/(?<target>[^,]+)(?<modifiers>,\S+))$""";
    private static GLib.Regex REGEX; // vala-lint=naming-convention

    public string command { get; set; }
    public string message { get; set; }
    public string prefix { get; set; }
    public string[] params { get; set; }
    public string nickname { get; set; }

    public string uri_string { get; set; }
    public string host { get; set; }
    public uint port { get; set; }
    public string? target { get; set; }
    public GLib.List<Iridium.Models.IRCURIModifier> modifiers = new GLib.List<Iridium.Models.IRCURIModifier> ();


    static construct {
        try {
            REGEX = new GLib.Regex (REGEX_STR, GLib.RegexCompileFlags.OPTIMIZE);
            //  NON_PRINT_REGEX = new GLib.Regex (NON_PRINT_REGEX_STR, GLib.RegexCompileFlags.OPTIMIZE);
        } catch (GLib.RegexError e) {
            // TODO: Handle errors!
            // This should never ever happen
            error ("Error while constructing regex: %s", e.message);
        }
    }

    public IRCURI (Soup.URI uri) {
        uri_string = Soup.URI.decode (uri.to_string (false).chomp ().chug ()).down ();
        debug ("URI string: %s", uri_string);
        if (uri_string.length == 0) {
            return;
        }

        host = uri.get_host ().chomp ().chug ().down ();
        port = uri.get_port ();
        string? fragment = uri.get_fragment ();
        string path = Soup.URI.decode (uri.get_path ().chomp ().chug ()).down ();
        string? user = uri.get_user ();
        string? password = uri.get_password ();
        debug ("Host: %s", host);
        debug ("Port: %s", port.to_string ());
        debug ("Fragment: %s", fragment);
        debug ("Path: %s", path);
        debug ("User: %s", user);
        debug ("Password: %s", password);

        

        try {
            REGEX.replace_eval (path, -1, 0, 0, (match_info, result) => {
                target = Soup.URI.decode (match_info.fetch_named ("target")).chomp ().chug ();
                if (match_info.fetch_named ("modifiers") != null) {
                    string[] modifier_tokens = match_info.fetch_named ("modifiers").split(",");
                    foreach (var modifier_token in modifier_tokens) {
                        if (modifier_token.chomp ().chug () != "") {
                            Iridium.Models.IRCURIModifier? modifier = Iridium.Models.IRCURIModifier.get_value_by_string (modifier_token.chomp ().chug ().down ());
                            if (modifier != null) {
                                modifiers.append (modifier);
                            }
                        }
                    }
                }
                return false;
            });
        } catch (GLib.RegexError e) {
            warning ("Error while parsing URI with regex: %s", e.message);
        }

        debug ("Target: %s", target);
        debug ("Modifiers:");
        foreach (var modifier in modifiers) {
            debug ("- %s", modifier.get_modifier_string ());
        }
    }

    public string? get_target_user () {
        if (target.length == 0) {
            // No target
            return null;
        }
        if (target.has_prefix ("#") || target.has_prefix ("+") || target.has_prefix ("&")) {
            // Target is a channel
            return null;
        } else if (modifiers.find (IRCURIModifier.IS_NICK) == null) {
            // No channel prefix and no isnick modifier means this should be treated as a channel name
            return null;
        }
        // A target user could have additional nickinfo or userinfo, so trim that off
        return target.split ("!")[0];
    }

    public string? get_target_channel () {
        if (target.length == 0) {
            // No target
            return null;
        }
        if (modifiers.find (IRCURIModifier.IS_NICK) != null) {
            // The isnick modifier means this should be treated as a nick
            return null;
        }
        if (target.has_prefix ("#") || target.has_prefix ("+") || target.has_prefix ("&")) {
            // If the URI has a channel prefix, keep it
            return target;
        }
        // No channel prefix provided, but this is a channel, so provide the default prefix
        return @"#$target";
    }

    public string? get_network () {
        if (modifiers.find (IRCURIModifier.IS_SERVER) != null) {
            // The isserver modifier means this should be treated as a server, not a network name
            return null;
        }
        if (host == "") {
            // We don't have a concept of a default network
            return null;
        }
        if (host.contains (".")) {
            // Treat this as a server
            return null;
        }
        return host;
    }

    public string? get_server () {
        if (host == "") {
            // The default server is the localhost
            return "localhost";
        }
        if ((modifiers.find (IRCURIModifier.IS_SERVER) == null) && !host.contains (".")) {
            // No isserver modifier and no . indicates this should be treated as a network name
            return null;
        }
        return host;
    }

    public uint get_connection_port () {
        if (port == 0) {
            return 6667;
        }
        return port;
    }

}
