public class LoggerAlertService_gpt {
  // Static variable to hold the singleton instance
  private static LoggerAlertService_gpt instance;
  private static Integer calloutTimeUsed = 0;

  // Private constructor to prevent direct instantiation
  private LoggerAlertService_gpt() {
    // Initialization logic, if necessary
  }

  // Static method to get the singleton instance of LoggerAlertService_gpt
  public static LoggerAlertService_gpt getInstance() {
    if (instance == null) {
      instance = new LoggerAlertService_gpt();
    }
    return instance;
  }

  // Method to process records and execute alert actions by passing them to the ActionsProcessor
  public void process(List<SObject> records) {
    if (records.isEmpty()) {
      System.debug('No records to process.');
      return;
    }

    List<LoggerAlertMatch__c> alertMatches = new List<LoggerAlertMatch__c>();
    List<ActionDispatcher> dispatchers = new List<ActionDispatcher>();
    List<LoggerAlert__c> todoAlertsVariable = null; // TODO!!!!
    for (LoggerAlert__c alert : todoAlertsVariable) {
      List<SObject> filteredRecords = this.getFilteredRecords(alert, records);

      if (filteredRecords.isEmpty()) {
        continue;
      }

      if (alert.IsMatchingThresholdEnabled__c) {
        // TODO add records to alertMatches
        alertMatches.addAll(this.generateAlertMatches(alert, filteredRecords));
      }

      for (LoggerAlertAction__c action : alert.LoggerAlertActions__r) {
        ActionDispatcher dispatcher = createActionDispatcher(action, filteredRecords);
        if (dispatcher != null) {
          dispatchers.add(dispatcher);
        }
      }
    }

    LoggerDataStore.getDatabase().insertRecords(alertMatches);

    if (dispatchers.isEmpty() == false) {
      System.debug('Passing dispatchers to the ActionsProcessor.');
      System.enqueueJob(new ActionsProcessor(dispatchers));
    }
  }

  private List<SObject> getFilteredRecords(LoggerAlert__c alert, List<SObject> records) {
    FormulaEval.FormulaInstance formulaEvaluator = System.Formula.builder()
      .withFormula(alert.SourceSObjectFilter__c)
      .withReturnType(FormulaEval.FormulaReturnType.Boolean)
      .withType(records.getSObjectType())
      .build();

    List<SObject> filteredRecords = new List<SObject>();
    for (SObject inputRecord : records) {
      Boolean matchesFilter = (Boolean) formulaEvaluator.evaluate(inputRecord);
      if (matchesFilter) {
        filteredRecords.add(inputRecord);
      }
    }

    return filteredRecords;
  }

  private List<LoggerAlertMatch__c> generateAlertMatches(LoggerAlert__c alert, List<SObject> records) {
    List<LoggerAlertMatch__c> alertMatches = new List<LoggerAlertMatch__c>();

    for (SObject record : records) {
      Log__c log = record.getSObjectType() == Log__c.SObjectType ? (Log__c) record : null;
      LogEntry__c logEntry = record.getSObjectType() == LogEntry__c.SObjectType ? (LogEntry__c) record : null;
      LogEntryEvent__e logEntryEvent = record.getSObjectType() == LogEntryEvent__e.SObjectType ? (LogEntryEvent__e) record : null;
      LogEntryTag__c logEntryTag = record.getSObjectType() == LogEntryTag__c.SObjectType ? (LogEntryTag__c) record : null;

      LoggerAlertMatch__c alertMatch = new LoggerAlertMatch__c(
        Log__c = log?.Id,
        LogEntry__c = logEntry?.Id,
        LogEntryEventUuid__c = logEntryEvent?.EventUuid,
        LogEntryTag__c = logEntryTag?.Id,
        LoggerAlert__c = alert.Id
      );
      alertMatches.add(alertMatch);
    }

    return alertMatches;
  }

