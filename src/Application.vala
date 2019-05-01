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
public class IridiumApp : Gtk.Application {

    public IridiumApp () {
        Object (
            application_id: "com.github.avojak.iridium",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 300;
        main_window.default_width = 300;
        main_window.title = _("Iridium");

        var label = new Gtk.Label (_("Hello, world!"));

        main_window.add (label);
        main_window.show_all ();
    }

    public static int main (string[] args) {
        return new IridiumApp ().run (args);
    }

}
