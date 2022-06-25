//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogEntryEventStreamController_Tests {
    @isTest
    static void it_should_return_List_of_Fields_configured_in_LogParameters() {
        String fields = '["Timestamp__c", "LoggedByUsername__c", "OriginLocation__c"]';
        LoggerTestConfigurator.setMock(
            new LoggerParameter__mdt(DeveloperName = LogEntryEventStreamController.DISPLAY_FIELDS_PARAMETER_NAME, Value__c = fields)
        );
        List<String> mockDisplayFields = (List<String>) JSON.deserialize(fields, List<String>.class);
        List<String> displayFields = LogEntryEventStreamController.getDataTableDisplayFields();

        System.assertEquals(mockDisplayFields.size(), displayFields.size(), 'fields count mismatch');
        for (String aField : mockDisplayFields) {
            System.assertEquals(true, displayFields.contains(aField), 'field not found');
        }
    }
    @isTest
    static void it_should_return_default_fields_when_List_of_Fields_not_configured_in_logParameters() {
        List<String> displayFields = LogEntryEventStreamController.getDataTableDisplayFields();

        System.assertEquals(LogEntryEventStreamController.DEFAULT_DISPLAY_FIELDS.size(), displayFields.size(), 'fields count mismatch');
        for (String aField : LogEntryEventStreamController.DEFAULT_DISPLAY_FIELDS) {
            System.assertEquals(true, displayFields.contains(aField), 'field not found');
        }
    }
}
