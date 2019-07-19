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

    private static string TOPIC_PLACEHOLDER_MARKUP = "<i>No channel topic has been set</i>";

    private Gee.List<string> usernames = new Gee.ArrayList<string> ();
    private string last_sender = null;

    private Gtk.Label topic_label;

    construct {
        // TODO: Might still be nice to make this have a horizontal scrollbar if needed
        topic_label = new Gtk.Label (null);
        topic_label.justify = Gtk.Justification.LEFT;
        topic_label.ellipsize = Pango.EllipsizeMode.END;
        topic_label.margin = 6;
        topic_label.wrap = false;
        topic_label.set_markup (TOPIC_PLACEHOLDER_MARKUP);

        insert_row (0);
        attach (topic_label, 0, 0, 1, 1);

        // TODO: Add a GUI way to update the channel topic
        //       Maybe an edit icon with a simple popup dialog?
        //       That would allow the popup to close, then not update
        //       the label until we get the message from the server.

        topic_label.activate_link.connect ((uri) => {
            try {
                AppInfo.launch_default_for_uri (uri, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
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
        if (trimmed_topic == "") {
            topic_label.set_markup (TOPIC_PLACEHOLDER_MARKUP);
            topic_label.set_tooltip_markup ("");
        } else {
            topic_label.set_markup (trimmed_topic);
            topic_label.set_tooltip_markup (trimmed_topic);
        }
    }

}
