/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import LOGGER_SETTINGS_SCHEMA from './loggerSettingsSchema';

const PAGE_LAYOUT_CONFIG = {
    sections: [
        {
            key: 'developerSettings',
            label: 'Developer Settings',
            showInReadOnlyMode: true,
            showInEditMode: true,
            columns: [
                {
                    fieldApiNames: [
                        LOGGER_SETTINGS_SCHEMA.fields.IsSavingEnabled__c,
                        LOGGER_SETTINGS_SCHEMA.fields.DefaultSaveMethod__c,
                        LOGGER_SETTINGS_SCHEMA.fields.IsPlatformEventStorageEnabled__c
                    ],
                    size: 6
                },
                {
                    fieldApiNames: [
                        LOGGER_SETTINGS_SCHEMA.fields.IsApexSystemDebugLoggingEnabled__c,
                        LOGGER_SETTINGS_SCHEMA.fields.IsJavaScriptConsoleLoggingEnabled__c
                    ],
                    size: 6
                }
            ]
        },
        {
            key: 'securitySettings',
            label: 'Security Settings',
            showInReadOnlyMode: true,
            showInEditMode: true,
            columns: [
                { fieldApiNames: [LOGGER_SETTINGS_SCHEMA.fields.IsDataMaskingEnabled__c], size: 6 },
                {
                    fieldApiNames: [LOGGER_SETTINGS_SCHEMA.fields.IsRecordFieldStrippingEnabled__c, LOGGER_SETTINGS_SCHEMA.fields.IsAnonymousModeEnabled__c],
                    size: 6
                }
            ]
        },
        {
            key: 'logManagementSettings',
            label: 'Log Management Settings',
            showInReadOnlyMode: true,
            showInEditMode: true,
            columns: [
                { fieldApiNames: [LOGGER_SETTINGS_SCHEMA.fields.DefaultNumberOfDaysToRetainLogs__c], size: 6 },
                { fieldApiNames: [LOGGER_SETTINGS_SCHEMA.fields.DefaultLogOwner__c, LOGGER_SETTINGS_SCHEMA.fields.DefaultLogShareAccessLevel__c], size: 6 }
            ]
        },
        {
            key: 'systemInformation',
            label: 'System Information',
            showInReadOnlyMode: true,
            showInEditMode: false,
            columns: [
                { fieldApiNames: [LOGGER_SETTINGS_SCHEMA.fields.CreatedById, LOGGER_SETTINGS_SCHEMA.fields.CreatedDate], size: 6 },
                { fieldApiNames: [LOGGER_SETTINGS_SCHEMA.fields.LastModifiedById, LOGGER_SETTINGS_SCHEMA.fields.LastModifiedDate], size: 6 }
            ]
        }
    ]
};

const LoggerSettingsPageLayout = class {
    constructor(sobjectDescribe, apexPicklistOptions, isReadOnlyMode, record) {
        const picklistOptions = this._parsePicklistOptions(apexPicklistOptions);

        this._buildPageLayoutSectionFields(sobjectDescribe, picklistOptions, isReadOnlyMode, record);
    }

    _parsePicklistOptions(apexPicklistOptions) {
        // TODO - long term, this feels like the wrong place for this mapping to live, but it'll live here for now
        const picklistOptions = {
            [LOGGER_SETTINGS_SCHEMA.fields.LoggingLevel__c]: apexPicklistOptions.loggingLevelOptions,
            [LOGGER_SETTINGS_SCHEMA.fields.DefaultSaveMethod__c]: apexPicklistOptions.saveMethodOptions,
            [LOGGER_SETTINGS_SCHEMA.fields.DefaultLogShareAccessLevel__c]: apexPicklistOptions.shareAccessLevelOptions
        };

        return picklistOptions;
    }

    _buildPageLayoutSectionFields(sobjectDescribe, picklistOptions, isReadOnlyMode, record) {
        this.sections = [];

        let layoutConfigSections = [...PAGE_LAYOUT_CONFIG.sections];
        layoutConfigSections.forEach(section => {
            section.show = (section.showInReadOnlyMode && isReadOnlyMode) || (section.showInEditMode && !isReadOnlyMode);

            if (!section.show) {
                return;
            }

            let sectionCounter = 0;
            section.columns?.forEach(column => {
                column.key = 'section' + sectionCounter++;
                column.fields = [];
                let fieldCounter = 0;
                column.fieldApiNames.forEach(fieldApiName => {
                    let field = { ...sobjectDescribe.fields[fieldApiName] };
                    field.key = column.key + 'field' + fieldCounter++;
                    field.value = record[fieldApiName];
                    this._setFieldTypeDetails(field, picklistOptions);

                    column.fields.push(field);
                });
            });
            this.sections.push(section);
        });
    }

    _setFieldTypeDetails(field, picklistOptions) {
        // Picklists are handled differently, since these aren't actually picklist fields
        // (Custom settings objects don't have picklist fields - custom Apex is used for generating picklist options)
        if (picklistOptions[field.apiName]) {
            field.picklistOptions = picklistOptions[field.apiName];
            field.type = 'picklist';
            field.useCombobox = true;

            return;
        }

        field.useCombobox = false;
        switch (field.dataType) {
            case 'Boolean':
                field.type = 'checkbox';
                break;
            case 'Double':
                field.type = 'number';
                break;
            default:
                field.type = 'text';
                break;
        }
    }
};

export function generatePageLayout(sobjectDescribe, apexPicklistOptions, isReadOnlyMode, record) {
    return new LoggerSettingsPageLayout(sobjectDescribe, apexPicklistOptions, isReadOnlyMode, record);
}
