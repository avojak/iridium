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

    private static Secret.Schema schema = new Secret.Schema (
        Constants.APP_ID,
        Secret.SchemaFlags.NONE,
        "version", Secret.SchemaAttributeType.STRING, // Versioning number for the schema, NOT the application
        "server", Secret.SchemaAttributeType.STRING,
        "port", Secret.SchemaAttributeType.INTEGER,
        "user", Secret.SchemaAttributeType.STRING
    );

    public void store_password (string server, int port, string user, string password) throws GLib.Error {
        var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        attributes.insert ("version", "1");
        attributes.insert ("server", server);
        attributes.insert ("port", port.to_string ());
        attributes.insert ("user", user);
        Secret.password_storev.begin (schema, attributes, Secret.COLLECTION_DEFAULT, "Iridium password", password, null, (obj, async_res) => {
            bool res = Secret.password_store.end (async_res);
            // TODO: Do something now that the password has been stored...
            print ("STORED SECRET " + res.to_string () + " (" + password + ")\n");
        });
    }

    public string? retrieve_password (string server, int port, string user) {
        var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
        attributes.insert ("version", "1");
        attributes.insert ("server", server);
        attributes.insert ("port", port.to_string ());
        attributes.insert ("user", user);
        //  Secret.password_lookupv.begin (schema, attributes, null, (obj, async_res) => {
        //      string password = Secret.password_lookup.end (async_res);
        //      password_retrieved (server, port, user, password);
        //  });

        //  https://mail.gnome.org/archives/vala-list/2016-January/msg00021.html
        string password = null;
        var loop = new MainLoop ();
        Secret.password_lookupv.begin (schema, attributes, null, (obj, async_res) => {
            password = Secret.password_lookup.end (async_res);
            loop.quit ();
        });
        loop.run ();
        return password;
    }

    public signal void password_retrieved (string server, int port, string user, string? password);

}