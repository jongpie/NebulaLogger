import { LightningElement, api } from 'lwc';

const VARIANT_TO_ICON = {
  base: 'utility:info',
  warning: 'utility:warning',
  error: 'utility:error',
  offline: 'utility:offline'
};

const VARIANT_TO_THEME = {
  base: '',
  warning: 'slds-theme_warning',
  error: 'slds-theme_error',
  offline: 'slds-theme_offline'
};

export default class LoggerNotificationAlert extends LightningElement {
  @api title;
  @api message;
  @api iconName;
  @api variant = 'warning';

  get resolvedVariant() {
    return VARIANT_TO_THEME[this.variant] !== undefined ? this.variant : 'warning';
  }

  get containerClass() {
    const theme = VARIANT_TO_THEME[this.resolvedVariant];
    return theme ? `slds-notify slds-notify_alert ${theme}` : 'slds-notify slds-notify_alert';
  }

  get resolvedIconName() {
    return this.iconName || VARIANT_TO_ICON[this.resolvedVariant];
  }

  get iconVariant() {
    return this.resolvedVariant === 'base' ? '' : 'inverse';
  }

  get assistiveText() {
    return this.title || `${this.resolvedVariant} alert`;
  }
}
