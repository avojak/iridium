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

public class Iridium.Widgets.ChannelTopicEditDialog : Gtk.Dialog {

    // TODO: Query for the topic length limit and show it in the dialog

    public unowned Iridium.MainWindow main_window { get; construct; }
    public string current_topic { get; construct; }

    private Gtk.TextView text_view;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    public ChannelTopicEditDialog (Iridium.MainWindow main_window, string current_topic) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Edit Channel Topic"),
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            current_topic: current_topic
        );
    }

    construct {
        var body = get_content_area ();

        // Create the header
        var header_grid = new Gtk.Grid ();
        header_grid.margin_start = 30;
        header_grid.margin_end = 30;
        header_grid.margin_bottom = 10;
        header_grid.column_spacing = 10;

        var header_image = new Gtk.Image.from_icon_name ("edit", Gtk.IconSize.DIALOG);

        var header_title = new Gtk.Label (_("Edit Channel Topic"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

        body.add (header_grid);

        // Create the form
        var form_grid = new Gtk.Grid ();
        form_grid.margin = 30;
        form_grid.row_spacing = 12;
        form_grid.column_spacing = 20;

        text_view = new Gtk.TextView ();
        text_view.set_pixels_below_lines (3);
        text_view.set_border_width (12);
        text_view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        text_view.set_editable (true);
        text_view.set_cursor_visible (true);
        text_view.set_vexpand (true);
        text_view.set_hexpand (true);

        // Initialize the buffer iterator
        Gtk.TextIter iter;
        text_view.get_buffer ().get_end_iter (out iter);
        text_view.get_buffer ().set_text (current_topic);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled_window.set_shadow_type (Gtk.ShadowType.ETCHED_IN);
        scrolled_window.add (text_view);
        scrolled_window.set_size_request (100, 100);

        form_grid.attach (scrolled_window, 0, 0, 1, 1);

        body.add (form_grid);

        spinner = new Gtk.Spinner ();
        body.add (spinner);

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_line_wrap (true); // TODO: Fix this - it's not working as expected for long error messages
        status_label.margin_bottom = 10;
        body.add (status_label);

        // Add action buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            close ();
        });

        var submit_button = new Gtk.Button.with_label (_("Submit"));
        submit_button.get_style_context ().add_class ("suggested-action");
        submit_button.clicked.connect (() => {
            spinner.start ();
            status_label.label = "";
            submit_button_clicked (get_new_topic ());
        });

        submit_button.sensitive = get_new_topic () != current_topic;
        text_view.get_buffer ().changed.connect (() => {
            var new_topic = get_new_topic ();
            submit_button.sensitive = new_topic != current_topic;
            if (new_topic.length == 0 && current_topic.length != 0) {
                // Make sure current topic isn't empty - doesn't make sense to clear
                // something that's already empty
                submit_button.set_label (_("Clear topic"));
            } else {
                submit_button.set_label (_("Submit"));
            }
        });

        add_action_widget (cancel_button, 0);
        add_action_widget (submit_button, 1);
    }

    private string get_new_topic () {
        Gtk.TextIter start;
        text_view.get_buffer ().get_start_iter (out start);
        Gtk.TextIter end;
        text_view.get_buffer ().get_end_iter (out end);
        return text_view.get_buffer ().get_text (start, end, false).chomp ().chug ().replace ("\n", " ");
    }

    public void dismiss () {
        spinner.stop ();
        close ();
    }

    public void display_error (string message) {
        // TODO: We can make the error messaging better
        spinner.stop ();
        status_label.label = message;
    }

    public signal void submit_button_clicked (string new_topic);

}
