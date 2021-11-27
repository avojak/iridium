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

public class Iridium.Models.Text.TextBufferUtils {

    public static bool search_word_in_string (string needle, string haystack, WordMatchDelegate handler) {
        Gtk.TextBuffer text_buffer = new Gtk.TextBuffer (null) {
            text = haystack
        };
        Gtk.TextIter search_start;
        Gtk.TextIter search_end;
        text_buffer.get_end_iter (out search_start);
        search_start.backward_chars (haystack.length);
        text_buffer.get_end_iter (out search_end);

        return search_word_in_buffer (needle, text_buffer, search_start, search_end, handler);
    }

    public static bool search_word_in_buffer (string needle, Gtk.TextBuffer text_buffer, Gtk.TextIter start, Gtk.TextIter end, WordMatchDelegate handler) {
        bool has_match = false;
        Gtk.TextIter search_start = start;
        Gtk.TextIter search_end = end;
        Gtk.TextIter match_start;
        Gtk.TextIter match_end;
        while (search_start.forward_search (needle, Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, search_end)) {
            if (match_start.starts_word () && match_end.ends_word ()) {
                has_match = true;
                if (!handler (match_start, match_end)) {
                    return has_match;
                }
            }
            search_start = match_end;
        }
        return has_match;
    }

    // Return whether or not to continue searching after finding a match
    public delegate bool WordMatchDelegate (Gtk.TextIter match_start, Gtk.TextIter match_end);

}