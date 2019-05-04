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

public class Iridium.Application : Gtk.Application {

    public static GLib.Settings settings;
    public static Iridium.Services.ServerConnectionHandler connection_handler;

    public Application () {
        Object (
            application_id: "com.github.avojak.iridium",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        settings = new GLib.Settings ("com.github.avojak.iridium");
        connection_handler = new Iridium.Services.ServerConnectionHandler ();
    }

    protected override void activate () {
        var main_window = new Iridium.MainWindow (this);
        main_window.show_all ();

        /* var server = "irc.freenode.net";
        var nickname = "iridium_bot";
        var username = "iridium_bot";
        var realname = "Iridium IRC Bot";
        var c = new Iridium.Services.ServerConnection (server, nickname, username, realname);
        c.do_connect (); */

        // var channel = "#irchacks";
    }

    public static int main (string[] args) {
        var app = new Iridium.Application ();
        return app.run (args);
    }

}
