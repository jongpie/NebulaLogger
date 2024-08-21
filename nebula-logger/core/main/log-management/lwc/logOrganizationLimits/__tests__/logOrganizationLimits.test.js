import { createElement } from 'lwc';
import LogOrganizationLimits from 'c/logOrganizationLimits';
import { getRecord } from 'lightning/uiRecordApi';

const mockGetRecord = require('./data/getRecord.json');

describe('c-log-organization-limits', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('displays organization limits when JSON is valid', async () => {
    const element = createElement('c-log-organization-limits', {
      is: LogOrganizationLimits
    });
    document.body.appendChild(element);

    getRecord.emit(mockGetRecord);
    await Promise.resolve('resolves getRecord()');

    const layoutItems = element.shadowRoot.querySelectorAll('lightning-layout-item');
    expect(layoutItems.length).toBe(2);
    const mockOrganizationLimits = JSON.parse(mockGetRecord.fields.OrganizationLimits__c.value);
    const formElements = element.shadowRoot.querySelectorAll('.slds-form-element');
    expect(formElements.length).toBe(mockOrganizationLimits.length);
    mockOrganizationLimits.forEach(limit => {
      const matchingElement = element.shadowRoot.querySelector(`[data-id="${limit.Name}"]`);
      expect(matchingElement).toBeTruthy();
    });
  });

  it('displays message when JSON is null', async () => {
    const element = createElement('c-log-organization-limits', {
      is: LogOrganizationLimits
    });
    document.body.appendChild(element);
    const mockGetRecordWithoutLimitsJson = { ...mockGetRecord };
    mockGetRecordWithoutLimitsJson.fields.OrganizationLimits__c.value = null;

    getRecord.emit(mockGetRecordWithoutLimitsJson);
    await Promise.resolve('resolves getRecord()');

    const warningNotifyElements = element.shadowRoot.querySelectorAll('.slds-alert_warning');
    expect(warningNotifyElements.length).toBe(1);
    const warningNotifyHeader2Elements = element.shadowRoot.querySelectorAll('.slds-alert_warning h2');
    expect(warningNotifyHeader2Elements.length).toBe(1);
    expect(warningNotifyHeader2Elements[0].innerHTML).toBe('Could not parse Organization Limits JSON data, the current value is displayed below.');
    const layoutItems = element.shadowRoot.querySelectorAll('lightning-layout-item');
    expect(layoutItems.length).toBe(1);
    const staticFormElements = element.shadowRoot.querySelectorAll('.slds-form-element__static');
    expect(staticFormElements.length).toBe(1);
    expect(staticFormElements[0].innerHTML).toBe('');
  });

  it('displays message when JSON is invalid', async () => {
    const element = createElement('c-log-organization-limits', {
      is: LogOrganizationLimits
    });
    document.body.appendChild(element);
    const mockGetRecordWithInvalidLimitsJson = { ...mockGetRecord };
    mockGetRecordWithInvalidLimitsJson.fields.OrganizationLimits__c.value = '༼ つ ◕_◕ ༽つ This is not valid JSON!!!';

    getRecord.emit(mockGetRecordWithInvalidLimitsJson);
    await Promise.resolve('resolves getRecord()');

    const warningNotifyElements = element.shadowRoot.querySelectorAll('.slds-alert_warning');
    expect(warningNotifyElements.length).toBe(1);
    const warningNotifyHeader2Elements = element.shadowRoot.querySelectorAll('.slds-alert_warning h2');
    expect(warningNotifyHeader2Elements.length).toBe(1);
    expect(warningNotifyHeader2Elements[0].innerHTML).toBe('Could not parse Organization Limits JSON data, the current value is displayed below.');
    const layoutItems = element.shadowRoot.querySelectorAll('lightning-layout-item');
    expect(layoutItems.length).toBe(1);
    const staticFormElements = element.shadowRoot.querySelectorAll('.slds-form-element__static');
    expect(staticFormElements.length).toBe(1);
    expect(staticFormElements[0].innerHTML).toBe(mockGetRecordWithInvalidLimitsJson.fields.OrganizationLimits__c.value);
  });
});
