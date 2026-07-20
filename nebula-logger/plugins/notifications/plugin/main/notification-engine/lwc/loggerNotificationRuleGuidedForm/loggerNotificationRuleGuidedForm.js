import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import LoggerNotificationServiceModal from 'c/loggerNotificationServiceModal';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import getNotifierTypes from '@salesforce/apex/LoggerNotifierGuidedFormController.getNotifierTypes';
import getAvailableServices from '@salesforce/apex/LoggerNotifierGuidedFormController.getAvailableServices';
import getFieldsForSObject from '@salesforce/apex/LoggerNotifierGuidedFormController.getFieldsForSObject';
import saveRuleWithRecipients from '@salesforce/apex/LoggerNotifierGuidedFormController.saveRuleWithRecipients';
import updateRuleWithRecipients from '@salesforce/apex/LoggerNotifierGuidedFormController.updateRuleWithRecipients';
import getRuleWithRecipients from '@salesforce/apex/LoggerNotifierGuidedFormController.getRuleWithRecipients';
import validateSourceSObjectFilter from '@salesforce/apex/LoggerNotifierGuidedFormController.validateSourceSObjectFilter';
import LOGGER_NOTIFICATION_OBJECT from '@salesforce/schema/LoggerNotificationRule__c';
import SOURCE_SOBJECT_TYPE_FIELD from '@salesforce/schema/LoggerNotificationRule__c.SourceSObjectType__c';
import THRESHOLD_TIME_PERIOD_UNIT_FIELD from '@salesforce/schema/LoggerNotificationRule__c.MatchThresholdTimePeriodUnit__c';
// Suggested filter formulas per Source SObject Type. Extracted to a sibling data module (see the
// header of that file for authoring constraints) so the payload can be edited without wading
// through this component's JS.
import FILTER_SUGGESTIONS from './loggerNotificationRuleFilterSuggestions';

// Wizard has 4 steps. `Basics` combines the original two-step Basics + Filter flow into one page
// since none of those fields require intermediate validation between them; Basics is the primary
// setup surface where admins pick Name / Source SObject Type / filter formula together.
const STEP_LABELS = ['Basics', 'Storage & Threshold', 'Recipients', 'Save'];
const LAST_STEP = STEP_LABELS.length;

function parseAtLeastOneRequiredFields(notifierType) {
  if (!notifierType || !notifierType.AtLeastOneRequiredRecipientFields__c) {
    return [];
  }
  return notifierType.AtLeastOneRequiredRecipientFields__c.split(/[\r\n,]+/)
    .map(entry => entry.trim())
    .filter(entry => entry.length > 0);
}

function hasValue(value) {
  return value !== null && value !== undefined && String(value).trim().length > 0;
}

// Parses a recipient's ConfigurationJson__c string into the row's Form-view pair array.
// Returns null when the JSON is malformed or its top-level shape isn't an object (caller uses that
// to keep the row in JSON view and surface a validation error). Values that aren't strings are
// re-serialized as compact JSON so nested objects, arrays, numbers, booleans, and null round-trip
// through the textarea editor without collapsing to `[object Object]`. Keys sort case-insensitive
// alphabetically for a stable admin experience across renders.
function parseConfigJsonToPairs(rawJson) {
  if (!hasValue(rawJson)) {
    return [];
  }
  let parsed;
  try {
    parsed = JSON.parse(rawJson);
  } catch (err) {
    return null;
  }
  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return null;
  }
  return Object.keys(parsed)
    .sort((leftKey, rightKey) => leftKey.toLowerCase().localeCompare(rightKey.toLowerCase()))
    .map(key => {
      const rawValue = parsed[key];
      const isString = typeof rawValue === 'string';
      return {
        key,
        // Values are kept as JSON-serialized text in the textarea for round-trip safety. Strings
        // render bare (without surrounding quotes) so a plain string value looks like a plain string
        // to the admin, not `"foo"`; on the way back out, `serializePairsToJson` re-quotes them if
        // they don't parse as their own JSON literal. Nested objects / arrays pretty-print with a
        // 2-space indent so admins can read + hand-edit multi-line values without a JSON linter.
        valueText: isString ? rawValue : JSON.stringify(rawValue, null, 2)
      };
    });
}

// Reverse of parseConfigJsonToPairs. Rebuilds a JSON object from the Form-view pair array. Each
// pair's valueText is first attempted as JSON (so nested objects, arrays, numbers, booleans, and
// null round-trip); if the parse fails, the raw text is kept as a JSON string. Empty-key pairs
// are dropped from the JSON output (they represent a row the admin has added but not named yet -
// carrying them into the JSON would either collide with any other empty-key row or produce a
// `{"":"..."}` shape that reads as garbage). Empty-key rows stay in Form-view state and only
// disappear once the admin either names them or removes them via the delete button. Duplicate
// named keys collapse - last write wins.
//
// Keys are sorted case-insensitive alphabetically before serialization so both the JSON-view
// textarea AND the on-record `ConfigurationJson__c` value match the sorted rendering
// Form view uses. That makes the database value predictable across saves (an admin who saves
// twice without editing gets identical bytes both times) and keeps Form view + JSON view + saved
// record all in one canonical order.
function serializePairsToJson(pairs) {
  const namedPairs = pairs.filter(pair => hasValue(pair.key));
  namedPairs.sort((leftPair, rightPair) => leftPair.key.toLowerCase().localeCompare(rightPair.key.toLowerCase()));
  const output = {};
  for (const pair of namedPairs) {
    let coercedValue;
    try {
      coercedValue = JSON.parse(pair.valueText);
    } catch (err) {
      coercedValue = pair.valueText;
    }
    output[pair.key] = coercedValue;
  }
  // Pretty-print with a 2-space indent so JSON view stays multi-line + readable after any Form-view
  // edit. Storage is a Long Text Area; a few extra whitespace bytes on write don't matter, and the
  // admin's mental model is "JSON should look like JSON" - which means indented.
  return JSON.stringify(output, null, 2);
}

function buildAtLeastOneRequiredLabel(fieldNames) {
  if (fieldNames.length === 0) {
    return '';
  }
  if (fieldNames.length === 1) {
    return fieldNames[0];
  }
  const head = fieldNames.slice(0, -1).join(', ');
  return head + ' or ' + fieldNames[fieldNames.length - 1];
}

export default class LoggerNotificationRuleGuidedForm extends NavigationMixin(LightningElement) {
  // Supports both create (recordId undefined) and edit (recordId provided). In edit mode the LWC
  // imperatively calls `getRuleWithRecipients` on mount to prefill `this.rule` and
  // `this.pendingRecipients`, tracks a `deletedRecipientIds` list as the admin removes existing
  // recipient rows, and on Save routes through `updateRuleWithRecipients` (which takes explicit
  // insert / update / delete lists) rather than `saveRuleWithRecipients` (which is insert-only).
  @api recordId;

  currentStep = 1;
  errorMessage;
  isSaving = false;
  // True while the Step 1 Next click is awaiting `validateSourceSObjectFilter`. Drives the Next
  // button's disabled state so admins can't queue up a second click while the first is in flight.
  isValidatingFilter = false;
  // True while the mount-time `getRuleWithRecipients` prefetch is in flight (edit mode only). Used
  // to gate the initial render so admins don't see a Create-mode form for a split second before
  // the existing rule loads.
  isLoadingRecord = false;
  // Guard so `renderedCallback` only kicks off the prefetch once. In Salesforce Quick Actions the
  // `recordId` property can be set AFTER `connectedCallback` fires, so we can't just hook the load
  // there - `renderedCallback` fires on every render (including after `@api` writes) and this flag
  // makes sure we don't re-fetch on subsequent re-renders.
  hasAttemptedRuleLoad = false;
  // Re-entry guard for the "Discard unsaved changes?" LightningConfirm. See `confirmDiscardAndClose`.
  isDiscardConfirmOpen = false;

