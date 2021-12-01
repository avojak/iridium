/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
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

public class Iridium.Services.ActionManager : GLib.Object {

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_NEW_WINDOW = "action_new_window";
    public const string ACTION_NEW_SERVER_CONNECTION = "action_new_server_connection";
    public const string ACTION_JOIN_CHANNEL = "action_join_channel";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_ZOOM_IN = "action_zoom_in";
    public const string ACTION_ZOOM_OUT = "action_zoom_out";
    public const string ACTION_ZOOM_DEFAULT = "action_zoom_default";
    public const string ACTION_DISCONNECT_FROM_SERVER = "action_disconnect_from_server";
    public const string ACTION_LEAVE_CHANNEL = "action_leave_channel";
    public const string ACTION_FAVORITE_CHANNEL = "action_favorite_channel";
    public const string ACTION_PREFERENCES = "action_preferences";
    public const string ACTION_TOGGLE_SIDEBAR = "action_toggle_sidebar";
    public const string ACTION_RESET_MARKER = "action_reset_marker";
    public const string ACTION_BROWSE_SERVERS = "action_browse_servers";

    public const string ACTION_SHOW_CHAT_VIEW = "action-show-chat-view";

    private const GLib.ActionEntry[] ACTION_ENTRIES = {
        { ACTION_NEW_WINDOW, action_new_window },
        { ACTION_NEW_SERVER_CONNECTION, action_new_server_connection },
        { ACTION_JOIN_CHANNEL, action_join_channel },
        { ACTION_QUIT, action_quit },
        { ACTION_ZOOM_IN, action_zoom_in },
        { ACTION_ZOOM_OUT, action_zoom_out },
        { ACTION_ZOOM_DEFAULT, action_zoom_default },
        { ACTION_DISCONNECT_FROM_SERVER, action_disconnect_from_server },
        { ACTION_LEAVE_CHANNEL, action_leave_channel },
        { ACTION_FAVORITE_CHANNEL, action_favorite_channel },
        { ACTION_PREFERENCES, action_preferences },
        { ACTION_TOGGLE_SIDEBAR, action_toggle_sidebar },
        { ACTION_RESET_MARKER, action_reset_marker },
        { ACTION_BROWSE_SERVERS, action_browse_servers }
    };

    private const GLib.ActionEntry[] APP_ACTION_ENTRIES = {
        { ACTION_SHOW_CHAT_VIEW, action_show_chat_view, "(ss)" }
    };

    private static Gee.MultiMap<string, string> accelerators;

    public unowned Iridium.Application application { get; construct; }
    public unowned Iridium.MainWindow window { get; construct; }

    private GLib.SimpleActionGroup action_group;

    public ActionManager (Iridium.Application application, Iridium.MainWindow window) {
        Object (
            application: application,
            window: window
        );
    }

    static construct {
        accelerators = new Gee.HashMultiMap<string, string> ();
        //  accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
        accelerators.set (ACTION_NEW_SERVER_CONNECTION, "<Control><Shift>n");
        accelerators.set (ACTION_JOIN_CHANNEL, "<Control>j");
        accelerators.set (ACTION_QUIT, "<Control>q");
        //  accelerators.set (ACTION_ZOOM_IN, "<Control>plus");
        //  accelerators.set (ACTION_ZOOM_IN, "<Control>equal");
        //  accelerators.set (ACTION_ZOOM_IN, "<Control>KP_Add");
        //  accelerators.set (ACTION_ZOOM_OUT, "<Control>minus");
        //  accelerators.set (ACTION_ZOOM_OUT, "<Control>KP_Subtract");
        //  accelerators.set (ACTION_ZOOM_DEFAULT, "<Control>0");
        //  accelerators.set (ACTION_ZOOM_DEFAULT, "<Control>KP_0");
        //  accelerators.set (ACTION_DISCONNECT_FROM_SERVER, "<Control>d");
        //  accelerators.set (ACTION_LEAVE_CHANNEL, "<Control>l");
        //  accelerators.set (ACTION_FAVORITE_CHANNEL, "<Control>s");
        accelerators.set (ACTION_PREFERENCES, "<Control><Shift>p");
        accelerators.set (ACTION_TOGGLE_SIDEBAR, "<Control>backslash");
        accelerators.set (ACTION_RESET_MARKER, "<Control>m");
    }

    construct {
        action_group = new GLib.SimpleActionGroup ();
        action_group.add_action_entries (ACTION_ENTRIES, this);
        window.insert_action_group ("win", action_group);

        foreach (var action in accelerators.get_keys ()) {
            var accelerators_array = accelerators[action].to_array ();
            accelerators_array += null;
            application.set_accels_for_action (ACTION_PREFIX + action, accelerators_array);
        }

        application.add_action_entries (APP_ACTION_ENTRIES, this);
    }

    public static void action_from_group (string action_name, ActionGroup action_group, Variant? parameter = null) {
        action_group.activate_action (action_name, parameter);
    }

    private void action_new_window () {
        // TODO
    }

    private void action_new_server_connection () {
        window.show_server_connection_dialog ();
    }

    private void action_join_channel (SimpleAction action, Variant? parameter) {
        if (parameter == null) {
            window.show_channel_join_dialog (null);
            return;
        }
        string[] parameters = parameter.get_strv ();
        if (parameters.length != 2) {
            warning ("Expected 2 variant parameters");
            return;
        }
        debug (parameters[0]);
        debug (parameters[1]);
    }

    private void action_quit () {
        window.before_destroy ();
    }

    private void action_zoom_in () {
        // TODO
    }

    private void action_zoom_out () {
        // TODO
    }

    private void action_zoom_default () {
        // TODO
    }

    private void action_disconnect_from_server () {
        // TODO
    }

    private void action_leave_channel () {
        // TODO
    }

    private void action_favorite_channel () {
        // TODO
    }

    private void action_preferences () {
        window.show_preferences_dialog ();
    }

    private void action_toggle_sidebar () {
        window.toggle_sidebar ();
    }

    private void action_reset_marker () {
        window.reset_marker_line ();
    }

    private void action_browse_servers () {
        window.show_browse_servers_dialog ();
    }

    private void action_show_chat_view (SimpleAction action, Variant? parameter) {
        if (parameter == null) {
            return;
        }
        if (parameter.n_children () != 2) {
            warning ("Expected 2 variant children");
            return;
        }
        string server_name = parameter.get_child_value (0).get_string ();
        string channel_name = parameter.get_child_value (1).get_string ();
        window.show_chat_view (server_name, channel_name);
    }

}
