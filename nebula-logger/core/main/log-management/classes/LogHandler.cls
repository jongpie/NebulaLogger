//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages setting fields on `Log__c` before insert & before update
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public without sharing class LogHandler extends LoggerSObjectHandler {
    private static final Map<String, LogStatus__mdt> MOCK_LOG_STATUS_TO_STATUS = new Map<String, LogStatus__mdt>();

    @TestVisible
    private List<Log__c> logs;
    @TestVisible
    private Map<Id, Log__c> oldLogsById;
    private Map<Id, LoggerScenario__c> loggerScenariosById;

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.Log__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.logs = (List<Log__c>) triggerNew;
        this.loggerScenariosById = queryLoggerScenarios(this.logs);

        this.setHasCommentsField();
        this.setClosedStatusFields();
        // The log OwnerId field should support being manually changed, so only auto-set it on insert
        this.setOwnerId();
        this.setParentLog();
        // The log retention date field should support being manually changed, so only auto-set it on insert
        this.setLogRetentionDetails();
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.logs = (List<Log__c>) triggerNewMap.values();
        this.oldLogsById = (Map<Id, Log__c>) triggerOldMap;

        this.setHasCommentsField();
        this.setClosedStatusFields();
        // Priority logic relies on roll-up fields, so only run on update (after log entries are inserted)
        this.setPriority();
    }

    protected override void executeAfterInsert(Map<Id, SObject> triggerNewMap) {
        this.logs = (List<Log__c>) triggerNewMap.values();

        this.shareLogsWithLoggingUsers();
    }

    private void setHasCommentsField() {
        for (Log__c log : this.logs) {
            log.HasComments__c = String.isNotBlank(log.Comments__c);
        }
    }

    private void setClosedStatusFields() {
        Map<String, LogStatus__mdt> logStatusNameToStatus = loadActiveLogStatuses();
        for (Log__c log : this.logs) {
            // Determine if the status is considered closed (based on `LogStatus__mdt` custom metadata)
            LogStatus__mdt logStatus = logStatusNameToStatus.get(log.Status__c);
            if (logStatus != null) {
                log.IsClosed__c = logStatus.IsClosed__c;
                log.IsResolved__c = logStatus.IsResolved__c;
            }

            // Now set the Closed By & Date fields based on IsClosed
            if (log.IsClosed__c == false) {
                log.ClosedBy__c = null;
                log.ClosedDate__c = null;
            } else {
                log.ClosedBy__c = log.ClosedBy__c == null ? System.UserInfo.getUserId() : log.ClosedBy__c;
                log.ClosedDate__c = log.ClosedDate__c == null ? System.now() : log.ClosedDate__c;
            }
        }
    }

    private void setOwnerId() {
        // Loop through the logs and figure out what value has been configured as the default owner (if any)
        Map<Id, String> ownerNamesByLoggingUserId = new Map<Id, String>();
        List<Log__c> logsToUpdate = new List<Log__c>();
        for (Log__c log : this.logs) {
            String loggingUserDefaultLogOwner = getLoggingUserSettings(log).DefaultLogOwner__c;

            if (String.isBlank(loggingUserDefaultLogOwner)) {
                continue;
            } else if (loggingUserDefaultLogOwner instanceof Id) {
                log.OwnerId = Id.valueOf(loggingUserDefaultLogOwner);
            } else {
                ownerNamesByLoggingUserId.put(log.LoggedBy__c, loggingUserDefaultLogOwner);
                logsToUpdate.add(log);
            }
        }

        if (logsToUpdate.isEmpty()) {
            return;
        }

        // Populate OwnerId based on configured usernames
        Map<String, Id> ownerIdByOwnerName = new Map<String, Id>();
        ownerIdByOwnerName.putAll(queryQueues(ownerNamesByLoggingUserId.values()));
        ownerIdByOwnerName.putAll(queryUsers(ownerNamesByLoggingUserId.values()));

        for (Log__c log : logsToUpdate) {
            String loggingUserDefaultLogOwner = getLoggingUserSettings(log).DefaultLogOwner__c;
            if (ownerIdByOwnerName.containsKey(loggingUserDefaultLogOwner)) {
                log.OwnerId = ownerIdByOwnerName.get(loggingUserDefaultLogOwner);
            }
        }
    }

    private void setParentLog() {
        List<String> parentLogTransactionIds = new List<String>();
        for (Log__c log : this.logs) {
            if (String.isNotBlank(log.ParentLogTransactionId__c)) {
                parentLogTransactionIds.add(log.ParentLogTransactionId__c);
            }
        }

        if (parentLogTransactionIds.isEmpty()) {
            return;
        }

        Map<String, Id> parentLogTransactionIdToRecordId = new Map<String, Id>();
        for (Log__c parentLog : LogManagementDataSelector.getInstance().getLogsByTransactionId(parentLogTransactionIds)) {
            parentLogTransactionIdToRecordId.put(parentLog.TransactionId__c, parentLog.Id);
        }

        for (Log__c log : this.logs) {
            if (String.isNotBlank(log.ParentLogTransactionId__c)) {
                log.ParentLog__c = parentLogTransactionIdToRecordId.get(log.ParentLogTransactionId__c);
            }
        }
    }

    private void setLogRetentionDetails() {
        for (Log__c log : this.logs) {
            // If the retention date has already been populated, leave it as-is
            if (log.LogRetentionDate__c != null) {
                continue;
            }

            // Load the logging user's settings
            LoggerSettings__c loggingUserSettings = getLoggingUserSettings(log);

            // Load the configured scenario rule (if one exists)
            LoggerScenarioRule__mdt matchingScenarioRule;
            if (log.TransactionScenario__c != null) {
                LoggerScenario__c loggerScenario = this.loggerScenariosById.get(log.TransactionScenario__c);
                matchingScenarioRule = LoggerScenarioRule.getInstance(loggerScenario.UniqueId__c);
                if (
                    matchingScenarioRule != null &&
                    (matchingScenarioRule.IsLogRetentionOverrideEnabled__c == null ||
                    Boolean.valueOf(matchingScenarioRule.IsLogRetentionOverrideEnabled__c) != true)
                ) {
                    matchingScenarioRule = null;
                }
            }

            Integer daysToRetainLog = Integer.valueOf(
                matchingScenarioRule != null ? matchingScenarioRule.NumberOfDaysToRetainLogs__c : loggingUserSettings.DefaultNumberOfDaysToRetainLogs__c
            );
            // TODO Add new field to LoggerScenarioRule__mdt for setting the default log purge action (same concept as matchingScenarioRule.NumberOfDaysToRetainLogs__c above)

            // When daysToRetainLog is null, assume that the log should be kept forever,
            // and set the retention date to null so that LogBatchPurger filters out/ignores the record
            log.LogRetentionDate__c = daysToRetainLog == null ? null : System.today().addDays(daysToRetainLog);
            log.LogPurgeAction__c = loggingUserSettings.DefaultLogPurgeAction__c;
        }
    }

    private void setPriority() {
        List<Schema.PicklistEntry> picklistEntries = Schema.Log__c.Priority__c.getDescribe().getPicklistValues();

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
            LoggerSettings__c loggingUserSettings = getLoggingUserSettings(log);

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
        LoggerDataStore.getDatabase().insertRecords(logShares, false);
    }

    private static LoggerSettings__c getLoggingUserSettings(Log__c log) {
        User loggingUser = new User(Id = log.LoggedBy__c, ProfileId = log.ProfileId__c);
        return Logger.getUserSettings(loggingUser);
    }

    private static Map<String, LogStatus__mdt> loadActiveLogStatuses() {
        Map<String, LogStatus__mdt> logStatusNameToStatus = new Map<String, LogStatus__mdt>();
        for (LogStatus__mdt logStatus : LogStatus__mdt.getAll().values()) {
            if (logStatus.IsActive__c) {
                logStatusNameToStatus.put(logStatus.MasterLabel, logStatus);
            }
        }

        if (System.Test.isRunningTest()) {
            logStatusNameToStatus.clear();
            logStatusNameToStatus.putAll(MOCK_LOG_STATUS_TO_STATUS);
        }

        return logStatusNameToStatus;
    }

    private static Map<Id, LoggerScenario__c> queryLoggerScenarios(List<Log__c> logs) {
        List<Id> loggerScenarioIds = new List<Id>();
        for (Log__c log : logs) {
            if (log.TransactionScenario__c != null) {
                loggerScenarioIds.add(log.TransactionScenario__c);
            }
        }

        Map<Id, LoggerScenario__c> loggerScenariosById = new Map<Id, LoggerScenario__c>();

        if (loggerScenarioIds.isEmpty()) {
            return loggerScenariosById;
        }

        List<LoggerScenario__c> matchingLoggerScenarios = LogManagementDataSelector.getInstance().getLoggerScenariosById(loggerScenarioIds);
        if (matchingLoggerScenarios != null && matchingLoggerScenarios.isEmpty() == false) {
            loggerScenariosById = new Map<Id, LoggerScenario__c>(matchingLoggerScenarios);
        }
        return loggerScenariosById;
    }

    private static Map<String, Id> queryQueues(List<String> possibleQueueNames) {
        Map<String, Id> queuesByDeveloperName = new Map<String, Id>();
        for (Group queue : LogManagementDataSelector.getInstance().getQueuesByDeveloperName(possibleQueueNames)) {
            queuesByDeveloperName.put(queue.DeveloperName, queue.Id);
        }
        return queuesByDeveloperName;
    }

    private static Map<String, Id> queryUsers(List<String> possibleUsernames) {
        Map<String, Id> usersByUsername = new Map<String, Id>();
        for (User user : LogManagementDataSelector.getInstance().getUsersByUsername(possibleUsernames)) {
            usersByUsername.put(user.Username, user.Id);
        }
        return usersByUsername;
    }

    @TestVisible
    private static void setMockLogStatus(LogStatus__mdt logStatus) {
        MOCK_LOG_STATUS_TO_STATUS.put(logStatus.MasterLabel, logStatus);
    }
}
