LoggerOpenTelemetryConverter.ResourceLog otelResourceLog = new LoggerOpenTelemetryConverter.ResourceLog();
System.debug('>>> start: ' + JSON.serializePretty(otelResourceLog));

// Add org details here, like org ID, org Name
LoggerOpenTelemetryConverter.Attribute orgIdAttribute = new LoggerOpenTelemetryConverter.Attribute(
    'Log__c.OrganizationId__c',
    LoggerOpenTelemetryConverter.AttributeType.stringValue,
    System.UserInfo.getOrganizationId()
);
otelResourceLog.resource.attributes.add(orgIdAttribute);

// Add other Log__c and LogEntry__c data here
Datetime timestamp = System.now();
LogEntry__c logEntry = new LogEntry__c(
    EpochTimestamp__c = timestamp.getTime(),
    LimitsCalloutsMax__c = 99,
    LoggingLevel__c = System.LoggingLevel.FINE.name(),
    Message__c = 'some message',
    OriginLocation__c = 'Some.Origin',
    OriginSourceMetadataType__c = 'ApexClass'
);

LoggerOpenTelemetryConverter.LogRecord otelLogRecord = new LoggerOpenTelemetryConverter.LogRecord();
LoggerOpenTelemetryConverter.OpenTelemetryLoggingLevel otelLoggingLevel = LoggerOpenTelemetryConverter.convertLoggingLevel(System.LoggingLevel.valueOf(logEntry.LoggingLevel__c));
// TOOD LoggingLevel data in Apex won't map directly to OTel's values - https://opentelemetry.io/docs/specs/otel/logs/data-model/
// otelLogRecord.severityNumber = logEntry.LoggingLevelOrdinal__c?.intValue();
// otelLogRecord.severityText = logEntry.LoggingLevel__c;

otelLogRecord.body = new Map<String, String>{LoggerOpenTelemetryConverter.AttributeType.stringValue.name() => logEntry.Message__c };
otelLogRecord.severityNumber = otelLoggingLevel.SeverityNumber;
otelLogRecord.severityText = otelLoggingLevel.SeverityText;
otelLogRecord.timeUnixNano = String.valueOf(logEntry.EpochTimestamp__c) + '000000';
List<Schema.SObjectField> logEntryAttributeFields = new List<Schema.SObjectField>{LogEntry__c.LimitsCalloutsMax__c, LogEntry__c.OriginLocation__c, LogEntry__c.OriginSourceMetadataType__c};
for (Schema.SObjectField field : logEntryAttributeFields) {
    otelLogRecord.attributes.add(new LoggerOpenTelemetryConverter.Attribute(
        field.getDescribe().getSObjectType().getDescribe().getName() + '.' + field.getDescribe().getName(),
        LoggerOpenTelemetryConverter.getAttributeType(field.getDescribe().getSoapType()),
        logEntry.get(field).toString()
    ) );
}

LoggerOpenTelemetryConverter.ScopeLog otelScopeLog = new LoggerOpenTelemetryConverter.ScopeLog();
otelScopeLog.logRecords.add(otelLogRecord);
otelResourceLog.scopeLogs.add(otelScopeLog);

System.debug('>>> end: ' + JSON.serializePretty(otelResourceLog));
