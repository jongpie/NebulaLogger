/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getQueryResult from '@salesforce/apex/RelatedLogEntriesController.getQueryResult';
import getAvailableTags from '@salesforce/apex/RelatedLogEntriesController.getAvailableTags';
import getCurrentUsername from '@salesforce/apex/RelatedLogEntriesController.getCurrentUsername';

export default class RelatedLogEntries extends LightningElement {
  /* eslint-disable @lwc/lwc/no-api-reassignments */
  @api recordId;
  @api fieldSetName;
  @api sortBy = '';
  @api sortDirection = '';
  @api rowLimit;
  @api search = '';
  @api queryResult;

  @track wiredResult;
  @track isLoading = true;
  @track showFilters = false;
  @track filters = {
    loggingLevels: [],
    timestampStart: null,
    timestampEnd: null,
    loggedByUsername: '',
    originSourceMetadataTypes: [],
    tags: [],
    currentUserOnly: false
  };
  @track availableTags = [];
  @track currentUsername = '';

  // Filter options
  loggingLevelOptions = [
    { label: 'ERROR', value: 'ERROR' },
    { label: 'WARN', value: 'WARN' },
    { label: 'INFO', value: 'INFO' },
    { label: 'DEBUG', value: 'DEBUG' },
    { label: 'FINE', value: 'FINE' },
    { label: 'FINER', value: 'FINER' },
    { label: 'FINEST', value: 'FINEST' }
  ];

  originSourceMetadataTypeOptions = [
    { label: 'AnonymousBlock', value: 'AnonymousBlock' },
    { label: 'ApexClass', value: 'ApexClass' },
    { label: 'ApexTrigger', value: 'ApexTrigger' },
    { label: 'AuraDefinitionBundle', value: 'AuraDefinitionBundle' },
    { label: 'Flow', value: 'Flow' },
    { label: 'LightningComponentBundle', value: 'LightningComponentBundle' },
    { label: 'OmniIntegrationProcedure', value: 'OmniIntegrationProcedure' },
    { label: 'OmniScript', value: 'OmniScript' }
  ];

  get filtersJson() {
    return JSON.stringify(this.filters);
  }

  get tagOptions() {
    return this.availableTags.map((tag) => ({ label: tag, value: tag }));
  }

  get activeFilterCount() {
    let count = 0;
    if (this.filters.loggingLevels.length > 0) count++;
    if (this.filters.timestampStart || this.filters.timestampEnd) count++;
    if (this.filters.loggedByUsername) count++;
    if (this.filters.originSourceMetadataTypes.length > 0) count++;
    if (this.filters.tags.length > 0) count++;
    if (this.filters.currentUserOnly) count++;
    return count;
  }

  get filterButtonLabel() {
    return this.activeFilterCount > 0 ? `Filters (${this.activeFilterCount})` : 'Filters';
  }

  get filterButtonVariant() {
    return this.activeFilterCount > 0 ? 'brand' : 'neutral';
  }

  get hasActiveFilters() {
    return this.activeFilterCount > 0;
  }

  get filterCountText() {
    return this.activeFilterCount === 1 ? '' : 's';
  }

  get hasRecords() {
    return this.queryResult && this.queryResult.records && this.queryResult.records.length > 0;
  }

  get showNoResultsMessage() {
    return !this.isLoading && this.queryResult && !this.hasRecords;
  }

  connectedCallback() {
    this.loadFiltersFromStorage();
    this.loadAvailableTags();
    this.loadCurrentUsername();
  }

  async loadCurrentUsername() {
    try {
      this.currentUsername = await getCurrentUsername();
    } catch (error) {
      /* eslint-disable-next-line no-console */
      console.error('Error loading current username:', error);
    }
  }

  get title() {
    return this.queryResult ? this.queryResult.labelPlural + ' (' + this.queryResult.records.length + ')' : '';
  }

  get showComponent() {
    return this.queryResult?.isAccessible === true;
  }

  loadFiltersFromStorage() {
    try {
      const storageKey = `logEntryFilters_${this.recordId}`;
      const savedFilters = localStorage.getItem(storageKey);
      if (savedFilters) {
        this.filters = JSON.parse(savedFilters);
      }
    } catch (error) {
      /* eslint-disable-next-line no-console */
      console.error('Error loading filters from storage:', error);
    }
  }

  saveFiltersToStorage() {
    try {
      const storageKey = `logEntryFilters_${this.recordId}`;
      localStorage.setItem(storageKey, JSON.stringify(this.filters));
    } catch (error) {
      /* eslint-disable-next-line no-console */
      console.error('Error saving filters to storage:', error);
    }
  }

  async loadAvailableTags() {
    try {
      this.availableTags = await getAvailableTags({ recordId: this.recordId });
    } catch (error) {
      /* eslint-disable-next-line no-console */
      console.error('Error loading available tags:', error);
      this.availableTags = [];
    }
  }

  @api
  handleSort(event) {
    this.isLoading = true;
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
  }

