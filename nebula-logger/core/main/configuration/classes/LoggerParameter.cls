//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Provides a centralized way to load parameters for SObject handlers & plugins,
 *              and casts the parameters to common data types
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.PropertyNamingConventions')
public class LoggerParameter {
    // During tests, always load this CMDT record
    // so that tests use the same format when calling System.debug()
    private static final String SYSTEM_DEBUG_MESSAGE_FORMAT_PARAMETER = 'SystemDebugMessageFormat';
    private static final Set<String> PARAMETERS_TO_LOAD_DURING_TESTS = new Set<String>{ SYSTEM_DEBUG_MESSAGE_FORMAT_PARAMETER };

    /**
     * @description Indicates if Logger will make an async callout to https://api.status.salesforce.com
     *              to get additional details about the current org, which is then stored on the Log__c record.
     *              Controlled by the custom metadata record LoggerParamer.CallStatusApi, or `false` as the default
     */
    public static final Boolean CALL_STATUS_API {
        get {
            if (CALL_STATUS_API == null) {
                CALL_STATUS_API = getBoolean('CallStatusApi', false);
            }
            return CALL_STATUS_API;
        }
        private set;
    }

    /**
     * @description Indicates if Logger will append its own log entries about the logging system.
     *              Controlled by the custom metadata record LoggerParamer.EnableLoggerSystemMessages, or `false` as the default
     */
    public static final Boolean ENABLE_SYSTEM_MESSAGES {
        get {
            if (ENABLE_SYSTEM_MESSAGES == null) {
                ENABLE_SYSTEM_MESSAGES = getBoolean('EnableLoggerSystemMessages', false);
            }
            return ENABLE_SYSTEM_MESSAGES;
        }
        private set;
    }

    /**
     * @description Indicates if Logger will send an error email notification if any internal exceptions occur.
     *              Controlled by the custom metadata record LoggerParamer.SendErrorEmailNotifications, or `true` as the default
     */
    public static final Boolean SEND_ERROR_EMAIL_NOTIFICATIONS {
        get {
            if (SEND_ERROR_EMAIL_NOTIFICATIONS == null) {
                SEND_ERROR_EMAIL_NOTIFICATIONS = getBoolean('SendErrorEmailNotifications', true);
            }
            return SEND_ERROR_EMAIL_NOTIFICATIONS;
        }
        private set;
    }

    /**
     * @description The merge-field syntax to use when calling System.debug().
     *              Controlled by the custom metadata record LoggerParamer.SystemDebugMessageFormat, or `{OriginLocation__c}\n{Message__c}` as the default
     */
    public static final String SYSTEM_DEBUG_MESSAGE_FORMAT {
        get {
            if (SYSTEM_DEBUG_MESSAGE_FORMAT == null) {
                SYSTEM_DEBUG_MESSAGE_FORMAT = getString(SYSTEM_DEBUG_MESSAGE_FORMAT_PARAMETER, '{OriginLocation__c}\n{Message__c}');
            }
            return SYSTEM_DEBUG_MESSAGE_FORMAT;
        }
        private set;
    }

    /**
     * @description Indicates if Logger's tagging system is enabled.
     *              Controlled by the custom metadata record LoggerParamer.EnableTagging, or `true` as the default
     */
    public static final Boolean TAGGING_IS_ENABLED {
        get {
            if (TAGGING_IS_ENABLED == null) {
                TAGGING_IS_ENABLED = getBoolean('EnableTagging', true);
            }
            return TAGGING_IS_ENABLED;
        }
        private set;
    }

    /**
     * @description Indicates if Logger's tagging will use Topic and TopicAssignment for storing tags, or `false` as the default
     */
    public static final Boolean TAG_USING_TOPICS {
        get {
            if (TAG_USING_TOPICS == null) {
                TAG_USING_TOPICS = getBoolean('UseTopicsForTags', false);
            }
            return TAG_USING_TOPICS;
        }
        private set;
    }

