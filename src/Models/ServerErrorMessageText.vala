public class Iridium.Models.ServerErrorMessageText : Iridium.Models.RichText {

    public ServerErrorMessageText (Iridium.Services.Message message) {
        Object (
            message: message
        );
    }

    public override void display (Gtk.TextBuffer buffer) {
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);

        // Add the message text
        var text = string.nfill (Iridium.Views.ChatView.USERNAME_SPACING, ' ');
        text += message.message;
        buffer.insert_text (ref iter, text, text.length);

        // Format the message
        Gtk.TextIter start = iter;
        start.backward_chars (text.length);
        buffer.apply_tag_by_name ("error", start, iter);
        buffer.insert (ref iter, "\n", 1);

        /* // Display username
        var username = message.username;
        if (username.length > Iridium.Views.ChatView.USERNAME_SPACING) {
            username = username.substring (0, Iridium.Views.ChatView.USERNAME_SPACING - 3);
            username += "...";
        } else {
            username += string.nfill (Iridium.Views.ChatView.USERNAME_SPACING - username.length, ' ');
        }
        buffer.insert_text (ref iter, username, username.length);

        // Format the username
        Gtk.TextIter username_start = iter;
        username_start.backward_chars (username.length);
        buffer.apply_tag_by_name (get_tag_name (), username_start, iter);
        buffer.insert_text (ref iter, message.message, message.message.length);
        buffer.insert (ref iter, "\n", 1); */
    }

}
