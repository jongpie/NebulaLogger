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

const POLLING_FREQUENCY_MS = 10000;
const TRACKED_OBJECTS = ['Log__c', 'LogEntry__c', 'LogEntryTag__c'];

export default class LogBatchPurge extends LightningElement {
  showLoadingSpinner = false;
  title = 'Log Batch Purge';

  metricsRecords = [];
  purgeActionOptions = [];

  selectedDateFilterOption = 'TODAY';
  dateFilterOptions = [
    { label: 'Today', value: 'TODAY' },
    { label: 'This Week', value: 'THIS_WEEK' },
    { label: 'This Month', value: 'THIS_MONTH' }
  ];

  purgeBatchColumns = [];
  purgeBatchJobRecords = [];
  // Default to disabled until canUserRunLogBatchPurger() resolves — a destructive
  // button must never be enabled before its permission check completes.
  disableRunPurgeButton = true;

  #objectSchemasByApiName = {};

  connectedCallback() {
    this.purgeBatchColumns = this._buildPurgeBatchColumns();
    this._initialize();
  }

  async _initialize() {
    this.showLoadingSpinner = true;
    try {
      const [purgeActionOptions, ...schemas] = await Promise.all([
        getPurgeActionOptions(),
        ...TRACKED_OBJECTS.map(sobjectApiName => getSchemaForName({ sobjectApiName }))
      ]);
      this.purgeActionOptions = purgeActionOptions;
      TRACKED_OBJECTS.forEach((apiName, index) => {
        this.#objectSchemasByApiName[apiName] = schemas[index];
      });

      await Promise.all([this._loadMetricRecords(), this._loadPurgeBatchJobRecords()]);
    } catch (error) {
      this._handleError(error);
    } finally {
      this.showLoadingSpinner = false;
      this._scheduleNextPoll();
    }
  }

  async _loadMetricRecords() {
    const metricsResult = await getMetrics({ dateFilterOption: this.selectedDateFilterOption });

    this.metricsRecords = TRACKED_OBJECTS.map(sObjectApiName => {
      const summaryByPurgeAction = metricsResult[sObjectApiName] || [];
      return {
        sObjectName: this.#objectSchemasByApiName[sObjectApiName].label,
        sObjectApiName,
        rowSpan: this.purgeActionOptions.length + 1,
        summary: this.purgeActionOptions.map(option => {
          const match = summaryByPurgeAction.find(item => item.LogPurgeAction__c === option.value);
          return {
            key: `${sObjectApiName}-${option.value}`,
            purgeAction: option.value,
            count: match ? match.recordCount : 0
          };
        })
      };
    });
  }

  async _loadPurgeBatchJobRecords() {
    const [purgeBatchResult, canUserRun] = await Promise.all([getBatchPurgeJobRecords(), canUserRunLogBatchPurger()]);
    this.disableRunPurgeButton = !canUserRun;
    this.purgeBatchJobRecords = purgeBatchResult.map(record => ({
      ...record,
      CreatedByName: record.CreatedBy.Name
    }));
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

    try {
      const jobId = await runBatchPurge();
      this.dispatchEvent(
        new ShowToastEvent({
          title: `Purge Job ${jobId} submitted`,
          variant: 'success'
        })
      );
      await this._loadPurgeBatchJobRecords();
    } catch (error) {
      this._handleError(error);
    }
  }

  async refreshPurgeBatchRecords() {
    this.showLoadingSpinner = true;
    try {
      await this._loadPurgeBatchJobRecords();
    } catch (error) {
      this._handleError(error);
    } finally {
      this.showLoadingSpinner = false;
    }
  }

  async onChangeDateFilter(event) {
    this.selectedDateFilterOption = event.detail.value;
    this.showLoadingSpinner = true;
    try {
      await this._loadMetricRecords();
    } catch (error) {
      this._handleError(error);
    } finally {
      this.showLoadingSpinner = false;
    }
  }

  _scheduleNextPoll() {
    /* eslint-disable-next-line @lwc/lwc/no-async-operation */
    setTimeout(async () => {
      try {
        await Promise.all([this._loadMetricRecords(), this._loadPurgeBatchJobRecords()]);
      } catch (error) {
        this._handleError(error);
      } finally {
        this._scheduleNextPoll();
      }
    }, POLLING_FREQUENCY_MS);
  }

  _buildPurgeBatchColumns() {
    return [
      { label: 'Job ID', fieldName: 'Id', initialWidth: 180 },
      { label: 'Job Type', fieldName: 'JobType', initialWidth: 170 },
      { label: 'Job Items Processed', fieldName: 'JobItemsProcessed', initialWidth: 180 },
      { label: 'Number of Errors', fieldName: 'NumberOfErrors', initialWidth: 170 },
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
      { label: 'Submitted By', fieldName: 'CreatedByName', type: 'text', initialWidth: 150 },
      { label: 'Status', fieldName: 'Status', type: 'text' }
    ];
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
