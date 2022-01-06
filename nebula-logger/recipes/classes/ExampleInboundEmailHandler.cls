/**
 * @description Example inbound email handler.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ExampleInboundEmailHandler implements Messaging.InboundEmailHandler {
    @TestVisible
    private static String logEntryMessage = 'Testing logging from InboundEmailHandler';

    /**
     * @description Contains example logging logic for handling an incoming email.
     * @param email The incoming email.
     * @param env The incoming email envelope.
     * @return The inbound email result.
     */
    @SuppressWarnings('PMD.AvoidDebugStatements')
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try {
            String nullString = null;
            nullString.length();
        } catch (Exception apexException) {
            Logger.error(logEntryMessage, apexException);
        } finally {
            result.success = true;
            System.debug(LoggingLevel.DEBUG, 'Logger buffer size before save: ' + Logger.getBufferSize());
            Logger.saveLog();
            System.debug(LoggingLevel.DEBUG, 'Logger buffer size after save: ' + Logger.getBufferSize());
        }

        return result;
    }
}
