import { createElement } from 'lwc';
import LoggerNotificationRuleGuidedForm from 'c/loggerNotificationRuleGuidedForm';
import LoggerNotificationServiceModal from 'c/loggerNotificationServiceModal';
import getFieldsForSObject from '@salesforce/apex/LoggerNotificationFormController.getFieldsForSObject';
import getNotifierTypes from '@salesforce/apex/LoggerNotificationFormController.getNotifierTypes';
import getAvailableServices from '@salesforce/apex/LoggerNotificationFormController.getAvailableServices';
import saveRuleWithRecipients from '@salesforce/apex/LoggerNotificationFormController.saveRuleWithRecipients';
import updateRuleWithRecipients from '@salesforce/apex/LoggerNotificationFormController.updateRuleWithRecipients';
import getRuleWithRecipients from '@salesforce/apex/LoggerNotificationFormController.getRuleWithRecipients';
import validateSourceSObjectFilter from '@salesforce/apex/LoggerNotificationFormController.validateSourceSObjectFilter';
import LightningConfirm from 'lightning/confirm';

// `LoggerNotificationServiceModal` inherits its static `.open()` from `lightning/modal`'s base class,
// which is globally mocked at config/jest/mocks/lightning/modal.js as a jest.fn(). Tests treat that
// inherited method as the interaction seam - override its resolved value per case to simulate a
// saved service (recordId) or a cancel (null).

jest.mock(
  '@salesforce/apex/LoggerNotificationFormController.getNotifierTypes',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);
jest.mock(
  '@salesforce/apex/LoggerNotificationFormController.getAvailableServices',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);
jest.mock('@salesforce/apex/LoggerNotificationFormController.saveRuleWithRecipients', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LoggerNotificationFormController.updateRuleWithRecipients', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LoggerNotificationFormController.getRuleWithRecipients', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LoggerNotificationFormController.validateSourceSObjectFilter', () => ({ default: jest.fn().mockResolvedValue(null) }), {
  virtual: true
});