    private static final Map<String, LoggerParameter__mdt> DEVELOPER_NAME_TO_RECORD {
        get {
            if (DEVELOPER_NAME_TO_RECORD == null) {
                DEVELOPER_NAME_TO_RECORD = loadRecords();
            }
            return DEVELOPER_NAME_TO_RECORD;
        }
        private set;
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
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<SObject>` value configured in the matching instance of `LoggerParameter__mdt`
     *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
     */
    public static List<SObject> getSObjectList(String parameterDeveloperName, List<SObject> defaultValue) {
        List<SObject> parameterValue = (List<SObject>) castParameterValue(parameterDeveloperName, List<SObject>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description This method returns the actual parameter if it exists, or if it's empty returns the default value.
     * @param parameterDeveloperName The parameter to return if it exists.
     * @param defaultValue The default value to return when the parameter doesn't exist.
     * @return A string that's retrieved using the parameter if it's not empty, otherwise the string is defaulted to defaultValue.
     */
    public static String getString(String parameterDeveloperName, String defaultValue) {
        // Since the Value__c field is already a String, this method skips using the method castParameterValue
        String parameterValue = loadParameterValue(parameterDeveloperName);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description This method returns the value of the parameter if it exists (cast as a list of strings), or if it's empty returns the default list.
     * @param parameterDeveloperName The parameter of the list to return if it exists.
     * @param defaultValue The default list to return when the parameter / value doesn't exist.
     * @return A list that's retrieved using the parameter if it's not null, otherwise the default list is returned.
     */
    public static List<String> getStringList(String parameterDeveloperName, List<String> defaultValue) {
        List<String> parameterValue = (List<String>) castParameterValue(parameterDeveloperName, List<String>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description matchOnPrefix description
     * @param  developerNamePrefix A prefix that has been used in the `DeveloperName` for multiple `LoggerParameter__mdt` records
     * @return                     The list of matching `LoggerParameter__mdt` records
     */
    public static List<LoggerParameter__mdt> matchOnPrefix(String developerNamePrefix) {
        List<LoggerParameter__mdt> matchingParameters = new List<LoggerParameter__mdt>();
        for (String parameterDeveloperName : DEVELOPER_NAME_TO_RECORD.keySet()) {
            if (parameterDeveloperName.startsWith(developerNamePrefix) == true) {
                matchingParameters.add(DEVELOPER_NAME_TO_RECORD.get(parameterDeveloperName));
            }
        }
        return matchingParameters;
    }

    private static Map<String, LoggerParameter__mdt> loadRecords() {
        Map<String, LoggerParameter__mdt> parameters = LoggerParameter__mdt.getAll().clone();
        if (System.Test.isRunningTest() == true) {
            // Keep a copy of any records that *should* be loaded during tests
            // Currently, only the record `SystemDebugMessageFormat` has a use case for this functionality,
            // but others can be easily added if other use cases are found
            Map<String, LoggerParameter__mdt> parametersToLoadDuringTests = new Map<String, LoggerParameter__mdt>();
            for (String testContextParameterName : PARAMETERS_TO_LOAD_DURING_TESTS) {
                if (parameters.containsKey(testContextParameterName) == true) {
                    parametersToLoadDuringTests.put(testContextParameterName, parameters.get(testContextParameterName));
                }
            }
            parameters.clear();
            parameters.putAll(parametersToLoadDuringTests);
        }
        return parameters;
    }

    @TestVisible
    private static void setMock(LoggerParameter__mdt parameter) {
        if (String.isBlank(parameter.DeveloperName) == true) {
            throw new IllegalArgumentException('DeveloperName is required on `LoggerParameter__mdt: \n' + JSON.serializePretty(parameter));
        }
        DEVELOPER_NAME_TO_RECORD.put(parameter.DeveloperName, parameter);
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
        return DEVELOPER_NAME_TO_RECORD.get(parameterDeveloperName)?.Value__c;
    }
}
