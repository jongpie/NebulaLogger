/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

// All field API names below use the local name - that is, the name without a namespace (even if the code is running in a namespaced package)
const PAGE_LAYOUT_CONFIG = {
    sections: [
        {
            key: 'generalSettings',
            label: 'General Settings',
            showInReadOnlyMode: true,
            showInEditMode: true,
            columns: [
                {
                    fieldApiNames: ['SetupOwnerId'],
                    size: 6
                },
                {
                    fieldApiNames: ['StartTime__c', 'EndTime__c'],
                    size: 6
                }
            ]
        },
        {
            key: 'loggerEngineSettings',
            label: 'Logger Engine Settings',
            showInReadOnlyMode: true,
            showInEditMode: true,
            columns: [
                {
                    fieldApiNames: ['IsEnabled__c', 'LoggingLevel__c', 'IsSavingEnabled__c', 'DefaultSaveMethod__c', 'DefaultScenario__c'],
                    size: 6
                },
                {
                    fieldApiNames: [
                        'IsApexSystemDebugLoggingEnabled__c',
                        'IsJavaScriptConsoleLoggingEnabled__c',
                        'IsDataMaskingEnabled__c',
                        'IsRecordFieldStrippingEnabled__c',
                        'IsAnonymousModeEnabled__c'
                    ],
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
                {
                    fieldApiNames: [
                        'DefaultPlatformEventStorageLocation__c',
                        'DefaultPlatformEventStorageLoggingLevel__c',
                        'DefaultNumberOfDaysToRetainLogs__c',
                        'DefaultLogPurgeAction__c'
                    ],
                    size: 6
                },
                { fieldApiNames: ['DefaultLogShareAccessLevel__c', 'DefaultLogOwner__c'], size: 6 }
            ]
        }
    ]
};

const LoggerSettingsPageLayout = class {
    constructor(sobjectSchema, apexPicklistOptions, isReadOnlyMode, record) {
        const picklistOptions = this._parsePicklistOptions(apexPicklistOptions);

        this._buildPageLayoutSectionFields(sobjectSchema, picklistOptions, isReadOnlyMode, record);
    }

    _parsePicklistOptions(apexPicklistOptions) {
        // TODO - long term, this feels like the wrong place for this mapping to live, but it'll live here for now
        const picklistOptions = {
            DefaultLogPurgeAction__c: apexPicklistOptions.purgeActionOptions,
            DefaultLogShareAccessLevel__c: apexPicklistOptions.shareAccessLevelOptions,
            DefaultPlatformEventStorageLocation__c: apexPicklistOptions.platformEventStorageLocationOptions,
            DefaultPlatformEventStorageLoggingLevel__c: apexPicklistOptions.loggingLevelOptions,
            DefaultSaveMethod__c: apexPicklistOptions.saveMethodOptions,
            LoggingLevel__c: apexPicklistOptions.loggingLevelOptions
        };

        return picklistOptions;
    }

    _buildPageLayoutSectionFields(sobjectSchema, picklistOptions, isReadOnlyMode, record) {
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
                    let field = { ...sobjectSchema.fields[fieldApiName] };
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
        field.useComboboxInput = false;
        field.useSetupOwnerInput = false;
        field.useStandardInput = false;

        if (field.localApiName === 'SetupOwnerId') {
            field.useSetupOwnerInput = true;

            return;
        }

        // Picklists are handled differently, since these aren't actually picklist fields
        // (Custom settings objects don't have picklist fields - custom Apex is used for generating picklist options)
        if (picklistOptions[field.localApiName]) {
            field.picklistOptions = picklistOptions[field.localApiName];
            field.type = 'picklist';
            field.useComboboxInput = true;

            return;
        }

        field.useStandardInput = true;
        switch (field.type?.toLowerCase()) {
            case 'boolean':
                field.type = 'checkbox';
                break;
            case 'double':
                field.type = 'number';
                break;
            case 'string':
                field.type = 'text';
                break;
            default:
                break;
        }
    }
};

export function generatePageLayout(sobjectSchema, apexPicklistOptions, isReadOnlyMode, record) {
    return new LoggerSettingsPageLayout(sobjectSchema, apexPicklistOptions, isReadOnlyMode, record);
}
