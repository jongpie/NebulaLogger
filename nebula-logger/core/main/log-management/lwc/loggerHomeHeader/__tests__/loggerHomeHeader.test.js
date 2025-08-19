import { createElement } from '@lwc/engine-dom';
import LoggerHomeHeader from 'c/loggerHomeHeader';
import getEnvironmentDetails from '@salesforce/apex/LoggerHomeHeaderController.getEnvironmentDetails';

const MOCK_ENVIRONMENT_DETAILS = {
  loggerNamespacePrefix: '(none)',
  loggerEnabledPluginsCount: 3,
  loggerEnabledPlugins: 'A Plugin, My Other Plugin, Some Other Plugin',
  loggerVersionNumber: 'v4.10.4',
  organizationApiVersion: 'v57.0',
  organizationCreatedByUsername: 'some.username@test.com',
  organizationFormattedCreatedDate: '5/22/2023, 2:09 PM',
  organizationId: '00D8G000000E1S9UAK',
  organizationInstanceLocation: 'NA',
  organizationInstanceName: 'CS123',
  organizationInstanceProducts: 'Salesforce Services',
  organizationMaintenanceWindow: 'Saturdays 07:00 PM - 11:00 PM PST',
  organizationName: 'My Scratch Org',
  organizationReleaseNumber: '242.19.17',
  organizationReleaseVersion: "Spring '23 Patch 19.17",
  organizationType: 'Enterprise Edition'
};

