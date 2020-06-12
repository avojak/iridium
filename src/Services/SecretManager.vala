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

    private static string SCHEMA_VERSION = "1"; // vala-lint=naming-convention

    private static Secret.Schema schema = new Secret.Schema (
        Constants.APP_ID,
        Secret.SchemaFlags.NONE,
        "version", Secret.SchemaAttributeType.STRING, // Versioning number for the schema, NOT the application
        "server", Secret.SchemaAttributeType.STRING,
        "port", Secret.SchemaAttributeType.INTEGER,
        "user", Secret.SchemaAttributeType.STRING
    );

    public void store_secret (string server, int port, string user, string secret) throws GLib.Error {
        print ("Storing secret for server: %s, port: %s, user: %s\n", server, port.to_string (), user);

        var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        attributes.insert ("version", SCHEMA_VERSION);
        attributes.insert ("server", server);
        attributes.insert ("port", port.to_string ());
        attributes.insert ("user", user);
        var label = Constants.APP_ID + ":" + user + "@" + server + ":" + port.to_string ();
        Secret.password_storev.begin (schema, attributes, null, label, secret, null, (obj, async_res) => {
            if (Secret.password_store.end (async_res)) {
                print ("Stored secret \"%s\"\n", label);
            } else {
                // TODO: Handle this better
                print ("Failed to store secret \"%s\"\n", label);
            }
        });
    }

    public string? retrieve_secret (string server, int port, string user) {
        print ("Retrieving password for server: %s, port: %s, user: %s\n", server, port.to_string (), user);

        // This is a dirty, dirty hack. Force authentication check by storing a dummy secret. Otherwise,
        // we get a null secret back and no prompt for authentication if needed.
        var dummy_label = Constants.APP_ID + ":dummy@example.com:6667";
        var dummy_attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        dummy_attributes.insert ("version", SCHEMA_VERSION);
        dummy_attributes.insert ("server", "example.com");
        dummy_attributes.insert ("port", "6667");
        dummy_attributes.insert ("user", "dummy");
        Secret.password_storev_sync (schema, dummy_attributes, null, dummy_label, "fake_not_real", null);

        var label = Constants.APP_ID + ":" + user + "@" + server + ":" + port.to_string ();
        var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        attributes.insert ("version", SCHEMA_VERSION);
        attributes.insert ("server", server);
        attributes.insert ("port", port.to_string ());
        attributes.insert ("user", user);
        // We can do this synchronously because each connection is already handled in its own thread
        string? secret = Secret.password_lookupv_sync (schema, attributes);
        if (secret == null) {
            print ("Failed to load secret: \"%s\"\n", label);
        }
        return secret;
    }

}
