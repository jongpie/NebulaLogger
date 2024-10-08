//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Service class used for orchestrating & sending notifications for logging data,
 *              based on org-specific rules configured in `LoggerAlert__c`
 */
public class LoggerAlertService {
  private static final Integer MAX_ACTION_RETRY_COUNT = 3;

  // Static variable to hold the singleton instance
  private static LoggerAlertService instance;
  private static Integer calloutTimeUsed = 0;

  // Private constructor to prevent direct instantiation
  private LoggerAlertService() {
    // Initialization logic, if necessary
  }

  // Static method to get the singleton instance of LoggerAlertService
  public static LoggerAlertService getInstance() {
    if (instance == null) {
      instance = new LoggerAlertService();
    }
    return instance;
  }

  // Method to process records and execute alert actions by passing them to the ActionsProcessor
  public void process(List<SObject> records) {
    // TODO add a new LoggerParameter__mdt record to globally enable/disable alerts
    // if (LoggerParameter.ENABLE_ALERTING == false) {
    //   return;
    // }

    if (records.isEmpty()) {
      System.debug('No records to process.');
      return;
    }

    if (records.getSObjectType() != LogEntry__c.SObjectType) {
      System.debug('⛔⚠️TEMP! Only testing with LogEntry__c for now');
      return;
    }

    /*
      TODO things to add
        1. If 1 or more Slack actions are setup, combine the lists in SlackFields__c together use to requery records
        2. Decide if email alerts will be supported for all Source SObject Types, and if so, can fields be customized (like Slack)?
        3. If 1 or more OTel actions are setup, query all fields on Log__c, LogEntry__c, LogEntryTag__c, LoggerTag__c, and LoggerScenario__c
        4. Based on IsLogRetentionOverrideEnabled__c, update the  field Log__c.LogRetentionDate__c
    */

    List<LoggerAlertMatch__c> alertMatches = new List<LoggerAlertMatch__c>();
    List<ActionDispatcher> dispatchers = new List<ActionDispatcher>();
    // List<LoggerAlert__c> todoAlertsVariable = null; // TODO!!!!
    List<LoggerAlert__c> todoAlertsVariable = [
      SELECT
        Id,
        Comments__c,
        IsMatchingThresholdEnabled__c,
        MatchingCountThreshold__c,
        MatchingThresholdRecordCount__c,
        MatchingThresholdSummary__c,
        MatchingThresholdTimePeriodIncrement__c,
        MatchingThresholdTimePeriodUnit__c,
        MatchingType__c,
        NumberOfDaysToRetainLogs__c,
        OriginOrganizationId__c,
        SourceSObjectFilter__c,
        SourceSObjectType__c,
        TotalMatches__c,
        Type__c,
        (
          SELECT
            Id,
            ActionSummary__c,
            CalloutNamedCredential__c,
            EmailAddressRecipient__c,
            EmailRecipientType__c,
            EmailUserRecipient__c,
            LoggerAlert__c,
            Name,
            OpenTelemetryProvider__c,
            SlackChannel__c,
            SlackConnectionType__c,
            SlackFields__c,
            SourceSObjectType__c,
            Type__c
          FROM LoggerAlertActions__r
          WHERE IsEnabled__c = TRUE
        )
      FROM LoggerAlert__c
      WHERE IsEnabled__c = TRUE AND IsOriginOrganizationIdValid__c = TRUE
    ];
    for (LoggerAlert__c alert : todoAlertsVariable) {
      List<SObject> matchingRecords = this.getMatchingRecords(alert, records);

      if (matchingRecords.isEmpty()) {
        continue;
      }

      if (alert.IsMatchingThresholdEnabled__c) {
        // TODO add records to alertMatches
        alertMatches.addAll(this.generateLoggerAlertMatchRecords(alert, matchingRecords));
      }

      for (LoggerAlertAction__c action : alert.LoggerAlertActions__r) {
        ActionDispatcher dispatcher = createActionDispatcher(action, matchingRecords);
        if (dispatcher != null) {
          dispatchers.add(dispatcher);
        }
      }
    }

    LoggerDataStore.getDatabase().insertRecords(alertMatches);

    if (dispatchers.isEmpty() == false) {
      System.debug('Passing dispatchers to the ActionsProcessor.');
      // TODO make this run sync & self re-enqueue so that some sync limits (like emails) can be processed
      new ActionsProcessor(dispatchers).execute();
      // System.enqueueJob(new ActionsProcessor(dispatchers));
    }
  }

