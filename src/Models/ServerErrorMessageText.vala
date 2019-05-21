public class Iridium.Models.ServerErrorMessageText : Iridium.Models.RichText {

    public ServerErrorMessageText (Iridium.Services.Message message) {
        Object (
            message: message
        );
    }

    public override void display (Gtk.TextBuffer buffer) {
        Gtk.TextIter iter;
        buffer.get_end_iter (out iter);
        buffer.insert_text (ref iter, message.message, message.message.length);

        // Format the message
        Gtk.TextIter start = iter;
        start.backward_chars (message.message.length);
        buffer.apply_tag_by_name ("error", start, iter);
        buffer.insert (ref iter, "\n", 1);
    }

}
