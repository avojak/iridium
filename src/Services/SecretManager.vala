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

public class Iridium.Services.SecretManager : GLib.Object {

    private static string SCHEMA_VERSION = "1";

    private static Secret.Schema schema = new Secret.Schema (
        Constants.APP_ID,
        Secret.SchemaFlags.NONE,
        "version", Secret.SchemaAttributeType.STRING, // Versioning number for the schema, NOT the application
        "server", Secret.SchemaAttributeType.STRING,
        "port", Secret.SchemaAttributeType.INTEGER,
        "user", Secret.SchemaAttributeType.STRING
    );

    public void store_password (string server, int port, string user, string password) throws GLib.Error {
        // First attempt to create the collection. If the collection already exists, the existing collection is returned.
        try {
            Secret.Collection.create_sync (null, "Iridium IRC Client Secret Collection", Constants.APP_ID, Secret.CollectionCreateFlags.COLLECTION_CREATE_NONE, null);
        } catch (Error e) {
            print ("Failed to create secret collection: \"%s\"\n", e.message);
        }

        var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        attributes.insert ("version", SCHEMA_VERSION);
        attributes.insert ("server", server);
        attributes.insert ("port", port.to_string ());
        attributes.insert ("user", user);
        Secret.password_storev.begin (schema, attributes, Constants.APP_ID, "Iridium password", password, null, (obj, async_res) => {
            bool res = Secret.password_store.end (async_res);
            // TODO: Do something now that the password has been stored...
            print ("STORED SECRET " + res.to_string () + " (" + password + ")\n");
        });
    }

    public string? retrieve_password (string server, int port, string user) {
        // Passwords are stored under the collection, so retrieve that first
        Secret.Collection secret_collection = null;
        try {
            secret_collection = Secret.Collection.for_alias_sync (null, Constants.APP_ID, Secret.CollectionFlags.LOAD_ITEMS);
        } catch (Error e) {
            print ("Failed to retrieve secret collection: \"%s\"\n", e.message);
            return null;
        }
        if (secret_collection == null) {
            print ("No secret collection for alias\n");
            return null;
        }
        if (!secret_collection.load_items_sync ()) {
            // TODO: Handle this!
            print ("Failed to load items from secret collection\n");
            return null;
        }

        // Search the collection using the attributes
        var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        attributes.insert ("version", SCHEMA_VERSION);
        attributes.insert ("server", server);
        attributes.insert ("port", port.to_string ());
        attributes.insert ("user", user);

        var items = secret_collection.search_sync (schema, attributes, Secret.SearchFlags.UNLOCK);
        if (items.length () == 0) {
            // TODO: Handle this!
            print ("No secret found matching attributes\n");
            return null;
        }
        if (items.length () > 1) {
            // TODO: Handle this!
            print ("Multiple secrets found matching attributes - using the first one\n");
        }
        var item = items.nth_data (0);
        var val = item.get_secret ();
        if (val == null) {
            // TODO: Handle this!
            print ("Secret item is either locked or has not yet been loaded\n");
            return null;
        }
        return val.get_text ();

        //  Secret.password_lookupv.begin (schema, attributes, null, (obj, async_res) => {
        //      string password = Secret.password_lookup.end (async_res);
        //      password_retrieved (server, port, user, password);
        //  });

        // https://mail.gnome.org/archives/vala-list/2016-January/msg00021.html
        // This should be safe to block because each connection will be calling this function
        // directly, and each connection is already its own thread.
        //  string password = null;
        //  var loop = new MainLoop ();
        //  Secret.password_lookupv.begin (schema, attributes, null, (obj, async_res) => {
        //      password = Secret.password_lookup.end (async_res);
        //      loop.quit ();
        //  });
        //  loop.run ();
        //  return password;
        //  return Secret.password_lookupv_sync (schema, attributes, null);
    }

    //  public signal void password_retrieved (string server, int port, string user, string? password);

}