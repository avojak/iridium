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

public class Iridium.Services.SQLClient : GLib.Object {

    private static string DATABASE_FILE = "iridium01.db";
    private static Iridium.Services.SQLClient INSTANCE;

    private Sqlite.Database database;

    public static Iridium.Services.SQLClient get_instance () {
        if (INSTANCE == null) {
            INSTANCE = new Iridium.Services.SQLClient ();
        }
        return INSTANCE;
    }

    private SQLClient () {
        initialize_database ();
    }

    private void initialize_database () {
        var config_dir_path = GLib.Environment.get_user_config_dir () + "/" + Constants.APP_ID;
        var config_dir_file = GLib.File.new_for_path (config_dir_path);
        try {
            if (!config_dir_file.query_exists ()) {
                config_dir_file.make_directory ();
            }
        } catch (GLib.Error e) {
            // TODO: Log this, probably show an error message that we cannot proceed
            print ("error creating config directory\n");
            return;
        }
        var db_file = config_dir_path + "/" + DATABASE_FILE;
        if (Sqlite.Database.open_v2 (db_file, out database) != Sqlite.OK) {
            // TODO: Log this and be consistent with other logging, also probably show error message
            //       that we cannot proceed
            stderr.printf ("Can't open database: %d: %s\n", database.errcode (), database.errmsg ());
            return;
        }

        initialize_tables ();
    }

    private void initialize_tables () {
        string sql = """
            CREATE TABLE IF NOT EXISTS "servers" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "hostname" TEXT NOT NULL,
                "port" INTEGER NOT NULL,
                "nickname" TEXT,
                "username" TEXT,
                "realname" TEXT,
                "password" TEXT,
                "enabled" BOOL
            );
            CREATE TABLE IF NOT EXISTS "channels" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "server_id" INTEGER,
                "channel" TEXT,
                "enabled" BOOL,
                "favorite" BOOL
            );
            """;
		database.exec(sql);
    }

    public void insert_server (Iridium.Services.Server server) {
        print ("\tinsert_server\n");
        var sql = """
            INSERT INTO servers (hostname, port, nickname, username, realname, password, enabled) 
            VALUES ($HOSTNAME, $PORT, $NICKNAME, $USERNAME, $REALNAME, $PASSWORD, $ENABLED);
            """;

        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }

        statement.bind_text (1, server.connection_details.server);
        statement.bind_int (2, Iridium.Services.ServerConnectionDetails.DEFAULT_PORT);
        statement.bind_text (3, server.connection_details.nickname);
        statement.bind_text (4, server.connection_details.username);
        statement.bind_text (5, server.connection_details.realname);
        statement.bind_text (6, server.connection_details.password);
        statement.bind_int (7, bool_to_int (server.enabled));

