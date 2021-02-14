/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
public without sharing class LogHandler {
    @testVisible
    private static Map<String, LogStatus__mdt> logStatusByName;

    static {
        logStatusByName = new Map<String, LogStatus__mdt>();

        // TODO replace query with new Spring '21 method getAll()
        for (LogStatus__mdt logStatus : [SELECT MasterLabel, IsClosed__c, IsResolved__c FROM LogStatus__mdt WHERE IsActive__c = TRUE]) {
            logStatusByName.put(logStatus.MasterLabel, logStatus);
        }
    }

    public void execute() {
        List<Log__c> logs = (List<Log__c>) Trigger.new;
        Map<Id, Log__c> oldLogsById = (Map<Id, Log__c>) Trigger.oldMap;

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.setClosedStatusFields(logs);
                // The log retention date field should support being manually changed, so only auto-set it on insert
                this.setLogRetentionDate(logs);
            }
            when BEFORE_UPDATE {
                this.setClosedStatusFields(logs);
                // Priority logic relies on roll-up fields, so only run on update (after log entries are inserted)
                this.setPriority(logs, oldLogsById);
            }
        }
    }

    private void setClosedStatusFields(List<Log__c> logs) {
        for (Log__c log : logs) {
            // Determine if the status is considered closed
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

    private void setLogRetentionDate(List<Log__c> logs) {
        for (Log__c log : logs) {
            // If the retention date has already been populated, leave it as-is
            if (log.LogRetentionDate__c != null) {
                continue;
            }

            LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance(log.LoggedBy__c);
            Integer daysToRetainLog = Integer.valueOf(loggerSettings.DefaultNumberOfDaysToRetainLogs__c);

            // When loggerSettings.DefaultNumberOfDaysToRetainLogs__c is null, assume that the log should be kept forever,
            // ...and set the retention date to null so that LogBatchPurger filters out/ignores the record
            log.LogRetentionDate__c = daysToRetainLog == null ? null : System.today().addDays(daysToRetainLog);
        }
    }

    private void setPriority(List<Log__c> logs, Map<Id, Log__c> oldLogsById) {
        List<PicklistEntry> picklistEntries = Schema.Log__c.Priority__c.getDescribe().getPicklistValues();

        // 4 assumptions
        //   1. Assume that that out of the box, picklist values are High, Medium, Low
        //   2. Assume that not everyone will want those exact values, so dynamiclly get picklist entries
        //   3. Assume that the picklist entries are sorted in order of priority (not alphabetically, etc.)
        //   4. Assume that there will always be 2+ values
        final String HIGH = picklistEntries.get(0).getValue();
        final String MEDIUM = picklistEntries.get(1).getValue();

        for (Log__c log : logs) {
            Log__c oldLog = oldLogsById.get(log.Id);

            if (log.TotalERRORLogEntries__c != oldLog.TotalERRORLogEntries__c && log.TotalERRORLogEntries__c > 0) {
                log.Priority__c = HIGH;
            } else if (log.TotalWARNLogEntries__c != oldLog.TotalWARNLogEntries__c && log.TotalWARNLogEntries__c > 0) {
                log.Priority__c = MEDIUM;
            }
        }
    }
}
