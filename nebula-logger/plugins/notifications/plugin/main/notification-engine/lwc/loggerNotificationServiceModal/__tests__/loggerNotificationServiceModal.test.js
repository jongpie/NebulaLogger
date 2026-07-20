import LoggerNotificationServiceModal from 'c/loggerNotificationServiceModal';

// `lightning/modal` is globally mocked at config/jest/mocks/lightning/modal.js. The base class
// exposes a jest-mocked `.close` method so we can assert what value the modal resolves with.
// Extending an actual LightningElement here isn't necessary: this LWC's only meaningful behavior
// is that its two event handlers invoke `this.close(...)` with the right argument. Unit-test that
// directly - no shadow DOM required.

// LWC's @api decorator installs a setter that expects the class to be mounted (has an associated
// VM). `new LoggerNotificationServiceModal()` skips the mount step and the @api setter's `assertIsVM`
// throws. `Object.create(prototype)` sidesteps the constructor entirely - we just need an instance
// with the LWC method surface for these direct-invocation handler tests.
function makeInstance() {
  const instance = Object.create(LoggerNotificationServiceModal.prototype);
  instance.close = jest.fn();
  return instance;
}

describe('c-logger-notification-service-modal', () => {
  it('resolves the modal with the new service Id when handleServiceCreated fires', () => {
    const instance = makeInstance();
    instance.handleServiceCreated({ detail: { recordId: 'a08000000000001AAA' } });
    expect(instance.close).toHaveBeenCalledWith('a08000000000001AAA');
  });

  it('resolves the modal with null when handleServiceFormClose fires (admin cancelled without saving)', () => {
    const instance = makeInstance();
    instance.handleServiceFormClose();
    expect(instance.close).toHaveBeenCalledWith(null);
  });

  // eslint-disable-next-line quotes
  it("resolves with null when the create event carries no recordId (defensive - shouldn't happen but guarded)", () => {
    const instance = makeInstance();
    instance.handleServiceCreated({ detail: {} });
    expect(instance.close).toHaveBeenCalledWith(null);
  });
});
