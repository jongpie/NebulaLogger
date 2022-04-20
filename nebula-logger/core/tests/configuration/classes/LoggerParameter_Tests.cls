//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LoggerParameter_Tests {
    private static User getUserRecord() {
        return new User(Id = UserInfo.getUserId(), Username = UserInfo.getUserName());
    }

    @IsTest
    static void it_should_throw_exception_when_mock_record_developer_name_is_null() {
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = null);
        Exception thrownIllegalArgumentException;

        try {
            LoggerParameter.setMock(mockParameter);
        } catch (IllegalArgumentException ex) {
            thrownIllegalArgumentException = ex;
        }

        System.assertNotEquals(null, thrownIllegalArgumentException);
    }

    @IsTest
    static void it_should_load_mock_record() {
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MockParameter', Value__c = 'Hello, world!');
        LoggerParameter.setMock(mockParameter);

        String returnedValue = LoggerParameter.getString(mockParameter.DeveloperName, null);

        System.assertNotEquals(null, returnedValue);
        System.assertEquals(mockParameter.Value__c, returnedValue);
    }

    @IsTest
    static void it_should_return_constant_value_for_call_status_api() {
        Boolean mockValue = true;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = JSON.serialize(mockValue));
        LoggerParameter.setMock(mockParameter);

        Boolean returnedValue = LoggerParameter.CALL_STATUS_API;

        System.assertEquals(mockValue, returnedValue);
    }

    @IsTest
    static void it_should_return_constant_value_for_enable_system_messages() {
        Boolean mockValue = true;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = JSON.serialize(mockValue));
        LoggerParameter.setMock(mockParameter);

        Boolean returnedValue = LoggerParameter.ENABLE_SYSTEM_MESSAGES;

        System.assertEquals(mockValue, returnedValue);
    }

    @IsTest
    static void it_should_return_constant_value_for_send_error_email_notifications() {
        Boolean mockValue = false;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = JSON.serialize(mockValue));
        LoggerParameter.setMock(mockParameter);

        Boolean returnedValue = LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS;

        System.assertEquals(mockValue, returnedValue);
    }

    @IsTest
    static void it_should_return_constant_value_for_system_debug_message_format() {
        // The constant LoggerParameter.SYSTEM_DEBUG_MESSAGE_FORMAT is unique - its value should always be
        // loaded from LoggerParameter__mdt, even in a test context so that orgs can control the output of debug
        // messages within their own test classes. All other constants use mock configurations
        String configuredValue = LoggerParameter__mdt.getInstance('SystemDebugMessageFormat').Value__c;

        String returnedValue = LoggerParameter.SYSTEM_DEBUG_MESSAGE_FORMAT;

        System.assertEquals(configuredValue, returnedValue);
    }

    @IsTest
    static void it_should_return_constant_value_for_tagging_is_enabled() {
        Boolean mockValue = false;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'EnableTagging', Value__c = JSON.serialize(mockValue));
        LoggerParameter.setMock(mockParameter);

        Boolean returnedValue = LoggerParameter.TAGGING_IS_ENABLED;

        System.assertEquals(mockValue, returnedValue);
    }

    @IsTest
    static void it_should_return_constant_value_for_tag_using_topics() {
        Boolean mockValue = true;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'UseTopicsForTags', Value__c = JSON.serialize(mockValue));
        LoggerParameter.setMock(mockParameter);

        Boolean returnedValue = LoggerParameter.TAG_USING_TOPICS;

        System.assertEquals(mockValue, returnedValue);
    }

    @IsTest
    static void it_should_return_boolean_parameter() {
        Boolean parameterValue = true;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyBoolean', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Boolean returnedValue = LoggerParameter.getBoolean(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_boolean_list_parameter() {
        List<Boolean> parameterValue = new List<Boolean>{ true, false, true, true };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyBooleanList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Boolean> returnedValue = LoggerParameter.getBooleanList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_default_value_when_configured_boolean_list_parameter_is_null() {
        List<Boolean> parameterValue = null;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyBooleanList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);
        List<Boolean> defaultParameterValue = new List<Boolean>{ true, false };

        List<Boolean> returnedValue = LoggerParameter.getBooleanList(mockParameter.DeveloperName, defaultParameterValue);

        System.assertEquals(null, parameterValue);
        System.assertNotEquals(parameterValue, returnedValue, 'Returned value should not match configured null parameter value');
        System.assertEquals(defaultParameterValue, returnedValue, 'Returned value does not match expected default parameter value');
    }

    @IsTest
    static void it_should_return_date_parameter() {
        Date parameterValue = System.today().addDays(-7);
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDate', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Date returnedValue = LoggerParameter.getDate(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_date_list_parameter() {
        List<Date> parameterValue = new List<Date>{ System.today(), System.today().addDays(10) };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDateList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Date> returnedValue = LoggerParameter.getDateList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_datetime_parameter() {
        Datetime parameterValue = System.now().addDays(-7);
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDatetime', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Datetime returnedValue = LoggerParameter.getDatetime(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_datetime_list_parameter() {
        List<Datetime> parameterValue = new List<Datetime>{ System.now(), System.now().addDays(10) };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDatetimeList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Datetime> returnedValue = LoggerParameter.getDatetimeList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_decimal_parameter() {
        Decimal parameterValue = 123456.0987;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDecimal', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Decimal returnedValue = LoggerParameter.getDecimal(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_decimal_list_parameter() {
        List<Decimal> parameterValue = new List<Decimal>{ 123.45, 678.09 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDecimalList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Decimal> returnedValue = LoggerParameter.getDecimalList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_double_parameter() {
        Double parameterValue = 123456.0987;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDouble', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Double returnedValue = LoggerParameter.getDouble(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_double_list_parameter() {
        List<Double> parameterValue = new List<Double>{ 123.45, 678.09 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDoubleList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Double> returnedValue = LoggerParameter.getDoubleList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_id_parameter() {
        Id parameterValue = UserInfo.getUserId();
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyId', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Id returnedValue = LoggerParameter.getId(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_id_list_parameter() {
        List<Id> parameterValue = new List<Id>{ UserInfo.getUserId() };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyIdList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Id> returnedValue = LoggerParameter.getIdList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_integer_parameter() {
        Integer parameterValue = 123456;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyInteger', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Integer returnedValue = LoggerParameter.getInteger(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_integer_list_parameter() {
        List<Integer> parameterValue = new List<Integer>{ 12345, 67809 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyIntegerList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Integer> returnedValue = LoggerParameter.getIntegerList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_long_parameter() {
        Long parameterValue = 123456;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyLong', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        Long returnedValue = LoggerParameter.getLong(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_long_list_parameter() {
        List<Long> parameterValue = new List<Long>{ 12345, 67809 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyLongList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<Long> returnedValue = LoggerParameter.getLongList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_sobject_parameter() {
        SObject parameterValue = getUserRecord();
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MySObject', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        SObject returnedValue = LoggerParameter.getSObject(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_sobject_list_parameter() {
        List<SObject> parameterValue = new List<SObject>{ getUserRecord() };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MySObjectList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<SObject> returnedValue = LoggerParameter.getSObjectList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_string_parameter() {
        String parameterValue = 'Hello';
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyString', Value__c = parameterValue);
        LoggerParameter.setMock(mockParameter);

        String returnedValue = LoggerParameter.getString(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_string_list_parameter() {
        List<String> parameterValue = new List<String>{ 'Hello', 'Goodbye' };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyStringList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMock(mockParameter);

        List<String> returnedValue = LoggerParameter.getStringList(mockParameter.DeveloperName, null);

        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_match_on_developer_name_prefix() {
        String developerNamePrefix = 'SomePrefix';
        LoggerParameter__mdt firstMatchingMockParameter = new LoggerParameter__mdt(DeveloperName = developerNamePrefix + 'SomeExample', Value__c = 'hello');
        LoggerParameter.setMock(firstMatchingMockParameter);
        LoggerParameter__mdt secondMatchingMockParameter = new LoggerParameter__mdt(DeveloperName = developerNamePrefix + 'AnotherExample', Value__c = 'world');
        LoggerParameter.setMock(secondMatchingMockParameter);
        LoggerParameter__mdt nonMatchingMockParameter = new LoggerParameter__mdt(DeveloperName = 'ThisShouldNotMatch', Value__c = '!');
        LoggerParameter.setMock(nonMatchingMockParameter);

        List<LoggerParameter__mdt> matchingParameters = LoggerParameter.matchOnPrefix(developerNamePrefix);

        System.assertEquals(2, matchingParameters.size());
        for (LoggerParameter__mdt matchingParameter : matchingParameters) {
            System.assertEquals(
                true,
                matchingParameter.DeveloperName == firstMatchingMockParameter.DeveloperName ||
                matchingParameter.DeveloperName == secondMatchingMockParameter.DeveloperName,
                'Returned parameter should be one of the two matching mock parameters'
            );
        }
    }
}