  // Factory method to create the appropriate action dispatcher for Callout
  private ActionDispatcher createActionDispatcher(LoggerAlertAction__c action, List<SObject> filteredRecords) {
    switch on action.Type__c {
      when 'Email' {
        return new EmailActionDispatcher(action, filteredRecords);
      }
      when 'Slack' {
        return new SlackActionDispatcher(action, filteredRecords);
      }
      when else {
        System.debug('Unknown action type \'' + action.Type__c + '\' on alert action ' + action.Id);
        return null;
      }
    }
  }

  // Private Queueable class to handle executing or re-enqueuing the actions
  private class ActionsProcessor implements System.Queueable {
    private final List<ActionDispatcher> dispatchers;

    // Constructor
    public ActionsProcessor(List<ActionDispatcher> dispatchers) {
      this.dispatchers = dispatchers;
    }

    public void execute(System.QueueableContext context) {
      System.debug('Running dispatchers in ActionsProcessor.');
      List<ActionDispatcher> remainingDispatchers = new List<ActionDispatcher>();

      List<SObject> filteredRecords = new List<SObject>();
      for (ActionDispatcher dispatcher : dispatchers) {
        if (hasSufficientLimits(dispatcher.getExpectedLimitsUsage())) {
          dispatcher.dispatch();
        } else {
          System.debug('Insufficient limits for dispatcher, adding to remainingDispatchers.');
          remainingDispatchers.add(dispatcher);
        }
      }

      // If there are remaining dispatchers, enqueue the job for later execution
      if (!remainingDispatchers.isEmpty()) {
        System.debug('Enqueuing remaining actions due to insufficient limits.');
        // TODO consider use the same instance, but processed dispatchers would need to be remove from the list
        System.enqueueJob(new ActionsProcessor(remainingDispatchers));
      }
    }

    // Method to check if there are enough remaining limits
    private Boolean hasSufficientLimits(TransactionLimitsUsage usage) {
      Integer remainingCallouts = System.Limits.getLimitCallouts() - System.Limits.getCallouts();
      Integer remainingDmlStatements = System.Limits.getLimitDmlStatements() - System.Limits.getDmlStatements();
      Integer remainingEmails = System.Limits.getLimitEmailInvocations() - System.Limits.getEmailInvocations();
      Integer remainingQueries = System.Limits.getLimitQueries() - System.Limits.getQueries();
      Integer remainingCalloutTime = 120 - calloutTimeUsed;

      System.debug('Remaining callouts: ' + remainingCallouts);
      System.debug('Remaining DML statements: ' + remainingDmlStatements);
      System.debug('Remaining emails: ' + remainingEmails);
      System.debug('Remaining queries: ' + remainingQueries);
      System.debug('Remaining callout time: ' + remainingCalloutTime + ' seconds');

      return remainingCallouts >= usage.expectedCallouts &&
        remainingDmlStatements >= usage.expectedDmlStatements &&
        remainingEmails >= usage.expectedEmails &&
        remainingQueries >= usage.expectedQueries &&
        remainingCalloutTime >= usage.expectedCalloutTime;
    }
  }

  // ActionDispatcher class that contains common logic for all dispatchers
  private abstract class ActionDispatcher {
    protected final LoggerAlertAction__c action;
    protected final List<SObject> filteredRecords;

    public ActionDispatcher(LoggerAlertAction__c action, List<SObject> filteredRecords) {
      this.action = action;
      this.filteredRecords = filteredRecords;
    }

    public abstract void dispatch();

    public abstract TransactionLimitsUsage getExpectedLimitsUsage();

    protected void authenticate() {
      System.debug('Authenticating...');
    }

    protected Boolean checkCalloutLimits() {
      Integer remainingCallouts = System.Limits.getLimitCallouts() - System.Limits.getCallouts();
      if (remainingCallouts < 5) {
        System.debug('Re-enqueuing due to nearing callout limit.');
        return true;
      }
      return false;
    }

