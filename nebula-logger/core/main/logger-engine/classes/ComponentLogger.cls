//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Controller class used by the lightning web component `logger`
 * @see Logger
 * @see LogEntryEventBuilder
 */
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity')
public inherited sharing class ComponentLogger {
    @TestVisible
    private static final String LOGGER_COMPONENT_NAME {
        get {
            if (LOGGER_COMPONENT_NAME == null) {
                String namespace = String.isNotBlank(Logger.getNamespacePrefix()) ? Logger.getNamespacePrefix() : 'c';
                LOGGER_COMPONENT_NAME = namespace + '/logger';
            }
            return LOGGER_COMPONENT_NAME;
        }
        set;
    }

    static {
        LoggerStackTrace.ignoreOrigin(ComponentLogger.class);
        LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, LOGGER_COMPONENT_NAME);
    }

    /**
     * @description Provides data to the frontend about `LoggerSettings__c` & server-supported logging details
     * @return   return The instance of `ComponentLoggerSettings` for the current user
     */
    @AuraEnabled(cacheable=true)
    public static ComponentLoggerSettings getSettings() {
        return new ComponentLoggerSettings();
    }

    /**
     * @description saveComponentLogEntries Saves log entries created via lwc or aura components
     * @param  componentLogEntries The list of `ComponentLogEntry` objects to save via `Logger`
     * @param  saveMethodName      String name of the instance of Logger.SaveMethod to use when saving.
     *                             When null, the value of `Logger.getSaveMethod()` will be used.
     * @return                     return The transaction ID (based on `Logger.getTransactionId())`
     */
    @AuraEnabled
    public static String saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries, String saveMethodName) {
        try {
            Logger.SaveMethod saveMethod = Logger.getSaveMethod();
            for (ComponentLogEntry componentLogEntry : componentLogEntries) {
                Logger.setScenario(componentLogEntry.scenario);
                System.LoggingLevel entryLoggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevel);
                LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(entryLoggingLevel, componentLogEntry.message).addTags(componentLogEntry.tags);
                LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();

                if (componentLogEntry.recordId != null) {
                    logEntryEventBuilder.setRecord(componentLogEntry.recordId).getLogEntryEvent();
                }
                if (componentLogEntry.record != null) {
                    logEntryEventBuilder.setRecord(componentLogEntry.record).getLogEntryEvent();
                }

                logEntryEventBuilder.setTimestamp(componentLogEntry.timestamp);
                setBrowserDetails(logEntryEvent, componentLogEntry);
                setComponentErrorDetails(logEntryEvent, componentLogEntry.error);
                setOriginStackTraceDetails(logEntryEvent, componentLogEntry.stack);
            }
            if (String.isNotBlank(saveMethodName)) {
                saveMethod = Logger.SaveMethod.valueOf(saveMethodName);
            }
            Logger.saveLog(saveMethod);
            return Logger.getTransactionId();
        } catch (System.Exception apexException) {
            String errorMessage = apexException.getMessage() + '\n' + apexException.getStackTraceString();
            System.AuraHandledException auraException = new System.AuraHandledException(errorMessage);
            auraException.setMessage(errorMessage);
            throw auraException;
        }
    }

    private static void setBrowserDetails(LogEntryEvent__e logEntryEvent, ComponentLogEntry componentLogEntry) {
        logEntryEvent.BrowserAddress__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.BrowserAddress__c, componentLogEntry.browserAddress);
        logEntryEvent.BrowserFormFactor__c = LoggerDataStore.truncateFieldValue(
            Schema.LogEntryEvent__e.BrowserFormFactor__c,
            componentLogEntry.browserFormFactor
        );
        logEntryEvent.BrowserLanguage__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.BrowserLanguage__c, componentLogEntry.browserLanguage);
        logEntryEvent.BrowserScreenResolution__c = LoggerDataStore.truncateFieldValue(
            Schema.LogEntryEvent__e.BrowserScreenResolution__c,
            componentLogEntry.browserScreenResolution
        );
        // TODO BrowserUrl__c is deprecated (replaced by BrowserAddress__c), but keep setting BrowserUrl__c for now so people have time to migrate to referencing BrowserAddress__c
        logEntryEvent.BrowserUrl__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.BrowserUrl__c, componentLogEntry.browserAddress);
        logEntryEvent.BrowserUserAgent__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.BrowserUserAgent__c, componentLogEntry.browserUserAgent);
        logEntryEvent.BrowserWindowResolution__c = LoggerDataStore.truncateFieldValue(
            Schema.LogEntryEvent__e.BrowserWindowResolution__c,
            componentLogEntry.browserWindowResolution
        );
    }

    private static void setComponentErrorDetails(LogEntryEvent__e logEntryEvent, ComponentError componentError) {
        if (componentError == null) {
            return;
        }

        logEntryEvent.ExceptionMessage__c = componentError.message;
        logEntryEvent.ExceptionType__c = componentError.type;

        LoggerStackTrace.SourceLanguage language = LoggerStackTrace.SourceLanguage.JavaScript;
        // All exception classes in Apex must end in 'Exception'
        if (componentError.type?.endsWith('Exception') == true) {
            language = LoggerStackTrace.SourceLanguage.Apex;
        }
        LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(language, componentError.stack);
        logEntryEvent.ExceptionLocation__c = exceptionStackTrace.Location;
        logEntryEvent.ExceptionSourceActionName__c = exceptionStackTrace.Source?.ActionName;
        logEntryEvent.ExceptionSourceApiName__c = exceptionStackTrace.Source?.ApiName;
        logEntryEvent.ExceptionSourceMetadataType__c = exceptionStackTrace.Source?.MetadataType.name();
        logEntryEvent.ExceptionStackTrace__c = LoggerDataStore.truncateFieldValue(
            Schema.LogEntryEvent__e.ExceptionStackTrace__c,
            exceptionStackTrace.ParsedStackTraceString
        );
    }

    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
    private static void setOriginStackTraceDetails(LogEntryEvent__e logEntryEvent, String stackTraceString) {
        LoggerStackTrace originStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, stackTraceString);

        // Older, custom convention used for a 'type', with values 'Aura' and 'LWC'
        String componentType;
        if (originStackTrace.Source?.MetadataType == LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle) {
            componentType = 'Aura';
        } else if (originStackTrace.Source?.MetadataType == LoggerStackTrace.SourceMetadataType.LightningComponentBundle) {
            componentType = 'LWC';
        }

        // Legacy fields (OriginType__c is considered legacy, even though it uses the 'Origin' prefix)
        logEntryEvent.ComponentType__c = componentType;
        logEntryEvent.OriginType__c = 'Component';

        // New Origin fields
        logEntryEvent.OriginLocation__c = originStackTrace.Location;
        logEntryEvent.StackTrace__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.StackTrace__c, originStackTrace.ParsedStackTraceString);
        // logEntryEvent.StackTrace__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.StackTrace__c, stackTraceString);
        if (originStackTrace.Source != null) {
            logEntryEvent.OriginSourceActionName__c = originStackTrace.Source.ActionName;
            logEntryEvent.OriginSourceMetadataType__c = originStackTrace.Source.MetadataType.name();
            logEntryEvent.OriginSourceApiName__c = originStackTrace.Source.ApiName;
        }
    }

    /**
     * @description A DTO object used for passing `LoggerSettings__c` details to lightning components
     */
    public class ComponentLoggerSettings {
        /**
         * @description Indicates the save method that will be used by default if no other save method is specified, based on `LoggerSettings__c.DefaultSaveMethod__c`
         */
        @AuraEnabled
        public String defaultSaveMethodName { get; set; }

        /**
         * @description Indicates if logging is enabled for the current user, based on `LoggerSettings__c.IsEnabled__c`
         */
        @AuraEnabled
        public Boolean isEnabled { get; set; }

        /**
         * @description Indicates if logging via the browser's `console.log()` is enabled for the current user, based on `Logger.IsJavaScriptConsoleLoggingEnabled__c`
         */
        @AuraEnabled
        public Boolean isConsoleLoggingEnabled { get; set; }

        /**
         * @description A map of the supported `LoggingLevel` enum values
         */
        @AuraEnabled
        public Map<String, Integer> supportedLoggingLevels { get; set; }

        /**
         * @description The configured `LoggingLevel` for the current user, based on `LoggerSettings__c.LoggingLevel__c`
         */
        @AuraEnabled
        public ComponentLoggingLevel userLoggingLevel { get; set; }

        private ComponentLoggerSettings() {
            this.defaultSaveMethodName = Logger.getSaveMethod().name();
            this.isEnabled = Logger.getUserSettings().IsEnabled__c;
            this.isConsoleLoggingEnabled = Logger.getUserSettings().IsJavaScriptConsoleLoggingEnabled__c;
            this.supportedLoggingLevels = getSupportedLoggingLevels();
            this.userLoggingLevel = getUserLoggingLevel();
        }

        private Map<String, Integer> getSupportedLoggingLevels() {
            return new Map<String, Integer>{
                System.LoggingLevel.ERROR.name() => System.LoggingLevel.ERROR.ordinal(),
                System.LoggingLevel.WARN.name() => System.LoggingLevel.WARN.ordinal(),
                System.LoggingLevel.INFO.name() => System.LoggingLevel.INFO.ordinal(),
                System.LoggingLevel.DEBUG.name() => System.LoggingLevel.DEBUG.ordinal(),
                System.LoggingLevel.FINE.name() => System.LoggingLevel.FINE.ordinal(),
                System.LoggingLevel.FINER.name() => System.LoggingLevel.FINER.ordinal(),
                System.LoggingLevel.FINEST.name() => System.LoggingLevel.FINEST.ordinal()
            };
        }

        private ComponentLoggingLevel getUserLoggingLevel() {
            return new ComponentLoggingLevel(Logger.getUserLoggingLevel());
        }
    }

    /**
     * @description A DTO object used for passing `LoggingLevel` details to lightning components
     */
    public class ComponentLoggingLevel {
        /**
         * @description The name of the `LoggingLevel` enum value
         */
        @AuraEnabled
        public String name { get; set; }

        /**
         * @description The ordinal of the `LoggingLevel` enum value
         */
        @AuraEnabled
        public Integer ordinal { get; set; }

        private ComponentLoggingLevel(System.LoggingLevel loggingLevel) {
            this.name = loggingLevel.name();
            this.ordinal = loggingLevel.ordinal();
        }
    }

    /**
     * @description A DTO object used to create log entries for lightning components
     */
    public class ComponentLogEntry {
        /**
         * @description The URL displayed in the user's browser
         */
        @AuraEnabled
        public String browserAddress { get; set; }

        /**
         * @description The form factor of the user's browser
         */
        @AuraEnabled
        public String browserFormFactor { get; set; }

        /**
         * @description The language set in the user's browser
         */
        @AuraEnabled
        public String browserLanguage { get; set; }

        /**
         * @description The resolution of the user's device
         */
        @AuraEnabled
        public String browserScreenResolution { get; set; }

        /**
         * @description DEPRECATED: Use `browserAddress` instead
         */
        @AuraEnabled
        public String browserUrl { get; set; }

        /**
         * @description The user agent of the user's browser
         */
        @AuraEnabled
        public String browserUserAgent { get; set; }

        /**
         * @description The resolution of the user's browser window
         */
        @AuraEnabled
        public String browserWindowResolution { get; set; }

        /**
         * @description The name of the `LoggingLevel` enum value
         */
        @AuraEnabled
        public String loggingLevel { get; set; }

        /**
         * @description The value to use as the log entry's message
         */
        @AuraEnabled
        public String message { get; set; }

        /**
         * @description (Optional) The record ID to relate to the log entry
         */
        @AuraEnabled
        public Id recordId { get; set; }

        /**
         * @description (Optional) The record to relate to the log entry - the record's JSON is also stored
         */
        @AuraEnabled
        public SObject record { get; set; }

        /**
         * @description Optionally specify the name to use for the current transaction's scenario
         */
        @AuraEnabled
        public String scenario { get; set; }

        /**
         * @description The JavaScript stack trace from when the log entry was created
         */
        @AuraEnabled
        public String stack { get; set; }

        /**
         * @description The datetime that the log entry was created in the lightning component
         */
        @AuraEnabled
        public Datetime timestamp { get; set; }

        /**
         * @description (Optional) A JavaScript Error to log
         */
        @AuraEnabled
        public ComponentError error { get; set; }

        /**
         * @description (Optional) A list of tags to associate with the log entry
         */
        @AuraEnabled
        public List<String> tags { get; set; }
    }

    /**
     * @description A DTO object used to log details about a JavaScript error
     */
    public class ComponentError {
        /**
         * @description The error's message
         */
        @AuraEnabled
        public String message { get; set; }

        /**
         * @description The error's stack trace
         */
        @AuraEnabled
        public String stack { get; set; }

        /**
         * @description The type of JavaScript error
         */
        @AuraEnabled
        public String type { get; set; }
    }
}
