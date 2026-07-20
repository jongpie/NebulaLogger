/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import canUserRunLogBatchPurger from '@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger';
import getBatchPurgeJobRecords from '@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords';
import getMetrics from '@salesforce/apex/LogBatchPurgeController.getMetrics';
import getPurgeActionOptions from '@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions';
import getRegisteredPurgeableSObjectTypes from '@salesforce/apex/LogBatchPurgeController.getRegisteredPurgeableSObjectTypes';
import runBatchPurge from '@salesforce/apex/LogBatchPurgeController.runBatchPurge';

const TITLE = 'Log Batch Purge';
const AUTO_REFRESH_STORAGE_KEY = 'nebula-logger.logBatchPurge.autoRefresh';
const AUTO_REFRESH_INTERVAL_STORAGE_KEY = 'nebula-logger.logBatchPurge.autoRefreshIntervalMs';
const DEFAULT_AUTO_REFRESH_INTERVAL_MS = 10000;

export default class LogBatchPurge extends LightningElement {
  title = TITLE;
  showLoadingSpinner = false;

  metricsResult;
  metricsRecords = [];
  purgeActionOptions = [];
  registeredPurgeableSObjectTypes = [];

  selectedDateFilterOption = 'TODAY';
  dateFilterOptions = [
    { label: 'Purge Date: Today', value: 'TODAY' },
    { label: 'Purge Date: This Week', value: 'THIS_WEEK' },
    { label: 'Purge Date: This Month', value: 'THIS_MONTH' },
    { label: 'Purge Date: All Time', value: 'ALL_TIME' }
  ];

  purgeBatchColumns = [];
  purgeBatchJobRecords = [];
  disableRunPurgeButton;

  autoRefreshEnabled = false;
  autoRefreshIntervalMs = DEFAULT_AUTO_REFRESH_INTERVAL_MS;
  autoRefreshIntervalOptions = [
    { label: 'Every 5 seconds', value: '5000' },
    { label: 'Every 10 seconds', value: '10000' },
    { label: 'Every 30 seconds', value: '30000' },
    { label: 'Every 60 seconds', value: '60000' }
  ];

  #autoRefreshTimerId;

  connectedCallback() {
    document.title = `${TITLE} | Salesforce`;
    this._restoreAutoRefreshPreferences();

    this._loadAll();

    if (this.autoRefreshEnabled) {
      this._startAutoRefresh();
    }
  }

  disconnectedCallback() {
    this._stopAutoRefresh();
  }

  get autoRefreshIntervalValue() {
    return String(this.autoRefreshIntervalMs);
  }

  get autoRefreshDisabled() {
    return !this.autoRefreshEnabled;
  }

  get retentionSubtitle() {
    const option = this.dateFilterOptions.find(candidate => candidate.value === this.selectedDateFilterOption);
    const label = option ? option.label : this.selectedDateFilterOption;
    return `Showing records whose retention date matches ${label}. Records with a blank retention date are treated as "keep forever" and are excluded.`;
  }

  _loadAll() {
    this._loadMetricRecords();
    this._loadPurgeBatchColumns();
    this._loadPurgeBatchJobRecords();
  }

  _loadMetricRecords() {
    this.showLoadingSpinner = true;

    Promise.all([getMetrics({ dateFilterOption: this.selectedDateFilterOption }), getPurgeActionOptions(), getRegisteredPurgeableSObjectTypes()])
      .then(([metricsResult, purgeActionOptionsResult, registeredTypes]) => {
        this.metricsResult = metricsResult;
        this.purgeActionOptions = purgeActionOptionsResult;
        this.registeredPurgeableSObjectTypes = registeredTypes;

        const coreRows = [
          { sobjectApiName: 'Log__c', pluginCaption: null },
          { sobjectApiName: 'LogEntry__c', pluginCaption: null },
          { sobjectApiName: 'LogEntryTag__c', pluginCaption: null }
        ];
        const registeredRows = registeredTypes.map(registered => ({
          sobjectApiName: registered.apiName,
          pluginCaption: registered.registeringPluginDeveloperName
            ? `Registered by plugin ${registered.registeringPluginDeveloperName}`
            : 'Registered by a plugin'
        }));

        const records = [...coreRows, ...registeredRows].map(row => {
          const aggregateResults = metricsResult[row.sobjectApiName] ?? [];
          const summary = this.purgeActionOptions.map(option => {
            const matches = aggregateResults.filter(item => item.LogPurgeAction__c === option.value);
            const key = `${row.sobjectApiName}-${option.value}`;
            return {
              key,
              purgeAction: option.value,
              count: matches.length > 0 ? matches[0].expr0 : 0
            };
          });
          return {
            ...row,
            rowSpan: this.purgeActionOptions.length + 1,
            summary
          };
        });
        this.metricsRecords = records;
        this.showLoadingSpinner = false;
      })
      .catch(this._handleError);
  }

