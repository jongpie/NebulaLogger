/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';

export default class LogEntryExceptionSection extends LightningElement {
  @api recordId;

  exceptionMessageConfig = {
    showThemePicker: true,
    showLanguagePicker: true,
    showRememberPreference: true,
    defaultLanguage: 'plaintext'
  };

  exceptionStackTraceConfig = {
    showThemePicker: true,
    showLanguagePicker: true,
    showRememberPreference: true,
    defaultLanguage: 'apex'
  };
}
