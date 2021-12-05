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

public class Iridium.Widgets.StatusBar : Gtk.ActionBar {

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        var server_connect_accellabel = new Granite.AccelLabel.from_action_name (
            _("New Server Connection…"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_NEW_SERVER_CONNECTION
        );

        var server_connect_menu_item = new Gtk.ModelButton ();
        server_connect_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_NEW_SERVER_CONNECTION;
        server_connect_menu_item.get_child ().destroy ();
        server_connect_menu_item.add (server_connect_accellabel);

        var channel_join_accellabel = new Granite.AccelLabel.from_action_name (
            _("Join Channel…"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_JOIN_CHANNEL
        );

        var channel_join_menu_item = new Gtk.ModelButton ();
        channel_join_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_JOIN_CHANNEL;
        channel_join_menu_item.get_child ().destroy ();
        channel_join_menu_item.add (channel_join_accellabel);

        var join_popover_grid = new Gtk.Grid ();
        join_popover_grid.margin_top = 3;
        join_popover_grid.margin_bottom = 3;
        join_popover_grid.orientation = Gtk.Orientation.VERTICAL;
        join_popover_grid.width_request = 200;
        join_popover_grid.attach (server_connect_menu_item, 0, 0, 1, 1);
        join_popover_grid.attach (channel_join_menu_item, 0, 1, 1, 1);
        join_popover_grid.show_all ();

        var join_popover = new Gtk.Popover (null);
        join_popover.add (join_popover_grid);

        var add_menu_button = new Gtk.MenuButton ();
        add_menu_button.label = _("Join…");
        add_menu_button.direction = Gtk.ArrowType.UP;
        add_menu_button.popover = join_popover;
        add_menu_button.tooltip_text = _("Join a Server or Channel");
        add_menu_button.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_menu_button.always_show_image = true;
        add_menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        pack_start (add_menu_button);
    }

}