    protected String getConfigValue(String key) {
      System.debug('Fetching config value for: ' + key);
      return 'ConfigValue';
    }
  }

  // Class for CalloutActionDispatcher with Rate Limiting and Throttling
  private abstract class CalloutActionDispatcher extends ActionDispatcher {
    private final Integer RATE_LIMIT = 10; // Max number of callouts allowed in a window
    private final Integer TIME_WINDOW_SECONDS = 60; // Time window for rate limiting (e.g., 60 seconds)
    private final Integer THROTTLE_DELAY_MS = 2000; // Delay between callouts (e.g., 2 seconds)

    private Datetime lastCalloutTime;
    private Integer calloutsInCurrentWindow = 0;

    public CalloutActionDispatcher(LoggerAlertAction__c action, List<SObject> filteredRecords) {
      super(action, filteredRecords);
    }

    // TODO decide if this should have a default implementation, or if subclasses should fully handle implementation
    public virtual override void dispatch() {
      if (!canMakeCallout()) {
        System.debug('Rate limit exceeded, queuing the job with delay.');
        enqueueJobWithDelay(); // Throttling the callout
        return;
      }

      try {
        authenticate();
        String serviceUrl = getConfigValue('ServiceCalloutURL');
        sendServiceCallout(serviceUrl);
        trackCallout();
      } catch (Exception e) {
        System.debug('Callout failed: ' + e.getMessage());
      }
    }

    public abstract List<System.HttpRequest> getHttpRequests();

    // Method to determine if a callout can be made (rate limiting logic)
    private Boolean canMakeCallout() {
      Datetime now = Datetime.now();

      if (lastCalloutTime == null || now.getTime() - lastCalloutTime.getTime() > TIME_WINDOW_SECONDS * 1000) {
        lastCalloutTime = now;
        calloutsInCurrentWindow = 0;
      }

      return calloutsInCurrentWindow < RATE_LIMIT;
    }

    // Method to track callouts within the current time window
    private void trackCallout() {
      calloutsInCurrentWindow++;
      lastCalloutTime = Datetime.now();
    }

    // Throttling: Queue the job and delay the next callout
    private void enqueueJobWithDelay() {
      System.enqueueJob(new DelayedCalloutJob(THROTTLE_DELAY_MS));
    }

    private void sendServiceCallout(String url) {
      Long startTime = Datetime.now().getTime();
      System.Http http = new System.Http();
      System.HttpRequest request = new System.HttpRequest();
      request.setEndpoint(url);
      request.setMethod('GET');

      System.HttpResponse response = http.send(request);
      Long endTime = Datetime.now().getTime();
      // TODO verify if this needs to be multipled by 1,000 milliseconds
      calloutTimeUsed += (endTime - startTime).intValue();
      System.debug('Callout successful: ' + response.getBody());
    }
  }

  // Inner class for EmailActionDispatcher
  private class EmailActionDispatcher extends ActionDispatcher {
    public EmailActionDispatcher(LoggerAlertAction__c action, List<SObject> filteredRecords) {
      super(action, filteredRecords);
    }

    public override void dispatch() {
      System.debug('Executing Email alert...');
      if (checkCalloutLimits()) {
        return;
      }

      authenticate();
      String recipient = getConfigValue('EmailRecipient');
      sendEmail(recipient);
    }

    private void sendEmail(String recipient) {
      System.debug('Sending email to: ' + recipient);
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage().setExpectedCallouts(0).setExpectedDmlStatements(0).setExpectedEmails(1); // Assuming 1 email is sent per execution
    }
  }

  /* Start of Slack classes */
  private class SlackActionDispatcher extends CalloutActionDispatcher {
    private final Integer requestTimeout = 10;

    public SlackActionDispatcher(LoggerAlertAction__c action, List<SObject> filteredRecords) {
      super(action, filteredRecords);
    }

