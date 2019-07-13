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

public abstract class Iridium.Models.RichText : GLib.Object {

    // https://github.com/didrocks/geary/blob/master/src/client/util/util-webkit.vala
    private static string URI_REGEX_STR = "(?i)\\b((?:[a-z][\\w-]+:(?:/{1,3}|[a-z0-9%])|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?«»“”‘’]))";
    private static GLib.Regex URI_REGEX;

    public Iridium.Services.Message message { get; construct; }

    //  private string self_username;
    private Gee.List<string> usernames = new Gee.ArrayList<string> ();

    public RichText (Iridium.Services.Message message) {
        Object (
            message: message
        );
    }

    static construct {
        try {
            URI_REGEX = new GLib.Regex (URI_REGEX_STR, GLib.RegexCompileFlags.OPTIMIZE);
        } catch (GLib.RegexError e) {
            // TODO: Handle errors!
            // This should never ever happen
        }
    }

    // Set our username so we can check for it and apply different styling
    //  public void set_username (string username) {
    //      this.self_username = username;
    //  }

    // Set the usernames that will be checked for to apply different styling
    public void set_usernames (Gee.List<string> usernames) {
        this.usernames = usernames;
    }

    public void display (Gtk.TextBuffer buffer) {
        // Display the rich text in the buffer
        do_display (buffer);

        // Apply tags for usernames first (this prevents 'username:' being picked up
        // as a URI)
        apply_username_tags (buffer);

        // Apply tag for URIs
        apply_uri_tags (buffer);

        // Update the "buffer-end" mark to be at the end of the buffer
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);
        if (buffer.get_mark ("buffer-end") == null) {
            buffer.create_mark ("buffer-end", iter, false);
        } else {
            buffer.move_mark_by_name ("buffer-end", iter);
        }
    }

    private void apply_uri_tags (Gtk.TextBuffer buffer) {
        // TODO: Need to update the regex because it matches certain punctuation around a URI
        //       For example, it matches "(www.example.com)." instead of just "www.example.com"
        
        Gtk.TextIter search_start;
        Gtk.TextIter search_end;
        Gtk.TextIter match_start;
        Gtk.TextIter match_end;
        Gtk.TextIter iter;
        
        buffer.get_end_iter (out search_start);
        search_start.backward_chars (message.message.length + 1); // +1 for newline char
        buffer.get_end_iter (out search_end);
        search_end.backward_chars (1); // 1 for newline char

        var text = buffer.get_text (search_start, search_end, false);
        Gee.Set<string> tokens = new Gee.HashSet<string>();
        tokens.add_all_array (text.split (" "));

        var selectable_tag = buffer.get_tag_table ().lookup ("selectable");
        foreach (string token in tokens) {
            if (URI_REGEX.match (token)) {
                iter = search_start;
                // Make sure we're not trying to tag something that's already selectable (i.e. a username)
                if (iter.has_tag (selectable_tag)) {
                    continue;
                }
                while (iter.forward_search (token, Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, search_end)) {
                    buffer.apply_tag_by_name ("hyperlink", match_start, match_end);
                    buffer.apply_tag_by_name ("selectable", match_start, match_end);
                    iter = match_end;
                }
            }
        }
    }

    private void apply_username_tags (Gtk.TextBuffer buffer) {
        Gtk.TextIter search_start;
        Gtk.TextIter search_end;
        Gtk.TextIter match_start;
        Gtk.TextIter match_end;
        foreach (var username in usernames) {
            // Set start_iter and end_iter for the portion of the buffer with the new message
            buffer.get_end_iter (out search_start);
            search_start.backward_chars (message.message.length + 1); // +1 for newline char
            buffer.get_end_iter (out search_end);
            search_end.backward_chars (1);

            while (search_start.forward_search (username, Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, search_end)) {
                if (match_start.starts_word () && match_end.ends_word ()) {
                    buffer.apply_tag_by_name ("inline-username", match_start, match_end);
                    buffer.apply_tag_by_name ("selectable", match_start, match_end);
                }
                search_start = match_end; 
            }
        }

        // TODO: Check for our username and style the whole message
        //  // Reset the search iters
        //  buffer.get_end_iter (out search_start);
        //  search_start.backward_chars (message.message.length + 1); // +1 for newline char
        //  buffer.get_end_iter (out search_end);
        //  search_end.backward_chars (1);
        
        //  // The our username appears, color the whole message
        //  if (search_start.forward_search (self_username, Gtk.TextSearchFlags.CASE_INSENSITIVE, out match_start, out match_end, search_end)) {
        //      buffer.apply_tag_by_name ("inline-self-username", search_start, search_end);
        //  }
    }

    protected abstract void do_display (Gtk.TextBuffer buffer);

}
