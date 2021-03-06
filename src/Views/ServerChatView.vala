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

public class Iridium.Views.ServerChatView : Iridium.Views.ChatView {

    public ServerChatView (Iridium.MainWindow window, string nickname) {
        Object (
            window: window,
            nickname: nickname
        );
    }

    protected override int get_indent () {
        return 0;
    }

    protected override string get_disabled_message () {
        return _("You are not connected to this server");
    }

    public override void do_display_self_private_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.SelfPrivateMessageText (message);
        rich_text.display (text_view.get_buffer ());
    }

    public override void do_display_server_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.ServerMessageText (message);
        rich_text.display (text_view.get_buffer ());
    }

    public override void do_display_server_error_msg (Iridium.Services.Message message) {
        var rich_text = new Iridium.Models.Text.ServerErrorMessageText (message);
        rich_text.display (text_view.get_buffer ());
    }

    public override void do_display_private_msg (Iridium.Services.Message message) {
        // Do nothing
    }

    public override bool does_display_datetime () {
        return false;
    }

}