    public override void dispatch() {
      System.debug('Executing Slack alert...');
      if (checkCalloutLimits()) {
        return;
      }

      authenticate();
      String channel = getConfigValue('SlackChannel');
      sendSlackMessage(channel);
    }

    public override List<System.HttpRequest> getHttpRequests() {
      // TODO requery the data
      // TODO create 1 request per match
      // TODO (dynamically?) use a field set for the current SObject Type
      List<System.HttpRequest> requests = new List<System.HttpRequest>();

      for (SObject record : this.filteredRecords) {
        SlackMessage slackMessage = new SlackMessage();
        String endpoint = this.action.CalloutNamedCredential__c;
        if (this.action.SlackConnectionType__c == 'Chat Post Message') {
          endpoint += this.action.CalloutNamedCredential__c + '/api/chat.postMessage' + this.action.SlackChannel__c;
        }

        // TODO figure out exact steps/metadata needed to setup named credentials
        // https://unofficialsf.com/authorizing-salesforce-access-to-slack/
        System.HttpRequest request = new System.HttpRequest();
        request.setBody(System.JSON.serializePretty(slackMessage));
        request.setEndpoint(slackMessage.namedCredentialDeveloperName + endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        request.setTimeout(this.requestTimeout);

        requests.add(request);
      }

      return requests;
    }

    private void sendSlackMessage(String channel) {
      System.debug('Sending message to Slack channel: ' + channel);
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage()
        .setExpectedCallouts(this.filteredRecords.size())
        .setExpectedCalloutTime(this.requestTimeout * this.filteredRecords.size())
        .setExpectedQueries(1)
        .setExpectedQueryRows(this.filteredRecords.size());
    }
  }

  // Examples:https://medium.com/trabe/build-and-post-messages-to-slack-using-javascript-and-the-slack-api-55c9b4f43ae7

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
  /* End of Slack classes */

  // TransactionLimitsUsage class with fluent API
  public class TransactionLimitsUsage {
    public Integer expectedCallouts = 0;
    public Integer expectedCalloutTime = 0; // Tracking expected callout time in seconds
    public Integer expectedDmlStatements = 0;
    public Integer expectedEmails = 0;
    public Integer expectedQueries = 0;
    public Integer expectedQueryRows = 0;
    public Integer expectedQueueableJobs = 0; // Tracking queueable jobs

    public TransactionLimitsUsage setExpectedCallouts(Integer callouts) {
      this.expectedCallouts = callouts;
      return this;
    }

    public TransactionLimitsUsage setExpectedCalloutTime(Integer calloutTime) {
      this.expectedCalloutTime = calloutTime;
      return this;
    }

    public TransactionLimitsUsage setExpectedDmlStatements(Integer dmlStatements) {
      this.expectedDmlStatements = dmlStatements;
      return this;
    }

    public TransactionLimitsUsage setExpectedEmails(Integer emails) {
      this.expectedEmails = emails;
      return this;
    }

    public TransactionLimitsUsage setExpectedQueries(Integer queries) {
      this.expectedQueries = queries;
      return this;
    }

    public TransactionLimitsUsage setExpectedQueryRows(Integer queryRows) {
      this.expectedQueryRows = queryRows;
      return this;
    }

    public TransactionLimitsUsage setExpectedQueueableJobs(Integer queueableJobs) {
      this.expectedQueueableJobs = queueableJobs;
      return this;
    }
  }

  // TODO remove this??
  // Queueable job to handle delayed callouts (throttling)
  private class DelayedCalloutJob implements System.Queueable, Database.AllowsCallouts {
    private Integer delayMs;

    public DelayedCalloutJob(Integer delayMs) {
      this.delayMs = delayMs;
    }

    public void execute(System.QueueableContext context) {
      System.debug('Throttling callout for ' + delayMs + ' milliseconds.');
      makeRateLimitedCallout();
    }

    private void makeRateLimitedCallout() {
      //   CalloutActionDispatcher.this.dispatch();
    }
  }
}
