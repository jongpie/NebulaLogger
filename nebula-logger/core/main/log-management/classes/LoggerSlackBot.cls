//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Class used send Slack notifications for Nebula Logger data
 */
public without sharing class LoggerSlackBot {
    // TODO scenarios to (try to) support:
    //      1. Sending Slack notifications using a webhook
    //      2. Sending Slack notifications using a named credential & Slack app
    // TODO implementation goals:
    //      1. If possible, don't use a (datetime) field for tracking if Slack notification was sent (something that the plugin does)
    //          - This might be needed to avoid sending duplicate Slack notifications across different EventBus transactions (for the same log transaction ID)
    //      2. Assume that multiple channels are supported, but only 1 workspace per org
    //      3. Multiple Salesforce orgs should be able to send notifications to the same Slack workspace (if desired)
    //      4. Assume the user has already created a Slack app (and the user's team has already been added to the Slack app)
    //      5. Assume the user has already created a Slack channel (and the user has already joined the Slack channel)
    //      6. Have a retry mechanism, but for each notification, have a max number of retry attempts
    //      7. Concepts & implementations should align with the Apex Slack SDK (https://developer.salesforce.com/docs/platform/salesforce-slack-sdk/overview)
    //         It's won't be used until it's GA (currently still in beta), but using it is a long-term goal

    private final String namedCredentialDeveloperName;

    public void sendNotification(String namedCredentialDeveloperName, List<Log__c> logs) {
        // TODO each record will have to be a separate callout (I think?), so there's
        // probably not a way to truly bulkify this method

        // TODO add checks for callout limits in the current transaction & re-enqueue a queueable when needed
    }

    private void sendNotification(String namedCredentialDeveloperName, Log__c log) {
        // if (
        //     LoggerParameter.SEND_SLACK_NOTIFICATIONS == false ||
        //     String.isBlank(LoggerParameter.SLACK_NAMED_CREDENTIAL_DEVELOPER_NAME) == true ||
        //     String.isBlank(log.SlackNotificationChannel__c) == true
        // ) {
        if (LoggerParameter.SEND_SLACK_NOTIFICATIONS == false) {
            return;
        }

        SlackNotification notification = this.createSlackNotification(log);
        this.sendSlackHttpRequest(namedCredentialDeveloperName, notification);
    }

    private SlackNotification createSlackNotification(Log__c log) {
        // TODO
        return null;
    }

    private System.HttpRequest sendSlackHttpRequest(String namedCredentialDeveloperName, SlackNotification notification) {
        System.HttpRequest request = new System.HttpRequest();
        // request.setEndpoint(LoggerParameter.SLACK_NAMED_CREDENTIAL_DEVELOPER_NAME);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
            Logger.finest('Created Slack HTTP Request').setHttpRequestDetails(request);
        }
        return request;
    }

    private class SlackNotification {
        public List<SlackFormattedMessage> attachments;
        public String text;
    }

    private class SlackFormattedMessage {
        public String author_name;
        public String author_link;
        public String color;
        public List<SlackField> fields;
        public String footer;
        public String pretext;
        public String text;
        public String title;
        public String title_link;
    }

    @TestVisible
    private class SlackField {
        public Boolean isShort;
        public String fieldPath;
        public String title;
        public String value;
    }
}
