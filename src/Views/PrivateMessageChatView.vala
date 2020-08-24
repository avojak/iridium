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

public class Iridium.Views.PrivateMessageChatView : Iridium.Views.ChatView {

    public string username { get; set; }

    private string last_sender = null;

    public PrivateMessageChatView (string self_nickname, string username) {
        Object (
            nickname: self_nickname,
            username: username
        );
    }

    protected override int get_indent () {
        return -140; // TODO: Figure out how to compute this
    }

    protected override string get_disabled_message () {
        return ""; // TODO: Does this even make sense since we don't allow disabled PM items?
    }

    public override void display_self_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.SelfPrivateMessageText (message);
        rich_text.suppress_sender_username = is_repeat_sender (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = message.username;
    }

    public override void display_server_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.ServerMessageText (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = null;
    }

    public override void display_server_error_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.ServerErrorMessageText (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = null;
    }

    public void display_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.OthersPrivateMessageText (message);
        rich_text.suppress_sender_username = is_repeat_sender (message);
        rich_text.display (text_view.get_buffer ());
        do_autoscroll ();
        last_sender = message.username;
    }

    private bool is_repeat_sender (Iridium.Services.Message message) {
        return last_sender == message.username;
    }

}
