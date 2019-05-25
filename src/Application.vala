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

    public static Iridium.Services.Settings settings;

    private static Iridium.Services.ServerConnectionHandler connection_handler;

    public Application () {
        Object (
            application_id: "com.github.avojak.iridium",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        settings = new Iridium.Services.Settings ();
        connection_handler = new Iridium.Services.ServerConnectionHandler ();
    }

    protected override void activate () {
        var main_window = new Iridium.MainWindow (this, connection_handler);
        main_window.show_all ();

        // TODO: Use NetworkMonitor to handle lost internet connection

        restore_state ();
    }

    private void restore_state () {
        // TODO: Implement
    }

    public static int main (string[] args) {
        var app = new Iridium.Application ();
        return app.run (args);
    }

}
