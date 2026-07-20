import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import getNotifierTypes from '@salesforce/apex/LoggerNotifierGuidedFormController.getNotifierTypes';
import NOTIFIER_APEX_CLASS_NAME_FIELD from '@salesforce/schema/LoggerNotificationService__c.NotifierApexClassName__c';
import NAME_FIELD from '@salesforce/schema/LoggerNotificationService__c.Name';

// `Name` is fetched so the wire's resolve step can push it into `document.title`. That's the only
// reason it's here - the form itself lets `lightning-record-edit-form` re-read Name via its own
// wire path, so we don't need to bind against the value directly.
const SERVICE_FIELDS = [NOTIFIER_APEX_CLASS_NAME_FIELD, NAME_FIELD];

function parseAtLeastOneRequiredFields(rawValue) {
  if (!rawValue) {
    return [];
  }
  return rawValue
    .split(/[\r\n,]+/)
    .map(entry => entry.trim())
    .filter(entry => entry.length > 0);
}

function hasValue(value) {
  return value !== null && value !== undefined && String(value).trim().length > 0;
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

export default class LoggerNotificationServiceGuidedForm extends NavigationMixin(LightningElement) {
  @api recordId;
  // Set by LoggerNotificationServiceModal when the form is mid-flow inside the rule form's
  // "Create a new Service" escape hatch. Only gates POST-SAVE behavior: embedded=true fires the
  // `create` event and lets the modal wrapper handle recovery (refresh services list + auto-select
  // the new record); embedded=false navigates to the saved service's record page from within the
  // form. The template renders the same way in both modes.
  @api embedded = false;

  notifierTypes = [];
  selectedNotifierApexClassName;
  errorMessage;
  isFormLoading = false;
  // Setup guidance sits above the form so admins see it before configuring; it's collapsed by default
  // because the markdown can be long and would otherwise push the form itself off-screen.
  isGuidanceExpanded = false;
  // Flips true the first time an input inside the record-edit-form changes. Drives the Esc handler's
  // unsaved-changes guard so admins can't lose in-progress work by tapping Escape.
  isFormDirty = false;
  isLoadingNotifierTypes = true;
  isLoadingRecord = false;

  // True when the LWC is mounted on the URL-addressable /lightning/cmp/c__... page rather than
  // inside a Quick Action Screen Action container or a LightningModal body. Gates Cancel + Esc
  // intercept: on the URL page there's no container to close, so Cancel would strand admins and
  // an Esc intercept is unnecessary. NOTE: `embedded=true` short-circuits this - when the form is
  // hosted inside LoggerNotificationServiceModal (the rule form's "Create a new Service" mid-flow
  // escape hatch), the parent page URL matches `/lightning/cmp/...` too, but there IS a container
  // to close (the LightningModal wrapper), so we treat embedded as "has a container" regardless.
  isUrlAddressableMount = false;

  connectedCallback() {
    this.isUrlAddressableMount = this.detectUrlAddressableMount();
    // Initial document.title. New-mode gets a generic label immediately; edit-mode also gets a
    // generic placeholder so the tab shows something meaningful before the getRecord wire
    // resolves. The wire callback overwrites the title with the actual record Name once it
    // lands. Runs on every mount because the tab title benefits either way.
    document.title = this.isNew ? 'New Notification Service | Salesforce' : 'Edit Notification Service | Salesforce';
    if (this.isUrlAddressableMount && !this.embedded) {
      return;
    }
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    window.addEventListener('keydown', this.boundHandleKeydown, true);
  }

  // Extracted so jest can spy on it. jsdom's `window.location.pathname` is not configurable, so
  // tests that need to force URL-addressable behavior stub this method directly.
  detectUrlAddressableMount() {
    return window.location.pathname.startsWith('/lightning/cmp/');
  }

  disconnectedCallback() {
    if (this.boundHandleKeydown) {
      window.removeEventListener('keydown', this.boundHandleKeydown, true);
    }
  }

  // Gates the Cancel button in the panel footer. Hidden on the URL-addressable page (no container
  // to close), visible everywhere else - including the embedded-in-LightningModal path, where the
  // parent page URL is also `/lightning/cmp/...` but the modal wrapper IS the container to close.
  get showCancelButton() {
    return !this.isUrlAddressableMount || this.embedded;
  }

  // The visible Save button lives in `<lightning-quick-action-panel>`'s footer slot, outside the
  // `<lightning-record-edit-form>`. A submit `type` attribute only triggers the record-edit-form's
  // onsubmit when the click reaches an ancestor `<form>`, which the slotted footer button isn't
  // inside. So we route the footer click here and synthetically click a hidden `type="submit"`
  // button that IS inside the record-edit-form.
  handleSaveClick() {
    const hiddenSubmit = this.template.querySelector('[data-hidden-submit]');
    if (hiddenSubmit) {
      hiddenSubmit.click();
    }
  }

  async handleKeydown(event) {
    if (event.key !== 'Escape') {
      return;
    }
    if (!this.isFormDirty) {
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

  // Shared exit path for Escape and the Cancel button. Prompts with LightningConfirm when the form
  // is dirty; closes immediately when it isn't.
  async confirmDiscardAndClose() {
    if (!this.isFormDirty) {
      this.closeQuickAction();
      return;
    }
    const proceed = await LightningConfirm.open({
      label: 'Discard unsaved changes?',
      message: 'You have unsaved changes to this notification service. Close the form and discard them?',
      theme: 'warning',
      variant: 'header'
    });
    if (proceed) {
      this.closeQuickAction();
    }
  }

  handleFormChange() {
    this.isFormDirty = true;
  }

  @wire(getNotifierTypes)
  wiredNotifierTypes({ data, error }) {
    this.isLoadingNotifierTypes = false;
    if (data) {
      this.notifierTypes = data;
    } else if (error) {
      this.errorMessage = 'Could not load notifier types: ' + this.extractErrorMessage(error);
    }
  }

  @wire(getRecord, { recordId: '$recordId', fields: SERVICE_FIELDS })
  wiredService({ data, error }) {
    if (data) {
      this.selectedNotifierApexClassName = getFieldValue(data, NOTIFIER_APEX_CLASS_NAME_FIELD);
      // Push the loaded service Name into the browser tab title so admins juggling multiple
      // Guided Edit tabs can tell them apart. Skip on blank names - the generic placeholder
      // connectedCallback set is a better fallback than `" | Salesforce"`.
      const recordName = getFieldValue(data, NAME_FIELD);
      if (recordName) {
        document.title = `${recordName} | Salesforce`;
      }
    } else if (error && this.recordId) {
      this.errorMessage = 'Could not load service record: ' + this.extractErrorMessage(error);
    }
  }

  get isLoading() {
    return this.isLoadingNotifierTypes || this.isLoadingRecord;
  }

  get isNew() {
    return !this.recordId;
  }

  get cardTitle() {
    return this.isNew ? 'New Notification Service (Guided)' : 'Edit Notification Service (Guided)';
  }

  get saveButtonLabel() {
    return this.isNew ? 'Create Service' : 'Save Changes';
  }

  get showNotifierPicker() {
    // Only picker on New - Edit stays locked to whatever notifier the record already points at,
    // since changing the notifier of an existing service mid-configuration is rarely intentional.
    return this.isNew;
  }

  get notifierTypeOptions() {
    return this.notifierTypes.map(notifier => ({
      label: notifier.DisplayLabel__c,
      value: notifier.NotifierApexClassName__c
    }));
  }

  get selectedNotifierType() {
    if (!this.selectedNotifierApexClassName || !this.notifierTypes || this.notifierTypes.length === 0) {
      return null;
    }
    return this.notifierTypes.find(notifier => notifier.NotifierApexClassName__c === this.selectedNotifierApexClassName) || null;
  }

  // The following getters exist so the template never dereferences a possibly-null selectedNotifierType.
  // LWC template expressions like `{selectedNotifierType.Description__c}` throw when the object is null,
  // so we wrap every access in a getter that null-checks first.

  get hasNotifierType() {
    return this.selectedNotifierType !== null;
  }

  get selectedNotifierDescription() {
    return this.selectedNotifierType ? this.selectedNotifierType.Description__c : null;
  }

  // On a New guided service, seed the Name field with the picked notifier's display label. Returns
  // undefined for the Edit path so we don't clobber the saved Name if the admin already set one.
  get defaultServiceName() {
    if (!this.isNew) {
      return undefined;
    }
    return this.selectedNotifierType ? this.selectedNotifierType.DisplayLabel__c : undefined;
  }

  get selectedNotifierDisplayLabel() {
    return this.selectedNotifierType ? this.selectedNotifierType.DisplayLabel__c : null;
  }

  get selectedNotifierSetupGuidance() {
    return this.selectedNotifierType ? this.selectedNotifierType.SetupGuidanceMarkdown__c : null;
  }

  get selectedNotifierSupportsWebhookUrl() {
    return this.selectedNotifierType ? this.selectedNotifierType.SupportsWebhookUrl__c === true : false;
  }

  get selectedNotifierSupportsNamedCredential() {
    return this.selectedNotifierType ? this.selectedNotifierType.SupportsNamedCredential__c === true : false;
  }

  // Parsed list of service-side fields where the picked notifier requires at least one to be populated
  // before the service can save. Empty for notifiers that don't declare the constraint (e.g. Email,
  // CustomNotification - which don't take a WebhookUrl / Named Credential at all).
  get atLeastOneRequiredServiceFields() {
    if (!this.selectedNotifierType) {
      return [];
    }
    return parseAtLeastOneRequiredFields(this.selectedNotifierType.AtLeastOneRequiredServiceFields__c);
  }

  // Inline hint that renders above the record-edit-form when the picked notifier declares service-side
  // required fields. Purely informational until submit - the actual save-block happens in handleSubmit.
  get serviceRequiredFieldsHint() {
    const fields = this.atLeastOneRequiredServiceFields;
    if (fields.length === 0) {
      return null;
    }
    return 'This notifier requires at least one of: ' + buildAtLeastOneRequiredLabel(fields) + '.';
  }

  handleNotifierTypeChange(event) {
    // Only spin on the FIRST notifier pick: `lightning-record-edit-form` fires `onload` exactly
    // once when it mounts, and it stays mounted across subsequent notifier switches (same
    // object-api-name). If we flipped the spinner on every switch, `handleFormLoad` would never
    // fire again to turn it back off and the modal would stay spinning forever.
    const isFirstPick = !this.selectedNotifierApexClassName;
    this.selectedNotifierApexClassName = event.detail.value;
    if (isFirstPick) {
      this.isFormLoading = true;
    }
  }

  handleFormLoad() {
    this.isFormLoading = false;
  }

  get guidanceToggleIcon() {
    return this.isGuidanceExpanded ? 'utility:chevronup' : 'utility:chevrondown';
  }

  get guidanceToggleAltText() {
    return this.isGuidanceExpanded ? 'Collapse setup guidance' : 'Expand setup guidance';
  }

  handleToggleGuidance() {
    this.isGuidanceExpanded = !this.isGuidanceExpanded;
  }

  handleSubmit(event) {
    // Client-side gate: the notifier's `AtLeastOneRequiredServiceFields__c` CMDT value names the
    // service-side fields (typically WebhookUrl__c + NamedCredentialDeveloperName__c) where at
    // least one must be populated. `event.detail.fields` holds the record-edit-form's current
    // values. Block the submit and surface an inline error if none of the required fields is set.
    const requiredFields = this.atLeastOneRequiredServiceFields;
    if (requiredFields.length === 0) {
      return;
    }
    const fields = event.detail && event.detail.fields ? event.detail.fields : {};
    const satisfied = requiredFields.some(fieldName => hasValue(fields[fieldName]));
    if (!satisfied) {
      event.preventDefault();
      this.errorMessage = 'Populate at least one of: ' + buildAtLeastOneRequiredLabel(requiredFields) + '.';
    }
  }

  handleSaveSuccess(event) {
    // A successful save clears the dirty state so the post-save navigation doesn't re-prompt Esc.
    this.isFormDirty = false;
    const savedId = event.detail.id;
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: this.isNew ? 'Notification service created.' : 'Notification service updated.',
        variant: 'success'
      })
    );
    if (this.embedded) {
      // Mid-flow inside the rule form's Recipients step (via LoggerNotificationServiceModal). The
      // modal wrapper listens for `create`, resolves its `.open()` promise with the new Id, and
      // the rule form refreshes its services list + auto-selects the record. Do NOT navigate here
      // - it would destroy the parent rule form's in-progress state.
      this.dispatchEvent(new CustomEvent('create', { detail: { recordId: savedId } }));
      this.closeQuickAction();
      return;
    }
    // Standalone (Quick Action or URL page): navigate to the saved record's record page. The
    // Quick Action container automatically tears down on navigation, so no closeQuickAction()
    // call is needed.
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: { recordId: savedId, objectApiName: 'LoggerNotificationService__c', actionName: 'view' }
    });
  }

  handleSaveError(event) {
    this.errorMessage = 'Save failed: ' + this.extractErrorMessage(event.detail);
  }

  handleCancel() {
    // Same guard as Escape. The button previously closed immediately, which meant an accidental
    // click destroyed any in-progress input.
    this.confirmDiscardAndClose();
  }

  closeQuickAction() {
    if (this.embedded) {
      // Inside LoggerNotificationServiceModal - the wrapper listens for `close` and calls its own
      // `this.close(null)` to detach the LightningModal.
      this.dispatchEvent(new CustomEvent('close'));
      return;
    }
    // Standalone Quick Action / URL page. See the rule form for the setTimeout(0) rationale:
    // firing CloseActionScreenEvent from a resolved-Promise continuation lands mid-async-action
    // and the container no-ops. Deferring one macro task lets the platform's state settle.
    setTimeout(() => this.dispatchEvent(new CloseActionScreenEvent()), 0);
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
