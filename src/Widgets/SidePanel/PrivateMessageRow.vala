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

public class Iridium.Widgets.SidePanel.PrivateMessageRow : Granite.Widgets.SourceList.ExpandableItem, Iridium.Widgets.SidePanel.Row {

    private Iridium.Widgets.SidePanel.Row.State _state;

    public string nickname { get; set; }
    public string server_name { get; construct; }

    public Iridium.Widgets.SidePanel.Row.State state {
        get {
            lock (_state) {
                return _state;
            }
        }
        set {
            lock (_state) {
                _state = value;
            }
        }
    }

    public PrivateMessageRow (string nickname, string server_name) {
        Object (
            name: nickname,
            nickname: nickname,
            server_name: server_name,
            icon: new GLib.ThemedIcon ("system-users"),
            state: Iridium.Widgets.SidePanel.Row.State.DISABLED
        );
    }

    public new string get_server_name () {
        return server_name;
    }

    public new string? get_channel_name () {
        return nickname;
    }

    public new void enable () {
        state = Iridium.Widgets.SidePanel.Row.State.ENABLED;
        update_icon ("system-users");
        markup = null;
    }

    public new void disable () {
        state = Iridium.Widgets.SidePanel.Row.State.DISABLED;
        markup = "<i>" + nickname + "</i>";
    }

    public new void error () {
        // Private messages don't have an error state
    }

    public new void updating () {
        // Private messages don't have an updating state
    }

    public new bool get_enabled () {
        return state == Iridium.Widgets.SidePanel.Row.State.ENABLED;
    }

    public new Iridium.Widgets.SidePanel.Row.State get_state () {
        return state;
    }

    public override Gtk.Menu? get_context_menu () {
        var menu = new Gtk.Menu ();

        var close_item = new Gtk.MenuItem.with_label (_("Close"));
        close_item.activate.connect (() => {
            close_private_message ();
        });

        menu.append (close_item);
        menu.show_all ();

        return menu;
    }

    public void update_nickname (string nickname) {
        this.name = nickname;
        this.nickname = nickname;
    }

    private void update_icon (string icon_name) {
        Idle.add (() => {
            icon = new GLib.ThemedIcon (icon_name);
            return false;
        });
    }

    public signal void close_private_message ();

}
