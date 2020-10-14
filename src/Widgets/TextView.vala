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

        // Convert to window coordinates
        int window_x;
        int window_y;
        buffer_to_window_coords (Gtk.TextWindowType.TEXT, rect.x, rect.y, out window_x, out window_y);

        // Don't include the border_width, because it gets buggy and sometimes doesn't update the part of the line in the border
        double line_width = hadjustment.upper + left_margin + right_margin;
        double line_x = left_margin + border_width;
        double line_y = window_y + 10; // TODO: Compute this based on font size and padding between lines

        ctx.save ();

        var rgba = Gdk.RGBA ();
        rgba.parse (Iridium.Models.ColorPalette.COLOR_ORANGE.get_value ());
        ctx.set_source_rgba (rgba.red, rgba.green, rgba.blue, 1);
        ctx.set_line_width (1);

        ctx.move_to (line_x, line_y);
        ctx.line_to (line_width, line_y);

        ctx.stroke ();
        ctx.restore ();

        return false;
    }

}