  notifierTypes = [];
  services = [];
  pendingRecipients = [];
  // Ids of recipients that came from the DB (present in the loaded rule) but were subsequently
  // removed from the wizard. Populated only in edit mode. On Save, this list is passed to Apex's
  // `updateRuleWithRecipients` as the `recipientIdsToDelete` argument.
  deletedRecipientIds = [];
  sourceSObjectTypeOptions = [];
  thresholdTimePeriodUnitOptions = [];
  deduplicationFieldOptions = [];
  nextLocalRecipientId = 0;
  // Per-recipient editor mode for the Configuration section. Keyed on the recipient's
  // localId; value is 'form' (default) or 'json'. Each row owns its own toggle so admins can pick
  // the view that fits the row's content shape - JSON view is the escape hatch for hand-editing a
  // complex payload, and Form view is the default because it's the more discoverable shape (labeled
  // key + value inputs, add/delete affordances). Rows without an entry here default to 'form';
  // rows whose stored JSON is malformed / not a top-level object fall back to JSON view via the
  // `showJsonEditor` gate in `recipientRows` so admins can fix the malformed content.
  configEditorModeByRecipient = {};
  // Keyed the same way. Populated when the admin clicks the toggle to switch a row into Form view
  // and that row's JSON is malformed / not a top-level object - keeps the row in JSON view and
  // renders an inline warning above the row's editor.
  configEditorErrorByRecipient = {};
  // Retained wire response for the services list so we can `refreshApex` after the create-service
  // LightningModal resolves with a new Id. Without this the dropdown stays stale until the LWC is
  // re-mounted.
  wiredServicesResult;

  // Local state for the rule fields we collect across steps. On the last step we hand this to Apex
  // as a LoggerNotificationRule__c record along with the pendingRecipients list.
  //
  // Source SObject Type intentionally starts empty (not pre-selected as LogEntry__c) - a default
  // choice is a real decision, and picking the wrong SObject silently produces a rule that fires
  // on the wrong records. Making admins choose explicitly forces the decision to be conscious.
  rule = {
    Name: '',
    SourceSObjectType__c: '',
    IsEnabled__c: true,
    Comments__c: '',
    SourceSObjectFilter__c: '',
    DeduplicationSourceField__c: '',
    IsMatchThresholdEnabled__c: false,
    MatchCountThreshold__c: null,
    MatchThresholdTimePeriodIncrement__c: null,
    MatchThresholdTimePeriodUnit__c: '',
    IsMatchHistoryEnabled__c: true,
    IsDeliveryHistoryEnabled__c: true,
    NumberOfDaysToRetainMatches__c: 14,
    NumberOfDaysToRetainDeliveries__c: 7
  };

  // True when the LWC is mounted on the URL-addressable /lightning/cmp/c__... page rather than
  // inside a Quick Action Screen Action container. Gates Cancel + Esc / X intercepts:
  //  - URL page has no container to close, so a Cancel button would strand admins on a form with
  //    no exit. The Cancel button is hidden and admins use the browser navigation to leave.
  //  - Esc / X capture-phase intercepts only make sense inside a Quick Action or LightningModal
  //    that would close on those events. On the URL page nothing closes, so no intercept needed.
  isUrlAddressableMount = false;

  connectedCallback() {
    this.isUrlAddressableMount = this.detectUrlAddressableMount();
    // Initial document.title. New-mode gets a generic label immediately; edit-mode also gets a
    // generic placeholder here so the tab shows something meaningful before the async record
    // fetch resolves. `loadExistingRule` overwrites the title with the actual record Name once it
    // lands. Runs on every mount (URL-addressable AND Quick Action) because the browser tab title
    // benefits from it either way.
    document.title = this.isNew ? 'New Notification Rule | Salesforce' : 'Edit Notification Rule | Salesforce';
    if (this.isUrlAddressableMount) {
      return;
    }
    // Quick Action / LightningModal mount. Capture-phase intercepts on Esc and clicks on the
    // container's close (X) button. Both surfaces close their host without asking, so we
    // intercept first and route through the unsaved-changes guard.
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    window.addEventListener('keydown', this.boundHandleKeydown, true);
    this.boundHandleModalCloseClick = this.handleModalCloseClick.bind(this);
    window.addEventListener('click', this.boundHandleModalCloseClick, true);
  }

  // Extracted so jest can spy on it. jsdom's `window.location.pathname` is not configurable, so
  // tests that need to force URL-addressable behavior stub this method directly.
  detectUrlAddressableMount() {
    return window.location.pathname.startsWith('/lightning/cmp/');
  }

  // Gates the Cancel button in the panel footer. Hidden on the URL-addressable page (no container
  // to close), visible everywhere else.
  get showCancelButton() {
    return !this.isUrlAddressableMount;
  }

  // Kick off the edit-mode prefetch here rather than in `connectedCallback`: Salesforce Quick
  // Actions can set the `@api recordId` property AFTER `connectedCallback` fires, so gating the
  // load on connectedCallback misses the recordId in a lot of cases and the wizard opens with an
  // empty rule state. `renderedCallback` fires on every render (including after `@api` writes),
  // so once recordId lands the fetch triggers. The `hasAttemptedRuleLoad` guard makes sure this
  // runs exactly once - re-renders from downstream state changes (typing in Step 1, advancing to
  // Step 2, etc.) don't re-fire the fetch.
  renderedCallback() {
    if (this.recordId && !this.hasAttemptedRuleLoad) {
      this.hasAttemptedRuleLoad = true;
      this.loadExistingRule();
    }
    // LWC binds `<textarea>` value ONLY via text content on first render; the text content does
    // NOT re-render when the underlying template expression changes on the same element instance.
    // So when service change / Load Suggested Configuration / Form-view edits mutate the row's
    // JSON, the DOM textarea can still show the previous value. Imperative sync closes the gap
    // by writing `.value` from JS on every render. Same story for Form-view pair value textareas.
    this.syncNativeTextareaValues();
  }

  // Imperatively pushes the current model state into each native `<textarea>` on the recipients
  // step. Called from `renderedCallback` so any state change that alters `ConfigurationJson__c`
  // or a Form-view pair's `valueText` is reflected in the DOM even when LWC doesn't remount the
  // textarea element. No-op when the wizard isn't on step 3 (no textareas render there).
  syncNativeTextareaValues() {
    const jsonEditors = this.template.querySelectorAll('textarea.config-json-editor');
    jsonEditors.forEach(textarea => {
      const localId = textarea.dataset.localId;
      const recipient = this.pendingRecipients.find(candidate => candidate.localId === localId);
      const expectedValue = recipient ? recipient.ConfigurationJson__c || '' : '';
      if (textarea.value !== expectedValue) {
        textarea.value = expectedValue;
      }
    });
    const pairEditors = this.template.querySelectorAll('textarea.config-pair-value');
    pairEditors.forEach(textarea => {
      const localId = textarea.dataset.localId;
      const pairIndex = Number.parseInt(textarea.dataset.pairIndex, 10);
      const recipient = this.pendingRecipients.find(candidate => candidate.localId === localId);
      if (!recipient) {
        return;
      }
      const pairs = this.ensureFormPairs(recipient);
      const pair = pairs[pairIndex];
      const expectedValue = pair ? pair.valueText : '';
      if (textarea.value !== expectedValue) {
        textarea.value = expectedValue;
      }
    });
  }