  _loadPurgeBatchColumns() {
    this.purgeBatchColumns = [
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

  _loadPurgeBatchJobRecords() {
    this.showLoadingSpinner = true;
    Promise.all([getBatchPurgeJobRecords(), canUserRunLogBatchPurger()])
      .then(([purgeBatchResult, canUserRunLogBatchPurgerAdHocResult]) => {
        this.disableRunPurgeButton = !canUserRunLogBatchPurgerAdHocResult;
        this.purgeBatchJobRecords = purgeBatchResult.map(record => ({
          ...record,
          CreatedByName: record.CreatedBy.Name
        }));
        this.showLoadingSpinner = false;
      })
      .catch(this._handleError);
  }

  async runBatchPurge() {
    const totalRowCount = this._totalRowsToPurge();
    const totalMessage =
      totalRowCount > 0 ? `This will delete approximately ${totalRowCount} record(s):\n${this._perSobjectBreakdownForConfirm()}` : 'This will delete data!';
    const confirmationResult = await LightningConfirm.open({
      label: 'Confirm Job Execution',
      message: `Are you sure that you want to run LogBatchPurger?\n\n${totalMessage}`,
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
        this._loadPurgeBatchJobRecords();
      })
      .catch(this._handleError);
  }

  refreshPurgeBatchRecords() {
    this._loadPurgeBatchJobRecords();
  }

  onChangeDateFilter(event) {
    this.selectedDateFilterOption = event.detail.value;
    this._loadMetricRecords();
  }

  onToggleAutoRefresh(event) {
    this.autoRefreshEnabled = event.detail.checked;
    this._persistAutoRefreshPreferences();
    if (this.autoRefreshEnabled) {
      this._startAutoRefresh();
    } else {
      this._stopAutoRefresh();
    }
  }

  onChangeAutoRefreshInterval(event) {
    this.autoRefreshIntervalMs = Number(event.detail.value);
    this._persistAutoRefreshPreferences();
    if (this.autoRefreshEnabled) {
      this._startAutoRefresh();
    }
  }

  _totalRowsToPurge() {
    return this.metricsRecords.reduce((runningTotal, row) => runningTotal + row.summary.reduce((rowTotal, item) => rowTotal + Number(item.count ?? 0), 0), 0);
  }

  _perSobjectBreakdownForConfirm() {
    return this.metricsRecords
      .map(row => {
        const rowTotal = row.summary.reduce((total, item) => total + Number(item.count ?? 0), 0);
        return `  - ${row.sobjectApiName}: ${rowTotal}`;
      })
      .join('\n');
  }

  _startAutoRefresh() {
    this._stopAutoRefresh();
    // eslint-disable-next-line
    this.#autoRefreshTimerId = setInterval(() => {
      this._loadMetricRecords();
      this._loadPurgeBatchJobRecords();
    }, this.autoRefreshIntervalMs);
  }

  _stopAutoRefresh() {
    if (this.#autoRefreshTimerId) {
      clearInterval(this.#autoRefreshTimerId);
      this.#autoRefreshTimerId = undefined;
    }
  }

  _restoreAutoRefreshPreferences() {
    try {
      const storedEnabled = window.localStorage.getItem(AUTO_REFRESH_STORAGE_KEY);
      if (storedEnabled !== null) {
        this.autoRefreshEnabled = storedEnabled === 'true';
      }
      const storedInterval = window.localStorage.getItem(AUTO_REFRESH_INTERVAL_STORAGE_KEY);
      if (storedInterval !== null) {
        const parsed = Number(storedInterval);
        if (this.autoRefreshIntervalOptions.some(option => option.value === storedInterval)) {
          this.autoRefreshIntervalMs = parsed;
        }
      }
    } catch (error) {
      // localStorage can throw in embedded contexts / private-browsing modes. Fall back to defaults.
    }
  }

  _persistAutoRefreshPreferences() {
    try {
      window.localStorage.setItem(AUTO_REFRESH_STORAGE_KEY, String(this.autoRefreshEnabled));
      window.localStorage.setItem(AUTO_REFRESH_INTERVAL_STORAGE_KEY, String(this.autoRefreshIntervalMs));
    } catch (error) {
      // Ignore; a persistence failure shouldn't break the runtime behavior.
    }
  }

  _handleError = error => {
    const errorMessage = error.body ? error.body.message : error.message;
    // eslint-disable-next-line
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
