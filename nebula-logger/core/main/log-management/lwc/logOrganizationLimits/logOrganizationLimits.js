/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ORGANIZATION_LIMITS_FIELD from '@salesforce/schema/Log__c.OrganizationLimits__c';

export default class LogOrganizationLimits extends LightningElement {
    @api
    recordId;

    isLoaded = false;
    isValidOrganizationLimitsJson;
    organizationLimitsLeft = [];
    organizationLimitsRight = [];

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ORGANIZATION_LIMITS_FIELD]
    })
    async wiredGetLog({ data }) {
        if (data) {
            const organizationLimitsJson = getFieldValue(data, ORGANIZATION_LIMITS_FIELD);
            this._processOrganizationLimits(organizationLimitsJson);
        }
    }

    _processOrganizationLimits(organizationLimitsJson) {
        if (!organizationLimitsJson) {
            this.isValidOrganizationLimitsJson = false;
            this.isLoaded = true;
            return;
        }

        let limits;
        try {
            limits = JSON.parse(organizationLimitsJson);
        } catch (error) {
            this.organizationLimitsJson = organizationLimitsJson;
            this.isValidOrganizationLimitsJson = false;
            this.isLoaded = true;
            return;
        }

        limits.forEach(limit => {
            let percentUsed = limit.Max === 0 ? null : ((limit.Used / limit.Max) * 100).toFixed(2);
            if (percentUsed?.endsWith('.00')) {
                percentUsed = percentUsed.slice(0, -3);
            }
            const percentUsedFormatted = limit.Max === 0 ? 'None Available' : percentUsed + '%';

            let percentUsedIcon = '✅';
            if (limit.Max === 0 || percentUsed >= 90) {
                percentUsedIcon = '⛔';
            } else if (percentUsed >= 80) {
                percentUsedIcon = '⚠️';
            }

            limit.Text = `${percentUsedIcon} ${percentUsedFormatted} (${limit.Used} / ${limit.Max})`;
        });

        // Divide the list in half - each half is displayed as a column in the HTML markup
        const halfLimitsLength = Math.ceil(limits.length / 2);
        this.organizationLimitsLeft = limits.slice(0, halfLimitsLength);
        this.organizationLimitsRight = limits.slice(halfLimitsLength);
        this.isValidOrganizationLimitsJson = true;
        this.isLoaded = true;
    }
}
