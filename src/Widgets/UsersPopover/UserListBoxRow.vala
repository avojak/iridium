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

public class Iridium.Widgets.UsersPopover.UserListBoxRow : Gtk.ListBoxRow {

    public string nickname { get; construct; }

    private Gtk.EventBox event_box;

    public UserListBoxRow (string nickname) {
        Object (
            nickname: nickname
        );
    }

    construct {
        event_box = new Gtk.EventBox ();
        event_box.enter_notify_event.connect (() => {
            event_box.set_state_flags (Gtk.StateFlags.PRELIGHT | Gtk.StateFlags.SELECTED, true);
            return false;
        });
        event_box.leave_notify_event.connect (() => {
            event_box.set_state_flags (Gtk.StateFlags.NORMAL, true);
            return false;
        });

        var label = new Gtk.Label (nickname);
        label.margin_top = 4;
        label.margin_bottom = 4;

        event_box.add (label);
        this.add (event_box);
    }

}
