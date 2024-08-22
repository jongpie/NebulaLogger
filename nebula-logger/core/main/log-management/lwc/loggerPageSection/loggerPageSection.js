/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';

export default class LoggerPageSection extends LightningElement {
  _showContent = true;

  get sectionToggleClass() {
    const classNames = ['slds-section__content'];
    classNames.push(this._showContent ? 'slds-show' : 'slds-hide');
    return classNames.join(' ');
  }

  get sectionToggleIcon() {
    return this._showContent ? 'utility:chevrondown' : 'utility:chevronright';
  }

  toggleSection() {
    this._showContent = !this._showContent;
  }
}
