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

public class Iridium.Widgets.TextView : Gtk.SourceView {

    // TODO: WHY CANT YOU CLICK AND DRAG TO SELECT TEXT???

    private const string COLOR_ORANGE = "#ffa154"; // "#f37329";

    public TextView (int text_indent) {
        Object (
            pixels_below_lines: 3,
            border_width: 12,
            wrap_mode: Gtk.WrapMode.WORD_CHAR,
            /* margin: 140, */
            indent: text_indent,
            monospace: true,
            editable: false,
            cursor_visible: false,
            vexpand: true,
            hexpand: true
        );
    }

    construct {
        Gtk.CssProvider font_css_provider = new Gtk.CssProvider ();
        get_style_context ().add_provider (font_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        string font = Iridium.Application.settings.get_string ("font");
        /* Convert font description to css equivalent and apply to the .view node */
        var font_css = string.join (" ",
            ".view {",
            Iridium.Widgets.FontUtils.pango_font_description_to_css (Pango.FontDescription.from_string (font)),
            "}"
        );
        try {
            font_css_provider.load_from_data (font_css);
        } catch (Error e) {
            critical (e.message);
        }
    }

    public bool is_marker_onscreen () {
         if (buffer.get_mark ("last-read-message") == null) {
            return false;
        }

        // Get the location of the last read message
        Gtk.TextIter iter;
        buffer.get_iter_at_mark (out iter, buffer.get_mark ("last-read-message"));
        iter.forward_to_line_end ();

        Gdk.Rectangle rect;
        get_iter_location (iter, out rect);

        // Convert to window coordinates
        int window_x;
        int window_y;
        buffer_to_window_coords (Gtk.TextWindowType.TEXT, rect.x, rect.y, out window_x, out window_y);

        return window_y > 0 && window_y < vadjustment.upper;
    }

    protected override bool draw (Cairo.Context ctx) {
        base.draw (ctx);

        // If there's no last read message mark, there's no place to draw the line
        if (buffer.get_mark ("last-read-message") == null) {
            return false;
        }

        // Get the location of the last read message
        Gtk.TextIter iter;
        buffer.get_iter_at_mark (out iter, buffer.get_mark ("last-read-message"));
        iter.forward_to_line_end ();

        Gdk.Rectangle rect;
        get_iter_location (iter, out rect);
        int line_y; // Don't use this - use line_y_window instead
        int line_height;
        get_line_yrange (iter, out line_y, out line_height);

        // Convert to window coordinates
        int line_x_window;
        int line_y_window;
        buffer_to_window_coords (Gtk.TextWindowType.TEXT, rect.x, rect.y, out line_x_window, out line_y_window);

        // Don't include the border_width, because it gets buggy and sometimes doesn't update the part of the line in the border
        double render_width = hadjustment.upper + left_margin + right_margin;
        double render_x = left_margin + border_width;
        double render_y = line_y_window + line_height + border_width;

        ctx.save ();

        var rgba = Gdk.RGBA ();
        rgba.parse (Iridium.Models.ColorPalette.COLOR_ORANGE.get_value ());
        ctx.set_source_rgba (rgba.red, rgba.green, rgba.blue, 1);
        ctx.set_line_width (1);

        ctx.move_to (render_x, render_y);
        ctx.line_to (render_width, render_y);

        ctx.stroke ();
        ctx.restore ();

        return false;
    }

}
