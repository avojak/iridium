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

public enum Iridium.Models.InvalidCertificatePolicy {

    REJECT,
    WARN,
    ALLOW;

    public string get_display_string () {
        switch (this) {
            case REJECT:
                return _("Reject");
            case WARN:
                return _("Warn");
            case ALLOW:
                return _("Allow");
            default:
                assert_not_reached ();
        }
    }

    public string get_short_name () {
        switch (this) {
            case REJECT:
                return _("REJECT");
            case WARN:
                return _("WARN");
            case ALLOW:
                return _("ALLOW");
            default:
                assert_not_reached ();
        }
    }

    public static InvalidCertificatePolicy get_value_by_name (string name) {
        EnumClass enumc = (EnumClass) typeof (InvalidCertificatePolicy).class_ref ();
        unowned EnumValue? eval = enumc.get_value_by_name (name);
        if (eval == null) {
            assert_not_reached ();
        }
        return (InvalidCertificatePolicy) eval.value;
    }

    public static InvalidCertificatePolicy get_value_by_short_name (string short_name) {
        switch (short_name) {
            case "REJECT":
                return REJECT;
            case "WARN":
                return WARN;
            case "ALLOW":
                return ALLOW;
            default:
                assert_not_reached ();
        }
    }

}
