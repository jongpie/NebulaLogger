import { LightningElement } from 'lwc';

export default class LogEntryMetadataViewer extends LightningElement {

    get apexClassUrl() {
        const url = window.location + '/lightning/setup/ApexClasses/page?address=%2F' + this.logEntry?.ApexClassId__c;
        console.log('>>> url', url);
        return url;
    }

    handleOpenApexClass() {
        console.log('running handleOpenApexClass()', this.apexClassUrl);
        window.open(this.apexClassUrl, '_blank');
    }
}
