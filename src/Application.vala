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

public class Iridium : Gtk.Application {

    public Iridium () {
        Object (
            application_id: "com.github.avojak.iridium",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new MainWindow (this);
        main_window.show_all ();

        var server = "irc.freenode.net";
        var nickname = "iridium_bot";
        var username = "iridium_bot";
        var realname = "Iridium IRC Bot";
        var c = new ServerConnection (server, nickname, username, realname);
        c.open_connection ();
        /* var server_handler = new ServerHandler (main_window);
        var server = "irc.freenode.net";
        var nick = "iridium_bot";
        var login = "iridium_bot";
        var channel = "#irchacks";
        server_handler.handle (server, nick, login, channel); */
    }

    public static int main (string[] args) {
        var app = new Iridium ();
        return app.run (args);
    }

}
