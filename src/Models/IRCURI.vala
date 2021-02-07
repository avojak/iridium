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
    //  public string host { get; set; }
    //  public uint port { get; set; }
    public string? target { get; set; }
    public string? modifiers { get; set; }


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
        uri_string = uri.to_string (false).chomp ().chug ();
        if (uri_string.length == 0) {
            return;
        }

        string host = uri.get_host ().chomp ().chug ();
        uint port = uri.get_port ();
        string? fragment = uri.get_fragment ();
        string path = uri.get_path ().chomp ().chug ();
        string? user = uri.get_user ();
        string? password = uri.get_password ();
        debug ("Host: %s", host);
        debug ("Port: %s", port.to_string ());
        debug ("Fragment: %s", fragment);
        debug ("Path: %s", path);
        debug ("User: %s", user);
        debug ("Password: %s", password);

        //  host = uri.get_host ().chomp ().chug ();
        //  port = uri.get_port ();

        

        try {
            REGEX.replace_eval (path, -1, 0, 0, (match_info, result) => {
                target = match_info.fetch_named ("target");
                if (match_info.fetch_named ("modifiers") != null) {
                    modifiers = match_info.fetch_named ("modifiers");
                }
                return false;
            });
        } catch (GLib.RegexError e) {
            warning ("Error while parsing URI with regex: %s", e.message);
        }

        debug ("Target: %s", target);
        debug ("Modifiers: %s", modifiers);
    }

    //  private void parse_uri () {
    //      try {
    //          REGEX.replace_eval (message, -1, 0, 0, (match_info, result) => {
    //              prefix = match_info.fetch_named ("prefix");
    //              command = match_info.fetch_named ("command");
    //              if (match_info.fetch_named ("params") != null) {
    //                  params = match_info.fetch_named ("params").split (" ");
    //              }
    //              message = match_info.fetch_named ("trail");
    //              if (message != null) {
    //                  message.replace ("\t", "");
    //                  strip_non_printable_chars ();
    //              }
    //              if ((prefix != null) && (command in USER_COMMANDS)) {  // vala-lint=naming-convention
    //                  nickname = prefix.split ("!")[0];
    //              }
    //              return false;
    //          });
    //      } catch (GLib.RegexError e) {
    //          // TODO: Handle errors!
    //          warning ("Error while parsing message with regex: %s", e.message);
    //      }
    //  }

}
