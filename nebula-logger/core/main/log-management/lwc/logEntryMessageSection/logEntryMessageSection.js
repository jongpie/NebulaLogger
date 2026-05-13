/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';

export default class LogEntryMessageSection extends LightningElement {
  @api recordId;

  // Capability flags forwarded to the inner Message viewer. Computed once so the same object
  // identity is reused across renders (avoids unnecessary @api set churn on the inner LWC).
  messageViewerConfig = {
    showThemePicker: true,
    showLanguagePicker: true,
    showRememberPreference: true,
    defaultLanguage: 'plaintext'
  };

  stackTraceViewerConfig = {
    showThemePicker: true,
    showLanguagePicker: true,
    showRememberPreference: true,
    defaultLanguage: 'apex'
  };
}
