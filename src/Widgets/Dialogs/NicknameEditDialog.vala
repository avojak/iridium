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

public class Iridium.Widgets.NicknameEditDialog : Granite.Dialog {

    public unowned Iridium.MainWindow main_window { get; construct; }
    public string current_nickname { get; construct; }

    private Gtk.Entry entry;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    public NicknameEditDialog (Iridium.MainWindow main_window, string current_nickname) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Edit Nickname"),
            transient_for: main_window,
            modal: true,
            main_window: main_window,
            current_nickname: current_nickname
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

        var header_title = new Gtk.Label (_("Edit Nickname"));
        header_title.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_title.halign = Gtk.Align.START;
        header_title.hexpand = true;
        header_title.margin_end = 10;
        header_title.set_line_wrap (true);

        header_grid.attach (header_image, 0, 0, 1, 1);
        header_grid.attach (header_title, 1, 0, 1, 1);

        body.add (header_grid);

        entry = new Gtk.Entry ();
        entry.hexpand = true;
        entry.text = current_nickname;

        var form_grid = new Gtk.Grid ();
        form_grid.margin = 30;
        form_grid.row_spacing = 12;
        form_grid.column_spacing = 20;

        form_grid.attach (entry, 0, 0, 1, 1);
        body.add (form_grid);

        spinner = new Gtk.Spinner ();
        body.add (spinner);

        status_label = new Gtk.Label ("");
        status_label.get_style_context ().add_class ("h4");
        status_label.halign = Gtk.Align.CENTER;
        status_label.valign = Gtk.Align.CENTER;
        status_label.justify = Gtk.Justification.CENTER;
        status_label.set_max_width_chars (50);
        status_label.set_line_wrap (true);
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
            submit_button_clicked (get_new_nickname ());
        });

        submit_button.sensitive = get_new_nickname () != current_nickname;
        entry.changed.connect (() => {
            var new_nickname = get_new_nickname ();
            submit_button.sensitive = (new_nickname != current_nickname) && new_nickname.length > 0;
        });

        add_action_widget (cancel_button, 0);
        add_action_widget (submit_button, 1);
    }

    private string get_new_nickname () {
        return entry.text.chomp ().chug ();
    }

    public void dismiss () {
        spinner.stop ();
        close ();
    }

    public void display_error (string message) {
        spinner.stop ();
        status_label.label = message;
    }

    public signal void submit_button_clicked (string new_nickname);

}