  private List<SObject> getMatchingRecords(LoggerAlert__c alert, List<SObject> records) {
    FormulaEval.FormulaInstance formulaEvaluator = System.Formula.builder()
      .withFormula(alert.SourceSObjectFilter__c)
      .withReturnType(FormulaEval.FormulaReturnType.Boolean)
      .withType(records.getSObjectType())
      .build();

    List<SObject> matchingRecords = new List<SObject>();
    for (SObject inputRecord : records) {
      Boolean matchesFilter = (Boolean) formulaEvaluator.evaluate(inputRecord);
      if (matchesFilter) {
        matchingRecords.add(inputRecord);
      }
    }

    return matchingRecords;
  }

  private List<LoggerAlertMatch__c> generateLoggerAlertMatchRecords(LoggerAlert__c alert, List<SObject> records) {
    List<LoggerAlertMatch__c> alertMatches = new List<LoggerAlertMatch__c>();

    for (SObject record : records) {
      Schema.SObjectType recordSObjectType = record.getSObjectType();

      Log__c log = recordSObjectType == Log__c.SObjectType ? (Log__c) record : null;
      LogEntry__c logEntry = recordSObjectType == LogEntry__c.SObjectType ? (LogEntry__c) record : null;
      LogEntryEvent__e logEntryEvent = recordSObjectType == LogEntryEvent__e.SObjectType ? (LogEntryEvent__e) record : null;
      LogEntryTag__c logEntryTag = recordSObjectType == LogEntryTag__c.SObjectType ? (LogEntryTag__c) record : null;

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
  private ActionDispatcher createActionDispatcher(LoggerAlertAction__c action, List<SObject> matchingRecords) {
    switch on action.Type__c {
      when 'Email' {
        return new EmailActionDispatcher(action, matchingRecords);
      }
      when 'Slack' {
        return new SlackActionDispatcher(action, matchingRecords);
      }
      when else {
        System.debug('Unknown action type \'' + action.Type__c + '\' on alert action ' + action.Id);
        return null;
      }
    }
  }

  // Private Queueable class to handle executing or re-enqueuing the actions
  private class ActionsProcessor implements Database.AllowsCallouts, System.Queueable {
    private final List<ActionDispatcher> dispatchers;

    // Constructor
    public ActionsProcessor(List<ActionDispatcher> dispatchers) {
      this.dispatchers = dispatchers;
    }

    public void execute(System.QueueableContext context) {
      this.execute();
    }

    public void execute() {
      System.debug('Running ' + dispatchers.size() + ' dispatchers in ActionsProcessor.');
      List<ActionDispatcher> remainingDispatchers = new List<ActionDispatcher>();

      List<SObject> matchingRecords = new List<SObject>();
      for (ActionDispatcher dispatcher : dispatchers) {
        System.debug('Processing dispatcher for action ' + dispatcher.action.Name + '\n\n' + System.JSON.serializePretty(dispatcher.action));
        if (dispatcher.hasPendingWork() && this.hasSufficientLimits(dispatcher.getExpectedLimitsUsage())) {
          System.debug('Running action ' + dispatcher.action.Name);
          dispatcher.incrementAttempts();
          dispatcher.dispatch();
        }

        System.debug('>>> dispatcher.hasPendingWork(): ' + dispatcher.hasPendingWork());
        System.debug('>>> dispatcher.getAttempts(): ' + dispatcher.getAttempts());
        if (dispatcher.hasPendingWork() && dispatcher.getAttempts() < MAX_ACTION_RETRY_COUNT) {
          System.debug('Re-enqueuing action ' + dispatcher.action.Name);
          remainingDispatchers.add(dispatcher);
        }
      }

      // If there are remaining dispatchers, enqueue the job for later execution
      if (remainingDispatchers.isEmpty() == false) {
        System.debug('Enqueuing remaining actions due to insufficient limits.');
        // TODO consider use the same instance, but processed dispatchers would need to be remove from the list
        LoggerDataStore.getJobQueue().enqueueJob(new ActionsProcessor(remainingDispatchers));
      }
    }

    // Method to check if there are enough remaining limits
    private Boolean hasSufficientLimits(TransactionLimitsUsage usage) {
      Integer remainingCallouts = Trigger.isExecuting ? 0 : System.Limits.getLimitCallouts() - System.Limits.getCallouts();
      Integer remainingDmlStatements = System.Limits.getLimitDmlStatements() - System.Limits.getDmlStatements();
      Integer remainingEmails = System.Limits.getLimitEmailInvocations() - System.Limits.getEmailInvocations();
      Integer remainingQueries = System.Limits.getLimitQueries() - System.Limits.getQueries();
      Integer remainingCalloutTime = 120 - calloutTimeUsed;

      System.debug('Remaining callouts: ' + remainingCallouts);
      System.debug('Remaining DML statements: ' + remainingDmlStatements);
      System.debug('Remaining emails: ' + remainingEmails);
      System.debug('Remaining queries: ' + remainingQueries);
      System.debug('Remaining callout time: ' + remainingCalloutTime + ' seconds');

      System.debug('>>>> remainingCallouts >= usage.expectedCallouts: ' + (remainingCallouts >= usage.expectedCallouts));
      System.debug('>>>> remainingDmlStatements >= usage.expectedDmlStatements: ' + (remainingDmlStatements >= usage.expectedDmlStatements));
      System.debug('>>>> remainingEmails >= usage.expectedEmails: ' + (remainingEmails >= usage.expectedEmails));
      System.debug('>>>> remainingQueries >= usage.expectedQueries: ' + (remainingQueries >= usage.expectedQueries));
      System.debug('>>>> remainingCalloutTime >= usage.expectedCalloutTime: ' + (remainingCalloutTime >= usage.expectedCalloutTime));
      Boolean hasSufficientLimits =
        remainingCallouts >= usage.expectedCallouts &&
        remainingDmlStatements >= usage.expectedDmlStatements &&
        remainingEmails >= usage.expectedEmails &&
        // remainingQueries >= usage.expectedQueries &&
        // remainingCalloutTime >= usage.expectedCalloutTime;
        remainingQueries >= usage.expectedQueries;

      System.debug('>>>> hasSufficientLimits: ' + hasSufficientLimits);
      return hasSufficientLimits;
    }
  }

  // ActionDispatcher class that contains common logic for all dispatchers
  private abstract class ActionDispatcher {
    protected final LoggerAlertAction__c action;
    protected Boolean hasPendingWork = true;
    protected final List<SObject> matchingRecords;

    private Integer attemptCount = 0;

    public ActionDispatcher(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      this.action = action;
      this.matchingRecords = matchingRecords;
    }

    public void incrementAttempts() {
      this.attemptCount++;
    }

    public Integer getAttempts() {
      return this.attemptCount;
    }

    public Boolean hasPendingWork() {
      return this.hasPendingWork;
    }

    public abstract void dispatch();

    public abstract TransactionLimitsUsage getExpectedLimitsUsage();

    protected void authenticate() {
      System.debug('Authenticating...');
    }
  }

  // Class for CalloutActionDispatcher with Rate Limiting and Throttling
  private abstract class CalloutActionDispatcher extends ActionDispatcher {
    private final Integer RATE_LIMIT = 10; // Max number of callouts allowed in a window
    private final Integer TIME_WINDOW_SECONDS = 60; // Time window for rate limiting (e.g., 60 seconds)
    private final Integer THROTTLE_DELAY_MS = 2000; // Delay between callouts (e.g., 2 seconds)

    private Datetime lastCalloutTime;
    private Integer calloutsInCurrentWindow = 0;

    public CalloutActionDispatcher(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      super(action, matchingRecords);
    }

    // TODO decide if this should have a default implementation, or if subclasses should fully handle implementation
    // public override abstract void dispatch();
    // public virtual override void dispatch() {
    //   if (!canMakeCallout()) {
    //     System.debug('Rate limit exceeded, queuing the job with delay.');
    //     enqueueJobWithDelay(); // Throttling the callout
    //     return;
    //   }

    //   try {
    //     authenticate();
    //     String serviceUrl = getConfigValue('ServiceCalloutURL');
    //     sendServiceCallout(serviceUrl);
    //     trackCallout();
    //   } catch (Exception e) {
    //     System.debug('Callout failed: ' + e.getMessage());
    //   }
    // }

    // public abstract List<System.HttpRequest> getHttpRequests();

    protected Boolean checkCalloutLimits() {
      Integer remainingCallouts = System.Limits.getLimitCallouts() - System.Limits.getCallouts();
      if (remainingCallouts < 5) {
        System.debug('Re-enqueuing due to nearing callout limit.');
        return true;
      }
      return false;
    }

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
    public EmailActionDispatcher(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      super(action, matchingRecords);
    }

    public override void dispatch() {
      String recipient;
      switch on action.EmailRecipientType__c {
        when 'Email Address' {
          recipient = action.EmailAddressRecipient__c;
        }
        when 'User' {
          recipient = action.EmailUserRecipient__c;
        }
      }
      this.sendEmail(recipient);
    }

    private void sendEmail(String recipient) {
      System.debug('Sending email to: ' + recipient);
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage().setExpectedEmails(1);
    }
  }

  /* Start of Slack classes */
  private class SlackActionDispatcher extends CalloutActionDispatcher {
    private final Integer requestTimeoutInSeconds = 10 * 1000;

    public SlackActionDispatcher(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      super(action, matchingRecords);
    }

    public override void dispatch() {
      // System.debug('Executing Slack alert...\n' + System.JSON.serializePretty(this.action));
      Logger.debug('Executing Slack alert');

      System.Http httpClient = new System.Http();
      for (System.HttpRequest request : this.getHttpRequests()) {
        // System.debug('Sending Slack ' + action.SlackConnectionType__c + ' request to ' + action.SlackChannel__c);
        // System.debug('Sending Slack, Trigger.isExecuting ' + Trigger.isExecuting);
        // System.debug('Sending Slack, Limits.getLimitCallouts ' + System.Limits.getLimitCallouts());
        System.HttpResponse response = httpClient.send(request);
        Logger.debug('Received Slack response').setHttpRequestDetails(request).setHttpResponseDetails(response);
      }

      this.hasPendingWork = false;
      Logger.debug('Finished Slack alert');
      Logger.saveLog();
    }

    private List<System.HttpRequest> getHttpRequests() {
      // TODO requery the data
      // TODO create 1 request per match
      // TODO (dynamically?) use a field set for the current SObject Type
      List<System.HttpRequest> requests = new List<System.HttpRequest>();

      for (SObject record : this.matchingRecords) {
        SlackMessage slackMessage = new SlackMessage();
        String endpoint = 'callout:' + this.action.CalloutNamedCredential__c;
        if (this.action.SlackConnectionType__c == 'Chat Post Message') {
          endpoint += this.action.CalloutNamedCredential__c + '/api/chat.postMessage' + this.action.SlackChannel__c;
        }
        System.debug('>>> Slack endpoint: ' + endpoint);

        // TODO figure out exact steps/metadata needed to setup named credentials
        // https://unofficialsf.com/authorizing-salesforce-access-to-slack/
        System.HttpRequest request = new System.HttpRequest();
        // request.setBody(System.JSON.serializePretty(slackMessage));
        request.setBody(
          '{"text":"Salesforce Log Alert","attachments":[{"title_link":"https://gus.my.salesforce.com/aEqEE000000ZGI90AO","title":"Log-357713","text":"Last Log Entry Message\n```WARN: Error(s) performing DML for ADM_Scrum_Team__c:\nunable to obtain exclusive access to this record```","pretext":null,"footer":null,"fields":[{"value":"\n```\nClass.AHI_CloudMediator.logErrorsAndGetLockedRows: line 214, column 1\nClass.AHI_CloudMediator.performDML: line 139, column 1\nClass.AHI_CloudMediator.aggregateClouds: line 85, column 1\nClass.AHI_CloudAggregator.processCloudsAndTeamsAsync: line 200, column 1\nClass.AHI_CloudAggregator.finish: line 176, column 1\n```\n","title":"Stack Trace","short":false,"fieldPath":"StackTrace__c"},{"value":"`4070`","title":"Total CPU","short":true,"fieldPath":"TotalLimitsCpuTimeUsed__c"},{"value":"`Medium`","title":"Priority","short":true,"fieldPath":"Priority__c"},{"value":"`005B0000005cpyJIAQ`","title":"Owner ID","short":true,"fieldPath":"OwnerId"},{"value":"`New`","title":"Status","short":true,"fieldPath":"Status__c"},{"value":"`00DT0000000DpvcMAC`","title":"Organization ID","short":true,"fieldPath":"OrganizationId__c"},{"value":"`GUS`","title":"Organization Name","short":true,"fieldPath":"OrganizationName__c"},{"value":"`Unlimited Edition`","title":"Organization Type","short":true,"fieldPath":"OrganizationType__c"},{"value":"`USA12`","title":"Instance Name","short":true,"fieldPath":"OrganizationInstanceName__c"},{"value":"`9`","title":"Total Entries","short":true,"fieldPath":"TotalLogEntries__c"},{"value":"`0`","title":"Total ERROR Entries","short":true,"fieldPath":"TotalERRORLogEntries__c"},{"value":"`8`","title":"Total WARN Entries","short":true,"fieldPath":"TotalWARNLogEntries__c"},{"value":"`Log-357713`","title":"Log Number","short":true,"fieldPath":"Name"},{"value":"`3421de85-07f4-4657-9638-947b228057d5`","title":"Transaction ID","short":true,"fieldPath":"TransactionId__c"},{"value":"`ohanaeng.maint@gus.com`","title":"Username","short":true,"fieldPath":"LoggedBy__r.Username"}],"color":"#FFC873","author_name":"ohanaeng.maint@gus.com","author_link":"https://gus.my.salesforce.com/005B0000005cpyJIAQ"}]}'
        );
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        request.setTimeout(this.requestTimeoutInSeconds);

        requests.add(request);
      }

      return requests;
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage()
        .setExpectedCallouts(this.matchingRecords.size())
        // TODO revisit the expected callout time approach/concept
        .setExpectedCalloutTime(this.requestTimeoutInSeconds * this.matchingRecords.size())
        .setExpectedQueries(1)
        .setExpectedQueryRows(this.matchingRecords.size());
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
