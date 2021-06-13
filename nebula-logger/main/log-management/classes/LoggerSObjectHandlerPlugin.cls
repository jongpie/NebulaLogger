//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used to define custom plugins to run when DML statements occur on `Log__c` or `LogEntry__c`
 */
// TODO: convert to `global` once plugin framework is stable/solidified/ready for the managed package
public abstract class LoggerSObjectHandlerPlugin {
    public abstract void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    );

    protected String getParameterAsString(String parameterDeveloperName) {
        return this.getParameter(parameterDeveloperName)?.Value__c;
    }

    // TODO: uncomment these as a future enhancement
    // protected Blob getParameterAsBlob(String parameterDeveloperName) {
    //     return Blob.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Boolean getParameterAsBoolean(String parameterDeveloperName) {
    //     return Boolean.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Date getParameterAsDate(String parameterDeveloperName) {
    //     return Date.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Datetime getParameterAsDatetime(String parameterDeveloperName) {
    //     return Datetime.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Decimal getParameterAsDecimal(String parameterDeveloperName) {
    //     return Decimal.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Double getParameterAsDouble(String parameterDeveloperName) {
    //     return Double.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Id getParameterAsId(String parameterDeveloperName) {
    //     return Id.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Integer getParameterAsInteger(String parameterDeveloperName) {
    //     return Integer.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Long getParameterAsLong(String parameterDeveloperName) {
    //     return Long.valueOf(this.getParameterAsString(parameterDeveloperName));
    // }

    // protected Object getParameterAsObject(String parameterDeveloperName) {
    //     return (Object) this.getParameterAsString(parameterDeveloperName);
    // }

    // protected SObject getParameterAsSObject(String parameterDeveloperName) {
    //     return (SObject) JSON.deserialize(this.getParameterAsString(parameterDeveloperName), SObject.class);
    // }

    private LoggerSObjectHandlerPluginParameter__mdt getParameter(String parameterDeveloperName) {
        LoggerSObjectHandlerPluginParameter__mdt parameter = LoggerSObjectHandlerPluginParameter__mdt.getInstance(parameterDeveloperName);

        if (parameter == null || parameter.IsEnabled__c == false) {
            return null;
        }

        return parameter;
    }
}
