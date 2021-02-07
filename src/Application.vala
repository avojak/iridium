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

    private GLib.List<Iridium.MainWindow> windows;
    private bool is_network_available;

    private Gee.List<Iridium.Services.Server> restore_state_servers;
    private Gee.List<Iridium.Services.Channel> restore_state_channels;

    public Application () {
        Object (
            application_id: Constants.APP_ID,
            flags: ApplicationFlags.HANDLES_COMMAND_LINE
        );
    }

    static construct {
        Granite.Services.Logger.initialize (Constants.APP_ID);
        if (is_dev_mode ()) {
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

        network_monitor.network_changed.connect (() => {
            warning ("Network availability changed: %s", network_monitor.get_network_available ().to_string ());
        });
    }

    public static bool is_dev_mode () {
        return Constants.APP_ID.has_suffix ("-dev");
    }

    //  public void new_window () {
    //      var main_window = new Iridium.MainWindow (this);
    //      main_window.present ();
    //      //  restore_state (main_window);
    //  }

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
        window.initialized.connect ((servers, channels, is_reconnecting) => {
            window.open_connections (servers, channels, is_reconnecting);
        });
        this.add_window (window);
        return window;
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        // If the application wasn't already open, activate it now
        if (windows.length () == 0) {
            activate ();
        }

        string[] argv = command_line.get_arguments ();
        GLib.List<Iridium.Models.IRCURI> uris = new GLib.List<Iridium.Models.IRCURI> ();
        foreach (var uri_string in argv[1:argv.length]) {
            try {
                Soup.URI uri = new Soup.URI (uri_string);
                if (uri == null) {
                    throw new OptionError.BAD_VALUE ("Argument is not a URL.");
                }
                if (uri.scheme != "irc") {
                    throw new OptionError.BAD_VALUE ("Cannot open non-irc: URL");
                }
                debug ("Received command line URI: %s", uri.to_string (false));
                //  debug ("host: %s", uri.get_host ());
                //  debug ("port: %s", uri.get_port ().to_string ());
                uris.append (new Iridium.Models.IRCURI (uri));
            } catch (OptionError e) {
                warning ("Argument parsing error: %s", e.message);
            }
        }

        var window = get_active_window ();
        // Ensure that the window is presented to the user when handling the URL.
        // This can happen when the application is already open but in the background.
        window.present ();
        ((Iridium.MainWindow) window).handle_uris (uris);

        return 0;
    }

    protected override void activate () {
        // This must happen here because the main event loops will have started
        connection_repository.sql_client = Iridium.Services.SQLClient.instance;
        certificate_manager.sql_client = Iridium.Services.SQLClient.instance;

        // TODO: Connect to signals to save window size and position in settings

        // Handle changes to network connectivity (eg. losing internet connection)
        network_monitor.network_changed.connect (() => {
            // Don't react to duplicate signals
            bool updated_availability = network_monitor.get_network_available ();
            if (is_network_available == updated_availability) {
                debug ("Ignoring duplicate network availability change signal");
                return;
            }
            is_network_available = updated_availability;
            if (is_network_available) {
                foreach (var window in windows) {
                    window.network_connection_gained ();
                    restore_state (window, true);
                }
            } else {
                foreach (var window in windows) {
                    restore_state_servers = connection_repository.get_servers ();
                    restore_state_channels = connection_repository.get_channels ();
                    window.network_connection_lost ();
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

        restore_state (window, false);
    }

    private void restore_state (Iridium.MainWindow main_window, bool is_reconnecting) {
        var servers = is_reconnecting ? restore_state_servers : connection_repository.get_servers ();
        var channels = is_reconnecting ? restore_state_channels : connection_repository.get_channels ();
        main_window.initialize (servers, channels, is_reconnecting);
    }

    public static int main (string[] args) {
        var app = new Iridium.Application ();
        return app.run (args);
    }

}
