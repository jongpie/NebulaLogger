import { createElement } from 'lwc';
import LoggerHomeHeader from 'c/loggerHomeHeader';
import getEnvironmentDetails from '@salesforce/apex/LoggerHomeHeaderController.getEnvironmentDetails';

const mockLoggerVersionNumber = 'v4.10.4';
const mockOrganizationApiVersion = 'v57.0';
const mockEnvironmentDetails = {
    loggerVersionNumber: mockLoggerVersionNumber,
    organizationApiVersion: mockOrganizationApiVersion
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
        // The jsdom instance is shared across test cases in a single file so reset the DOM
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

        getEnvironmentDetails.emit(mockEnvironmentDetails);
        await Promise.resolve('Resolve getEnvironmentDetails()');
        const organizationApiVersionElement = element.shadowRoot.querySelector('[data-id="organization-api-version"]');
        expect(organizationApiVersionElement).toBeTruthy();
        expect(organizationApiVersionElement.innerHTML).toBe(`Organization API ${mockOrganizationApiVersion}`);
        const loggerVersionNumberElement = element.shadowRoot.querySelector('[data-id="logger-version-number"]');
        expect(loggerVersionNumberElement).toBeTruthy();
        expect(loggerVersionNumberElement.innerHTML).toBe(`${mockLoggerVersionNumber}`);
        const releaseNotesButton = element.shadowRoot.querySelector('[data-id="release-notes-button"]');
        expect(releaseNotesButton.label).toBe(`View ${mockLoggerVersionNumber} Release Notes`);
    });
});
