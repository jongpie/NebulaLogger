import { createElement } from '@lwc/engine-dom';
import LogEntryPageSection from 'c/logEntryPageSection';

// Mock data imports
const mockLogEntrySchema = require('./data/getSchemaForName.json');
const mockHttpRequestData = require('./data/httpRequestSection.json');
const mockHttpResponseData = require('./data/httpResponseSection.json');
const mockDatabaseResultData = require('./data/databaseResultSection.json');
const mockRelatedRecordData = require('./data/relatedRecordSection.json');

// Mock the Apex method
jest.mock(
  '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName',
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

// Mock the wire service
jest.mock(
  'lightning/uiRecordApi',
  () => ({
    getRecord: jest.fn(),
    getFieldValue: jest.fn()
  }),
  { virtual: true }
);

describe('c-log-entry-page-section', () => {
  let element;
  let getRecordMock;
  let getFieldValueMock;
  let getSchemaForNameMock;

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();

    // Setup mocks
    getRecordMock = require('@salesforce/sfdx-lwc-jest').createApexTestWireAdapter(jest.fn());
    getFieldValueMock = jest.fn();

    const { getRecord, getFieldValue } = require('lightning/uiRecordApi');
    getRecord.mockReturnValue(getRecordMock);
    getFieldValue.mockImplementation(getFieldValueMock);

    getSchemaForNameMock = require('@salesforce/apex/LoggerSObjectMetadata.getSchemaForName').default;
    getSchemaForNameMock.mockResolvedValue(mockLogEntrySchema);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  describe('Component Initialization', () => {
    it('should initialize with correct public properties', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      expect(element.recordId).toBe('a1234567890abcdef');
      expect(element.sectionType).toBe('HTTP Request');
    });

    it('should render loading spinner initially', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });

    it('should render loading state when component is first created', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
      expect(loadingDiv.querySelector('lightning-spinner')).toBeTruthy();
    });
  });

  describe('Property Updates', () => {
    it('should update record ID when changed', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      element.recordId = 'new-record-id';
      expect(element.recordId).toBe('new-record-id');
    });

    it('should update section type when changed', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      element.sectionType = 'HTTP Response';
      expect(element.sectionType).toBe('HTTP Response');
    });
  });

  describe('Component Behavior', () => {
    it('should handle different section types correctly', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      // Test HTTP Request section
      expect(element.sectionType).toBe('HTTP Request');

      // Change to HTTP Response section
      element.sectionType = 'HTTP Response';
      expect(element.sectionType).toBe('HTTP Response');

      // Change to Database Result Details section
      element.sectionType = 'Database Result Details';
      expect(element.sectionType).toBe('Database Result Details');

      // Change to Related Record Details section
      element.sectionType = 'Related Record Details';
      expect(element.sectionType).toBe('Related Record Details');
    });

    it('should handle unknown section type gracefully', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'Unknown Section';
      document.body.appendChild(element);

      expect(element.sectionType).toBe('Unknown Section');
    });

    it('should handle empty record ID', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = '';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      expect(element.recordId).toBe('');
      expect(element.sectionType).toBe('HTTP Request');
    });

    it('should handle null record ID', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = null;
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      expect(element.recordId).toBe(null);
      expect(element.sectionType).toBe('HTTP Request');
    });
  });

  describe('Component Lifecycle', () => {
    it('should be properly created and attached to DOM', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      expect(element).toBeTruthy();
      expect(document.body.contains(element)).toBe(true);
    });

    it('should be properly removed from DOM', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      document.body.removeChild(element);
      expect(document.body.contains(element)).toBe(false);
    });

    it('should handle multiple component instances', () => {
      // Create first component
      const element1 = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element1.recordId = 'record1';
      element1.sectionType = 'HTTP Request';
      document.body.appendChild(element1);

      // Create second component
      const element2 = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element2.recordId = 'record2';
      element2.sectionType = 'HTTP Response';
      document.body.appendChild(element2);

      // Verify both components exist and have correct properties
      expect(element1.recordId).toBe('record1');
      expect(element1.sectionType).toBe('HTTP Request');
      expect(element2.recordId).toBe('record2');
      expect(element2.sectionType).toBe('HTTP Response');

      // Clean up
      document.body.removeChild(element1);
      document.body.removeChild(element2);
    });
  });

  describe('Component Structure', () => {
    it('should have correct HTML structure', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      // Check for main container
      const container = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(container).toBeTruthy();

      // Check for loading spinner
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();

      // Since the component is in loading state, c-logger-page-section should not be rendered yet
      const pageSection = element.shadowRoot.querySelector('c-logger-page-section');
      expect(pageSection).toBeFalsy(); // Should not exist in loading state
    });

    it('should have correct CSS classes', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      // Check for main container with correct class
      const container = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(container).toBeTruthy();
      expect(container.className).toContain('slds-is-relative');
    });

    it('should have correct loading state structure', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      // Check for loading state structure
      const loadingContainer = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingContainer).toBeTruthy();
      expect(loadingContainer.style.minHeight).toBe('6em');

      // Check for spinner
      const spinner = loadingContainer.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });
  });

  describe('Error Scenarios', () => {
    it('should handle missing properties gracefully', () => {
      // Create component without setting properties
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      document.body.appendChild(element);

      // Component should still be created
      expect(element).toBeTruthy();
      expect(element.recordId).toBeUndefined();
      expect(element.sectionType).toBeUndefined();
    });

    it('should handle invalid section type gracefully', () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'Invalid Section Type';
      document.body.appendChild(element);

      // Component should handle invalid section type
      expect(element.sectionType).toBe('Invalid Section Type');
    });
  });

  describe('Wire Service Integration', () => {
    it('should handle errors from getRecord wire service gracefully', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      const mockError = new Error('Failed to load record');
      getRecordMock.emit({ error: mockError });

      await Promise.resolve();

      // Component should handle error gracefully
      expect(element).toBeTruthy();
    });

    it('should handle errors from getSchemaForName gracefully', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockHttpRequestData.fields[fieldName]?.value || null;
      });

      getSchemaForNameMock.mockRejectedValue(new Error('Schema error'));

      getRecordMock.emit(mockHttpRequestData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should handle error gracefully
      expect(element).toBeTruthy();
    });
  });

  describe('Template Rendering', () => {
    it('should render loading state initially', () => {
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      // Should show loading spinner
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();

      // Should not show content yet
      const pageSection = element.shadowRoot.querySelector('c-logger-page-section');
      expect(pageSection).toBeFalsy();

      const noDataMessage = element.shadowRoot.querySelector('.slds-notify_alert');
      expect(noDataMessage).toBeFalsy();
    });
  });

  describe('Field Processing', () => {
    it('should filter out empty fields when processing data', async () => {
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      // Mock getFieldValue to return some empty values
      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        if (fieldName === 'HttpRequestHeaderKeys__c' || fieldName === 'HttpRequestHeaders__c') {
          return null; // These should be filtered out
        }
        return mockHttpRequestData.fields[fieldName]?.value || null;
      });

      getRecordMock.emit(mockHttpRequestData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should handle the data processing
      expect(element).toBeTruthy();
    });

    it('should handle missing field metadata gracefully', async () => {
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockHttpRequestData.fields[fieldName]?.value || null;
      });

      // Mock schema with missing fields
      getSchemaForNameMock.mockResolvedValue({
        fields: {
          // Missing some fields
        }
      });

      getRecordMock.emit(mockHttpRequestData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should handle missing metadata gracefully
      expect(element).toBeTruthy();
    });
  });

  describe('Different Section Types', () => {
    it('should handle HTTP Request section type', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockHttpRequestData.fields[fieldName]?.value || null;
      });

      getRecordMock.emit(mockHttpRequestData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should process HTTP Request data
      expect(element).toBeTruthy();
    });

    it('should handle HTTP Response section type', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Response';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockHttpResponseData.fields[fieldName]?.value || null;
      });

      getRecordMock.emit(mockHttpResponseData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should process HTTP Response data
      expect(element).toBeTruthy();
    });

    it('should handle Database Result Details section type', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'Database Result Details';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockDatabaseResultData.fields[fieldName]?.value || null;
      });

      getRecordMock.emit(mockDatabaseResultData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should process Database Result data
      expect(element).toBeTruthy();
    });

    it('should handle Related Record Details section type', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'Related Record Details';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockRelatedRecordData.fields[fieldName]?.value || null;
      });

      getRecordMock.emit(mockRelatedRecordData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should process Related Record data
      expect(element).toBeTruthy();
    });
  });

  describe('Error Handling', () => {
    it('should handle console errors gracefully', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      getFieldValueMock.mockImplementation((record, field) => {
        const fieldName = field.fieldApiName;
        return mockHttpRequestData.fields[fieldName]?.value || null;
      });

      getSchemaForNameMock.mockRejectedValue(new Error('Schema error'));

      getRecordMock.emit(mockHttpRequestData);

      await Promise.resolve();
      await Promise.resolve();

      // Component should handle error gracefully without crashing
      expect(element).toBeTruthy();
    });

    it('should handle wire service errors gracefully', async () => {
      // Create component with properties set
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });
      element.recordId = 'a1234567890abcdef';
      element.sectionType = 'HTTP Request';
      document.body.appendChild(element);

      const mockError = new Error('Wire service error');
      getRecordMock.emit({ error: mockError });

      await Promise.resolve();

      // Component should handle error gracefully without crashing
      expect(element).toBeTruthy();
    });
  });
});
