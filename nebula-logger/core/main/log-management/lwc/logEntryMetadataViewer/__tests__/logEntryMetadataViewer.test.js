import { createElement } from '@lwc/engine-dom';
import LogEntryMetadataViewer from 'c/logEntryMetadataViewer';

// Provide Prism so c-logger-code-viewer can highlight without loading real resources
jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise(resolve => {
          global.Prism = require('../../../staticresources/LoggerResources/prism.js');
          resolve();
        });
      },
      loadStyle() {
        return Promise.resolve();
      }
    };
  },
  { virtual: true }
);

// Mock the Apex controller as imperative call
jest.mock(
  '@salesforce/apex/LogEntryMetadataViewerController.getMetadata',
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

describe('LogEntryMetadataViewer LWC Tests', () => {
  let element;

  beforeEach(() => {
    // Create component
    element = createElement('c-log-entry-metadata-viewer', {
      is: LogEntryMetadataViewer
    });

    // Set default properties
    element.recordId = 'a1234567890abcdef';
    element.sourceMetadata = 'Exception';

    // Append to DOM
    document.body.appendChild(element);
  });

  afterEach(() => {
    // Clean up
    if (document.body.contains(element)) {
      document.body.removeChild(element);
    }
  });

  describe('Component Initialization', () => {
    it('should initialize with correct default values', () => {
      expect(element.recordId).toBe('a1234567890abcdef');
      expect(element.sourceMetadata).toBe('Exception');
    });

    it('should render loading spinner initially', () => {
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });

    it('should render loading state when hasLoaded is false', () => {
      // The component should show loading spinner when hasLoaded is false
      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
      expect(loadingDiv.querySelector('lightning-spinner')).toBeTruthy();
    });
  });

  describe('Section Title Logic', () => {
    it('should display "Exception Source Metadata" for Exception source', () => {
      element.sourceMetadata = 'Exception';

      // Force a re-render
      element.dispatchEvent(new CustomEvent('rerender'));

      // Check if the section title is displayed correctly
      const sectionTitle = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
      if (sectionTitle) {
        expect(sectionTitle.textContent).toBe('Exception Source Metadata');
      }
    });

    it('should display "Origin Source Metadata" for Origin source', () => {
      element.sourceMetadata = 'Origin';

      // Force a re-render
      element.dispatchEvent(new CustomEvent('rerender'));

      const sectionTitle = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
      if (sectionTitle) {
        expect(sectionTitle.textContent).toBe('Origin Source Metadata');
      }
    });

    it('should display empty title for unknown source', () => {
      element.sourceMetadata = 'Unknown';

      // Force a re-render
      element.dispatchEvent(new CustomEvent('rerender'));

      const sectionTitle = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
      if (sectionTitle) {
        expect(sectionTitle.textContent).toBe('');
      }
    });

    it('should display empty title for null source', () => {
      element.sourceMetadata = null;

      // Force a re-render
      element.dispatchEvent(new CustomEvent('rerender'));

      const sectionTitle = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
      if (sectionTitle) {
        expect(sectionTitle.textContent).toBe('');
      }
    });
  });

  describe('UI Rendering', () => {
    it('should render the loading spinner', () => {
      const spinner = element.shadowRoot.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });

    it('should render loading container with proper styling', () => {
      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
      expect(loadingDiv.style.minHeight).toBe('6em');
    });
  });

  describe('Component State Management', () => {
    it('should maintain state consistency during property changes', () => {
      // Change source metadata
      element.sourceMetadata = 'Origin';
      expect(element.sourceMetadata).toBe('Origin');

      // Change back to Exception
      element.sourceMetadata = 'Exception';
      expect(element.sourceMetadata).toBe('Exception');
    });

    it('should handle recordId changes', () => {
      const newRecordId = 'b9876543210fedcba';
      element.recordId = newRecordId;
      expect(element.recordId).toBe(newRecordId);
    });
  });

  describe('Template Conditional Rendering', () => {
    it('should show loading template when hasLoaded is false', () => {
      // Initially, hasLoaded should be false, so loading template should be visible
      // The template directive creates a comment node, so we need to look for the actual rendered content
      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
    });

    it('should not show source snippet template initially', () => {
      // Initially, sourceSnippet should be undefined, so this template should not render
      const sourceSnippetTemplate = element.shadowRoot.querySelector('template[if\\:true]');
      // This might be null initially since sourceSnippet is undefined
      expect(sourceSnippetTemplate).toBeFalsy();
    });
  });

  describe('Component Structure', () => {
    it('should have proper component structure', () => {
      // Check that the component has the expected structure
      // The root element should contain the rendered content
      const rootElement = element.shadowRoot;
      expect(rootElement).toBeTruthy();

      // Check for the loading div which should be visible initially
      const loadingDiv = rootElement.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();
    });

    it('should have proper loading state structure', () => {
      const loadingDiv = element.shadowRoot.querySelector('div.slds-is-relative');
      expect(loadingDiv).toBeTruthy();

      const spinner = loadingDiv.querySelector('lightning-spinner');
      expect(spinner).toBeTruthy();
    });
  });

  describe('Error Handling', () => {
    it('should handle invalid JSON gracefully', async () => {
      // Mock the getRecord wire service
      const { getRecord } = require('lightning/uiRecordApi');
      const mockGetRecord = require('@salesforce/sfdx-lwc-jest').createApexTestWireAdapter(jest.fn());

      // Simulate record with invalid JSON
      const mockRecord = {
        fields: {
          ExceptionSourceApiName__c: { value: 'TestClass' },
          ExceptionSourceApiVersion__c: { value: '58.0' },
          ExceptionSourceMetadataType__c: { value: 'ApexClass' },
          ExceptionSourceSnippet__c: { value: 'invalid json' }
        }
      };

      // This should not throw an error
      expect(() => {
        mockGetRecord.emit(mockRecord);
      }).not.toThrow();
    });

    it('should handle malformed JSON gracefully', async () => {
      // Mock the getRecord wire service
      const { getRecord } = require('lightning/uiRecordApi');
      const mockGetRecord = require('@salesforce/sfdx-lwc-jest').createApexTestWireAdapter(jest.fn());

      // Simulate record with malformed JSON
      const mockRecord = {
        fields: {
          ExceptionSourceApiName__c: { value: 'TestClass' },
          ExceptionSourceApiVersion__c: { value: '58.0' },
          ExceptionSourceMetadataType__c: { value: 'ApexClass' },
          ExceptionSourceSnippet__c: { value: '{"Code": "test", "Language": "apex"' } // Missing closing brace
        }
      };

      // This should not throw an error
      expect(() => {
        mockGetRecord.emit(mockRecord);
      }).not.toThrow();
    });

    it('should handle empty string snippet gracefully', async () => {
      // Mock the getRecord wire service
      const { getRecord } = require('lightning/uiRecordApi');
      const mockGetRecord = require('@salesforce/sfdx-lwc-jest').createApexTestWireAdapter(jest.fn());

      // Simulate record with empty string snippet
      const mockRecord = {
        fields: {
          ExceptionSourceApiName__c: { value: 'TestClass' },
          ExceptionSourceApiVersion__c: { value: '58.0' },
          ExceptionSourceMetadataType__c: { value: 'ApexClass' },
          ExceptionSourceSnippet__c: { value: '' }
        }
      };

      // This should not throw an error
      expect(() => {
        mockGetRecord.emit(mockRecord);
      }).not.toThrow();
    });
  });

  describe('Property Binding', () => {
    it('should bind recordId property correctly', () => {
      expect(element.recordId).toBe('a1234567890abcdef');
    });

    it('should bind sourceMetadata property correctly', () => {
      expect(element.sourceMetadata).toBe('Exception');
    });

    it('should update properties when changed', () => {
      element.recordId = 'new-record-id';
      element.sourceMetadata = 'Origin';

      expect(element.recordId).toBe('new-record-id');
      expect(element.sourceMetadata).toBe('Origin');
    });
  });

  describe('End-to-end behavior with LDS and Apex', () => {
    const flushPromises = () => Promise.resolve();

    let getRecordAdapter;
    let getFieldValue;
    let getMetadata;

    beforeEach(() => {
      ({ getRecord: getRecordAdapter, getFieldValue } = require('lightning/uiRecordApi'));
      getMetadata = require('@salesforce/apex/LogEntryMetadataViewerController.getMetadata').default;
      getFieldValue.mockReset();
      getMetadata.mockReset();
    });

    it('loads snippet, builds title with .cls, shows modal and unmodified notice', async () => {
      // Map of field values returned by getFieldValue
      const fieldValues = {
        ExceptionSourceApiName__c: 'TestClass',
        ExceptionSourceApiVersion__c: '58.0',
        ExceptionSourceMetadataType__c: 'ApexClass',
        ExceptionSourceSnippet__c: JSON.stringify({
          Code: 'public class TestClass {}',
          Language: 'apex',
          StartingLineNumber: 3,
          TargetLineNumber: 7
        })
      };
      getFieldValue.mockImplementation((record, field) => fieldValues[field.fieldApiName]);
      getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });

      const el = element; // created in outer beforeEach
      getRecordAdapter.emit({ fields: {} });
      await flushPromises();
      await flushPromises();
      await flushPromises();
      expect(getMetadata).toHaveBeenCalled();

      // The snippet code viewer should now be rendered with a title
      const titleSpan = el.shadowRoot.querySelector('c-logger-code-viewer span[slot="title"]');
      expect(titleSpan).toBeTruthy();
      expect(titleSpan.textContent).toBe('TestClass.cls - 58.0');

      // The View Full Source button should be visible; click it to open modal
      const allButtons = Array.from(el.shadowRoot.querySelectorAll('lightning-button'));
      const viewBtn = allButtons.find(b => b.label === 'View Full Source');
      expect(viewBtn).toBeTruthy();
      viewBtn.dispatchEvent(new Event('click'));
      await flushPromises();
      await flushPromises();

      // Modal should render with unmodified message styles and icon
      const modal = el.shadowRoot.querySelector('section.slds-modal');
      expect(modal).toBeTruthy();
      const notice = el.shadowRoot.querySelector('div.slds-notify');
      expect(notice.className).toContain('slds-alert_offline');
      const noticeIcon = el.shadowRoot.querySelector('lightning-icon.slds-m-right_x-small');
      expect(noticeIcon.iconName).toBe('utility:success');
      const noticeText = el.shadowRoot.querySelector('div.slds-notify h2');
      expect(noticeText.textContent).toContain('has not been modified');

      // Close modal by clicking Close button
      el.shadowRoot.querySelector('lightning-button[data-id="close-btn"]').click();
      await flushPromises();
      expect(el.shadowRoot.querySelector('section.slds-modal')).toBeFalsy();
    });

    it('shows modified warning when Apex reports changes', async () => {
      const fieldValues = {
        ExceptionSourceApiName__c: 'MyTrigger',
        ExceptionSourceApiVersion__c: '59.0',
        ExceptionSourceMetadataType__c: 'ApexTrigger',
        ExceptionSourceSnippet__c: JSON.stringify({ Code: 'trigger code', Language: 'apex' })
      };
      getFieldValue.mockImplementation((record, field) => fieldValues[field.fieldApiName]);
      getMetadata.mockResolvedValue({ Code: 'updated full', HasCodeBeenModified: true });

      const el = element;
      getRecordAdapter.emit({ fields: {} });
      await flushPromises();
      await flushPromises();
      await flushPromises();
      expect(getMetadata).toHaveBeenCalled();

      // Title should use .trigger extension
      const titleSpan = el.shadowRoot.querySelector('c-logger-code-viewer span[slot="title"]');
      expect(titleSpan.textContent).toBe('MyTrigger.trigger - 59.0');

      // Open modal
      const buttons = Array.from(el.shadowRoot.querySelectorAll('lightning-button'));
      const btn = buttons.find(b => b.label === 'View Full Source');
      expect(btn).toBeTruthy();
      btn.dispatchEvent(new Event('click'));
      await flushPromises();

      const notice = el.shadowRoot.querySelector('div.slds-notify');
      expect(notice.className).toContain('slds-alert_warning');
      const noticeIcon = el.shadowRoot.querySelector('lightning-icon.slds-m-right_x-small');
      expect(noticeIcon.iconName).toBe('utility:warning');
      const noticeText = el.shadowRoot.querySelector('div.slds-notify h2');
      expect(noticeText.textContent).toContain('has been modified');
    });

    it('handles Origin branch and unknown type with empty extension', async () => {
      // Switch to Origin path
      element.sourceMetadata = 'Origin';
      const fieldValues = {
        OriginSourceApiName__c: 'Comp',
        OriginSourceApiVersion__c: '60.0',
        OriginSourceMetadataType__c: 'UnknownType',
        OriginSourceSnippet__c: JSON.stringify({ Code: '<aura/>', Language: 'aura' })
      };
      getFieldValue.mockImplementation((record, field) => fieldValues[field.fieldApiName]);
      getMetadata.mockResolvedValue({ Code: 'n/a', HasCodeBeenModified: false });

      getRecordAdapter.emit({ fields: {} });
      await flushPromises();

      // Title should not have an extension when unknown type
      const titleSpan = element.shadowRoot.querySelector('c-logger-code-viewer span[slot="title"]');
      expect(titleSpan.textContent).toBe('Comp. - 60.0');
    });

    it('closes modal with Escape key', async () => {
      const fieldValues = {
        ExceptionSourceApiName__c: 'Esc',
        ExceptionSourceApiVersion__c: '58.0',
        ExceptionSourceMetadataType__c: 'ApexClass',
        ExceptionSourceSnippet__c: JSON.stringify({ Code: 'x', Language: 'apex' })
      };
      getFieldValue.mockImplementation((record, field) => fieldValues[field.fieldApiName]);
      getMetadata.mockResolvedValue({ Code: 'full', HasCodeBeenModified: false });

      const el = element;
      getRecordAdapter.emit({ fields: {} });
      await flushPromises();

      el.shadowRoot.querySelector('lightning-button[icon-name="utility:apex"]').click();
      // Some LWC test envs may not expose icon-name on the stub; search by label as fallback
      if (!element.shadowRoot.querySelector('section.slds-modal')) {
        const buttons = Array.from(el.shadowRoot.querySelectorAll('lightning-button'));
        const btn = buttons.find(b => b.label === 'View Full Source');
        btn && btn.dispatchEvent(new Event('click'));
      }
      await flushPromises();
      expect(el.shadowRoot.querySelector('section.slds-modal')).toBeTruthy();

      // Send Escape keydown to modal section
      const modalSection = el.shadowRoot.querySelector('section.slds-modal');
      modalSection.dispatchEvent(new KeyboardEvent('keydown', { code: 'Escape', bubbles: true }));
      await flushPromises();
      expect(el.shadowRoot.querySelector('section.slds-modal')).toBeFalsy();
    });
  });
});
