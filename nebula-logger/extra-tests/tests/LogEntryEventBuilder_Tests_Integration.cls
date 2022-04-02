//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogEntryEventBuilder_Tests_Integration {
    private static final Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar')];

    @IsTest
    static void stripInaccessibleFieldsForRecordWhenEnabled() {
        User standardUser = LoggerMockCreator.createUser(STANDARD_USER_PROFILE.Id);
        AccountBrand mockAccountBrand = (AccountBrand) LoggerMockCreator.createDataBuilder(Schema.AccountBrand.SObjectType)
            .populateMockId()
            .populateRequiredFields()
            .getRecord();
        // The 'standard user' profile doesn't have access to AccountBrand,
        // so stripAccessible will remove everything except the ID field
        AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            System.assertEquals(false, Schema.AccountBrand.SObjectType.getDescribe().isAccessible(), 'AccountBrand was accessible, and should not have been.');
            System.assertEquals(
                false,
                Schema.AccountBrand.CompanyName.getDescribe().isAccessible(),
                'AccountBrand Company Name was accessible, and should not have been.'
            );
            System.assertEquals(false, Schema.AccountBrand.Email.getDescribe().isAccessible(), 'AccountBrand Email was accessible, and should not have been.');
            System.assertEquals(false, Schema.AccountBrand.Name.getDescribe().isAccessible(), 'AccountBrand Name was accessible, and should not have been.');
            System.assertEquals(false, Schema.AccountBrand.Phone.getDescribe().isAccessible(), 'AccountBrand Phone was accessible, and should not have been.');

            Logger.getUserSettings().IsRecordFieldStrippingEnabled__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAccountBrand);
        }

        System.assertNotEquals(JSON.serializePretty(mockAccountBrand), builder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.assertEquals(JSON.serializePretty(strippedAccountBrand), builder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
    }

    @IsTest
    static void stripInaccessibleFieldsForRecordsWhenEnabled() {
        User standardUser = LoggerMockCreator.createUser(STANDARD_USER_PROFILE.Id);
        List<AccountBrand> mockAccountBrands = new List<AccountBrand>();
        List<AccountBrand> strippedAccountBrands = new List<AccountBrand>();
        for (Integer i = 0; i < 5; i++) {
            AccountBrand mockAccountBrand = (AccountBrand) LoggerMockCreator.createDataBuilder(Schema.AccountBrand.SObjectType)
                .populateMockId()
                .populateRequiredFields()
                .getRecord();
            mockAccountBrands.add(mockAccountBrand);

            // The 'standard user' profile doesn't have access to AccountBrand,
            // so stripAccessible will remove everything except the ID field
            AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);
            strippedAccountBrands.add(strippedAccountBrand);
        }

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            System.assertEquals(false, Schema.AccountBrand.SObjectType.getDescribe().isAccessible(), 'AccountBrand was accessible, and should not have been.');
            System.assertEquals(
                false,
                Schema.AccountBrand.CompanyName.getDescribe().isAccessible(),
                'AccountBrand Company Name was accessible and should not have been.'
            );
            System.assertEquals(false, Schema.AccountBrand.Email.getDescribe().isAccessible(), 'AccountBrand Email was accessible, and should not have been,');
            System.assertEquals(false, Schema.AccountBrand.Name.getDescribe().isAccessible(), 'AccountBrand Name was accessible, and should not have been.');
            System.assertEquals(false, Schema.AccountBrand.Phone.getDescribe().isAccessible(), 'AccountBrand Phone was accessible, and should not have been.');

            Logger.getUserSettings().IsRecordFieldStrippingEnabled__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAccountBrands);
        }

        System.assertNotEquals(JSON.serializePretty(mockAccountBrands), builder.getLogEntryEvent().RecordJson__c, 'Record JSON is incorrect.');
        System.assertEquals(JSON.serializePretty(strippedAccountBrands), builder.getLogEntryEvent().RecordJson__c, 'Record JSON is incorrect.');
    }
}
