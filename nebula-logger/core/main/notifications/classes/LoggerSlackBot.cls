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

    public System.HttpResponse chatPostMessage(SlackMessage slackMessage) {
        // TODO add check for transaction's callout limits, and re-queue if needed
        System.HttpRequest httpRequest = this.sendSlackHttpRequest('/api/chat.postMessage', slackMessage);
        return new System.Http().send(HttpRequest);
    }

    private System.HttpRequest sendSlackHttpRequest(String endpoint, SlackMessage slackMessage) {
        // TODO figure out exact steps/metadata needed to setup named credentials
        // https://unofficialsf.com/authorizing-salesforce-access-to-slack/
        System.HttpRequest request = new System.HttpRequest();
        request.setEndpoint(slackMessage.namedCredentialDeveloperName + endpoint);
        request.setBody(JSON.serializePretty(slackMessage));
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        return request;
    }

    /* Block kit DTOs */
    /* https://api.slack.com/reference/block-kit/blocks */
    /* https://api.slack.com/methods/chat.postMessage */
    public class SlackMessage {
        public List<SlackBlock> blocks;
        public String channel;
        public String icon_emoji;
        public String icon_url;

        // Internal-use only, not used by Slack
        public transient String namedCredentialDeveloperName;
    }

    public class SlackBlock {
        public SlackBlockAccessory accessory;
        public List<SlackBlockAction> elements;
        public List<SlackBlockField> fields;
        public SlackBlockField text;
        public String type;
    }

    public class SlackBlockAccessory {
        public String alt_text;
        public String image_url;
        public SlackBlockField text;
        public String type;
    }

    public class SlackBlockAction {
        public String style;
        public SlackBlockField text;
        public String type;
        public String value;
    }

    public class SlackBlockField {
        public Boolean emoji;
        public String text;
        public String type;
    }
}
