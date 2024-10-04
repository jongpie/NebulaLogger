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

    List<LoggerAlert__c> todoAlertsVariable = null; // TODO!!!!
    for (LoggerAlert__c alert : todoAlertsVariable) {
      List<SObject> matchingRecords = this.getMatchingRecords(alert, records);

      if (matchingRecords.isEmpty()) {
        continue;
      }

      // Create executors for each alert and pass to ActionsProcessor
      List<AbstractActionExecutor> executors = new List<AbstractActionExecutor>();
      for (LoggerAlertAction__c action : alert.LoggerAlertActions__r) {
        AbstractActionExecutor executor = createActionExecutorForCallout(action, matchingRecords);
        if (executor != null) {
          executors.add(executor);
        }
      }

      // Always pass executors to the processor to handle execution or re-enqueue
      if (!executors.isEmpty()) {
        System.debug('Passing executors to the ActionsProcessor.');
        new ActionsProcessor(executors).execute();
      }
    }
  }

  private List<SObject> getMatchingRecords(LoggerAlert__c alert, List<SObject> records) {
    FormulaEval.FormulaInstance formulaEvaluator = System.Formula.builder()
      .withReturnType(FormulaEval.FormulaReturnType.Boolean)
      .withType(records.getSObjectType())
      .withFormula(alert.SourceSObjectFilter__c)
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

  // Factory method to create the appropriate action executor for Callout
  private AbstractActionExecutor createActionExecutorForCallout(LoggerAlertAction__c action, List<SObject> matchingRecords) {
    switch on action.Type__c {
      when 'Callout' {
        return new CalloutActionExecutor(action, matchingRecords);
      }
      when 'Email' {
        return new EmailActionExecutor(action, matchingRecords);
      }
      when 'Slack' {
        return new SlackActionExecutor(action, matchingRecords);
      }
      when else {
        System.debug('Unknown action type \'' + action.Type__c + '\' on alert action ' + action.Id);
        return null;
      }
    }
  }

  // Private Queueable class to handle executing or re-enqueuing the actions
  private class ActionsProcessor implements System.Queueable {
    private final List<AbstractActionExecutor> executors;

    // Constructor
    public ActionsProcessor(List<AbstractActionExecutor> executors) {
      this.executors = executors;
    }

    // Synchronous execution method
    public void execute() {
      System.debug('Running executors in ActionsProcessor.');
      List<AbstractActionExecutor> remainingExecutors = new List<AbstractActionExecutor>();

      List<SObject> matchingRecords = new List<SObject>();
      for (AbstractActionExecutor executor : executors) {
        if (hasSufficientLimits(executor.getExpectedLimitsUsage())) {
          executor.execute();
        } else {
          System.debug('Insufficient limits for executor, adding to remainingExecutors.');
          remainingExecutors.add(executor);
        }
      }

      // If there are remaining executors, enqueue the job for later execution
      if (!remainingExecutors.isEmpty()) {
        System.debug('Enqueuing remaining actions due to insufficient limits.');
        // TODO consider use the same instance, but processed executors would need to be remove from the list
        System.enqueueJob(new ActionsProcessor(remainingExecutors));
      }
    }

    // Required Queueable execute method
    public void execute(System.QueueableContext context) {
      execute(); // Call the synchronous method
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

  // AbstractActionExecutor class that contains common logic for all executors
  private abstract class AbstractActionExecutor {
    protected final LoggerAlertAction__c action;
    protected final List<SObject> matchingRecords;

    public AbstractActionExecutor(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      this.action = action;
      this.matchingRecords = matchingRecords;
    }

    public abstract void execute();

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

  // Class for CalloutActionExecutor with Rate Limiting and Throttling
  private class CalloutActionExecutor extends AbstractActionExecutor {
    private final Integer RATE_LIMIT = 10; // Max number of callouts allowed in a window
    private final Integer TIME_WINDOW_SECONDS = 60; // Time window for rate limiting (e.g., 60 seconds)
    private final Integer THROTTLE_DELAY_MS = 2000; // Delay between callouts (e.g., 2 seconds)

    private Datetime lastCalloutTime;
    private Integer calloutsInCurrentWindow = 0;

    public CalloutActionExecutor(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      super(action, matchingRecords);
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return null;
    }

    public override void execute() {
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

  // Inner class for EmailActionExecutor
  private class EmailActionExecutor extends AbstractActionExecutor {
    public EmailActionExecutor(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      super(action, matchingRecords);
    }

    public override void execute() {
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

  // Inner class for SlackActionExecutor
  private class SlackActionExecutor extends AbstractActionExecutor {
    public SlackActionExecutor(LoggerAlertAction__c action, List<SObject> matchingRecords) {
      super(action, matchingRecords);
    }

    public override void execute() {
      System.debug('Executing Slack alert...');
      if (checkCalloutLimits()) {
        return;
      }

      authenticate();
      String channel = getConfigValue('SlackChannel');
      sendSlackMessage(channel);
    }

    private void sendSlackMessage(String channel) {
      System.debug('Sending message to Slack channel: ' + channel);
    }

    public override TransactionLimitsUsage getExpectedLimitsUsage() {
      return new TransactionLimitsUsage().setExpectedCallouts(1).setExpectedDmlStatements(0).setExpectedEmails(0); // No emails for Slack actions
    }
  }

  // TransactionLimitsUsage class with fluent API
  public class TransactionLimitsUsage {
    public Integer expectedCallouts = 0;
    public Integer expectedDmlStatements = 0;
    public Integer expectedEmails = 0;
    public Integer expectedQueries = 0;
    public Integer expectedCalloutTime = 0; // Tracking expected callout time in seconds
    public Integer expectedQueueableJobs = 0; // Tracking queueable jobs

    public TransactionLimitsUsage setExpectedCallouts(Integer callouts) {
      this.expectedCallouts = callouts;
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

    public TransactionLimitsUsage setExpectedCalloutTime(Integer calloutTime) {
      this.expectedCalloutTime = calloutTime;
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
      //   CalloutActionExecutor.this.execute();
    }
  }
}
