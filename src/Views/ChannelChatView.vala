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

public class Iridium.Views.ChannelChatView : Iridium.Views.ChatView {

    private static string TOPIC_PLACEHOLDER = "<i>No channel topic has been set</i>";

    public unowned Iridium.MainWindow main_window { get; construct; }

    private Iridium.Widgets.ChannelTopicEditDialog? topic_edit_dialog;

    private Gee.List<string> usernames = new Gee.ArrayList<string> ();
    private string last_sender = null;

    private Gtk.InfoBar info_bar;
    private Gtk.Label info_label;
    private Gtk.Button edit_button;

    public ChannelChatView (Iridium.MainWindow main_window) {
        Object (
            main_window: main_window
        );
    }

    construct {
        // TODO: Refactor this out
        info_bar = new Gtk.InfoBar ();
        info_bar.set_message_type (Gtk.MessageType.INFO);
        info_bar.set_revealed (true);

        var topic_grid = new Gtk.Grid ();
        topic_grid.orientation = Gtk.Orientation.HORIZONTAL;

        info_label = new Gtk.Label (null);
        info_label.set_use_markup (true);
        info_label.set_markup (TOPIC_PLACEHOLDER); 
        info_label.set_tooltip_text (null);
        info_label.set_halign (Gtk.Align.START);
        info_label.set_hexpand (true);
        info_label.set_selectable (false);
        info_label.set_ellipsize (Pango.EllipsizeMode.END);

        edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.BUTTON);
        edit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        edit_button.relief = Gtk.ReliefStyle.NONE;
        edit_button.valign = Gtk.Align.CENTER;
        edit_button.set_tooltip_text ("Edit topic...");
        edit_button.clicked.connect (() => {
            show_topic_edit_dialog ();
        });
        
        topic_grid.add (info_label);
        topic_grid.add (edit_button);

        info_bar.get_content_area ().add (topic_grid);
        info_bar.get_style_context ().add_class ("inline");

        insert_row (0);
        attach (info_bar, 0, 0, 1, 1);

        // TODO: Add a GUI way to update the channel topic
        //       Maybe an edit icon with a simple popup dialog?
        //       That would allow the popup to close, then not update
        //       the label until we get the message from the server.

        //  topic_label.activate_link.connect ((uri) => {
        //      try {
        //          AppInfo.launch_default_for_uri (uri, null);
        //      } catch (Error e) {
        //          warning ("%s\n", e.message);
        //      }
        //  });
    }

    protected override int get_indent () {
        return -140; // TODO: Figure out how to compute this
    }

    protected override string get_disabled_message () {
        return "You must join this channel to begin chatting";
    }

    private void show_topic_edit_dialog () {
        if (topic_edit_dialog == null) {
            var current_topic = info_label.get_use_markup () ? "" : info_label.get_text ();
            topic_edit_dialog = new Iridium.Widgets.ChannelTopicEditDialog (main_window, current_topic);
            topic_edit_dialog.show_all ();
            topic_edit_dialog.submit_button_clicked.connect ((new_topic) => {
                set_topic (new_topic);
            });
            topic_edit_dialog.destroy.connect (() => {
                topic_edit_dialog = null;
            });
        }
        topic_edit_dialog.present ();
    }

    public override void display_self_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.SelfPrivateMessageText (message);
        rich_text.set_usernames (usernames);
        rich_text.suppress_sender_username = is_repeat_sender (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = message.username;
    }

    public override void display_server_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.ServerMessageText (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = null;
    }

    public void display_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.OthersPrivateMessageText (message);
        rich_text.set_usernames (usernames);
        rich_text.suppress_sender_username = is_repeat_sender (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = message.username;
    }

    private bool is_repeat_sender (Iridium.Services.Message message) {
        return last_sender == message.username;
    }

    public void display_channel_error_msg (Iridium.Services.Message message) {
        // TODO: Maybe use more specific methods in this class for different errors?
        if (topic_edit_dialog != null) {
            topic_edit_dialog.display_error (message.message);
        }
    }

    public void set_usernames (Gee.List<string> usernames) {
        this.usernames = usernames;
    }

    public void set_channel_topic (string? topic) {
        // TODO: Parse this for URLs
        var trimmed_topic = topic == null ? "" : topic.chomp ().chug ();
        if (trimmed_topic == "") {
            info_label.set_use_markup (true);
            info_label.set_markup (TOPIC_PLACEHOLDER);
            info_bar.set_tooltip_text (null);
        } else {
            info_label.set_use_markup (false);
            info_label.set_text (trimmed_topic);
            info_bar.set_tooltip_text ("Channel topic: " + trimmed_topic);
        }
        // Close the edit dialog if it's open
        if (topic_edit_dialog != null) {
            topic_edit_dialog.dismiss();
        }
    }

    public void set_topic_edit_button_enabled (bool enabled) {
        edit_button.sensitive = enabled;
    }

    public signal void set_topic (string new_topic);

}
