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

    public unowned Iridium.MainWindow main_window { get; construct; }

    private Gtk.Stack server_stack;
    private Gtk.Stack main_stack;

    public MainLayout (Iridium.MainWindow main_window) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            main_window: main_window
        );
    }

    construct {
        position = 240;
        
        server_stack = new Gtk.Stack ();

        main_stack = new Gtk.Stack ();
        Iridium.Views.Welcome welcome_view = new Iridium.Views.Welcome (main_window);
        main_stack.add_named (welcome_view, "welcome");

        pack1 (server_stack, false, false);
        pack2 (main_stack, true, false);
    }

}
