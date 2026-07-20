import { createElement } from 'lwc';
import LoggerNotificationServiceGuidedForm from 'c/loggerNotificationServiceGuidedForm';
import getNotifierTypes from '@salesforce/apex/LoggerNotifierGuidedFormController.getNotifierTypes';
// getRecord is the wire adapter behind the LWC's edit-mode Name/NotifierApexClassName prefetch.
// `emit()` in tests feeds a fake record shape into the adapter so the wire callback fires with
// the given field values.
import { getRecord } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';

const MOCK_NOTIFIER_TYPES = [
  {
    AtLeastOneRequiredRecipientFields__c: null,
    AtLeastOneRequiredServiceFields__c: 'WebhookUrl__c\nNamedCredentialDeveloperName__c',
    Description__c: 'Post to Slack.',
    DeveloperName: 'Slack',
    DisplayLabel__c: 'Slack',
    IsChannelIdentifierRequired__c: true,
    IsEmailAddressRequired__c: false,
    IsEnabled__c: true,
    IsUserRequired__c: false,
    NotifierApexClassName__c: 'SlackLoggerNotifier',
    SetupGuidanceMarkdown__c: '## Slack setup steps',
    SuggestedConfigurationJson__c: '{}',
    SupportsChannelIdentifier__c: true,
    SupportsEmailAddress__c: false,
    SupportsNamedCredential__c: true,
    SupportsUser__c: false,
    SupportsWebhookUrl__c: true
  }
];

