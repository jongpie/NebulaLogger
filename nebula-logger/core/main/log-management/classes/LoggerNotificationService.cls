public with sharing class LoggerNotificationService {
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>{
        Schema.LogEntry__c.SObjectType => new List<Schema.SObjectField>{
            Schema.LogEntry__c.ExceptionStackTrace__c
        }
    };

    private static final Map<Schema.SObjectType, List<LoggerNotification__c>> SOBJECT_TYPE_TO_NOTIFICATIONS {
        get {
            if (SOBJECT_TYPE_TO_NOTIFICATIONS == null) {
                // TODO use a new method in LogManagementDataSelector to query & cache LoggerNotification__c records
                SOBJECT_TYPE_TO_NOTIFICATIONS = new Map<Schema.SObjectType, List<LoggerNotification__c>>();
            }
            return SOBJECT_TYPE_TO_NOTIFICATIONS;
        }
        set;
    }

    // TODO this will be a copy of Apex Rollup's RollupEvaluator class
    private Object evaluator;
    private LoggerEmailSender emailSender = new LoggerEmailSender();
    private LoggerSlackBot slackBot = new LoggerSlackBot();

    public LoggerNotificationService() {
    }

    public void sendNotifications(List<SObject> records) {
        if (SOBJECT_TYPE_TO_NOTIFICATIONS.containsKey(records.getSObjectType()) == false) {
            return;
        }

        // TODO enqueue a queueable, and within the queueable, handle re-enqueuing when limits are hit
        List<Messaging.SingleEmailMessage> emailNotifications = new List<Messaging.SingleEmailMessage>();
        // List<LoggerSlackBot.SlackNotification> slackNotifications = new List<LoggerSlackBot.SlackNotification>();
        for (LoggerNotification__c notification : SOBJECT_TYPE_TO_NOTIFICATIONS.get(records.getSObjectType())) {
            if (notification.IsEmailNotificationEnabled__c == false && notification.IsSlackNotificationEnabled__c == false) {
                continue;
            }
            List<SObject> matchingRecords = new LoggerEvaluator().getMatches(notification.SourceSObjectFilter__c, records);
            for (SObject record : matchingRecords) {
                if (notification.IsEmailNotificationEnabled__c) {
                    Messaging.SingleEmailMessage emailNotification = new Messaging.SingleEmailMessage();
                    if (notification.EmailAddressRecipient__c != null) {
                        emailNotification.setToAddresses(new List<String>{ notification.EmailAddressRecipient__c });
                        // emailNotification.setToAddresses(new List<String>{ notification.EmailAddressRecipient__c });
                    }
                    // TODO add support for a new User lookup on LoggerNotification__c
                    // emailNotification.setTargetObjectId(notification.EmailUserRecipient__c);

                    emailNotifications.add(emailNotification);
                }

                if (notification.IsSlackNotificationEnabled__c) {
                    LoggerSlackBot.SlackMessage slackMessage = this.buildSlackMessage(notification.SlackNamedCredential__c, notification.SlackChannel__c, record);
                    this.slackBot.chatPostMessage(slackMessage);
                }
            }

        }
        this.emailSender.sendEmail(emailNotifications);
    }

    private LoggerSlackBot.SlackMessage buildSlackMessage(String namedCredentialDeveloperName, String channel, SObject record) {//, Schema.FieldSet fieldSet) {
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
        for (Schema.SObjectField field : new List<Schema.SObjectField>()) {
            String recordValue = '```' + String.valueOf(record.get(field.getDescribe().getName())) + '```';

            LoggerSlackBot.SlackBlockField slackField = new LoggerSlackBot.SlackBlockField();
            slackField.type = 'mrkdwn';
            slackField.text = '*' + field.getDescribe().getLabel() + '*\n' + recordValue;
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