  // Imperative Apex call that prefetches an existing rule + its child recipients so the wizard
  // opens with the current state pre-populated. Only fires when the LWC was mounted with a
  // `recordId` (i.e. via the Guided Edit quick action / WebLink on an existing record). Runs off
  // `connectedCallback` rather than a `@wire` so we can await it and set the `rule` / `pendingRecipients`
  // state synchronously - `@wire` on `getRuleWithRecipients` would need reactive glue that doesn't
  // buy us anything here.
  async loadExistingRule() {
    this.isLoadingRecord = true;
    try {
      const result = await getRuleWithRecipients({ ruleId: this.recordId });
      if (!result || !result.rule) {
        this.errorMessage = 'Could not load the notification rule for editing (recordId: ' + this.recordId + ').';
        return;
      }
      // Copy the rule fields we care about into the reactive state. Ignore Apex-side system fields
      // (Id is retained separately via `this.recordId`, `CreatedById` / `LastModifiedById` etc. are
      // never touched by the wizard).
      this.rule = {
        Name: result.rule.Name || '',
        SourceSObjectType__c: result.rule.SourceSObjectType__c || '',
        IsEnabled__c: result.rule.IsEnabled__c !== false,
        Comments__c: result.rule.Comments__c || '',
        SourceSObjectFilter__c: result.rule.SourceSObjectFilter__c || '',
        DeduplicationSourceField__c: result.rule.DeduplicationSourceField__c || '',
        IsMatchThresholdEnabled__c: result.rule.IsMatchThresholdEnabled__c === true,
        MatchCountThreshold__c: result.rule.MatchCountThreshold__c ?? null,
        MatchThresholdTimePeriodIncrement__c: result.rule.MatchThresholdTimePeriodIncrement__c ?? null,
        MatchThresholdTimePeriodUnit__c: result.rule.MatchThresholdTimePeriodUnit__c || '',
        IsMatchHistoryEnabled__c: result.rule.IsMatchHistoryEnabled__c !== false,
        IsDeliveryHistoryEnabled__c: result.rule.IsDeliveryHistoryEnabled__c !== false,
        NumberOfDaysToRetainMatches__c: result.rule.NumberOfDaysToRetainMatches__c ?? null,
        NumberOfDaysToRetainDeliveries__c: result.rule.NumberOfDaysToRetainDeliveries__c ?? null
      };
      // Recipients get local Ids for the DOM iteration, plus their DB Id stashed so `handleSave`
      // can build the update / delete lists.
      this.pendingRecipients = (result.recipients || []).map(recipient => {
        this.nextLocalRecipientId += 1;
        return {
          localId: 'local-' + this.nextLocalRecipientId,
          Id: recipient.Id,
          LoggerNotificationService__c: recipient.LoggerNotificationService__c || null,
          ChannelIdentifier__c: recipient.ChannelIdentifier__c || '',
          EmailAddress__c: recipient.EmailAddress__c || '',
          User__c: recipient.User__c || null,
          ConfigurationJson__c: recipient.ConfigurationJson__c || '',
          IsEnabled__c: recipient.IsEnabled__c !== false
        };
      });
      // Snapshot the loaded state so `hasUnsavedChanges` can tell the difference between "loaded
      // from the DB" and "admin actually typed something". Without this, opening Guided Edit on
      // a saved rule and immediately hitting Esc would falsely prompt the LightningConfirm dialog
      // because the freshly-prefilled rule looks dirty against the create-mode defaults.
      this.initialSnapshot = JSON.stringify({ rule: this.rule, pendingRecipients: this.pendingRecipients });
      // Update the browser tab title with the loaded rule Name so admins juggling multiple Guided
      // Edit tabs can tell them apart. Skip when Name is empty (would produce `" | Salesforce"`);
      // the generic placeholder connectedCallback set is a better fallback than that.
      if (this.rule.Name) {
        document.title = `${this.rule.Name} | Salesforce`;
      }
    } catch (error) {
      this.errorMessage = 'Could not load the notification rule: ' + this.extractErrorMessage(error);
    } finally {
      this.isLoadingRecord = false;
    }
  }

  get isNew() {
    return !this.recordId;
  }

  disconnectedCallback() {
    if (this.boundHandleKeydown) {
      // Matching third argument to addEventListener - without `true` the removal silently
      // no-ops and the listener leaks past the LWC's disconnection.
      window.removeEventListener('keydown', this.boundHandleKeydown, true);
    }
    if (this.boundHandleModalCloseClick) {
      window.removeEventListener('click', this.boundHandleModalCloseClick, true);
    }
  }

  async handleKeydown(event) {
    if (event.key !== 'Escape') {
      return;
    }
    // If our own Discard-confirm is already up, let Esc pass through to the confirm's built-in
    // cancel handler. Swallowing it here would trap the admin - the confirm's own Esc would never
    // fire and there'd be no way to close the confirm without clicking Cancel.
    if (this.isDiscardConfirmOpen) {
      return;
    }
    if (!this.hasUnsavedChanges) {
      this.closeQuickAction();
      return;
    }
    // Prevent the quick-action modal's built-in Esc-to-close from firing while we prompt. If we
    // let it through, the modal detaches this LWC before the async confirm resolves.
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
    await this.confirmDiscardAndClose();
  }

  // Capture-phase click handler that intercepts the Quick Action modal's built-in X close button
  // (`.slds-modal__close` in platform-owned DOM, outside this LWC's shadow root). If the form has
  // unsaved changes, swallow the click and route through the shared unsaved-changes guard - same
  // LightningConfirm the Esc key and the Cancel button use. If clean, let the click pass through
  // and the container closes as usual.
  async handleModalCloseClick(event) {
    const target = event.target;
    if (!target || typeof target.closest !== 'function') {
      return;
    }
    const closeButton = target.closest('.slds-modal__close, button[title="Close this window"]');
    if (!closeButton) {
      return;
    }
    // Same passthrough as the Esc handler: if our Discard-confirm dialog is already open, don't
    // eat this click. The click needs to reach the LightningConfirm's own Cancel/OK buttons.
    if (this.isDiscardConfirmOpen) {
      return;
    }
    if (!this.hasUnsavedChanges) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
    await this.confirmDiscardAndClose();
  }

  // Shared exit path used by both the Escape keydown handler and the Cancel button. When there are
  // unsaved changes, prompts with LightningConfirm and closes only on confirm; otherwise closes
  // immediately. Keeps the two entry points in lockstep - one guard, one prompt string.
  //
  // Re-entry guard: `isDiscardConfirmOpen` prevents a rapid second Esc / Cancel from stacking a
  // second LightningConfirm behind the first while the first is still awaiting the admin's
  // decision. Without it, holding Esc down or hammering Cancel piles confirms on top of each other
  // and each one has to be dismissed individually.
  async confirmDiscardAndClose() {
    if (!this.hasUnsavedChanges) {
      this.closeQuickAction();
      return;
    }
    if (this.isDiscardConfirmOpen) {
      return;
    }
    this.isDiscardConfirmOpen = true;
    try {
      const proceed = await LightningConfirm.open({
        label: 'Discard unsaved changes?',
        message: 'You have unsaved changes to this notification rule. Close the form and discard them?',
        theme: 'warning',
        variant: 'header'
      });
      if (proceed) {
        this.closeQuickAction();
      }
    } finally {
      this.isDiscardConfirmOpen = false;
    }
  }

