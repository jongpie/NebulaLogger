/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { createElement } from '@lwc/engine-dom';
import RelatedLogEntries from 'c/relatedLogEntries';
import getQueryResult from '@salesforce/apex/RelatedLogEntriesController.getQueryResult';
import { refreshApex } from '@salesforce/apex';

const MOCK_QUERY_RESULT = require('./data/getQueryResult.json');

// Mock the Apex wire adapter
jest.mock(
  '@salesforce/apex/RelatedLogEntriesController.getQueryResult',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

// Mock refreshApex
jest.mock('@salesforce/apex', () => ({
  refreshApex: jest.fn()
}));

describe('RelatedLogEntries LWC', () => {
  let element;

  beforeEach(() => {
    element = createElement('c-related-log-entries', { is: RelatedLogEntries });
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  describe('Component Initialization', () => {
    it('should initialize with default values', () => {
      document.body.appendChild(element);

      expect(element.recordId).toBeUndefined();
      expect(element.fieldSetName).toBeUndefined();
      expect(element.sortBy).toBe('');
      expect(element.sortDirection).toBe('');
      expect(element.rowLimit).toBeUndefined();
      expect(element.search).toBe('');
      expect(element.queryResult).toBeUndefined();
      expect(element.showComponent).toBe(false);
      expect(element.title).toBeUndefined();
      expect(element.isLoading).toBe(true);
    });

    it('should set public properties correctly', () => {
      element.recordId = 'test-record-id';
      element.fieldSetName = 'Related_List_Defaults';
      element.rowLimit = 50;
      element.sortBy = 'Timestamp__c';
      element.sortDirection = 'DESC';

      document.body.appendChild(element);

      expect(element.recordId).toBe('test-record-id');
      expect(element.fieldSetName).toBe('Related_List_Defaults');
      expect(element.rowLimit).toBe(50);
      expect(element.sortBy).toBe('Timestamp__c');
      expect(element.sortDirection).toBe('DESC');
    });
  });

  describe('Wire Service', () => {
    it('should process successful wire result and show component', async () => {
      document.body.appendChild(element);

      // Emit mock data through the wire
      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve(); // Wait for component to process the data

      expect(element.showComponent).toBe(true);
      expect(element.title).toBe('Log Entries (4 Total)');
      expect(element.queryResult).toBeDefined();
      expect(element.isLoading).toBe(false);
    });

    it('should handle wire error gracefully', async () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
      document.body.appendChild(element);

      // Emit error through the wire
      getQueryResult.error(new Error('Test error'));

      await Promise.resolve(); // Wait for component to process the error

      expect(element.showComponent).toBe(false);
      expect(element.isLoading).toBe(false);
      expect(consoleSpy).toHaveBeenCalled();

      consoleSpy.mockRestore();
    });

    it('should not show component when fieldSet is undefined', async () => {
      document.body.appendChild(element);

      const invalidResult = { ...MOCK_QUERY_RESULT };
      delete invalidResult.fieldSet;

      getQueryResult.emit(invalidResult);

      await Promise.resolve();

      expect(element.showComponent).toBe(false);
      expect(element.queryResult).toBeNull();
    });
  });

  describe('Data Processing', () => {
    it('should process datetime fields correctly', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const timestampField = element.queryResult.fieldSet.fields.find(field => field.fieldName === 'Timestamp__c');
      expect(timestampField.type).toBe('date');
      expect(timestampField.typeAttributes).toEqual({
        month: '2-digit',
        day: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      });
    });

    it('should process reference fields correctly', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const logField = element.queryResult.fieldSet.fields.find(field => field.fieldName === 'Log__c');
      expect(logField.type).toBe('url');
      expect(logField.typeAttributes).toEqual({
        label: { fieldName: 'Log__rNameDisplay' },
        name: { fieldName: 'Log__c' },
        target: '_self'
      });

      // Check that records have the display field and URL
      const firstRecord = element.queryResult.records[0];
      expect(firstRecord.Log__rNameDisplay).toBe('Log-001429');
      expect(firstRecord.Log__c).toBe('/a0154000007ksDlAAI');
    });

    it('should process name fields correctly', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const nameField = element.queryResult.fieldSet.fields.find(field => field.fieldName === 'Name');
      expect(nameField.type).toBe('url');
      expect(nameField.typeAttributes).toEqual({
        label: { fieldName: 'NameDisplay' },
        name: { fieldName: 'Id' },
        target: '_self'
      });

      // Check that records have the display field and URL
      const firstRecord = element.queryResult.records[0];
      expect(firstRecord.NameDisplay).toBe('a0054000004OazX');
      expect(firstRecord.Name).toBe('/a0054000004OazXAAS');
    });
  });

  describe('Public Methods', () => {
    it('should handle sort events correctly', () => {
      document.body.appendChild(element);

      const sortEvent = {
        detail: {
          fieldName: 'Message__c',
          sortDirection: 'ASC'
        }
      };

      element.handleSort(sortEvent);

      expect(element.sortBy).toBe('Message__c');
      expect(element.sortDirection).toBe('ASC');
    });

    it('should handle search change events correctly', () => {
      document.body.appendChild(element);

      const searchEvent = {
        target: {
          value: 'test search'
        }
      };

      element.handleSearchChange(searchEvent);

      expect(element.search).toBe('test search');
      expect(element.isLoading).toBe(true);
    });

    it('should refresh data correctly', async () => {
      document.body.appendChild(element);

      // Mock refreshApex to return a resolved promise
      refreshApex.mockResolvedValue();

      await element.refresh();

      expect(refreshApex).toHaveBeenCalledWith(element.wiredResult);
      expect(element.isLoading).toBe(false);
    });
  });

  describe('Component Rendering', () => {
    it('should render component when showComponent is true', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      expect(element.showComponent).toBe(true);

      // Check that the main card is rendered
      const card = element.shadowRoot.querySelector('lightning-card');
      expect(card).toBeTruthy();
      expect(card.title).toBe('Log Entries (4 Total)');
    });

    it('should not render component when showComponent is false', () => {
      document.body.appendChild(element);

      // Component should not be visible initially
      expect(element.showComponent).toBe(false);

      const card = element.shadowRoot.querySelector('lightning-card');
      expect(card).toBeFalsy();
    });

    it('should show loading spinner when isLoading is true', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      // Initially loading should be true
      expect(element.isLoading).toBe(true);

      await Promise.resolve();

      // After processing, loading should be false
      expect(element.isLoading).toBe(false);
    });

    it('should render datatable with correct data', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const datatable = element.shadowRoot.querySelector('lightning-datatable');
      expect(datatable).toBeTruthy();
      expect(datatable.data).toEqual(element.queryResult.records);
      expect(datatable.columns).toEqual(element.queryResult.fieldSet.fields);
    });

    it('should render search input and refresh button', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const searchInput = element.shadowRoot.querySelector('lightning-input[data-id="enter-search"]');
      const refreshButton = element.shadowRoot.querySelector('lightning-button-icon');

      expect(searchInput).toBeTruthy();
      expect(refreshButton).toBeTruthy();
      expect(refreshButton.iconName).toBe('utility:refresh');
    });
  });

  describe('Event Handling', () => {
    it('should handle search input changes', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const searchInput = element.shadowRoot.querySelector('lightning-input[data-id="enter-search"]');
      expect(searchInput).toBeTruthy();

      // Simulate search input change
      const searchEvent = new CustomEvent('change', {
        detail: { value: 'new search term' }
      });
      searchInput.dispatchEvent(searchEvent);

      // The component should handle the change event
      expect(element.search).toBe('new search term');
    });

    it('should handle refresh button click', async () => {
      document.body.appendChild(element);

      getQueryResult.emit(MOCK_QUERY_RESULT);

      await Promise.resolve();

      const refreshButton = element.shadowRoot.querySelector('lightning-button-icon');
      expect(refreshButton).toBeTruthy();

      // Mock refreshApex
      refreshApex.mockResolvedValue();

      // Simulate button click
      refreshButton.click();

      await Promise.resolve();

      expect(refreshApex).toHaveBeenCalled();
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty records array', async () => {
      document.body.appendChild(element);

      const emptyResult = {
        ...MOCK_QUERY_RESULT,
        records: [],
        totalLogEntriesCount: 0
      };

      getQueryResult.emit(emptyResult);

      await Promise.resolve();

      expect(element.title).toBe('Log Entries (0 Total)');
      expect(element.queryResult.records).toEqual([]);
    });

    it('should handle missing fieldSet fields', async () => {
      document.body.appendChild(element);

      const invalidResult = {
        ...MOCK_QUERY_RESULT,
        fieldSet: {
          ...MOCK_QUERY_RESULT.fieldSet,
          fields: []
        }
      };

      getQueryResult.emit(invalidResult);

      await Promise.resolve();

      expect(element.queryResult.fieldSet.fields).toEqual([]);
    });

    it('should handle null search value', () => {
      document.body.appendChild(element);

      const searchEvent = {
        target: {
          value: null
        }
      };

      element.handleSearchChange(searchEvent);

      expect(element.search).toBe(null);
    });
  });
});
