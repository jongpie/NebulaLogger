/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import getLogEntryEventSchema from '@salesforce/apex/LoggerSObjectMetadata.getLogEntryEventSchema';

export default class LogEntryEventStream extends LightningElement {
    unfilteredEvents = [];
    logEntryEvents = [];
    isExpanded = false;
    isStreamEnabled = true;

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

        getLogEntryEventSchema().then(result => {
            this._logEntryEventSchema = result;
            this._channel = '/event/' + this._logEntryEventSchema.apiName;

            this.createSubscription();
        });
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

    async createSubscription() {
        this._subscription = await subscribe(this._channel, -2, event => {
            const logEntryEvent = event.data.payload;
            // As of API v52.0 (Summer '21), platform events have a unique field, EventUUID
            // but it doesn't seem to be populated via empApi, so use a synthetic key instead
            logEntryEvent.key =
                logEntryEvent[this._logEntryEventSchema.fields.TransactionId__c.apiName] +
                '__' +
                logEntryEvent[this._logEntryEventSchema.fields.TransactionEntryNumber__c.apiName];
            this.unfilteredEvents.unshift(logEntryEvent);
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

    // onToggleExpand() {
    //     let consoleBlock = this.template.querySelector('[data-id="event-stream-console"]');
    //     consoleBlock.className = this.isExpanded ? '' : 'expanded';
    //     this.isExpanded = !this.isExpanded;
    // }

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
        return this._matchesTextFilter(this.loggedByFilter, logEntryEvent[this._logEntryEventSchema.fields.LoggedByUsername__c.apiName]);
    }

    _meetsLoggingLevelFilter(logEntryEvent) {
        let matches = false;
        if (
            !this.loggingLevelFilter ||
            Number(logEntryEvent[this._logEntryEventSchema.fields.LoggingLevelOrdinal__c.apiName]) >= Number(this.loggingLevelFilter)
        ) {
            matches = true;
        }
        return matches;
    }

    _meetsMessageFilter(logEntryEvent) {
        return this._matchesTextFilter(this.messageFilter, logEntryEvent[this._logEntryEventSchema.fields.Message__c.apiName]);
    }

    _meetsOriginLocationFilter(logEntryEvent) {
        return this._matchesTextFilter(this.originLocationFilter, logEntryEvent[this._logEntryEventSchema.fields.OriginLocation__c.apiName]);
    }

    _meetsOriginTypeFilter(logEntryEvent) {
        return this._matchesTextFilter(this.originTypeFilter, logEntryEvent[this._logEntryEventSchema.fields.OriginType__c.apiName]);
    }

    _meetsScenarioFilter(logEntryEvent) {
        return this._matchesTextFilter(this.scenarioFilter, logEntryEvent[this._logEntryEventSchema.fields.Scenario__c.apiName]);
    }

    _matchesTextFilter(filterCriteria = '', text = '') {
        let matches = false;
        if (!filterCriteria || text.includes(filterCriteria) || text.match(filterCriteria)) {
            matches = true;
        }
        return matches;
    }
}
