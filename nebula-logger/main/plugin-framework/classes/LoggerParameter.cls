//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugin Framework
 * @description Provides a centralized way to load CMDT parameters for SObject handlers & plugins,
 *              and casts the parameters to common data types
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.ExcessivePublicCount')
public class LoggerParameter {
    private SObjectType configurationSObjectType;
    private Map<String, SObject> mockParameterByDeveloperName = new Map<String, SObject>();

    /**
     * @description An instance of `LoggerParameter` that loads SObject Handler parameters from the object `LoggerSObjectHandlerParameter__mdt`
     */
    public static LoggerParameter handler {
        get {
            if (handler == null) {
                handler = new LoggerParameter(Schema.LoggerSObjectHandlerParameter__mdt.SObjectType);
            }
            return handler;
        }
        set;
    }

    /**
     * @description An instance of `LoggerParameter` that loads SObject Handler Plugin parameters from the object `LoggerSObjectHandlerPluginParameter__mdt`
     */
    public static LoggerParameter plugin {
        get {
            if (plugin == null) {
                plugin = new LoggerParameter(Schema.LoggerSObjectHandlerPluginParameter__mdt.SObjectType);
            }
            return plugin;
        }
        set;
    }

    private LoggerParameter(Schema.SObjectType configurationSObjectType) {
        this.configurationSObjectType = configurationSObjectType;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Boolean`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Boolean` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Boolean getBoolean(String parameterDeveloperName) {
        return this.getBoolean(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Boolean`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Boolean` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Boolean getBoolean(String parameterDeveloperName, Boolean defaultValue) {
        Boolean parameterValue = (Boolean) this.castParameterValue(parameterDeveloperName, Boolean.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Boolean>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Boolean>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Boolean> getBooleanList(String parameterDeveloperName) {
        return this.getBooleanList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Boolean>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Boolean>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Boolean> getBooleanList(String parameterDeveloperName, List<Boolean> defaultValue) {
        List<Boolean> parameterValue = (List<Boolean>) this.castParameterValue(parameterDeveloperName, List<Boolean>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Date`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Date` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Date getDate(String parameterDeveloperName) {
        return this.getDate(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Date`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Date` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Date getDate(String parameterDeveloperName, Date defaultValue) {
        Date parameterValue = (Date) this.castParameterValue(parameterDeveloperName, Date.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Date>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Date>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Date> getDateList(String parameterDeveloperName) {
        return this.getDateList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Date>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Date>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Date> getDateList(String parameterDeveloperName, List<Date> defaultValue) {
        List<Date> parameterValue = (List<Date>) this.castParameterValue(parameterDeveloperName, List<Date>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Datetime`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Datetime` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Datetime getDatetime(String parameterDeveloperName) {
        return this.getDatetime(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Datetime`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Datetime` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Datetime getDatetime(String parameterDeveloperName, Datetime defaultValue) {
        Datetime parameterValue = (Datetime) this.castParameterValue(parameterDeveloperName, Datetime.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Datetime>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Datetime>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Datetime> getDatetimeList(String parameterDeveloperName) {
        return this.getDatetimeList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Datetime>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Datetime>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Datetime> getDatetimeList(String parameterDeveloperName, List<Datetime> defaultValue) {
        List<Datetime> parameterValue = (List<Datetime>) this.castParameterValue(parameterDeveloperName, List<Datetime>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Decimal`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Decimal` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Decimal getDecimal(String parameterDeveloperName) {
        return this.getDecimal(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Decimal`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Decimal` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Decimal getDecimal(String parameterDeveloperName, Decimal defaultValue) {
        Decimal parameterValue = (Decimal) this.castParameterValue(parameterDeveloperName, Decimal.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Decimal>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Decimal>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Decimal> getDecimalList(String parameterDeveloperName) {
        return this.getDecimalList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Decimal>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Decimal>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Decimal> getDecimalList(String parameterDeveloperName, List<Decimal> defaultValue) {
        List<Decimal> parameterValue = (List<Decimal>) this.castParameterValue(parameterDeveloperName, List<Decimal>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Double`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Double` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Double getDouble(String parameterDeveloperName) {
        return this.getDouble(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Double`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Double` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Double getDouble(String parameterDeveloperName, Double defaultValue) {
        Double parameterValue = (Double) this.castParameterValue(parameterDeveloperName, Double.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Double>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Double>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Double> getDoubleList(String parameterDeveloperName) {
        return this.getDoubleList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Double>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Double>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Double> getDoubleList(String parameterDeveloperName, List<Double> defaultValue) {
        List<Double> parameterValue = (List<Double>) this.castParameterValue(parameterDeveloperName, List<Double>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Id`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Id` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Id getId(String parameterDeveloperName) {
        return this.getId(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Id`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Id` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Id getId(String parameterDeveloperName, Id defaultValue) {
        Id parameterValue = (Id) this.castParameterValue(parameterDeveloperName, Id.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Id>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Id>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Id> getIdList(String parameterDeveloperName) {
        return this.getIdList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Id>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Id>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Id> getIdList(String parameterDeveloperName, List<Id> defaultValue) {
        List<Id> parameterValue = (List<Id>) this.castParameterValue(parameterDeveloperName, List<Id>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Integer`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Integer` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Integer getInteger(String parameterDeveloperName) {
        return this.getInteger(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Integer`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Integer` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Integer getInteger(String parameterDeveloperName, Integer defaultValue) {
        Integer parameterValue = (Integer) this.castParameterValue(parameterDeveloperName, Integer.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Integer>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Integer>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Integer> getIntegerList(String parameterDeveloperName) {
        return this.getIntegerList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Integer>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Integer>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Integer> getIntegerList(String parameterDeveloperName, List<Integer> defaultValue) {
        List<Integer> parameterValue = (List<Integer>) this.castParameterValue(parameterDeveloperName, List<Integer>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Long`
     * @param parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Long` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public Long getLong(String parameterDeveloperName) {
        return this.getLong(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `Long`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `Long` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public Long getLong(String parameterDeveloperName, Long defaultValue) {
        Long parameterValue = (Long) this.castParameterValue(parameterDeveloperName, Long.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Long>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Long>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<Long> getLongList(String parameterDeveloperName) {
        return this.getLongList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<Long>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<Long>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<Long> getLongList(String parameterDeveloperName, List<Long> defaultValue) {
        List<Long> parameterValue = (List<Long>) this.castParameterValue(parameterDeveloperName, List<Long>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `SObject`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `SObject` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public SObject getSObject(String parameterDeveloperName) {
        return this.getSObject(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `SObject`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `SObject` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public SObject getSObject(String parameterDeveloperName, SObject defaultValue) {
        SObject parameterValue = (SObject) this.castParameterValue(parameterDeveloperName, SObject.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<SObject>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<SObject>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<SObject> getSObjectList(String parameterDeveloperName) {
        return this.getSObjectList(parameterDeveloperName, null);
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<SObject>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @param  defaultValue           A default value to return instead of null
     * @return                        The `List<SObject>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin)
     *                                Returns the supplied `defaultValue` when no matching parameter is found, the parameter is disabled, or the parameter value is null
     */
    public List<SObject> getSObjectList(String parameterDeveloperName, List<SObject> defaultValue) {
        List<SObject> parameterValue = (List<SObject>) this.castParameterValue(parameterDeveloperName, List<SObject>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `String`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `String` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    // Since the Value__c field is a string field, this method is used internally by the other parameter methods
    public String getString(String parameterDeveloperName) {
        return this.getString(parameterDeveloperName, null);
    }

    /**
     * @description This method returns the actual parameter if it exists, or if it's empty returns the default value.
     * @param parameterDeveloperName The parameter to return if it exists.
     * @param defaultValue The default value to return when the parameter doesn't exist.
     * @return A string that's retrieved using the parameter if it's not empty, otherwise the string is defaulted to defaultValue.
     */
    public String getString(String parameterDeveloperName, String defaultValue) {
        // Since the Value__c field is already a String, this method skips using the method castParameterValue
        String parameterValue = this.loadParameterValue(parameterDeveloperName);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    /**
     * @description Returns the configured value of the field `Value__c` as a `List<String>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<String>` value configured in the matching instance of either `LoggerSObjectHandlerParameter__mdt` (for LoggerParameter.Handler)
     *                                or `LoggerSObjectHandlerPluginParameter__mdt` (for LoggerParameter.Plugin).
     *                                When no matching parameter is found, or the parameter is disabled, null is returned
     */
    public List<String> getStringList(String parameterDeveloperName) {
        return this.getStringList(parameterDeveloperName, null);
    }

    /**
     * @description This method returns the value of the parameter if it exists (cast as a list of strings), or if it's empty returns the default list.
     * @param parameterDeveloperName The parameter of the list to return if it exists.
     * @param defaultValue The default list to return when the parameter / value doesn't exist.
     * @return A list that's retrieved using the parameter if it's not null, otherwise the default list is returned.
     */
    public List<String> getStringList(String parameterDeveloperName, List<String> defaultValue) {
        List<String> parameterValue = (List<String>) this.castParameterValue(parameterDeveloperName, List<String>.class);
        return parameterValue != null ? parameterValue : defaultValue;
    }

    // Private testVisible methods
    @TestVisible
    private void setMockParameter(LoggerSObjectHandlerParameter__mdt parameter) {
        this.mockParameterByDeveloperName.put(parameter.DeveloperName, parameter);
    }

    @TestVisible
    private void setMockParameter(LoggerSObjectHandlerPluginParameter__mdt parameter) {
        this.mockParameterByDeveloperName.put(parameter.DeveloperName, parameter);
    }

    // Private methods
    private Object castParameterValue(String parameterDeveloperName, Type dataType) {
        String parameterValue = this.loadParameterValue(parameterDeveloperName);
        if (parameterValue == null) {
            return null;
        } else {
            return JSON.deserialize(parameterValue, dataType);
        }
    }

    private String loadParameterValue(String parameterDeveloperName) {
        String parameterValue;

        switch on this.configurationSObjectType.newSObject() {
            when LoggerSObjectHandlerParameter__mdt handlerParam {
                LoggerSObjectHandlerParameter__mdt handlerParameter = LoggerSObjectHandlerParameter__mdt.getInstance(parameterDeveloperName);
                if (handlerParameter != null && handlerParameter.IsEnabled__c == true) {
                    parameterValue = handlerParameter.Value__c;
                }
            }
            when LoggerSObjectHandlerPluginParameter__mdt pluginParam {
                LoggerSObjectHandlerPluginParameter__mdt pluginParameter = LoggerSObjectHandlerPluginParameter__mdt.getInstance(parameterDeveloperName);
                if (pluginParameter != null && pluginParameter.IsEnabled__c == true) {
                    parameterValue = pluginParameter.Value__c;
                }
            }
        }

        if (Test.isRunningTest() == true) {
            // During tests, don't actually use the org's CMDT records - only use mock records
            parameterValue = (String) mockParameterByDeveloperName.get(parameterDeveloperName)?.get('Value__c');
        }

        return parameterValue;
    }
}
