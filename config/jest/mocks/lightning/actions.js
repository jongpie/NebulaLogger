// Jest mock for `lightning/actions`. On-platform, `CloseActionScreenEvent` is a CustomEvent
// subclass (event type: `close`) that the Quick Action Screen Action container listens for to
// tear down its modal. jsdom doesn't ship the real class, so we substitute a lightweight
// CustomEvent subclass that keeps the same shape for tests that need to assert on the event's
// `type` and `constructor.name`.
export class CloseActionScreenEvent extends CustomEvent {
  constructor() {
    super('close');
  }
}
