//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugin Framework
 * @description Provides a centralized way to load parameters for SObject handlers & plugins,
 *              and casts the parameters to common data types
 */
public class LoggerParameter {
    private static Map<String, SObject> mockParameterByDeveloperName = new Map<String, SObject>();

    public static final Boolean ENABLE_SYSTEM_MESSAGES = LoggerParameter.getBoolean('EnableSystemMessages', false);
    public static final Boolean TAGGING_IS_ENABLED = getBoolean('LogEntryEventHandler_EnableTagging', true);
    public static final Boolean TAG_USING_TOPICS = getBoolean('LogEntryEventHandler_UseTopicsForTags', false);
    public static final Boolean SHOULD_CALL_STATUS_API = LoggerParameter.getBoolean('LogEntryEventHandler_CallStatusApi', false);

    /**
     * @description Returns the configured value of the field `Value__c` as a `Boolean`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Boolean` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Boolean getBoolean(String parameterDeveloperName) {
        return getBoolean(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Boolean`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Boolean` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Boolean getBoolean(String parameterDeveloperName, Boolean defaultValue) {
        Boolean parameterValue = (Boolean) castParameterValue(parameterDeveloperName, Boolean.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Boolean>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Boolean>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Boolean> getBooleanList(String parameterDeveloperName) {
        return getBooleanList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Boolean>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Boolean>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Boolean> getBooleanList(String parameterDeveloperName, List<Boolean> defaultValue) {
        List<Boolean> parameterValue = (List<Boolean>) castParameterValue(parameterDeveloperName, List<Boolean>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Date`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Date` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Date getDate(String parameterDeveloperName) {
        return getDate(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Date`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Date` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Date getDate(String parameterDeveloperName, Date defaultValue) {
        Date parameterValue = (Date) castParameterValue(parameterDeveloperName, Date.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Date>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Date>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Date> getDateList(String parameterDeveloperName) {
        return getDateList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Date>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Date>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Date> getDateList(String parameterDeveloperName, List<Date> defaultValue) {
        List<Date> parameterValue = (List<Date>) castParameterValue(parameterDeveloperName, List<Date>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Datetime`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Datetime` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Datetime getDatetime(String parameterDeveloperName) {
        return getDatetime(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Datetime`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Datetime` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Datetime getDatetime(String parameterDeveloperName, Datetime defaultValue) {
        Datetime parameterValue = (Datetime) castParameterValue(parameterDeveloperName, Datetime.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Datetime>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Datetime>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Datetime> getDatetimeList(String parameterDeveloperName) {
        return getDatetimeList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Datetime>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Datetime>` value configured in the matching instance of  `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Datetime> getDatetimeList(String parameterDeveloperName, List<Datetime> defaultValue) {
        List<Datetime> parameterValue = (List<Datetime>) castParameterValue(parameterDeveloperName, List<Datetime>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Decimal`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Decimal` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Decimal getDecimal(String parameterDeveloperName) {
        return getDecimal(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Decimal`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Decimal` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Decimal getDecimal(String parameterDeveloperName, Decimal defaultValue) {
        Decimal parameterValue = (Decimal) castParameterValue(parameterDeveloperName, Decimal.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Decimal>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Decimal>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Decimal> getDecimalList(String parameterDeveloperName) {
        return getDecimalList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Decimal>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Decimal>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Decimal> getDecimalList(String parameterDeveloperName, List<Decimal> defaultValue) {
        List<Decimal> parameterValue = (List<Decimal>) castParameterValue(parameterDeveloperName, List<Decimal>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Double`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Double` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Double getDouble(String parameterDeveloperName) {
        return getDouble(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Double`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Double` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Double getDouble(String parameterDeveloperName, Double defaultValue) {
        Double parameterValue = (Double) castParameterValue(parameterDeveloperName, Double.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Double>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Double>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Double> getDoubleList(String parameterDeveloperName) {
        return getDoubleList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Double>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Double>` value configured in the matching instance of LLoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Double> getDoubleList(String parameterDeveloperName, List<Double> defaultValue) {
        List<Double> parameterValue = (List<Double>) castParameterValue(parameterDeveloperName, List<Double>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Id`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Id` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Id getId(String parameterDeveloperName) {
        return getId(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Id`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Id` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Id getId(String parameterDeveloperName, Id defaultValue) {
        Id parameterValue = (Id) castParameterValue(parameterDeveloperName, Id.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Id>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Id>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Id> getIdList(String parameterDeveloperName) {
        return getIdList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Id>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Id>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Id> getIdList(String parameterDeveloperName, List<Id> defaultValue) {
        List<Id> parameterValue = (List<Id>) castParameterValue(parameterDeveloperName, List<Id>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Integer`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Integer` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Integer getInteger(String parameterDeveloperName) {
        return getInteger(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Integer`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Integer` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Integer getInteger(String parameterDeveloperName, Integer defaultValue) {
        Integer parameterValue = (Integer) castParameterValue(parameterDeveloperName, Integer.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Integer>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Integer>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Integer> getIntegerList(String parameterDeveloperName) {
        return getIntegerList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Integer>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Integer>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Integer> getIntegerList(String parameterDeveloperName, List<Integer> defaultValue) {
        List<Integer> parameterValue = (List<Integer>) castParameterValue(parameterDeveloperName, List<Integer>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Long`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `Long` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static Long getLong(String parameterDeveloperName) {
        return getLong(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Long`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Long` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static Long getLong(String parameterDeveloperName, Long defaultValue) {
        Long parameterValue = (Long) castParameterValue(parameterDeveloperName, Long.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Long>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<Long>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<Long> getLongList(String parameterDeveloperName) {
        return getLongList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Long>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Long>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<Long> getLongList(String parameterDeveloperName, List<Long> defaultValue) {
        List<Long> parameterValue = (List<Long>) castParameterValue(parameterDeveloperName, List<Long>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `SObject`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `SObject` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static SObject getSObject(String parameterDeveloperName) {
        return getSObject(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `SObject`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `SObject` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static SObject getSObject(String parameterDeveloperName, SObject defaultValue) {
        SObject parameterValue = (SObject) castParameterValue(parameterDeveloperName, SObject.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<SObject>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<SObject>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<SObject> getSObjectList(String parameterDeveloperName) {
        return getSObjectList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<SObject>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<SObject>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<SObject> getSObjectList(String parameterDeveloperName, List<SObject> defaultValue) {
        List<SObject> parameterValue = (List<SObject>) castParameterValue(parameterDeveloperName, List<SObject>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `String`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `String` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    // Since the Value__c field is a string field, this method is used internally by the other parameter methods
    public static String getString(String parameterDeveloperName) {
        return getString(parameterDeveloperName, null);
    }

    public static String getString(String parameterDeveloperName, String defaultValue) {
        // Since the Value__c field is already a String, this method skips using the method castParameterValue
        String parameterValue = loadParameterValue(parameterDeveloperName);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<String>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
     * @return                        The `List<String>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                When no matching parameter is found null is returned
     */
    public static List<String> getStringList(String parameterDeveloperName) {
        return getStringList(parameterDeveloperName, null);
    }

    public static List<String> getStringList(String parameterDeveloperName, List<String> defaultValue) {
        List<String> parameterValue = (List<String>) castParameterValue(parameterDeveloperName, List<String>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    // Private methods
    @TestVisible
    private static void setMockParameter(LoggerParameter__mdt parameter) {
        mockParameterByDeveloperName.put(parameter.DeveloperName, parameter);
    }

    private static Object castParameterValue(String parameterDeveloperName, Type dataType) {
        String parameterValue = loadParameterValue(parameterDeveloperName);
        if (parameterValue == null) {
            return null;
        } else {
            return JSON.deserialize(parameterValue, dataType);
        }
    }

    private static String loadParameterValue(String parameterDeveloperName) {
        String parameterValue = LoggerParameter__mdt.getInstance(parameterDeveloperName)?.Value__c;

        if (Test.isRunningTest() == true) {
            // During tests, don't actually use the org's CMDT records - only use mock records
            parameterValue = (String) mockParameterByDeveloperName.get(parameterDeveloperName)?.get('Value__c');
        }

        return parameterValue;
    }
}
