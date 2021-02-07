/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global inherited sharing virtual class LogMessage {
    private String formattedMessage;
    private String unformattedMessage;
    private List<Object> messageInputs;

    global LogMessage(String unformattedMessage, Object messageInput) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = new List<Object>{ messageInput };
    }

    global LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = new List<Object>{ messageInput1, messageInput2 };
    }

    global LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2, Object messageInput3) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = new List<Object>{ messageInput1, messageInput2, messageInput3 };
    }

    global LogMessage(String unformattedMessage, List<Object> messageInputs) {
        this.unformattedMessage = unformattedMessage;
        this.messageInputs = messageInputs;
    }

    global virtual String getMessage() {
        // Just in case getMessage() is called multiple times (first by the originating code, then by Logger)
        // ...cache the result (save CPU time from multiple calls) and discard the original parameters (reduce heap size)
        if (this.formattedMessage == null) {
            this.formattedMessage = String.format(this.unformattedMessage, this.messageInputs);

            this.unformattedMessage = null;
            this.messageInputs = null;
        }

        return this.formattedMessage;
    }
}