  // True whenever the admin has entered anything the runtime doesn't already know about - a rule
  // name, an edited filter, an added recipient. Any of these is enough to warrant an unsaved-changes
  // warning on Esc so a stray keypress doesn't wipe the in-progress form.
  //
  // Edit mode: compare against the snapshot captured at load time. The DB-prefilled fields are
  // "known" state and should NOT trigger a prompt on Esc unless the admin has actually edited
  // something after the load.
  //
  // Create mode: no snapshot exists, so fall back to comparing individual fields against the
  // known initial-state defaults. Simpler than tracking a dirty flag and avoids "typed then
  // deleted" edge cases.
  get hasUnsavedChanges() {
    if (this.initialSnapshot) {
      return JSON.stringify({ rule: this.rule, pendingRecipients: this.pendingRecipients }) !== this.initialSnapshot;
    }
    if (this.pendingRecipients.length > 0) {
      return true;
    }
    if (this.rule.Name && this.rule.Name.trim().length > 0) {
      return true;
    }
    if (this.rule.SourceSObjectFilter__c && this.rule.SourceSObjectFilter__c.trim().length > 0) {
      return true;
    }
    if (this.rule.DeduplicationSourceField__c && this.rule.DeduplicationSourceField__c.length > 0) {
      return true;
    }
    if (this.rule.Comments__c && this.rule.Comments__c.trim().length > 0) {
      return true;
    }
    if (this.rule.IsMatchThresholdEnabled__c === true) {
      return true;
    }
    return false;
  }

  @wire(getNotifierTypes)
  wiredNotifierTypes({ data, error }) {
    if (data) {
      this.notifierTypes = data;
    } else if (error) {
      this.errorMessage = 'Could not load notifier types: ' + this.extractErrorMessage(error);
    }
  }

  @wire(getAvailableServices)
  wiredServices(result) {
    // Retain the raw wire result so `refreshApex` can re-fetch after the nested "Create a new
    // Service" modal saves a new record. Without this the dropdown stays stale until the LWC is
    // re-mounted.
    this.wiredServicesResult = result;
    const { data, error } = result;
    if (data) {
      this.services = data;
    } else if (error) {
      this.errorMessage = 'Could not load notification services: ' + this.extractErrorMessage(error);
    }
  }

  // Resolve the default record type Id for LoggerNotificationRule__c so we can wire getPicklistValues.
  @wire(getObjectInfo, { objectApiName: LOGGER_NOTIFICATION_OBJECT })
  loggerNotificationObjectInfo;

  @wire(getPicklistValues, {
    recordTypeId: '$loggerNotificationObjectInfo.data.defaultRecordTypeId',
    fieldApiName: SOURCE_SOBJECT_TYPE_FIELD
  })
  wiredSourceSObjectTypePicklist({ data, error }) {
    if (data) {
      this.sourceSObjectTypeOptions = data.values.map(picklistValue => ({ label: picklistValue.label, value: picklistValue.value }));
    } else if (error) {
      this.errorMessage = 'Could not load Source SObject Type options: ' + this.extractErrorMessage(error);
    }
  }

  @wire(getPicklistValues, {
    recordTypeId: '$loggerNotificationObjectInfo.data.defaultRecordTypeId',
    fieldApiName: THRESHOLD_TIME_PERIOD_UNIT_FIELD
  })
  wiredThresholdTimePeriodUnitPicklist({ data, error }) {
    if (data) {
      this.thresholdTimePeriodUnitOptions = data.values.map(picklistValue => ({ label: picklistValue.label, value: picklistValue.value }));
    } else if (error) {
      this.errorMessage = 'Could not load Time Period Unit options: ' + this.extractErrorMessage(error);
    }
  }

  // Field list for the Deduplication Source Field dropdown, keyed on the currently-picked Source SObject Type.
  // Refetches automatically when the admin changes the picklist in step 1 because the wire target is reactive.
  @wire(getFieldsForSObject, { sobjectTypeName: '$rule.SourceSObjectType__c' })
  wiredDeduplicationFieldOptions({ data, error }) {
    if (data) {
      this.deduplicationFieldOptions = [
        { label: '(none)', value: '' },
        ...data.map(field => ({ label: field.apiName + ' (' + field.label + ')', value: field.apiName }))
      ];
    } else if (error) {
      this.errorMessage = 'Could not load deduplication field options: ' + this.extractErrorMessage(error);
    }
  }

  get cardTitle() {
    return this.isNew ? 'New Notification Rule (Guided)' : 'Edit Notification Rule (Guided)';
  }

  get saveButtonLabel() {
    if (this.isSaving) {
      return 'Saving...';
    }
    return this.isNew ? 'Create Rule' : 'Save Changes';
  }

  get nextButtonLabel() {
    return this.isValidatingFilter ? 'Validating...' : 'Next';
  }

  // Step 1: Basics (combined Basics + Filter). Step 2: Threshold. Step 3: Recipients. Step 4: Save.
  get isStep1() {
    return this.currentStep === 1;
  }
  get isStep2() {
    return this.currentStep === 2;
  }
  get isStep3() {
    return this.currentStep === 3;
  }
  get isStep4() {
    return this.currentStep === LAST_STEP;
  }

  get showPreviousButton() {
    return this.currentStep > 1;
  }
  get showNextButton() {
    return this.currentStep < LAST_STEP;
  }
  get showSaveButton() {
    return this.currentStep === LAST_STEP;
  }

  get steps() {
    return STEP_LABELS.map((label, index) => {
      const number = index + 1;
      let cssClass = 'slds-path__item';
      if (number === this.currentStep) {
        cssClass += ' slds-is-current slds-is-active';
      } else if (number < this.currentStep) {
        cssClass += ' slds-is-complete';
      } else {
        cssClass += ' slds-is-incomplete';
      }
      return { number, label, cssClass, isComplete: number < this.currentStep };
    });
  }

  get serviceOptions() {
    return this.services.map(service => ({ label: service.Name, value: service.Id }));
  }

  get hasServices() {
    return this.services && this.services.length > 0;
  }

  // Renders as a hint above the recipient list on the Recipients step (step 3 in the 4-step
  // wizard) when no services exist yet in the org. Steers admins toward the "Create a new Service"
  // button instead of leaving them stuck at an empty combobox with no idea how to proceed.
  get showNoServicesEmptyState() {
    return this.isStep3 && !this.hasServices;
  }

  get filterSuggestions() {
    const type = this.rule.SourceSObjectType__c;
    return type && FILTER_SUGGESTIONS[type] ? FILTER_SUGGESTIONS[type] : [];
  }

  get hasFilterSuggestions() {
    return this.filterSuggestions.length > 0;
  }

  // Gates the Source SObject Filter formula editor + deduplication combobox on Step 1. Filter
  // formulas compile against a specific SObject, and the deduplication picklist is populated
  // from a wire keyed on `$rule.SourceSObjectType__c`, so both controls are meaningless until an
  // SObject has been picked. Hiding them (rather than rendering them disabled) also gives the
  // page a natural cadence: pick the SObject, THEN the filter + deduplication UI appears.
  get hasSourceSObjectTypePicked() {
    return !!this.rule.SourceSObjectType__c;
  }

  handleApplyFilterSuggestion(event) {
    const formula = event.currentTarget.dataset.formula;
    if (formula) {
      this.rule = { ...this.rule, SourceSObjectFilter__c: formula };
    }
  }

  // Threshold-step conditional getters. Follow the validation rules on the object:
  // IsMatchThresholdEnabled__c and IsDeliveryHistoryEnabled__c both require IsMatchHistoryEnabled__c
  // to be true. If match history is off, the whole threshold block and the delivery-history checkbox
  // stay hidden - clearing them out at the same time so admins never leave stale values behind.
  get showThresholdDependentFields() {
    return this.rule.IsMatchHistoryEnabled__c === true;
  }

  get showMatchingThresholdDetails() {
    return this.rule.IsMatchHistoryEnabled__c === true && this.rule.IsMatchThresholdEnabled__c === true;
  }

