/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe } from 'lightning/empApi';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import getDataTableDisplayFields from '@salesforce/apex/LogEntryEventStreamController.getDataTableDisplayFields';
export default class LogEntryEventStream extends LightningElement {
    unfilteredEvents = [];

    logEntryEvents = [];
    isExpanded = false;
    isStreamEnabled = true;
    isStreamSettingExpanded = true;
    isConsoleViewEnabled = true;
    selectViewMenuIcon = 'utility:apex'; //default console view
    selectViewMenuOptions = [
        {
            id: 'console-view',
            iconName: 'utility:apex',
            label: 'Console',
            value: 'console',
            checked: true //default console view enabled.
        },
        {
            id: 'table-view',
            iconName: 'utility:table',
            label: 'Table',
            value: 'table',
            checked: false
        }
    ];

    //data table
    tableViewDisplayFields = [];
    DEFAULT_DATATABLE_COLUMNS = ['Timestamp__c', 'LoggedByUsername__c', 'OriginLocation__c', 'LoggingLevel__c', 'Message__c'];
    dataTableColumns = [];

    // Filters
    loggedByFilter;
    loggingLevelFilter;
    messageFilter;
    originTypeFilter;
    originLocationFilter;
    scenarioFilter;
    maxEvents = 50;

    _logEntryEventSchema;
    _channel;
    _subscription = {};

    async connectedCallback() {
        document.title = 'Log Entry Event Stream';

        Promise.all([getSchemaForName({ sobjectApiName: 'LogEntryEvent__e' }), getDataTableDisplayFields()])
            .then(([getSchemaForNameResult, getTableViewFieldsResult]) => {
                this._logEntryEventSchema = getSchemaForNameResult;
                this.tableViewDisplayFields = getTableViewFieldsResult;
                this._channel = '/event/' + this._logEntryEventSchema.apiName;
                this.createSubscription();
                this.loadDataTableColumns();
            })
            .catch(this._handleError);
    }

    loadDataTableColumns() {
        this.dataTableColumns = [];
        if (this.tableViewDisplayFields) {
            this.tableViewDisplayFields.forEach(column => {
                const aField = this._logEntryEventSchema.fields[column];
                if (aField) {
                    const formattedColumn = {
                        label: aField.label,
                        fieldName: aField.apiName,
                        type: aField.type
                    };
                    this.dataTableColumns.push(formattedColumn);
                }
            });
        }
    }

    disconnectedCallback() {
        this.cancelSubscription();
    }

    get title() {
        let logEntryString = ' Log Entry Events';
        let startingTitle = this.logEntryEvents.length + logEntryString;
        if (this.unfilteredEvents.length !== this.logEntryEvents.length) {
            startingTitle = this.logEntryEvents.length + ' matching results out of ' + this.unfilteredEvents.length + logEntryString;
        }
        return startingTitle;
    }

    get streamButtonVariant() {
        return this.isStreamEnabled ? 'success' : 'brand';
    }

    get loggingLevelOptions() {
        return [
            { label: '--SELECT--', value: '' },
            { label: 'ERROR', value: '8' },
            { label: 'WARN', value: '7' },
            { label: 'INFO', value: '6' },
            { label: 'DEBUG', value: '5' },
            { label: 'FINE', value: '4' },
            { label: 'FINER', value: '3' },
            { label: 'FINEST', value: '2' }
        ];
    }

    get originTypeOptions() {
        return [
            { label: '--SELECT--', value: '' },
            { label: 'Apex', value: 'Apex' },
            { label: 'Component', value: 'Component' },
            { label: 'Flow', value: 'Flow' }
        ];
    }

    get splitViewLabel() {
        return this.isStreamSettingExpanded ? 'Close Split View' : 'Open Split View';
    }

    async createSubscription() {
        this._subscription = await subscribe(this._channel, -2, event => {
            const logEntryEvent = JSON.parse(JSON.stringify(event.data.payload));
            let cleanedLogEntryEvent;
            if (!this._logEntryEventSchema.namespacePrefix) {
                cleanedLogEntryEvent = logEntryEvent;
            } else {
                // To handle the namespaced managed package, convert all of the field API names from the fully-qualified name (that includes the namespace)
                // to instead use just the local field name
                // Example: `Nebula__LoggingLevel__c` becomes `LoggingLevel__c`
                // This makes it easier for the rest of the code in this lwc to just reference the field without worrying about if there is a namespace
                cleanedLogEntryEvent = {};
                Object.keys(logEntryEvent).forEach(eventFieldApiName => {
                    const localFieldApiName = eventFieldApiName.replace(this._logEntryEventSchema.namespacePrefix, '');
                    cleanedLogEntryEvent[localFieldApiName] = logEntryEvent[eventFieldApiName];
                });
            }

            // As of API v52.0 (Summer '21), platform events have a unique field, EventUUID
            // but it doesn't seem to be populated via empApi, so use a synthetic key instead
            cleanedLogEntryEvent.key = cleanedLogEntryEvent.TransactionId__c + '__' + cleanedLogEntryEvent.TransactionEntryNumber__c;
            this.unfilteredEvents.unshift(cleanedLogEntryEvent);
            this._filterEvents();
        });
    }

