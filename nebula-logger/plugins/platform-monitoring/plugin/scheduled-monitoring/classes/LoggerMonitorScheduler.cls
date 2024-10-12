//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

global without sharing class LoggerMonitorScheduler implements System.Schedulable {
  private static final String TAG_MONITORING = 'Monitoring';

  private enum HttpVerb {
    GET,
    DELETION, // DELETE is a reserved word in Apex
    PATCH,
    POST,
    PUT
  }

  private Datetime minimumDate;

  global LoggerMonitorScheduler() {
    this(System.today().addDays(-1));
  }

  global LoggerMonitorScheduler(Datetime minimumDate) {
    this.minimumDate = minimumDate;
  }

  global void execute(System.SchedulableContext schedulableContext) {
    // TODO add checks for corresponding LoggerParameter__mdt records
    List<System.Type> monitorTypes = new List<System.Type>{
      // ApexLogMonitor.class,
      // AsyncApexJobMonitor.class,
      // BackgroundOperationMonitor.class,
      // BulkApiJobMonitor.class,
      EntityLimitMonitor.class,
      // EventLogFileMonitor.class,
      // IdentityProviderEventMonitor.class,
      // LightningToggleMetricsMonitor.class,
      // OrgLimitsMonitor.class,
      // PlatformEventsUsageMetricMonitor.class,
      // ProcessApprovalMonitor.class,
      RecordCountMonitor.class
    };

    for (System.Type monitorType : monitorTypes) {
      LoggerMonitor queueableMonitor = (LoggerMonitor) monitorType.newInstance();
      if (queueableMonitor.shouldRun() == true) {
        queueableMonitor.setMinimumDate(this.minimumDate);
        LoggerDataStore.getJobQueue().enqueueJob(queueableMonitor);
      }
    }
  }

  private without sharing abstract class LoggerMonitor implements System.Queueable {
    private Datetime minimumDate;

    public abstract Boolean shouldRun();
    public abstract void execute(System.QueueableContext queueableContext);

    public Datetime getMinimumDate() {
      return this.minimumDate;
    }

    public void setMinimumDate(Datetime minimumDate) {
      this.minimumDate = minimumDate;
    }
  }

  private without sharing abstract class LoggerRESTMonitor extends LoggerMonitor {
    public override abstract Boolean shouldRun();
    public override abstract void execute(System.QueueableContext queueableContext);

    protected System.HttpRequest createOrganizationHttpRequest(HttpVerb verb, String endpointUri) {
      String endpointTemplate = '{0}/services/data/v57.0{1}';
      String endpoint = String.format(endpointTemplate, new List<String>{ System.URL.getOrgDomainUrl().toExternalForm(), endpointUri });
      System.HttpRequest request = new System.HttpRequest();
      request.setEndpoint(endpoint);
      request.setHeader('Authorization', 'OAuth ' + System.UserInfo.getSessionId());
      request.setHeader('Content-Type', 'application/json');
      request.setMethod(verb == HttpVerb.DELETION ? 'DELETE' : verb.name());
      return request;
    }
  }

  // TODO the log files returned from the Tooling API may be too large for Apex's heap size (╯°□°）╯︵ ┻━┻
  // private without sharing class ApexLogMonitor extends LoggerRESTMonitor implements Database.AllowsCallouts {
  //     private Set<Id> apexLogIds = new Set<Id>();

  //     public override void execute(System.QueueableContext queueableContext) {
  //         Logger.ignoreOrigin(ApexLogMonitor.class);
  //         Logger.setScenario('Schema.' + Schema.ApexLog.getSObjectType().getDescribe().getName() + ' Monitoring');
  //         clearIrrelevantFields(Logger.info('Running ApexLog extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

  //         Integer recordCount = this.queryRecordCount();
  //         if (recordCount == 0) {
  //             clearIrrelevantFields(Logger.info('No matching ApexLog records found').addTag(TAG_MONITORING));
  //         } else {
  //             Logger.info('Found ' + recordCount + ' matching ApexLog records');
  //         }
  //         Set<Id> apexLogIds = new Set<Id>();
  //         for (ApexLog apexLog : this.queryRecords()) {
  //             apexLogIds.add(apexLog.Id);
  //             // HttpRequest toolingApiRequest = this.createHttpRequest(apexLog.Id);
  //             // HttpResponse toolingApiResponse = new System.Http().send(toolingApiRequest);
  //             Logger.getUserSettings().IsDataMaskingEnabled__c = false;
  //             clearIrrelevantFields(
  //                 Logger.info('Matching ApexLog entry', apexLog)
  //                     // .setHttpRequestDetails(toolingApiRequest)
  //                     // .setHttpResponseDetails(toolingApiResponse)
  //                     .addTag(TAG_MONITORING)
  //             );
  //         }

  //         if (this.apexLogIds.isEmpty() == false) {
  //             // TODO
  //             LoggerDataStore.getJobQueue().enqueueJob(this);
  //         }

  //         Logger.saveLog();
  //     }

  //     private Integer queryRecordCount() {
  //         return [
  //             SELECT COUNT()
  //             FROM ApexLog
  //             WHERE StartTime >= :this.getMinimumDate()
  //         ];
  //     }

  //     private List<ApexLog> queryRecords() {
  //         return [
  //             SELECT
  //                 Id,
  //                 Application,
  //                 DurationMilliseconds,
  //                 Location,
  //                 LogLength,
  //                 LogUserId,
  //                 LogUser.Username,
  //                 Operation,
  //                 Request,
  //                 RequestIdentifier,
  //                 StartTime,
  //                 Status
  //             FROM ApexLog
  //             WHERE StartTime >= :this.getMinimumDate()
  //             LIMIT 2
  //         ];
  //     }

  //     private HttpRequest createHttpRequest(Id apexLogId) {
  //         // String endpointTemplate = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v57.0/tooling/sobjects/ApexLog/' + apexLogId + '/Body/';
  //         // String endpoint = String.format(endpointTemplate, new List<String>{ apexLogId });
  //         String endpointTemplate = '{0}/services/data/v57.0/tooling/sobjects/ApexLog/{1}/Body/';
  //         String endpoint = String.format(endpointTemplate, new List<String>{ URL.getSalesforceBaseUrl().toExternalForm(), apexLogId });
  //         HttpRequest request = new HttpRequest();
  //         request.setEndpoint(endpoint);
  //         request.setHeader('Authorization', 'OAuth ' + System.UserInfo.getSessionId());
  //         request.setHeader('Content-Type', 'application/json');
  //         request.setMethod('GET');
  //         return request;
  //     }
  // }

  private without sharing class AsyncApexJobMonitor extends LoggerMonitor {
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(AsyncApexJobMonitor.class);
      Logger.setScenario('Schema.' + Schema.AsyncApexJob.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running AsyncApexJob extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      Integer recordCount = this.queryRecordCount();
      if (recordCount == 0) {
        clearIrrelevantFields(Logger.info('No matching AsyncApexJob records found').addTag(TAG_MONITORING));
      } else {
        Logger.info('Found ' + recordCount + ' matching AsyncApexJob records');
      }
      for (Schema.AsyncApexJob asyncApexJob : this.queryRecords()) {
        clearIrrelevantFields(Logger.info('Matching AsyncApexJob entry', asyncApexJob).addTag(TAG_MONITORING));
      }

      Logger.saveLog();
    }

    private Integer queryRecordCount() {
      return [
        SELECT COUNT()
        FROM AsyncApexJob
        WHERE CreatedDate >= :this.getMinimumDate()
      ];
    }

    // TODO https://developer.salesforce.com/docs/atlas.en-us.200.0.object_reference.meta/object_reference/sforce_api_objects_AsyncApexJob.htm
    private List<Schema.AsyncApexJob> queryRecords() {
      return [
        SELECT
          Id,
          CreatedById,
          CreatedDate,
          ApexClassId,
          ApexClass.Name,
          CompletedDate,
          CronTriggerId,
          CronTrigger.CronExpression,
          CronTrigger.CronJobDetailId,
          CronTrigger.CronJobDetail.JobType,
          CronTrigger.CronJobDetail.Name,
          CronTrigger.EndTime,
          CronTrigger.NextFireTime,
          CronTrigger.OwnerId,
          CronTrigger.PreviousFireTime,
          CronTrigger.StartTime,
          CronTrigger.State,
          CronTrigger.TimesTriggered,
          CronTrigger.TimeZoneSidKey,
          ExtendedStatus,
          JobItemsProcessed,
          JobType,
          LastProcessed,
          LastProcessedOffset,
          MethodName,
          NumberOfErrors,
          ParentJobId,
          Status,
          TotalJobItems
        FROM AsyncApexJob
        WHERE CreatedDate >= :this.getMinimumDate()
      ];
    }
  }

  private without sharing class BackgroundOperationMonitor extends LoggerMonitor {
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(BackgroundOperationMonitor.class);
      Logger.setScenario('Schema.' + Schema.BackgroundOperation.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running BackgroundOperation extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      Integer recordCount = this.queryRecordCount();
      if (recordCount == 0) {
        clearIrrelevantFields(Logger.info('No matching BackgroundOperation records found').addTag(TAG_MONITORING));
      } else {
        Logger.info('Found ' + recordCount + ' matching BackgroundOperation records');
      }
      for (BackgroundOperation backgroundOperation : this.queryRecords()) {
        clearIrrelevantFields(Logger.info('Matching background operation entry', backgroundOperation).addTag(TAG_MONITORING));
      }

      Logger.saveLog();
    }

    private Integer queryRecordCount() {
      return [
        SELECT COUNT()
        FROM BackgroundOperation
        WHERE CreatedDate >= :this.getMinimumDate()
      ];
    }
    // TODO https://developer.salesforce.com/docs/atlas.en-us.200.0.object_reference.meta/object_reference/sforce_api_objects_backgroundoperation.htm
    private List<BackgroundOperation> queryRecords() {
      return [
        SELECT
          Id,
          CreatedById,
          CreatedDate,
          Error,
          ExecutionGroup,
          ExpiresAt,
          FinishedAt,
          GroupLeaderId,
          Name,
          NumFollowers,
          ParentKey,
          ProcessAfter,
          RetryBackoff,
          RetryCount,
          RetryLimit,
          SequenceGroup,
          SequenceNumber,
          StartedAt,
          Status,
          SubmittedAt,
          Timeout,
          WorkerUri
        FROM BackgroundOperation
        WHERE CreatedDate >= :this.getMinimumDate()
      ];
    }
  }

  private without sharing class BulkApiJobMonitor extends LoggerRESTMonitor implements Database.AllowsCallouts {
    // Source https://developer.salesforce.com/docs/atlas.en-us.242.0.api_asynch.meta/api_asynch/queries.htm
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(BulkApiJobMonitor.class);
      Logger.setScenario('TODO'); //Schema.' + Schema.ApexLog.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running Bulk API 2.0 Job extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      String jobsEndpointUri = '/jobs/query';
      Boolean isDone = false;
      while (isDone == false && System.Limits.getCallouts() <= System.Limits.getLimitCallouts()) {
        // TODO make additional callouts for each job....?
        // https://developer.salesforce.com/docs/atlas.en-us.242.0.api_asynch.meta/api_asynch/queries.htm
      }
      // String queryString = 'SELECT '
      // while (System.Limits.getCallouts <= System.Limits.getLimitCallouts()) {
      // TODO deserialize response.getBody() into a new DTO class
      System.HttpRequest request = this.createOrganizationHttpRequest(HttpVerb.GET, jobsEndpointUri);
      System.HttpResponse response = new System.Http().send(request);
      Logger.info('Running EventLogFile extract').setHttpRequestDetails(request).setHttpResponseDetails(response).addTag(TAG_MONITORING);
      Logger.savelog();
      // }
    }
  }

  private without sharing class EntityLimitMonitor extends LoggerRESTMonitor implements Database.AllowsCallouts {
    // Source https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_entitylimit.htm
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(EntityLimitMonitor.class);
      Logger.setScenario('REST.SObject.EntityLimit');
      clearIrrelevantFields(Logger.info('Running REST API Entity Limit extract').addTag(TAG_MONITORING));

      String queryString = 'SELECT DurableId, EntityDefinitionId, Label, Max, Remaining, Type FROM EntityLimit';
      String entityLimitUri = '/tooling/query/?q=' + queryString.replace(' ', '+');
      System.HttpRequest request = this.createOrganizationHttpRequest(HttpVerb.GET, entityLimitUri);
      System.HttpResponse response = new System.Http().send(request);
      Logger.info('Matching results for REST API EntityLimit extract').setHttpRequestDetails(request).setHttpResponseDetails(response).addTag(TAG_MONITORING);
      Logger.savelog();
    }
  }

  private without sharing class EventLogFileMonitor extends LoggerMonitor {
    public override Boolean shouldRun() {
      return LoggerParameter.getBoolean('EnableEventLogFileMonitoring', false);
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(EventLogFileMonitor.class);
      Logger.setScenario('Schema.' + Schema.EventLogFile.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running EventLogFile extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      Integer recordCount = this.queryRecordCount();
      if (recordCount == 0) {
        clearIrrelevantFields(Logger.info('No matching EventLogFile records found').addTag(TAG_MONITORING));
      } else {
        Logger.info('Found ' + recordCount + ' matching EventLogFile records');
      }
      for (Schema.EventLogFile eventLogFile : this.queryRecords()) {
        // System.debug(eventLogFile.LogFile.toString());
        // System.debug('EventType: ' + eventLogFile.EventType);
        LogMessage logMessage = new LogMessage('Processing {0} event log file ID {1}', eventLogFile.EventType, eventLogFile.Id);
        clearIrrelevantFields(Logger.info(logMessage, eventLogFile.Id).addTag(TAG_MONITORING));

        this.log(eventLogFile);
      }
      Logger.saveLog();
      // return eventLogFiles;
    }

    private Integer queryRecordCount() {
      return [
        SELECT COUNT()
        FROM EventLogFile
        WHERE CreatedDate >= :this.getMinimumDate()
      ];
    }

    private List<Schema.EventLogFile> queryRecords() {
      // Interval, Sequence
      return [
        SELECT ApiVersion, CreatedById, CreatedDate, EventType, Id, LogDate, LogFile, LogFileContentType, LogFileFieldNames, LogFileFieldTypes, LogFileLength
        FROM EventLogFile
        WHERE CreatedDate >= :this.getMinimumDate()
      ];
    }

    private void log(Schema.EventLogFile eventLogFile) {
      // TODO use Dataweave
      List<String> logFileFieldNames = eventLogFile.LogFileFieldNames.split(',');
      List<String> logFileRows = eventLogFile.LogFile.toString().split('\n');
      System.debug('logFileRows: ' + System.JSON.serializePretty(logFileRows));
      Map<String, Map<String, Object>> untypedEventLogFiles = new Map<String, Map<String, Object>>();
      // Index starts at 1 instead of 0 so that the header row is skipped
      for (Integer i = 1; i < logFileRows.size(); i++) {
        String logFileRow = logFileRows.get(i);
        logFileRow = logFileRow.removeStart('"').removeEnd('"');
        List<String> columnValues = logFileRow.split('","');
        Map<String, Object> untypedEventLogFileRow = new Map<String, Object>();
        for (Integer j = 0; j < columnValues.size(); j++) {
          String columnName = logFileFieldNames.get(j);
          Object columnValue = columnValues.get(j);
          untypedEventLogFileRow.put(columnName, columnValue);
        }
        untypedEventLogFiles.put(String.valueOf(i), untypedEventLogFileRow);
        LogEntryEventBuilder logEntryEventBuilder = Logger.info(
          'Matching event log file entry\n\n' + System.JSON.serializePretty(untypedEventLogFileRow),
          eventLogFile.Id
        );
        Id userId = untypedEventLogFileRow.containsKey('USER_ID_DERIVED') ? (Id) untypedEventLogFileRow.get('USER_ID_DERIVED') : null;
        Datetime timestamp = untypedEventLogFileRow.containsKey('TIMESTAMP_DERIVED')
          ? (Datetime) System.JSON.deserialize((String) untypedEventLogFileRow.get('TIMESTAMP_DERIVED'), Datetime.class)
          : null;
        LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
      }
    }
  }

  private without sharing class IdentityProviderEventMonitor extends LoggerMonitor {
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(IdentityProviderEventMonitor.class);
      Logger.setScenario('Schema.' + Schema.IdpEventLog.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running IdpEventLog extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      Integer recordCount = this.queryRecordCount();
      if (recordCount == 0) {
        clearIrrelevantFields(Logger.info('No matching IdpEventLog records found').addTag(TAG_MONITORING));
      } else {
        Logger.info('Found ' + recordCount + ' matching IdpEventLog records');
      }
      for (IdpEventLog idpEventLog : this.queryRecords()) {
        clearIrrelevantFields(Logger.info('Matching IdpEventLog entry', IdpEventLog).addTag(TAG_MONITORING));
      }

      Logger.saveLog();
    }

    private Integer queryRecordCount() {
      return [
        SELECT COUNT()
        FROM IdpEventLog
        WHERE Timestamp >= :this.getMinimumDate()
      ];
    }

    // TODO https://developer.salesforce.com/docs/atlas.en-us.200.0.object_reference.meta/object_reference/sforce_api_objects_AsyncApexJob.htm
    private List<IdpEventLog> queryRecords() {
      return [
        SELECT
          Id,
          // CreatedById,
          // CreatedDate,
          AppId,
          // App.Label,
          // App.Name,
          AuthSessionId,
          ErrorCode,
          IdentityUsed,
          InitiatedBy,
          OptionsHasLogoutUrl,
          SamlEntityUrl,
          SsoType,
          Timestamp,
          UserId
        FROM IdpEventLog
        WHERE Timestamp >= :this.getMinimumDate()
      ];
    }
  }

  private without sharing class LightningToggleMetricsMonitor extends LoggerMonitor {
    // Source https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_lightning_togglemetrics.htm

    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return System.Type.forName('LightningToggleMetrics') != null;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(IdentityProviderEventMonitor.class);
      Logger.setScenario('Schema.' + Schema.IdpEventLog.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running IdpEventLog extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      Integer recordCount = this.queryRecordCount();
      if (recordCount == 0) {
        clearIrrelevantFields(Logger.info('No matching IdpEventLog records found').addTag(TAG_MONITORING));
      } else {
        Logger.info('Found ' + recordCount + ' matching IdpEventLog records');
      }
      for (IdpEventLog idpEventLog : this.queryRecords()) {
        clearIrrelevantFields(Logger.info('Matching IdpEventLog entry', IdpEventLog).addTag(TAG_MONITORING));
      }

      Logger.saveLog();
    }

    private Integer queryRecordCount() {
      // The object LightningToggleMetrics only exists in prod orgs (it's not present in scratch orgs or sandboxes),
      // so the query has to be done dynamically
      String query = 'SELECT COUNT() FROM LightningToggleMetrics WHERE MetricsDate >= :minimumDate';
      return System.Database.countQueryWithBinds(query, new Map<String, Object>{ 'minimumDate' => this.getMinimumDate() }, System.AccessLevel.USER_MODE);
    }

    // TODO https://developer.salesforce.com/docs/atlas.en-us.200.0.object_reference.meta/object_reference/sforce_api_objects_AsyncApexJob.htm
    private List<IdpEventLog> queryRecords() {
      // The object LightningToggleMetrics only exists in prod orgs (it's not present in scratch orgs or sandboxes),
      // so the query has to be done dynamically
      String query =
        'SELECT CoresBin2To4, CoresBin4To8, CoresBinOver8, CoresBinUnder2, DownlinkBin3To5, DownlinkBin5To8, DownlinkBin8To10, DownlinkBinOver10, ' +
        ' DownlinkBinUnder3, EptBin3To5, EptBin5To8, EptBin8To10, EptBinOver10, EptBinUnder3, FlexiPageNameOrId, FlexiPageType,' +
        ' Id, MedianEPT, MetricsDate, RecordCountEPT, RttBin50To150, RttBinOver150, RttBinUnder50, SumEPT, SystemModstamp, TotalCount' +
        ' FROM LightningToggleMetrics' +
        ' WHERE MetricsDate >= :minimumDate';
      return System.Database.queryWithBinds(query, new Map<String, Object>{ 'minimumDate' => this.getMinimumDate() }, System.AccessLevel.USER_MODE);
    }
  }

  private without sharing class OrgLimitsMonitor extends LoggerMonitor {
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(OrgLimitsMonitor.class);
      Logger.setScenario(System.OrgLimits.class.getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running OrgLimits extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      for (System.OrgLimit orgLimit : System.OrgLimits.getAll()) {
        Map<String, Object> limitAttributeToValue = new Map<String, Object>{
          'Limit' => orgLimit.getLimit(),
          'Name' => orgLimit.getName(),
          'Value' => orgLimit.getValue()
        };
        clearIrrelevantFields(Logger.info('Matching OrgLimit entry\n' + System.JSON.serializePretty(limitAttributeToValue)).addTag(TAG_MONITORING));
      }

      Logger.saveLog();
    }
  }

  private without sharing class PlatformEventsUsageMetricMonitor extends LoggerMonitor {
    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(PlatformEventsUsageMetricMonitor.class);
      Logger.setScenario('Schema.' + Schema.PlatformEventUsageMetric.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running PlatformEventUsageMetric extract with minimum date: ' + this.getMinimumDate()).addTag(TAG_MONITORING));

      Integer recordCount = this.queryRecordCount();
      if (recordCount == 0) {
        clearIrrelevantFields(Logger.info('No matching PlatformEventUsageMetric records found').addTag(TAG_MONITORING));
      } else {
        Logger.info('Found ' + recordCount + ' matching PlatformEventUsageMetric records');
      }
      for (PlatformEventUsageMetric platformEventUsageMetric : this.queryRecords()) {
        clearIrrelevantFields(Logger.info('Matching PlatformEventUsageMetric entry', platformEventUsageMetric).addTag(TAG_MONITORING));
      }

      Logger.saveLog();
    }

    // TODO https://developer.salesforce.com/docs/atlas.en-us.200.0.object_reference.meta/object_reference/sforce_api_objects_AsyncApexJob.htm
    private Integer queryRecordCount() {
      return [
        SELECT COUNT()
        FROM PlatformEventUsageMetric
        WHERE StartDate >= :this.getMinimumDate()
      ];
    }

    private List<PlatformEventUsageMetric> queryRecords() {
      return [
        SELECT EndDate, ExternalId, Id, Name, StartDate, Value
        FROM PlatformEventUsageMetric
        WHERE StartDate >= :this.getMinimumDate()
      ];
    }
  }

  private without sharing class ProcessApprovalMonitor extends LoggerRESTMonitor implements Database.AllowsCallouts {
    // Source: https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_record_count.htm
    // Or could be this? https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_approval.htm

    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(ProcessApprovalMonitor.class);
      Logger.setScenario('REST.Process.Approval'); //Schema.' + Schema.ApexLog.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running REST API Process Approval extract').addTag(TAG_MONITORING));

      String jobsEndpointUri = '/process/approvals';
      Boolean isDone = false;
      // while (isDone == false && Limits.getCallouts() <= Limits.getLimitCallouts()) {
      //     // TODO make additional callouts for each job....?
      //     // https://developer.salesforce.com/docs/atlas.en-us.242.0.api_asynch.meta/api_asynch/queries.htm
      // }
      // String queryString = 'SELECT '
      // while (System.Limits.getCallouts <= System.Limits.getLimitCallouts()) {
      System.HttpRequest request = this.createOrganizationHttpRequest(HttpVerb.GET, jobsEndpointUri);
      System.HttpResponse response = new System.Http().send(request);
      // RecordCountResponse recordCountResponse = (RecordCountResponse) System.JSON.deserialize(response.getBody(), RecordCountResponse.class);
      // TODO deserialize response.getBody() into a new DTO class
      Logger.info('Matching results for REST API Process Approvals') // System.JSON.serializePretty(recordCountResponse))
        .setHttpRequestDetails(request)
        .setHttpResponseDetails(response)
        .addTag(TAG_MONITORING);
      Logger.savelog();
      // }
    }
  }

  private without sharing class RecordCountMonitor extends LoggerRESTMonitor implements Database.AllowsCallouts {
    // Source: https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/resources_record_count.htm
    private Set<Id> apexLogIds = new Set<Id>();

    public override Boolean shouldRun() {
      // TODO add check on new LoggerParameter__mdt record
      return true;
    }

    public override void execute(System.QueueableContext queueableContext) {
      Logger.ignoreOrigin(RecordCountMonitor.class);
      Logger.setScenario('REST.Limits.RecordCounts'); //Schema.' + Schema.ApexLog.getSObjectType().getDescribe().getName() + ' Monitoring');
      clearIrrelevantFields(Logger.info('Running REST API Record Count extract').addTag(TAG_MONITORING));

      String jobsEndpointUri = '/limits/recordCount';
      Boolean isDone = false;
      // while (isDone == false && Limits.getCallouts() <= Limits.getLimitCallouts()) {
      //     // TODO make additional callouts for each job....?
      //     // https://developer.salesforce.com/docs/atlas.en-us.242.0.api_asynch.meta/api_asynch/queries.htm
      // }
      // String queryString = 'SELECT '
      // while (System.Limits.getCallouts <= System.Limits.getLimitCallouts()) {
      System.HttpRequest request = this.createOrganizationHttpRequest(HttpVerb.GET, jobsEndpointUri);
      System.HttpResponse response = new System.Http().send(request);
      RecordCountResponse recordCountResponse = (RecordCountResponse) System.JSON.deserialize(response.getBody(), RecordCountResponse.class);
      Logger.info('Matching results for REST API Record Counts').setHttpRequestDetails(request).setHttpResponseDetails(response).addTag(TAG_MONITORING);
      Logger.savelog();
      // }
    }
  }

  // private static void clearIrrelevantFields(LogEntryEvent__e logEntryEvent) {
  private static void clearIrrelevantFields(LogEntryEventBuilder eventBuilder) {
    LogEntryEvent__e logEntryEvent = eventBuilder.getLogEntryEvent();

    // logEntryEvent.ImpersonatedById__c = null;
    // logEntryEvent.LimitsAggregateQueriesMax__c = null;
    // logEntryEvent.LimitsAggregateQueriesUsed__c = null;
    // logEntryEvent.LimitsAggregateQueryMax__c = null;
    // logEntryEvent.LimitsAsyncCallsMax__c = null;
    // logEntryEvent.LimitsAsyncCallsUsed__c = null;
    // logEntryEvent.LimitsCalloutsMax__c = null;
    // logEntryEvent.LimitsCalloutsUsed__c = null;
    // logEntryEvent.LimitsCpuTimeMax__c = null;
    // logEntryEvent.LimitsCpuTimeUsed__c = null;
    // logEntryEvent.LimitsDmlRowsMax__c = null;
    // logEntryEvent.LimitsDmlRowsUsed__c = null;
    // logEntryEvent.LimitsDmlStatementsMax__c = null;
    // logEntryEvent.LimitsDmlStatementsUsed__c = null;
    // logEntryEvent.LimitsEmailInvocationsMax__c = null;
    // logEntryEvent.LimitsEmailInvocationsUsed__c = null;
    // logEntryEvent.LimitsFutureCallsMax__c = null;
    // logEntryEvent.LimitsFutureCallsUsed__c = null;
    // logEntryEvent.LimitsHeapSizeMax__c = null;
    // logEntryEvent.LimitsHeapSizeUsed__c = null;
    // logEntryEvent.LimitsMobilePushApexCallsMax__c = null;
    // logEntryEvent.LimitsMobilePushApexCallsUsed__c = null;
    // logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c = null;
    // logEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c = null;
    // logEntryEvent.LimitsQueueableJobsMax__c = null;
    // logEntryEvent.LimitsQueueableJobsUsed__c = null;
    // logEntryEvent.LimitsSoqlQueriesMax__c = null;
    // logEntryEvent.LimitsSoqlQueriesUsed__c = null;
    // logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c = null;
    // logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c = null;
    // logEntryEvent.LimitsSoqlQueryRowsMax__c = null;
    // logEntryEvent.LimitsSoqlQueryRowsUsed__c = null;
    // logEntryEvent.LimitsSoslSearchesMax__c = null;
    // logEntryEvent.LimitsSoslSearchesUsed__c = null;
    // logEntryEvent.Locale__c = null;
    // logEntryEvent.LoggedById__c = null;
    // logEntryEvent.LoggedByUsername__c = null;
    // logEntryEvent.LoginApplication__c = null;
    // logEntryEvent.LoginBrowser__c = null;
    // logEntryEvent.LoginHistoryId__c = null;
    // logEntryEvent.LoginPlatform__c = null;
    // logEntryEvent.LoginType__c = null;
    // logEntryEvent.LogoutUrl__c = null;
    // logEntryEvent.ProfileId__c = null;
    // logEntryEvent.ProfileName__c = null;
    // logEntryEvent.SessionId__c = null;
    // logEntryEvent.SessionSecurityLevel__c = null;
    // logEntryEvent.SessionType__c = null;
    // logEntryEvent.SourceIp__c = null;
    // logEntryEvent.ThemeDisplayed__c = null;
    // logEntryEvent.TimeZoneId__c = null;
    // logEntryEvent.TimeZoneName__c = null;
    // logEntryEvent.UserLicenseDefinitionKey__c = null;
    // logEntryEvent.UserLicenseId__c = null;
    // logEntryEvent.UserLicenseName__c = null;
    // logEntryEvent.UserRoleId__c = null;
    // logEntryEvent.UserRoleName__c = null;
    // logEntryEvent.UserType__c = null;
  }

  // DTO classes used for monitors that call the REST/Tooling API
  private class RecordCountResponse {
    public List<RecordCountDetail> sObjects { get; set; }
  }

  private class RecordCountDetail {
    public Integer count { get; set; }
    public String name { get; set; }
  }
}
