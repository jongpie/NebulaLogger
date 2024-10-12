/*
  Possible class names:
  - ⭐ EventLogFileConverter
  - ⭐ EventLogFileBatchSaver
  - ⭐ EventLogFileSaver
  -     EventLogFileManager
  - ⭐  EventLogFileMonitor
    -   EventMonitoringLogger
    -   EventMonitoringLogConverter
    -   EventLogFileLogger
*/
public without sharing class EventMonitoringLogger implements Database.Batchable<SObject> {
  public Database.QueryLocator start(Database.BatchableContext batchableContext) {
    // TODO add a LoggerParameter__mdt record to store the list of EventType values to query in EventLogFile
    // List<String> eventTypeNames = new List<String>{ 'API', 'BulkApi', 'RestApi', 'ApexSoap' };
    List<String> eventTypeNames = new List<String>{ 'ApexExecution' };

    return EventMonitoringDataSelector.getInstance().getEventLogFileQueryLocator(eventTypeNames);
  }

  public void execute(Database.BatchableContext batchableContext, List<SObject> scopeRecords) {
    Logger.fine('Available fields on EventLogFile\n\n' + String.join(Schema.EventLogFile.SObjectType.getDescribe().fields.getMap().keySet(), '\n'));

    List<Schema.EventLogFile> eventLogFiles = (List<Schema.EventLogFile>) scopeRecords;
    for (Schema.EventLogFile eventLogFile : eventLogFiles) {
      // Map<String, Object> untypedEventLogFile = getEventLogFileAsMap(eventLogFile);
      String untypedEventLogFile = convertCsvToJson(eventLogFile.LogFIle.toString());

      // List<Map<String, Object>> untypedEventLogFiles = (List<Map<String, Object>>) System.JSON.deserializeUntyped(untypedEventLogFile.toString());
      List<Object> untypedEventLogFiles = (List<Object>) System.JSON.deserializeUntyped(untypedEventLogFile.toString());
      // List<ApexUnexpectedExceptionEvent> untypedEventLogFiles = (List<ApexUnexpectedExceptionEvent>) System.JSON.deserializeUntyped(
      // untypedEventLogFile.toString()
      // );
      // for (Map<String, Object> eventLogFileMap : untypedEventLogFiles) {
      for (Object eventLogFileMap : untypedEventLogFiles) {
        // for (ApexUnexpectedExceptionEvent eventLogFileMap : untypedEventLogFiles) {
        LogEntryEventBuilder builder = Logger.info('Event log file type ' + eventLogFile.EventType + ': ' + eventLogFileMap, eventLogFile.Id);
        builder.setTimestamp(System.now()); // TEMP/testing

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();
        // logEntryEvent.RequestId__c = eventLogFileMap.get('REQUEST_ID')?.toString();
        // TODO figure out how to handle populating TransactionId__c
        // TODO figure out how to handle populating LoggedBy__c

        // Map<String, Object> untypedEventLogFile = convertCsvToJson(eventLogFile.LogFIle.toString());
      }

      // Logger.debug('EventLogFile: ' + eventLogFile.LogFile.toString());
      // Logger.info('EventLogFile: ' + untypedEventLogFile);
      // Logger.info('EventLogFile:
    }
    Logger.saveLog();
  }

  public void finish(Database.BatchableContext batchableContext) {
  }

  public static String convertCsvToJson(String csvPayload) {
    DataWeave.Script script = new DataWeaveScriptResource.EventLogFileToJson();
    DataWeave.Result result = script.execute(new Map<String, Object>{ 'payload' => csvPayload });
    return result.getValueAsString();
  }
  // private static Map<String, Object> getEventLogFileAsMap(EventLogFile eventLogFile) {
  //   Map<String, Object> untypedEventLogFile = new Map<String, Object>();
  //   // return (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(eventLogFile));

  //   return untypedEventLogFile;
  // }

  private class ApexUnexpectedExceptionEvent {
    public String EVENT_TYPE;
    public String EXCEPTION_CATEGORY;
    public String EXCEPTION_MESSAGE;
    public String EXCEPTION_TYPE;
    public String ORGANIZATION_ID;
    public String REQUEST_ID;
    public String STACK_TRACE;
    public String TIMESTAMP;
    public String TIMESTAMP_DERIVED;
    public String USER_ID;
  }
}
