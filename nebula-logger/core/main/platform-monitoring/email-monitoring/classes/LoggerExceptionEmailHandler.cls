global with sharing class LoggerExceptionEmailHandler implements Messaging.InboundEmailHandler {
    // https://github.com/nathanKramer/sf-exception-emails/
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail mail, Messaging.InboundEnvelope envelope) {
        String todo = mail.plainTextBody;

        Logger.error('Got an unhandled exception via email: ' + mail.plainTextBody);
        Logger.saveLog();

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        // TODO determine what needs to be done to the result before returning it
        return result;
    }
}
