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

public class Iridium.Widgets.ServerPanelRow : Gtk.ListBoxRow {

    public string text { get; construct; }

    public ServerPanelRow (string text) {
        Object (
            text: text
        );
    }

    construct {
        var label = new Gtk.Label (text);
        label.xalign = 0;
        label.get_style_context ().add_class ("h4");

        var status_image = new Gtk.Image.from_icon_name ("user-offline", Gtk.IconSize.MENU);

        add (status_image);
        add (label);
    }

}
