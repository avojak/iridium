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
    public static Iridium.Services.ServerConnectionRepository connection_repository;
    public static Iridium.Services.SecretManager secret_manager;
    public static Iridium.Services.CertificateManager certificate_manager;
    public static Iridium.Services.ServerConnectionManager connection_manager;
    public static NetworkMonitor network_monitor;

    private GLib.List <Iridium.MainWindow> windows;
    private bool is_network_available;

    public Application () {
        Object (
            application_id: Constants.APP_ID,
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    static construct {
        Granite.Services.Logger.initialize (Constants.APP_ID);
        if (Constants.APP_ID.has_suffix ("-dev")) {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
        } else {
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.WARN;
        }
        info ("%s version: %s", Constants.APP_ID, Constants.VERSION);
        info ("Kernel version: %s", Posix.utsname ().release);
    }

    construct {
        settings = new GLib.Settings (Constants.APP_ID);
        network_monitor = NetworkMonitor.get_default ();
        connection_repository = Iridium.Services.ServerConnectionRepository.instance;
        secret_manager = Iridium.Services.SecretManager.instance;
        certificate_manager = Iridium.Services.CertificateManager.instance;
        connection_manager = Iridium.Services.ServerConnectionManager.instance;

        windows = new GLib.List<Iridium.MainWindow> ();

        network_monitor.network_changed.connect ((available) => {
            warning ("Network availability changed: %s", available.to_string ());
        });
    }

    public void new_window () {
        var main_window = new Iridium.MainWindow (this);
        main_window.present ();
        //  restore_state (main_window);
    }

    public override void window_added (Gtk.Window window) {
        windows.append (window as Iridium.MainWindow);
        base.window_added (window);
    }

    public override void window_removed (Gtk.Window window) {
        windows.remove (window as Iridium.MainWindow);
        base.window_removed (window);
    }

    private Iridium.MainWindow add_new_window () {
        var window = new Iridium.MainWindow (this);
        this.add_window (window);
        return window;
    }

    protected override void activate () {
        //  var main_window = new Iridium.MainWindow (this);
        //  main_window.show_all ();

        // This must happen here because the main event loops will have started
        connection_repository.sql_client = Iridium.Services.SQLClient.instance;
        certificate_manager.sql_client = Iridium.Services.SQLClient.instance;

        // TODO: Connect to signals to save window size and position in settings
        
        // Note: These signals may be fired many times in a row, so be careful
        //       about what sorts of actions are triggered as a result.
        network_monitor.network_changed.connect ((available) => {
            // TODO: Might be able to get better behavior by checking connectivity as well?
            if (is_network_available != available) {
                is_network_available = available;
                if (!is_network_available) {
                    foreach (var window in windows) {
                        window.network_connection_lost ();
                    }
                } else {
                    foreach (var window in windows) {
                        window.network_connection_gained ();
                        //  restore_state (window);
                    }
                }
            }
        });

        var window = this.add_new_window ();

        // Check the initial state of the network connection
        is_network_available = network_monitor.get_network_available ();
        if (!is_network_available) {
            foreach (var _window in windows) {
                _window.network_connection_lost ();
            }
        }

        restore_state (window);
    }

    private void restore_state (Iridium.MainWindow main_window) {
        var servers = connection_repository.get_servers ();
        var channels = connection_repository.get_channels ();
        main_window.initialize (servers, channels);
    }

    public static int main (string[] args) {
        var app = new Iridium.Application ();
        return app.run (args);
    }

}
