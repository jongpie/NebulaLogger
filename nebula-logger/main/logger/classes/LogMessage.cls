/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing virtual class LogMessage {

    private String message;
    private List<Object> messageInputs;

    public LogMessage(String message) {
        this.message = message;
    }

    public LogMessage(String unformattedMessage, Object messageInput) {
        this.message       = unformattedMessage;
        this.messageInputs = new List<Object>{messageInput};
    }

    public LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2) {
        this.message       = unformattedMessage;
        this.messageInputs = new List<Object>{messageInput1, messageInput2};
    }

    public LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2, Object messageInput3) {
        this.message       = unformattedMessage;
        this.messageInputs = new List<Object>{messageInput1, messageInput2, messageInput3};
    }

    public LogMessage(String unformattedMessage, List<Object> messageInputs) {
        this.message       = unformattedMessage;
        this.messageInputs = messageInputs;
    }

    public virtual String getMessage() {
        if(this.messageInputs == null) return this.message;

        return String.format(this.message, this.messageInputs);
    }

}