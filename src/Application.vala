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
    private bool is_first_network_availability = true;

    private Gee.List<Iridium.Services.Server> restore_state_servers = new Gee.ArrayList<Iridium.Services.Server> ();
    private Gee.List<Iridium.Services.Channel> restore_state_channels = new Gee.ArrayList<Iridium.Services.Channel> ();

    private string[]? queued_command_line_arguments;

    public Application () {
        Object (
            application_id: Constants.APP_ID,
            flags: ApplicationFlags.HANDLES_COMMAND_LINE
        );
    }

    static construct {
        //  Granite.Services.Logger.initialize (Constants.APP_ID);
        //  if (is_dev_mode ()) {
        //      Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
        //  } else {
        //      Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.WARN;
        //  }
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

        startup.connect ((handler) => {
            Hdy.init ();
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
        window.ui_initialized.connect (() => {
            // If we run into the GLib NetworkMonitor bug, or there really isn't network availability, don't connect yet
            if (is_network_available) {
                window.open_connections (connection_repository.get_servers (), connection_repository.get_channels (), false);
            }
        });
        window.connections_opened.connect ((is_reconnecting) => {
            // Don't handle command line arguments if we're just reconnecting
            if (!is_reconnecting && (queued_command_line_arguments != null)) {
                debug ("Sending queued command line arguments to window");
                handle_command_line_arguments (queued_command_line_arguments);
            }
        });
        window.initialize_ui (connection_repository.get_servers (), connection_repository.get_channels ());
        this.add_window (window);
        return window;
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        string[] command_line_arguments = parse_command_line_arguments (command_line.get_arguments ());
        // If the application wasn't already open, activate it now
        if (windows.length () == 0) {
            queued_command_line_arguments = command_line_arguments;
            activate ();
        } else {
            handle_command_line_arguments (command_line_arguments);
        }
        return 0;
    }

    private string[] parse_command_line_arguments (string[] command_line_arguments) {
        if (command_line_arguments.length == 0) {
            return command_line_arguments;
        } else {
            // For Flatpak, the first commandline argument is the app ID, so we need to filter it out
            if (command_line_arguments[0] == Constants.APP_ID) {
                return command_line_arguments[1:command_line_arguments.length - 1];
            } {
                return command_line_arguments;
            }
        }
    }

    private void handle_command_line_arguments (string[] argv) {
        GLib.List<Iridium.Models.IRCURI> uris = new GLib.List<Iridium.Models.IRCURI> ();
        foreach (var uri_string in argv) {
            try {
                Soup.URI uri = new Soup.URI (uri_string);
                if (uri == null) {
                    throw new OptionError.BAD_VALUE ("Argument is not a URL.");
                }
                if (uri.scheme != "irc") {
                    throw new OptionError.BAD_VALUE ("Cannot open non-irc: URL");
                }
                debug ("Received command line URI: %s", uri.to_string (false));
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
    }

    protected override void activate () {
        // This must happen here because the main event loops will have started
        connection_repository.sql_client = Iridium.Services.SQLClient.instance;
        certificate_manager.sql_client = Iridium.Services.SQLClient.instance;

        // Handle changes to network connectivity (eg. losing internet connection)
        network_monitor.network_changed.connect (() => {
            debug ("Network availability changed: %s", network_monitor.get_network_available ().to_string ());
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
                    // If this is the first time that the network has become available, it's not a reconnection,
                    // it's the first connection. The servers and channels have been stored away in the
                    // restore_state_* lists.
                    window.open_connections (restore_state_servers, restore_state_channels, !is_first_network_availability);
                }
                is_first_network_availability = false;
            } else {
                foreach (var window in windows) {
                    restore_state_servers = connection_repository.get_servers ();
                    restore_state_channels = connection_repository.get_channels ();
                    Iridium.Application.connection_manager.close_all_connections ();
                    window.network_connection_lost ();
                }
            }
        });

        // Respect the system style preference
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var window = this.add_new_window ();

        // Check the initial state of the network connection
        // Note: There is a bug in GLib where the initial network availability property may report `false`
        //       incorrectly due to an asynchronous D-Bus call.
        //       See: https://gitlab.gnome.org/GNOME/glib/-/issues/1718
        is_network_available = network_monitor.get_network_available ();
        debug ("Initial network availability: %s", is_network_available.to_string ());

        // If the network isn't initially available, grab the servers and channels for later
        if (!is_network_available) {
            restore_state_servers = connection_repository.get_servers ();
            restore_state_channels = connection_repository.get_channels ();
            window.network_connection_lost ();
        } else {
            // If network is available, next `true` value for network availability will be a reconnection
            is_first_network_availability = false;
        }
    }

    public static int main (string[] args) {
        var app = new Iridium.Application ();
        return app.run (args);
    }

}
