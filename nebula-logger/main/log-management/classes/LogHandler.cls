/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
public without sharing class LogHandler {
    private static Map<String, LogStatus__mdt> logStatusByName = getLogStatuses();

    private static Map<String, LogStatus__mdt> getLogStatuses() {
        Map<String, LogStatus__mdt> logStatusByName = new Map<String, LogStatus__mdt>();

        for (LogStatus__mdt logStatus : [
            SELECT Id, MasterLabel, IsClosed__c
            FROM LogStatus__mdt
            WHERE IsActive__c = TRUE
        ]) {
            logStatusByName.put(logStatus.MasterLabel, logStatus);
        }

        return logStatusByName;
    }

    public void execute() {
        List<Log__c> logs = (List<Log__c>) Trigger.new;
        Map<Id, Log__c> oldLogsById = (Map<Id, Log__c>) Trigger.oldMap;

        if (
            Trigger.operationType == TriggerOperation.BEFORE_INSERT ||
            Trigger.operationType == TriggerOperation.BEFORE_UPDATE
        ) {
            this.setIsClosed(logs);
        }

        if (Trigger.operationType == TriggerOperation.BEFORE_UPDATE) {
            this.setClosedDate(logs, oldLogsById);
            this.setPriority(logs, oldLogsById);
        }
    }

    private void setIsClosed(List<Log__c> logs) {
        for (Log__c log : logs) {
            LogStatus__mdt logStatus = logStatusByName.get(log.Status__c);

            if (logStatus == null) {
                continue;
            }

            log.IsClosed__c = logStatus.IsClosed__c;
        }
    }

    private void setClosedDate(List<Log__c> logs, Map<Id, Log__c> oldLogsById) {
        for (Log__c log : logs) {
            Log__c oldLog = oldLogsById.get(log.Id);

            if (log.IsClosed__c == false) {
                log.ClosedDate__c = null;
            } else if (log.IsClosed__c && oldLog.IsClosed__c == false) {
                log.ClosedDate__c = System.now();
            }
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
