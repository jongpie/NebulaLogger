/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';

export default class LogEntryArchives extends LightningElement {
  isLoading = false;
  logEntryArchives = [];
  startDate = new Date(new Date().getTime() + -60 * 24 * 60 * 60 * 1000).toISOString(); // 60 days ago
  endDate = new Date().toISOString();
  minimumLoggingLevelOrdinal;
  rowLimit;
  _schema = {};
  _messageSearchTerm;

  async connectedCallback() {
    this.minimumLoggingLevelOrdinal = this.loggingLevelOptions[this.loggingLevelOptions.length - 1].value;
    this.rowLimit = this.rowLimitOptions[0].value;
    await getSchemaForName({ sobjectApiName: 'LogEntryArchive__b' }).then(data => {
      this._schema = data;
      document.title = this._schema.labelPlural;
    });
    this._loadColumns();
    await this._loadLogEntryArchives();
  }

  get title() {
    return this.logEntryArchives.length + ' ' + this._schema.labelPlural;
  }

  get loggingLevelOptions() {
    return [
      { label: 'ERROR', value: '8' },
      { label: 'WARN', value: '7' },
      { label: 'INFO', value: '6' },
      { label: 'DEBUG', value: '5' },
      { label: 'FINE', value: '4' },
      { label: 'FINER', value: '3' },
      { label: 'FINEST', value: '2' }
    ];
  }

  get rowLimitOptions() {
    return [
      { label: '50 Records', value: '50' },
      { label: '100 Records', value: '100' }
    ];
  }

  handleDateChange(event) {
    const updatedProperty = event.target.dataset.id;
    this[updatedProperty] = !event.detail.value ? '' : new Date(event.detail.value).toISOString();
    this._loadLogEntryArchives();
  }

  handleLoggingLevelFilterChange(event) {
    const selectedLoggingLevelOrdinal = event.target.value;
    this.minimumLoggingLevelOrdinal = selectedLoggingLevelOrdinal;
    this._loadLogEntryArchives();
  }

  handleRowLimitFilterChange(event) {
    const selectedRowLimit = event.target.value;
    this.rowLimit = selectedRowLimit;
    this._loadLogEntryArchives();
  }

  handleSearch(event) {
    this._messageSearchTerm = event.target.value;
    this._loadLogEntryArchives();
  }

  handleRefresh() {
    const searchTerm = this.template.querySelector('lightning-input').value;
    this._loadLogEntryArchives(searchTerm);
  }

  // TODO Future release, add 'View' action with ability to view more fields for a `LogEntryArchive__b` record (similar to loggerSettings LWC)
  // handleRowAction(event) {
  //     const actionName = event.detail.action.name;
  //     const row = event.detail.row;
  //     /* eslint-disable-next-line default-case */
  //     switch (actionName) {
  //         case 'view':
  //             alert('TODO!');
  //             // this._viewCurrentRecord(row);
  //             break;
  //     }
  // }

  async _loadLogEntryArchives() {
    let hasInvalidInputs = false;
    this.template.querySelectorAll('lightning-input, lightning-comboxbox').forEach(input => {
      if (input.reportValidity() === false) {
        hasInvalidInputs = true;
      }
    });

    if (hasInvalidInputs === true) {
      return;
    }

    this.isLoading = true;
    this.logEntryArchives = [];
    getLogEntryArchives({
      startDate: this.startDate,
      endDate: this.endDate,
      rowLimit: Number(this.rowLimit),
      messageSearchTerm: this._messageSearchTerm,
      minimumLoggingLevelOrdinal: Number(this.minimumLoggingLevelOrdinal)
    })
      .then(results => {
        this.logEntryArchives = JSON.parse(JSON.stringify(results));

        this.logEntryArchives.forEach(archive => {
          archive.compositeId = archive.TransactionId__c + archive.TransactionEntryNumber__c;
        });
        this.isLoading = false;
      })
      .catch(this._handleError);
  }

  _loadColumns() {
    this.columns = [];

    const tableColumnNames = [
      'LoggedByUsername__c',
      'TransactionId__c',
      'TransactionEntryNumber__c',
      'LoggingLevel__c',
      'OriginType__c',
      'OriginLocation__c',
      'Message__c',
      'Timestamp__c'
    ];
    for (let i = 0; i < tableColumnNames.length; i++) {
      const field = this._schema.fields[tableColumnNames[i]];
      const column = {
        fieldName: field.localApiName,
        label: field.label,
        type: field.type.toLowerCase()
      };
      if (column.type === 'datetime') {
        column.type = 'date';
        // FIXME and make dynamic based on user prefences for datetimes
        column.typeAttributes = {
          month: '2-digit',
          day: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        };
      } else if (column.type === 'string') {
        column.type = 'text';
      } else if (column.type === 'textarea') {
        column.wrapText = true;
      }
      this.columns.push(column);
    }

    // TODO Finish in a future release
    // Append the row-level actions
    // let tableRowActions = [{ label: 'View', name: 'view' }];
    // this.columns.push({
    //     type: 'action',
    //     typeAttributes: {
    //         menuAlignment: 'auto'
    //         rowActions: tableRowActions,
    //     }
    // });
  }

  _handleError = error => {
    const errorMessage = error.body ? error.body.message : 'error.message';
    const errorStackTrace = error.body ? error.body.stackTrace : '';
    const errorExceptionType = error.body ? error.body.exceptionType + ' in ' : '';
    /* eslint-disable-next-line no-console */
    console.error({ error });
    this.dispatchEvent(
      new ShowToastEvent({
        message: errorExceptionType + errorStackTrace,
        mode: 'sticky',
        title: errorMessage,
        variant: 'error'
      })
    );
    this.isLoading = false;
  };
}
