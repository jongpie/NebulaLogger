import { api } from 'lwc';
import LightningModal from 'lightning/modal';

// Thin LightningModal wrapper around loggerNotificationServiceGuidedForm. LightningModal mounts the
// modal at the document root (outside every ancestor shadow-root + transform / filter containing
// block), which is the only way to get a viewport-wide backdrop when opening from inside another
// modal. Callers use LoggerNotificationServiceModal.open({size: 'medium', recordId?}) and await
// the returned promise: it resolves to the new service's Id on save, or null on cancel/close.
export default class LoggerNotificationServiceModal extends LightningModal {
  // Forwarded to the embedded form. When set, the form runs in edit mode and prefetches the
  // existing service record via `getRecord`. Unset for the "Set up a new Service" path.
  @api recordId;

  handleServiceCreated(event) {
    // Default to null (not undefined) when the detail is missing a recordId - callers of open()
    // treat "no Id" and "cancelled" identically via a single truthy check, and null keeps that
    // contract crisp instead of leaking undefined into the promise resolution.
    const newServiceId = event?.detail?.recordId ?? null;
    // LightningModal.close(result) resolves the .open() promise with result; the caller can then
    // refresh their services list and stamp the new Id onto the pending recipient row.
    this.close(newServiceId);
  }

  handleServiceFormClose() {
    // The child form's `close` event fires when the admin cancels or Esc-confirms. Resolve the
    // modal promise with null so callers can distinguish create-then-close (recordId) from
    // cancel-without-save (null) with a single truthy check.
    this.close(null);
  }
}
