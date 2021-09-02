import { LightningElement, track, api } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';

export default class LogEntryEventStreamer extends LightningElement {
    channel = '/event/LogEntryEvent__e'; // TODO need to support namespace in managed package
    loggingLevelFilter;
    messageFilter;
    maxEvents = 20;
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
            { label: 'ERROR', value: 'ERROR' },
            { label: 'WARN', value: 'WARN' },
            { label: 'INFO', value: 'INFO' },
            { label: 'DEBUG', value: 'DEBUG' },
            { label: 'FINE', value: 'FINE' },
            { label: 'FINER', value: 'FINER' },
            { label: 'FINEST', value: 'FINEST' }
        ];
    }

    connectedCallback() {
        this.createSubscription();
    }

    disconnectedCallback() {
        this.cancelSubscription();
    }

    createSubscription() {
        subscribe(this.channel, -1, this.messageCallback.bind(this)).then(response => {
            this._subscription = response;
        });
    }

    cancelSubscription() {
        unsubscribe(this._subscription);
    }

    handleLoggingLevelFilterChange(event) {
        this.handleLoggingLevelFilterChange = event.target.value;
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

    messageCallback = function (response) {
        let newEvent = response.data.payload;
        newEvent.key = newEvent.TransactionId__c + '__' + newEvent.TransactionEntryNumber__c;
        console.log('newEvent:', JSON.stringify(newEvent));
        // if (!this.messageFilter || newEvent.Message__c.includes(this.messageFilter)) {
            this.logEntryEvents.unshift(newEvent);
        // }
        while (this.logEntryEvents.length > this.maxEvents) {
            this.logEntryEvents.pop();
        }
        console.log('this.logEntryEvents:', JSON.stringify(this.logEntryEvents));
    };
}
