/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe } from 'lightning/empApi';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import isEnabled from '@salesforce/apex/LogEntryEventStreamController.isEnabled';
import getDatatableDisplayFields from '@salesforce/apex/LogEntryEventStreamController.getDatatableDisplayFields';
export default class LogEntryEventStream extends LightningElement {
    unfilteredEvents = [];

    logEntryEvents = [];
    isEnabled = true;
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
    datatableColumns = [];

    // Filters
    loggedByFilter;
    loggingLevelFilter;
    messageFilter;
    originTypeFilter;
    originLocationFilter;
    scenarioFilter;
    maxEventsToDisplay = 50;
    maxEventsToStream = 500;

    _logEntryEventSchema;
    _channel;
    _subscription = {};
    // Count of events delivered since the stream was most recently started
    _currentEventsDelivered = 0;
    // Count of events delivered to the component since it's been loaded
    _totalEventsDelivered = 0;

    async connectedCallback() {
        Promise.all([isEnabled(), getSchemaForName({ sobjectApiName: 'LogEntryEvent__e' }), getDatatableDisplayFields()])
            .then(([isEnabledResult, getSchemaForNameResult, getTableViewFieldsResult]) => {
                this.isEnabled = isEnabledResult;
                this._logEntryEventSchema = getSchemaForNameResult;
                this.tableViewDisplayFields = getTableViewFieldsResult;

                if (this.isEnabled) {
                    this._channel = '/event/' + this._logEntryEventSchema.apiName;
                    this.createSubscription();
                    this.loadDatatableColumns();
                }
            })
            .catch(this._handleError);
    }

    disconnectedCallback() {
        this.cancelSubscription();
    }

    get title() {
        let logEntryString = ' Matching Log Entry Events';
        let startingTitle = this.logEntryEvents.length + logEntryString + ' | ' + this._totalEventsDelivered + ' Total Streamed Events';
        // if (this.unfilteredEvents.length !== this.logEntryEvents.length) {
        //     startingTitle = this.logEntryEvents.length + ' matching results out of ' + this.unfilteredEvents.length + logEntryString;
        // }
        return startingTitle;
    }

    get eventDeliveryUsageSummary() {
        return this._currentEventsDelivered + ' Platform Events Delivered to Stream | ' + this.maxEventsToStream + ' Max Currently Configured';
    }

    get eventDeliveryPercent() {
        if (this._currentEventsDelivered === 0) {
            return 0;
        } else if (this._currentEventsDelivered >= this.maxEventsToStream) {
            return 100;
        }
        return (this._currentEventsDelivered / this.maxEventsToStream) * 100;
    }

    get eventDeliveryProgressVariant() {
        if (!this.isStreamEnabled) {
            return 'active-step';
        } else if (this.eventDeliveryPercent < 50) {
            return 'base';
        } else if (this.eventDeliveryPercent >= 50 && this.eventDeliveryPercent < 75) {
            return 'warning';
        }
        return 'expired';
    }

    get maxEventsToStreamHelp() {
        return (
            "Streaming platform events counts towards your org's daily allocation for Event Delivery." +
            ' \n\nTo minimize usage of the daily allocation, this field controls the max number of LogEntryEvent__e records to deliver to your stream before the stream auto-pauses.' +
            ' \n\nFor more information on platform event allocations, see https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm'
        );
    }

    get disabledWarningMessage() {
        return 'The log entry event stream has been disabled by an admin, using the record LoggerParameter__mdt.EnableLogEntryEventStream.';
    }

    get isDisabled() {
        return !this.isEnabled;
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

    loadDatatableColumns() {
        this.datatableColumns = [];
        if (!this.tableViewDisplayFields) {
            return;
        }

        this.tableViewDisplayFields.forEach(column => {
            const aField = this._logEntryEventSchema.fields[column];
            if (aField) {
                const formattedColumn = {
                    label: aField.label,
                    fieldName: aField.apiName,
                    type: aField.type
                };
                this.datatableColumns.push(formattedColumn);
            }
        });
    }

    async createSubscription() {
        this._currentEventsDelivered = 0;
        this._subscription = await subscribe(this._channel, -1, event => {
            if (!this.isStreamEnabled) {
                return;
            }

            if (this._currentEventsDelivered >= this.maxEventsToStream) {
                this.onToggleStream();
                return;
            }

            this._currentEventsDelivered++;
            this._totalEventsDelivered++;

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

    handleMaxEventsStreamedChange(event) {
        this.maxEventsToStream = event.target.value;
    }

    handleMaxEventsToDisplayChange(event) {
        this.maxEventsToDisplay = event.target.value;
        this._filterEvents();
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
        while (this.unfilteredEvents.length > this.maxEventsToDisplay) {
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
