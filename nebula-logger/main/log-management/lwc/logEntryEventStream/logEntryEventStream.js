import { LightningElement, track, api } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';

export default class LogEntryEventStreamer extends LightningElement {
    channel = '/event/LogEntryEvent__e'; // TODO need to support namespace in managed package
    loggingLevelFilter;
    messageFilter;
    maxEvents = 50;
    logEntryEvents = [];
    isStreamEnabled = true;

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

    connectedCallback() {
        document.title = 'Log Entry Event Stream'
        this.createSubscription();
    }

    disconnectedCallback() {
        this.cancelSubscription();
    }

    createSubscription() {
        subscribe(this.channel, -1, this.subscriptionCallback.bind(this)).then(response => {
            this._subscription = response;
        });
    }

    cancelSubscription() {
        unsubscribe(this._subscription);
    }

    handleLoggingLevelFilterChange(event) {
        this.loggingLevelFilter = event.target.value;
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

    onToggleStream() {
        this.isStreamEnabled = !this.isStreamEnabled;
        if (this.isStreamEnabled) {
            createSubscription();
        } else {
            cancelSubscription();
        }
    }

    subscriptionCallback(response) {
        const newEvent = response.data.payload;
        // As of API v52.0 (Summer '21), platform events have a unique field, EventUUID
        // but it doesn't seem to be populated via empApi, so use a synthetic key instead
        newEvent.key = newEvent.TransactionId__c + '__' + newEvent.TransactionEntryNumber__c;

        console.log('newEvent:', JSON.stringify(newEvent));

        const updatedLogEntryEvents = [... this.logEntryEvents];
        if (this._meetsLoggingLevelFilter(newEvent) && this._meetsMessageFilter(newEvent)) {
            console.log('event meets filter criteria!');
            updatedLogEntryEvents.unshift(newEvent);
        }

        while (updatedLogEntryEvents.length > this.maxEvents) {
            updatedLogEntryEvents.pop();
        }
        this.logEntryEvents = updatedLogEntryEvents;
        console.log('this.logEntryEvents:', JSON.stringify(this.logEntryEvents));
    };

    // Private functions
    _meetsLoggingLevelFilter(logEntryEvent) {
        // TODO fix logging level filtering + comparison of oridinals
        if (!this.loggingLevelFilter || newEvent.LoggingLevelOrdinal__c >= Number(loggingLevelFilter)) {
            return true;
        } else {
            return false;
        }
    }

    _meetsMessageFilter(logEntryEvent) {
        // TODO support for regex searches in Message__c
        if (!this.messageFilter || logEntryEvent.Message__c.contains(this.messageFilter)) {
            return true;
        } else {
            return false;
        }
    }
}
