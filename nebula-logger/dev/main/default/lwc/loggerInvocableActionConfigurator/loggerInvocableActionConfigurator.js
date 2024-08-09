import { LightningElement, api } from 'lwc';

// Docs: https://developer.salesforce.com/docs/platform/lwc/guide/use-flow-custom-property-editor-interface.html
// Examples: https://developer.salesforce.com/docs/platform/lwc/guide/use-flow-custom-property-editor-action-example.html
export default class LoggerInvocableActionConfigurator extends LightningElement {
    _inputVariables = [];

    @api
    get inputVariables() {
        return this._inputVariables;
    }

    // Set a field with the data that was stored from the flow.
    set inputVariables(variables) {
        console.log('>>> variables', variables, JSON.stringify(variables));
        this._inputVariables = variables || [];
    }

    _elementInfo = {};
    originFlowActionName;

    // _builderContext;
    // @api
    // get builderContext() {
    //     return this._builderContext;
    // }

    // set builderContext(value) {
    //     this._builderContext = value;
    //     console.log('>>> builderContext', this.builderContext, JSON.stringify(this.builderContext));
    // }

    @api
    get elementInfo() {
        return this._elementInfo;
    }

    // Set a local variable with the data that was stored from flow.
    set elementInfo(info) {
        console.log('>>> info', info, JSON.stringify(info));
        this._elementInfo = info || {};

        this.originFlowActionName = this._elementInfo.apiName;
    }

    _genericTypeMappings;
    @api
    get genericTypeMappings() {
        return this._genericTypeMappings;
    }

    set genericTypeMappings(value) {
        this._genericTypeMappings = value;
        console.log('>>> genericTypeMappings', this.genericTypeMappings, JSON.stringify(this.genericTypeMappings));
    }

    @api
    validate() {
        const sliderCmp = this.template.querySelector('lightning-slider');
        // const validity = [];
        // if (this.volume < 0 || this.volume > 100) {
        //     sliderCmp.setCustomValidity('The slider range is between 0 and     100.');
        //     validity.push({
        //         key: 'Slider Range',
        //         errorString: 'The slider range is between 0 and 100.',
        //     });
        // } else {
        //     sliderCmp.setCustomValidity('');
        // }
        // sliderCmp.reportValidity();
        return validity;
    }

    get loggingLevels() {
        return [
            { label: '⛔ ERROR', value: 'ERROR' },
            { label: '⚠️ WARN', value: 'WARN' },
            { label: 'ℹ️ INFO', value: 'INFO' },
            { label: '🐞 DEBUG', value: 'DEBUG' },
            { label: '👍 FINE', value: 'FINE' },
            { label: '👌 FINER', value: 'FINER' },
            { label: '🌟 FINEST', value: 'FINEST' }
        ];
    }

    get loggingLevelName() {
        return this._getParameterValue('loggingLevelName');
    }

    get saveMethods() {
        return [
            { label: 'EVENT_BUS', value: 'EVENT_BUS' },
            { label: 'QUEUEABLE', value: 'QUEUEABLE' },
            { label: 'REST', value: 'REST' },
            { label: 'SYNCHRONOUS_DML', value: 'SYNCHRONOUS_DML' }
        ];
    }

    get message() {
        // const param = this.inputVariables.find(({ name }) => name === 'message');
        // return param && param.value;
        return this._getParameterValue('message');
    }

    get saveMethodName() {
        return this._getParameterValue('saveMethodName');
    }

    get tagsString() {
        return this._getParameterValue('tagsString');
    }

    _getParameterValue(parameter) {
        return this.inputVariables.find(({ name }) => name === parameter)?.value;
    }
}