jest.mock(
  '@salesforce/apex/LoggerHomeHeaderController.getEnvironmentDetails',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

describe('c-logger-home-header', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('renders home header component', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });

    document.body.appendChild(element);

    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');
    const headerTitleElement = element.shadowRoot.querySelector('[data-id="header-title"]');
    expect(headerTitleElement).toBeTruthy();
    expect(headerTitleElement.innerHTML).toBe(`Nebula Logger ${MOCK_ENVIRONMENT_DETAILS.loggerVersionNumber}`);
    const pluginsSummaryElement = element.shadowRoot.querySelector('[data-id="enabled-plugins-summary"]');
    expect(pluginsSummaryElement).toBeTruthy();
    expect(pluginsSummaryElement.innerHTML).toBe(MOCK_ENVIRONMENT_DETAILS.loggerEnabledPluginsCount + ' Enabled Plugins');
    const environmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    expect(environmentDetailsButton.label).toBe('View Environment Details');
    const releaseNotesButton = element.shadowRoot.querySelector('lightning-button[data-id="release-notes-button"]');
    expect(releaseNotesButton.label).toBe(`View ${MOCK_ENVIRONMENT_DETAILS.loggerVersionNumber} Release Notes`);
  });

  it('displays environment details modal when "View Environment Details" button is clicked', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');

    const viewEnvironmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    viewEnvironmentDetailsButton.click();
    await Promise.resolve('Render modal');

    const modalTitleElement = element.shadowRoot.querySelector('[data-id="environment-details-modal-title"]');
    expect(modalTitleElement.innerHTML).toBe('Environment Details');
    const dataIdToEnvironmentProperty = {
      'environment-loggerEnabledPlugins': MOCK_ENVIRONMENT_DETAILS.loggerEnabledPlugins,
      'environment-loggerVersionNumber': MOCK_ENVIRONMENT_DETAILS.loggerVersionNumber,
      'environment-loggerNamespacePrefix': MOCK_ENVIRONMENT_DETAILS.loggerNamespacePrefix,
      'environment-organizationId': MOCK_ENVIRONMENT_DETAILS.organizationId,
      'environment-organizationName': MOCK_ENVIRONMENT_DETAILS.organizationName,
      'environment-organizationType': MOCK_ENVIRONMENT_DETAILS.organizationType,
      'environment-organizationInstanceName': MOCK_ENVIRONMENT_DETAILS.organizationInstanceName,
      'environment-organizationInstanceLocation': MOCK_ENVIRONMENT_DETAILS.organizationInstanceLocation,
      'environment-organizationInstanceProducts': MOCK_ENVIRONMENT_DETAILS.organizationInstanceProducts,
      'environment-organizationApiVersion': MOCK_ENVIRONMENT_DETAILS.organizationApiVersion,
      'environment-organizationReleaseNumber': MOCK_ENVIRONMENT_DETAILS.organizationReleaseNumber,
      'environment-organizationReleaseVersion': MOCK_ENVIRONMENT_DETAILS.organizationReleaseVersion,
      'environment-organizationMaintenanceWindow': MOCK_ENVIRONMENT_DETAILS.organizationMaintenanceWindow,
      'environment-organizationCreatedByUsername': MOCK_ENVIRONMENT_DETAILS.organizationCreatedByUsername,
      'environment-organizationFormattedCreatedDate': MOCK_ENVIRONMENT_DETAILS.organizationFormattedCreatedDate
    };
    Object.keys(dataIdToEnvironmentProperty).forEach(dataId => {
      const textElement = element.shadowRoot.querySelector(`[data-id="${dataId}"]`);
      expect(textElement.value).toBe(dataIdToEnvironmentProperty[dataId]);
    });
  });

  it("closes environment details modal when 'Escape' key is pressed", async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');
    const viewEnvironmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    expect(viewEnvironmentDetailsButton).toBeTruthy();
    viewEnvironmentDetailsButton.click();
    await Promise.resolve('Render modal');
    let modalElement = element.shadowRoot.querySelector('.slds-modal');
    modalElement.focus();

    const escapeKeyboardShortcutEvent = new KeyboardEvent('keydown', { code: 'Escape' });
    modalElement.dispatchEvent(escapeKeyboardShortcutEvent);
    await Promise.resolve('Resolve keyboard event');

    modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeFalsy();
  });

  it('hides the "View Release Notes" button when version number is not available', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit({ ...MOCK_ENVIRONMENT_DETAILS, ...{ loggerVersionNumber: null } });
    await Promise.resolve('Resolve getEnvironmentDetails()');
    const navigationHandler = jest.fn();
    element.addEventListener('navigate', navigationHandler);

    const button = element.shadowRoot.querySelector('lightning-button[data-id="release-notes-button"]');
    expect(button).toBeFalsy();
  });

  it('displays github release notes url when "View Release Notes" button is clicked', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');
    const navigationHandler = jest.fn();
    element.addEventListener('navigate', navigationHandler);

    const button = element.shadowRoot.querySelector('lightning-button[data-id="release-notes-button"]');
    const navigateEvt = new CustomEvent('click');
    button.dispatchEvent(navigateEvt);

    expect(navigationHandler).toHaveBeenCalledTimes(1);
    const navigateArgument = navigationHandler.mock.calls[0][0].detail.pageReference;
    expect(navigateArgument).toBeTruthy();
    expect(navigateArgument.type).toBe('standard__webPage');
    expect(navigateArgument.attributes.url).toBe(`https://github.com/jongpie/NebulaLogger/releases/tag/${MOCK_ENVIRONMENT_DETAILS.loggerVersionNumber}`);
  });

  // New test cases to improve coverage
  it('handles title when loggerVersionNumber is undefined', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit({ ...MOCK_ENVIRONMENT_DETAILS, loggerVersionNumber: undefined });
    await Promise.resolve('Resolve getEnvironmentDetails()');

    const headerTitleElement = element.shadowRoot.querySelector('[data-id="header-title"]');
    expect(headerTitleElement.innerHTML).toBe('Nebula Logger');
  });

  it('handles enabledPluginsSummary when loggerEnabledPlugins is undefined', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit({ ...MOCK_ENVIRONMENT_DETAILS, loggerEnabledPlugins: undefined });
    await Promise.resolve('Resolve getEnvironmentDetails()');

    const pluginsSummaryElement = element.shadowRoot.querySelector('[data-id="enabled-plugins-summary"]');
    expect(pluginsSummaryElement).toBeFalsy();
  });

  it('handles enabledPluginsSummary when loggerEnabledPlugins is null', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit({ ...MOCK_ENVIRONMENT_DETAILS, loggerEnabledPlugins: null });
    await Promise.resolve('Resolve getEnvironmentDetails()');

    const pluginsSummaryElement = element.shadowRoot.querySelector('[data-id="enabled-plugins-summary"]');
    expect(pluginsSummaryElement).toBeFalsy();
  });

  it('handles enabledPluginsSummary when loggerEnabledPlugins is empty string', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit({ ...MOCK_ENVIRONMENT_DETAILS, loggerEnabledPlugins: '' });
    await Promise.resolve('Resolve getEnvironmentDetails()');

    const pluginsSummaryElement = element.shadowRoot.querySelector('[data-id="enabled-plugins-summary"]');
    expect(pluginsSummaryElement).toBeFalsy();
  });

  it('handles View Status Site button click', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');

    // Open modal first
    const viewEnvironmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    viewEnvironmentDetailsButton.click();
    await Promise.resolve('Render modal');

    const navigationHandler = jest.fn();
    element.addEventListener('navigate', navigationHandler);

    const viewStatusSiteButton = element.shadowRoot.querySelector('lightning-button[data-id="view-status-site-btn"]');
    viewStatusSiteButton.click();
    await Promise.resolve('Resolve navigation');

    expect(navigationHandler).toHaveBeenCalledTimes(1);
    const navigateArgument = navigationHandler.mock.calls[0][0].detail.pageReference;
    expect(navigateArgument).toBeTruthy();
    expect(navigateArgument.type).toBe('standard__webPage');
    expect(navigateArgument.attributes.url).toBe(`https://status.salesforce.com/instances/${MOCK_ENVIRONMENT_DETAILS.organizationInstanceName}`);
  });

  it('handles modal close button click', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');

    // Open modal first
    const viewEnvironmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    viewEnvironmentDetailsButton.click();
    await Promise.resolve('Render modal');

    // Verify modal is open
    let modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeTruthy();

    // Click close button
    const closeButton = element.shadowRoot.querySelector('lightning-button[data-id="close-btn"]');
    closeButton.click();
    await Promise.resolve('Resolve close button click');

    // Verify modal is closed
    modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeFalsy();
  });

  it('handles modal header close button click', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');

    // Open modal first
    const viewEnvironmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    viewEnvironmentDetailsButton.click();
    await Promise.resolve('Render modal');

    // Verify modal is open
    let modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeTruthy();

    // Click header close button
    const headerCloseButton = element.shadowRoot.querySelector('button.slds-modal__close');
    headerCloseButton.click();
    await Promise.resolve('Resolve header close button click');

    // Verify modal is closed
    modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeFalsy();
  });

  it('handles keydown events that are not Escape', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);
    getEnvironmentDetails.emit(MOCK_ENVIRONMENT_DETAILS);
    await Promise.resolve('Resolve getEnvironmentDetails()');

    // Open modal first
    const viewEnvironmentDetailsButton = element.shadowRoot.querySelector('lightning-button[data-id="environment-details-button"]');
    viewEnvironmentDetailsButton.click();
    await Promise.resolve('Render modal');

    // Verify modal is open
    let modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeTruthy();

    // Send non-Escape keydown event
    const enterKeyEvent = new KeyboardEvent('keydown', { code: 'Enter' });
    modalElement.dispatchEvent(enterKeyEvent);
    await Promise.resolve('Resolve non-escape keydown event');

    // Modal should still be open
    modalElement = element.shadowRoot.querySelector('.slds-modal');
    expect(modalElement).toBeTruthy();
  });

  it('handles wire service with no data gracefully', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);

    // Emit undefined data
    getEnvironmentDetails.emit(undefined);
    await Promise.resolve('Resolve getEnvironmentDetails()');

    // Component should handle undefined data gracefully
    const headerTitleElement = element.shadowRoot.querySelector('[data-id="header-title"]');
    expect(headerTitleElement.innerHTML).toBe('Nebula Logger');
  });

  it('handles wire service with empty data gracefully', async () => {
    const element = createElement('c-logger-home-header', {
      is: LoggerHomeHeader
    });
    document.body.appendChild(element);

    // Emit empty data
    getEnvironmentDetails.emit({});
    await Promise.resolve('Resolve getEnvironmentDetails()');

    // Component should handle empty data gracefully
    const headerTitleElement = element.shadowRoot.querySelector('[data-id="header-title"]');
    expect(headerTitleElement.innerHTML).toBe('Nebula Logger');
  });
});