  // Delivery retention days only matters when delivery rows are being stored. Match retention days
  // always shows once match history is on (the whole threshold cluster is gated on that flag already).
  get showDeliveryRetentionDaysInput() {
    return this.rule.IsMatchHistoryEnabled__c === true && this.rule.IsDeliveryHistoryEnabled__c === true;
  }

  get showMatchHistoryOffMessage() {
    return this.rule.IsMatchHistoryEnabled__c === false;
  }

  handleMatchHistoryChange(event) {
    const enabled = event.target.checked;
    // When match history flips off, force-clear the two dependents so the record still saves cleanly.
    if (enabled === false) {
      this.rule = {
        ...this.rule,
        IsMatchHistoryEnabled__c: false,
        IsMatchThresholdEnabled__c: false,
        IsDeliveryHistoryEnabled__c: false,
        MatchCountThreshold__c: null,
        MatchThresholdTimePeriodIncrement__c: null,
        MatchThresholdTimePeriodUnit__c: ''
      };
    } else {
      this.rule = { ...this.rule, IsMatchHistoryEnabled__c: true };
    }
  }

  handleThresholdEnabledChange(event) {
    const enabled = event.target.checked;
    if (enabled === false) {
      // Clear the three sub-fields when the threshold feature turns off.
      this.rule = {
        ...this.rule,
        IsMatchThresholdEnabled__c: false,
        MatchCountThreshold__c: null,
        MatchThresholdTimePeriodIncrement__c: null,
        MatchThresholdTimePeriodUnit__c: ''
      };
    } else {
      this.rule = { ...this.rule, IsMatchThresholdEnabled__c: true };
    }
  }

  // Plain-english recap of what the Match Threshold inputs on Step 2 will do, rendered inline as
  // admins fill them in. Empty string until all three threshold sub-fields have usable values - a
  // half-filled recap ("fires after ? matches within 15 Minutes") is more confusing than showing
  // nothing.
  get thresholdPlainEnglishSummary() {
    if (this.rule.IsMatchThresholdEnabled__c !== true) {
      return '';
    }
    const count = Number(this.rule.MatchCountThreshold__c);
    const increment = Number(this.rule.MatchThresholdTimePeriodIncrement__c);
    const unit = this.rule.MatchThresholdTimePeriodUnit__c;
    if (!count || !increment || !unit) {
      return '';
    }
    const matchNoun = count === 1 ? 'match' : 'matches';
    const matchVerb = count === 1 ? 'is' : 'are';
    // Compound modifier "N-<unit> window" always uses the singular unit ("10-minute window", not
    // "10-minutes window"), so strip a trailing s regardless of the increment.
    const unitLabel = unit.toLowerCase().replace(/s$/, '');
    return `The rule will fire once ${count} ${matchNoun} ${matchVerb} recorded within any rolling ${increment}-${unitLabel} window.`;
  }

  get recipientRows() {
    // Enrich pendingRecipients with UI-only fields the template needs (service name, notifier CMDT).
    return this.pendingRecipients.map((recipient, index) => {
      const editorMode = this.configEditorModeByRecipient[recipient.localId] || 'form';
      const toggleError = this.configEditorErrorByRecipient[recipient.localId];
      const service = this.services.find(candidate => candidate.Id === recipient.LoggerNotificationService__c);
      const notifierType = service ? this.notifierTypes.find(notifier => notifier.NotifierApexClassName__c === service.NotifierApexClassName__c) : null;
      const atLeastOneRequired = parseAtLeastOneRequiredFields(notifierType);
      const atLeastOneSatisfied = atLeastOneRequired.length === 0 || atLeastOneRequired.some(fieldName => hasValue(recipient[fieldName]));
      // Form-view pairs are independent state on the recipient row (stored as `formPairs`). This
      // matters for two reasons:
      //   1) An empty-key pair (fresh "Add entry" click before the admin types anything) can't be
      //      round-tripped through the JSON - it would either drop or collide with other empty-key
      //      pairs. Storing pairs directly means an empty-key row stays visible until named.
      //   2) The admin's typed key ordering is preserved during editing; we only re-sort when the
      //      JSON becomes canonical (JSON view or save-time serialize).
      // We rebuild `formPairs` from JSON on-demand when the row's JSON changes AND the local state
      // is empty (e.g. right after picking a service, or on initial edit-mode load).
      const parsedFromJson = parseConfigJsonToPairs(recipient.ConfigurationJson__c);
      const jsonInvalid = parsedFromJson === null;
      const formPairsSource = Array.isArray(recipient.formPairs) ? recipient.formPairs : parsedFromJson || [];
      const pairs = formPairsSource.map((pair, pairIndex) => ({
        localPairId: recipient.localId + '::' + pairIndex,
        key: pair.key,
        valueText: pair.valueText
      }));
      return {
        localId: recipient.localId,
        index,
        serviceId: recipient.LoggerNotificationService__c,
        serviceName: service ? service.Name : '(select a service)',
        supportsChannelIdentifier: notifierType ? notifierType.SupportsChannelIdentifier__c === true : false,
        supportsEmailAddress: notifierType ? notifierType.SupportsEmailAddress__c === true : false,
        supportsUser: notifierType ? notifierType.SupportsUser__c === true : false,
        channelIdentifierRequired: notifierType ? notifierType.IsChannelIdentifierRequired__c === true : false,
        emailAddressRequired: notifierType ? notifierType.IsEmailAddressRequired__c === true : false,
        userRequired: notifierType ? notifierType.IsUserRequired__c === true : false,
        suggestedConfigurationJson: notifierType ? notifierType.SuggestedConfigurationJson__c : null,
        atLeastOneRequiredFields: atLeastOneRequired,
        atLeastOneRequiredLabel: buildAtLeastOneRequiredLabel(atLeastOneRequired),
        atLeastOneRequiredSatisfied: atLeastOneSatisfied,
        showAtLeastOneRequiredWarning: atLeastOneRequired.length > 0 && !atLeastOneSatisfied,
        // Row-level "Create a new Service" affordance only makes sense when the admin hasn't already
        // picked a service for this row. Once picked, the button is noise on every recipient in orgs
        // with a healthy service catalog.
        showCreateServiceButton: !recipient.LoggerNotificationService__c,
        // The Configuration JSON section is hidden until the row has a picked service.
        // Before that point there's no notifier context, so there's nothing meaningful for the admin
        // to type - and the "Load Suggested Configuration" button couldn't do anything either.
        showConfigurationSection: !!recipient.LoggerNotificationService__c,
        // View-mode gating: exactly one of the two branches renders per row. Form view falls back
        // to JSON view when the row's stored JSON is malformed / not a top-level object - the admin
        // has to fix it in JSON view first.
        showJsonEditor: editorMode === 'json' || jsonInvalid,
        showFormEditor: editorMode === 'form' && !jsonInvalid,
        // Rendered inline above the JSON textarea when the row is stuck in JSON view because its
        // JSON is malformed (usually because the admin flipped to Form view and back after editing
        // by hand). Distinct from `configEditorToggleError` which surfaces at the toggle button.
        showRowJsonInvalidHint: editorMode === 'form' && jsonInvalid,
        // Per-row toggle uses a two-button group. The currently-active mode gets `variant="brand"`
        // (blue-filled) so the selection is visible at a glance; the inactive mode gets `neutral`.
        configFormButtonVariant: editorMode === 'form' ? 'brand' : 'neutral',
        configJsonButtonVariant: editorMode === 'json' ? 'brand' : 'neutral',
        configEditorToggleError: toggleError,
        pairs,
        ChannelIdentifier__c: recipient.ChannelIdentifier__c || '',
        EmailAddress__c: recipient.EmailAddress__c || '',
        User__c: recipient.User__c || '',
        ConfigurationJson__c: recipient.ConfigurationJson__c || '',
        IsEnabled__c: recipient.IsEnabled__c !== false
      };
    });
  }

