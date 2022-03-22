import { LightningElement } from 'lwc';

export default class LogEntryArchives extends LightningElement {
    get title() {
        return 'Log Entry Archives';
    }

    async connectedCallback() {
        document.title = this.title;
    }
}
