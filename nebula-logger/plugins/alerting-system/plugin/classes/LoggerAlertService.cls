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
  private static final Map<String, List<LoggerAlert__c>> SOBJECT_API_NAME_TO_ALERTS = new Map<String, List<LoggerAlert__c>>();

  // Static variable to hold the singleton instance
  private static Integer calloutTimeUsed = 0;
  private static LoggerAlertService instance;
  private static ActionsProcessor processor;

  // Private constructor to prevent direct instantiation
  private LoggerAlertService() {
    // No-op
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

    Schema.SObjectType sourceSObjectType = records.getSObjectType();
    if (sourceSObjectType != LogEntry__c.SObjectType) {
      System.debug('⛔⚠️TEMP! Only testing with LogEntry__c for now');
      return;
    }

    /*
      TODO things to add
        1. If 1 or more Slack actions are setup, combine the lists in OutputFields__c together use to requery records
        2. Decide if email alerts will be supported for all Source SObject Types, and if so, can fields be customized (like Slack)?
        3. If 1 or more OTel actions are setup, query all fields on Log__c, LogEntry__c, LogEntryTag__c, LoggerTag__c, and LoggerScenario__c
        4. Based on IsLogRetentionOverrideEnabled__c, update the  field Log__c.LogRetentionDate__c
    */

    // TODO add re-query step here. It should query some base fields (Id, TransactionId__c, etc.),
    // as well as any fields specified in LoggerAlert__c.OutputFields__c (which will possible be renamed
    // to something more generic, like "Display Fields", "Action Fields", "Output Fields", etc.)

    List<LoggerAlert__c> sourceSObjectTypeAlerts = this.getAlerts(sourceSObjectType);
    Set<String> contextFieldNames = this.getContextFields(sourceSObjectType, sourceSObjectTypeAlerts);
    // TODO use contextFieldNames to dynamically requery scope records (need to also include base fields?)

    BulkRecordCreateActionDispatcher bulkRecordCreateActionDispatcher = new BulkRecordCreateActionDispatcher();
    List<LoggerAlertMatch__c> alertMatches = new List<LoggerAlertMatch__c>();
    List<ActionDispatcher> dispatchers = new List<ActionDispatcher>{ bulkRecordCreateActionDispatcher };

    for (LoggerAlert__c alert : sourceSObjectTypeAlerts) {
      // The list of matches is initialized here, but it's passed to multiple actions below.
      // Every action should have a deep clone of the list (instead of the original reference)
      // passed so that the action can freely do things like clear or remove items from the list,
      // without interfering with other actions running for the same records.
      List<SObject> matchingRecords = this.getMatchingRecords(alert, records);

      if (matchingRecords.isEmpty()) {
        continue;
      }

      // TODO remove this call to deepClone()?
      bulkRecordCreateActionDispatcher.addMatches(alert, matchingRecords.deepClone());

      for (LoggerAlertAction__c action : alert.LoggerAlertActions__r) {
        ActionDispatcher dispatcher = createActionDispatcher(action, matchingRecords.deepClone());
        if (dispatcher != null) {
          dispatchers.add(dispatcher);
        }
      }
    }

    LoggerDataStore.getDatabase().insertRecords(alertMatches);

    if (dispatchers.isEmpty() == false) {
      new ActionsProcessor(dispatchers).execute();
    }
  }

  private Set<String> getContextFields(Schema.SObjectType sourceSObjectType, List<LoggerAlert__c> alerts) {
    Set<String> fieldPathStrings = new Set<String>();
    for (LoggerAlert__c alert : alerts) {
      for (LoggerAlertAction__c alertAction : alert.LoggerAlertActions__r) {
        if (String.isBlank(alertAction.OutputFields__c)) {
          continue;
        }

        for (String fieldName : alertAction.OutputFields__c.split('[ ,\\n]')) {
          if (String.isBlank(fieldName)) {
            continue;
          }
          fieldPathStrings.add(fieldName.trim().toLowerCase());
        }
      }

      Set<String> cleanedFieldNames = new Set<String>();
      for (String fieldName : fieldPathStrings) {
        LoggerSObjectMetadata.FieldPath fieldPath = new LoggerSObjectMetadata.FieldPath(sourceSObjectType, fieldName);
        if (fieldPath.isValid()) {
          cleanedFieldNames.add(fieldPath.getFormattedFieldPath());
        }
      }
    }

    return fieldPathStrings;
  }

  private List<LoggerAlert__c> getAlerts(Schema.SObjectType sobjectType) {
    String sobjectApiName = sobjectType.toString();
    if (SOBJECT_API_NAME_TO_ALERTS.containsKey(sobjectApiName) == false) {
      // TODO move SOQL query to LogManagementDataSelector class
      SOBJECT_API_NAME_TO_ALERTS.put(
        sobjectApiName,
        [
          SELECT
            Id,
            IsLogRetentionOverrideEnabled__c,
            IsMatchStorageEnabled__c,
            NumberOfDaysToRetainLogs__c,
            OriginOrganizationId__c,
            SourceSObjectFilter__c,
            SourceSObjectType__c,
            TotalMatches__c,
            Type__c,
            (
              SELECT
                Id,
                CalloutConnectionType__c,
                CalloutNamedCredential__c,
                OutputFields__c,
                EmailAddressRecipient__c,
                EmailRecipientType__c,
                EmailUserRecipient__c,
                LoggerAlert__c,
                ObservabilityPlatform__c,
                SlackChannel__c,
                Type__c
              FROM LoggerAlertActions__r
              WHERE IsEnabled__c = TRUE
            )
          FROM LoggerAlert__c
          WHERE IsEnabled__c = TRUE AND IsOriginOrganizationIdValid__c = TRUE
        ]
      );
    }

    return SOBJECT_API_NAME_TO_ALERTS.get(sobjectApiName);
  }

  private List<SObject> getMatchingRecords(LoggerAlert__c alert, List<SObject> records) {
    FormulaEval.FormulaInstance formulaEvaluator = System.Formula.builder()
      .withFormula(alert.SourceSObjectFilter__c)
      .withReturnType(FormulaEval.FormulaReturnType.Boolean)
      .withType(records.getSObjectType())
      .build();

    // TOOD move to a new private static helper method
    Set<String> referencedFieldNames = formulaEvaluator.getReferencedFields();
    // TODO make sure Id, and any other relevant fields are included, but make sure to match casing returned from formulaEvaluator.getReferencedFields()
    referencedFieldNames.add('Id');
    // TODO need to trim each value + use correct/consistent casing (lowercase?)
    // referencedFieldNames.add(alert.OutputFields__c.split(','));
    for (LoggerAlertAction__c action : alert.LoggerAlertActions__r) {
      referencedFieldNames.addAll(action.OutputFields__c.split('\n'));
    }
    String query = 'SELECT ' + String.join(referencedFieldNames, ', ') + ' FROM ' + records.getSObjectType() + ' WHERE Id IN :records';
    List<SObject> requeriedRecords = System.Database.query(query);

    List<SObject> matchingRecords = new List<SObject>();
    for (SObject inputRecord : requeriedRecords) {
      Boolean matchesFilter = (Boolean) formulaEvaluator.evaluate(inputRecord);
      if (matchesFilter) {
        matchingRecords.add(inputRecord);
      }
    }

    return matchingRecords;
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

    public ActionsProcessor() {
      // No-op
    }

    public BulkRecordCreateActionDispatcher getRecordCreateActionDispatcher() {
      return null;
    }

    public EmailActionDispatcher getEmailActionDispatcher() {
      return null;
    }

    public SlackActionDispatcher getSlackActionDispatcher() {
      return null;
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

    protected ActionDispatcher() {
      // No-op
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

  private class BulkRecordCreateActionDispatcher extends ActionDispatcher {
    private List<LoggerAlertMatch__c> loggerAlertMatches = new List<LoggerAlertMatch__c>();

    public BulkRecordCreateActionDispatcher() {
      super();
    }

    public void addMatches(LoggerAlert__c alert, List<SObject> matchingRecords) {
      if (alert.IsMatchStorageEnabled__c) {
        this.loggerAlertMatches.addAll(this.generateLoggerAlertMatchRecords(alert, matchingRecords));
        this.hasPendingWork = true;
      }
    }

    public override void dispatch() {
      LoggerDataStore.getDatabase().insertRecords(this.loggerAlertMatches);
      this.loggerAlertMatches.clear();
      this.hasPendingWork = false;
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage().setExpectedDmlStatements(1);
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
      System.debug('>>> preparing to send email for action:\n\n' + System.JSON.serializePretty(this.action));

      // Docs: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_email_outbound_single.htm
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setSaveAsActivity(false);
      email.setSenderDisplayName('Nebula Logger');
      email.setSubject('Email to Users and External Recipients');
      email.setPlainTextBody('This email is sent to internal users and external recipients.');
      switch on action.EmailRecipientType__c {
        when 'Email Address' {
          email.setToAddresses(action.EmailAddressRecipient__c.split(','));
        }
        when 'User' {
          email.setTargetObjectId(action.EmailUserRecipient__c);
        }
      }

      System.Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
      System.debug('>>> sent email: ' + email);

      this.hasPendingWork = false;
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage().setExpectedEmails(this.matchingRecords.size());
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
        // System.debug('Sending Slack ' + action.CalloutConnectionType__c + ' request to ' + action.SlackChannel__c);
        // System.debug('Sending Slack, Trigger.isExecuting ' + Trigger.isExecuting);
        // System.debug('Sending Slack, Limits.getLimitCallouts ' + System.Limits.getLimitCallouts());
        System.HttpResponse response = httpClient.send(request);
        Logger.debug('Received Slack response').setHttpRequestDetails(request).setHttpResponseDetails(response);
      }

      this.hasPendingWork = false;
      Logger.debug('Finished Slack alert');
      Logger.saveLog();
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage()
        .setExpectedCallouts(this.matchingRecords.size())
        // TODO revisit the expected callout time approach/concept
        .setExpectedCalloutTime(this.requestTimeoutInSeconds * this.matchingRecords.size())
        .setExpectedQueries(1)
        .setExpectedQueryRows(this.matchingRecords.size());
    }

    private List<System.HttpRequest> getHttpRequests() {
      // TODO requery the data
      // TODO create 1 request per match
      // TODO (dynamically?) use a field set for the current SObject Type
      List<System.HttpRequest> requests = new List<System.HttpRequest>();

      for (SObject record : this.matchingRecords) {
        SlackMessage slackMessage = this.buildSlackMessage(record);
        String endpoint = 'callout:' + this.action.CalloutNamedCredential__c;
        if (this.action.CalloutConnectionType__c == 'OAuth') {
          endpoint += this.action.CalloutNamedCredential__c + '/api/chat.postMessage' + this.action.SlackChannel__c;
        }
        System.debug('>>> Slack endpoint: ' + endpoint);

        // TODO figure out exact steps/metadata needed to setup named credentials
        // https://unofficialsf.com/authorizing-salesforce-access-to-slack/
        System.HttpRequest request = new System.HttpRequest();
        // request.setBody(System.JSON.serializePretty(slackMessage));
        request.setBody(System.JSON.serializePretty(slackMessage, true));
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        request.setTimeout(this.requestTimeoutInSeconds);

        requests.add(request);
      }

      return requests;
    }

    private SlackMessage buildSlackMessage(SObject record) {
      SlackMessage message = new SlackMessage();

      String recordLink = System.URL.getOrgDomainUrl().toExternalForm() + '/' + record.Id;
      String headerText = 'Salesforce Alert: New ' + record.getSObjectType() + ' Record';
      headerText += '\n*<' + recordLink + '|' + record.get('Name') + '>*';
      SlackBlock headerBlock = new SlackBlock('section', new SlackBlockField('mrkdwn', headerText));
      message.blocks.add(headerBlock);

      SlackBlock wideMessageBlock = new SlackBlock(
        'section',
        new SlackBlockField('mrkdwn', '*Full-width field*\n\n```this field spans the full width.\n```\n' + record.Id)
      );
      message.blocks.add(wideMessageBlock);

      SlackBlock multiColumnBlock = new SlackBlock(
        'section',
        new List<SlackBlockField>{
          new SlackBlockField('mrkdwn', '*Half-width field 1:* Value 1'),
          new SlackBlockField('mrkdwn', '*Half-width field 2:* Value 2')
        }
      );
      // multiColumnBlock.accessory = new SlackBlockAccessory();
      // multiColumnBlock.accessory.text = new SlackBlockField('plain_text', 'View Record');
      // multiColumnBlock.accessory.type = 'button';
      // multiColumnBlock.accessory.url = System.URL.getOrgDomainUrl().toExternalForm() + '/' + record.Id;
      message.blocks.add(multiColumnBlock);

      SlackBlockAction viewRecordButton = new SlackBlockAction();
      viewRecordButton.style = 'primary';
      viewRecordButton.text = new SlackBlockField('plain_text', 'zzzView Record');
      viewRecordButton.type = 'button';
      viewRecordButton.value = System.URL.getOrgDomainUrl().toExternalForm() + '/' + record.Id;
      SlackBlock footerBlock = new SlackBlock('actions');
      footerBlock.elements = new List<SlackBlockAction>{ viewRecordButton };
      // TODO revisit this, causes an invalid_blocks error
      // message.blocks.add(footerBlock);

      return message;
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
    public List<SlackBlock> blocks = new List<SlackBlock>();
    public String channel;
    public String icon_emoji;
    public String icon_url;
  }

  public class SlackBlock {
    public SlackBlockAccessory accessory;
    public List<SlackBlockAction> elements;
    public List<SlackBlockField> fields = new List<SlackBlockField>();
    public SlackBlockField text;
    public String type;

    public SlackBlock(String type, SlackBlockField field) {
      this(type, new List<SlackBlockField>{ field });
    }

    public SlackBlock(String type, List<SlackBlockField> fields) {
      this(type);
      this.fields = fields;
    }

    public SlackBlock(String type) {
      this.type = type;
    }
  }

  public class SlackBlockAccessory {
    public String alt_text;
    public String image_url;
    public SlackBlockField text;
    public String type;
    public String url;
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

    public SlackBlockField(String type, String text) {
      this.type = type;
      this.text = text;
    }
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
    public Integer expectedQueueableJobs = 0;

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
