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

    private static string REGEX_STR = """^(:(?<prefix>\S+) )?(?<command>\S+)( (?!:)(?<params>.+?))?( :(?<trail>.+))?$""";
    private static string ESCAPE_EXCEPT_CHARS = "\b\f\n\r\t\'";
    private static string[] USER_COMMANDS = {
        Iridium.Services.MessageCommands.PRIVMSG,
        Iridium.Services.MessageCommands.JOIN,
        Iridium.Services.MessageCommands.NICK,
        Iridium.Services.MessageCommands.QUIT,
        Iridium.Services.MessageCommands.PART
    };
    private static GLib.Regex regex;

    public string command { get; set; }
    public string message { get; set; }
    private string prefix;
    private string[] params;
    private string username;

    static construct {
        try {
            regex = new GLib.Regex (REGEX_STR, GLib.RegexCompileFlags.OPTIMIZE);
        } catch (GLib.RegexError e) {
            // TODO: Handle errors!
            // This should never ever happen
        }
    }

    public Message (string _message) {
        message = _message.validate() ? _message : _message.escape (ESCAPE_EXCEPT_CHARS);
        parse_message ();
    }

    private void parse_message () {
        try {
            regex.replace_eval (message, -1, 0, 0, (match_info, result) => {
                prefix = match_info.fetch_named ("prefix");
                command = match_info.fetch_named ("command");
                if (match_info.fetch_named ("params") != null) {
                    params = match_info.fetch_named ("params").split (" ");
                }
                message = match_info.fetch_named ("trail");
                if (message != null) {
                    message.replace ("\t", "");
                }
                if ((prefix != null) && (command in USER_COMMANDS)) {
                    username = prefix.split ("!")[0];
                }
                return false;
            });
        } catch (GLib.RegexError e) {
            // TODO: Handle errors!
        }
    }

}
