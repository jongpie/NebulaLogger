/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';

const TOOLBAR_BASE = {
  showThemePicker: true,
  showLanguagePicker: true,
  showRememberPreference: true
};

export default class LogEntryRestSection extends LightningElement {
  @api recordId;

  requestHeadersConfig = { ...TOOLBAR_BASE, defaultLanguage: 'http' };
  responseHeadersConfig = { ...TOOLBAR_BASE, defaultLanguage: 'http' };

  requestParametersConfig = { ...TOOLBAR_BASE, defaultLanguage: 'plaintext' };

  requestBodyConfig = {
    ...TOOLBAR_BASE,
    contentTypeHeadersFieldApiName: 'RestRequestHeaders__c',
    defaultLanguage: 'plaintext'
  };

  responseBodyConfig = {
    ...TOOLBAR_BASE,
    contentTypeHeadersFieldApiName: 'RestResponseHeaders__c',
    defaultLanguage: 'plaintext'
  };
}
