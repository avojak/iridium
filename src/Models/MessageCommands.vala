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

public class Iridium.Services.MessageCommands : GLib.Object {

    // Connection messages
    public const string CAP = "CAP";
    public const string AUTHENTICATE = "AUTHENTICATE";
    public const string PASS = "PASS";
    public const string NICK = "NICK";
    public const string USER = "USER";
    public const string OPER = "OPER";
    public const string QUIT = "QUIT";

    // Channel operations
    public const string JOIN = "JOIN";
    public const string PART = "PART";
    public const string TOPIC = "TOPIC";
    public const string NAMES = "NAMES";
    public const string LIST = "LIST";

    // Server queries and commands
    public const string MOTD = "MOTD";
    public const string VERSION = "VERSION";
    public const string ADMIN = "ADMIN";
    public const string CONNECT = "CONNECT";
    public const string TIME = "TIME";
    public const string STATS = "STATS";
    public const string INFO = "INFO";
    public const string MODE = "MODE";

    // Sending messages
    public const string PRIVMSG = "PRIVMSG";
    public const string NOTICE = "NOTICE";

    // Optional messages
    public const string USERHOST = "USERHOST";

    // Miscellaneous messages
    public const string KILL = "KILL";

}
