/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class LogEntryHandler {
    
    public void execute() {
        this.setRelatedRecordLookupFields();
    }

    private void setRelatedRecordLookupFields() {
        if(!Trigger.isBefore) return;

        DescribeSObjectResult sobjectDescribe = Schema.LogEntry__c.SObjectType.getDescribe();
        for(LogEntry__c logEntry : (List<LogEntry__c>)Trigger.new) {
            // Skip the log entry if there's no related record ID
            if(logEntry.RelatedRecordId__c == null) continue;
    
            // Based on the related record ID, get the SObject Type
            Id relatedRecordId = (Id)logEntry.RelatedRecordId__c;
            logEntry.RelatedRecordType__c = String.valueOf(relatedRecordId.getSObjectType());
            
            // Based on the SObject Type, check for a matching field (based on naming convention of ObjectName == FieldName)
            String lookupFieldName = 'Nebula__' + (logEntry.RelatedRecordType__c.endsWith('__c') ? logEntry.RelatedRecordType__c : logEntry.RelatedRecordType__c + '__c');
            Schema.SObjectField lookupField = sobjectDescribe.fields.getMap().get(lookupFieldName);
            
            // If there's a lookup field, set it
            if(lookupField != null) logEntry.put(lookupField, relatedRecordId);
        }
    }

}