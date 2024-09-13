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
global without sharing class EventMonitoringLogger implements Database.Batchable<SObject> {
  global Database.QueryLocator start(Database.BatchableContext batchableContext) {
    return EventMonitoringDataSelector.getInstance().getEventLogFileQueryLocator();
  }

  global void execute(Database.BatchableContext batchableContext, List<SObject> scopeRecords) {
    List<Schema.EventLogFile> eventLogFiles = (List<Schema.EventLogFile>) scopeRecords;
    for (Schema.EventLogFile eventLogFile : eventLogFiles) {
      // Map<String, Object> untypedEventLogFile = getEventLogFileAsMap(eventLogFile);
      String untypedEventLogFile = convertCsvToJson(eventLogFile.LogFIle.toString());
      // Map<String, Object> untypedEventLogFile = convertCsvToJson(eventLogFile.LogFIle.toString());
      Logger.debug('untypedEventLogFile: ' + untypedEventLogFile.toString());

      Logger.debug('EventLogFile: ' + eventLogFile.LogFile.toString());
      // Logger.info('EventLogFile: ' + untypedEventLogFile);
      // Logger.info('EventLogFile:
    }
    Logger.saveLog();
  }

  global void finish(Database.BatchableContext batchableContext) {
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
}
