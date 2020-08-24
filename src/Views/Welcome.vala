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

public class Iridium.Views.Welcome : Granite.Widgets.Welcome {

    public unowned Iridium.MainWindow window { get; construct; }

    public Welcome (Iridium.MainWindow window) {
        Object (
            window: window,
            title: _("Welcome to Iridium"),
            subtitle: _("Connect to Any IRC Server")
        );
    }

    construct {
        valign = Gtk.Align.FILL;
        halign = Gtk.Align.FILL;
        vexpand = true;

        // TODO: Instead, simply have an option to connect to a new server. We
        //       can maybe have a separate star icon for favoriting?
        // TODO: Revisit the wording based on human interface guidelines
        append (Constants.APP_ID + ".network-server-new", _("Add a New Server"), _("Connect to a server and save it in the server list"));
        //  append ("document-open-recent", _("Recently Connected"), _("Connect to a recently connected server"));

        // TODO: Have an option for connecting to a server from a list of
        //       popular/common servers?

        activated.connect (index => {
            switch (index) {
                case 0:
                    Iridium.Services.ActionManager.action_from_group (Iridium.Services.ActionManager.ACTION_NEW_SERVER_CONNECTION, window.get_action_group ("win"));
                break;
            }
        });
    }

}