    cancelSubscription() {
        unsubscribe(this._subscription);
    }

    handleFilterChange(event) {
        this[event.target.dataset.id] = event.target.value;
        this._filterEvents();
    }

    handleMaxEventsChange(event) {
        this.maxEvents = event.target.value;
    }

    onClear() {
        this.logEntryEvents = [];
        this.unfilteredEvents = [];
    }

    onToggleExpand() {
        let consoleBlock = this.template.querySelector('[data-id="event-stream-console"]');
        consoleBlock.className = this.isExpanded ? 'slds-card ' : 'slds-card expanded';
        this.isExpanded = !this.isExpanded;
    }

    onSelectView(event) {
        const selectedView = event.detail.value;
        let selectedViewOption = this.selectViewMenuOptions.filter(action => action.value === selectedView);
        this.selectViewMenuOptions = this.selectViewMenuOptions.map(action => {
            action.checked = action.value === selectedView ? true : false;
            return action;
        });
        this.selectViewMenuIcon = selectedViewOption[0].iconName;
        this.isConsoleViewEnabled = selectedView === 'console' ? true : false;
    }

    onToggleSplitView() {
        const splitViewContainerElement = this.template.querySelector('[data-id="split-view-container"');
        const splitViewToggleButtonElement = this.template.querySelector('[data-id="split-view-button"');
        this.isStreamSettingExpanded = !this.isStreamSettingExpanded;
        if (this.isStreamSettingExpanded) {
            splitViewContainerElement.classList.replace('slds-is-closed', 'slds-is-open');
            splitViewToggleButtonElement.classList.replace('slds-is-closed', 'slds-is-open');
        } else {
            splitViewContainerElement.classList.replace('slds-is-open', 'slds-is-closed');
            splitViewToggleButtonElement.classList.replace('slds-is-open', 'slds-is-closed');
        }
    }

    onToggleStream() {
        this.isStreamEnabled = !this.isStreamEnabled;
        // eslint-disable-next-line
        this.isStreamEnabled ? this.createSubscription() : this.cancelSubscription();
    }

    // Private functions
    _filterEvents() {
        while (this.unfilteredEvents.length > this.maxEvents) {
            this.unfilteredEvents.pop();
        }

        this.logEntryEvents = this.unfilteredEvents.filter(
            logEntryEvent =>
                this._meetsLoggedByFilter(logEntryEvent) &&
                this._meetsLoggingLevelFilter(logEntryEvent) &&
                this._meetsMessageFilter(logEntryEvent) &&
                this._meetsOriginLocationFilter(logEntryEvent) &&
                this._meetsOriginTypeFilter(logEntryEvent) &&
                this._meetsScenarioFilter(logEntryEvent)
        );
    }

    _meetsLoggedByFilter(logEntryEvent) {
        return this._matchesTextFilter(this.loggedByFilter, logEntryEvent.LoggedByUsername__c);
    }

    _meetsLoggingLevelFilter(logEntryEvent) {
        let matches = false;
        if (!this.loggingLevelFilter || Number(logEntryEvent.LoggingLevelOrdinal__c) >= Number(this.loggingLevelFilter)) {
            matches = true;
        }
        return matches;
    }

    _meetsMessageFilter(logEntryEvent) {
        return this._matchesTextFilter(this.messageFilter, logEntryEvent.Message__c);
    }

    _meetsOriginLocationFilter(logEntryEvent) {
        return this._matchesTextFilter(this.originLocationFilter, logEntryEvent.OriginLocation__c);
    }

    _meetsOriginTypeFilter(logEntryEvent) {
        return this._matchesTextFilter(this.originTypeFilter, logEntryEvent.OriginType__c);
    }

    _meetsScenarioFilter(logEntryEvent) {
        return this._matchesTextFilter(this.scenarioFilter, logEntryEvent.TransactionScenario__c);
    }

    _matchesTextFilter(filterCriteria = '', text = '') {
        let matches = false;
        if (!filterCriteria || text.includes(filterCriteria) || text.match(filterCriteria)) {
            matches = true;
        }
        return matches;
    }
    _handleError = error => {
        const errorMessage = error.body ? error.body.message : error.message;
        /* eslint-disable-next-line no-console */
        console.error(errorMessage, error);
        this.dispatchEvent(
            new ShowToastEvent({
                mode: 'sticky',
                title: errorMessage,
                variant: 'error'
            })
        );
    };
}
