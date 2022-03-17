/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement } from 'lwc';

// Apex methods
import getVersionNumber from '@salesforce/apex/LoggerInfoController.getVersionNumber';
import getNamespacePrefix from '@salesforce/apex/LoggerInfoController.getNamespacePrefix';
import getPlugins from '@salesforce/apex/LoggerInfoController.getPlugins';

export default class LoggerInfo extends LightningElement {
    versionNumber;
    namespacePrefix;
    plugins = [];

    connectedCallback() {
        Promise.all([getVersionNumber(), getNamespacePrefix(), getPlugins()]).then(([versionNumber, namespacePrefix, plugins]) => {
            this.versionNumber = versionNumber;
            this.namespacePrefix = namespacePrefix;
            this.plugins = plugins;
        });
    }

    get hasPlugins() {
        return this.plugins && this.plugins.length > 0;
    }

    viewReleaseNotes() {
        const releaseNotesUrl = 'https://github.com/jongpie/NebulaLogger/releases/tag/' + this.versionNumber;
        window.open(releaseNotesUrl);
    }

    viewPluginsWikiPage() {
        window.open('https://github.com/jongpie/NebulaLogger/wiki/Plugin-Framework');
    }
}
