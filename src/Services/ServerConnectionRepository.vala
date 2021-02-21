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

public class Iridium.Services.ServerConnectionRepository : GLib.Object {

    public Iridium.Services.SQLClient sql_client { get; set; }

    private static Iridium.Services.ServerConnectionRepository _instance = null;
    public static Iridium.Services.ServerConnectionRepository instance {
        get {
            if (_instance == null) {
                _instance = new Iridium.Services.ServerConnectionRepository ();
            }
            return _instance;
        }
    }

    private bool should_remember_connections;

    private ServerConnectionRepository () {
        should_remember_connections = Iridium.Application.settings.get_boolean ("remember-connections");
        Iridium.Application.settings.changed["remember-connections"].connect (() => {
            should_remember_connections = Iridium.Application.settings.get_boolean ("remember-connections");
        });
    }

    public void on_server_connection_successful (Iridium.Services.ServerConnectionDetails connection_details) {
        debug ("Server connection successful");
        if (!should_remember_connections) {
            debug ("Not remembering connections");
            return;
        }
        lock (sql_client) {
            // Don't add a duplicate server
            if (sql_client.get_server (connection_details.server) != null) {
                debug ("Skipping duplicate server");
                return;
            }

            // Add the new entry
            debug ("Adding new entry");
            var server = new Iridium.Services.Server ();
            server.connection_details = connection_details;
            sql_client.insert_server (server);
        }
        debug ("Done");
    }

    public void on_server_row_added (string server_name) {
        // TODO: Implement - maybe do nothing…?
    }

    public void on_server_row_removed (string server_name) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            sql_client.remove_server (server_name);

            var channels = sql_client.get_channels ();
            foreach (var channel in channels) {
                if (channel.server_id == server.id) {
                    sql_client.remove_channel (channel.id);
                }
            }
        }
    }

    public void on_server_row_enabled (string server_name) {
        set_server_row_enabled (server_name, true);
    }

    public void on_server_row_disabled (string server_name) {
        set_server_row_enabled (server_name, false);
    }

    private void set_server_row_enabled (string server_name, bool enabled) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            sql_client.set_server_enabled (server_name, enabled);
        }
    }

    public void on_channel_row_added (string server_name, string channel_name) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }

            // Don't add a duplicate channel for the same server
            if (sql_client.get_channel (server.id, channel_name) != null) {
                return;
            }

            var channel = new Iridium.Services.Channel ();
            channel.server_id = server.id;
            channel.name = channel_name;
            channel.enabled = false;
            channel.favorite = false;

            sql_client.insert_channel (server.id, channel);
        }
    }

    public void on_channel_row_removed (string server_name, string channel_name) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            var channel = sql_client.get_channel (server.id, channel_name);
            if (channel == null) {
                return;
            }
            sql_client.remove_channel (channel.id);
        }
    }

    public void on_channel_row_enabled (string server_name, string channel_name) {
        set_channel_row_enabled (server_name, channel_name, true);
    }

    public void on_channel_row_disabled (string server_name, string channel_name) {
        set_channel_row_enabled (server_name, channel_name, false);
    }

    private void set_channel_row_enabled (string server_name, string channel_name, bool enabled) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            var channel = sql_client.get_channel (server.id, channel_name);
            if (channel == null) {
                return;
            }
            sql_client.set_channel_enabled (channel.id, enabled);
        }
    }

    public void on_channel_favorite_added (string server_name, string channel_name) {
        set_channel_favorite (server_name, channel_name, true);
    }

    public void on_channel_favorite_removed (string server_name, string channel_name) {
        set_channel_favorite (server_name, channel_name, false);
    }

    private void set_channel_favorite (string server_name, string channel_name, bool favorite) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            var channel = sql_client.get_channel (server.id, channel_name);
            if (channel == null) {
                return;
            }
            sql_client.set_channel_favorite (channel.id, favorite);
        }
    }

    public void on_private_message_row_added (string server_name, string nickname) {
        // TODO: Implement
    }

    public void on_private_message_row_removed (string server_name, string nickname) {
        // TODO: Implement
    }

    public void on_private_message_row_enabled (string server_name, string nickname) {
        // TODO: Implement
    }

    public void on_private_message_row_disabled (string server_name, string nickname) {
        // TODO: Implement
    }

    public Iridium.Services.Server? get_server (string server_name) {
        if (!should_remember_connections) {
            return null;
        }
        lock (sql_client) {
            return sql_client.get_server (server_name);
        }
    }

    public Gee.List<Iridium.Services.Server> get_servers () {
        if (!should_remember_connections) {
            return new Gee.ArrayList<Iridium.Services.Server> ();
        }
        lock (sql_client) {
            return sql_client.get_servers ();
        }
    }

    public Gee.List<Iridium.Services.Channel> get_channels () {
        if (!should_remember_connections) {
            return new Gee.ArrayList<Iridium.Services.Channel> ();
        }
        lock (sql_client) {
            return sql_client.get_channels ();
        }
    }

    public void on_nickname_changed (string server_name, string old_nickname, string new_nickname) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            Iridium.Services.Server? server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            server.connection_details.nickname = new_nickname;
            sql_client.update_server (server);
        }
    }

    public void on_network_name_received (string server_name, string network_name) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            Iridium.Services.Server? server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            server.network_name = network_name;
            sql_client.update_server (server);
        }
    }

    public void update_server_connection_details (string server_name, Iridium.Services.ServerConnectionDetails new_connection_details) {
        if (!should_remember_connections) {
            return;
        }
        lock (sql_client) {
            var existing_server_entry = sql_client.get_server (server_name);
            if (existing_server_entry == null) {
                var server = new Iridium.Services.Server ();
                server.connection_details = new_connection_details;
                sql_client.insert_server (server);
            } else {
                existing_server_entry.connection_details = new_connection_details;
                sql_client.update_server (existing_server_entry);
            }
        }
    }

    public void clear () {
        debug ("Clearing all database content…");
        lock (sql_client) {
            sql_client.remove_all_servers ();
            sql_client.remove_all_channels ();
            sql_client.remove_all_server_identities ();
        }
    }

}