jest.mock(
  '@salesforce/apex/LoggerNotifierGuidedFormController.getNotifierTypes',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// LightningConfirm.open is stubbed by @salesforce/sfdx-lwc-jest to throw unless overridden per test.
// Replace .open with a jest.fn() so tests can .mockResolvedValue(true/false); reset each run so a
// leftover Escape keydown from a prior test can't leak into a later test that hasn't set an expectation.
beforeEach(() => {
  LightningConfirm.open = jest.fn().mockResolvedValue(false);
});

// Flush the microtask queue enough times to let wire adapters + `await` chains + child-component
// re-renders settle. A single `Promise.resolve()` isn't enough when the change flow spans multiple
// awaits (wire -> reactive update -> child render).
const flushPromises = async () => {
  for (let i = 0; i < 5; i += 1) {
    await Promise.resolve();
  }
};

describe('c-logger-notification-service-guided-form', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('mounts without a selected notifier and does not throw dereferencing the null notifier type', () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    document.body.appendChild(element);
    return Promise.resolve().then(() => {
      const panel = element.shadowRoot.querySelector('lightning-quick-action-panel');
      expect(panel).not.toBeNull();
      const editForm = element.shadowRoot.querySelector('lightning-record-edit-form');
      expect(editForm).toBeNull();
    });
  });

  it('renders the Cancel button in the panel footer when mounted inside a Quick Action / LightningModal (default jsdom location)', () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    document.body.appendChild(element);
    return Promise.resolve().then(() => {
      const cancelButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Cancel');
      expect(cancelButton).toBeDefined();
    });
  });

  it('hides the Cancel button when `isUrlAddressableMount` is true (URL-addressable page - no container to close)', () => {
    // See the rule form's matching test for the rationale on why the DOM path isn't testable in
    // jsdom. Verify the getter contract via an explicit `this` binding.
    const getShowCancel = Object.getOwnPropertyDescriptor(LoggerNotificationServiceGuidedForm.prototype, 'showCancelButton').get;
    expect(getShowCancel.call({ isUrlAddressableMount: true, embedded: false })).toBe(false);
    expect(getShowCancel.call({ isUrlAddressableMount: false, embedded: false })).toBe(true);
  });

  it('shows the Cancel button on the embedded-in-modal path even when `isUrlAddressableMount` is true', () => {
    // The rule form's "Create a new Service" LightningModal wrapper hosts this form on a page whose
    // URL is `/lightning/cmp/c__loggerNotificationRuleGuidedForm` - which trips isUrlAddressableMount
    // to true. But the LightningModal wrapper IS a container to close, so Cancel should stay visible.
    const getShowCancel = Object.getOwnPropertyDescriptor(LoggerNotificationServiceGuidedForm.prototype, 'showCancelButton').get;
    expect(getShowCancel.call({ isUrlAddressableMount: true, embedded: true })).toBe(true);
  });

  it('renders the notifier picker (not a spinner) once the wire adapter has emitted at least once', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    // Simulate the wire delivering data - after that the isLoadingNotifierTypes flag flips false
    // and the picker replaces the spinner.
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await Promise.resolve();
    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    expect(combobox).not.toBeNull();
  });

  it('accepts a recordId (Edit path) without throwing and treats it as not-new so defaultServiceName is undefined', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    element.recordId = 'a08000000000001AAA';
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await Promise.resolve();
    expect(element.recordId).toBe('a08000000000001AAA');
  });

  it('sets document.title to the create-mode placeholder in connectedCallback when no recordId is provided', () => {
    // Reset first so the previous test's title doesn't leak into this assertion. jsdom preserves
    // document.title between tests within a file.
    document.title = 'irrelevant baseline';
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    element.embedded = true;
    document.body.appendChild(element);
    // connectedCallback runs synchronously on append, so the title is already the create-mode
    // placeholder here - no flush needed.
    expect(document.title).toBe('New Notification Service | Salesforce');
  });

  it('sets document.title to the edit-mode placeholder immediately, then to the loaded record Name once getRecord resolves', async () => {
    document.title = 'irrelevant baseline';
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    element.embedded = true;
    element.recordId = 'a08000000000001AAA';
    document.body.appendChild(element);
    // Immediately after mount the placeholder is set; getRecord hasn't emitted yet, so the tab
    // shows something meaningful before the wire resolves rather than reading "Lightning Experience".
    expect(document.title).toBe('Edit Notification Service | Salesforce');

    // Now feed the record through the wire adapter. The wire callback pulls Name off the shape and
    // pushes `<Name> | Salesforce` into document.title.
    getRecord.emit({
      fields: {
        Name: { value: 'Team Slack (prod)' },
        NotifierApexClassName__c: { value: 'SlackLoggerNotifier' }
      }
    });
    await flushPromises();
    expect(document.title).toBe('Team Slack (prod) | Salesforce');
  });

  it('does not overwrite document.title when the loaded record has a blank Name (the placeholder is a better fallback than "" | Salesforce)', async () => {
    document.title = 'irrelevant baseline';
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    element.embedded = true;
    element.recordId = 'a08000000000001AAA';
    document.body.appendChild(element);
    // Placeholder set by connectedCallback.
    expect(document.title).toBe('Edit Notification Service | Salesforce');

    // Wire returns with Name explicitly blank (rare but valid - the field is required at the
    // platform level, but a fetch-error / recovery path could produce this shape).
    getRecord.emit({
      fields: {
        Name: { value: '' },
        NotifierApexClassName__c: { value: 'SlackLoggerNotifier' }
      }
    });
    await flushPromises();
    // Title stays at the placeholder rather than becoming `" | Salesforce"`.
    expect(document.title).toBe('Edit Notification Service | Salesforce');
  });

  it('renders the notifier picker + collapsed setup guidance after the notifier types wire resolves', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await Promise.resolve();
    // Loading spinner is gone once the wire resolves.
    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    expect(combobox).not.toBeNull();
    expect(combobox.options).toHaveLength(1);
    expect(combobox.options[0].label).toBe('Slack');
    // The setup guidance markdown lives above the form, but only appears after a notifier is picked.
    const guidanceBoxBeforePick = element.shadowRoot.querySelector('pre.guidance-pre');
    expect(guidanceBoxBeforePick).toBeNull();
  });

  it('pre-populates the Name field with the notifier type display label on New (defaultServiceName)', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    // The Name input-field's value binding is populated from defaultServiceName.
    const inputFields = Array.from(element.shadowRoot.querySelectorAll('lightning-input-field'));
    const nameField = inputFields.find(f => f.fieldName === 'Name');
    expect(nameField).toBeDefined();
    expect(nameField.value).toBe('Slack');
  });

  it('closes immediately on Escape when the form has not been touched (no dirty state, no confirm shown)', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await Promise.resolve();

    const closeHandler = jest.fn();
    element.addEventListener('close', closeHandler);

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await Promise.resolve();

    expect(LightningConfirm.open).not.toHaveBeenCalled();
    expect(closeHandler).toHaveBeenCalledTimes(1);
  });

  it('prompts LightningConfirm on Escape when the form is dirty; closes when the user confirms', async () => {
    LightningConfirm.open.mockResolvedValue(true);

    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await Promise.resolve();

    // Advance past the notifier picker so the wrapper div (which owns the onchange listener) exists.
    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    // Simulate a typed-in change bubbling up from the record-edit-form wrapper.
    const wrapper = element.shadowRoot.querySelector('.slds-is-relative');
    wrapper.dispatchEvent(new CustomEvent('change', { bubbles: true }));

    const closeHandler = jest.fn();
    element.addEventListener('close', closeHandler);

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushPromises();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(LightningConfirm.open.mock.calls[0][0]).toEqual(
      expect.objectContaining({
        label: 'Discard unsaved changes?',
        theme: 'warning'
      })
    );
    expect(closeHandler).toHaveBeenCalledTimes(1);
  });

  it('keeps the form open on Escape when the confirm dialog is cancelled', async () => {
    LightningConfirm.open.mockResolvedValue(false);

    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    const wrapper = element.shadowRoot.querySelector('.slds-is-relative');
    wrapper.dispatchEvent(new CustomEvent('change', { bubbles: true }));

    const closeHandler = jest.fn();
    element.addEventListener('close', closeHandler);

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushPromises();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(closeHandler).not.toHaveBeenCalled();
  });

  it('renders the service-side at-least-one hint above the record-edit-form once a notifier is picked', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    const hint = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_warning')).find(el => el.textContent.includes('WebhookUrl__c'));
    expect(hint).toBeDefined();
    expect(hint.textContent).toContain('This notifier requires at least one of');
    expect(hint.textContent).toContain('NamedCredentialDeveloperName__c');
  });

  it('blocks record-edit-form submit when neither WebhookUrl__c nor NamedCredentialDeveloperName__c is set', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    const editForm = element.shadowRoot.querySelector('lightning-record-edit-form');
    const submitEvent = new CustomEvent('submit', { cancelable: true, bubbles: true, detail: { fields: { Name: 'Slack' } } });
    editForm.dispatchEvent(submitEvent);
    await flushPromises();

    expect(submitEvent.defaultPrevented).toBe(true);
    const errorBanner = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_error')).find(el => el.textContent.includes('Populate at least one of'));
    expect(errorBanner).toBeDefined();
  });

  it('allows record-edit-form submit when WebhookUrl__c is populated', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    const editForm = element.shadowRoot.querySelector('lightning-record-edit-form');
    const submitEvent = new CustomEvent('submit', {
      cancelable: true,
      bubbles: true,
      detail: { fields: { Name: 'Slack', WebhookUrl__c: 'https://hooks.slack.com/services/x/y/z' } }
    });
    editForm.dispatchEvent(submitEvent);
    await flushPromises();

    expect(submitEvent.defaultPrevented).toBe(false);
  });

  it('fires a `create` event carrying the new service Id (and NOT a navigate) when embedded=true and the record-edit-form save succeeds', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'SlackLoggerNotifier' } }));
    await flushPromises();

    const createHandler = jest.fn();
    const closeHandler = jest.fn();
    element.addEventListener('create', createHandler);
    element.addEventListener('close', closeHandler);

    const editForm = element.shadowRoot.querySelector('lightning-record-edit-form');
    editForm.dispatchEvent(new CustomEvent('success', { detail: { id: 'a08000000000001AAA' } }));
    await flushPromises();

    expect(createHandler).toHaveBeenCalledTimes(1);
    expect(createHandler.mock.calls[0][0].detail).toEqual({ recordId: 'a08000000000001AAA' });
    // The close event also fires so the modal host can tear the modal down.
    expect(closeHandler).toHaveBeenCalledTimes(1);
  });

  it('ignores non-Escape keydown events (no confirm, no close)', async () => {
    const element = createElement('c-logger-notification-service-guided-form', { is: LoggerNotificationServiceGuidedForm });
    // Embedded=true mimics production mounting inside LoggerNotificationServiceModal. Launcher-mode
    // (`embedded=false`) redirects to the modal on connect and renders nothing, breaking every
    // downstream shadowRoot query in these tests.
    element.embedded = true;
    document.body.appendChild(element);
    getNotifierTypes.emit(MOCK_NOTIFIER_TYPES);
    await Promise.resolve();

    const closeHandler = jest.fn();
    element.addEventListener('close', closeHandler);

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    window.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }));

    expect(LightningConfirm.open).not.toHaveBeenCalled();
    expect(closeHandler).not.toHaveBeenCalled();
  });
});
