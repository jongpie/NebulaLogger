import { createElement } from '@lwc/engine-dom';
import LogEntryMetadataViewer from 'c/logEntryMetadataViewer';
import getMetadata from '@salesforce/apex/LogEntryMetadataViewerController.getMetadata';
import { getRecord } from 'lightning/uiRecordApi';

// Provide Prism so c-logger-code-viewer can highlight without loading real resources
jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise(resolve => {
          global.Prism = require('../../../staticresources/LoggerResources/prism.min.js');
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
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('should display exception source metadata snippet for Apex class exception source', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', {
      is: LogEntryMetadataViewer
    });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    const mockApexClassSnippet = {
      Code: 'some-code-block',
      ApiVersion: '65.0',
      TotalLinesOfCode: 123,
      StartingLineNumber: 55,
      TargetLineNumber: 65,
      EndingLineNumber: 68
    };
    const mockLogEntryRecord = {
      fields: {
        ExceptionSourceApiName__c: { value: 'SomeApexClass' },
        ExceptionSourceApiVersion__c: { value: '65.0' },
        ExceptionSourceMetadataType__c: { value: 'ApexClass' },
        ExceptionSourceSnippet__c: { value: JSON.stringify(mockApexClassSnippet) }
      }
    };

    document.body.appendChild(element);
    getRecord.emit(mockLogEntryRecord);
    await Promise.resolve('resolves getRecord() call');
    await Promise.resolve('resolves creating an instance of c-logger-code-viewer');
    await Promise.resolve('resolves loading & running PrismJS inside of c-logger-code-viewer');

    const sectionTitle = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
    expect(sectionTitle).toBeTruthy();
    expect(sectionTitle.textContent).toBe('Exception Source Metadata');
    const codeViewerTitle = element.shadowRoot.querySelector('c-logger-code-viewer span[slot="title"]');
    expect(codeViewerTitle).toBeTruthy();
    expect(codeViewerTitle.textContent).toBe(
      `${mockLogEntryRecord.fields.ExceptionSourceApiName__c.value}.cls - ${mockLogEntryRecord.fields.ExceptionSourceApiVersion__c.value}`
    );
    const codeViewer = element.shadowRoot.querySelector('c-logger-code-viewer');
    const prismCode = codeViewer.shadowRoot.querySelector('div.prism-viewer pre code');
    expect(prismCode).toBeTruthy();
    expect(prismCode.textContent).toContain(mockApexClassSnippet.Code);
    const actionsSlotButtons = element.shadowRoot.querySelectorAll('c-logger-code-viewer span[slot="actions"] lightning-button');
    expect(actionsSlotButtons).toBeTruthy();
    expect(actionsSlotButtons.length).toBe(1);
    const viewFullSourceButton = actionsSlotButtons[0];
    expect(viewFullSourceButton.iconName).toBe('utility:apex');
    expect(viewFullSourceButton.label).toBe('View Full Source');
    expect(viewFullSourceButton.variant).toBe('inverse');
  });

  it('should display origin source metadata snippet for Apex class origin source', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', {
      is: LogEntryMetadataViewer
    });
    element.sourceMetadata = 'Origin';
    element.recordId = 'test-log-entry-id';
    const mockApexClassSnippet = {
      Code: 'some-code-block',
      ApiVersion: '65.0',
      TotalLinesOfCode: 123,
      StartingLineNumber: 55,
      TargetLineNumber: 65,
      EndingLineNumber: 68
    };
    const mockLogEntryRecord = {
      fields: {
        OriginSourceApiName__c: { value: 'SomeApexClass' },
        OriginSourceApiVersion__c: { value: '65.0' },
        OriginSourceMetadataType__c: { value: 'ApexClass' },
        OriginSourceSnippet__c: { value: JSON.stringify(mockApexClassSnippet) }
      }
    };

    document.body.appendChild(element);
    getRecord.emit(mockLogEntryRecord);
    await Promise.resolve('resolves getRecord() call');
    await Promise.resolve('resolves creating an instance of c-logger-code-viewer');
    await Promise.resolve('resolves loading & running PrismJS inside of c-logger-code-viewer');

    const sectionTitle = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
    expect(sectionTitle).toBeTruthy();
    expect(sectionTitle.textContent).toBe('Origin Source Metadata');
    const codeViewerTitle = element.shadowRoot.querySelector('c-logger-code-viewer span[slot="title"]');
    expect(codeViewerTitle).toBeTruthy();
    expect(codeViewerTitle.textContent).toBe(
      `${mockLogEntryRecord.fields.OriginSourceApiName__c.value}.cls - ${mockLogEntryRecord.fields.OriginSourceApiVersion__c.value}`
    );
    const codeViewer = element.shadowRoot.querySelector('c-logger-code-viewer');
    const prismCode = codeViewer.shadowRoot.querySelector('div.prism-viewer pre code');
    expect(prismCode).toBeTruthy();
    expect(prismCode.textContent).toContain(mockApexClassSnippet.Code);
    const actionsSlotButtons = element.shadowRoot.querySelectorAll('c-logger-code-viewer span[slot="actions"] lightning-button');
    expect(actionsSlotButtons).toBeTruthy();
    expect(actionsSlotButtons.length).toBe(1);
    const viewFullSourceButton = actionsSlotButtons[0];
    expect(viewFullSourceButton.iconName).toBe('utility:apex');
    expect(viewFullSourceButton.label).toBe('View Full Source');
    expect(viewFullSourceButton.variant).toBe('inverse');
  });
});