  // Summary-step getters - describe what's configured so admins can review before saving.
  get summaryRecipients() {
    return this.pendingRecipients.map(recipient => {
      const service = this.services.find(candidate => candidate.Id === recipient.LoggerNotificationService__c);
      return {
        localId: recipient.localId,
        serviceName: service ? service.Name : '(no service selected)',
        target: recipient.ChannelIdentifier__c || recipient.EmailAddress__c || recipient.User__c || '(no target set)',
        isEnabled: recipient.IsEnabled__c !== false ? 'Enabled' : 'Disabled'
      };
    });
  }

  get summaryThresholdDescription() {
    if (this.rule.IsMatchThresholdEnabled__c !== true) {
      return 'No threshold - the rule fires on every match.';
    }
    const count = this.rule.MatchCountThreshold__c || '?';
    const increment = this.rule.MatchThresholdTimePeriodIncrement__c || '?';
    const unit = this.rule.MatchThresholdTimePeriodUnit__c || '?';
    return 'Threshold - fires after ' + count + ' matches within ' + increment + ' ' + unit + '.';
  }

  get summaryHistoryDescription() {
    if (this.rule.IsMatchHistoryEnabled__c !== true) {
      return 'No match or delivery history stored.';
    }
    if (this.rule.IsDeliveryHistoryEnabled__c === true) {
      return 'Match history and delivery history are stored.';
    }
    return 'Match history stored (delivery history off).';
  }

  get summaryDeduplicationDescription() {
    return this.rule.DeduplicationSourceField__c
      ? 'Matches deduplicated by ' + this.rule.DeduplicationSourceField__c + '.'
      : 'No deduplication - one match per source record.';
  }

  get summaryRuleStatus() {
    return this.rule.IsEnabled__c === true ? 'Enabled' : 'Disabled';
  }

  get hasRecipients() {
    return this.pendingRecipients.length > 0;
  }

  handleRuleFieldChange(event) {
    const field = event.target.dataset.field;
    const rawValue = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.rule = { ...this.rule, [field]: rawValue };
  }

  // Shape for a fresh recipient row - kept in one place so the "Add recipient" button and the
  // create-service auto-seed path can't drift out of sync when a field is added later.
  buildEmptyRecipientRow(overrides) {
    this.nextLocalRecipientId += 1;
    return {
      localId: 'local-' + this.nextLocalRecipientId,
      LoggerNotificationService__c: null,
      ChannelIdentifier__c: '',
      EmailAddress__c: '',
      User__c: '',
      ConfigurationJson__c: '',
      IsEnabled__c: true,
      ...(overrides || {})
    };
  }

  handleAddRecipient() {
    this.pendingRecipients = [...this.pendingRecipients, this.buildEmptyRecipientRow()];
  }

  handleRemoveRecipient(event) {
    const localId = event.target.dataset.localId;
    // If the row corresponds to a recipient that already exists in the DB (has an `Id`), append
    // its Id to `deletedRecipientIds` so the Save-time diff sends it to Apex's
    // `recipientIdsToDelete`. Rows without an Id were added in this session and simply drop from
    // the pending list.
    const target = this.pendingRecipients.find(recipient => recipient.localId === localId);
    if (target && target.Id) {
      this.deletedRecipientIds = [...this.deletedRecipientIds, target.Id];
    }
    this.pendingRecipients = this.pendingRecipients.filter(recipient => recipient.localId !== localId);
    // Drop any per-row toggle state so a future recycle of the same localId (unlikely, but
    // possible if a session builds up many recipients) doesn't inherit stale mode / error state.
    if (this.configEditorModeByRecipient[localId] || this.configEditorErrorByRecipient[localId]) {
      const nextModes = { ...this.configEditorModeByRecipient };
      const nextErrors = { ...this.configEditorErrorByRecipient };
      delete nextModes[localId];
      delete nextErrors[localId];
      this.configEditorModeByRecipient = nextModes;
      this.configEditorErrorByRecipient = nextErrors;
    }
  }

  handleRecipientFieldChange(event) {
    const localId = event.target.dataset.localId;
    const field = event.target.dataset.field;
    const rawValue = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    this.pendingRecipients = this.pendingRecipients.map(recipient => {
      if (recipient.localId !== localId) {
        return recipient;
      }
      const updated = { ...recipient, [field]: rawValue };
      // Whenever the picked service changes, overwrite ConfigurationJson__c with the
      // newly-picked notifier's SuggestedConfigurationJson__c (empty string when the notifier
      // ships nothing). Applies to both new rows and existing records - a service switch always
      // implies "start from this notifier's suggested config"; admins keep the explicit "Load
      // suggested" button to re-apply the same JSON if they've edited it and want to reset.
      // `formPairs` is cleared so the next Form-view render re-materializes from the new JSON.
      if (field === 'LoggerNotificationService__c') {
        const service = rawValue ? this.services.find(candidate => candidate.Id === rawValue) : null;
        const notifierType = service ? this.notifierTypes.find(notifier => notifier.NotifierApexClassName__c === service.NotifierApexClassName__c) : null;
        updated.ConfigurationJson__c = notifierType && notifierType.SuggestedConfigurationJson__c ? notifierType.SuggestedConfigurationJson__c : '';
        updated.formPairs = undefined;
      }
      // A direct JSON textarea edit invalidates the row's cached formPairs - the next Form-view
      // render should re-materialize from the just-edited JSON, not from whatever pair state was
      // there before.
      if (field === 'ConfigurationJson__c') {
        updated.formPairs = undefined;
      }
      return updated;
    });
  }

  handleUserChange(event) {
    // lightning-record-picker uses event.detail.recordId, not event.target.value.
    const localId = event.target.dataset.localId;
    const recordId = event.detail && event.detail.recordId ? event.detail.recordId : null;
    this.pendingRecipients = this.pendingRecipients.map(recipient => (recipient.localId === localId ? { ...recipient, User__c: recordId } : recipient));
  }

  // Row-level "Create a new Service" - opens the modal, stamps the new service Id back onto the
  // recipient row that triggered it. The row's localId comes from the data attribute on the button.
  handleCreateServiceFromRecipientRow(event) {
    const localId = event.currentTarget.dataset.localId;
    return this.openCreateServiceModalAndApply(newServiceId => {
      this.pendingRecipients = this.pendingRecipients.map(recipient =>
        recipient.localId === localId ? { ...recipient, LoggerNotificationService__c: newServiceId } : recipient
      );
    });
  }

  // Empty-state banner "Create a new Service" - opens the modal, seeds a new recipient row pointing
  // at the just-created service (admins land on the banner precisely because there's no row yet).
  handleCreateServiceFromEmptyState() {
    return this.openCreateServiceModalAndApply(newServiceId => {
      this.pendingRecipients = [...this.pendingRecipients, this.buildEmptyRecipientRow({ LoggerNotificationService__c: newServiceId })];
    });
  }

