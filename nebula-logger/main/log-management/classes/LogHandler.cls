//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Manages setting fields on `Log__c` before insert & before update
 */
public without sharing class LogHandler {
    private static final Organization ORGANIZATION = [SELECT Id, InstanceName, IsSandbox FROM Organization];

    @testVisible
    private static Map<String, LogStatus__mdt> logStatusByName;

    static {
        logStatusByName = new Map<String, LogStatus__mdt>();
        for (LogStatus__mdt logStatus : LogStatus__mdt.getAll().values()) {
            if (logStatus.IsActive__c == true) {
                logStatusByName.put(logStatus.MasterLabel, logStatus);
            }
        }
    }

    /**
     * @description Runs the trigger handler's logic
     */
    public void execute() {
        List<Log__c> logs = (List<Log__c>) Trigger.new;
        Map<Id, Log__c> oldLogsById = (Map<Id, Log__c>) Trigger.oldMap;

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                this.setOrgReleaseCycle(logs);
                this.setClosedStatusFields(logs);
                // The log retention date field should support being manually changed, so only auto-set it on insert
                this.setLogRetentionDate(logs);
            }
            when BEFORE_UPDATE {
                this.setClosedStatusFields(logs);
                // Priority logic relies on roll-up fields, so only run on update (after log entries are inserted)
                this.setPriority(logs, oldLogsById);
            }
            when AFTER_INSERT {
                this.shareLogsWithLoggingUsers(logs);
            }
        }
    }

    private void setOrgReleaseCycle(List<Log__c> logs) {
        // Currently, there doesn't seem to be a way within Apex or api.status.salesforce.com...
        // ...to know if your org is on a preview instance or non-preview instance
        // So, that unfortunately leaves hardcoding the instances for now
        // Source: https://www.salesforce.com/blog/spring-21-sandbox-preview/
        // And no need for this to be static since it's only used internally for BEFORE_INSERT context
        Set<String> previewInstances = new Set<String>{
            'CS2', 'CS4', 'CS5', 'CS7', 'CS9', 'CS11', 'CS14', 'CS15', 'CS17', 'CS19', 'CS20', 'CS21',
            'CS23', 'CS25', 'CS26', 'CS27', 'CS28', 'CS31', 'CS32', 'CS34', 'CS35', 'CS36', 'CS37', 'CS41',
            'CS42', 'CS44', 'CS45', 'CS47', 'CS53', 'CS57', 'CS59', 'CS61', 'CS63', 'CS67', 'CS69', 'CS72',
            'CS74', 'CS75', 'CS76', 'CS77', 'CS78', 'CS79', 'CS80', 'CS81', 'CS84', 'CS87', 'CS88', 'CS91',
            'CS95', 'CS96', 'CS97', 'CS99', 'CS105', 'CS106', 'CS107', 'CS108', 'CS109', 'CS111', 'CS112',
            'CS113', 'CS116', 'CS122', 'CS123', 'CS124', 'CS125', 'CS126', 'CS127', 'CS128', 'CS129', 'CS133',
            'CS137', 'CS138', 'CS142', 'CS152', 'CS159', 'CS160', 'CS169', 'CS174', 'CS189', 'CS190', 'CS191',
            'CS192', 'CS193', 'CS194', 'CS195', 'CS196', 'CS197', 'CS198', 'CS199', 'CS201', 'CS203', 'AUS2S',
            'AUS8S', 'IND3S', 'USA3S'
        };

        Set<String> nonPreviewInstances = new Set<String>{
            'CS1', 'CS6', 'CS8', 'CS10', 'CS16', 'CS18', 'CS22', 'CS24', 'CS29', 'CS33', 'CS40', 'CS43',
            'CS50', 'CS52', 'CS58', 'CS60', 'CS62', 'CS64', 'CS65', 'CS66', 'CS68', 'CS70', 'CS73', 'CS86',
            'CS89', 'CS90', 'CS92', 'CS94', 'CS98', 'CS100', 'CS101', 'CS102', 'CS110', 'CS114', 'CS115', 'CS117',
            'CS119', 'CS121', 'CS132', 'CS148', 'CS151', 'CS162', 'CS165', 'CS173', 'AUS4S', 'IND2S', 'USA2S'
        };

        String releaseCycle;
        if (ORGANIZATION.IsSandbox == false || nonPreviewInstances.contains(ORGANIZATION.InstanceName)) {
            releaseCycle = 'Non-Preview Instance';
        } else if (previewInstances.contains(ORGANIZATION.InstanceName)) {
            releaseCycle = 'Preview Instance';
        } else {
            // Use 'Unknown' as the default for private instances and situations where the hardcoded sets above are missing some values
            releaseCycle = 'Unknown';
        }

        for (Log__c log : logs) {
            log.OrganizationInstanceReleaseCycle__c = releaseCycle;
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

    private void shareLogsWithLoggingUsers(List<Log__c> logs) {
        // For each log record, share the record with the user that created the log (Log__c.LoggedBy__c)
        List<Log__Share> logShares = new List<Log__Share>();
        for (Log__c log : logs) {
            LoggerSettings__c loggingUserSettings = LoggerSettings__c.getInstance(log.LoggedBy__c);
            System.debug('loggingUserSettings==' + loggingUserSettings);

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
        List<Database.SaveResult> saveResults = Database.insert(logShares, false);
        System.debug('saveResults==' + saveResults);
    }
}
