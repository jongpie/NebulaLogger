//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LoggerParameter_Tests {
    private static User getUserRecord() {
        return new User(Id = UserInfo.getUserId(), Username = UserInfo.getUserName());
    }

    @IsTest
    static void it_should_return_boolean_parameter() {
        Boolean parameterValue = true;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyBoolean', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Boolean returnedValue = LoggerParameter.getBoolean(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_boolean_list_parameter() {
        List<Boolean> parameterValue = new List<Boolean>{ true, false, true, true };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyBooleanList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Boolean> returnedValue = LoggerParameter.getBooleanList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_date_parameter() {
        Date parameterValue = System.today().addDays(-7);
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDate', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Date returnedValue = LoggerParameter.getDate(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_date_list_parameter() {
        List<Date> parameterValue = new List<Date>{ System.today(), System.today().addDays(10) };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDateList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Date> returnedValue = LoggerParameter.getDateList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_datetime_parameter() {
        Datetime parameterValue = System.now().addDays(-7);
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDatetime', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Datetime returnedValue = LoggerParameter.getDatetime(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_datetime_list_parameter() {
        List<Datetime> parameterValue = new List<Datetime>{ System.now(), System.now().addDays(10) };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDatetimeList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Datetime> returnedValue = LoggerParameter.getDatetimeList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_decimal_parameter() {
        Decimal parameterValue = 123456.0987;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDecimal', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Decimal returnedValue = LoggerParameter.getDecimal(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_decimal_list_parameter() {
        List<Decimal> parameterValue = new List<Decimal>{ 123.45, 678.09 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDecimalList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Decimal> returnedValue = LoggerParameter.getDecimalList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_double_parameter() {
        Double parameterValue = 123456.0987;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDouble', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Double returnedValue = LoggerParameter.getDouble(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_double_list_parameter() {
        List<Double> parameterValue = new List<Double>{ 123.45, 678.09 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyDoubleList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Double> returnedValue = LoggerParameter.getDoubleList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_id_parameter() {
        Id parameterValue = UserInfo.getUserId();
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyId', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Id returnedValue = LoggerParameter.getId(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_id_list_parameter() {
        List<Id> parameterValue = new List<Id>{ UserInfo.getUserId() };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyIdList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Id> returnedValue = LoggerParameter.getIdList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_integer_parameter() {
        Integer parameterValue = 123456;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyInteger', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Integer returnedValue = LoggerParameter.getInteger(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_integer_list_parameter() {
        List<Integer> parameterValue = new List<Integer>{ 12345, 67809 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyIntegerList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Integer> returnedValue = LoggerParameter.getIntegerList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_long_parameter() {
        Long parameterValue = 123456;
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyLong', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        Long returnedValue = LoggerParameter.getLong(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_long_list_parameter() {
        List<Long> parameterValue = new List<Long>{ 12345, 67809 };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyLongList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<Long> returnedValue = LoggerParameter.getLongList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_sobject_parameter() {
        SObject parameterValue = getUserRecord();
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MySObject', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        SObject returnedValue = LoggerParameter.getSObject(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_sobject_list_parameter() {
        List<SObject> parameterValue = new List<SObject>{ getUserRecord() };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MySObjectList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<SObject> returnedValue = LoggerParameter.getSObjectList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_string_parameter() {
        String parameterValue = 'Hello';
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyString', Value__c = parameterValue);
        LoggerParameter.setMockParameter(mockParameter);

        String returnedValue = LoggerParameter.getString(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }

    @IsTest
    static void it_should_return_string_list_parameter() {
        List<String> parameterValue = new List<String>{ 'Hello', 'Goodbye' };
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'MyStringList', Value__c = JSON.serialize(parameterValue));
        LoggerParameter.setMockParameter(mockParameter);

        List<String> returnedValue = LoggerParameter.getStringList(mockParameter.DeveloperName, null);
        System.assertEquals(parameterValue, returnedValue, 'Returned value does not match expected parameter value');
    }
}
