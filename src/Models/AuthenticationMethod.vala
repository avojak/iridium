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

public enum Iridium.Models.AuthenticationMethod { 
    
    NONE,
    SERVER_PASSWORD;

    public string get_display_string () {
        switch (this) {
            case NONE:
                return _("None");
            case SERVER_PASSWORD:
                return _("Server Password");
            default:
                assert_not_reached ();
        }
    }

    public static AuthenticationMethod get_value_by_name (string name) {
        EnumClass enumc = (EnumClass) typeof (AuthenticationMethod).class_ref ();
        unowned EnumValue? eval = enumc.get_value_by_name (name);
        if (eval == null) {
			assert_not_reached ();
		}
		return (AuthenticationMethod) eval.value;
        //  switch (display) {
        //      case "None":
        //          return NONE;
        //      case "Server Password":
        //          return SERVER_PASSWORD;
        //      default:
        //          assert_not_reached ();
        //  }
    }

}