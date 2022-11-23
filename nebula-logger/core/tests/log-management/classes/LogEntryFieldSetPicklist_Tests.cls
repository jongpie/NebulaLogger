//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryFieldSetPicklist_Tests {
    @IsTest
    static void it_should_return_null_for_default_value() {
        // Admins should choose a field set, so always return null for the default
        System.Test.startTest();
        LogEntryFieldSetPicklist instance = new LogEntryFieldSetPicklist();
        System.Test.stopTest();

        System.Assert.isNull(instance.getDefaultValue());
    }

    @IsTest
    static void it_should_return_all_field_sets_as_values() {
        Map<String, Schema.FieldSet> expectedFieldSets = Schema.SObjectType.LogEntry__c.fieldSets.getMap();

        System.Test.startTest();
        LogEntryFieldSetPicklist instance = new LogEntryFieldSetPicklist();
        System.Test.stopTest();

        List<VisualEditor.DataRow> dataRows = instance.getValues().getDataRows();
        System.Assert.areEqual(expectedFieldSets.size(), dataRows.size());
        for (VisualEditor.DataRow dataRow : dataRows) {
            String fieldSetName = (String) dataRow.getValue();
            String fieldSetLabel = (String) dataRow.getLabel();

            System.Assert.isTrue(expectedFieldSets.containsKey(fieldSetName));

            Schema.FieldSet fieldSet = expectedFieldSets.get(fieldSetName);
            System.Assert.areEqual(fieldSet.getLabel(), fieldSetLabel);
        }
    }
}
