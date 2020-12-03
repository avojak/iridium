/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
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

public class Iridium.Services.NetworkStabilizationMonitor : GLib.Object {

    private const long STABLE_DURATION = 3 * 1000 * 1000; // 3 seconds in microseconds

    private bool is_network_available;
    private bool is_network_stable;
    private GLib.DateTime down_time;
    private GLib.DateTime up_time;

    construct {
        var network_monitor = GLib.NetworkMonitor.get_default ();
        is_network_stable = network_monitor.get_network_available ();
        is_network_available = is_network_stable;

        down_time = new GLib.DateTime.now_local();
        up_time = new GLib.DateTime.now_local();
        
        network_monitor.network_changed.connect ((available) => {
            is_network_available = available;
            if (!available) {
                is_network_stable = false;
                down_time = new GLib.DateTime.now_local();
            } else {
                up_time = new GLib.DateTime.now_local();
            }
        });
    }

    public void start () {
        Timeout.add_seconds_full (GLib.Priority.DEFAULT_IDLE, 1, () => {
            if (!is_network_stable && is_network_available) {
                var now = new GLib.DateTime.now_local();
                if (now.difference (up_time) >= STABLE_DURATION) {
                    debug ("Detected network connection stablized after %s seconds", (now.difference (up_time) / 1000000).to_string ());
                    is_network_stable = true;
                    connection_stablized ();
                }
            }
            return true;
        });
    }

    public signal void connection_stablized ();

}
