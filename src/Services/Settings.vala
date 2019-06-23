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

public class Iridium.Services.Settings : Granite.Services.Settings {

    public bool prefer_dark_style { get; set; }
    public string[] connection_details { get; set; }
    public string[] servers { get; set; }
    public string[] channels { get; set; }
    /* public string[] direct_messages { get; set; } */

    public Settings () {
        base ("com.github.avojak.iridium");
    }

    // connection_details:
    //   ["blah=blah\nfoo=bar", ""]
    //   server=irc.freenode.net
    //   port=6667
    //   username=iridium
    //   nickname=iridium
    //   realname=Iridium

    // servers:
    //   ["name=irc.freenode.net\nenabled=true"]

    // channels:
    //   ["server=irc.freenode.net\nname=#irchacks\nenabled=true"]

    // direct_messages:
    //   ["server=irc.freenode.net\nname=avojak\nenabled=true"]

    public void on_server_connection_successful (Iridium.Services.ServerConnectionDetails new_connection_details) {
        var current_connection_details = connection_details;

        Gee.List<string> existing_connection_details = new Gee.ArrayList<string> ();
        existing_connection_details.add_all_array (current_connection_details);
        foreach (string entry in existing_connection_details) {
            if (entry.contains ("server=%s".printf (new_connection_details.server))) {
                return;
            }
        }
        existing_connection_details.add ("server=%s\nport=%s\nusername=%s\nnickname=%s\nrealname=%s".printf (
            new_connection_details.server,
            Iridium.Services.ServerConnectionDetails.DEFAULT_PORT.to_string (),
            new_connection_details.username,
            new_connection_details.nickname,
            new_connection_details.realname
        ));

        connection_details = existing_connection_details.to_array ();
    }

    public void on_server_row_added (string server_name) {
        var current_servers = servers;

        Gee.List<string> existing_servers = new Gee.ArrayList<string> ();
        existing_servers.add_all_array (current_servers);
        foreach (string entry in existing_servers) {
            if (entry.contains ("name=%s".printf (server_name))) {
                return;
            }
        }
        existing_servers.add ("name=%s\nenabled=%s".printf (server_name, true.to_string ()));

        servers = existing_servers.to_array ();
    }

    public void on_server_row_removed (string server_name) {
        // First remove the server entry
        var current_servers = servers;

        Gee.List<string> existing_servers = new Gee.ArrayList<string> ();
        existing_servers.add_all_array (current_servers);

        Gee.List<string> updated_servers = new Gee.ArrayList<string> ();
        foreach (string entry in existing_servers) {
            if (!entry.contains ("name=%s".printf (server_name))) {
                updated_servers.add (entry);
            }
        }

        servers = updated_servers.to_array ();

        // Now remove the associated channel entries
        var current_channels = channels;

        Gee.List<string> existing_channels = new Gee.ArrayList<string> ();
        existing_channels.add_all_array (current_channels);

        Gee.List<string> updated_channels = new Gee.ArrayList<string> ();
        foreach (string entry in existing_channels) {
            if (!entry.contains ("server=%s".printf (server_name))) {
                updated_channels.add (entry);
            }
        }

        channels = updated_channels.to_array ();

        // Now remove the connection details
        var current_connection_details = connection_details;

        Gee.List<string> existing_connection_details = new Gee.ArrayList<string> ();
        existing_connection_details.add_all_array (current_connection_details);

        Gee.List<string> updated_connection_details = new Gee.ArrayList<string> ();
        foreach (string entry in existing_connection_details) {
            if (!entry.contains ("server=%s".printf (server_name))) {
                updated_connection_details.add (entry);
            }
        }

        connection_details = updated_connection_details.to_array ();
    }

    public void on_server_row_enabled (string server_name) {
        var current_servers = servers;

        Gee.List<string> existing_servers = new Gee.ArrayList<string> ();
        existing_servers.add_all_array (current_servers);

        Gee.List<string> updated_servers = new Gee.ArrayList<string> ();
        foreach (string entry in existing_servers) {
            if (entry.contains ("name=%s".printf (server_name))) {
                updated_servers.add ("name=%s\nenabled=%s".printf (server_name, true.to_string ()));
            } else {
                updated_servers.add (entry);
            }
        }

        servers = updated_servers.to_array ();
    }

