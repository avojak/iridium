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

public class Iridium.Widgets.SidePanel.ChannelRow : Granite.Widgets.SourceList.Item, Iridium.Widgets.SidePanel.Row {

    public string channel_name { get; construct; }
    public string server_name { get; construct; }

    private bool is_enabled = true;
    private bool is_favorite = false;

    public ChannelRow (string channel_name, string server_name) {
        Object (
            name: channel_name,
            channel_name: channel_name,
            server_name: server_name
        );
    }

    construct {
        //  icon = new GLib.ThemedIcon ("user-available");
        icon = new GLib.ThemedIcon ("internet-chat");
    }

    public new string get_server_name () {
        return server_name;
    }

    public new string? get_channel_name () {
        return channel_name;
    }

    public new void enable () {
        if (is_enabled) {
            return;
        }
        //  icon = new GLib.ThemedIcon ("user-available");
        icon = new GLib.ThemedIcon ("internet-chat");
        //  icon = null;
        if (is_favorite) {
            markup = channel_name + " <small>" + server_name + "</small>";
        } else {
            markup = null;
        }
        is_enabled = true;
    }

    public new void disable () {
        if (!is_enabled) {
            return;
        }
        //  icon = new GLib.ThemedIcon ("user-offline");
        icon = new GLib.ThemedIcon ("internet-chat");
        //  icon = null;
        if (is_favorite) {
            markup = "<i>" + channel_name + " <small>" + server_name + "</small></i>";
        } else {
            markup = "<i>" + channel_name + "</i>";
        }
        is_enabled = false;
    }

    //  public new void error () {
    //  }

    public new void updating () {
        //  icon = new GLib.ThemedIcon ("mail-unread");
        // Maybe add the symbolic chat and user icons so we can specifically use them when not loading?
        // Could also create "disabled" versions of each that are greyed out slightly
        icon = new GLib.ThemedIcon (Constants.APP_ID + ".image-loading-symbolic");
        if (is_favorite) {
            markup = "<i>" + channel_name + " <small>" + server_name + "</small></i>";
        } else {
            markup = "<i>" + channel_name + "</i>";
        }
        is_enabled = false;
    }

    public new bool get_enabled () {
        return is_enabled;
    }

    public void set_favorite (bool favorite) {
        is_favorite = favorite;
        if (favorite) {
            if (is_enabled) {
                markup = channel_name + " <small>" + server_name + "</small>";
            } else {
                markup = "<i>" + channel_name + " <small>" + server_name + "</small></i>";
            }
        } else {
            if (is_enabled) {
                markup = null;
            } else {
                markup = "<i>" + channel_name + "</i>";
            }
        }
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var favorite_item = new Gtk.MenuItem.with_label (_("Add to favorites"));
        favorite_item.activate.connect (() => {
            favorite_channel ();
        });

        var remove_favorite_item = new Gtk.MenuItem.with_label (_("Remove from favorites"));
        remove_favorite_item.activate.connect (() => {
            remove_favorite_channel ();
        });

        var join_item = new Gtk.MenuItem.with_label (_("Join channel"));
        join_item.activate.connect (() => {
            join_channel ();
        });

        var leave_item = new Gtk.MenuItem.with_label (_("Leave channel"));
        leave_item.activate.connect (() => {
            leave_channel ();
        });

        var close_item = new Gtk.MenuItem.with_label (_("Close"));
        close_item.activate.connect (() => {
            if (is_enabled) {
                leave_channel ();
            }
            remove_channel ();
        });

        if (is_favorite) {
            menu.append (remove_favorite_item);
        } else {
            menu.append (favorite_item);
        }
        menu.append (new Gtk.SeparatorMenuItem ());
        if (is_enabled) {
            menu.append (leave_item);
        } else {
            menu.append (join_item);
        }
        menu.append (close_item);

        menu.show_all ();

        return menu;
    }

    public signal void favorite_channel ();
    public signal void remove_favorite_channel ();
    public signal void join_channel ();
    public signal void leave_channel ();
    public signal void remove_channel ();

}
