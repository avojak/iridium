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

    //  private Gtk.Button channel_join_button;
    private Gtk.MenuButton channel_users_button;
    //  private Gtk.ToggleButton channel_topic_button;

    private Iridium.Widgets.UsersPopover.ChannelUsersPopover channel_users_popover;

    public HeaderBar () {
        Object (
            title: Constants.APP_NAME,
            show_close_button: true
        );
    }

    construct {
        //  var server_connect_button = new Gtk.Button.from_icon_name (Constants.APP_ID + ".network-server-new", Gtk.IconSize.LARGE_TOOLBAR);
        //  /* var server_connect_button = new Gtk.Button.from_icon_name ("network-server", Gtk.IconSize.BUTTON); */
        //  server_connect_button.tooltip_text = _("Connect to a Server");
        //  server_connect_button.relief = Gtk.ReliefStyle.NONE;
		//  server_connect_button.valign = Gtk.Align.CENTER;
        //  // TODO: Support keyboard accelerator
        //  server_connect_button.clicked.connect (() => {
        //      server_connect_button_clicked ();
        //  });

        //  channel_join_button = new Gtk.Button.from_icon_name (Constants.APP_ID + ".internet-chat-new", Gtk.IconSize.LARGE_TOOLBAR);
        //  /* var channel_join_button = new Gtk.Button.from_icon_name ("internet-chat", Gtk.IconSize.BUTTON); */
        //  channel_join_button.tooltip_text = _("Join a Channel");
        //  channel_join_button.relief = Gtk.ReliefStyle.NONE;
		//  channel_join_button.valign = Gtk.Align.CENTER;
        //  // TODO: Support keyboard accelerator
        //  channel_join_button.sensitive = false;
        //  channel_join_button.clicked.connect (() => {
        //      channel_join_button_clicked ();
        //  });


        // TODO: Make this display a menu rather than be a toggle. The menu can have a toggle item
        //       and an edit item.
        //  channel_topic_button = new Gtk.ToggleButton ();
        //  channel_topic_button.set_image (new Gtk.Image.from_icon_name ("help-faq-symbolic", Gtk.IconSize.BUTTON));
        //  channel_topic_button.tooltip_text = _("Show channel topic"); // TODO: Enable accelerator
        //  channel_topic_button.relief = Gtk.ReliefStyle.NONE;
        //  channel_topic_button.valign = Gtk.Align.CENTER;
        //  channel_topic_button.toggled.connect (() => {
        //      var active = channel_topic_button.get_active ();
        //      if (active) {
        //          channel_topic_button.tooltip_text = _("Hide channel topic");
        //      } else {
        //          channel_topic_button.tooltip_text = _("Show channel topic");
        //      }
        //      channel_topic_toggled (active);
        //  });

        channel_users_button = new Gtk.MenuButton ();
        channel_users_button.set_image (new Gtk.Image.from_icon_name ("system-users-symbolic", Gtk.IconSize.BUTTON));
        channel_users_button.tooltip_text = _("Channel users"); // TODO: Enable accelerator
        channel_users_button.relief = Gtk.ReliefStyle.NONE;
		channel_users_button.valign = Gtk.Align.CENTER;

        channel_users_popover = new Iridium.Widgets.UsersPopover.ChannelUsersPopover (channel_users_button);
        channel_users_popover.username_selected.connect (on_username_selected);
        channel_users_button.popover = channel_users_popover;

        //  var preferences_button = new Gtk.Button.from_icon_name ("preferences-system-symbolic", Gtk.IconSize.BUTTON);
        //  preferences_button.tooltip_text = _("Preferences");
        //  preferences_button.relief = Gtk.ReliefStyle.NONE;
        //  preferences_button.valign = Gtk.Align.CENTER;
        //  preferences_button.clicked.connect (() => {
        //      preferences_button_clicked ();
        //  });

        // TODO: Move this to a settings menu
        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.primary_icon_tooltip_text = _("Light background");
        mode_switch.secondary_icon_tooltip_text = _("Dark background");
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.bind_property ("active", Iridium.Application.settings, "prefer-dark-style");
        mode_switch.notify.connect (() => {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = Iridium.Application.settings.prefer_dark_style;
        });
        if (Iridium.Application.settings.prefer_dark_style) {
            mode_switch.active = true;
        }

        //  pack_start (server_connect_button);
        //  pack_start (channel_join_button);

        pack_end (mode_switch);
        //  pack_end (preferences_button);
        pack_end (channel_users_button);
        //  pack_end (channel_topic_button);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
    }

    public void update_title (string title, string? subtitle) {
        this.title = title;
        this.subtitle = subtitle;
    }

    //  public void set_channel_join_button_enabled (bool enabled) {
    //      channel_join_button.sensitive = enabled;
    //  }

    //  public void set_channel_topic_button_visible (bool visible) {
        //  channel_topic_button.visible = visible;
        //  channel_topic_button.no_show_all = !visible;
    //  }

    //  public void set_channel_topic_button_enabled (bool enabled) {
        //  channel_topic_button.sensitive = enabled;
    //  }

    //  public bool get_channel_topic_button_active () {
        //  return channel_topic_button.get_active ();
    //  }

    public void set_channel_users_button_visible (bool visible) {
        channel_users_button.visible = visible;
        channel_users_button.no_show_all = !visible;
    }

    public void set_channel_users_button_enabled (bool enabled) {
        channel_users_button.sensitive = enabled;
    }

    public void set_channel_users (Gee.List<string> usernames) {
        channel_users_popover.set_users (usernames);
    }

    private void on_username_selected (string username) {
        username_selected (username);
    }

    //  public signal void server_connect_button_clicked ();
    //  public signal void channel_join_button_clicked ();
    //  public signal void preferences_button_clicked ();
    //  public signal void channel_topic_toggled (bool visible);
    public signal void username_selected (string username);

}
