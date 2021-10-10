import { LightningElement } from 'lwc';
import { isEmpEnabled, subscribe, unsubscribe } from 'lightning/empApi';

export default class LogEntryEventStream extends LightningElement {
    logEntryEvents = [];
    isExpanded = false;
    isStreamEnabled = true;

    // Filters
    loggedByFilter;
    loggingLevelFilter;
    messageFilter;
    originTypeFilter;
    originLocationFilter;
    maxEvents = 50;

    _channel = '/event/LogEntryEvent__e'; // TODO need to support namespace in managed package
    _subscription = {};

    get title() {
        return this.logEntryEvents.length + ' Log Entry Events';
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

    async connectedCallback() {
        document.title = 'Log Entry Event Stream';
        if (isEmpEnabled()) {
            this.createSubscription();
        }
    }

    disconnectedCallback() {
        this.cancelSubscription();
    }

    createSubscription() {
        subscribe(this._channel, -1, this.subscriptionCallback.bind(this)).then(response => {
            this._subscription = response;
        });
    }

    cancelSubscription() {
        unsubscribe(this._subscription);
    }

    handleLoggingLevelFilterChange(event) {
        this.loggingLevelFilter = event.target.value;
    }

    handleOriginTypeFilterChange(event) {
        this.originTypeFilter = event.target.value;
    }

    handleOriginLocationFilterChange(event) {
        this.originLocationFilter = event.target.value;
    }

    handleLoggedByFilterChange(event) {
        this.loggedByFilter = event.target.value;
    }

    handleMessageFilterChange(event) {
        this.messageFilter = event.target.value;
    }

    handleMaxEventsChange(event) {
        this.maxEvents = event.target.value;
    }

    onClear() {
        this.logEntryEvents = [];
    }

    // onToggleExpand() {
    //     let consoleBlock = this.template.querySelector('[data-id="event-stream-console"]');
    //     consoleBlock.className = this.isExpanded ? '' : 'expanded';
    //     this.isExpanded = !this.isExpanded;
    // }

    onToggleStream() {
        this.isStreamEnabled = !this.isStreamEnabled;
        if (this.isStreamEnabled) {
            this.createSubscription();
        } else {
            this.cancelSubscription();
        }
    }

    subscriptionCallback(response) {
        const logEntryEvent = response.data.payload;
        // As of API v52.0 (Summer '21), platform events have a unique field, EventUUID
        // but it doesn't seem to be populated via empApi, so use a synthetic key instead
        logEntryEvent.key = logEntryEvent.TransactionId__c + '__' + logEntryEvent.TransactionEntryNumber__c;

        const updatedLogEntryEvents = [...this.logEntryEvents];

        if (
            this._meetsLoggedByFilter(logEntryEvent) &&
            this._meetsLoggingLevelFilter(logEntryEvent) &&
            this._meetsMessageFilter(logEntryEvent) &&
            this._meetsOriginLocationFilter(logEntryEvent) &&
            this._meetsOriginTypeFilter(logEntryEvent)
        ) {
            updatedLogEntryEvents.unshift(logEntryEvent);
        }

        while (updatedLogEntryEvents.length > this.maxEvents) {
            updatedLogEntryEvents.pop();
        }
        this.logEntryEvents = updatedLogEntryEvents;
    }

    // Private functions
    _meetsLoggedByFilter(logEntryEvent) {
        let matches = false;
        if (!this.loggedByFilter || logEntryEvent.LoggedByUsername__c.includes(this.loggedByFilter)) {
            matches = true;
        }
        return matches;
    }

    _meetsLoggingLevelFilter(logEntryEvent) {
        let matches = false;
        if (!this.loggingLevelFilter || Number(logEntryEvent.LoggingLevelOrdinal__c) >= Number(this.loggingLevelFilter)) {
            matches = true;
        }
        return matches;
    }

    _meetsMessageFilter(logEntryEvent) {
        // TODO support for regex searches in Message__c
        let matches = false;
        if (!this.messageFilter || logEntryEvent.Message__c.includes(this.messageFilter)) {
            matches = true;
        }
        return matches;
    }

    _meetsOriginLocationFilter(logEntryEvent) {
        // TODO support for regex searches in OriginLocation__c
        let matches = false;
        if (!this.originLocationFilter || logEntryEvent.OriginLocation__c.includes(this.originLocationFilter)) {
            matches = true;
        }
        return matches;
    }

    _meetsOriginTypeFilter(logEntryEvent) {
        // TODO support for regex searches in Message__c
        let matches = false;
        if (!this.originTypeFilter || logEntryEvent.OriginType__c === this.originTypeFilter) {
            matches = true;
        }
        return matches;
    }
}
