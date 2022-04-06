import { LightningElement } from 'lwc';
import LOG_ENTRY_ARCHIVE_OBJECT from '@salesforce/schema/LogEntryArchive__b';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';

export default class LogEntryArchives extends LightningElement {
    logEntryArchives = [];
    _messageSearchTerm;
    _minimumLoggingLevelOrdinal;
    _schema = {};

    async connectedCallback() {
        await getSchemaForName({ sobjectApiName: 'LogEntryArchive__b' }).then(data => {
            console.log('schema data', data);
            this._schema = data;
            document.title = this._schema.labelPlural;
        });
        console.log('ze LOG_ENTRY_ARCHIVE_OBJECT', LOG_ENTRY_ARCHIVE_OBJECT);
        this._loadColumns();
        await this._loadLogEntryArchives();
    }

    get title() {
        const calculatedTitle = this.logEntryArchives.length + ' ' + this._schema.labelPlural;
        return calculatedTitle;
    }

    get loggingLevelOptions() {
        return [
            { label: '--Select Logging Level--', value: '' },
            { label: 'ERROR', value: '8' },
            { label: 'WARN', value: '7' },
            { label: 'INFO', value: '6' },
            { label: 'DEBUG', value: '5' },
            { label: 'FINE', value: '4' },
            { label: 'FINER', value: '3' },
            { label: 'FINEST', value: '2' }
        ];
    }

    handleLoggingLevelFilterChange(event) {
        console.log('log level filter change, event', event);
        console.log('log level filter change, event.target.value', event.target.value);
        const selectedLoggingLevelOrdinal = Number(event.target.value);
        console.log('log level filter change, selectedLoggingLevelOrdinal', selectedLoggingLevelOrdinal);
        this._minimumLoggingLevelOrdinal = selectedLoggingLevelOrdinal;
        this._loadLogEntryArchives();
    }

    handleSearch(event) {
        this._messageSearchTerm = event.target.value;
        this._loadLogEntryArchives();
    }

    handleRefresh() {
        const searchTerm = this.template.querySelector('lightning-input').value;
        console.info('refreshing, with searchTerm', searchTerm);
        this._loadLogEntryArchives(searchTerm);
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

    async _loadLogEntryArchives() {
        console.log('this._messageSearchTerm', this._messageSearchTerm);
        console.log('this._minimumLoggingLevelOrdinal', this._minimumLoggingLevelOrdinal);
        getLogEntryArchives({ messageSearchTerm: this._messageSearchTerm, minimumLoggingLevelOrdinal: this._minimumLoggingLevelOrdinal }).then(results => {
            this.logEntryArchives = JSON.parse(JSON.stringify(results));

            this.logEntryArchives.forEach(archive => {
                archive.compositeId = archive.TransactionId__c + archive.TransactionEntryNumber__c;
            });
            /* eslint-disable-next-line no-console */
            console.info('Loaded LogEntryArchive__b records', this.logEntryArchives);
        });
    }

    _loadColumns() {
        this.columns = [];

        const tableColumnNames = [
            'LoggedByUsername__c',
            'TransactionId__c',
            'TransactionEntryNumber__c',
            'LoggingLevel__c',
            'OriginType__c',
            'OriginLocation__c',
            'Message__c',
            'Timestamp__c'
        ];
        for (let i = 0; i < tableColumnNames.length; i++) {
            const field = this._schema.fields[tableColumnNames[i]];
            const column = {
                fieldName: field.localApiName,
                label: field.label,
                type: field.type.toLowerCase()
            };
            if (column.type === 'string') {
                column.type = 'text';
            }
            this.columns.push(column);
        }

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
