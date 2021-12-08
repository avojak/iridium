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
    public string? network_name { get; set; }
    public Iridium.Widgets.SidePanel.Row.State state { get; set; }

    //  private bool is_enabled = true;
    private bool is_favorite = false;

    public ChannelRow (string channel_name, string server_name) {
        Object (
            name: channel_name,
            channel_name: channel_name,
            server_name: server_name,
            icon: new GLib.ThemedIcon ("emblem-disabled"),
            state: Iridium.Widgets.SidePanel.Row.State.DISABLED
        );
    }

    public new string get_server_name () {
        return server_name;
    }

    public new string? get_channel_name () {
        return channel_name;
    }

    public new void enable () {
        if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
            return;
        }
        state = Iridium.Widgets.SidePanel.Row.State.ENABLED;
        icon = new GLib.ThemedIcon ("emblem-enabled");
        //  icon = new GLib.ThemedIcon ("internet-chat");
        //  icon = null;
        //  this.is_enabled = true;
        update_markup ();
    }

    public new void disable () {
        if (state == Iridium.Widgets.SidePanel.Row.State.DISABLED) {
            return;
        }
        state = Iridium.Widgets.SidePanel.Row.State.DISABLED;
        icon = new GLib.ThemedIcon ("emblem-disabled");
        //  icon = new GLib.ThemedIcon ("internet-chat");
        //  icon = null;
        //  this.is_enabled = false;
        update_markup ();
    }

    public new void error (string error_message, string? error_details) {
        state = Iridium.Widgets.SidePanel.Row.State.ERROR;
    }

    public new void updating () {
        //  icon = new GLib.ThemedIcon ("mail-unread");
        // Maybe add the symbolic chat and user icons so we can specifically use them when not loading?
        // Could also create "disabled" versions of each that are greyed out slightly
        //  icon = new GLib.ThemedIcon (Constants.APP_ID + ".image-loading-symbolic");
        state = Iridium.Widgets.SidePanel.Row.State.UPDATING;
        //  this.is_enabled = false;
        update_markup ();
    }

    public new bool get_enabled () {
        return state == Iridium.Widgets.SidePanel.Row.State.ENABLED;
    }

    public new Iridium.Widgets.SidePanel.Row.State get_state () {
        return state;
    }

    public void set_favorite (bool favorite) {
        is_favorite = favorite;
        update_markup ();
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var edit_topic_item = new Gtk.MenuItem.with_label (_("Edit topic…"));
        edit_topic_item.activate.connect (() => {
            edit_topic ();
        });

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
            if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
                leave_channel ();
            }
            remove_channel ();
        });

        if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
            menu.append (edit_topic_item);
            menu.append (new Gtk.SeparatorMenuItem ());
        }
        if (is_favorite) {
            menu.append (remove_favorite_item);
        } else {
            menu.append (favorite_item);
        }
        menu.append (new Gtk.SeparatorMenuItem ());
        if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
            menu.append (leave_item);
        } else {
            menu.append (join_item);
        }
        menu.append (close_item);

        menu.show_all ();

        return menu;
    }

    public void update_network_name (string network_name) {
        this.network_name = network_name;
        update_markup ();
    }

    private void update_markup () {
        if (is_favorite) {
            var server_text = network_name == null ? server_name : network_name;
            if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
                markup = channel_name + " <small>" + server_text + "</small>";
            } else {
                markup = "<i>" + channel_name + " <small>" + server_text + "</small></i>";
            }
        } else {
            if (state == Iridium.Widgets.SidePanel.Row.State.ENABLED) {
                markup = null;
            } else {
                markup = "<i>" + channel_name + "</i>";
            }
        }
    }

    public signal void edit_topic ();
    public signal void favorite_channel ();
    public signal void remove_favorite_channel ();
    public signal void join_channel ();
    public signal void leave_channel ();
    public signal void remove_channel ();

}
