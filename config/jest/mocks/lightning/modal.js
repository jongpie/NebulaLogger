// Jest mock for `lightning/modal`. On-platform, LightningModal is a base class that renders the
// component at the document root and exposes:
//   - a static `open(props)` -> Promise<result> API for callers
//   - an instance `.close(result)` method that resolves the open() promise
//
// The mock swaps both surfaces for jest-testable stand-ins. `.open` is a `jest.fn` that returns a
// resolved promise (Promise-of-null by default; individual tests can override with .mockResolvedValue).
// The base class exposes a jest-mocked `.close` method so subclass unit tests can assert what value
// was passed. The class deliberately does NOT extend LightningElement - callers that want to render
// the modal LWC in jest and observe its shadow DOM would need on-platform LightningModal semantics
// (portal + shadow root at document body) that can't be emulated in jsdom anyway.

class LightningModal {
  close = jest.fn();
}
LightningModal.open = jest.fn().mockResolvedValue(null);

export default LightningModal;
