import { LightningElement } from 'lwc';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';

export default class LogEntryArchives extends LightningElement {
    logEntryArchives;

    get title() {
        return 'Log Entry Archives';
    }

    async connectedCallback() {
        document.title = this.title;

        getLogEntryArchives().then(results => {
            this.logEntryArchives = JSON.parse(JSON.stringify(results));
            console.info('Loaded LogEntryArchive__b records', this.logEntryArchives);
        });
    }
}