jest.mock(
  '@salesforce/apex/LoggerNotificationFormController.getFieldsForSObject',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// `lightning/actions` is globally mocked at config/jest/mocks/lightning/actions.js and routed via
// `moduleNameMapper` in jest.config.js. CloseActionScreenEvent is a CustomEvent subclass in that
// mock, matching the on-platform behavior the Quick Action container listens for.

// LightningConfirm.open is stubbed by @salesforce/sfdx-lwc-jest to throw unless overridden per test.
// Replace .open with a jest.fn() so tests can .mockResolvedValue(true/false); reset each run so a
// leftover Escape keydown from a prior test can't leak into a later test that hasn't set an expectation.
beforeEach(() => {
  LightningConfirm.open = jest.fn().mockResolvedValue(false);
  // Reset the modal mock's resolved value each run; individual tests override to simulate a saved
  // service. Without this a prior test's mockResolvedValue(recordId) can leak into a later test
  // that expects the null (cancel) default.
  LoggerNotificationServiceModal.open.mockReset();
  LoggerNotificationServiceModal.open.mockResolvedValue(null);
  // Same story for the filter-validation Apex mock - default to null (valid) so tests that never
  // touch step 2 keep working, and individual tests override to a specific error string.
  validateSourceSObjectFilter.mockReset();
  validateSourceSObjectFilter.mockResolvedValue(null);
  // Reset the edit-mode Apex mocks each run; tests that need edit-mode behavior set their own
  // resolved values.
  getRuleWithRecipients.mockReset();
  updateRuleWithRecipients.mockReset();
});

// The Email notifier requires User__c OR EmailAddress__c on each recipient. This drives every
// recipient at-least-one test in this file - the exact CMDT shape mirrors what the runtime SOQL
// returns from LoggerNotificationFormController.getNotifierTypes.
const MOCK_EMAIL_NOTIFIER_TYPE = {
  AtLeastOneRequiredRecipientFields__c: 'User__c\nEmailAddress__c',
  AtLeastOneRequiredServiceFields__c: null,
  Description__c: 'Sends notifications via Salesforce email.',
  DeveloperName: 'Email',
  DisplayLabel__c: 'Email',
  IsChannelIdentifierRequired__c: false,
  IsEmailAddressRequired__c: false,
  IsEnabled__c: true,
  IsUserRequired__c: false,
  NotifierApexClassName__c: 'EmailLoggerNotifier',
  SetupGuidanceMarkdown__c: '',
  // SObject-keyed with a `"*"` fallback bucket - shape matches what production CMDT records ship.
  // The empty-object bucket is the resolver's "notifier ships no meaningful suggested config"
  // signal; the LWC treats a resolver result of '{}' as auto-populating to '{}', which matches
  // the pre-change behavior for Email.
  SuggestedConfigurationJson__c: '{"*":{}}',
  SupportsChannelIdentifier__c: false,
  SupportsEmailAddress__c: true,
  SupportsNamedCredential__c: false,
  SupportsUser__c: true,
  SupportsWebhookUrl__c: false
};
const MOCK_EMAIL_SERVICE = {
  Id: 'a08000000000001AAA',
  IsEnabled__c: true,
  Name: 'Email',
  NotifierApexClassName__c: 'EmailLoggerNotifier'
};

const flushPromises = async () => {
  for (let i = 0; i < 5; i += 1) {
    await Promise.resolve();
  }
};

// `flushMacroTasks` drains microtasks AND yields one macro-task tick, so `setTimeout(fn, 0)`
// callbacks queued during the current turn have a chance to run before the assertion. Needed for
// the close path: the LWC defers `dispatchEvent(new CloseActionScreenEvent())` to a macro task so
// the platform's async-action state settles before it receives the close.
const flushMacroTasks = async () => {
  await flushPromises();
  /* eslint-disable-next-line @lwc/lwc/no-async-operation */
  await new Promise(resolve => setTimeout(resolve, 0));
};

// Populates Step 1's three required inputs (Name, Source SObject Type, Source SObject Filter)
// with sane defaults so tests can advance past Step 1 without each one re-implementing the same
// three field-set boilerplate. `Source SObject Filter` is now rendered by
// c-logger-notification-formula-editor - a real LWC (not a stubbed lightning-* component) - so its
// `reportValidity()` returns false when the field is required + empty, which blocks Next. That's
// intentional runtime behavior; the shared helper keeps the tests aligned.
const fillStep1RequiredFields = async element => {
  const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
  if (sourceCombo && !sourceCombo.value) {
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
  }
  const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
  if (nameInput && !nameInput.value) {
    nameInput.value = 'Test rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
  }
  const filterEditor = element.shadowRoot.querySelector('c-logger-notification-formula-editor');
  if (filterEditor && !filterEditor.value) {
    filterEditor.value = "ISPICKVAL(LoggingLevel__c, 'ERROR')";
    filterEditor.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
  }
};

const advanceToRecipientsStep = async element => {
  // 4-step wizard: Basics (1) → Storage & Threshold (2) → Recipients (3) → Save (4). Two Nexts to
  // reach Recipients. Prior versions of this wizard had a separate Filter step so this used to
  // click three times.
  await fillStep1RequiredFields(element);
  const clickNext = async () => {
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
  };
  await clickNext();
  await clickNext();
};

const addRecipientAndSelectEmailService = async element => {
  const addButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add recipient');
  addButton.dispatchEvent(new CustomEvent('click'));
  await flushPromises();

  // The recipient service combobox is data-field="LoggerNotificationService__c" on the rule form
  // template. Setting .value + firing 'change' mimics an admin picking a service from the dropdown.
  const serviceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(
    combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
  );
  serviceCombo.value = MOCK_EMAIL_SERVICE.Id;
  serviceCombo.dispatchEvent(new CustomEvent('change'));
  await flushPromises();
};

describe('c-logger-notification-rule-guided-form', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('mounts on New (no recordId) with the panel header reflecting new-mode', () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    return Promise.resolve().then(() => {
      const panel = element.shadowRoot.querySelector('lightning-quick-action-panel');
      expect(panel).not.toBeNull();
      expect(panel.header).toBe('New Notification Rule (Guided)');
    });
  });

  it('sets document.title to the create-mode placeholder in connectedCallback when no recordId is provided', () => {
    // Reset so a previous test's title doesn't leak into this assertion. jsdom preserves
    // document.title between tests within a file.
    document.title = 'irrelevant baseline';
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    // connectedCallback runs synchronously on append - no flush needed.
    expect(document.title).toBe('New Notification Rule | Salesforce');
  });

  it('sets document.title to the edit-mode placeholder immediately, then to the loaded rule Name once getRuleWithRecipients resolves', async () => {
    document.title = 'irrelevant baseline';
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Loud errors',
        SourceSObjectType__c: 'LogEntry__c',
        IsEnabled__c: true,
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    // Immediately after mount the placeholder is set. `loadExistingRule` was kicked off from
    // renderedCallback but hasn't awaited past the imperative Apex call yet.
    expect(document.title).toBe('Edit Notification Rule | Salesforce');

    // Flush the microtask queue so `loadExistingRule` resolves and the title upgrades to the Name.
    await flushPromises();
    expect(document.title).toBe('Loud errors | Salesforce');
  });

  it('does not overwrite document.title when the loaded rule has a blank Name (the placeholder is a better fallback than "" | Salesforce)', async () => {
    document.title = 'irrelevant baseline';
    // Blank Name at the DB level is rare (Name is required on LoggerNotificationRule__c) but a
    // partial-load / migration scenario could produce it - the placeholder is a better fallback
    // than `" | Salesforce"`.
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: '',
        SourceSObjectType__c: 'LogEntry__c',
        IsEnabled__c: true,
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    expect(document.title).toBe('Edit Notification Rule | Salesforce');
    await flushPromises();
    // Title stays at the placeholder rather than becoming `" | Salesforce"`.
    expect(document.title).toBe('Edit Notification Rule | Salesforce');
  });

  it('hides the Source SObject Filter editor + deduplication combobox on Step 1 until a Source SObject Type has been picked', async () => {
    // Both controls are meaningless without a picked SObject: the filter compiles against a
    // specific SObject, and the deduplication combobox is populated by a wire keyed on that
    // SObject. Rendering them empty invites admins to fill them out in the wrong order.
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    await flushPromises();

    // Fresh mount - no Source SObject Type picked yet.
    expect(element.shadowRoot.querySelector('c-logger-notification-formula-editor')).toBeNull();
    const dedupBeforePick = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(
      combobox => combobox.label === 'Deduplication Source Field'
    );
    expect(dedupBeforePick).toBeUndefined();
  });

  it('reveals the Source SObject Filter editor + deduplication combobox once a Source SObject Type is picked', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    await flushPromises();

    // Picking a Source SObject Type flips the `hasSourceSObjectTypePicked` gate and both controls
    // mount on the next render.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    expect(element.shadowRoot.querySelector('c-logger-notification-formula-editor')).not.toBeNull();
    const dedupAfterPick = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(
      combobox => combobox.label === 'Deduplication Source Field'
    );
    expect(dedupAfterPick).toBeDefined();
  });

  it('renders the Source SObject Filter editor + deduplication combobox on Edit-mode load because the prefetched rule already has a Source SObject Type', async () => {
    // Edit-mode prefetch pre-populates `rule.SourceSObjectType__c` from the loaded record, so the
    // filter editor + deduplication combobox should render on first paint - no admin interaction
    // needed to reveal them.
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: true,
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();

    expect(element.shadowRoot.querySelector('c-logger-notification-formula-editor')).not.toBeNull();
    const dedup = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Deduplication Source Field');
    expect(dedup).toBeDefined();
  });

  it('switches to edit-mode title + save-button label when a recordId is provided', async () => {
    // The LWC now supports both create and edit. When mounted with a recordId, it kicks off a
    // getRuleWithRecipients prefetch and switches its card title + save button copy to reflect
    // that admins are editing an existing record. The prefetch mock resolves to a bare rule so
    // the LWC has something to prefill from.
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        IsEnabled__c: true,
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();

    const panel = element.shadowRoot.querySelector('lightning-quick-action-panel');
    expect(panel.header).toBe('Edit Notification Rule (Guided)');
    // The `Save Changes` button only renders on Step 4, so we don't assert on the DOM button here
    // (advancing four steps for a title-only test would over-couple this case). The end-to-end
    // "Save Changes" behavior is asserted by the updateRuleWithRecipients payload test below,
    // which does walk to Step 4.
  });

  it('calls getRuleWithRecipients with the recordId and prefills the rule state', async () => {
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Loud errors',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: false,
        Comments__c: 'Existing comment',
        DeduplicationSourceField__c: 'Log__c',
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: true,
        MatchCountThreshold__c: 3,
        MatchThresholdTimePeriodIncrement__c: 15,
        MatchThresholdTimePeriodUnit__c: 'Minutes'
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();

    // Verify Apex was called with the exact payload the LWC intends to send.
    expect(getRuleWithRecipients).toHaveBeenCalledWith({ ruleId: 'a09000000000001AAA' });
    // The rule's fields should now be reflected in the DOM. Step 1's Name input carries the
    // prefilled value.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    expect(nameInput.value).toBe('Loud errors');
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    expect(sourceCombo.value).toBe('LogEntry__c');
  });

  it('surfaces an error banner when getRuleWithRecipients returns a null rule', async () => {
    getRuleWithRecipients.mockResolvedValue(null);
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09deadbeefdeadbeef';
    document.body.appendChild(element);
    await flushPromises();

    const errorBanner = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_error')).find(el =>
      el.textContent.includes('Could not load the notification rule')
    );
    expect(errorBanner).toBeDefined();
    expect(errorBanner.textContent).toContain('a09deadbeefdeadbeef');
  });

  it('does not call getRuleWithRecipients when no recordId is provided (create mode)', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    expect(getRuleWithRecipients).not.toHaveBeenCalled();
    const panel = element.shadowRoot.querySelector('lightning-quick-action-panel');
    expect(panel.header).toBe('New Notification Rule (Guided)');
  });

  it('renders four steps in the path nav with the expected labels', () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    return Promise.resolve().then(() => {
      const stepListItems = element.shadowRoot.querySelectorAll('.slds-path__item');
      expect(stepListItems.length).toBe(4);
      const labels = Array.from(element.shadowRoot.querySelectorAll('.slds-path__title')).map(el => el.textContent.trim());
      // Step 2's label is 'Storage & Threshold' (not just 'Threshold') because the step covers
      // match/delivery history storage AND the threshold debounce feature. If someone renames the
      // step to just 'Threshold' the label undersells the storage implications; this test locks
      // that copy in.
      expect(labels).toEqual(['Basics', 'Storage & Threshold', 'Recipients', 'Save']);
    });
  });

  it('renders the Cancel button in the panel footer when mounted inside a Quick Action / LightningModal (default jsdom location)', () => {
    // jsdom defaults `window.location.pathname` to '/', so `isUrlAddressableMount` computes to
    // false and the Cancel button renders. This is the Quick Action / LightningModal-embedded
    // branch - admins get a way out of the modal.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    return Promise.resolve().then(() => {
      const cancelButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Cancel');
      expect(cancelButton).toBeDefined();
    });
  });

  it('hides the Cancel button when `isUrlAddressableMount` is true (URL-addressable page - nothing to close)', () => {
    // Full DOM assertion of the Cancel-button hide-when-URL-mounted behavior can't be tested
    // cleanly in jsdom (window.location.pathname isn't configurable, LWC class fields are
    // reactive-VM-only setters that Object.create bypasses, LWC's createElement Proxy rejects
    // arbitrary property assignments). Instead verify the getter's contract by calling it with
    // an explicit `this` binding via .call(). This is what drives the `lwc:if` on the Cancel
    // button in the template. Behavior verified end-to-end in the corresponding Playwright spec.
    const getShowCancel = Object.getOwnPropertyDescriptor(LoggerNotificationRuleGuidedForm.prototype, 'showCancelButton').get;
    expect(getShowCancel.call({ isUrlAddressableMount: true })).toBe(false);
    expect(getShowCancel.call({ isUrlAddressableMount: false })).toBe(true);
  });

  it('advances to step 2 when Next is clicked from step 1', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();
    // Step 1 has three required inputs (Name, Source SObject Type, Source SObject Filter). Without
    // populating them, the formula editor's reportValidity() returns false and blocks the advance.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    expect(nextButton).toBeDefined();
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const step2Header = element.shadowRoot.querySelector('h2');
    expect(step2Header.textContent).toContain('Step 2');
  });

  it('renders the deduplication field dropdown with API-name-first labels once the fields wire resolves', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Set Source SObject Type to LogEntry__c so the reactive `$rule.SourceSObjectType__c` binding
    // on the getFieldsForSObject wire has a value to send. The deduplication combobox lives on
    // Step 1 (combined Basics + Filter) so no Next click needed to reach it.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Assert the wire was invoked with the LWC's current Source SObject Type. `getLastConfig()`
    // on a jest.fn() apex-wire adapter returns the last `{sobjectTypeName: ...}` payload the LWC
    // reactively pushed at the wire - if handleRuleFieldChange breaks its reactive binding, this
    // fires. Weak "was called" assertions would silently pass through that class of regression.
    expect(getFieldsForSObject.getLastConfig()).toEqual({ sobjectTypeName: 'LogEntry__c' });

    getFieldsForSObject.emit([
      { apiName: 'Log__c', label: 'Parent Log' },
      { apiName: 'LoggingLevel__c', label: 'Logging Level' }
    ]);
    await flushPromises();

    // Locate the deduplication combobox by its data-field attribute.
    const combos = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox'));
    const deduplicationCombo = combos.find(combobox => combobox.dataset && combobox.dataset.field === 'DeduplicationSourceField__c');
    expect(deduplicationCombo).toBeDefined();
    // The first option is the placeholder "(none)"; the wire-emitted fields follow.
    expect(deduplicationCombo.options[0]).toEqual({ label: '(none)', value: '' });
    // API name leads, label follows in parens - explicit locked-in contract.
    expect(deduplicationCombo.options[1]).toEqual({ label: 'Log__c (Parent Log)', value: 'Log__c' });
    expect(deduplicationCombo.options[2]).toEqual({ label: 'LoggingLevel__c (Logging Level)', value: 'LoggingLevel__c' });
  });

  // Filter-suggestion coverage. The LWC ships a FILTER_SUGGESTIONS map keyed on Source SObject
  // Type; each entry is a label + formula that populates the Source SObject Filter textarea when
  // clicked. These tests lock in the exact set of suggestions per SObject and the exact formula
  // string each carries - so a regression like "someone re-adds NOT(ISBLANK(ExceptionType__c))"
  // (which fails Salesforce's picklist-field compile check) fails jest immediately rather than
  // waiting until a real Playwright run against a live org catches it.
  const suggestionButtonsForSourceType = async sourceType => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Set the reactive rule state on Step 1 so the `filterSuggestions` getter returns entries.
    // Fire change on the Source SObject Type combobox rather than reaching into the LWC's private
    // `rule` field. The suggestion buttons now live on Step 1 (combined Basics + Filter), so no
    // Next click needed.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = sourceType;
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Return every rendered suggestion button. The "Next" and "Cancel" buttons are also
    // `lightning-button` elements, so filter to buttons that carry the `data-formula` attribute
    // (the LWC template stamps that on every FILTER_SUGGESTIONS button and nowhere else).
    return Array.from(element.shadowRoot.querySelectorAll('lightning-button[data-formula]'));
  };

  it('renders the four LogEntry__c filter suggestions with the expected labels + formulas', async () => {
    const buttons = await suggestionButtonsForSourceType('LogEntry__c');
    const rendered = buttons.map(btn => ({ label: btn.label, formula: btn.dataset.formula }));

    expect(rendered).toEqual([
      { label: 'ERROR entries', formula: "ISPICKVAL(LoggingLevel__c, 'ERROR')" },
      { label: 'ERROR or WARN entries', formula: "OR(\n  ISPICKVAL(LoggingLevel__c, 'ERROR'),\n  ISPICKVAL(LoggingLevel__c, 'WARN')\n)" },
      { label: 'Entries mentioning "callout"', formula: "ISPICKVAL(LoggingLevel__c, 'ERROR') && CONTAINS(Message__c, 'callout')" },
      { label: 'Entries with an exception', formula: 'HasException__c' }
    ]);
  });

  it('renders the two Log__c filter suggestions with the expected labels + formulas', async () => {
    const buttons = await suggestionButtonsForSourceType('Log__c');
    const rendered = buttons.map(btn => ({ label: btn.label, formula: btn.dataset.formula }));

    expect(rendered).toEqual([
      { label: 'Logs with at least one ERROR entry', formula: 'TotalERRORLogEntries__c >= 1' },
      { label: 'Logs with 3+ ERROR entries', formula: 'TotalERRORLogEntries__c >= 3' }
    ]);
  });

  it('renders no suggestion buttons for LoggerScenario__c (no useful native filter target exists on that object)', async () => {
    const buttons = await suggestionButtonsForSourceType('LoggerScenario__c');
    expect(buttons).toHaveLength(0);
  });

  it('renders no suggestion buttons for LogEntryTag__c (no useful native filter target exists on that object)', async () => {
    const buttons = await suggestionButtonsForSourceType('LogEntryTag__c');
    expect(buttons).toHaveLength(0);
  });

  it('populates the Source SObject Filter textarea when a suggestion button is clicked', async () => {
    const buttons = await suggestionButtonsForSourceType('LogEntry__c');
    const exceptionSuggestion = buttons.find(btn => btn.label === 'Entries with an exception');
    expect(exceptionSuggestion).toBeDefined();

    exceptionSuggestion.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // The filter textarea is on the same step; after the click, its `value` binding reflects the
    // suggestion's formula. This locks in the LWC's `handleApplyFilterSuggestion` → reactive state
    // update → template rebinding path.
    const element = document.body.querySelector('c-logger-notification-rule-guided-form');
    // Source SObject Filter is now rendered by c-logger-notification-formula-editor (a syntax-
    // highlighted overlay-textarea component) instead of lightning-textarea. The filter is the only
    // formula editor on the form, so querySelector for the tag is sufficient - no label match needed.
    const filterEditor = element.shadowRoot.querySelector('c-logger-notification-formula-editor');
    expect(filterEditor.value).toBe('HasException__c');
  });

  it('shows Delivery History and Match Threshold checkboxes when Match History is enabled', () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    const clickNext = () =>
      Promise.resolve()
        .then(() => fillStep1RequiredFields(element))
        .then(() => {
          const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
          nextButton.dispatchEvent(new CustomEvent('click'));
        })
        // handleNextStep on Step 1 awaits validateSourceSObjectFilter (mocked to resolve null).
        // Flush pending microtasks so the callout settles before the next assertion.
        .then(() => flushPromises());
    // One Next: Basics (1) → Storage & Threshold (2).
    return clickNext().then(() => {
      const step2Header = element.shadowRoot.querySelector('h2');
      expect(step2Header.textContent).toContain('Step 2');
      const inputLabels = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).map(input => input.label);
      expect(inputLabels).toContain('Is Match History Enabled');
      expect(inputLabels).toContain('Is Delivery History Enabled');
      expect(inputLabels).toContain('Is Match Threshold Enabled');
    });
  });

  it('renders both retention-days inputs on step 2 with their default values (14 for matches, 7 for deliveries) in Create mode', async () => {
    // Match retention is gated behind Match History (default: on); delivery retention is further gated
    // behind Delivery History (default: on). Defaults come from the LWC's local rule state - matches
    // defaults to 14, deliveries defaults to 7 (typically shorter than matches so callout payloads
    // clear out sooner while match rows stick around for auditing). Any regression that hides either
    // input or changes either default would trip this test.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Advance Basics → Storage & Threshold.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    expect(matchesInput).toBeDefined();
    expect(matchesInput.label).toBe('Days to Retain Matches');
    expect(matchesInput.type).toBe('number');
    expect(matchesInput.value).toBe(14);

    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    expect(deliveriesInput).toBeDefined();
    expect(deliveriesInput.label).toBe('Days to Retain Deliveries');
    expect(deliveriesInput.type).toBe('number');
    expect(deliveriesInput.value).toBe(7);
  });

  it('caps the Days to Retain Deliveries input at the current Days to Retain Matches value via HTML max attribute', async () => {
    // Native <input max> gives admins a nudge in the browser (blocks the up arrow from exceeding the
    // limit, red border on manual overtype) alongside the server-side handler validation. Reactive
    // max: matches value flows into the max prop so raising matches also raises the ceiling.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    matchesInput.value = 45;
    matchesInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    expect(deliveriesInput.max).toBe(45);
  });

  it('hides both retention-days inputs when Match History is disabled (nothing to retain)', async () => {
    // showThresholdDependentFields is bound to rule.IsMatchHistoryEnabled__c - flipping Match History
    // off removes the whole retention + delivery + threshold cluster (there's no history for the
    // purger to delete when match rows aren't being stored, and delivery rows are children of
    // matches so they cascade with them).
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const matchHistoryCheckbox = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Is Match History Enabled');
    matchHistoryCheckbox.checked = false;
    matchHistoryCheckbox.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    expect(matchesInput).toBeUndefined();
    expect(deliveriesInput).toBeUndefined();
  });

  it('hides only the Days to Retain Deliveries input when Delivery History is disabled but Match History stays enabled', async () => {
    // Match retention stays visible (match rows are still being stored) but delivery retention hides
    // because there are no delivery rows to retain.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const deliveryHistoryCheckbox = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.label === 'Is Delivery History Enabled'
    );
    deliveryHistoryCheckbox.checked = false;
    deliveryHistoryCheckbox.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    expect(matchesInput).toBeDefined();
    expect(deliveriesInput).toBeUndefined();
  });

  it('updates both retention-days fields on change and forwards the new values to Apex on save', async () => {
    // Full round-trip: admin edits matches=45 + deliveries=15, both values live on the reactive rule
    // state, the payload sent to Apex carries both.
    saveRuleWithRecipients.mockResolvedValue('a09000000000001AAA');
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Basics → Storage & Threshold, edit both retention fields.
    const clickNext = async () => {
      await fillStep1RequiredFields(element);
      const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
      nextButton.dispatchEvent(new CustomEvent('click'));
      await flushPromises();
    };
    await clickNext();
    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    matchesInput.value = 45;
    matchesInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    deliveriesInput.value = 15;
    deliveriesInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Storage & Threshold → Recipients.
    await clickNext();
    await addRecipientAndSelectEmailService(element);
    const emailInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'EmailAddress__c'
    );
    emailInput.value = 'alerts@example.com';
    emailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Recipients → Save.
    await clickNext();
    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create Rule');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    expect(saveRuleWithRecipients).toHaveBeenCalledTimes(1);
    const call = saveRuleWithRecipients.mock.calls[0][0];
    expect(call.rule.NumberOfDaysToRetainMatches__c).toBe(45);
    expect(call.rule.NumberOfDaysToRetainDeliveries__c).toBe(15);
  });

  it('prefills both retention-days fields on Edit-mode load when the fetched rule carries values', async () => {
    // Edit mode: the wizard mounts with a recordId, calls getRuleWithRecipients, and copies the
    // returned field values into local rule state. Both retention inputs should show their loaded
    // values (60 and 7) rather than the Create-mode default (14).
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: true,
        Comments__c: '',
        DeduplicationSourceField__c: '',
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false,
        MatchCountThreshold__c: null,
        MatchThresholdTimePeriodIncrement__c: null,
        MatchThresholdTimePeriodUnit__c: '',
        NumberOfDaysToRetainMatches__c: 60,
        NumberOfDaysToRetainDeliveries__c: 7
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    expect(matchesInput.value).toBe(60);
    expect(deliveriesInput.value).toBe(7);
  });

  it('prefills both retention-days fields as null on Edit-mode load when the fetched rule has no values (rule opted out of retention)', async () => {
    // A rule saved with null retention values means "keep forever" for whichever object has the
    // null - the Edit-mode prefill preserves the null so the admin sees a blank input.
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: true,
        Comments__c: '',
        DeduplicationSourceField__c: '',
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false,
        MatchCountThreshold__c: null,
        MatchThresholdTimePeriodIncrement__c: null,
        MatchThresholdTimePeriodUnit__c: '',
        NumberOfDaysToRetainMatches__c: null,
        NumberOfDaysToRetainDeliveries__c: null
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const matchesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainMatches__c'
    );
    const deliveriesInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'NumberOfDaysToRetainDeliveries__c'
    );
    expect(matchesInput.value).toBeNull();
    expect(deliveriesInput.value).toBeNull();
  });

  it('hides the match-threshold detail fields until the threshold checkbox is on', () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    const clickNext = () =>
      Promise.resolve()
        .then(() => fillStep1RequiredFields(element))
        .then(() => {
          const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
          nextButton.dispatchEvent(new CustomEvent('click'));
        })
        // handleNextStep on Step 1 awaits validateSourceSObjectFilter (mocked to resolve null).
        // Flush pending microtasks so the callout settles before the next assertion.
        .then(() => flushPromises());
    // One Next reaches Storage & Threshold (Step 2).
    return clickNext().then(() => {
      const inputLabels = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).map(input => input.label);
      expect(inputLabels).not.toContain('Match Count Threshold');
      expect(inputLabels).not.toContain('Time Period Increment');
    });
  });

  it('does not render the plain-english threshold summary until the match-count / increment / unit fields are all populated', async () => {
    // The threshold summary is a UI-only recap that reads back the admin's inputs in a sentence. It
    // should only appear once every input has a real value - a half-filled recap ("fires after ?
    // matches within 15 Minutes") would be more confusing than showing nothing at all.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Basics → Storage & Threshold.
    const clickNext = async () => {
      await fillStep1RequiredFields(element);
      const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
      nextButton.dispatchEvent(new CustomEvent('click'));
      await flushPromises();
    };
    await clickNext();

    // Turn on the threshold checkbox so the detail inputs render.
    const thresholdCheckbox = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Is Match Threshold Enabled');
    thresholdCheckbox.checked = true;
    thresholdCheckbox.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // With every field still blank, no summary paragraph should render.
    const findSummary = () => Array.from(element.shadowRoot.querySelectorAll('p')).find(paragraph => paragraph.textContent.includes('The rule will fire once'));
    expect(findSummary()).toBeUndefined();

    // Populate count only - still no summary.
    const countInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Match Count Threshold');
    countInput.value = '5';
    countInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
    expect(findSummary()).toBeUndefined();

    // Populate the increment - still not enough (unit missing).
    const incrementInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Time Period Increment');
    incrementInput.value = '10';
    incrementInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
    expect(findSummary()).toBeUndefined();

    // Populate the unit - now the summary should appear.
    const unitCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Time Period Unit');
    unitCombo.value = 'Minutes';
    unitCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const summary = findSummary();
    expect(summary).toBeDefined();
    // Exact sentence - locked in so a regression that produces "the rule fires when 5 in 10 minutes"
    // (or any other stylistic drift) trips this test.
    expect(summary.textContent.trim()).toContain('The rule will fire once 5 matches are recorded within any rolling 10-minute window.');
  });

  it('renders the singular form of the threshold summary when the count is 1 or the increment is 1', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    const clickNext = async () => {
      await fillStep1RequiredFields(element);
      const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
      nextButton.dispatchEvent(new CustomEvent('click'));
      await flushPromises();
    };
    await clickNext();

    const thresholdCheckbox = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Is Match Threshold Enabled');
    thresholdCheckbox.checked = true;
    thresholdCheckbox.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const countInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Match Count Threshold');
    countInput.value = '1';
    countInput.dispatchEvent(new CustomEvent('change'));
    const incrementInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Time Period Increment');
    incrementInput.value = '1';
    incrementInput.dispatchEvent(new CustomEvent('change'));
    const unitCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Time Period Unit');
    unitCombo.value = 'Hours';
    unitCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const summary = Array.from(element.shadowRoot.querySelectorAll('p')).find(paragraph => paragraph.textContent.includes('The rule will fire once'));
    expect(summary).toBeDefined();
    // "1 match" (not "1 matches") and "1-hour" (not "1-hours") - the singularization matters when
    // the increment is 1 or the count is 1.
    expect(summary.textContent.trim()).toContain('The rule will fire once 1 match is recorded within any rolling 1-hour window.');
  });

  it('reaches the Recipients step and lets admins add a pending recipient', () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    const clickNext = () =>
      Promise.resolve()
        .then(() => fillStep1RequiredFields(element))
        .then(() => {
          const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
          nextButton.dispatchEvent(new CustomEvent('click'));
        })
        // handleNextStep on Step 1 awaits validateSourceSObjectFilter (mocked to resolve null).
        // Flush pending microtasks so the callout settles before the next assertion.
        .then(() => flushPromises());
    // Two Nexts: Basics (1) → Storage & Threshold (2) → Recipients (3).
    return clickNext()
      .then(clickNext)
      .then(() => {
        const step3Header = element.shadowRoot.querySelector('h2');
        expect(step3Header.textContent).toContain('Step 3');
        const addButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add recipient');
        expect(addButton).toBeDefined();
        addButton.dispatchEvent(new CustomEvent('click'));
      })
      .then(() => {
        const recipientRows = element.shadowRoot.querySelectorAll('.slds-box.slds-box_x-small');
        expect(recipientRows.length).toBeGreaterThanOrEqual(1);
      });
  });

  it('renders a lightning-spinner overlay while the filter-validation Apex call is in flight, then removes it', async () => {
    // Withhold the mock's resolution so we can inspect the DOM at the "in flight" moment.
    let resolveValidation;
    validateSourceSObjectFilter.mockImplementation(
      () =>
        new Promise(resolve => {
          resolveValidation = resolve;
        })
    );

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Basics + Filter live on Step 1. Populate the required fields and the filter, then click Next
    // to trigger the callout - no intermediate step to walk to.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    // Flush before querying for the filter editor - it's gated on `hasSourceSObjectTypePicked`
    // and only mounts after the source-change re-renders.
    await flushPromises();
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'E2E rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    // Source SObject Filter is now rendered by c-logger-notification-formula-editor (a syntax-
    // highlighted overlay-textarea component) instead of lightning-textarea. The filter is the only
    // formula editor on the form, so querySelector for the tag is sufficient - no label match needed.
    const filterEditor = element.shadowRoot.querySelector('c-logger-notification-formula-editor');
    filterEditor.value = "ISPICKVAL(LoggingLevel__c, 'ERROR')";
    filterEditor.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Trigger the validation callout. Because the mock is pending, `isValidatingFilter` should be
    // true and the spinner should render.
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next' || btn.label === 'Validating...');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await Promise.resolve();

    const spinnerInFlight = element.shadowRoot.querySelector('lightning-spinner');
    expect(spinnerInFlight).not.toBeNull();
    expect(spinnerInFlight.alternativeText).toBe('Validating filter');

    // Now resolve the mock with null (valid filter) and let the microtask queue drain.
    resolveValidation(null);
    await flushPromises();

    // Spinner should be removed once the callout settles.
    const spinnerAfter = element.shadowRoot.querySelector('lightning-spinner');
    expect(spinnerAfter).toBeNull();
  });

  it('blocks Next on Step 1 (Basics) when the filter validator returns an error string', async () => {
    validateSourceSObjectFilter.mockResolvedValue("Filter did not compile against LogEntry__c: field 'BogusField__c' not found");

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Basics + Filter are combined into Step 1. Set the required fields + a bogus filter, then
    // click Next - the filter validator runs before the wizard advances.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'E2E rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Populate the filter textarea with a bogus expression - it's on Step 1 now.
    // Source SObject Filter is now rendered by c-logger-notification-formula-editor (a syntax-
    // highlighted overlay-textarea component) instead of lightning-textarea. The filter is the only
    // formula editor on the form, so querySelector for the tag is sufficient - no label match needed.
    const filterEditor = element.shadowRoot.querySelector('c-logger-notification-formula-editor');
    filterEditor.value = 'BogusField__c = TRUE';
    filterEditor.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Click Next - the Apex validation runs and should block the advance to Step 2.
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Validating...' || btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Still on Step 1.
    expect(element.shadowRoot.querySelector('h2').textContent).toContain('Step 1');
    // Error banner surfaces the validator's message.
    const errorBanner = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_error')).find(el => el.textContent.includes('BogusField__c'));
    expect(errorBanner).toBeDefined();
    // Apex was called with the right payload.
    expect(validateSourceSObjectFilter).toHaveBeenCalledWith({
      sobjectTypeName: 'LogEntry__c',
      filter: 'BogusField__c = TRUE'
    });
  });

  it('advances Next from Step 1 to Step 2 when the filter validator returns null (filter is valid)', async () => {
    validateSourceSObjectFilter.mockResolvedValue(null);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Basics + Filter live on Step 1. Populate the three required fields inline and click Next
    // once to trigger the filter-validation callout.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'E2E rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Source SObject Filter is now rendered by c-logger-notification-formula-editor (a syntax-
    // highlighted overlay-textarea component) instead of lightning-textarea. The filter is the only
    // formula editor on the form, so querySelector for the tag is sufficient - no label match needed.
    const filterEditor = element.shadowRoot.querySelector('c-logger-notification-formula-editor');
    filterEditor.value = "ISPICKVAL(LoggingLevel__c, 'ERROR')";
    filterEditor.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Validating...' || btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Now on Step 2 (Storage & Threshold).
    expect(element.shadowRoot.querySelector('h2').textContent).toContain('Step 2');
    // Assert the exact payload sent to the Apex controller: the LWC must forward the picked
    // Source SObject Type + the filter value on the reactive rule state. If handleNextStep drifts
    // (e.g. sends `this.rule.SourceSObjectFilter__c` for the wrong step, or forgets to include the
    // SObject type), the trigger's before-save validation and the Save-time compile-check would
    // stop matching what the wizard verified in-flight - this is the assertion that keeps them
    // aligned.
    expect(validateSourceSObjectFilter).toHaveBeenCalledTimes(1);
    expect(validateSourceSObjectFilter).toHaveBeenCalledWith({
      sobjectTypeName: 'LogEntry__c',
      filter: "ISPICKVAL(LoggingLevel__c, 'ERROR')"
    });
  });

  it('skips the filter validation callout when the Source SObject Filter textarea is empty (required-field gate blocks the click before Apex runs)', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await flushPromises();

    // Populate Name + Source SObject Type but leave the filter empty. The formula editor is a real
    // LWC with a real required-field check, so Next is blocked BEFORE the Apex call fires - which
    // is the guard we're asserting on. Prior to the formula editor swap, lightning-textarea's jest
    // stub returned undefined from reportValidity and the required gate was silently a no-op in
    // tests, so this test used to prove "handleNextStep short-circuits on empty filter." That
    // short-circuit still exists in the source and remains correct - but the observable path in
    // tests now is "required-field gate blocks Next," which is the more precise assertion anyway.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'E2E rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Still on Step 1 - the click was refused because the filter is required + empty.
    expect(element.shadowRoot.querySelector('h2').textContent).toContain('Step 1');
    // And critically: no Apex round-trip happened, so a bogus empty-filter payload never left the
    // browser.
    expect(validateSourceSObjectFilter).not.toHaveBeenCalled();
  });

  it('closes immediately on Escape when nothing has been typed and no recipients are pending, removing the LWC from the DOM', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Wire a listener that mimics the Salesforce Quick Action container's behavior: on receiving
    // `close`, detach the LWC from the DOM. The follow-up assertion then confirms the modal is
    // actually gone, not just that the event fired. A dispatched event with no listener that acts
    // on it isn't the same as a closed modal.
    element.addEventListener('close', () => element.remove());

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushMacroTasks();

    expect(LightningConfirm.open).not.toHaveBeenCalled();
    expect(element.isConnected).toBe(false);
  });

  it('closes immediately on Escape in edit mode when the admin has NOT touched the prefilled rule', async () => {
    // Regression: edit-mode load prefills Name / Filter / Comments from the DB. Those aren't
    // unsaved changes - the admin just opened the form. Esc-immediately should still close
    // without a LightningConfirm prompt, matching the create-mode "untouched" behavior.
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        Comments__c: 'Loaded from the DB',
        IsEnabled__c: true,
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false
      },
      recipients: [
        {
          Id: 'a0A0000000000R1AAA',
          LoggerNotificationService__c: MOCK_EMAIL_SERVICE.Id,
          EmailAddress__c: 'first@example.com',
          IsEnabled__c: true
        }
      ]
    });
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();

    element.addEventListener('close', () => element.remove());

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushMacroTasks();

    expect(LightningConfirm.open).not.toHaveBeenCalled();
    expect(element.isConnected).toBe(false);
  });

  it('prompts LightningConfirm on Escape in edit mode once the admin edits a prefilled field', async () => {
    LightningConfirm.open.mockResolvedValue(false);
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: true,
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false
      },
      recipients: []
    });
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    await flushPromises();

    // Type a different Name - the snapshot no longer matches current state.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Renamed rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushPromises();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
  });

  it('prompts LightningConfirm on Escape once the admin has typed a rule Name; closes on confirm', async () => {
    LightningConfirm.open.mockResolvedValue(true);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Simulate typing a Name value - the change handler updates the reactive rule object.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    expect(nameInput).toBeDefined();
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    element.addEventListener('close', () => element.remove());

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushMacroTasks();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(LightningConfirm.open.mock.calls[0][0]).toEqual(
      expect.objectContaining({
        label: 'Discard unsaved changes?',
        theme: 'warning'
      })
    );
    expect(element.isConnected).toBe(false);
  });

  it('keeps the form open on Escape when the confirm dialog is cancelled', async () => {
    LightningConfirm.open.mockResolvedValue(false);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    element.addEventListener('close', () => element.remove());

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushMacroTasks();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    // Cancelled confirm → LWC is still attached to the DOM.
    expect(element.isConnected).toBe(true);
  });

  it('does not stack additional LightningConfirm dialogs when Escape is hit repeatedly while the discard confirm is already open', async () => {
    // Withhold the mock's resolution so the confirm stays "open" for the duration of the test.
    // A rapid double-Esc must not spawn a second confirm behind the first - the re-entry guard on
    // `confirmDiscardAndClose` short-circuits when `isDiscardConfirmOpen` is already true.
    let resolveConfirm;
    LightningConfirm.open.mockImplementation(
      () =>
        new Promise(resolve => {
          resolveConfirm = resolve;
        })
    );

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // First Esc - opens the confirm.
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await Promise.resolve();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);

    // Second, third, fourth Esc - all must be no-ops while the first confirm is still pending.
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await Promise.resolve();
    await Promise.resolve();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);

    // Resolve the first confirm so the test tears down cleanly.
    resolveConfirm(false);
    await Promise.resolve();
  });

  it('intercepts a click on the QuickAction close (X) button and prompts LightningConfirm when there are unsaved changes', async () => {
    LightningConfirm.open.mockResolvedValue(true);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Type a Name so the form is dirty.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Simulate the QuickAction container's X button. The real button lives in platform-owned DOM
    // outside the LWC's shadow root and carries the `.slds-modal__close` class. Mount an
    // equivalent in the document body so the capture-phase window click listener sees it. The
    // container's own onclick would tear down the modal, so the platform-side default matters as
    // much as the interception - assert that our `preventDefault` was called by observing the
    // event's `defaultPrevented` flag.
    const platformCloseButton = document.createElement('button');
    platformCloseButton.className = 'slds-modal__close';
    document.body.appendChild(platformCloseButton);

    // Fire a real MouseEvent so `preventDefault` / `stopPropagation` behave normally. `.click()`
    // synthesizes a MouseEvent that respects defaultPrevented.
    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
    platformCloseButton.dispatchEvent(clickEvent);
    await Promise.resolve();
    await Promise.resolve();

    // Our handler should have run and blocked the container's tear-down while it prompts.
    expect(clickEvent.defaultPrevented).toBe(true);
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(LightningConfirm.open.mock.calls[0][0]).toEqual(expect.objectContaining({ label: 'Discard unsaved changes?' }));

    document.body.removeChild(platformCloseButton);
  });

  it('lets a click on the QuickAction close (X) button pass through when there are no unsaved changes', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const platformCloseButton = document.createElement('button');
    platformCloseButton.className = 'slds-modal__close';
    document.body.appendChild(platformCloseButton);

    const clickEvent = new MouseEvent('click', { bubbles: true, cancelable: true });
    platformCloseButton.dispatchEvent(clickEvent);
    await Promise.resolve();

    // Clean form - no preventDefault, no confirm.
    expect(clickEvent.defaultPrevented).toBe(false);
    expect(LightningConfirm.open).not.toHaveBeenCalled();

    document.body.removeChild(platformCloseButton);
  });

  it('actually removes the LWC from the DOM after the discard confirm is accepted', async () => {
    // End-to-end: the Salesforce Quick Action container tears down the modal by listening for a
    // `close` event on the LWC host and removing the host from the DOM when it fires. Simulate
    // that here and assert the LWC is gone, not just that the event was dispatched. Regression
    // context: an earlier fix added `bubbles: true` / `composed: true` to the CustomEvent, which
    // broke prod because an intermediate ancestor was swallowing the bubbling event before it
    // reached the container's host-level listener - the confirm's OK fired but the modal stayed
    // open. The "modal actually removed" assertion catches that whole class of regression.
    LightningConfirm.open.mockResolvedValue(true);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    element.addEventListener('close', () => element.remove());

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    await flushMacroTasks();

    expect(element.isConnected).toBe(false);
  });

  it('renders the at-least-one warning banner on a recipient whose Email notifier requires User__c OR EmailAddress__c and neither is set', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    // Prime the notifier types + services wires so recipientRows can pair the picked service with its CMDT.
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);

    const warning = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_warning')).find(el => el.textContent.includes('Populate at least one of'));
    expect(warning).toBeDefined();
    // Label reads "User__c or EmailAddress__c" - the fields declared by the mock CMDT record.
    expect(warning.textContent).toContain('User__c');
    expect(warning.textContent).toContain('EmailAddress__c');
  });

  it('clears the at-least-one warning once one of the required recipient fields is populated', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);

    // Populate EmailAddress__c via the record-picker/input's change event.
    const emailInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'EmailAddress__c'
    );
    expect(emailInput).toBeDefined();
    emailInput.value = 'alerts@example.com';
    emailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const warning = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_warning')).find(el => el.textContent.includes('Populate at least one of'));
    expect(warning).toBeUndefined();
  });

  it('blocks Save on the Review step when a recipient has no required field populated, surfacing an error banner and NOT calling Apex', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    // Fill the required rule Name so the save doesn't get blocked on some OTHER validation.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);

    // Advance to Step 4 (Review & save).
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create Rule');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    expect(saveRuleWithRecipients).not.toHaveBeenCalled();
    const errorBanner = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_error')).find(el => el.textContent.includes('requires one of'));
    expect(errorBanner).toBeDefined();
    expect(errorBanner.textContent).toContain('User__c');
    expect(errorBanner.textContent).toContain('EmailAddress__c');
  });

  it('allows Save through to Apex once one of the required recipient fields is populated', async () => {
    saveRuleWithRecipients.mockResolvedValue('a09000000000001AAA');
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Set Source SObject Type - it has no default, so a save with it blank would send an empty
    // string to Apex and fail the trigger's resolveSObjectType check. This test verifies the
    // happy-path save, so pick a real value.
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);

    // Populate EmailAddress__c so the at-least-one constraint is satisfied.
    const emailInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
      input => input.dataset && input.dataset.field === 'EmailAddress__c'
    );
    emailInput.value = 'alerts@example.com';
    emailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Advance to Step 4.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create Rule');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Assert on the full payload shape - both the rule object and every recipient field the LWC
    // is expected to forward. Weak assertions ("was called", "has 1 recipient") let regressions
    // slip through where the LWC quietly drops or renames a field on its way to Apex; the trigger
    // then sees a partial record and either rejects it or persists garbage. This snapshot-style
    // check keeps the wire contract between LWC and Apex honest.
    expect(saveRuleWithRecipients).toHaveBeenCalledTimes(1);
    const call = saveRuleWithRecipients.mock.calls[0][0];

    // Rule payload: every field on the LWC's `rule` object should round-trip. IsMatchHistoryEnabled__c
    // and IsDeliveryHistoryEnabled__c default to true; the threshold fields default to null/'' and
    // stay that way when the admin doesn't touch the threshold step. Both retention fields default
    // to 14 in Create mode (mirrors each field's <defaultValue>14</defaultValue> on the SObject).
    expect(call.rule).toEqual({
      Name: 'Loud errors',
      SourceSObjectType__c: 'LogEntry__c',
      IsEnabled__c: true,
      Comments__c: '',
      // Filter comes from fillStep1RequiredFields - the same value the shared helper writes into
      // the formula editor. Testing that specific value here also proves the editor's @api value
      // setter and the parent form's onchange binding are both wired correctly.
      SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
      DeduplicationSourceField__c: '',
      IsMatchThresholdEnabled__c: false,
      MatchCountThreshold__c: null,
      MatchThresholdTimePeriodIncrement__c: null,
      MatchThresholdTimePeriodUnit__c: '',
      IsMatchHistoryEnabled__c: true,
      IsDeliveryHistoryEnabled__c: true,
      NumberOfDaysToRetainMatches__c: 14,
      NumberOfDaysToRetainDeliveries__c: 7
    });

    // Recipient payload: exactly one row, with every field stripped of UI-only cruft (no localId).
    // Fields the admin didn't touch come through as null rather than empty strings - the LWC's
    // handleSave normalizes them with `|| null` before dispatch so the Apex payload matches what
    // the trigger's before-save validation expects.
    expect(call.recipients).toEqual([
      {
        LoggerNotificationService__c: MOCK_EMAIL_SERVICE.Id,
        ChannelIdentifier__c: null,
        EmailAddress__c: 'alerts@example.com',
        User__c: null,
        // Email's SuggestedConfigurationJson__c is '{}', which the auto-populate handler stamps
        // onto the row when the service is picked. See the auto-populate cluster of tests below.
        ConfigurationJson__c: '{}',
        IsEnabled__c: true
      }
    ]);
  });

  it('renders the empty-state banner on step 3 when no services exist yet', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    // Emit an empty services list - simulates a fresh install where no LoggerNotificationService__c
    // records have been created yet.
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([]);
    await flushPromises();

    await advanceToRecipientsStep(element);

    const emptyStateBanner = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_info')).find(el =>
      el.textContent.includes('No notification services exist yet')
    );
    expect(emptyStateBanner).toBeDefined();
    // The banner must include a "Create a new Service" call-to-action so admins have somewhere to go.
    const createServiceButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create a new Service');
    expect(createServiceButton).toBeDefined();
  });

  it('invokes LoggerNotificationServiceModal.open when "Create a new Service" is clicked from the empty-state banner', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([]);
    await flushPromises();

    await advanceToRecipientsStep(element);

    const createServiceButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create a new Service');
    expect(createServiceButton).toBeDefined();
    createServiceButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // The modal is opened via LightningModal.open() rather than rendered into the parent shadow DOM.
    // On-platform this ensures a full-viewport backdrop; in jest we just verify the API was called.
    expect(LoggerNotificationServiceModal.open).toHaveBeenCalledTimes(1);
    expect(LoggerNotificationServiceModal.open).toHaveBeenCalledWith(expect.objectContaining({ size: 'medium' }));
  });

  it('seeds a new recipient row auto-selecting the just-created service when the modal was opened from the empty state', async () => {
    // Resolve the modal .open() promise with a service Id, simulating the admin completing the
    // nested guided-form save. The parent should then seed a new recipient row pointing at the Id.
    LoggerNotificationServiceModal.open.mockResolvedValue(MOCK_EMAIL_SERVICE.Id);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([]);
    await flushPromises();

    await advanceToRecipientsStep(element);

    const createServiceButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create a new Service');
    createServiceButton.dispatchEvent(new CustomEvent('click'));
    // Wait for the modal open() + refreshApex() awaits to settle.
    await flushPromises();

    // Emit the refreshed services list - simulates refreshApex re-invoking the wire adapter.
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    const serviceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(
      combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
    );
    expect(serviceCombo).toBeDefined();
    expect(serviceCombo.value).toBe(MOCK_EMAIL_SERVICE.Id);
  });

  it('stamps the new service Id onto an existing recipient row when the modal was opened from that row', async () => {
    LoggerNotificationServiceModal.open.mockResolvedValue(MOCK_EMAIL_SERVICE.Id);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([]);
    await flushPromises();

    await advanceToRecipientsStep(element);

    // Add a recipient row FIRST (with no service selectable yet). Then open the modal from that
    // row's "Create a new Service" button - the parent should stamp the new service back onto that
    // same row rather than seeding another one.
    const addButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add recipient');
    addButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Scope to the row-level button by requiring a data-local-id (the empty-state banner button has none).
    const rowCreateButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(
      btn => btn.label === 'Create a new Service' && btn.dataset && btn.dataset.localId
    );
    expect(rowCreateButton).toBeDefined();
    rowCreateButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    // Only the existing recipient row is present (no duplicate row) and its combobox is auto-selected.
    const serviceCombos = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).filter(
      combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
    );
    expect(serviceCombos).toHaveLength(1);
    expect(serviceCombos[0].value).toBe(MOCK_EMAIL_SERVICE.Id);
  });

  it('does not touch the recipient list when the modal resolves with null (admin cancelled)', async () => {
    LoggerNotificationServiceModal.open.mockResolvedValue(null);

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([]);
    await flushPromises();

    await advanceToRecipientsStep(element);

    const createServiceButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create a new Service');
    createServiceButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Modal resolved with null - no recipient row should have been seeded.
    const serviceCombos = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).filter(
      combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
    );
    expect(serviceCombos).toHaveLength(0);
  });

  it('closes immediately on Cancel click when nothing has been typed and no recipients are pending, removing the LWC from the DOM', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    element.addEventListener('close', () => element.remove());

    const cancelButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Cancel');
    expect(cancelButton).toBeDefined();
    cancelButton.dispatchEvent(new CustomEvent('click'));
    await flushMacroTasks();

    expect(LightningConfirm.open).not.toHaveBeenCalled();
    expect(element.isConnected).toBe(false);
  });

  it('prompts LightningConfirm on Cancel click when the admin has typed a rule Name and actually removes the modal on confirm', async () => {
    LightningConfirm.open.mockResolvedValue(true);
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Simulate typing a Name.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    element.addEventListener('close', () => element.remove());

    const cancelButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Cancel');
    cancelButton.dispatchEvent(new CustomEvent('click'));
    await flushMacroTasks();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(element.isConnected).toBe(false);
  });

  it('keeps the modal in the DOM on Cancel click when the admin cancels the LightningConfirm dialog', async () => {
    LightningConfirm.open.mockResolvedValue(false);
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    nameInput.value = 'Loud errors';
    nameInput.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    element.addEventListener('close', () => element.remove());

    const cancelButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Cancel');
    cancelButton.dispatchEvent(new CustomEvent('click'));
    await flushMacroTasks();

    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(element.isConnected).toBe(true);
  });

  it('renders step 1 with the Source SObject Type combobox unset (admin must choose, no silent LogEntry__c default)', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    expect(sourceCombo).toBeDefined();
    // Empty value (not 'LogEntry__c') - admins must consciously pick.
    expect(sourceCombo.value).toBe('');
  });

  it('blocks Next when a required lightning-input on the current step reports invalid', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Locate the Name input (required on step 1) and stub its reportValidity to return false -
    // this is how the sfdx-lwc-jest stub exposes "invalid" state, since the stub's default
    // reportValidity() returns undefined (treated as valid) and the stub has no real value/required
    // wiring to fail against.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    expect(nameInput).toBeDefined();
    nameInput.reportValidity = jest.fn().mockReturnValue(false);

    // Click Next.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // The step header must still read Step 1 - Next should have been blocked.
    const stepHeader = element.shadowRoot.querySelector('h2');
    expect(stepHeader.textContent).toContain('Step 1');
    // reportValidity was called - the built-in error UI is what surfaces the invalid state.
    expect(nameInput.reportValidity).toHaveBeenCalled();
  });

  it('advances to the next step when every required lightning-input on the current step is valid', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Stub reportValidity on every rendered input to return true - simulates all required fields
    // being populated.
    Array.from(element.shadowRoot.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')).forEach(input => {
      input.reportValidity = jest.fn().mockReturnValue(true);
    });

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Now on Step 2.
    const stepHeader = element.shadowRoot.querySelector('h2');
    expect(stepHeader.textContent).toContain('Step 2');
  });

  it('calls reportValidity on every rendered lightning-* input in the current step (fields light up together, not one by one)', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    await Promise.resolve();

    // Multiple inputs live in step 1: Name (input), Source SObject Type (combobox), Comments (textarea).
    // Even if the FIRST field is invalid, the handler should still call reportValidity on the rest
    // so the admin sees every failing field at once instead of playing whack-a-mole.
    const nameInput = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(input => input.label === 'Name');
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    const commentsTextarea = Array.from(element.shadowRoot.querySelectorAll('lightning-textarea')).find(textarea => textarea.label === 'Comments');
    nameInput.reportValidity = jest.fn().mockReturnValue(false);
    sourceCombo.reportValidity = jest.fn().mockReturnValue(true);
    commentsTextarea.reportValidity = jest.fn().mockReturnValue(true);

    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    expect(nameInput.reportValidity).toHaveBeenCalled();
    expect(sourceCombo.reportValidity).toHaveBeenCalled();
    expect(commentsTextarea.reportValidity).toHaveBeenCalled();
  });

  it('does not render a warning banner when the notifier declares no at-least-one recipient fields', async () => {
    // Slack has SupportsChannelIdentifier__c but no AtLeastOneRequiredRecipientFields__c - populating
    // ChannelIdentifier isn't required (though IsChannelIdentifierRequired__c on that notifier makes
    // it hard-required individually - separate mechanism). This test locks in the fact that a null
    // AtLeastOneRequiredRecipientFields__c value means zero warning banner, ever.
    const slackNotifierType = {
      ...MOCK_EMAIL_NOTIFIER_TYPE,
      DeveloperName: 'Slack',
      DisplayLabel__c: 'Slack',
      NotifierApexClassName__c: 'SlackLoggerNotifier',
      AtLeastOneRequiredRecipientFields__c: null,
      IsChannelIdentifierRequired__c: false,
      SupportsChannelIdentifier__c: true,
      SupportsEmailAddress__c: false,
      SupportsUser__c: false
    };
    const slackService = { ...MOCK_EMAIL_SERVICE, Name: 'Slack', NotifierApexClassName__c: 'SlackLoggerNotifier' };

    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([slackNotifierType]);
    getAvailableServices.emit([slackService]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    // Reuse the helper - the service is Slack here, not Email, but the interaction shape is identical.
    await addRecipientAndSelectEmailService(element);

    const warning = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_warning')).find(el => el.textContent.includes('Populate at least one of'));
    expect(warning).toBeUndefined();
  });

  it('calls updateRuleWithRecipients with the exact diff payload when Save fires in edit mode', async () => {
    // Prefetch response: a rule with two existing recipients. In the wizard, the admin will
    // (a) edit the first recipient's EmailAddress, (b) remove the second recipient, and (c) add a
    // brand-new recipient row. Save should send:
    //  - recipientsToUpdate: [recipient1 with new EmailAddress]
    //  - recipientsToInsert: [the newly-added recipient]
    //  - recipientIdsToDelete: [recipient2's Id]
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: true,
        Comments__c: '',
        DeduplicationSourceField__c: '',
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false,
        MatchCountThreshold__c: null,
        MatchThresholdTimePeriodIncrement__c: null,
        MatchThresholdTimePeriodUnit__c: '',
        NumberOfDaysToRetainMatches__c: 30,
        NumberOfDaysToRetainDeliveries__c: 7
      },
      recipients: [
        {
          Id: 'a0A0000000000R1AAA',
          LoggerNotificationService__c: MOCK_EMAIL_SERVICE.Id,
          EmailAddress__c: 'first@example.com',
          IsEnabled__c: true
        },
        {
          Id: 'a0A0000000000R2AAA',
          LoggerNotificationService__c: MOCK_EMAIL_SERVICE.Id,
          EmailAddress__c: 'second@example.com',
          IsEnabled__c: true
        }
      ]
    });
    updateRuleWithRecipients.mockResolvedValue('a09000000000001AAA');
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    // Advance to Step 3 (Recipients).
    await advanceToRecipientsStep(element);

    // Mutate recipient 1's email. Target by data-local-id rather than by array position - the
    // array shifts as recipients are added/removed, and off-by-one bugs at index-selection time
    // would silently corrupt assertions.
    const findEmailInputByLocalId = localId =>
      Array.from(element.shadowRoot.querySelectorAll('lightning-input')).find(
        input => input.dataset && input.dataset.field === 'EmailAddress__c' && input.dataset.localId === localId
      );
    // Recipient rows come out of loadExistingRule with localIds 'local-1', 'local-2' (LWC's
    // nextLocalRecipientId starts at 0 and increments per prefill).
    const firstRecipientEmailInput = findEmailInputByLocalId('local-1');
    firstRecipientEmailInput.value = 'first-renamed@example.com';
    firstRecipientEmailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Remove recipient 2 by clicking its scoped trash icon.
    const removeButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button-icon')).find(
      btn => btn.iconName === 'utility:delete' && btn.dataset && btn.dataset.localId === 'local-2'
    );
    removeButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Add a brand-new recipient row. Not using the `addRecipientAndSelectEmailService` helper
    // because its `.find()` on the service combobox grabs the FIRST unassigned row, which in
    // multi-recipient edit-mode scenarios finds an already-populated row and no-ops instead of
    // configuring the newly-added one. Inline the setup so we can target the new row precisely.
    const addButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add recipient');
    addButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    // The newly-added row is the last recipient's service combobox on the page.
    const allServiceCombos = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).filter(
      combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
    );
    const newServiceCombo = allServiceCombos[allServiceCombos.length - 1];
    newServiceCombo.value = MOCK_EMAIL_SERVICE.Id;
    newServiceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
    // Now that the new row's service is set, its Email input is the last on the page.
    const allEmailInputs = Array.from(element.shadowRoot.querySelectorAll('lightning-input')).filter(
      input => input.dataset && input.dataset.field === 'EmailAddress__c'
    );
    const newRecipientEmailInput = allEmailInputs[allEmailInputs.length - 1];
    newRecipientEmailInput.value = 'new@example.com';
    newRecipientEmailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Advance to Step 4 and Save.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Save Changes');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Assert the full payload. Weak assertions here would let a field-drop regression slip through
    // - the trigger's before-save validation would reject the wrong shape but only at save time.
    expect(updateRuleWithRecipients).toHaveBeenCalledTimes(1);
    const call = updateRuleWithRecipients.mock.calls[0][0];
    expect(call.rule).toEqual({
      Id: 'a09000000000001AAA',
      Name: 'Existing Rule',
      SourceSObjectType__c: 'LogEntry__c',
      SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
      IsEnabled__c: true,
      Comments__c: '',
      DeduplicationSourceField__c: '',
      IsMatchHistoryEnabled__c: true,
      IsDeliveryHistoryEnabled__c: true,
      IsMatchThresholdEnabled__c: false,
      MatchCountThreshold__c: null,
      MatchThresholdTimePeriodIncrement__c: null,
      MatchThresholdTimePeriodUnit__c: '',
      NumberOfDaysToRetainMatches__c: 30,
      NumberOfDaysToRetainDeliveries__c: 7
    });
    expect(call.recipientsToUpdate).toEqual([
      {
        Id: 'a0A0000000000R1AAA',
        LoggerNotificationService__c: MOCK_EMAIL_SERVICE.Id,
        ChannelIdentifier__c: null,
        EmailAddress__c: 'first-renamed@example.com',
        User__c: null,
        ConfigurationJson__c: null,
        IsEnabled__c: true
      }
    ]);
    expect(call.recipientsToInsert).toEqual([
      {
        LoggerNotificationService__c: MOCK_EMAIL_SERVICE.Id,
        ChannelIdentifier__c: null,
        EmailAddress__c: 'new@example.com',
        User__c: null,
        // Picking the Email service on the new row triggers the auto-populate handler, which
        // writes Email's SuggestedConfigurationJson__c ('{}') into the config field. This is the
        // documented new behavior: any service-pick or service-change replaces the config JSON
        // with the newly-picked notifier's suggestion.
        ConfigurationJson__c: '{}',
        IsEnabled__c: true
      }
    ]);
    expect(call.recipientIdsToDelete).toEqual(['a0A0000000000R2AAA']);
  });

  it('does not add locally-added recipients to recipientIdsToDelete when they are removed before Save', async () => {
    // In edit mode: prefetch returns zero recipients, admin adds one and then removes it. The
    // remove should NOT populate deletedRecipientIds because the row was never in the DB.
    getRuleWithRecipients.mockResolvedValue({
      rule: {
        Id: 'a09000000000001AAA',
        Name: 'Existing Rule',
        SourceSObjectType__c: 'LogEntry__c',
        SourceSObjectFilter__c: "ISPICKVAL(LoggingLevel__c, 'ERROR')",
        IsEnabled__c: true,
        Comments__c: '',
        DeduplicationSourceField__c: '',
        IsMatchHistoryEnabled__c: true,
        IsDeliveryHistoryEnabled__c: true,
        IsMatchThresholdEnabled__c: false,
        MatchCountThreshold__c: null,
        MatchThresholdTimePeriodIncrement__c: null,
        MatchThresholdTimePeriodUnit__c: ''
      },
      recipients: []
    });
    updateRuleWithRecipients.mockResolvedValue('a09000000000001AAA');
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    element.recordId = 'a09000000000001AAA';
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    // Add a recipient (helper is safe here because the prefetch returned zero recipients, so the
    // helper's `.find()` correctly targets the only row on the page).
    await addRecipientAndSelectEmailService(element);
    // Delete it before saving.
    const removeButtons = Array.from(element.shadowRoot.querySelectorAll('lightning-button-icon')).filter(btn => btn.iconName === 'utility:delete');
    removeButtons[0].dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Advance to Step 4 and Save.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Save Changes');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    expect(updateRuleWithRecipients).toHaveBeenCalledTimes(1);
    const call = updateRuleWithRecipients.mock.calls[0][0];
    expect(call.recipientIdsToDelete).toEqual([]);
    expect(call.recipientsToInsert).toEqual([]);
    expect(call.recipientsToUpdate).toEqual([]);
  });

  // --- Configuration section: hide-until-service, auto-populate on service pick, and
  //     the row-level Load Suggested Configuration + Form/JSON toggle. ---

  // Helper: a Slack-shaped notifier with a non-trivial SuggestedConfigurationJson__c payload.
  // Distinct from MOCK_EMAIL_NOTIFIER_TYPE (which ships `'{"*":{}}'` as its suggested JSON) so we
  // can observe an actual payload landing in the recipient's textarea when the service is picked.
  // The stored shape is SObject-keyed (LogEntry__c-focused + Log__c-focused + `"*"` fallback);
  // `SLACK_SUGGESTED_JSON_LOG_ENTRY` is the pretty-printed LogEntry__c bucket the resolver produces
  // for a rule whose Source SObject Type is `LogEntry__c` (which is what `fillStep1RequiredFields`
  // sets), so tests assert on that shape directly.
  const SLACK_SUGGESTED_STORED_JSON = JSON.stringify({
    LogEntry__c: {
      channel: '#alerts',
      sourceFields: ['LoggingLevel__c', 'Message__c']
    },
    Log__c: {
      channel: '#alerts',
      sourceFields: ['Name', 'TransactionId__c']
    },
    '*': {
      sourceFields: ['Name']
    }
  });
  const SLACK_SUGGESTED_JSON_LOG_ENTRY = JSON.stringify({ channel: '#alerts', sourceFields: ['LoggingLevel__c', 'Message__c'] }, null, 2);
  const MOCK_SLACK_NOTIFIER_TYPE = {
    ...MOCK_EMAIL_NOTIFIER_TYPE,
    DeveloperName: 'Slack',
    DisplayLabel__c: 'Slack',
    NotifierApexClassName__c: 'SlackLoggerNotifier',
    AtLeastOneRequiredRecipientFields__c: null,
    IsChannelIdentifierRequired__c: false,
    SupportsChannelIdentifier__c: true,
    SupportsEmailAddress__c: false,
    SupportsUser__c: false,
    SuggestedConfigurationJson__c: SLACK_SUGGESTED_STORED_JSON
  };
  const MOCK_SLACK_SERVICE = { ...MOCK_EMAIL_SERVICE, Id: 'a08000000000002AAA', Name: 'Slack', NotifierApexClassName__c: 'SlackLoggerNotifier' };

  // Finds the Configuration textarea inside the first recipient row. Returns null when
  // no service has been picked yet (the section is hidden until then).
  // The JSON-view editor is a NATIVE `<textarea>` (not `<lightning-textarea>`) so our stylesheet
  // can reach it with `field-sizing: content` - same reasoning as the Form-view value textarea.
  // Selector accepts both shapes so a future switch back to `<lightning-textarea>` doesn't silently
  // break tests.
  const findConfigTextarea = element =>
    Array.from(element.shadowRoot.querySelectorAll('textarea.config-json-editor, lightning-textarea')).find(
      candidate => candidate.dataset && candidate.dataset.field === 'ConfigurationJson__c'
    ) || null;

  // Two-button toggle group: one button per view mode, both always visible. Locate each by its
  // `data-target-mode` so a test can click the target mode directly. `.variant` reveals which
  // button is the "active" one (variant === 'brand') for tests that need to assert the current view.
  const findModeButton = (element, targetMode) =>
    Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.dataset && btn.dataset.targetMode === targetMode) || null;
  const findFormModeButton = element => findModeButton(element, 'form');
  const findJsonModeButton = element => findModeButton(element, 'json');
  // Fires a click on the mode button that would flip the row into the given target view. Uses the
  // form-then-json fallback so this helper works from either starting state (Form default).
  const clickModeButton = (element, targetMode) => {
    const button = findModeButton(element, targetMode);
    button.dispatchEvent(new CustomEvent('click'));
  };

  const findLoadSuggestedButton = element =>
    Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Load Suggested Configuration') || null;

  const findFormPairKeyInputs = element => Array.from(element.shadowRoot.querySelectorAll('lightning-input.config-pair-key, .config-pair-key'));

  // The value textarea is a NATIVE `<textarea>` (not a `<lightning-textarea>`) so our stylesheet
  // can reach it directly - required for `field-sizing: content`. The selector picks up both the
  // native element and any legacy `.config-pair-value` node, so a future switch back to
  // `<lightning-textarea>` wouldn't silently break tests.
  const findFormPairValueTextareas = element => Array.from(element.shadowRoot.querySelectorAll('textarea.config-pair-value, .config-pair-value'));

  const addRecipientAndSelectSlackService = async element => {
    const addButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add recipient');
    addButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    // Grab the LAST service combobox - the one just added. If the caller invokes this helper
    // multiple times to add multiple rows, `.find()` (first-match) would land on row 0's combobox
    // every time and no-op the subsequent picks; `.filter().pop()` targets the newest row.
    const serviceCombos = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).filter(
      combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
    );
    const serviceCombo = serviceCombos[serviceCombos.length - 1];
    serviceCombo.value = MOCK_SLACK_SERVICE.Id;
    serviceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
  };

  it('hides the Configuration section until a service is picked on the recipient row', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    // Add a recipient row but do NOT pick a service.
    const addButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add recipient');
    addButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Pre-service-pick: no config textarea, no Load Suggested Configuration, no Form/JSON toggle group.
    expect(findConfigTextarea(element)).toBeNull();
    expect(findLoadSuggestedButton(element)).toBeNull();
    expect(findFormModeButton(element)).toBeNull();
    expect(findJsonModeButton(element)).toBeNull();
  });

  it("auto-populates ConfigurationJson__c from the picked notifier's SuggestedConfigurationJson__c on service pick (new row)", async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);

    // Post-service-pick: Load Suggested Configuration + both mode buttons render. Form is the default active
    // mode - its button variant is `brand`, JSON's is `neutral`.
    expect(findLoadSuggestedButton(element)).not.toBeNull();
    expect(findFormModeButton(element)).not.toBeNull();
    expect(findJsonModeButton(element)).not.toBeNull();
    expect(findFormModeButton(element).variant).toBe('brand');
    expect(findJsonModeButton(element).variant).toBe('neutral');
    // Two form-view pair rows, matching the two top-level keys from SUGGESTED_JSON.
    expect(findFormPairKeyInputs(element)).toHaveLength(2);
    const keyInputs = findFormPairKeyInputs(element);
    expect(keyInputs[0].value).toBe('channel');
    expect(keyInputs[1].value).toBe('sourceFields');
  });

  it('overwrites ConfigurationJson__c when the picked service changes (Email → Slack), regardless of prior content', async () => {
    // Email ships an empty `"*":{}` bucket; Slack ships the full SLACK_SUGGESTED_STORED_JSON. Picking
    // Email first, then switching to Slack, should replace the config JSON with Slack's suggestion.
    // We inspect the underlying JSON via the toggle path (flip to JSON view to read the raw text)
    // rather than the textarea directly, since Form view is now the default.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE, MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE, MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);
    // After the Email pick the row is in Form view with zero pairs (`'{}'` -> no keys).
    expect(findFormPairKeyInputs(element)).toHaveLength(0);

    const serviceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(
      combobox => combobox.dataset && combobox.dataset.field === 'LoggerNotificationService__c'
    );
    serviceCombo.value = MOCK_SLACK_SERVICE.Id;
    serviceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // After the Slack pick the row's config has been replaced with Slack's suggested JSON. In
    // Form view that's exactly two pair rows (channel + sourceFields).
    const keyInputs = findFormPairKeyInputs(element);
    expect(keyInputs).toHaveLength(2);
    expect(keyInputs[0].value).toBe('channel');
    expect(keyInputs[1].value).toBe('sourceFields');
  });

  it('"Load Suggested Configuration" button reapplies the notifier\'s SuggestedConfigurationJson__c on click', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    // Flip to JSON view so we can inspect + edit the raw textarea. Form view is default.
    clickModeButton(element, 'json');
    await flushPromises();

    // Admin edits the JSON to something arbitrary.
    const configTextarea = findConfigTextarea(element);
    configTextarea.value = '{"custom":"override"}';
    configTextarea.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
    expect(findConfigTextarea(element).value).toBe('{"custom":"override"}');

    // Click Load Suggested Configuration - textarea snaps back to the notifier's canonical suggested
    // JSON for the currently-picked Source SObject Type (LogEntry__c, set by fillStep1RequiredFields).
    findLoadSuggestedButton(element).dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_LOG_ENTRY);
  });

  // --- SObject-keyed SuggestedConfigurationJson__c resolution. The stored payload is a top-level
  //     map keyed by source SObject API name with a `"*"` fallback bucket, so the LWC resolves it
  //     against the currently-picked SourceSObjectType__c at auto-populate / Load-Suggested time. ---

  // Same three-bucket shape as MOCK_SLACK_NOTIFIER_TYPE but stripped of the `"*"` fallback bucket
  // so tests can observe the empty-string / hidden-button case when neither an SObject-specific nor
  // fallback bucket exists.
  const SLACK_SUGGESTED_STORED_JSON_NO_FALLBACK = JSON.stringify({
    LogEntry__c: {
      channel: '#alerts',
      sourceFields: ['LoggingLevel__c', 'Message__c']
    }
  });
  const MOCK_SLACK_NOTIFIER_TYPE_NO_FALLBACK = {
    ...MOCK_SLACK_NOTIFIER_TYPE,
    SuggestedConfigurationJson__c: SLACK_SUGGESTED_STORED_JSON_NO_FALLBACK
  };
  const SLACK_SUGGESTED_JSON_LOG = JSON.stringify({ channel: '#alerts', sourceFields: ['Name', 'TransactionId__c'] }, null, 2);
  const SLACK_SUGGESTED_JSON_FALLBACK = JSON.stringify({ sourceFields: ['Name'] }, null, 2);

  // Step 1 baseline sets Source SObject Type to `LogEntry__c`. Some tests need to switch it to a
  // different value (Log__c or an SObject with no dedicated bucket) BEFORE picking a service so the
  // service-pick auto-populate resolves against the right key.
  const setSourceSObjectType = async (element, value) => {
    const sourceCombo = Array.from(element.shadowRoot.querySelectorAll('lightning-combobox')).find(combobox => combobox.label === 'Source SObject Type');
    sourceCombo.value = value;
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
  };

  it('auto-populates the LogEntry__c bucket when the rule targets LogEntry__c', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    // fillStep1RequiredFields sets SourceSObjectType__c to LogEntry__c by default.
    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    clickModeButton(element, 'json');
    await flushPromises();

    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_LOG_ENTRY);
  });

  it('auto-populates the Log__c bucket when the rule targets Log__c', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    // Fill Step 1 with LogEntry__c defaults (satisfies the required Name + filter fields), then
    // override the picked SObject to Log__c so the auto-populate resolves against that bucket.
    await fillStep1RequiredFields(element);
    await setSourceSObjectType(element, 'Log__c');
    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    clickModeButton(element, 'json');
    await flushPromises();

    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_LOG);
  });

  it('falls back to the "*" bucket when the rule targets an SObject with no dedicated bucket', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await fillStep1RequiredFields(element);
    // LogEntryTag__c isn't a real SObject in the picklist, but the resolver operates on the string
    // regardless - unknown keys route to the `"*"` fallback bucket.
    await setSourceSObjectType(element, 'LogEntryTag__c');
    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    clickModeButton(element, 'json');
    await flushPromises();

    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_FALLBACK);
  });

  it('hides the "Load Suggested Configuration" button and stamps empty config when neither an SObject-specific nor a "*" bucket resolves', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE_NO_FALLBACK]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await fillStep1RequiredFields(element);
    await setSourceSObjectType(element, 'LogEntryTag__c');
    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);

    // No bucket resolves -> "Load Suggested Configuration" button hides + auto-populated
    // ConfigurationJson__c is empty (Form view renders zero pair rows).
    expect(findLoadSuggestedButton(element)).toBeNull();
    expect(findFormPairKeyInputs(element)).toHaveLength(0);
    clickModeButton(element, 'json');
    await flushPromises();
    expect(findConfigTextarea(element).value).toBe('');
  });

  it('resolves the SObject-specific bucket at Load-Suggested click time using the current SourceSObjectType__c value', async () => {
    // The Load Suggested Configuration button reads the CURRENT rule.SourceSObjectType__c on each
    // click, so an admin who first picked LogEntry__c, added a Slack recipient (auto-populated with
    // LogEntry__c bucket), then stepped back and switched to Log__c, sees the Log__c bucket the
    // NEXT time they hit Load Suggested Configuration.
    const element = createElement('c-logger-notification-rule-guided-form', { is: LoggerNotificationRuleGuidedForm });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    // Pick LogEntry__c on Step 1, advance to Step 3, add a Slack recipient. Auto-populate seeds
    // ConfigurationJson__c with the LogEntry__c bucket.
    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    clickModeButton(element, 'json');
    await flushPromises();
    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_LOG_ENTRY);

    // Step back to Step 1, switch SObject to Log__c, advance back to Step 3, click Load Suggested.
    // The button resolves against Log__c on the click, so the textarea flips to that bucket.
    const previousButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Previous');
    previousButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    previousButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    await setSourceSObjectType(element, 'Log__c');
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    findLoadSuggestedButton(element).dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_LOG);
  });

  it('toggles the recipient row between Form view (default) and JSON view', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);

    // Default view is Form - textarea absent, pair inputs present. Slack's SUGGESTED_JSON has two
    // top-level keys (channel, sourceFields), so we expect two pair inputs.
    expect(findConfigTextarea(element)).toBeNull();
    expect(findFormPairKeyInputs(element)).toHaveLength(2);

    // Click JSON - pair inputs go away, textarea appears with the pretty-printed JSON.
    clickModeButton(element, 'json');
    await flushPromises();
    expect(findFormPairKeyInputs(element)).toHaveLength(0);
    expect(findConfigTextarea(element)).not.toBeNull();
    expect(findConfigTextarea(element).value).toBe(SLACK_SUGGESTED_JSON_LOG_ENTRY);
    // Button variants swap: JSON is now brand-filled, Form is neutral.
    expect(findJsonModeButton(element).variant).toBe('brand');
    expect(findFormModeButton(element).variant).toBe('neutral');
  });

  it('refuses to switch a row from JSON view back to Form view when its JSON is malformed and surfaces a row-scoped error', async () => {
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);

    // Flip to JSON view + overwrite the textarea with malformed JSON (missing closing brace).
    clickModeButton(element, 'json');
    await flushPromises();
    const configTextarea = findConfigTextarea(element);
    configTextarea.value = '{"broken":';
    configTextarea.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Click the Form-mode button to switch back to Form - LWC refuses + surfaces the row-scoped error alert.
    clickModeButton(element, 'form');
    await flushPromises();

    // Textarea still rendered - view didn't flip back to Form.
    expect(findConfigTextarea(element)).not.toBeNull();
    expect(findFormPairKeyInputs(element)).toHaveLength(0);
    // Error alert visible on the row.
    const errorAlert = Array.from(element.shadowRoot.querySelectorAll('.slds-theme_warning')).find(el => el.textContent.includes('Cannot switch to Form view'));
    expect(errorAlert).toBeDefined();
  });

  it('Form view: clicking "Add entry" appends an empty-key pair to the row without dropping it', async () => {
    // Regression driver: the first Form-view implementation stripped empty-key pairs at serialize
    // time, so the "Add entry" click produced no visible change. This test locks in the fix - a
    // fresh Add-entry click grows the pair list by exactly one, even when the new pair has no key
    // yet.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    // Form view is the default post-service-pick, so no toggle click needed to see pair rows.
    expect(findFormPairKeyInputs(element)).toHaveLength(2);

    // "Add entry" is the base button below the pair rows in Form view.
    const addEntryButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add entry');
    expect(addEntryButton).toBeDefined();
    addEntryButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Three rows now - the two from the suggested JSON + one blank empty-key row waiting to be named.
    const keyInputs = findFormPairKeyInputs(element);
    expect(keyInputs).toHaveLength(3);
    expect(keyInputs[2].value).toBe('');
  });

  it('Form view: editing a key + value dispatches the correct JSON payload to saveRuleWithRecipients', async () => {
    // Pin the LWC's LWC→Apex contract: Form-view edits must land in ConfigurationJson__c
    // as valid, top-level-object JSON. Uses the create-mode save path (which requires an
    // EmailAddress-populated Email recipient); we drive the config editor separately.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    // Fill Step 1's required fields so Save can proceed later.
    const nameInput = element.shadowRoot.querySelector('lightning-input[data-field="Name"]');
    nameInput.value = 'Config-editor rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    const sourceCombo = element.shadowRoot.querySelector('lightning-combobox[data-field="SourceSObjectType__c"]');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);
    // Add a required EmailAddress so the save doesn't blow up on the at-least-one guard.
    const emailInput = element.shadowRoot.querySelector('lightning-input[data-field="EmailAddress__c"]');
    emailInput.value = 'alerts@example.com';
    emailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Form view is the default. Add + edit a pair directly.
    const addEntryButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add entry');
    addEntryButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const keyInputs = findFormPairKeyInputs(element);
    const valueTextareas = findFormPairValueTextareas(element);
    keyInputs[0].value = 'foo';
    keyInputs[0].dispatchEvent(new CustomEvent('change'));
    valueTextareas[0].value = 'bar';
    valueTextareas[0].dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Advance to Step 4 + save.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create Rule');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    expect(saveRuleWithRecipients).toHaveBeenCalledTimes(1);
    const savedPayload = saveRuleWithRecipients.mock.calls[0][0];
    // The recipient's ConfigurationJson__c should be pretty-printed JSON containing the
    // typed key/value. `JSON.parse` gives us shape assertions that are indent-agnostic - so a
    // future switch away from 2-space indent doesn't false-fail this test.
    expect(savedPayload.recipients).toHaveLength(1);
    expect(JSON.parse(savedPayload.recipients[0].ConfigurationJson__c)).toEqual({ foo: 'bar' });
  });

  it('Form view: save-time JSON payload sorts keys case-insensitive alphabetically', async () => {
    // Locks in the "storage matches display" invariant: Form view already renders keys sorted, and
    // `serializePairsToJson` sorts before serializing so the on-record `ConfigurationJson__c`
    // bytes match the sorted view. We type keys in intentionally-wrong order (`zebra`, `Apple`,
    // `middle`) - both to exercise case-insensitivity and to prove the sort actually reorders them.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_EMAIL_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_EMAIL_SERVICE]);
    await flushPromises();

    // Step 1 setup + advance to Recipients.
    const nameInput = element.shadowRoot.querySelector('lightning-input[data-field="Name"]');
    nameInput.value = 'Sort keys rule';
    nameInput.dispatchEvent(new CustomEvent('change'));
    const sourceCombo = element.shadowRoot.querySelector('lightning-combobox[data-field="SourceSObjectType__c"]');
    sourceCombo.value = 'LogEntry__c';
    sourceCombo.dispatchEvent(new CustomEvent('change'));
    await flushPromises();
    await advanceToRecipientsStep(element);
    await addRecipientAndSelectEmailService(element);
    // Populate EmailAddress so the save doesn't hit the at-least-one guard.
    const emailInput = element.shadowRoot.querySelector('lightning-input[data-field="EmailAddress__c"]');
    emailInput.value = 'alerts@example.com';
    emailInput.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Add three pairs in intentionally-wrong order.
    const addEntryButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Add entry');
    addEntryButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    addEntryButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    addEntryButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const keyInputs = findFormPairKeyInputs(element);
    const valueTextareas = findFormPairValueTextareas(element);
    keyInputs[0].value = 'zebra';
    keyInputs[0].dispatchEvent(new CustomEvent('change'));
    valueTextareas[0].value = 'z-value';
    valueTextareas[0].dispatchEvent(new CustomEvent('change'));
    keyInputs[1].value = 'Apple';
    keyInputs[1].dispatchEvent(new CustomEvent('change'));
    valueTextareas[1].value = 'a-value';
    valueTextareas[1].dispatchEvent(new CustomEvent('change'));
    keyInputs[2].value = 'middle';
    keyInputs[2].dispatchEvent(new CustomEvent('change'));
    valueTextareas[2].value = 'm-value';
    valueTextareas[2].dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Advance + save.
    await fillStep1RequiredFields(element);
    const nextButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Next');
    nextButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    const saveButton = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).find(btn => btn.label === 'Create Rule');
    saveButton.dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // JSON.stringify preserves insertion order for string keys, so the raw string is our
    // ground-truth ordering signal. Case-insensitive alphabetic: `Apple` -> `middle` -> `zebra`.
    const savedRawJson = saveRuleWithRecipients.mock.calls[0][0].recipients[0].ConfigurationJson__c;
    expect(savedRawJson.indexOf('"Apple"')).toBeLessThan(savedRawJson.indexOf('"middle"'));
    expect(savedRawJson.indexOf('"middle"')).toBeLessThan(savedRawJson.indexOf('"zebra"'));
  });

  it('Form view: nested-object values pretty-print with 2-space indent so multi-line JSON stays readable', async () => {
    // Regression driver: an earlier implementation used compact JSON.stringify, so opening the
    // saved rule in Form view showed nested arrays / objects collapsed onto one line. Admins
    // couldn't scan or hand-edit them. Fix pretty-prints with a 2-space indent; test verifies the
    // exact whitespace so a future compact-serialize regression fails here.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    // Form view is the default post-service-pick.
    const valueTextareas = findFormPairValueTextareas(element);
    // Slack's SUGGESTED_JSON has `sourceFields` as a nested array - it should render multi-line
    // in the Form-view value textarea, not as `["LoggingLevel__c","Message__c"]`.
    const sourceFieldsValue = valueTextareas[1].value;
    expect(sourceFieldsValue).toBe('[\n  "LoggingLevel__c",\n  "Message__c"\n]');
  });

  it('Form view: delete-entry prompts LightningConfirm, removes the pair on confirm, keeps it on cancel', async () => {
    // First run: user cancels the confirm - pair count stays the same.
    LightningConfirm.open.mockResolvedValueOnce(false);
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    await addRecipientAndSelectSlackService(element);
    // Form view is the default post-service-pick.
    expect(findFormPairKeyInputs(element)).toHaveLength(2);

    // Click the first pair's delete icon. LightningConfirm resolves false (cancel) - no removal.
    const deleteButtons = Array.from(element.shadowRoot.querySelectorAll('lightning-button-icon')).filter(
      btn => btn.alternativeText === 'Delete configuration entry'
    );
    expect(deleteButtons).toHaveLength(2);
    deleteButtons[0].dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    expect(LightningConfirm.open).toHaveBeenCalledTimes(1);
    expect(LightningConfirm.open.mock.calls[0][0]).toEqual(
      expect.objectContaining({
        label: 'Remove configuration entry?',
        theme: 'warning'
      })
    );
    expect(findFormPairKeyInputs(element)).toHaveLength(2);

    // Second run: user confirms - pair is removed.
    LightningConfirm.open.mockResolvedValueOnce(true);
    deleteButtons[0].dispatchEvent(new CustomEvent('click'));
    await flushPromises();
    expect(findFormPairKeyInputs(element)).toHaveLength(1);
  });

  it('per-recipient toggle state does not bleed across rows (rowA flips to JSON, rowB stays in Form)', async () => {
    // Regression driver for the switch away from a global config editor mode - each recipient row
    // must have its own editor mode. This test proves a JSON-view switch on row A leaves row B on
    // its default Form view.
    const element = createElement('c-logger-notification-rule-guided-form', {
      is: LoggerNotificationRuleGuidedForm
    });
    document.body.appendChild(element);
    getNotifierTypes.emit([MOCK_SLACK_NOTIFIER_TYPE]);
    getAvailableServices.emit([MOCK_SLACK_SERVICE]);
    await flushPromises();

    await advanceToRecipientsStep(element);
    // Add + configure two recipient rows, both using Slack.
    await addRecipientAndSelectSlackService(element);
    await addRecipientAndSelectSlackService(element);

    // Flip only the first row's toggle to JSON view. Two recipient rows, each with two mode
    // buttons (Form + JSON), so 4 buttons total - `[0]` is row A's Form button, `[1]` is row A's
    // JSON button, `[2]` is row B's Form button, etc. Click row A's JSON-mode button directly.
    const jsonModeButtons = Array.from(element.shadowRoot.querySelectorAll('lightning-button')).filter(btn => btn.dataset && btn.dataset.targetMode === 'json');
    expect(jsonModeButtons).toHaveLength(2);
    jsonModeButtons[0].dispatchEvent(new CustomEvent('click'));
    await flushPromises();

    // Row A: has a textarea (JSON view). Row B: no textarea (still Form view). JSON editor is a
    // native `<textarea>` so we query it directly, not through `<lightning-textarea>`.
    const configTextareas = Array.from(element.shadowRoot.querySelectorAll('textarea.config-json-editor')).filter(
      candidate => candidate.dataset && candidate.dataset.field === 'ConfigurationJson__c'
    );
    expect(configTextareas).toHaveLength(1); // only row A's
  });
});
