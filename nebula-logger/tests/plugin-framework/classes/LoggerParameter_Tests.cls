//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@isTest
private class LoggerParameter_Tests {
    private static User getUserRecord() {
        return new User(Id = UserInfo.getUserId(), Username = UserInfo.getUserName());
    }

    @isTest
    static void it_should_return_boolean_parameter_for_handler() {
        Boolean parameterValue = true;
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyBoolean',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Boolean returnedValue = LoggerParameter.Handler.getBoolean(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_boolean_parameter_for_plugin() {
        Boolean parameterValue = true;
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyBoolean',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Boolean returnedValue = LoggerParameter.Plugin.getBoolean(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_boolean_list_parameter_for_handler() {
        List<Boolean> parameterValue = new List<Boolean>{true, false, true, true};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyBooleanList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Boolean> returnedValue = LoggerParameter.Handler.getBooleanList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_boolean_list_parameter_for_plugin() {
        List<Boolean> parameterValue = new List<Boolean>{true, false, true, true};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyBooleanList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Boolean> returnedValue = LoggerParameter.Plugin.getBooleanList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_date_parameter_for_handler() {
        Date parameterValue = System.today().addDays(-7);
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDate',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Date returnedValue = LoggerParameter.Handler.getDate(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_date_parameter_for_plugin() {
        Date parameterValue = System.today().addDays(-7);
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDate',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Date returnedValue = LoggerParameter.Plugin.getDate(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_date_list_parameter_for_handler() {
        List<Date> parameterValue = new List<Date>{System.today(), System.today().addDays(10)};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDateList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Date> returnedValue = LoggerParameter.Handler.getDateList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_date_list_parameter_for_plugin() {
        List<Date> parameterValue = new List<Date>{System.today(), System.today().addDays(10)};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDateList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Date> returnedValue = LoggerParameter.Plugin.getDateList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_datetime_parameter_for_handler() {
        Datetime parameterValue = System.now().addDays(-7);
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDatetime',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Datetime returnedValue = LoggerParameter.Handler.getDatetime(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_datetime_parameter_for_plugin() {
        Datetime parameterValue = System.now().addDays(-7);
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDatetime',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Datetime returnedValue = LoggerParameter.Plugin.getDatetime(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_datetime_list_parameter_for_handler() {
        List<Datetime> parameterValue = new List<Datetime>{System.now(), System.now().addDays(10)};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDatetimeList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Datetime> returnedValue = LoggerParameter.Handler.getDatetimeList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_datetime_list_parameter_for_plugin() {
        List<Datetime> parameterValue = new List<Datetime>{System.now(), System.now().addDays(10)};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDatetimeList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Datetime> returnedValue = LoggerParameter.Plugin.getDatetimeList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_decimal_parameter_for_handler() {
        Decimal parameterValue = 123456.0987;
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDecimal',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Decimal returnedValue = LoggerParameter.Handler.getDecimal(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_decimal_parameter_for_plugin() {
        Decimal parameterValue = 123456.0987;
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDecimal',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Decimal returnedValue = LoggerParameter.Plugin.getDecimal(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_decimal_list_parameter_for_handler() {
        List<Decimal> parameterValue = new List<Decimal>{123.45, 678.09};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDecimalList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Decimal> returnedValue = LoggerParameter.Handler.getDecimalList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_decimal_list_parameter_for_plugin() {
        List<Decimal> parameterValue = new List<Decimal>{123.45, 678.09};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDecimalList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Decimal> returnedValue = LoggerParameter.Plugin.getDecimalList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_double_parameter_for_handler() {
        Double parameterValue = 123456.0987;
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDouble',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Double returnedValue = LoggerParameter.Handler.getDouble(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_double_parameter_for_plugin() {
        Double parameterValue = 123456.0987;
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDouble',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Double returnedValue = LoggerParameter.Plugin.getDouble(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_double_list_parameter_for_handler() {
        List<Double> parameterValue = new List<Double>{123.45, 678.09};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyDoubleList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Double> returnedValue = LoggerParameter.Handler.getDoubleList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_double_list_parameter_for_plugin() {
        List<Double> parameterValue = new List<Double>{123.45, 678.09};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyDoubleList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Double> returnedValue = LoggerParameter.Plugin.getDoubleList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_id_parameter_for_handler() {
        Id parameterValue = UserInfo.getUserId();
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyId',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Id returnedValue = LoggerParameter.Handler.getId(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_id_parameter_for_plugin() {
        Id parameterValue = UserInfo.getUserId();
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyId',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Id returnedValue = LoggerParameter.Plugin.getId(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_id_list_parameter_for_handler() {
        List<Id> parameterValue = new List<Id>{UserInfo.getUserId()};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyIdList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Id> returnedValue = LoggerParameter.Handler.getIdList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_id_list_parameter_for_plugin() {
        List<Id> parameterValue = new List<Id>{UserInfo.getUserId()};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyIdList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Id> returnedValue = LoggerParameter.Plugin.getIdList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_integer_parameter_for_handler() {
        Integer parameterValue = 123456;
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyInteger',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Integer returnedValue = LoggerParameter.Handler.getInteger(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_integer_parameter_for_plugin() {
        Integer parameterValue = 123456;
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyInteger',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Integer returnedValue = LoggerParameter.Plugin.getInteger(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_integer_list_parameter_for_handler() {
        List<Integer> parameterValue = new List<Integer>{12345, 67809};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyIntegerList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Integer> returnedValue = LoggerParameter.Handler.getIntegerList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_integer_list_parameter_for_plugin() {
        List<Integer> parameterValue = new List<Integer>{12345, 67809};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyIntegerList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Integer> returnedValue = LoggerParameter.Plugin.getIntegerList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_long_parameter_for_handler() {
        Long parameterValue = 123456;
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyLong',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        Long returnedValue = LoggerParameter.Handler.getLong(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_long_parameter_for_plugin() {
        Long parameterValue = 123456;
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyLong',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        Long returnedValue = LoggerParameter.Plugin.getLong(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_long_list_parameter_for_handler() {
        List<Long> parameterValue = new List<Long>{12345, 67809};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyLongList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<Long> returnedValue = LoggerParameter.Handler.getLongList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_long_list_parameter_for_plugin() {
        List<Long> parameterValue = new List<Long>{12345, 67809};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyLongList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<Long> returnedValue = LoggerParameter.Plugin.getLongList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_sobject_parameter_for_handler() {
        SObject parameterValue = getUserRecord();
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MySObject',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        SObject returnedValue = LoggerParameter.Handler.getSObject(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_sobject_parameter_for_plugin() {
        SObject parameterValue = getUserRecord();
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MySObject',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        SObject returnedValue = LoggerParameter.Plugin.getSObject(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_sobject_list_parameter_for_handler() {
        List<SObject> parameterValue = new List<SObject>{getUserRecord()};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MySObjectList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<SObject> returnedValue = LoggerParameter.Handler.getSObjectList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_sobject_list_parameter_for_plugin() {
        List<SObject> parameterValue = new List<SObject>{getUserRecord()};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MySObjectList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<SObject> returnedValue = LoggerParameter.Plugin.getSObjectList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_string_parameter_for_handler() {
        String parameterValue = 'Hello';
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyString',
            IsEnabled__c = true,
            Value__c = parameterValue
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        String returnedValue = LoggerParameter.Handler.getString(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_string_parameter_for_plugin() {
        String parameterValue = 'Hello';
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyString',
            IsEnabled__c = true,
            Value__c = parameterValue
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        String returnedValue = LoggerParameter.Plugin.getString(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_string_list_parameter_for_handler() {
        List<String> parameterValue = new List<String>{'Hello', 'Goodbye'};
        LoggerSObjectHandlerParameter__mdt mockParameter = new LoggerSObjectHandlerParameter__mdt(
            DeveloperName = 'MyStringList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Handler.setMockParameter(mockParameter);

        List<String> returnedValue = LoggerParameter.Handler.getStringList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @isTest
    static void it_should_return_string_list_parameter_for_plugin() {
        List<String> parameterValue = new List<String>{'Hello', 'Goodbye'};
        LoggerSObjectHandlerPluginParameter__mdt mockParameter = new LoggerSObjectHandlerPluginParameter__mdt(
            DeveloperName = 'MyStringList',
            IsEnabled__c = true,
            Value__c = JSON.serialize(parameterValue)
        );
        LoggerParameter.Plugin.setMockParameter(mockParameter);

        List<String> returnedValue = LoggerParameter.Plugin.getStringList(mockParameter.DeveloperName);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }
}
