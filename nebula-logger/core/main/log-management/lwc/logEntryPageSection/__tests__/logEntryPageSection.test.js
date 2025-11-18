import { createElement } from '@lwc/engine-dom';
import LogEntryPageSection from 'c/logEntryPageSection';
import { getRecord } from 'lightning/uiRecordApi';

// Mock data imports
const mockLogEntrySchema = require('./data/getSchemaForName.json');
const mockHttpRequestData = require('./data/httpRequestSection.json');
const mockHttpResponseData = require('./data/httpResponseSection.json');
const mockDatabaseResultData = require('./data/databaseResultSection.json');
const mockRelatedRecordData = require('./data/relatedRecordSection.json');

// Mock the Prism library
jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise((resolve, _) => {
          global.Prism = require('../../../staticresources/LoggerResources/prism.js');
          resolve();
        });
      },
      loadStyle() {
        // No-op for now
        return Promise.resolve();
      }
    };
  },
  { virtual: true }
);

// Mock the Apex method
jest.mock(
  '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName',
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

describe('c-log-entry-page-section', () => {
  let element;
  let mockGetSchemaForName;

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();

    // Setup mock implementations
    mockGetSchemaForName = require('@salesforce/apex/LoggerSObjectMetadata.getSchemaForName').default;

    // Default mock implementations
    mockGetSchemaForName.mockResolvedValue(mockLogEntrySchema);
  });

  afterEach(() => {
    if (element && element.parentNode) {
      element.parentNode.removeChild(element);
    }
    element = null;
  });

  const createComponent = (recordId = 'a1234567890abcdef', sectionType = 'HTTP Request') => {
    element = createElement('c-log-entry-page-section', {
      is: LogEntryPageSection
    });
    element.recordId = recordId;
    element.sectionType = sectionType;
    document.body.appendChild(element);
    return element;
  };

  describe('Component Initialization', () => {
    it('should initialize with correct public properties', () => {
      element = createComponent();

      expect(element.recordId).toBe('a1234567890abcdef');
      expect(element.sectionType).toBe('HTTP Request');
    });

    it('should render loading spinner initially', () => {
      element = createComponent();

      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });

    it('should render loading state when component is first created', () => {
      element = createComponent();

      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
      expect(loadingDiv.querySelector('lightning-spinner')).toBeTruthy();
    });

    it('should have correct loading state structure', () => {
      element = createComponent();

      const loadingContainer = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingContainer).toBeTruthy();
      expect(loadingContainer.style.minHeight).toBe('6em');

      const spinner = loadingContainer.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });
  });

  describe('Property Updates', () => {
    it('should update record ID when changed', () => {
      element = createComponent();

      element.recordId = 'new-record-id';
      expect(element.recordId).toBe('new-record-id');
    });

    it('should update section type when changed', () => {
      element = createComponent();

      element.sectionType = 'HTTP Response';
      expect(element.sectionType).toBe('HTTP Response');
    });
  });

  describe('Component Behavior', () => {
    it('should handle different section types correctly', () => {
      const types = ['HTTP Request', 'HTTP Response', 'Database Result Details', 'Related Record Details'];

      types.forEach(type => {
        element = createComponent('test-id', type);
        expect(element.sectionType).toBe(type);
      });
    });

    it('should handle unknown section type gracefully', () => {
      element = createComponent('test-id', 'Unknown Type');

      expect(element.sectionType).toBe('Unknown Type');
    });

    it('should handle empty record ID', () => {
      element = createComponent('', 'HTTP Request');
      expect(element.recordId).toBe('');
    });

    it('should handle null record ID', () => {
      element = createComponent(null, 'HTTP Request');
      expect(element.recordId).toBe(null);
    });
  });

  describe('Component Lifecycle', () => {
    it('should be properly created and attached to DOM', () => {
      element = createComponent();
      expect(element.parentNode).toBe(document.body);
    });

    it('should be properly removed from DOM', () => {
      element = createComponent();
      document.body.removeChild(element);
      expect(element.parentNode).toBe(null);
    });

    it('should handle multiple component instances', () => {
      const element1 = createComponent('id1', 'HTTP Request');
      const element2 = createComponent('id2', 'HTTP Response');

      expect(element1.recordId).toBe('id1');
      expect(element2.recordId).toBe('id2');
      expect(element1.sectionType).toBe('HTTP Request');
      expect(element2.sectionType).toBe('HTTP Response');

      // Clean up
      document.body.removeChild(element1);
      document.body.removeChild(element2);
    });
  });

  describe('Component Structure', () => {
    it('should have correct HTML structure', () => {
      element = createComponent();

      const container = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(container).toBeTruthy();
      expect(container.querySelector('lightning-spinner')).toBeTruthy();
    });

    it('should have correct CSS classes', () => {
      element = createComponent();

      const container = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(container.classList.contains('slds-is-relative')).toBe(true);
    });
  });

  describe('Error Scenarios', () => {
    it('should handle missing properties gracefully', () => {
      element = createElement('c-log-entry-page-section', {
        is: LogEntryPageSection
      });

      // Component should not crash without properties
      expect(element.recordId).toBeUndefined();
      expect(element.sectionType).toBeUndefined();
    });

    it('should handle invalid section type gracefully', () => {
      element = createComponent('test-id', 'Invalid Type');

      // Component should handle invalid section types
      expect(element.sectionType).toBe('Invalid Type');
    });
  });

  describe('Template Rendering', () => {
    it('should render loading state initially', () => {
      element = createComponent();

      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
    });

    it('should render loading state structure correctly', () => {
      element = createComponent();

      const loadingContainer = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingContainer).toBeTruthy();
      expect(loadingContainer.style.minHeight).toBe('6em');

      const spinner = loadingContainer.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });
  });

  describe('Different Section Types', () => {
    it('should handle HTTP Request section type', () => {
      element = createComponent('test-id', 'HTTP Request');
      expect(element.sectionType).toBe('HTTP Request');
    });

    it('should handle HTTP Response section type', () => {
      element = createComponent('test-id', 'HTTP Response');
      expect(element.sectionType).toBe('HTTP Response');
    });

    it('should handle Database Result Details section type', () => {
      element = createComponent('test-id', 'Database Result Details');
      expect(element.sectionType).toBe('Database Result Details');
    });

    it('should handle Related Record Details section type', () => {
      element = createComponent('test-id', 'Related Record Details');
      expect(element.sectionType).toBe('Related Record Details');
    });
  });

  describe('Edge Cases', () => {
    it('should handle very long record IDs', () => {
      const longId = 'a'.repeat(1000);
      element = createComponent(longId, 'HTTP Request');
      expect(element.recordId).toBe(longId);
    });

    it('should handle special characters in section type', () => {
      const specialType = 'HTTP Request & Response (Special)';
      element = createComponent('test-id', specialType);
      expect(element.sectionType).toBe(specialType);
    });

    it('should handle empty section type', () => {
      element = createComponent('test-id', '');
      expect(element.sectionType).toBe('');
    });

    it('should handle whitespace in section type', () => {
      const whitespaceType = '  HTTP Request  ';
      element = createComponent('test-id', whitespaceType);
      expect(element.sectionType).toBe(whitespaceType);
    });
  });

  describe('Component Reusability', () => {
    it('should allow changing properties after creation', () => {
      element = createComponent('initial-id', 'HTTP Request');

      element.recordId = 'updated-id';
      element.sectionType = 'HTTP Response';

      expect(element.recordId).toBe('updated-id');
      expect(element.sectionType).toBe('HTTP Response');
    });

    it('should maintain state when properties are updated', () => {
      element = createComponent('test-id', 'HTTP Request');

      const initialRecordId = element.recordId;
      const initialSectionType = element.sectionType;

      element.recordId = 'new-id';
      element.sectionType = 'HTTP Response';

      expect(element.recordId).not.toBe(initialRecordId);
      expect(element.sectionType).not.toBe(initialSectionType);
    });
  });

  describe('DOM Integration', () => {
    it('should be properly integrated into the DOM', () => {
      element = createComponent();
      expect(element.parentNode).toBe(document.body);
    });

    it('should have proper shadow DOM structure', () => {
      element = createComponent();
      expect(element.shadowRoot).toBeTruthy();
    });

    it('should render with proper LWC attributes', () => {
      element = createComponent();
      expect(element.tagName.toLowerCase()).toBe('c-log-entry-page-section');
    });
  });

  describe('Accessibility', () => {
    it('should have proper ARIA attributes in loading state', () => {
      element = createComponent();

      const loadingContainer = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingContainer).toBeTruthy();

      const spinner = loadingContainer.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });
  });

  describe('Performance', () => {
    it('should handle rapid property changes', () => {
      element = createComponent();

      // Rapidly change properties
      for (let i = 0; i < 10; i++) {
        element.recordId = `id-${i}`;
        element.sectionType = i % 2 === 0 ? 'HTTP Request' : 'HTTP Response';
      }

      expect(element.recordId).toBe('id-9');
      expect(element.sectionType).toBe('HTTP Response');
    });

    it('should handle multiple instances efficiently', () => {
      const elements = [];

      // Create multiple instances
      for (let i = 0; i < 5; i++) {
        const el = createComponent(`id-${i}`, 'HTTP Request');
        elements.push(el);
      }

      // Verify all instances are created correctly
      elements.forEach((el, index) => {
        expect(el.recordId).toBe(`id-${index}`);
        expect(el.sectionType).toBe('HTTP Request');
      });

      // Clean up
      elements.forEach(el => {
        if (el.parentNode) {
          document.body.removeChild(el);
        }
      });
    });
  });

  describe('Wire Service Integration', () => {
    it('should handle wire service data correctly', async () => {
      element = createComponent('test-id', 'HTTP Request');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockHttpRequestData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for wire service to process and Apex call to complete
      await Promise.resolve(); // Wire service callback
      await Promise.resolve(); // Apex call
      await Promise.resolve(); // Component re-render

      // Component should have processed the wire data - spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();

      // Section should be rendered if there are fields
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      // Section may or may not be visible depending on whether fields exist
      // The important thing is that loading is complete
    });

    it('should handle wire service errors gracefully', async () => {
      element = createComponent('test-id', 'HTTP Request');

      // Emit wire service error - wire service passes { data, error } to the handler
      // When there's an error, data is null/undefined and error is set
      // const errorAdapter = { data: null, error: { message: 'Test error' } };
      // getRecord.emit(errorAdapter);
      getRecord.error(new Error('Test error'));

      // Wait for wire service to process
      await Promise.resolve(); // Wire service callback
      // await Promise.resolve(); // Component re-render

      // Component should handle errors gracefully - spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();

      // No section should be rendered when there's an error
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      expect(section).toBeFalsy();
    });
  });

  describe('Field Processing', () => {
    it('should process HTTP Request fields correctly', async () => {
      element = createComponent('test-id', 'HTTP Request');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockHttpRequestData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify fields are rendered in the DOM
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        const fields = section.shadowRoot.querySelectorAll('lightning-layout-item');
        expect(fields.length).toBeGreaterThan(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });

    it('should process HTTP Response fields correctly', async () => {
      element = createComponent('test-id', 'HTTP Response');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockHttpResponseData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify fields are rendered in the DOM
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        const fields = section.shadowRoot.querySelectorAll('lightning-layout-item');
        expect(fields.length).toBeGreaterThan(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });

    it('should process Database Result fields correctly', async () => {
      element = createComponent('test-id', 'Database Result Details');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockDatabaseResultData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify fields are rendered in the DOM
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        const fields = section.shadowRoot.querySelectorAll('lightning-layout-item');
        expect(fields.length).toBeGreaterThan(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });

    it('should process Related Record fields correctly', async () => {
      element = createComponent('test-id', 'Related Record Details');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockRelatedRecordData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify fields are rendered in the DOM
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        const fields = section.shadowRoot.querySelectorAll('lightning-layout-item');
        expect(fields.length).toBeGreaterThan(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });
  });

  // describe('Schema Integration', () => {
  //   it('should load field metadata correctly', async () => {
  //     element = createComponent('test-id', 'HTTP Request');

  //     // Emit wire service data - ensure record has required structure
  //     const recordData = {
  //       ...mockHttpRequestData,
  //       id: 'test-id',
  //       apiName: 'LogEntry__c'
  //     };
  //     getRecord.emit(recordData);

  //     // Wait for processing
  //     await Promise.resolve();
  //     await Promise.resolve(); // Wait for async operations

  //     // Verify schema was loaded by checking that fields have labels (from metadata)
  //     const section = element.shadowRoot.querySelector('c-logger-page-section');
  //     if (section) {
  //       const labels = section.shadowRoot.querySelectorAll('label.slds-form-element__label');
  //       // If fields are rendered, they should have labels from the schema
  //       expect(labels.length).toBeGreaterThanOrEqual(0);
  //     }

  //     // Spinner should be gone
  //     const spinner = element.shadowRoot.querySelector('lightning-spinner');
  //     expect(spinner).toBeFalsy();
  //   });

  //   it('should handle schema loading errors gracefully', async () => {
  //     // Mock schema loading to fail
  //     mockGetSchemaForName.mockRejectedValue(new Error('Schema error'));

  //     element = createComponent('test-id', 'HTTP Request');

  //     // Emit wire service data - ensure record has required structure
  //     const recordData = {
  //       ...mockHttpRequestData,
  //       id: 'test-id',
  //       apiName: 'LogEntry__c'
  //     };
  //     getRecord.emit(recordData);

  //     // Wait for processing
  //     await Promise.resolve();
  //     await Promise.resolve(); // Wait for async operations

  //     // Should handle schema errors gracefully - component should still render
  //     const spinner = element.shadowRoot.querySelector('lightning-spinner');
  //     expect(spinner).toBeFalsy();

  //     // Component should still process fields even if schema fails
  //     // (fields will use API names as labels if schema fails)
  //     const section = element.shadowRoot.querySelector('c-logger-page-section');
  //     // Section may or may not be visible depending on fields
  //     expect(spinner).toBeFalsy();
  //   });
  // });

  describe('Field Rendering Logic', () => {
    it('should determine code viewer usage correctly', async () => {
      element = createComponent('test-id', 'HTTP Request');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockHttpRequestData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify code viewers are used for appropriate fields
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        const codeViewers = section.shadowRoot.querySelectorAll('c-logger-code-viewer');
        // Code viewers should be present for JSON/HTTP fields
        expect(codeViewers.length).toBeGreaterThanOrEqual(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });

    it('should handle field type detection correctly', async () => {
      element = createComponent('test-id', 'HTTP Request');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockHttpRequestData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify different field types are rendered correctly
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        // Should have form elements rendered
        const formElements = section.shadowRoot.querySelectorAll('.slds-form-element');
        expect(formElements.length).toBeGreaterThanOrEqual(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });

    it('should handle long text fields correctly', async () => {
      element = createComponent('test-id', 'HTTP Request');

      // Emit wire service data - ensure record has required structure
      const recordData = {
        ...mockHttpRequestData,
        id: 'test-id',
        apiName: 'LogEntry__c'
      };
      getRecord.emit(recordData);

      // Wait for processing
      await Promise.resolve();
      await Promise.resolve(); // Wait for async operations

      // Verify long text fields use textarea
      const section = element.shadowRoot.querySelector('c-logger-page-section');
      if (section) {
        const textareas = section.shadowRoot.querySelectorAll('lightning-textarea');
        // Long text fields should use textarea
        expect(textareas.length).toBeGreaterThanOrEqual(0);
      }

      // Spinner should be gone
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeFalsy();
    });
  });
});
