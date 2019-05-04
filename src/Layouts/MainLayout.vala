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

public class Iridium.Layouts.MainLayout : Gtk.Paned {

    public unowned Iridium.Views.Welcome welcome_view { get; construct; }
    public unowned Iridium.Widgets.ServerPanel server_panel { get; construct; }

    private Gtk.Stack server_stack;
    private Gtk.Stack main_stack;

    public MainLayout (Iridium.Views.Welcome welcome_view, Iridium.Widgets.ServerPanel server_panel) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            welcome_view: welcome_view,
            server_panel: server_panel
        );
    }

    construct {
        position = 240;

        server_stack = new Gtk.Stack ();
        server_stack.add_named (server_panel, "server_panel");

        main_stack = new Gtk.Stack ();
        main_stack.add_named (welcome_view, "welcome");

        pack1 (server_stack, false, false);
        pack2 (main_stack, true, false);
    }

}
