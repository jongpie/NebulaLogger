import { LightningElement } from 'lwc';

export default class LoggerNotificationFilterBuilder extends LightningElement {
    filterConditions = [
        {
            fieldPathName: 'LoggingLevelOrdinal__c',
            operator: '>=',
            fieldValue: 6
        }
    ];
}
