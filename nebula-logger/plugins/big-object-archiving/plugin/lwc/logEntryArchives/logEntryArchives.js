import { LightningElement } from 'lwc';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';

const COLUMNS = [
    { label: 'Logged By', fieldName: 'LoggedByUsername__c', type: 'text' },
    { label: 'Logging Level', fieldName: 'LoggingLevel__c', type: 'text' },
    { label: 'Transaction ID', fieldName: 'TransactionId__c', type: 'text' },
    { label: 'Transaction Entry Number', fieldName: 'TransactionEntryNumber__c', type: 'text' },
    { label: 'Message', fieldName: 'Message__c', type: 'text' },
    { label: 'Timestamp', fieldName: 'Timestamp__c', type: 'date' }
];
export default class LogEntryArchives extends LightningElement {
    logEntryArchives = [];

    get title() {
        const calculatedTitle = this.logEntryArchives.length + ' Log Entry Archives';
        document.title = calculatedTitle;
        return calculatedTitle;
    }

    async connectedCallback() {
        this._loadColumns();
        await this.loadLogEntryArchives();
    }

    async loadLogEntryArchives() {
        getLogEntryArchives().then(results => {
            this.logEntryArchives = JSON.parse(JSON.stringify(results));
            this.logEntryArchives.forEach(archive => {
                archive.syntheticId = archive.Timestamp__c + archive.LoggingLevelOrdinal__c + archive.TransactionId__c + archive.TransactionEntryNumber__c;
            });
            /* eslint-disable-next-line no-console */
            console.info('Loaded LogEntryArchive__b records', this.logEntryArchives);
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        /* eslint-disable-next-line default-case */
        switch (actionName) {
            case 'view':
                alert('TODO!');
                // this._viewCurrentRecord(row);
                break;
        }
    }

    _loadColumns() {
        this.columns = COLUMNS;

        // Append the row-level actions
        let tableRowActions = [{ label: 'View', name: 'view' }];
        this.columns.push({
            type: 'action',
            typeAttributes: {
                rowActions: tableRowActions,
                menuAlignment: 'auto'
            }
        });
    }
}
