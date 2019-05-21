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

    public weak Iridium.Views.Welcome welcome_view { get; construct; }
    public unowned Iridium.Widgets.SidePanel.Panel side_panel { get; construct; }

    private Gtk.Stack main_stack;

    public MainLayout (Iridium.Views.Welcome welcome_view, Iridium.Widgets.SidePanel.Panel side_panel) {
        Object (
            orientation: Gtk.Orientation.HORIZONTAL,
            welcome_view: welcome_view,
            side_panel: side_panel
        );
    }

    construct {
        position = 240;

        main_stack = new Gtk.Stack ();
        main_stack.add_named (welcome_view, "welcome");

        pack1 (side_panel, false, false);
        pack2 (main_stack, true, false);
    }

    public void add_chat_view (Iridium.Views.ChatView view, string name) {
        if (get_chat_view (name) != null) {
            return;
        }
        main_stack.add_named (view, name);
    }

    public void remove_chat_view (string name, string alternative) {
        var view = get_chat_view (name);
        // If the chat view to remove is currently being displayed, show
        // the alternative view
        if (main_stack.get_visible_child () == view) {
            show_chat_view (alternative);
        }
        main_stack.remove (view);
    }

    public Iridium.Views.ChatView? get_chat_view (string name) {
        var view = main_stack.get_child_by_name (name);
        return (Iridium.Views.ChatView) view;
    }

    // TODO: Add methods here so we don't have to do type-casting at the consumer level

    public Iridium.Views.ChannelChatView? get_channel_chat_view (string name) {
        return main_stack.get_child_by_name (name) as Iridium.Views.ChannelChatView;
    }

    public Iridium.Views.ServerChatView? get_server_chat_view (string name) {
        return main_stack.get_child_by_name (name) as Iridium.Views.ServerChatView;
    }

    public void show_chat_view (string name) {
        main_stack.get_child_by_name (name).show_all ();
        main_stack.set_visible_child_full (name, Gtk.StackTransitionType.SLIDE_RIGHT);
        // TODO: Set focus on the text entry
    }

}