  // Shared modal-open + wire-refresh + service-application. LightningModal mounts at the document
  // root (outside every ancestor shadow-root and containing block) so the nested modal's backdrop
  // covers the full viewport - a same-shadow-root `<section role="dialog">` inside the outer
  // quick-action modal would only cover the outer modal's width.
  async openCreateServiceModalAndApply(applyServiceId) {
    // `medium` (~48rem / 768px) fits inside the Quick Action modal's own footprint without
    // dwarfing it. `large` was too wide - the nested modal visually eclipsed the outer wizard.
    const newServiceId = await LoggerNotificationServiceModal.open({
      size: 'medium',
      description: 'Create a new notification service without leaving the rule.'
    });
    if (!newServiceId) {
      return;
    }
    try {
      await refreshApex(this.wiredServicesResult);
    } catch (refreshError) {
      this.errorMessage = 'Service was created, but the services list could not be refreshed: ' + this.extractErrorMessage(refreshError);
      return;
    }
    applyServiceId(newServiceId);
  }

  handleLoadSuggestedConfig(event) {
    const localId = event.target.dataset.localId;
    const target = this.pendingRecipients.find(recipient => recipient.localId === localId);
    if (!target || !target.LoggerNotificationService__c) {
      return;
    }
    const service = this.services.find(candidate => candidate.Id === target.LoggerNotificationService__c);
    if (!service) {
      return;
    }
    const notifierType = this.notifierTypes.find(notifier => notifier.NotifierApexClassName__c === service.NotifierApexClassName__c);
    if (!notifierType || !notifierType.SuggestedConfigurationJson__c) {
      return;
    }
    // `formPairs` is cleared so the next Form-view render re-materializes from the reset JSON -
    // otherwise the admin would still see whatever pairs they had before hitting Load Suggested Configuration.
    this.pendingRecipients = this.pendingRecipients.map(recipient =>
      recipient.localId === localId ? { ...recipient, ConfigurationJson__c: notifierType.SuggestedConfigurationJson__c, formPairs: undefined } : recipient
    );
  }

  // Per-recipient JSON <-> Form toggle. Click on the target mode's button in the two-button group;
  // the handler reads the target mode from `data-target-mode`. Refuses the switch to Form view
  // when the row's JSON is malformed / not a top-level object and stores an inline error keyed on
  // the row's localId. Clicking the button for the mode that's already active is a no-op.
  handleConfigEditorToggle(event) {
    const localId = event.target.dataset.localId;
    const targetMode = event.target.dataset.targetMode;
    const target = this.pendingRecipients.find(recipient => recipient.localId === localId);
    if (!target || (targetMode !== 'form' && targetMode !== 'json')) {
      return;
    }
    const currentMode = this.configEditorModeByRecipient[localId] || 'form';
    if (currentMode === targetMode) {
      return;
    }
    if (targetMode === 'form') {
      if (hasValue(target.ConfigurationJson__c) && parseConfigJsonToPairs(target.ConfigurationJson__c) === null) {
        this.configEditorErrorByRecipient = {
          ...this.configEditorErrorByRecipient,
          [localId]: "Cannot switch to Form view - this recipient's JSON is malformed or not a top-level object. Fix it here first."
        };
        return;
      }
    }
    this.configEditorModeByRecipient = { ...this.configEditorModeByRecipient, [localId]: targetMode };
    if (this.configEditorErrorByRecipient[localId]) {
      const nextErrors = { ...this.configEditorErrorByRecipient };
      delete nextErrors[localId];
      this.configEditorErrorByRecipient = nextErrors;
    }
  }

  // Form-view handlers. Each edit updates the row's `formPairs` state and re-serializes the named
  // subset back to `ConfigurationJson__c` so JSON view + save-time payload stay in sync.
  // We keep `formPairs` (with empty-key rows) AND the derived JSON (without them) because empty-key
  // rows can't be round-tripped through JSON without either dropping or colliding.
  handleConfigPairKeyChange(event) {
    const localId = event.target.dataset.localId;
    const pairIndex = Number.parseInt(event.target.dataset.pairIndex, 10);
    const newKey = event.target.value;
    this.updatePairAtIndex(localId, pairIndex, current => ({ ...current, key: newKey }));
  }

  handleConfigPairValueChange(event) {
    const localId = event.target.dataset.localId;
    const pairIndex = Number.parseInt(event.target.dataset.pairIndex, 10);
    const newValueText = event.target.value;
    this.updatePairAtIndex(localId, pairIndex, current => ({ ...current, valueText: newValueText }));
  }

  handleAddConfigPair(event) {
    const localId = event.target.dataset.localId;
    this.pendingRecipients = this.pendingRecipients.map(recipient => {
      if (recipient.localId !== localId) {
        return recipient;
      }
      const currentPairs = this.ensureFormPairs(recipient);
      const nextPairs = [...currentPairs, { key: '', valueText: '' }];
      return { ...recipient, formPairs: nextPairs, ConfigurationJson__c: serializePairsToJson(nextPairs) };
    });
  }

  async handleDeleteConfigPair(event) {
    const localId = event.target.dataset.localId;
    const pairIndex = Number.parseInt(event.target.dataset.pairIndex, 10);
    const target = this.pendingRecipients.find(recipient => recipient.localId === localId);
    if (!target) {
      return;
    }
    const currentPairs = this.ensureFormPairs(target);
    const pair = currentPairs[pairIndex];
    if (!pair) {
      return;
    }
    const confirmed = await LightningConfirm.open({
      label: 'Remove configuration entry?',
      message: 'Remove the "' + (pair.key || '(empty key)') + '" entry from this recipient\'s configuration?',
      theme: 'warning',
      variant: 'header'
    });
    if (!confirmed) {
      return;
    }
    const nextPairs = currentPairs.filter((_, index) => index !== pairIndex);
    this.pendingRecipients = this.pendingRecipients.map(recipient =>
      recipient.localId === localId
        ? {
            ...recipient,
            formPairs: nextPairs,
            ConfigurationJson__c: nextPairs.length === 0 ? '' : serializePairsToJson(nextPairs)
          }
        : recipient
    );
  }

  // Shared write-through helper for Form-view key + value edits. Applies the transform to the
  // row's local `formPairs` state, then re-serializes the named subset back to the JSON field.
  updatePairAtIndex(localId, pairIndex, transform) {
    this.pendingRecipients = this.pendingRecipients.map(recipient => {
      if (recipient.localId !== localId) {
        return recipient;
      }
      const currentPairs = this.ensureFormPairs(recipient);
      if (pairIndex < 0 || pairIndex >= currentPairs.length) {
        return recipient;
      }
      const nextPairs = currentPairs.map((current, index) => (index === pairIndex ? transform(current) : current));
      return { ...recipient, formPairs: nextPairs, ConfigurationJson__c: serializePairsToJson(nextPairs) };
    });
  }

  // Materializes `formPairs` on the recipient from its JSON when the row doesn't already have a
  // local pair list. Called by every Form-view handler so the first Form-view interaction on any
  // row seeds `formPairs` from whatever's currently in the JSON (auto-populated suggested config,
  // hand-entered JSON, or the saved config on an edit).
  ensureFormPairs(recipient) {
    if (Array.isArray(recipient.formPairs)) {
      return recipient.formPairs;
    }
    return parseConfigJsonToPairs(recipient.ConfigurationJson__c) || [];
  }

  async handleNextStep() {
    if (!this.isCurrentStepValid()) {
      return;
    }
    // Step 1 (Basics) owns the SourceSObjectFilter__c textarea. Before letting the admin advance,
    // run the same Apex-side compile-and-evaluate check the before-save trigger applies at save
    // time. Doing it here means a bad formula surfaces on step 1 (right next to the input) instead
    // of at the end of the wizard, where the failed save otherwise leaves admins hunting for the
    // offending field with no context. Skip when the field is empty - the required-field guard
    // above catches that separately.
    if (this.currentStep === 1 && this.rule.SourceSObjectFilter__c) {
      this.isValidatingFilter = true;
      try {
        const validationError = await validateSourceSObjectFilter({
          sobjectTypeName: this.rule.SourceSObjectType__c,
          filter: this.rule.SourceSObjectFilter__c
        });
        if (validationError) {
          this.errorMessage = validationError;
          return;
        }
      } catch (apexError) {
        this.errorMessage = 'Could not validate the filter: ' + this.extractErrorMessage(apexError);
        return;
      } finally {
        this.isValidatingFilter = false;
      }
      // Clear any prior error banner - only for the "we validated last time and it failed" case;
      // step-1 or step-4 errors surviving into step 3 would be a mistake in the caller, not here.
      this.errorMessage = null;
    }
    if (this.currentStep < LAST_STEP) {
      this.currentStep += 1;
    }
  }

