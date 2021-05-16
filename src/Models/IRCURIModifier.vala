/*
 * Copyright (c) 2021 Andrew Vojak (https://avojak.com)
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

public enum Iridium.Models.IRCURIModifier {

    IS_NICK,
    IS_SERVER,
    NEED_KEY,
    NEED_PASS;

    public string get_modifier_string () {
        switch (this) {
            case IS_NICK:
                return "isnick";
            case IS_SERVER:
                return "isserver";
            case NEED_KEY:
                return "needkey";
            case NEED_PASS:
                return "needpass";
            default:
                assert_not_reached ();
        }
    }

    public static IRCURIModifier get_value_by_name (string name) {
        EnumClass enumc = (EnumClass) typeof (IRCURIModifier).class_ref ();
        unowned EnumValue? eval = enumc.get_value_by_name (name);
        if (eval == null) {
            assert_not_reached ();
        }
        return (IRCURIModifier) eval.value;
    }

    public static IRCURIModifier? get_value_by_string (string modifier_string) {
        switch (modifier_string) {
            case "isnick":
                return IS_NICK;
            case "isserver":
                return IS_SERVER;
            case "needkey":
                return NEED_KEY;
            case "needpass":
                return NEED_PASS;
            default:
                return null;
        }
    }

}
