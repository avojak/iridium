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

public class Iridium.Services.ServerConnectionDAO : GLib.Object {
    
    public Iridium.Services.SQLClient sql_client { get; set; }

    public void on_server_connection_successful (Iridium.Services.ServerConnectionDetails connection_details) {
        lock (sql_client) {
            // Remove the existing server and associated channels now so that if the app is closed
            // during initialization, it will still be in the database to attempt connection again
            //  var existing_server = sql_client.get_server (connection_details.server);
            //  if (existing_server == null) {
            //      print ("\tServer is null: " + connection_details.server + "\n");
            //  }
            //  if (existing_server != null) {
            //      sql_client.remove_server (existing_server.connection_details.server);
            //      sql_client.remove_channels (existing_server.id);
            //  }

            // Don't add a duplicate server
            if (sql_client.get_server (connection_details.server) != null) {
                return;
            }
            
            // Add the new entry
            var server = new Iridium.Services.Server ();
            server.connection_details = connection_details;
            sql_client.insert_server (server);

            //  print ("\ton_server_connection_successful\n");
            //  if (sql_client.get_server (connection_details.server) == null) {
            //      print ("\tsql_client doesn't have server, inserting...\n");
            //      var server = new Iridium.Services.Server ();
            //      server.connection_details = connection_details;
            //      sql_client.insert_server (server);
            //  }
        }
    }

    public void on_server_row_added (string server_name) {
        // TODO: Implement - maybe do nothing...?
    }

    public void on_server_row_removed (string server_name) {
        lock (sql_client) {
            sql_client.remove_server (server_name);
        }
    }

    public void on_server_row_enabled (string server_name) {
        lock (sql_client) {
            sql_client.set_server_enabled (server_name, true);
        }
    }

    public void on_server_row_disabled (string server_name) {
        lock (sql_client) {
            sql_client.set_server_enabled (server_name, false);
        }
    }

    public void on_channel_row_added (string server_name, string channel_name) {
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

            sql_client.insert_channel (server.id, channel);
        }
    }

    public void on_channel_row_removed (string server_name, string channel_name) {
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
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            var channel = sql_client.get_channel (server.id, channel_name);
            if (channel == null) {
                return;
            }
            sql_client.set_channel_enabled (channel.id, true);
        }
    }

    public void on_channel_row_disabled (string server_name, string channel_name) {
        lock (sql_client) {
            var server = sql_client.get_server (server_name);
            if (server == null) {
                return;
            }
            var channel = sql_client.get_channel (server.id, channel_name);
            if (channel == null) {
                return;
            }
            sql_client.set_channel_enabled (channel.id, false);
        }
    }

    public void on_private_message_row_added (string server_name, string username) {
        // TODO: Implement
    }

    public void on_private_message_row_removed (string server_name, string username) {
        // TODO: Implement
    }

    public void on_private_message_row_enabled (string server_name, string username) {
        // TODO: Implement
    }

    public void on_private_message_row_disabled (string server_name, string username) {
        // TODO: Implement
    }

    public Gee.List<Iridium.Services.Server> get_servers () {
        lock (sql_client) {
            return sql_client.get_servers ();
        }
    }

    public Gee.List<Iridium.Services.Channel> get_channels () {
        lock (sql_client) {
            return sql_client.get_channels ();
        }
    }

    //  public void clear () {
    //      lock (sql_client) {
    //          sql_client.remove_servers ();
    //          sql_client.remove_channels ();
    //      }
    //  }

}