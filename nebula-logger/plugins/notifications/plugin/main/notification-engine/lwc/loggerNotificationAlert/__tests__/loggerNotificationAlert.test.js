import { createElement } from 'lwc';
import LoggerNotificationAlert from 'c/loggerNotificationAlert';

describe('c-logger-notification-alert', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function build(props = {}) {
    const element = createElement('c-logger-notification-alert', { is: LoggerNotificationAlert });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
  }

  it('renders the warning variant by default', () => {
    const element = build({ message: 'Heads up' });
    return Promise.resolve().then(() => {
      const alert = element.shadowRoot.querySelector('div.slds-notify');
      expect(alert).not.toBeNull();
      expect(alert.classList.contains('slds-theme_warning')).toBe(true);
      expect(alert.getAttribute('role')).toBe('alert');
    });
  });

  it('applies the requested variant theme class', () => {
    const element = build({ message: 'Uh oh', variant: 'error' });
    return Promise.resolve().then(() => {
      const alert = element.shadowRoot.querySelector('div.slds-notify');
      expect(alert.classList.contains('slds-theme_error')).toBe(true);
      expect(alert.classList.contains('slds-theme_warning')).toBe(false);
    });
  });

  it('falls back to warning when the variant is unknown', () => {
    const element = build({ message: 'Anything', variant: 'nonsense' });
    return Promise.resolve().then(() => {
      const alert = element.shadowRoot.querySelector('div.slds-notify');
      expect(alert.classList.contains('slds-theme_warning')).toBe(true);
    });
  });

  it('renders the title when provided', () => {
    const element = build({ title: 'Warning', message: 'Body' });
    return Promise.resolve().then(() => {
      const strong = element.shadowRoot.querySelector('h2 strong');
      expect(strong).not.toBeNull();
      expect(strong.textContent).toBe('Warning');
    });
  });

  it('omits the title element when no title is set', () => {
    const element = build({ message: 'Body only' });
    return Promise.resolve().then(() => {
      expect(element.shadowRoot.querySelector('h2 strong')).toBeNull();
    });
  });

  it('renders the message as rich text', () => {
    const element = build({ message: '<p>Rich <strong>body</strong></p>' });
    return Promise.resolve().then(() => {
      const formatted = element.shadowRoot.querySelector('lightning-formatted-rich-text');
      expect(formatted).not.toBeNull();
      expect(formatted.value).toBe('<p>Rich <strong>body</strong></p>');
    });
  });

  it('picks a variant-appropriate icon by default', () => {
    const element = build({ message: 'Body', variant: 'error' });
    return Promise.resolve().then(() => {
      const icon = element.shadowRoot.querySelector('lightning-icon');
      expect(icon.iconName).toBe('utility:error');
    });
  });

  it('honors an explicit iconName override', () => {
    const element = build({ message: 'Body', variant: 'warning', iconName: 'utility:notification' });
    return Promise.resolve().then(() => {
      const icon = element.shadowRoot.querySelector('lightning-icon');
      expect(icon.iconName).toBe('utility:notification');
    });
  });

  it('uses inverse icon variant for themed alerts and no variant for base', () => {
    const themed = build({ message: 'Body', variant: 'warning' });
    return Promise.resolve()
      .then(() => {
        expect(themed.shadowRoot.querySelector('lightning-icon').variant).toBe('inverse');
        document.body.removeChild(themed);
        const base = build({ message: 'Body', variant: 'base' });
        return Promise.resolve().then(() => base);
      })
      .then(base => {
        expect(base.shadowRoot.querySelector('lightning-icon').variant).toBe('');
      });
  });
});
