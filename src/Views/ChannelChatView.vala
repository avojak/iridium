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

    private static string TOPIC_PLACEHOLDER = "No channel topic has been set";

    private Gee.List<string> usernames = new Gee.ArrayList<string> ();
    private string last_sender = null;

    private Gtk.Entry topic_entry;

    construct {
        topic_entry = new Gtk.Entry ();
        topic_entry.hexpand = true;
        topic_entry.margin = 6;
        topic_entry.editable = false; // TODO: Enable this to allow changing the channel topic
        //  topic_entry.secondary_icon_tooltip_text = "Channel Topic Info";
        topic_entry.placeholder_text = TOPIC_PLACEHOLDER;

        insert_row (0);
        attach (topic_entry, 0, 0, 1, 1);

        topic_entry.changed.connect (() => {
            // TODO: Implement this at some point to display who set the topic and when
            //  if (topic_entry.text != "") {
            //      topic_entry.secondary_icon_name = "dialog-information-symbolic";
            //  } else {
            //      topic_entry.secondary_icon_name = null;
            //  }
        });
    }

    protected override int get_indent () {
        return -140; // TODO: Figure out how to compute this
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
        // TODO: Implement
    }

    public void set_usernames (Gee.List<string> usernames) {
        this.usernames = usernames;
    }

    public void set_channel_topic (string? topic) {
        var trimmed_topic = topic == null ? "" : topic.chomp ().chug ();
        topic_entry.set_text (trimmed_topic);
        topic_entry.set_tooltip_text (trimmed_topic == "" ? TOPIC_PLACEHOLDER : trimmed_topic);
    }

}
