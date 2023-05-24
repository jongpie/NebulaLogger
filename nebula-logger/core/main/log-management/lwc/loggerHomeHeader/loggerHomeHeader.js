import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLoggerVersionNumber from '@salesforce/apex/LoggerHomeHeaderController.getLoggerVersionNumber';
import getOrganizationApiVersion from '@salesforce/apex/LoggerHomeHeaderController.getOrganizationApiVersion';

export default class LoggerHomeHeader extends NavigationMixin(LightningElement) {
    loggerVersionNumber = '?';
    organizationApiVersion = '?';
    title = 'Nebula Logger';

    @wire(getLoggerVersionNumber)
    wiredLoggerVersionNumber({ error, data }) {
        if (data) {
            this.loggerVersionNumber = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.loggerVersionNumber = undefined;
        }
    }

    @wire(getOrganizationApiVersion)
    wiredOrganizationApiVersion({ error, data }) {
        if (data) {
            this.organizationApiVersion = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.organizationApiVersion = undefined;
        }
    }

    get environmentDetailsButtonLabel() {
        return 'View Environment Details';
    }

    get releaseNotesButtonLabel() {
        return `View ${this.loggerVersionNumber} Release Notes`;
    }

    handleViewEnvironmentDetails() {
        this.showModal = true;
    }

    handleViewReleaseNotes() {
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: `https://github.com/jongpie/NebulaLogger/releases/tag/${this.loggerVersionNumber}`
            }
        };
        this[NavigationMixin.Navigate](config);
    }
}