  @api
  handleSearchChange(event) {
    this.isLoading = true;
    this.search = event.target.value;
  }

  handleToggleFilters() {
    this.showFilters = !this.showFilters;
  }

  handleLoggingLevelChange(event) {
    this.filters.loggingLevels = event.detail.value;
    this.applyFilters();
  }

  handleTimestampStartChange(event) {
    this.filters.timestampStart = event.detail.value;
    this.applyFilters();
  }

  handleTimestampEndChange(event) {
    this.filters.timestampEnd = event.detail.value;
    this.applyFilters();
  }

  handleLoggedByUsernameChange(event) {
    this.filters.loggedByUsername = event.detail.value;
    this.applyFilters();
  }

  handleOriginSourceMetadataTypeChange(event) {
    this.filters.originSourceMetadataTypes = event.detail.value;
    this.applyFilters();
  }

  handleTagsChange(event) {
    this.filters.tags = event.detail.value;
    this.applyFilters();
  }

  handleCurrentUserOnlyChange(event) {
    this.filters.currentUserOnly = event.detail.checked;
    if (this.filters.currentUserOnly) {
      // When enabled, use the current user's username
      // In a real implementation, this would come from an Apex method
      this.filters.loggedByUsername = this.currentUsername;
    } else {
      // When disabled, clear the username filter
      this.filters.loggedByUsername = '';
    }
    this.applyFilters();
  }

  handleClearFilters() {
    this.filters = {
      loggingLevels: [],
      timestampStart: null,
      timestampEnd: null,
      loggedByUsername: '',
      originSourceMetadataTypes: [],
      tags: [],
      currentUserOnly: false
    };
    this.saveFiltersToStorage();
    this.isLoading = true;
    this.refresh();
  }

  applyFilters() {
    this.saveFiltersToStorage();
    this.isLoading = true;
  }

  @wire(getQueryResult, {
    recordId: '$recordId',
    fieldSetName: '$fieldSetName',
    rowLimit: '$rowLimit',
    sortByFieldName: '$sortBy',
    sortDirection: '$sortDirection',
    search: '$search',
    filters: '$filtersJson'
  })
  wiredLogEntries(result) {
    this.isLoading = true;
    this.wiredResult = result;
    if (result.data) {
      this.queryResult = this.processResult(result.data);
    } else if (result.error) {
      /* eslint-disable-next-line no-console */
      console.log(result.error);
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error loading log entries',
          message: error.body?.message || 'An error occurred',
          variant: 'error'
        })
      );
    }
    this.isLoading = false;
  }

  async refresh() {
    this.isLoading = true;
    await refreshApex(this.wiredResult);
    await this.loadAvailableTags();
    this.isLoading = false;
  }

  // Parse the Apex results & add any UI-specific attributes based on field metadata
  processResult(queryResult) {
    if (queryResult.fieldSet === undefined) {
      return null;
    }

    queryResult = Object.assign({}, queryResult); // clone queryResult

    let fieldSet = Object.assign({}, queryResult.fieldSet); // clone fieldSet
    let fields = [].concat(queryResult.fieldSet.fields); // clone fields
    let records = [].concat(queryResult.records); // clone records

    for (let i = 0; i < fieldSet.fields.length; i++) {
      let field = Object.assign({}, fieldSet.fields[i]); // clone field

      if (field.type === 'datetime') {
        field.type = 'date';
        // FIXME and make dynamic based on user prefences for datetimes
        field.typeAttributes = {
          month: '2-digit',
          day: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        };
      } else if (field.type === 'reference') {
        let displayFieldName = field.lookupDisplayFieldName.replace('.', '') + 'Display';
        let looupFieldName = field.fieldName;

        // Add URL formatting to the field
        field.type = 'url';
        field.typeAttributes = {
          label: { fieldName: displayFieldName },
          name: { fieldName: looupFieldName },
          target: '_self'
        };

        // Add the link to each log entry record
        for (let j = 0; j < records.length; j++) {
          let record = Object.assign({}, records[j]); //cloning object

          let parentObject = record[field.relationshipName];
          record[displayFieldName] = parentObject[field.lookupDisplayFieldName.split('.').splice(1)];
          record[field.fieldName] = '/' + record[looupFieldName];

          records[j] = record;
        }
      } else if (field.isNameField) {
        // Make the record's Name field a clickable link to the record
        let displayFieldName = field.fieldName + 'Display';

        // Add URL formatting to the field
        field.type = 'url';
        field.typeAttributes = {
          label: { fieldName: displayFieldName },
          name: { fieldName: 'Id' },
          target: '_self'
        };

        // Add the link to each log entry record
        for (let j = 0; j < records.length; j++) {
          let record = Object.assign({}, records[j]); //cloning object
          record[displayFieldName] = record[field.fieldName];
          record[field.fieldName] = '/' + record.Id;

          records[j] = record;
        }
      }

      fields[i] = field;
    }

    queryResult.fieldSet = fieldSet;
    queryResult.fieldSet.fields = fields;
    queryResult.records = records;

    return queryResult;
  }
}
