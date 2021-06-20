//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugin Framework
 * @description Provides a centralized way to load CMDT parameters for SObject handlers & plugins,
 *              and casts the parameters to common data types
 */
public class LoggerParameter {
    // Static stuff
    @testVisible
    private Map<String, String> mockParameterValueByDeveloperName = new Map<String, String>();


    /**
     * @description An instance of `LoggerParameter` that loads SObject Handler parameters from the object `LoggerSObjectHandlerParameter__mdt`
     */
    public static LoggerParameter Handler {
        get {
            if (Handler == null) {
                Handler = new LoggerParameter(Schema.LoggerSObjectHandlerParameter__mdt.SObjectType);
            }
            return Handler;
        }
        set;
    }

    /**
     * @description An instance of `LoggerParameter` that loads SObject Handler Plugin parameters from the object `LoggerSObjectHandlerPluginParameter__mdt`
     */
    public static LoggerParameter Plugin {
        get {
            if (Plugin == null) {
                Plugin = new LoggerParameter(Schema.LoggerSObjectHandlerPluginParameter__mdt.SObjectType);
            }
            return Plugin;
        }
        set;
    }
    /**
     * @description Creates an instance of `LoggerParameter` that can load parameters from `LoggerSObjectHandlerParameter__mdt`
     * @return    An instance of `LoggerParameter` for the `LoggerSObjectHandlerParameter__mdt` CMDT object
     */
    public static LoggerParameter getHandlerInstance() {
        return new LoggerParameter(Schema.LoggerSObjectHandlerParameter__mdt.SObjectType);
    }

    /**
     * @description Creates an instance of `LoggerParameter` that can load parameters from `LoggerSObjectHandlerPluginParameter__mdt`
     * @return    An instance of `LoggerParameter` for the `LoggerSObjectHandlerPluginParameter__mdt` CMDT object
     */
    public static LoggerParameter getPluginInstance() {
        return new LoggerParameter(Schema.LoggerSObjectHandlerPluginParameter__mdt.SObjectType);
    }

    // Instance stuff
    private SObjectType configurationSObjectType;

    private LoggerParameter(Schema.SObjectType configurationSObjectType) {
        this.configurationSObjectType = configurationSObjectType;
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Boolean`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Boolean` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Boolean getBoolean(String parameterDeveloperName) {
        return (Boolean) this.castParameterValue(parameterDeveloperName, Boolean.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Boolean>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Boolean>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Boolean> getBooleanList(String parameterDeveloperName) {
        return (List<Boolean>) this.castParameterValue(parameterDeveloperName, List<Boolean>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Date`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Date` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Date getDate(String parameterDeveloperName) {
        return (Date) this.castParameterValue(parameterDeveloperName, Date.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Date>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Date>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Date> getDateList(String parameterDeveloperName) {
        return (List<Date>) this.castParameterValue(parameterDeveloperName, List<Date>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Datetime`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Datetime` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Datetime getDatetime(String parameterDeveloperName) {
        return (Datetime) this.castParameterValue(parameterDeveloperName, Datetime.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Datetime>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Datetime>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Datetime> getDatetimeList(String parameterDeveloperName) {
        return (List<Datetime>) this.castParameterValue(parameterDeveloperName, List<Datetime>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Decimal`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Decimal` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Decimal getDecimal(String parameterDeveloperName) {
        return (Decimal) this.castParameterValue(parameterDeveloperName, Decimal.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Decimal>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Decimal>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Decimal> getDecimalList(String parameterDeveloperName) {
        return (List<Decimal>) this.castParameterValue(parameterDeveloperName, List<Decimal>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Double`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Double` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Double getDouble(String parameterDeveloperName) {
        return (Double) this.castParameterValue(parameterDeveloperName, Double.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Double>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Double>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Double> getDoubleList(String parameterDeveloperName) {
        return (List<Double>) this.castParameterValue(parameterDeveloperName, List<Double>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Id`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Id` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Id getId(String parameterDeveloperName) {
        return (Id) this.getString(parameterDeveloperName);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Id>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Id>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Id> getIdList(String parameterDeveloperName) {
        return (List<Id>) this.castParameterValue(parameterDeveloperName, List<Id>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Integer`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Integer` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Integer getInteger(String parameterDeveloperName) {
        return (Integer) this.castParameterValue(parameterDeveloperName, Integer.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Integer>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Integer>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Integer> getIntegerList(String parameterDeveloperName) {
        return (List<Integer>) this.castParameterValue(parameterDeveloperName, List<Integer>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `Long`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Long` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Long getLong(String parameterDeveloperName) {
        return (Long) this.castParameterValue(parameterDeveloperName, Long.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<Long>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Long>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Long> getLongList(String parameterDeveloperName) {
        return (List<Long>) this.castParameterValue(parameterDeveloperName, List<Long>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as an `Object`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `Object` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public Object getObject(String parameterDeveloperName) {
        return (Object) this.getString(parameterDeveloperName);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as an `List<Object>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<Object>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<Object> getObjectList(String parameterDeveloperName) {
        return (List<Object>) this.castParameterValue(parameterDeveloperName, List<Object>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `SObject`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `SObject` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public SObject getSObject(String parameterDeveloperName) {
        return (SObject) this.castParameterValue(parameterDeveloperName, SObject.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<SObject>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<SObject>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<SObject> getSObjectList(String parameterDeveloperName) {
        return (List<SObject>) this.castParameterValue(parameterDeveloperName, List<SObject>.class);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `String`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `String` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    // Since the Value__c field is a string field, this method is used internally by the other parameter methods
    public String getString(String parameterDeveloperName) {
        return this.loadParameterValue(parameterDeveloperName);
    }

    /**
     * @description Returns the configured value of the field `LoggerSObjectHandlerPluginParameter__mdt.Value__c` as a `List<String>`
     * @param  parameterDeveloperName The developer name of the instance of `LoggerSObjectHandlerPluginParameter__mdt`
     * @return                        The `List<String>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter__mdt`,
     *                                or null when not found or disabled
     */
    public List<String> getStringList(String parameterDeveloperName) {
        return (List<String>) this.castParameterValue(parameterDeveloperName, List<String>.class);
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
            parameterValue = mockParameterValueByDeveloperName.get(parameterDeveloperName);
        }

        return parameterValue;
    }
}
