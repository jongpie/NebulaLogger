import { createElement } from 'lwc';
import LoggerHomeHeader from 'c/loggerHomeHeader';
import getLoggerVersionNumber from '@salesforce/apex/LoggerHomeHeaderController.getLoggerVersionNumber';
import getOrganizationApiVersion from '@salesforce/apex/LoggerHomeHeaderController.getOrganizationApiVersion';

const mockLoggerVersionNumber = 'v4.10.4';
const mockOrganizationApiVersion = 'v57.0';

jest.mock(
    '@salesforce/apex/LoggerHomeHeaderController.getLoggerVersionNumber',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerHomeHeaderController.getOrganizationApiVersion',
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

    it('displays logger version number and organization api number', async () => {
        const element = createElement('c-logger-home-header', {
            is: LoggerHomeHeader
        });

        document.body.appendChild(element);

        getLoggerVersionNumber.emit(mockLoggerVersionNumber);
        getOrganizationApiVersion.emit(mockOrganizationApiVersion);
        await Promise.resolve('Resolve getLoggerVersionNumber()');
        await Promise.resolve('Resolve getOrganizationApiVersion()');
        const loggerVersionNumberElement = element.shadowRoot.querySelector('[data-id="logger-version-number"]');
        expect(loggerVersionNumberElement).toBeTruthy();
        expect(loggerVersionNumberElement.innerHTML).toBe(`${mockLoggerVersionNumber}`);
        const organizationApiVersionElement = element.shadowRoot.querySelector('[data-id="organization-api-version"]');
        expect(organizationApiVersionElement).toBeTruthy();
        expect(organizationApiVersionElement.innerHTML).toBe(`Organization API ${mockOrganizationApiVersion}`);
    });
});
