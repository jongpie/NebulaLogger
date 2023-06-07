import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import resources from '@salesforce/resourceUrl/LoggerResources';
// import Prism from '../prism';
import template from './template.html';

const LoggingApexMetadataViewer = class {
    logEntryContext;
    mockJavaScript;

    setupParentController(parentController) {
        // Promise.all([loadScript(this, resources + '/prism.js'), loadStyle(this, resources + '/prism.css')]).then(result => {
        // console.log('finished loading static resources', result);
        // console.log('Prism: ', Prism);

        console.log('zzz setting up parent controller', parentController);
        console.log('parent controller context', parentController.logEntryContext);
        this.logEntry = parentController.logEntry;
        console.log('LoggingApexMetadataViewer now has this.logEntry', this.logEntry);
        this.logEntryContext = parentController.logEntryContext;
        console.log('LoggingApexMetadataViewer now has this.logEntryContext', this.logEntryContext);

        // parentController.exceptionApexClass = this.exceptionApexClass;

        parentController.apexClassUrl = this.apexClassUrl;
        // parentController.mockJavaScript = `console.log('hello, world!');`;//this.mockJavaScript;
        parentController.handleOpenApexClass = this.handleOpenApexClass;
        console.log('parent controller setup', parentController);

        console.log('setting up Prism, i guess');
        // this.template.shadowRoot.querySelector('pre').innerHTML = 'zzzzzzzz';

        // const codeViewer = this.getTemplate().querySelector('.code-editor');
        // console.log('>>> codeViewer', codeViewer);
        // });
    }

    getTemplate() {
        console.log({ template });
        return template;
    }

    get apexClassUrl() {
        const url = window.location + '/lightning/setup/ApexClasses/page?address=%2F' + this.logEntry?.ApexClassId__c;
        console.log('>>> url', url);
        return url;
    }

    // get mockJavaScript() {
    //     return `console.log('hello, world!');`
    //     // return ```
    //     // .example {
    //     //     font-family: Georgia, Times, serif;
    //     //     color: #555;
    //     //     text-align: center;
    //     // }
    //     // ```;
    // }

    handleOpenApexClass() {
        console.log('running handleOpenApexClass()', this.apexClassUrl);
        window.open(this.apexClassUrl, '_blank');
    }
};

export function getDelegateController(parentController) {
    // return new LogEntryBuilder(loggingLevel, settingPromise);
    console.log('running LoggingApexMetadataViewer.getDelegateController()', parentController);
    const controller = new LoggingApexMetadataViewer();
    controller.setupParentController(parentController);
    return controller;
}
