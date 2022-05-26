/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getMetrics from "@salesforce/apex/BatchPurgeController.getMetrics";
import getSchemaForName from "@salesforce/apex/LoggerSObjectMetadata.getSchemaForName";
import canUserRunLogBatchPurger from "@salesforce/apex/BatchPurgeController.canUserRunLogBatchPurger";
import purgeActionOptions from "@salesforce/apex/BatchPurgeController.getPurgeActionOptions";
import runPurgeBatch from "@salesforce/apex/BatchPurgeController.runPurgeBatch";
import getPurgeBatchJobRecords from "@salesforce/apex/BatchPurgeController.getPurgeBatchJobRecords";

export default class BatchPurge extends LightningElement {
  //UI
  title = "Purge Batch";
  showLoadingSpinner = false;

  POLLING_FREQUENCY = 10000; // milliseconds

  //log  metrics.
  logObjectSchema;
  logEntryObjectSchema;
  logEntryTagObjectSchema;

  metricsResult;
  metricsColumns;
  metricsRecords;
  purgeActionOptions;

  //Date filter options
  selectedDateFilterOption = "TODAY"; //default

  dateFilterOptions = [
    { label: "Today", value: "TODAY" },
    { label: "This Week", value: "THIS_WEEK" },
    { label: "This Month", value: "THIS_MONTH" }
  ];

  //Purge Batch
  purgeBatchColumns;
  purgeBatchJobRecords;
  disableRunPurgeButton;

  async connectedCallback() {
    document.title = this.title;
    this.selectedDateFilterOption = "TODAY";

    this.loadMetricRecords();
    this.loadPurgeBatchColumns();
    this.loadpurgeBatchJobRecords();

    this.pollpurgeBatchJobRecords();
  }

  loadMetricRecords() {
    this.showLoadingSpinner = true;

    Promise.all([
      getMetrics({ dateFilterOption: this.selectedDateFilterOption }),
      purgeActionOptions(),
      getSchemaForName({ sobjectApiName: "Log__c" }),
      getSchemaForName({ sobjectApiName: "LogEntry__c" }),
      getSchemaForName({ sobjectApiName: "LogEntryTag__c" })
    ])
      .then(
        ([
          metricsResult,
          purgeActionOptionsResult,
          logObjectSchema,
          logEntryObjectSchema,
          logEntryTagObjectSchema
        ]) => {
          this.metricsResult = metricsResult;
          this.purgeActionOptions = purgeActionOptionsResult;
          this.logObjectSchema = logObjectSchema;
          this.logEntryObjectSchema = logEntryObjectSchema;
          this.logEntryTagObjectSchema = logEntryTagObjectSchema;

          const METRIC_TEMPLATE = [
            {
              sObjectName: this.logObjectSchema.label,
              sObjectApiName: "Log__c",
              rowSpan: this.purgeActionOptions.length + 1,
              summary: []
            },
            {
              sObjectName: this.logEntryObjectSchema.label,
              sObjectApiName: "LogEntry__c",
              rowSpan: this.purgeActionOptions.length + 1,
              summary: []
            },
            {
              sObjectName: this.logEntryTagObjectSchema.label,
              sObjectApiName: "LogEntryTag__c",
              rowSpan: this.purgeActionOptions.length + 1,
              summary: []
            }
          ];

          let records = [...METRIC_TEMPLATE];

          records.forEach((record) => {
            const aMetricRecord = metricsResult[record.sObjectApiName];
            record.summary = this.purgeActionOptions.map((option) => {
              const summary = aMetricRecord.filter(
                (item) => item.LogPurgeAction__c === option.value
              );
              return {
                purgeAction: option.value,
                count: summary.length > 0 ? summary[0].expr0 : 0
              };
            });
          });
          this.metricsRecords = records;
          this.showLoadingSpinner = false;
        }
      )
      .catch(this._handleError);
  }

  loadPurgeBatchColumns() {
    let columns = [
      { label: "Job Id", fieldName: "Id", initialWidth: 180 },
      { label: "Job Type", fieldName: "JobType", initialWidth: 170 },
      { label: "Method Name", fieldName: "MethodName", initialWidth: 180 },
      {
        label: "Job Items Processed",
        fieldName: "JobItemsProcessed",
        initialWidth: 180
      },
      {
        label: "Number of Errors",
        fieldName: "NumberOfErrors",
        initialWidth: 170
      },
      {
        label: "Submitted On",
        fieldName: "CreatedDate",
        type: "date",
        initialWidth: 200,
        typeAttributes: {
          day: "numeric",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: true
        }
      },
      {
        label: "Submitted By",
        fieldName: "CreatedBy",
        type: "text",
        initialWidth: 150
      },
      { label: "Status", fieldName: "Status", type: "text" }
    ];

    this.purgeBatchColumns = columns;
  }

  loadpurgeBatchJobRecords() {
    this.showLoadingSpinner = true;
    Promise.all([getPurgeBatchJobRecords(), canUserRunLogBatchPurger()])
      .then(([purgeBatchResult, canUserRunLogBatchPurgerAdHocResult]) => {
        this.disableRunPurgeButton = !canUserRunLogBatchPurgerAdHocResult;
        const formattedBatchJobRecords = purgeBatchResult.map((record) => {
          record.CreatedBy = record.CreatedBy.Name;
          return record;
        });
        this.purgeBatchJobRecords = formattedBatchJobRecords;
        this.showLoadingSpinner = false;
      })
      .catch(this._handleError);
  }

  runPurgeBatch() {
    runPurgeBatch()
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: `Purge Job ${result} submitted.`,
            variant: "success"
          })
        );
        this.loadpurgeBatchJobRecords();
      })
      .catch(this._handleError);
  }

  refreshpurgeBatchJobRecords() {
    this.loadpurgeBatchJobRecords();
  }

  onChangeDateFilter(event) {
    this.selectedDateFilterOption = event.detail.value;
    this.loadMetricRecords();
  }

  pollpurgeBatchJobRecords() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
      this.loadpurgeBatchJobRecords();
      this.loadMetricRecords();
      this.pollpurgeBatchJobRecords();
    }, this.POLLING_FREQUENCY);
  }

  _handleError = (error) => {
    const errorMessage = error.body ? error.body.message : error.message;
    /* eslint-disable-next-line no-console */
    console.error(errorMessage, error);
    this.dispatchEvent(
      new ShowToastEvent({
        mode: "sticky",
        title: errorMessage,
        variant: "error"
      })
    );
    this.showLoadingSpinner = false;
  };
}
