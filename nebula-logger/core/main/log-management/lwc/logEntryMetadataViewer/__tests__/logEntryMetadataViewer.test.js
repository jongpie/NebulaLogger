import { createElement } from 'lwc';
import LogEntryMetadataViewer from 'c/logEntryMetadataViewer';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMetadata from '@salesforce/apex/LogEntryMetadataViewerController.getMetadata';

const mockLogEntryMetadata = require('./data/getRecord.json');
const mockLogEntryRecord = require('./data/getRecord.json');

jest.mock(
    'lightning/platformResourceLoader',
    () => {
        return {
            loadScript() {
                return new Promise((resolve, _) => {
                    global.Prism = require('../../../staticresources/LoggerResources/prism.js');
                    resolve();
                });
            },
            loadStyle() {
                return new Promise((resolve, _) => {
                    // No-op for now
                    resolve();
                });
            }
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LogEntryMetadataViewerController.getMetadata',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

describe('c-log-entry-metadata-viewer', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('displays metadata for Apex origin class', async () => {
        const element = createElement('c-log-entry-metadata-viewer', {
            is: LogEntryMetadataViewer
        });
        element.recordId = 'some_id_value';

        document.body.appendChild(element);
        getMetadata.mockResolvedValue(mockLogEntryMetadata);
        getRecord.emit(mockLogEntryRecord);

        await Promise.resolve('resolve getMetadata Apex controller method');
        await Promise.resolve('resolve getRecord UI function');
        const originDetailsSection = element.shadowRoot.querySelector('c-logger-page-section[data-id="origin-details"]');
        expect(originDetailsSection).toBeTruthy();
        const messageField = element.shadowRoot.querySelector('lightning-output-field[data-id="Message__c"]');
        expect(messageField).toBeTruthy();
        const messageMaskedField = element.shadowRoot.querySelector('lightning-output-field[data-id="MessageMasked__c"]');
        if (mockLogEntryRecord.MessageMasked__c) {
            expect(messageMaskedField).toBeTruthy();
        } else {
            expect(messageMaskedField).toBeFalsy();
        }
        const messageTruncatedField = element.shadowRoot.querySelector('lightning-output-field[data-id="MessageTruncated__c"]');
        if (mockLogEntryRecord.MessageTruncated__c) {
            expect(messageTruncatedField).toBeTruthy();
        } else {
            expect(messageTruncatedField).toBeFalsy();
        }
        const stackTraceField = element.shadowRoot.querySelector('lightning-output-field[data-id="StackTrace__c"]');
        expect(stackTraceField).toBeTruthy();
        const originCodeViewer = element.shadowRoot.querySelector('c-logger-code-viewer[data-id="originApexCodeSnippet"]');
        expect(originCodeViewer).toBeTruthy();
        const expectedCodeSnippet = JSON.parse(mockLogEntryRecord.fields.OriginSourceSnippet__c.value);
        expect(originCodeViewer.code).toBe(expectedCodeSnippet.code);
    });

    it('displays metadata for Apex exception class', async () => {
        const element = createElement('c-log-entry-metadata-viewer', {
            is: LogEntryMetadataViewer
        });
        element.recordId = 'some_id_value';

        document.body.appendChild(element);
        getMetadata.mockResolvedValue(mockLogEntryMetadata);
        getRecord.emit(mockLogEntryRecord);

        await Promise.resolve('resolve getMetadata Apex controller method');
        await Promise.resolve('resolve getRecord UI function');
        const originDetailsSection = element.shadowRoot.querySelector('c-logger-page-section[data-id="origin-details"]');
        expect(originDetailsSection).toBeTruthy();
        const exceptionTypeField = element.shadowRoot.querySelector('lightning-output-field[data-id="ExceptionType__c"]');
        expect(exceptionTypeField).toBeTruthy();
        const exceptionMessageField = element.shadowRoot.querySelector('lightning-output-field[data-id="ExceptionMessage__c"]');
        expect(exceptionMessageField).toBeTruthy();
        const exceptionStackTraceField = element.shadowRoot.querySelector('lightning-output-field[data-id="ExceptionStackTrace__c"]');
        expect(exceptionStackTraceField).toBeTruthy();
        const exceptionCodeViewer = element.shadowRoot.querySelector('c-logger-code-viewer[data-id="exceptionApexCodeSnippet"]');
        expect(exceptionCodeViewer).toBeTruthy();
        const expectedCodeSnippet = JSON.parse(mockLogEntryRecord.fields.ExceptionSourceSnippet__c.value);
        expect(exceptionCodeViewer.code).toBe(expectedCodeSnippet.code);
    });

    test.todo('displays full origin Apex class in modal when "View Apex Class" button is clicked');
    test.todo('displays full exception Apex class in modal when "View Apex Class" button is clicked');
});
