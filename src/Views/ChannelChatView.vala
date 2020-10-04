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

    private Gee.List<string> usernames = new Gee.ArrayList<string> ();
    private string? last_sender = null;

    public ChannelChatView (string nickname) {
        Object (
            nickname: nickname
        );
    }

    protected override int get_indent () {
        return -140; // TODO: Figure out how to compute this
    }

    protected override string get_disabled_message () {
        return _("You must join this channel to begin chatting");
    }

    public override void do_display_self_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.SelfPrivateMessageText (message);
        rich_text.set_usernames (usernames);
        rich_text.suppress_sender_username = is_repeat_sender (message);
        rich_text.display (text_view.get_buffer ());
        //  do_autoscroll ();
        last_sender = message.username;
    }

    public override void do_display_server_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.ServerMessageText (message);
        rich_text.display (text_view.get_buffer ());
        //  do_autoscroll ();
        last_sender = null;
    }

    public override void do_display_server_error_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.ServerErrorMessageText (message);
        rich_text.display (text_view.get_buffer ());
        //  do_autoscroll ();
        last_sender = null;
    }

    public override void do_display_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.OthersPrivateMessageText (message);
        rich_text.set_usernames (usernames);
        rich_text.suppress_sender_username = is_repeat_sender (message);
        rich_text.display (text_view.get_buffer ());
        //  do_autoscroll ();
        last_sender = message.username;
    }

    private bool is_repeat_sender (Iridium.Services.Message message) {
        return last_sender == message.username;
    }

    //  public void display_channel_error_msg (Iridium.Services.Message message) {
    //      // TODO: Maybe use more specific methods in this class for different errors?
    //      //  if (topic_edit_dialog != null) {
    //      //      topic_edit_dialog.display_error (message.message);
    //      //  }
    //  }

    public void set_usernames (Gee.List<string> usernames) {
        this.usernames = usernames;
    }

}