  // Validates the currently-rendered step by asking every visible lightning-* input to
  // reportValidity(). Because LWC's lwc:if only mounts the current step's markup, everything
  // returned by this query is scoped to the active step. `reportValidity()` returns false if the
  // field is invalid (empty when required, or otherwise failing constraints) AND surfaces the
  // built-in red-outline + hint text so admins can see which field to fix. Runs `.every` over the
  // full list rather than short-circuiting so all failing fields light up at once - admins hate
  // fix-one-then-see-the-next-error dances.
  isCurrentStepValid() {
    const inputs = this.template.querySelectorAll(
      'lightning-input, lightning-textarea, lightning-combobox, lightning-record-picker, c-logger-notification-formula-editor'
    );
    let allValid = true;
    inputs.forEach(input => {
      if (input.reportValidity && input.reportValidity() === false) {
        allValid = false;
      }
    });
    return allValid;
  }

  handlePreviousStep() {
    if (this.currentStep > 1) {
      this.currentStep -= 1;
    }
  }

  handleStepClick(event) {
    const target = parseInt(event.currentTarget.dataset.step, 10);
    if (target && target <= this.currentStep) {
      this.currentStep = target;
    }
  }

  handleSave() {
    this.errorMessage = null;

    // Same per-field validity check we run on Next. Save is reachable directly on Step 4 (Review),
    // which has no required-input constraints of its own, but a user who advanced from Step 3
    // without picking a service on a newly-added recipient row would otherwise slip through -
    // stepping back to Step 3 to re-check is cheap and covers that.
    if (!this.isCurrentStepValid()) {
      return;
    }

    // Client-side check: every recipient whose notifier declares AtLeastOneRequiredRecipientFields__c must have
    // at least one of those fields populated. Blocks Save so admins get a clear error before the
    // Apex trip.
    const unsatisfied = this.recipientRows.filter(recipientRow => recipientRow.showAtLeastOneRequiredWarning);
    if (unsatisfied.length > 0) {
      this.errorMessage =
        'Fix these recipients before saving: ' +
        unsatisfied.map(recipientRow => recipientRow.serviceName + ' requires one of ' + recipientRow.atLeastOneRequiredLabel).join('; ');
      return;
    }

    this.isSaving = true;

    if (this.isNew) {
      this.executeCreate();
    } else {
      this.executeUpdate();
    }
  }

  // Insert path: hand the full rule + recipient list to `saveRuleWithRecipients`. Recipient rows
  // are stripped of UI-only fields (localId, Id-if-any) before dispatch. This is the pre-existing
  // Create flow, extracted so `handleSave` can branch cleanly on `isNew`.
  executeCreate() {
    const ruleToSave = { ...this.rule };
    const recipientsToSave = this.pendingRecipients.map(recipient => ({
      LoggerNotificationService__c: recipient.LoggerNotificationService__c,
      ChannelIdentifier__c: recipient.ChannelIdentifier__c || null,
      EmailAddress__c: recipient.EmailAddress__c || null,
      User__c: recipient.User__c || null,
      ConfigurationJson__c: recipient.ConfigurationJson__c || null,
      IsEnabled__c: recipient.IsEnabled__c !== false
    }));

    saveRuleWithRecipients({ rule: ruleToSave, recipients: recipientsToSave })
      .then(newId => {
        const recipientCountLabel = recipientsToSave.length === 1 ? '1 recipient' : recipientsToSave.length + ' recipients';
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Notification rule created with ' + recipientCountLabel + '.',
            variant: 'success'
          })
        );
        this.finishSave(newId);
      })
      .catch(error => {
        this.errorMessage = 'Save failed: ' + this.extractErrorMessage(error);
      })
      .finally(() => {
        this.isSaving = false;
      });
  }

  // Update path: compute the recipient diff (insert / update / delete) and hand each list to
  // `updateRuleWithRecipients`. Recipients without an `Id` in `pendingRecipients` are inserts;
  // those with an `Id` are updates (we don't try to detect no-change updates here - the server-side
  // savepoint keeps things atomic and re-DML on unchanged rows is a rounding-error DML cost).
  // Deletions come from `deletedRecipientIds`, which was populated as the admin clicked the trash
  // icon on rows that had come from the DB.
  executeUpdate() {
    const ruleToSave = { ...this.rule, Id: this.recordId };
    const recipientsToInsert = [];
    const recipientsToUpdate = [];
    this.pendingRecipients.forEach(recipient => {
      const payload = {
        LoggerNotificationService__c: recipient.LoggerNotificationService__c,
        ChannelIdentifier__c: recipient.ChannelIdentifier__c || null,
        EmailAddress__c: recipient.EmailAddress__c || null,
        User__c: recipient.User__c || null,
        ConfigurationJson__c: recipient.ConfigurationJson__c || null,
        IsEnabled__c: recipient.IsEnabled__c !== false
      };
      if (recipient.Id) {
        recipientsToUpdate.push({ ...payload, Id: recipient.Id });
      } else {
        recipientsToInsert.push(payload);
      }
    });
    const recipientIdsToDelete = [...this.deletedRecipientIds];

    updateRuleWithRecipients({
      rule: ruleToSave,
      recipientsToInsert,
      recipientsToUpdate,
      recipientIdsToDelete
    })
      .then(ruleId => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Notification rule updated.',
            variant: 'success'
          })
        );
        this.finishSave(ruleId);
      })
      .catch(error => {
        this.errorMessage = 'Save failed: ' + this.extractErrorMessage(error);
      })
      .finally(() => {
        this.isSaving = false;
      });
  }

  handleCancel() {
    // Same guard as Escape. The button previously closed immediately, which meant an accidental
    // click halfway through the wizard destroyed everything the admin had entered.
    this.confirmDiscardAndClose();
  }

  closeQuickAction() {
    // `CloseActionScreenEvent` is Salesforce's officially-supported way to close a Screen Action
    // Quick Action's host modal. The URL-addressable page ignores it, which is fine - admins on
    // that path use browser back / navigation to leave.
    //
    // `setTimeout(0)` defers the dispatch one macro task so it doesn't fire from inside a resolved-
    // Promise continuation (which the Quick Action container's async-state tracker no-ops).
    setTimeout(() => this.dispatchEvent(new CloseActionScreenEvent()), 0);
  }

  // Shared success path used by both `executeCreate` and `executeUpdate`. Navigates to the saved
  // record page and closes the Quick Action container.
  finishSave(savedRuleId) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: savedRuleId, objectApiName: 'LoggerNotificationRule__c', actionName: 'view' }
    });
    this.closeQuickAction();
  }

  extractErrorMessage(error) {
    if (!error) {
      return 'Unknown error';
    }
    if (typeof error === 'string') {
      return error;
    }
    if (error.body) {
      if (Array.isArray(error.body)) {
        return error.body.map(bodyEntry => bodyEntry.message).join(', ');
      }
      return error.body.message || JSON.stringify(error.body);
    }
    return error.message || JSON.stringify(error);
  }
}
