import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getEnvironmentDetails from '@salesforce/apex/LoggerHomeHeaderController.getEnvironmentDetails';

const GITHUB_REPO_URL = 'https://github.com/jongpie/NebulaLogger/';
const STATUS_SITE_URL = 'https://status.salesforce.com/instances/';

export default class LoggerHomeHeader extends NavigationMixin(LightningElement) {
    environment = {};
    showEnvironmentDetailsModal = false;

    @wire(getEnvironmentDetails)
    wiredEnvironmentDetails({ data }) {
        if (data) {
            this.environment = data;
        }
    }

    get title() {
        let titleText = 'Nebula Logger';
        if (this.environment.loggerVersionNumber) {
            titleText += ' ' + this.environment.loggerVersionNumber;
        }
        return titleText;
    }

    get enabledPluginsSummary() {
        if (!this.environment.loggerEnabledPlugins) {
            return undefined;
        }

        return this.environment.loggerEnabledPluginsCount + ' Enabled Plugins';
    }

    get environmentDetailsButtonLabel() {
        return `View Environment Details`;
    }

    get showReleaseNotesButton() {
        return !!this.environment?.loggerVersionNumber;
    }

    get releaseNotesButtonLabel() {
        return `View ${this.environment.loggerVersionNumber} Release Notes`;
    }

    handleViewEnvironmentDetails() {
        this.showEnvironmentDetailsModal = true;
    }

    handleCloseEnvironmentDetailsModal() {
        this.showEnvironmentDetailsModal = false;
    }

    handleViewStatusSite() {
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: `${STATUS_SITE_URL}${this.environment.organizationInstanceName}`
            }
        };
        this[NavigationMixin.Navigate](config);
    }

    handleViewReleaseNotes() {
        const pageReference = {
            type: 'standard__webPage',
            attributes: {
                url: `${GITHUB_REPO_URL}releases/tag/${this.environment.loggerVersionNumber}`
            }
        };
        this[NavigationMixin.Navigate](pageReference);
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.handleCloseEnvironmentDetailsModal();
        }
    }
}
