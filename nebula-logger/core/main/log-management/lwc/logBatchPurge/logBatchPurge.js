/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import getMetrics from '@salesforce/apex/LogBatchPurgeController.getMetrics';
import canUserRunLogBatchPurger from '@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger';
import getPurgeActionOptions from '@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions';
import runBatchPurge from '@salesforce/apex/LogBatchPurgeController.runBatchPurge';
import getBatchPurgeJobRecords from '@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords';

export default class LogBatchPurge extends LightningElement {
    // UI
    showLoadingSpinner = false;
    title = 'Log Batch Purge';

    // log  metrics
    logObjectSchema;
    logEntryObjectSchema;
    logEntryTagObjectSchema;

    metricsResult;
    metricsColumns = [];
    metricsRecords = [];
    purgeActionOptions;

    // Date filter options
    selectedDateFilterOption = 'TODAY';
    dateFilterOptions = [
        { label: 'Today', value: 'TODAY' },
        { label: 'This Week', value: 'THIS_WEEK' },
        { label: 'This Month', value: 'THIS_MONTH' }
    ];

    // Purge Batch
    purgeBatchColumns = [];
    purgeBatchJobRecords = [];
    disableRunPurgeButton;

    #pollingFrequency = 10000; // milliseconds

    connectedCallback() {
        this.selectedDateFilterOption = 'TODAY';

        this.loadMetricRecords();
        this.loadPurgeBatchColumns();
        this.loadPurgeBatchJobRecords();

        this.pollPurgeBatchJobRecords();
    }

    loadMetricRecords() {
        this.showLoadingSpinner = true;

        Promise.all([
            getMetrics({ dateFilterOption: this.selectedDateFilterOption }),
            getPurgeActionOptions(),
            getSchemaForName({ sobjectApiName: 'Log__c' }),
            getSchemaForName({ sobjectApiName: 'LogEntry__c' }),
            getSchemaForName({ sobjectApiName: 'LogEntryTag__c' })
        ])
            .then(([metricsResult, purgeActionOptionsResult, logObjectSchema, logEntryObjectSchema, logEntryTagObjectSchema]) => {
                this.metricsResult = metricsResult;
                this.purgeActionOptions = purgeActionOptionsResult;
                this.logObjectSchema = logObjectSchema;
                this.logEntryObjectSchema = logEntryObjectSchema;
                this.logEntryTagObjectSchema = logEntryTagObjectSchema;

                const METRIC_TEMPLATE = [
                    {
                        sObjectName: this.logObjectSchema.label,
                        sObjectApiName: 'Log__c',
                        rowSpan: this.purgeActionOptions.length + 1,
                        summary: []
                    },
                    {
                        sObjectName: this.logEntryObjectSchema.label,
                        sObjectApiName: 'LogEntry__c',
                        rowSpan: this.purgeActionOptions.length + 1,
                        summary: []
                    },
                    {
                        sObjectName: this.logEntryTagObjectSchema.label,
                        sObjectApiName: 'LogEntryTag__c',
                        rowSpan: this.purgeActionOptions.length + 1,
                        summary: []
                    }
                ];

                let records = [...METRIC_TEMPLATE];

                records.forEach(record => {
                    const aMetricRecord = metricsResult[record.sObjectApiName];
                    record.summary = this.purgeActionOptions.map(option => {
                        const summary = aMetricRecord.filter(item => item.LogPurgeAction__c === option.value);
                        return {
                            key: record.sObjectApiName + '-' + option.value,
                            purgeAction: option.value,
                            count: summary.length > 0 ? summary[0].expr0 : 0
                        };
                    });
                });
                this.metricsRecords = records;
                this.showLoadingSpinner = false;
            })
            .catch(this._handleError);
    }

    loadPurgeBatchColumns() {
        let columns = [
            { label: 'Job ID', fieldName: 'Id', initialWidth: 180 },
            { label: 'Job Type', fieldName: 'JobType', initialWidth: 170 },
            {
                label: 'Job Items Processed',
                fieldName: 'JobItemsProcessed',
                initialWidth: 180
            },
            {
                label: 'Number of Errors',
                fieldName: 'NumberOfErrors',
                initialWidth: 170
            },
            {
                label: 'Submitted On',
                fieldName: 'CreatedDate',
                type: 'date',
                initialWidth: 200,
                typeAttributes: {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: true
                }
            },
            {
                label: 'Submitted By',
                fieldName: 'CreatedByName',
                type: 'text',
                initialWidth: 150
            },
            { label: 'Status', fieldName: 'Status', type: 'text' }
        ];

        this.purgeBatchColumns = columns;
    }

    loadPurgeBatchJobRecords() {
        this.showLoadingSpinner = true;
        Promise.all([getBatchPurgeJobRecords(), canUserRunLogBatchPurger()])
            .then(([purgeBatchResult, canUserRunLogBatchPurgerAdHocResult]) => {
                this.disableRunPurgeButton = !canUserRunLogBatchPurgerAdHocResult;
                const formattedBatchJobRecords = purgeBatchResult.map(record => {
                    record.CreatedByName = record.CreatedBy.Name;
                    return record;
                });
                this.purgeBatchJobRecords = formattedBatchJobRecords;
                this.showLoadingSpinner = false;
            })
            .catch(this._handleError);
    }

    async runBatchPurge() {
        const confirmationResult = await LightningConfirm.open({
            label: 'Confirm Job Execution',
            message: 'Are you sure that you want to run LogBatchPurger? This will delete data!',
            theme: 'warning'
        });

        if (!confirmationResult) {
            return;
        }

        runBatchPurge()
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: `Purge Job ${result} submitted`,
                        variant: 'success'
                    })
                );
                this.loadPurgeBatchJobRecords();
            })
            .catch(this._handleError);
    }

    refreshPurgeBatchRecords() {
        this.loadPurgeBatchJobRecords();
    }

    onChangeDateFilter(event) {
        this.selectedDateFilterOption = event.detail.value;
        this.loadMetricRecords();
    }

    pollPurgeBatchJobRecords() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.loadPurgeBatchJobRecords();
            this.loadMetricRecords();
            this.pollPurgeBatchJobRecords();
        }, this.#pollingFrequency);
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
        this.showLoadingSpinner = false;
    };
}
