// Standard imports
import { LightningElement, api, track } from 'lwc';
// import { NavigationMixin } from 'lightning/navigation';

import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import resources from '@salesforce/resourceUrl/LoggerResources';

// Delegate imports
import { getDelegateController as getExceptionApexViewController } from './exceptionApexMetadataViewer/controller';
import { getDelegateController as getHttpCalloutSectionController } from './httpCalloutSection/controller';
import { getDelegateController as getLoggingApexViewController } from './loggingApexMetadataViewer/controller';
import { getDelegateController as getFlowViewController } from './flowMetadataViewer/controller';
import { getDelegateController as getRelatedRecordsController } from './relatedRecordsViewer/controller';
import { getDelegateController as getInformationSectionController } from './informationSection/controller';

// Template imports
// import template_messageViewer from './template_messageViewer.html';
// import template_apexMetadataViewer from './template_apexMetadataViewer.html';
import defaultTemplate from './defaultTemplate.html';
// import template_flowMetadataViewer from './template_flowMetadataViewer.html';
// import template_relatedRecordsViewer from './template_relatedRecordsViewer.html';
// import template_relatedTagsViewer from './template_relatedTagsViewer.html';

// Apex imports
import getLogEntry from '@salesforce/apex/LogEntrySectionController.getLogEntry';

export default class LogEntrySection extends LightningElement {
    // export default class LogEntrySection extends NavigationMixin(LightningElement) {
    @api
    recordId;
    @api
    section;

    logEntry;
    @track
    logEntryContext;

    displayUnmaskedData = false;
    isLoading = false;
    columns = [{ fieldName: 'Id' }];
    fields = [{ fieldName: 'Id' }];
    records = [{ Id: '123' }];
    selectedRecord = { sobjectType: null, recordId: null };
    title = 'Related Records';

    render() {
        return this._getTemplate();
    }

    // Apex Metadata Viewer
    // get apexClassUrl() {
    //     return 'https://customization-app-669.scratch.lightning.force.com/lightning/setup/ApexClasses/page?address=%2F'+ this.logEntry?._____ApexClassId;
    // }

    // handleOpenApexClass() {
    //     window.open(this.apexClassUrl, '_blank');
    //     // const openInCurrentWindow = false;
    //     // const pageReference = {
    //     //     type: 'standard__webPage',
    //     //     attributes: {
    //     //         url: this.apexClassUrl
    //     //     }
    //     // };
    //     // this[NavigationMixin.Navigate](pageReference, openInCurrentWindow);
    // }

    // Flow Metadata Viewer
    // get flowBuilderIframeStyle() {
    //     return 'min-height: calc(100% - 300px); width: 100%; overflow-y:scroll';
    // }

    // get flowBuilderIframeUrl() {
    //     return 'https://customization-app-669.scratch.lightning.force.com/builder_platform_interaction/flowBuilder.app?flowId=' + this.logEntry?._____FlowId;
    // }

    // handleOpenFlowBuilder() {
    //     window.open(this.flowBuilderIframeUrl, '_blank');
    //     // const openInCurrentWindow = false;
    //     // const pageReference = {
    //     //     type: 'standard__webPage',
    //     //     attributes: {
    //     //         url: this.flowBuilderIframeUrl
    //     //     }
    //     // };
    //     // this[NavigationMixin.Navigate](pageReference, openInCurrentWindow);
    // }

    // Common
    connectedCallback() {
        // this.logEntry = {'OriginType__c': 'Apex', '_____ApexClassId': '01p8I000003luM2', '_____FlowId' : '3018I000000M7fEQAS'};
        // // this.logEntry = {'OriginType__c': 'Flow', '_____FlowId' : '3018I000000M7fEQAS'};
        // console.log('loaded mock logEntry', this.logEntry);
        Promise.all([loadScript(this, resources + '/prism.js'), loadStyle(this, resources + '/prism.css')]).then(result => {
            console.log('finished loading static resources', result);
            console.log('Prism: ', Prism);
        });

        if (!this.recordId) {
            return;
        }

        console.log('running getLogEntry function', this.recordId);
        getLogEntry({ logEntryId: this.recordId }).then(result => {
            this.logEntry = result.logEntry;
            this.logEntryContext = result;
            console.log('>>> log entry context', JSON.parse(JSON.stringify(this.logEntryContext)));
            console.log('>>> log entry record', JSON.parse(JSON.stringify(this.logEntry)));
            // this.template.querySelector('.code-editor').innerHTML = `<pre><code class="language-apex">${this.logEntryContext.apexClass.Body}</code></pre>`;
            // this.template.querySelector('pre').innerHTML = Prism.highlight(`console.log('hello, world);`, Prism.languages.javascript, 'javascript');
        });

        // TEMP
        const codeViewer = this.template.querySelector('.code-editor');
        console.log({ codeViewer });
        if (codeViewer) {
            codeViewer.innerHTML = '<pre class="line-numbers language-markup"><code>&lt;img src="example.png"&gt;</code></pre>';
        }
    }

    // @wire(getLogEntry, { logEntryId: '$recordId' })
    // wiredGetLogEntry(result) {
    //     console.log('running wiredGetLogEntry function', result);
    //     if (result.data) {
    //       this.logEntry = result.data;
    //     }
    // }

    _getTemplate() {
        console.log('running this._getTemplate() for this.section == ' + this.section);
        let selectedTemplate;
        // throw new Error('this.section: ' + this.section);
        switch (this.section) {
            // case 'Message Viewer':
            //     selectedTemplate = template_messageViewer;
            //     break;
            case 'Exception Apex Metadata Viewer':
                selectedTemplate = getExceptionApexViewController(this).getTemplate();
                break;
            case 'Flow Metadata Viewer':
                selectedTemplate = getFlowViewController(this).getTemplate();
                break;
            case 'HTTP Callout Section':
                selectedTemplate = getHttpCalloutSectionController(this).getTemplate();
                break;
            case 'Information Section':
                selectedTemplate = getInformationSectionController(this).getTemplate();
                break;
            case 'Logging Apex Metadata Viewer':
                selectedTemplate = getLoggingApexViewController(this).getTemplate();
                break;
            case 'Related Records Viewer':
                selectedTemplate = getRelatedRecordsController(this).getTemplate();
                break;
            default:
                selectedTemplate = defaultTemplate;
                console.log('Could not determine template 😭');
        }
        console.log('selectedTemplate, before merged properties: ' + selectedTemplate);
        // selectedTemplate.logEntryContext = this.logEntryContext;
        // Object.keys(selectedTemplate).forEach(delegateControllerProperty => {
        //     this[delegateControllerProperty] = selectedTemplate[delegateControllerProperty];
        // });
        // console.log('selectedTemplate, with merged properties: ' + selectedTemplate);
        return selectedTemplate;
    }

    get unmaskedDataButtonVariant() {
        return this.displayUnmaskedData ? 'destructive' : 'success';
    }

    handleDataMaskToggle(event) {
        console.log('button clicked', event);
        this.displayUnmaskedData = !this.displayUnmaskedData;
    }

    handleRecordSearch(event) {
        console.log('search entered', event);
    }
}
