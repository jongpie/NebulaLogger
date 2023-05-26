import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEnvironmentDetails from '@salesforce/apex/LoggerHomeHeaderController.getEnvironmentDetails';

const GITHUB_REPO_URL = 'https://github.com/jongpie/NebulaLogger/';

export default class LoggerHomeHeader extends NavigationMixin(LightningElement) {
    title = 'Nebula Logger';
    environment = {
        loggerVersionNumber: '?',
        organizationApiVersion: '?'
    };

    @wire(getEnvironmentDetails)
    wiredEnvironmentDetails({ data }) {
        if (data) {
            this.environment = data;
        }
    }
    get releaseNotesButtonLabel() {
        return `View ${this.environment.loggerVersionNumber} Release Notes`;
    }

    handleViewReleaseNotes() {
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: `${GITHUB_REPO_URL}releases/tag/${this.loggerVersionNumber}`
            }
        };
        this[NavigationMixin.Navigate](config);
    }
}
