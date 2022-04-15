/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

// All field API names below use the local name - that is, the name without a namespace (even if the code is running in a namespaced package)
const PAGE_LAYOUT_CONFIG = {
    sections: [
        {
            key: 'developerSettings',
            label: 'Developer Settings',
            showInReadOnlyMode: true,
            showInEditMode: true,
            columns: [
                {
                    fieldApiNames: ['IsSavingEnabled__c', 'DefaultSaveMethod__c', 'DefaultPlatformEventStorageLocation__c'],
                    size: 6
                },
                {
                    fieldApiNames: ['IsApexSystemDebugLoggingEnabled__c', 'IsJavaScriptConsoleLoggingEnabled__c'],
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
                { fieldApiNames: ['IsDataMaskingEnabled__c'], size: 6 },
                {
                    fieldApiNames: ['IsRecordFieldStrippingEnabled__c', 'IsAnonymousModeEnabled__c'],
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
                { fieldApiNames: ['DefaultNumberOfDaysToRetainLogs__c', 'DefaultLogPurgeAction__c'], size: 6 },
                { fieldApiNames: ['DefaultLogScenario__c', 'DefaultLogShareAccessLevel__c', 'DefaultLogOwner__c'], size: 6 }
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
            LoggingLevel__c: apexPicklistOptions.loggingLevelOptions,
            DefaultLogPurgeAction__c: apexPicklistOptions.purgeActionOptions,
            DefaultPlatformEventStorageLocation__c: apexPicklistOptions.platformEventStorageLocationOptions,
            DefaultSaveMethod__c: apexPicklistOptions.saveMethodOptions,
            DefaultLogShareAccessLevel__c: apexPicklistOptions.shareAccessLevelOptions
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
        // Picklists are handled differently, since these aren't actually picklist fields
        // (Custom settings objects don't have picklist fields - custom Apex is used for generating picklist options)
        if (picklistOptions[field.localApiName]) {
            field.picklistOptions = picklistOptions[field.localApiName];
            field.type = 'picklist';
            field.useCombobox = true;

            return;
        }

        field.useCombobox = false;
        switch (field.type?.toLowerCase()) {
            case 'boolean':
                field.type = 'checkbox';
                break;
            case 'double':
                field.type = 'number';
                break;
            default:
                field.type = 'text';
                break;
        }
    }
};

export function generatePageLayout(sobjectSchema, apexPicklistOptions, isReadOnlyMode, record) {
    return new LoggerSettingsPageLayout(sobjectSchema, apexPicklistOptions, isReadOnlyMode, record);
}
