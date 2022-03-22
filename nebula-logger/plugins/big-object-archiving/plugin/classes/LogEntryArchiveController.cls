//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

public with sharing class LogEntryArchiveController {
    @AuraEnabled
    public static List<LogEntryArchive__b> getLogEntryArchives() {
        // TODO add more fields, add support for filters (based on index),
        // add 'order by' or custom sorting (index limits which fields can be used in sort within SOQL)
        return [SELECT LoggedByUsername__c, LoggingLevel__c, Message__c FROM LogEntryArchive__b WITH SECURITY_ENFORCED];
    }
}
