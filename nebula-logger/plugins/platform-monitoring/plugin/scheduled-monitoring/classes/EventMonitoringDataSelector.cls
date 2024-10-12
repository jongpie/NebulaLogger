@SuppressWarnings('PMD.ApexDoc')
public with sharing class EventMonitoringDataSelector {
  private static EventMonitoringDataSelector instance = new EventMonitoringDataSelector();

  @SuppressWarnings('PMD.EmptyStatementBlock')
  @TestVisible
  private EventMonitoringDataSelector() {
  }

  /**
   * @description The instance `EventMonitoringDataSelector` used for any querying specific to the logger engine layer
   * @return   The singleton instance of `LoggerEngineDataSelector`
   */
  public static EventMonitoringDataSelector getInstance() {
    return instance;
  }

  public virtual Database.QueryLocator getEventLogFileQueryLocator(List<String> eventTypeNames) {
    return System.Database.getQueryLocator(
      // TODO move SOQL query to a selector class (new EventMonitoringDataSelector class?)
      [
        SELECT
          ApiVersion,
          CreatedBy.Name,
          CreatedBy.Username,
          CreatedById,
          EventType,
          // Interval,
          LastModifiedBy.Name,
          LastModifiedBy.Username,
          LastModifiedById,
          LogDate,
          LogFile,
          LogFileContentType,
          LogFileFieldNames,
          LogFileFieldTypes,
          LogFileLength
        // Sequence
        FROM EventLogFile
        // WHERE EventType IN :eventTypeNames
        ORDER BY LogDate DESC, CreatedDate DESC //, Sequence DESC
      ]
    );
  }
}
