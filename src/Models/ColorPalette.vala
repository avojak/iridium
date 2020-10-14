/*
 * Copyright (c) 2020 Andrew Vojak (https://avojak.com)
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

public enum Iridium.Models.ColorPalette {

    COLOR_STRAWBERRY,
    COLOR_ORANGE,
    COLOR_LIME,
    COLOR_BLUEBERRY;

    public string get_value () {
        var prefer_dark_style = Iridium.Application.settings.get_boolean ("prefer-dark-style");
        // Colors defined by the elementary OS Human Interface Guidelines
        // When in the "dark style", use shades that are one step lighter than the "middle" value
        switch (this) {
            case COLOR_STRAWBERRY:
                return prefer_dark_style ? "#ed5353" : "#c6262e";
            case COLOR_ORANGE:
                return prefer_dark_style ? "#ffa154" : "#cc3b02";
            case COLOR_LIME:
                return prefer_dark_style ? "#9bdb4d" : "#3a9104";
            case COLOR_BLUEBERRY:
                return prefer_dark_style ? "#64baff" : "#3689e6";
            default:
                assert_not_reached ();
        }
    }

}
