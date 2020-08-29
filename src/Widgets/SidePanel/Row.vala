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

public interface Iridium.Widgets.SidePanel.Row : GLib.Object {

    protected enum State {
        ENABLED,
        DISABLED,
        UPDATING
    }

    public abstract string get_server_name ();
    public abstract string? get_channel_name ();
    public abstract void enable ();
    public abstract void disable ();
    public abstract void error (string error_message, string? error_details);
    // TODO: Maybe remove this from interface and add to implementations as 'joining', 'connecting', etc.
    public abstract void updating ();
    //  public abstract State get_state ();
    public abstract bool get_enabled ();

}
