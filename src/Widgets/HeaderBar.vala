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

public class Iridium.Widgets.HeaderBar : Gtk.HeaderBar {

    private Gtk.MenuButton channel_users_button;

    private Iridium.Widgets.UsersPopover.ChannelUsersPopover channel_users_popover;

    public HeaderBar () {
        Object (
            title: Constants.APP_NAME,
            show_close_button: true
        );
    }

    construct {
        var join_button = new Gtk.MenuButton ();
        join_button.set_image (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON));
        join_button.tooltip_text = _("Join");
        join_button.relief = Gtk.ReliefStyle.NONE;
        join_button.valign = Gtk.Align.CENTER;

        var new_server_connection_accellabel = new Granite.AccelLabel.from_action_name (
            _("New Server Connection"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_NEW_SERVER_CONNECTION
        );

        var new_server_connection_menu_item = new Gtk.ModelButton ();
        new_server_connection_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_NEW_SERVER_CONNECTION;
        new_server_connection_menu_item.get_child ().destroy ();
        new_server_connection_menu_item.add (new_server_connection_accellabel);

        var join_channel_accellabel = new Granite.AccelLabel.from_action_name (
            _("Join Channel"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_JOIN_CHANNEL
        );

        var join_channel_menu_item = new Gtk.ModelButton ();
        join_channel_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_JOIN_CHANNEL;
        join_channel_menu_item.get_child ().destroy ();
        join_channel_menu_item.add (join_channel_accellabel);

        var join_popover_grid = new Gtk.Grid ();
        join_popover_grid.margin_top = 3;
        join_popover_grid.margin_bottom = 3;
        join_popover_grid.orientation = Gtk.Orientation.VERTICAL;
        join_popover_grid.width_request = 200;
        join_popover_grid.attach (new_server_connection_menu_item, 0, 0, 1, 1);
        join_popover_grid.attach (join_channel_menu_item, 0, 1, 1, 1);
        join_popover_grid.show_all ();

        var join_popover = new Gtk.Popover (null);
        join_popover.add (join_popover_grid);

        join_button.popover = join_popover;

        channel_users_button = new Gtk.MenuButton ();
        channel_users_button.set_image (new Gtk.Image.from_icon_name ("system-users-symbolic", Gtk.IconSize.BUTTON));
        channel_users_button.tooltip_text = _("Channel users"); // TODO: Enable accelerator
        channel_users_button.relief = Gtk.ReliefStyle.NONE;
        channel_users_button.valign = Gtk.Align.CENTER;

        channel_users_popover = new Iridium.Widgets.UsersPopover.ChannelUsersPopover (channel_users_button);
        channel_users_popover.nickname_selected.connect (on_nickname_selected);
        channel_users_button.popover = channel_users_popover;

        var settings_button = new Gtk.MenuButton ();
        settings_button.image = new Gtk.Image.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.BUTTON);
        settings_button.tooltip_text = _("Menu");
        settings_button.relief = Gtk.ReliefStyle.NONE;
        settings_button.valign = Gtk.Align.CENTER;

        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.primary_icon_tooltip_text = _("Light background");
        mode_switch.secondary_icon_tooltip_text = _("Dark background");
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.halign = Gtk.Align.CENTER;
        mode_switch.margin = 12;
        mode_switch.margin_bottom = 6;
        mode_switch.bind_property ("active", Gtk.Settings.get_default (), "gtk_application_prefer_dark_theme");
        Iridium.Application.settings.bind ("prefer-dark-style", mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var toggle_sidebar_accellabel = new Granite.AccelLabel.from_action_name (
            _("Toggle Sidebar"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_TOGGLE_SIDEBAR
        );

        var toggle_sidebar_menu_item = new Gtk.ModelButton ();
        toggle_sidebar_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_TOGGLE_SIDEBAR;
        toggle_sidebar_menu_item.get_child ().destroy ();
        toggle_sidebar_menu_item.add (toggle_sidebar_accellabel);

        var reset_marker_accellabel = new Granite.AccelLabel.from_action_name (
            _("Reset Marker Line"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_RESET_MARKER
        );

        var reset_marker_menu_item = new Gtk.ModelButton ();
        reset_marker_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_RESET_MARKER;
        reset_marker_menu_item.get_child ().destroy ();
        reset_marker_menu_item.add (reset_marker_accellabel);

        var preferences_accellabel = new Granite.AccelLabel.from_action_name (
            _("Preferences"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_PREFERENCES
        );

        var preferences_menu_item = new Gtk.ModelButton ();
        preferences_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_PREFERENCES;
        preferences_menu_item.get_child ().destroy ();
        preferences_menu_item.add (preferences_accellabel);

        var quit_accellabel = new Granite.AccelLabel.from_action_name (
            _("Quit"),
            Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_QUIT
        );

        var quit_menu_item = new Gtk.ModelButton ();
        quit_menu_item.action_name = Iridium.Services.ActionManager.ACTION_PREFIX + Iridium.Services.ActionManager.ACTION_QUIT;
        quit_menu_item.get_child ().destroy ();
        quit_menu_item.add (quit_accellabel);

        var settings_popover_grid = new Gtk.Grid ();
        settings_popover_grid.margin_bottom = 3;
        settings_popover_grid.orientation = Gtk.Orientation.VERTICAL;
        settings_popover_grid.width_request = 200;
        settings_popover_grid.attach (mode_switch, 0, 0, 1, 1);
        settings_popover_grid.attach (create_menu_separator (12), 0, 1, 1, 1);
        settings_popover_grid.attach (toggle_sidebar_menu_item, 0, 2, 1, 1);
        settings_popover_grid.attach (reset_marker_menu_item, 0, 3, 1, 1);
        settings_popover_grid.attach (preferences_menu_item, 0, 4, 1, 1);
        settings_popover_grid.attach (create_menu_separator (), 0, 5, 1, 1);
        settings_popover_grid.attach (quit_menu_item, 0, 6, 1, 1);
        settings_popover_grid.show_all ();

        var settings_popover = new Gtk.Popover (null);
        settings_popover.add (settings_popover_grid);

        settings_button.popover = settings_popover;

        pack_end (settings_button);
        pack_end (channel_users_button);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_start (join_button);
        pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
    }

    private Gtk.Separator create_menu_separator (int margin_top = 0) {
        var menu_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        menu_separator.margin_top = margin_top;
        return menu_separator;
    }

    public void update_title (string title, string? subtitle) {
        this.title = title;
        this.subtitle = subtitle;
    }

    public void set_channel_users_button_visible (bool visible) {
        channel_users_button.visible = visible;
        channel_users_button.no_show_all = !visible;
    }

    public void set_channel_users_button_enabled (bool enabled) {
        channel_users_button.sensitive = enabled;
    }

    public void set_channel_users (Gee.List<string> nicknames) {
        channel_users_popover.set_users (nicknames);
    }

    private void on_nickname_selected (string nickname) {
        nickname_selected (nickname);
    }

    public signal void nickname_selected (string nickname);

}
