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

/*
 * This implementation is VERY heavily inspired by
 * https://github.com/agronick/Relay/blob/master/src/message.vala
 */
public class Iridium.Services.Message : GLib.Object {

    private static string REGEX_STR = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$"""; // vala-lint=naming-convention
    private static string ESCAPE_EXCEPT_CHARS = "\b\f\n\r\t\'"; // vala-lint=naming-convention
    private static string NON_PRINT_REGEX_STR = """[\x01]"""; // vala-lint=naming-convention
    private static string[] USER_COMMANDS = { // vala-lint=naming-convention
        Iridium.Services.MessageCommands.PRIVMSG,
        Iridium.Services.MessageCommands.JOIN,
        Iridium.Services.MessageCommands.NICK,
        Iridium.Services.MessageCommands.QUIT,
        Iridium.Services.MessageCommands.PART
    };
    private static GLib.Regex REGEX; // vala-lint=naming-convention
    private static GLib.Regex NON_PRINT_REGEX; // vala-lint=naming-convention

    public string command { get; set; }
    public string message { get; set; }
    public string prefix { get; set; }
    public string[] params { get; set; }
    public string username { get; set; }

    static construct {
        try {
            REGEX = new GLib.Regex (REGEX_STR, GLib.RegexCompileFlags.OPTIMIZE);
            NON_PRINT_REGEX = new GLib.Regex (NON_PRINT_REGEX_STR, GLib.RegexCompileFlags.OPTIMIZE);
        } catch (GLib.RegexError e) {
            // TODO: Handle errors!
            // This should never ever happen
            error ("Error while constructing regex: %s", e.message);
        }
    }

    public Message (string _message = "") {
        if (_message.strip ().length == 0) {
            message = _message;
            return;
        }
        message = _message.validate () ? _message : _message.escape (ESCAPE_EXCEPT_CHARS);
        parse_message ();
    }

    private void parse_message () {
        try {
            REGEX.replace_eval (message, -1, 0, 0, (match_info, result) => {
                prefix = match_info.fetch_named ("prefix");
                command = match_info.fetch_named ("command");
                if (match_info.fetch_named ("params") != null) {
                    params = match_info.fetch_named ("params").split (" ");
                }
                message = match_info.fetch_named ("trail");
                if (message != null) {
                    message.replace ("\t", "");
                    strip_non_printable_chars ();
                }
                if ((prefix != null) && (command in USER_COMMANDS)) {  // vala-lint=naming-convention
                    username = prefix.split ("!")[0];
                }
                return false;
            });
        } catch (GLib.RegexError e) {
            // TODO: Handle errors!
            error ("Error while parsing message with regex: %s", e.message);
        }
    }

    private void strip_non_printable_chars () {
        // TODO: Probably a better way to do this
        if (NON_PRINT_REGEX.match (message[0].to_string ())) {
            message = message.substring (1);
        }
        if (NON_PRINT_REGEX.match (message[message.length - 1].to_string ())) {
            message = message.substring (0, message.length - 1);
        }
    }

}