        statement.step ();
        statement.reset ();
    }

    public Iridium.Services.Server? get_server (string server_name) {
        var sql = "SELECT * FROM servers WHERE hostname = $HOSTNAME;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return null;
        }
        statement.bind_text (1, server_name);

        if (statement.step () != Sqlite.ROW) {
            return null;
        }
        var server = parse_server_row (statement);
        statement.reset ();
        return server;
    }

    public void update_server (Iridium.Services.Server server) {
        // TODO: Implement
    }

    public void set_server_enabled (string hostname, bool enabled) {
        var sql = "UPDATE servers SET enabled = $ENABLED WHERE hostname = $HOSTNAME;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }
        statement.bind_int (1, bool_to_int (enabled));
        statement.bind_text (2, hostname);
        
        statement.step ();
        statement.reset ();
    }

    public void remove_server (string hostname) {
        var sql = "DELETE FROM servers WHERE hostname = $HOSTNAME;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }
        statement.bind_text (1, hostname);
        
        statement.step ();
        statement.reset ();
    }

    //  public void remove_servers () {
    //      var sql = "DELETE * FROM servers;";
    //      Sqlite.Statement statement;
    //      if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
    //          // TODO: Log this
    //          stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
	//  	    return;
    //      }
    //      statement.step ();
    //      statement.reset ();
    //  }

    public void insert_channel (int server_id, Iridium.Services.Channel channel) {
        var sql = """
            INSERT INTO channels (server_id, channel, enabled, favorite) 
            VALUES ($SERVER_ID, $CHANNEL, $ENABLED, $FAVORITE);
            """;

        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
            return;
        }

        statement.bind_int (1, server_id);
        statement.bind_text (2, channel.name);
        statement.bind_int (3, bool_to_int(channel.enabled));
        statement.bind_int (4, bool_to_int(channel.favorite));

        statement.step ();
        statement.reset ();
    }

    public Iridium.Services.Channel? get_channel (int server_id, string channel_name) {
        var sql = "SELECT * FROM channels WHERE server_id = $SERVER_ID AND channel = $CHANNEL;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
            return null;
        }
        statement.bind_int (1, server_id);
        statement.bind_text (2, channel_name);

        if (statement.step () != Sqlite.ROW) {
            return null;
        }
        var channel = parse_channel_row (statement);
        statement.reset ();
        return channel;
    }

    public void update_channel (Iridium.Services.Channel channel) {
        // TODO: Implement
    }

    public void set_channel_enabled (int channel_id, bool enabled) {
        var sql = "UPDATE channels SET enabled = $ENABLED WHERE id = $ID;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }
        statement.bind_int (1, bool_to_int (enabled));
        statement.bind_int (2, channel_id);
        
        statement.step ();
        statement.reset ();
    }

    public void remove_channel (int channel_id) {
        var sql = "DELETE FROM channels WHERE id = $ID;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }
        statement.bind_int (1, channel_id);
        
        statement.step ();
        statement.reset ();
    }

    public void remove_channels (int server_id) {
        var sql = "DELETE FROM channels WHERE server_id = $SERVER_ID;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }
        statement.bind_int (1, server_id);
        
        statement.step ();
        statement.reset ();
    }

    public Gee.List<Iridium.Services.Server> get_servers () {
        var servers = new Gee.ArrayList<Iridium.Services.Server> ();

        var sql = "SELECT * FROM servers;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return servers;
        }

        while (statement.step () == Sqlite.ROW) {
            var server = parse_server_row (statement);
            servers.add (server);
        }
        statement.reset ();

        return servers;
    }

    public Gee.List<Iridium.Services.Channel> get_channels () {
        var channels = new Gee.ArrayList<Iridium.Services.Channel> ();

        var sql = "SELECT * FROM channels;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return channels;
        }

        while (statement.step () == Sqlite.ROW) {
            var channel = parse_channel_row (statement);
            channels.add (channel);
        }
        statement.reset ();

        return channels;
    }

    public void set_channel_favorite (int channel_id, bool favorite) {
        var sql = "UPDATE channels SET favorite = $FAVORITE WHERE id = $ID;";
        Sqlite.Statement statement;
        if (database.prepare_v2 (sql, sql.length, out statement) != Sqlite.OK) {
            // TODO: Log this
            stderr.printf ("Error: %d: %s\n", database.errcode (), database.errmsg ());
		    return;
        }
        statement.bind_int (1, bool_to_int (favorite));
        statement.bind_int (2, channel_id);
        
        statement.step ();
        statement.reset ();
    }

    private Iridium.Services.Server parse_server_row (Sqlite.Statement statement) {
        var num_columns = statement.column_count ();
        var server = new Iridium.Services.Server ();
        var connection_details = new Iridium.Services.ServerConnectionDetails ();
        for (int i = 0; i < num_columns; i++) {
            switch (statement.column_name (i)) {
                case "id":
                    server.id = statement.column_int (i);
                    break;
                case "hostname":
                    connection_details.server = statement.column_text (i);
                    break;
                case "port":
                    break;
                case "nickname":
                    connection_details.nickname = statement.column_text (i);
                    break;
                case "username":
                    connection_details.username = statement.column_text (i);
                    break;
                case "realname":
                    connection_details.realname = statement.column_text (i);
                    break;
                case "password":
                    connection_details.password = statement.column_text (i);
                    break;
                case "enabled":
                    server.enabled = int_to_bool (statement.column_int (i));
                    break;
                default:
                    break;
            }
        }
        server.connection_details = connection_details;
        return server;
    }

    private Iridium.Services.Channel parse_channel_row (Sqlite.Statement statement) {
        var num_columns = statement.column_count ();
        var channel = new Iridium.Services.Channel ();
        for (int i = 0; i < num_columns; i++) {
            switch (statement.column_name (i)) {
                case "id":
                    channel.id = statement.column_int (i);
                    break;
                case "server_id":
                    channel.server_id = statement.column_int (i);
                    break;
                case "channel":
                    channel.name = statement.column_text (i);
                    break;
                case "enabled":
                    channel.enabled = int_to_bool (statement.column_int (i));
                    break;
                case "favorite":
                    channel.favorite = int_to_bool (statement.column_int (i));
                    break;
                default:
                    break;
            }
        }
        return channel;
    }

    private static int bool_to_int (bool val) {
        return val ? 1 : 0;
    }

    private static bool int_to_bool (int val) {
        return val == 1;
    }

}