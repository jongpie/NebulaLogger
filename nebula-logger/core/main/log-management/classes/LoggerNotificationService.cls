global without sharing class LoggerNotificationService {
    // Static variables
    private static LoggerNotificationService instance = new LoggerNotificationService();

    private static final List<LoggerNotification__c> NOTIFICATION_RULES {
        get {
            if (NOTIFICATION_RULES == null) {
                // TODO move query to LogManagementDataSelector
                NOTIFICATION_RULES = [SELECT Id, LogEntryFilter__c FROM LoggerNotification__c];
            }
            return NOTIFICATION_RULES;
        }
        set;
    }

    // Instance variables
    private LoggerEmailSender emailSender = new LoggerEmailSender();
    private LoggerSlackBot slackBot = new LoggerSlackBot();

    public enum NotificationType {
        // TODO revist picklist fields & code for supporting custom Apex classes
        CUSTOM,
        EMAIL,
        SLACK
    }

    global class FormulaEvalLogEntry {
        global LogEntry__c record;

        public FormulaEvalLogEntry(LogEntry__c logEntry) {
            this.record = logEntry;
        }
    }

    // Static methods
    public static LoggerNotificationService getInstance() {
        return instance;
    }

    public static void validateFilterFormula(String formula) {
        // This will automatically throw an exception (by the platform) if the formula isn't valid
        getBooleanFormulaInstance(formula);
    }

    private static FormulaEval.FormulaInstance getBooleanFormulaInstance(String formula) {
        return FormulaEval.FormulaBuilder.builder()
            .withFormula(formula)
            .withReturnType(FormulaEval.FormulaReturnType.BOOLEAN)
            .withType(FormulaEvalLogEntry.class)
            .build();
    }

    // Instance methods
    public void sendNotifications(List<LogEntry__c> logEntries) {
        for (LoggerNotification__c notificationRule : NOTIFICATION_RULES) {
            List<LogEntry__c> matchingLogEntries = this.getMatches(notificationRule.LogEntryFilter__c, logEntries);
            // TODO AHHHHH A SOQL QUERY IN A LOOP, BAD!
            List<LoggerNotificationRecipient__c> recipients = new List<LoggerNotificationRecipient__c>();
            for (LoggerNotificationRecipient__c recipient : recipients) {
                if (matchingLogEntries.isEmpty() == false) {
                    this.sendNotification(recipient, matchingLogEntries);
                }
            }
        }
    }

    // TODO make private?
    public List<LogEntry__c> getMatches(String formula, List<LogEntry__c> logEntries) {
        FormulaEval.FormulaInstance fx = FormulaEval.FormulaBuilder.builder()
            .withFormula(formula)
            .withReturnType(FormulaEval.FormulaReturnType.BOOLEAN)
            .withType(FormulaEvalLogEntry.class)
            .build();

        List<LogEntry__c> matchingLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : logEntries) {
            Boolean matchesFormulaCriteria = (Boolean) fx.evaluate(new FormulaEvalLogEntry(logEntry));
            if (matchesFormulaCriteria) {
                matchingLogEntries.add(logEntry);
            }
        }
        return matchingLogEntries;
    }

    private void sendNotification(LoggerNotificationRecipient__c recipient, List<LogEntry__c> matchingLogEntries) {
        // TODO
        switch on recipient.Type__c {
            when 'Email' {
                // TODO should this send 1 email for all log entries (instead of 1 email per 1 log entry)?
                List<Messaging.SingleEmailMessage> emailNotifications = new List<Messaging.SingleEmailMessage>();
                for (LogEntry__c logEntry : matchingLogEntries) {
                    Messaging.SingleEmailMessage emailNotification = this.buildEmailMessage();
                    if (recipient.EmailAddressRecipient__c != null) {
                        emailNotification.setToAddresses(new List<String>{ recipient.EmailAddressRecipient__c });
                    }
                    if (recipient.EmailUserRecipient__c != null) {
                        emailNotification.setTargetObjectId(recipient.EmailUserRecipient__c);
                    }

                    emailNotifications.add(emailNotification);
                }
                this.emailSender.sendEmails(emailNotifications);
            }
            when 'Slack' {
                for (LogEntry__c logEntry : matchingLogEntries) {
                    LoggerSlackBot.SlackMessage slackMessage = this.buildSlackMessage(recipient.SlackNamedCredential__c, recipient.SlackChannel__c, logEntry);
                    this.slackBot.chatPostMessage(slackMessage);
                }
            }
            when else {
                // ? throw an exception, problably?
            }
        }
    }

    // private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>{
    //     Schema.LogEntry__c.SObjectType => new List<Schema.SObjectField>{ Schema.LogEntry__c.ExceptionStackTrace__c }
    // };

    // private static final Map<Schema.SObjectType, List<LoggerNotification__c>> SOBJECT_TYPE_TO_NOTIFICATIONS {
    //     get {
    //         if (SOBJECT_TYPE_TO_NOTIFICATIONS == null) {
    //             // TODO use a new method in LogManagementDataSelector to query & cache LoggerNotification__c records
    //             SOBJECT_TYPE_TO_NOTIFICATIONS = new Map<Schema.SObjectType, List<LoggerNotification__c>>();
    //         }
    //         return SOBJECT_TYPE_TO_NOTIFICATIONS;
    //     }
    //     set;
    // }

    // private LoggerEvaluator evaluator = new LoggerEvaluator();
    // private LoggerEmailSender emailSender = new LoggerEmailSender();
    // private LoggerSlackBot slackBot = new LoggerSlackBot();

    // public void sendNotifications(List<SObject> records) {
    //     if (SOBJECT_TYPE_TO_NOTIFICATIONS.containsKey(records.getSObjectType()) == false) {
    //         return;
    //     }

    //     // TODO enqueue a queueable, and within the queueable, handle re-enqueuing when limits are hit
    //     List<Messaging.SingleEmailMessage> emailNotifications = new List<Messaging.SingleEmailMessage>();
    //     // List<LoggerSlackBot.SlackNotification> slackNotifications = new List<LoggerSlackBot.SlackNotification>();
    //     for (LoggerNotification__c notification : SOBJECT_TYPE_TO_NOTIFICATIONS.get(records.getSObjectType())) {
    //         if (notification.IsEmailNotificationEnabled__c == false && notification.IsSlackNotificationEnabled__c == false) {
    //             continue;
    //         }
    //         List<SObject> matchingRecords = this.evaluator.getMatches(notification.SourceSObjectFilter__c, records);
    //         for (SObject record : matchingRecords) {
    //             if (notification.IsEmailNotificationEnabled__c) {
    //                 Messaging.SingleEmailMessage emailNotification = new Messaging.SingleEmailMessage();
    //                 if (notification.EmailAddressRecipient__c != null) {
    //                     emailNotification.setToAddresses(new List<String>{ notification.EmailAddressRecipient__c });
    //                     // emailNotification.setToAddresses(new List<String>{ notification.EmailAddressRecipient__c });
    //                 }
    //                 // TODO add support for a new User lookup on LoggerNotification__c
    //                 // emailNotification.setTargetObjectId(notification.EmailUserRecipient__c);

    //                 // TODO switch to private method this.buildEmail();
    //                 emailNotifications.add(emailNotification);
    //             }

    //             if (notification.IsSlackNotificationEnabled__c) {
    //                 LoggerSlackBot.SlackMessage slackMessage = this.buildSlackMessage(
    //                     notification.SlackNamedCredential__c,
    //                     notification.SlackChannel__c,
    //                     record
    //                 );
    //                 this.slackBot.chatPostMessage(slackMessage);
    //             }
    //         }
    //     }
    //     // this.emailSender.sendEmail(emailNotifications);
    // }

    private Messaging.SingleEmailMessage buildEmailMessage() {
        Messaging.SingleEmailMessage emailNotification = new Messaging.SingleEmailMessage();

        return emailNotification;
    }

    private LoggerSlackBot.SlackMessage buildSlackMessage(String namedCredentialDeveloperName, String channel, SObject record) {
        //, Schema.FieldSet fieldSet) {
        LoggerSlackBot.SlackMessage slackMessage = new LoggerSlackBot.SlackMessage();
        slackMessage.namedCredentialDeveloperName = namedCredentialDeveloperName;
        slackMessage.channel = channel;
        slackMessage.blocks = new List<LoggerSlackBot.SlackBlock>();

        LoggerSlackBot.SlackBlock headerSectionBlock = new LoggerSlackBot.SlackBlock();
        headerSectionBlock.type = 'section';
        headerSectionBlock.text = new LoggerSlackBot.SlackBlockField();
        headerSectionBlock.text.text = 'You have a new request:\n*<fakeLink.toEmployeeProfile.com|Fred Enriquez - New device request>*';
        headerSectionBlock.text.type = 'mrkdwn';
        slackMessage.blocks.add(headerSectionBlock);

        LoggerSlackBot.SlackBlock dividerBlock = new LoggerSlackBot.SlackBlock();
        dividerBlock.type = 'divider';
        slackMessage.blocks.add(dividerBlock);

        LoggerSlackBot.SlackBlock fieldsSectionBlock = new LoggerSlackBot.SlackBlock();
        fieldsSectionBlock.type = 'section';
        fieldsSectionBlock.fields = new List<LoggerSlackBot.SlackBlockField>();
        for (Schema.SObjectField recordField : new List<Schema.SObjectField>()) {
            String recordFieldValue = '```' + String.valueOf(record.get(recordField.getDescribe().getName())) + '```';

            LoggerSlackBot.SlackBlockField slackField = new LoggerSlackBot.SlackBlockField();
            slackField.type = 'mrkdwn';
            slackField.text = '*' + recordField.getDescribe().getLabel() + '*\n' + recordFieldValue;
            fieldsSectionBlock.fields.add(slackField);
        }
        slackMessage.blocks.add(fieldsSectionBlock);

        LoggerSlackBot.SlackBlockAction viewAction = new LoggerSlackBot.SlackBlockAction();
        viewAction.type = 'button';
        viewAction.style = 'primary';
        viewAction.text = new LoggerSlackBot.SlackBlockField();
        viewAction.text.text = 'View';
        LoggerSlackBot.SlackBlock actionsBlock = new LoggerSlackBot.SlackBlock();
        actionsBlock.type = 'actions';
        actionsBlock.elements = new List<LoggerSlackBot.SlackBlockAction>{ viewAction };
        slackMessage.blocks.add(actionsBlock);

        return slackMessage;
    }
}
