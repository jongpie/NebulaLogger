//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages setting fields on `Log__c` before insert & before update
 */
public without sharing class LogHandler extends LoggerSObjectHandler {
    @TestVisible
    private static Map<String, LogStatus__mdt> logStatusByName = loadActiveLogStatuses();

    @TestVisible
    private List<Log__c> logs;
    @TestVisible
    private Map<Id, Log__c> oldLogsById;

    private static Map<String, LogStatus__mdt> loadActiveLogStatuses() {
        Map<String, LogStatus__mdt> logStatusByName = new Map<String, LogStatus__mdt>();
        for (LogStatus__mdt logStatus : LogStatus__mdt.getAll().values()) {
            if (logStatus.IsActive__c == true) {
                logStatusByName.put(logStatus.MasterLabel, logStatus);
            }
        }

        return logStatusByName;
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.Log__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.logs = (List<Log__c>) triggerNew;

        this.setClosedStatusFields();
        // The log retention date field should support being manually changed, so only auto-set it on insert
        this.setLogRetentionDate();
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.logs = (List<Log__c>) triggerNewMap.values();
        this.oldLogsById = (Map<Id, Log__c>) triggerOldMap;

        this.setClosedStatusFields();
        // Priority logic relies on roll-up fields, so only run on update (after log entries are inserted)
        this.setPriority();
    }

    protected override void executeAfterInsert(Map<Id, SObject> triggerNewMap) {
        this.logs = (List<Log__c>) triggerNewMap.values();

        this.shareLogsWithLoggingUsers();
    }

    private void setClosedStatusFields() {
        for (Log__c log : this.logs) {
            // Determine if the status is considered closed (based on `LogStatus__mdt` custom metadata)
            LogStatus__mdt logStatus = logStatusByName.get(log.Status__c);
            if (logStatus != null) {
                log.IsClosed__c = logStatus.IsClosed__c;
                log.IsResolved__c = logStatus.IsResolved__c;
            }

            // Now set the Closed By & Date fields based on IsClosed
            if (log.IsClosed__c == false) {
                log.ClosedBy__c = null;
                log.ClosedDate__c = null;
            } else {
                log.ClosedBy__c = log.ClosedBy__c == null ? UserInfo.getUserId() : log.ClosedBy__c;
                log.ClosedDate__c = log.ClosedDate__c == null ? System.now() : log.ClosedDate__c;
            }
        }
    }

    private void setLogRetentionDate() {
        for (Log__c log : this.logs) {
            // If the retention date has already been populated, leave it as-is
            if (log.LogRetentionDate__c != null) {
                continue;
            }

            // Load the logging user's settings
            User loggingUser = new User(Id = log.LoggedBy__c, ProfileId = log.ProfileId__c);
            LoggerSettings__c loggingUserSettings = Logger.getUserSettings(loggingUser);
            Integer daysToRetainLog = Integer.valueOf(loggingUserSettings.DefaultNumberOfDaysToRetainLogs__c);

            // When loggerSettings.DefaultNumberOfDaysToRetainLogs__c is null, assume that the log should be kept forever,
            // and set the retention date to null so that LogBatchPurger filters out/ignores the record
            log.LogRetentionDate__c = daysToRetainLog == null ? null : System.today().addDays(daysToRetainLog);
        }
    }

    private void setPriority() {
        List<PicklistEntry> picklistEntries = Schema.Log__c.Priority__c.getDescribe().getPicklistValues();

        // 3 assumptions
        //   1. Assume that that there will always be 3+ picklist values for the Priority__c field (out of the box, the values are: High, Medium, Low)
        //   2. Assume that not everyone will want those exact values, so dynamiclly get picklist entries (e.g., some orgs may instead use Critical, High, Medium, Low)
        //   3. Assume that the picklist entries are sorted in order of priority (not alphabetically, etc.)
        final String firstPriority = picklistEntries.get(0).getValue();
        final String secondPriority = picklistEntries.get(1).getValue();

        for (Log__c log : this.logs) {
            Log__c oldLog = this.oldLogsById.get(log.Id);

            if (log.TotalERRORLogEntries__c != oldLog.TotalERRORLogEntries__c && log.TotalERRORLogEntries__c > 0) {
                log.Priority__c = firstPriority;
            } else if (log.TotalWARNLogEntries__c != oldLog.TotalWARNLogEntries__c && log.TotalWARNLogEntries__c > 0) {
                log.Priority__c = secondPriority;
            }
        }
    }

    private void shareLogsWithLoggingUsers() {
        // For each log record, share the record with the user that created the log (Log__c.LoggedBy__c)
        List<Log__Share> logShares = new List<Log__Share>();
        for (Log__c log : this.logs) {
            // Anonymous logs don't have a user set for LoggedBy__c, so there's no one to share the record with
            if (log.LoggedBy__c == null) {
                continue;
            }

            // Load the logging user's settings
            User loggingUser = new User(Id = log.LoggedBy__c, ProfileId = log.ProfileId__c);
            LoggerSettings__c loggingUserSettings = Logger.getUserSettings(loggingUser);

            // Ignore blank and unsupported values
            if (loggingUserSettings.DefaultLogShareAccessLevel__c != 'Read' && loggingUserSettings.DefaultLogShareAccessLevel__c != 'Edit') {
                continue;
            }

            Log__Share logShare = new Log__Share(
                AccessLevel = loggingUserSettings.DefaultLogShareAccessLevel__c,
                ParentId = log.Id,
                RowCause = Schema.Log__Share.RowCause.LoggedByUser__c,
                UserOrGroupId = log.LoggedBy__c
            );
            logShares.add(logShare);
        }
        Database.insert(logShares, false);
    }
}