    public void on_server_row_disabled (string server_name) {
        var current_servers = servers;

        Gee.List<string> existing_servers = new Gee.ArrayList<string> ();
        existing_servers.add_all_array (current_servers);

        Gee.List<string> updated_servers = new Gee.ArrayList<string> ();
        foreach (string entry in existing_servers) {
            if (entry.contains ("name=%s".printf (server_name))) {
                updated_servers.add ("name=%s\nenabled=%s".printf (server_name, false.to_string ()));
            } else {
                updated_servers.add (entry);
            }
        }

        servers = updated_servers.to_array ();
    }

    public void on_channel_row_added (string server_name, string channel_name) {
        var current_channels = channels;

        Gee.List<string> existing_channels = new Gee.ArrayList<string> ();
        existing_channels.add_all_array (current_channels);
        foreach (string entry in existing_channels) {
            if (entry.contains ("server=%s\nname=%s".printf (server_name, channel_name))) {
                return;
            }
        }
        existing_channels.add ("server=%s\nname=%s\nenabled=%s".printf (server_name, channel_name, true.to_string ()));

        channels = existing_channels.to_array ();
    }

    public void on_channel_row_removed (string server_name, string channel_name) {
        var current_channels = channels;

        Gee.List<string> existing_channels = new Gee.ArrayList<string> ();
        existing_channels.add_all_array (current_channels);

        Gee.List<string> updated_channels = new Gee.ArrayList<string> ();
        foreach (string entry in existing_channels) {
            if (!entry.contains ("server=%s\nname=%s".printf (server_name, channel_name))) {
                updated_channels.add (entry);
            }
        }

        channels = updated_channels.to_array ();
    }

    public void on_channel_row_enabled (string server_name, string channel_name) {
        var current_channels = channels;

        Gee.List<string> existing_channels = new Gee.ArrayList<string> ();
        existing_channels.add_all_array (current_channels);

        Gee.List<string> updated_channels = new Gee.ArrayList<string> ();
        foreach (string entry in existing_channels) {
            if (entry.contains ("server=%s\nname=%s".printf (server_name, channel_name))) {
                updated_channels.add ("server=%s\nname=%s\nenabled=%s".printf (server_name, channel_name, true.to_string ()));
            } else {
                updated_channels.add (entry);
            }
        }

        channels = updated_channels.to_array ();
    }

    public void on_channel_row_disabled (string server_name, string channel_name) {
        var current_channels = channels;

        Gee.List<string> existing_channels = new Gee.ArrayList<string> ();
        existing_channels.add_all_array (current_channels);

        Gee.List<string> updated_channels = new Gee.ArrayList<string> ();
        foreach (string entry in existing_channels) {
            if (entry.contains ("server=%s\nname=%s".printf (server_name, channel_name))) {
                updated_channels.add ("server=%s\nname=%s\nenabled=%s".printf (server_name, channel_name, false.to_string ()));
            } else {
                updated_channels.add (entry);
            }
        }

        channels = updated_channels.to_array ();
    }

    public void on_dm_row_added (string server_name, string username) {

    }

    public void on_dm_row_removed (string server_name, string username) {

    }

    public void on_dm_row_enabled (string server_name, string username) {

    }

    public void on_dm_row_disabled (string server_name, string username) {

    }

    public Gee.List<string> get_servers_list () {
        var current_servers = servers;
        Gee.List<string> existing_servers = new Gee.ArrayList<string> ();
        existing_servers.add_all_array (current_servers);
        return existing_servers;
    }

    public Gee.List<string> get_channels_list () {
        var current_channels = channels;
        Gee.List<string> existing_channels = new Gee.ArrayList<string> ();
        existing_channels.add_all_array (current_channels);
        return existing_channels;
    }

    public Gee.List<string> get_connection_details_list () {
        var current_connection_details = connection_details;
        Gee.List<string> existing_connection_details = new Gee.ArrayList<string> ();
        existing_connection_details.add_all_array (current_connection_details);
        return existing_connection_details;
    }

    public Gee.Map<string, Iridium.Services.ServerConnectionDetails> get_connection_details_map () {
        Gee.Map<string, Iridium.Services.ServerConnectionDetails> connection_details_map = new Gee.HashMap<string, Iridium.Services.ServerConnectionDetails> ();
        var connection_details_list = get_connection_details_list ();
        foreach (string entry in connection_details_list) {
            string[] tokens = entry.split ("\n");
            var connection_details = new Iridium.Services.ServerConnectionDetails ();
            connection_details.server = tokens[0].split ("=")[1];
            connection_details.username = tokens[2].split ("=")[1];
            connection_details.nickname = tokens[3].split ("=")[1];
            connection_details.realname = tokens[4].split ("=")[1];
            connection_details_map.set (connection_details.server, connection_details);
        }
        return connection_details_map;
    }

}
