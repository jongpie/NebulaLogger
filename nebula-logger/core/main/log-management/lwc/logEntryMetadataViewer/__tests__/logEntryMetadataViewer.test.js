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

// Number of microtask hops to drain across getRecord, c-logger-code-viewer creation,
// and the Promise.all(map(async)) chain inside _loadPrismResources.
const flushPromises = async () => {
  for (let i = 0; i < 8; i++) {
    /* eslint-disable-next-line no-await-in-loop */
    await Promise.resolve();
  }
};

const buildSnippet = overrides => ({
  Code: 'some-code-block',
  ApiVersion: '65.0',
  TotalLinesOfCode: 123,
  StartingLineNumber: 55,
  TargetLineNumber: 65,
  EndingLineNumber: 68,
  ...overrides
});

const buildLogEntryRecord = ({ source, metadataType, snippet }) => {
  const apiNameField = source === 'Exception' ? 'ExceptionSourceApiName__c' : 'OriginSourceApiName__c';
  const apiVersionField = source === 'Exception' ? 'ExceptionSourceApiVersion__c' : 'OriginSourceApiVersion__c';
  const metadataTypeField = source === 'Exception' ? 'ExceptionSourceMetadataType__c' : 'OriginSourceMetadataType__c';
  const snippetField = source === 'Exception' ? 'ExceptionSourceSnippet__c' : 'OriginSourceSnippet__c';
  return {
    fields: {
      [apiNameField]: { value: 'SomeApexClass' },
      [apiVersionField]: { value: '65.0' },
      [metadataTypeField]: { value: metadataType },
      [snippetField]: { value: snippet === null ? null : JSON.stringify(snippet) }
    }
  };
};

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
    // Drain microtasks across getRecord, c-logger-code-viewer creation,
    // and the Promise.all(map(async)) chain inside _loadPrismResources.
    for (let i = 0; i < 8; i++) {
      /* eslint-disable-next-line no-await-in-loop */
      await Promise.resolve();
    }

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
    // Drain microtasks across getRecord, c-logger-code-viewer creation,
    // and the Promise.all(map(async)) chain inside _loadPrismResources.
    for (let i = 0; i < 8; i++) {
      /* eslint-disable-next-line no-await-in-loop */
      await Promise.resolve();
    }

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

  it('should show a spinner before the wired log entry record loads', async () => {
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';

    document.body.appendChild(element);
    await Promise.resolve();

    expect(element.shadowRoot.querySelector('lightning-spinner')).toBeTruthy();
    expect(element.shadowRoot.querySelector('c-logger-page-section')).toBeNull();
    expect(element.shadowRoot.querySelector('c-logger-code-viewer')).toBeNull();
  });

  it('should render "No source snippet available" when the snippet field is empty', async () => {
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';

    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: null }));
    await flushPromises();

    expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    expect(element.shadowRoot.querySelector('c-logger-page-section')).toBeNull();
    expect(element.shadowRoot.querySelector('c-logger-code-viewer')).toBeNull();
    expect(element.shadowRoot.textContent).toContain('No source snippet available');
  });

  it('should produce a .trigger title for ApexTrigger metadata', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';

    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexTrigger', snippet: buildSnippet() }));
    await flushPromises();

    const codeViewerTitle = element.shadowRoot.querySelector('c-logger-code-viewer span[slot="title"]');
    expect(codeViewerTitle).toBeTruthy();
    expect(codeViewerTitle.textContent).toBe('SomeApexClass.trigger - 65.0');
  });

  it('should hide the "View Full Source" button when there is no full source metadata', async () => {
    // getMetadata resolves with an empty object → hasFullSourceMetadata is false.
    getMetadata.mockResolvedValue({});
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';

    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();

    const actionsSlotButtons = element.shadowRoot.querySelectorAll('c-logger-code-viewer span[slot="actions"] lightning-button');
    expect(actionsSlotButtons.length).toBe(0);
  });

  it('should open the full-source modal with success notification when code is unmodified', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();

    const viewFullSourceButton = element.shadowRoot.querySelector('c-logger-code-viewer span[slot="actions"] lightning-button');
    viewFullSourceButton.click();
    await flushPromises();

    const modalSection = element.shadowRoot.querySelector('section.slds-modal');
    expect(modalSection).toBeTruthy();
    const modalTitle = element.shadowRoot.querySelector('section.slds-modal h2.slds-text-heading_medium');
    expect(modalTitle.textContent).toBe('Full Source: SomeApexClass.cls - 65.0');
    const notification = element.shadowRoot.querySelector('section.slds-modal div[role="alert"]');
    expect(notification.classList.contains('slds-theme_success')).toBe(true);
    expect(notification.classList.contains('slds-theme_warning')).toBe(false);
    const notificationIcon = notification.querySelector('lightning-icon');
    expect(notificationIcon.iconName).toBe('utility:success');
    const notificationMessage = notification.querySelector('h2');
    expect(notificationMessage.textContent).toBe('This Apex code has not been modified since this log entry was generated.');
    const modalCodeViewer = element.shadowRoot.querySelector('section.slds-modal c-logger-code-viewer');
    expect(modalCodeViewer).toBeTruthy();
    expect(modalCodeViewer.code).toBe('full code here');
  });

  it('should open the full-source modal with warning notification when code has been modified', async () => {
    getMetadata.mockResolvedValue({ Code: 'modified code', HasCodeBeenModified: true });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();

    element.shadowRoot.querySelector('c-logger-code-viewer span[slot="actions"] lightning-button').click();
    await flushPromises();

    const notification = element.shadowRoot.querySelector('section.slds-modal div[role="alert"]');
    expect(notification.classList.contains('slds-theme_success')).toBe(false);
    expect(notification.classList.contains('slds-theme_warning')).toBe(true);
    const notificationIcon = notification.querySelector('lightning-icon');
    expect(notificationIcon.iconName).toBe('utility:warning');
    const notificationMessage = notification.querySelector('h2');
    expect(notificationMessage.textContent).toBe('This Apex code has been modified since this log entry was generated.');
  });

  it('should close the modal when the header close icon is clicked', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();

    element.shadowRoot.querySelector('c-logger-code-viewer span[slot="actions"] lightning-button').click();
    await flushPromises();
    expect(element.shadowRoot.querySelector('section.slds-modal')).toBeTruthy();

    element.shadowRoot.querySelector('section.slds-modal button.slds-modal__close').click();
    await flushPromises();
    expect(element.shadowRoot.querySelector('section.slds-modal')).toBeNull();
  });

  it('should close the modal when the footer Close button is clicked', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();

    element.shadowRoot.querySelector('c-logger-code-viewer span[slot="actions"] lightning-button').click();
    await flushPromises();

    element.shadowRoot.querySelector('lightning-button[data-id="close-btn"]').click();
    await flushPromises();
    expect(element.shadowRoot.querySelector('section.slds-modal')).toBeNull();
  });

  it('should close the modal when the Escape key is pressed', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();

    element.shadowRoot.querySelector('c-logger-code-viewer span[slot="actions"] lightning-button').click();
    await flushPromises();

    const modalSection = element.shadowRoot.querySelector('section.slds-modal');
    modalSection.dispatchEvent(new KeyboardEvent('keydown', { code: 'Escape', bubbles: true }));
    await flushPromises();

    expect(element.shadowRoot.querySelector('section.slds-modal')).toBeNull();
  });

  it('should leave the modal open when a non-Escape key is pressed', async () => {
    getMetadata.mockResolvedValue({ Code: 'full code here', HasCodeBeenModified: false });
    const element = createElement('c-log-entry-metadata-viewer', { is: LogEntryMetadataViewer });
    element.sourceMetadata = 'Exception';
    element.recordId = 'test-log-entry-id';
    document.body.appendChild(element);
    getRecord.emit(buildLogEntryRecord({ source: 'Exception', metadataType: 'ApexClass', snippet: buildSnippet() }));
    await flushPromises();
    element.shadowRoot.querySelector('c-logger-code-viewer span[slot="actions"] lightning-button').click();
    await flushPromises();

    const modalSection = element.shadowRoot.querySelector('section.slds-modal');
    modalSection.dispatchEvent(new KeyboardEvent('keydown', { code: 'Enter', bubbles: true }));
    await flushPromises();

    expect(element.shadowRoot.querySelector('section.slds-modal')).toBeTruthy();
  });
});
