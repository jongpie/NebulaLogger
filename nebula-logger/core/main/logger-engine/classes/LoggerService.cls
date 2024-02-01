//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description The core class for logging
 * @see LogEntryEventBuilder
 * @see LogMessage
 */
@SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.ExcessivePublicCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity'
)
global without sharing virtual class LoggerService {
    private static Boolean suspendSaving = false;
    private static String lastSaveMethodNameUsed;
    private static Integer saveLogCallCount = 0;

    @TestVisible
    private static LoggerService instance {
        get {
            if (instance == null) {
                instance = new LoggerService();
            }
            return instance;
        }
        set;
    }

    // TODO decide if these should be `public`, `protected`, or replaced with public methods
    // For now, they're `public` for quick dev + fewer LOC
    public final AsyncContextManager asyncContextManager = new AsyncContextManager();
    public final EnvironmentManager environmentManager = new EnvironmentManager();
    public final SettingsManager settingsManager = new SettingsManager();
    public final StatusApiClient statusApiClient = new StatusApiClient();
    public final TransactionContextManager transactionContextManager = new TransactionContextManager();

    public final EntryBuilderManager entryBuilderManager;
    public final ScenarioManager scenarioManager;
    public final SaveManager saveManager;

    public static LoggerService getInstance() {
        return instance;
    }

    global LoggerService() {
        // TODO not my favorite approach, need to decide how to best have the managers talk to each other
        this.saveManager = new SaveManager(this.settingsManager, this.entryBuilderManager);
        this.scenarioManager = new ScenarioManager(this.settingsManager);

        this.entryBuilderManager = new EntryBuilderManager()
            .setAsyncContextManager(this.asyncContextManager)
            .setEnvironmentManager(this.environmentManager)
            .setScenarioManager(this.scenarioManager)
            .setSettingsManager(this.settingsManager)
            .setTransactionContextManager(this.transactionContextManager);
    }

    /* The inner classes below are each responsible for managing or representing a piece of Nebula Logger's functionality */

    // Inner class for tracking details about the current transaction's async context
    @SuppressWarnings('PMD.ApexDoc')
    public class AsyncContext {
        public final String type;
        public final String parentJobId;
        public final String childJobId;
        public final String triggerId;

        public AsyncContext(Database.BatchableContext batchableContext) {
            this.childJobId = batchableContext?.getChildJobId();
            this.parentJobId = batchableContext?.getJobId();
            this.type = Database.BatchableContext.class.getName();
        }

        public AsyncContext(System.FinalizerContext finalizerContext) {
            this.parentJobId = finalizerContext?.getAsyncApexJobId();
            this.type = System.FinalizerContext.class.getName();
        }

        public AsyncContext(System.QueueableContext queueableContext) {
            this.parentJobId = queueableContext?.getJobId();
            this.type = System.QueueableContext.class.getName();
        }

        public AsyncContext(System.SchedulableContext schedulableContext) {
            this.triggerId = schedulableContext?.getTriggerId();
            this.type = System.SchedulableContext.class.getName();
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class AsyncContextManager {
        private AsyncContext currentAsyncContext;

        public AsyncContext getCurrentAsyncContext() {
            return this.currentAsyncContext;
        }

        public void setCurrentAsyncContext(Database.BatchableContext batchableContext) {
            this.setCurrentAsyncContext(new AsyncContext(batchableContext));
        }

        public void setCurrentAsyncContext(System.FinalizerContext finalizerContext) {
            this.setCurrentAsyncContext(new AsyncContext(finalizerContext));
        }

        public void setCurrentAsyncContext(System.QueueableContext queueableContext) {
            this.setCurrentAsyncContext(new AsyncContext(queueableContext));
        }

        public void setCurrentAsyncContext(System.SchedulableContext schedulableContext) {
            this.setCurrentAsyncContext(new AsyncContext(schedulableContext));
        }

        public void setCurrentAsyncContext(AsyncContext asyncContext) {
            this.currentAsyncContext = asyncContext;
            System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Async Context: ' + JSON.serializePretty(asyncContext));
        }

    }

    @SuppressWarnings('PMD.ApexDoc')
    public virtual class EntryBuilderManager {
        private final Set<String> ignoredApexClassOrigins = new Set<String>();
        private final List<LogEntryEventBuilder> pendingLogEntryBuilders = new List<LogEntryEventBuilder>();

        private AsyncContextManager asyncContextManager;
        private ScenarioManager scenarioManager;
        private SettingsManager settingsManager;
        private EnvironmentManager environmentManager;
        private TransactionContextManager transactionContextManager;

        private Integer currentTransactionEntryNumber = 1;

        public EntryBuilderManager setEnvironmentManager(EnvironmentManager environmentManager) {
            this.environmentManager = environmentManager;
            return this;
        }

        public EntryBuilderManager setAsyncContextManager(AsyncContextManager asyncContextManager) {
            this.asyncContextManager = asyncContextManager;
            return this;
        }

        public EntryBuilderManager setScenarioManager(ScenarioManager scenarioManager) {
            this.scenarioManager = scenarioManager;
            return this;
        }

        public EntryBuilderManager setSettingsManager(SettingsManager settingsManager) {
            this.settingsManager = settingsManager;
            return this;
        }

        public EntryBuilderManager setTransactionContextManager(TransactionContextManager transactionContextManager) {
            this.transactionContextManager = transactionContextManager;
            return this;
        }


        public List<LogEntryEventBuilder> getBuffer() {
            return this.pendingLogEntryBuilders;
        }

        public virtual void flushBuffer() {
            this.pendingLogEntryBuilders.clear();
        }

        public void ignoreOrigin(System.Type apexType) {
            if (apexType != null) {
                this.ignoredApexClassOrigins.add(apexType.getName());
            }
        }

        public LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel) {
            Boolean shouldSave = this.settingsManager.meetsUserLoggingLevel(loggingLevel);
            return this.newEntry(loggingLevel, shouldSave);
        }

        public LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, Boolean shouldSave) {
            LogEntryEventBuilder logEntryEventBuilder = new LogEntryEventBuilder(this.settingsManager.getUserSettings(), loggingLevel, shouldSave, this.ignoredApexClassOrigins);
            if (logEntryEventBuilder.shouldSave()) {
                LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
                logEntryEvent.ApiVersion__c = this.environmentManager.organizationApiVersion;
                logEntryEvent.EntryScenario__c = this.scenarioManager.getCurrentEntryScenario();
                logEntryEvent.LoggerVersionNumber__c = this.environmentManager.serviceVersionNumber;
                logEntryEvent.OrganizationApiVersion__c = this.environmentManager.organizationApiVersion;
                logEntryEvent.OrganizationDomainUrl__c = this.environmentManager.organizationDomainUrl;
                logEntryEvent.RequestId__c = this.transactionContextManager.requestId;
                logEntryEvent.SystemMode__c = this.transactionContextManager.quiddity?.name();
                logEntryEvent.TransactionEntryNumber__c = this.currentTransactionEntryNumber++;
                logEntryEvent.TransactionId__c = this.transactionContextManager.transactionId;
                logEntryEvent.UserLoggingLevel__c = this.settingsManager.getUserLoggingLevel().name();
                logEntryEvent.UserLoggingLevelOrdinal__c = this.settingsManager.getUserLoggingLevel().ordinal();
                this.pendingLogEntryBuilders.add(logEntryEventBuilder);
            }

            return logEntryEventBuilder;
        }

        public void finalizeEntry(LogEntryEventBuilder logEntryEventBuilder) {
            LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
            // logEntryEvent.ParentLogTransactionId__c = getParentLogTransactionId();
            // logEntryEvent.TransactionScenario__c = this.transactionScenario;

            if (asyncContextManager.getCurrentAsyncContext() != null) {
                logEntryEvent.AsyncContextChildJobId__c = asyncContextManager.getCurrentAsyncContext().childJobId;
                logEntryEvent.AsyncContextParentJobId__c = asyncContextManager.getCurrentAsyncContext().parentJobId;
                logEntryEvent.AsyncContextTriggerId__c = asyncContextManager.getCurrentAsyncContext().triggerId;
                logEntryEvent.AsyncContextType__c = asyncContextManager.getCurrentAsyncContext().type;
            }
        }
    }


    @SuppressWarnings('PMD.ApexDoc')
    public class EnvironmentManager {
        public final String organizationApiVersion;
        public final String organizationDomainUrl;
        public final String serviceNamespace;
        public final String serviceVersionNumber;

        public EnvironmentManager() {
            this.organizationApiVersion = this.loadOrganizationApiVersion();
            this.organizationDomainUrl = System.URL.getOrgDomainUrl()?.toExternalForm();
            this.serviceNamespace = this.loadServiceNamespace();
            this.serviceVersionNumber = 'TODO maybe migrate Logger.CURRENT_VERSION_NUMBER + pipeline scripts that update it...?';
        }

        private String loadServiceNamespace() {
            String className = LoggerService.class.getName();
            return className.contains('.') ? className.substringBefore('.') : '';
        }

        private String loadOrganizationApiVersion() {
            // Small hack to determine the org's current API version (since Apex doesn't natively provide it)
            // Serializing any SObject w/ an ID will include the API version
            // So, use System.UserInfo.getUserId() to create the current user's record without querying
            // Then parse the JSON to get the API version
            // Expected JSON: {"attributes":{"type":"Schema.User","url":"/services/data/v53.0/sobjects/Schema.User/005J000000AugnYIAR"}
            String userJson = System.JSON.serialize(new Schema.User(Id = System.UserInfo.getUserId()));
            return userJson.substringAfter('/data/').substringBefore('/sobjects/User');
        }
    }

    // public virtual class Saver {
    //     public abstract void saveLog(List<LogEntryEvent__e> logEntryEvents);
    // }

    @SuppressWarnings('PMD.ApexDoc')
    public class SaveManager {
        private final SettingsManager settingsManager;
        private final EntryBuilderManager entryBuilderManager;

        private String saveMethodName;
        private Boolean isSavingSuspended = false;
        private String lastSaveMethodNameUsed;
        private Integer saveLogCallCount = 0;

        public SaveManager(SettingsManager settingsManager, EntryBuilderManager entryBuilderManager) {
            this.settingsManager = settingsManager;
            this.entryBuilderManager = entryBuilderManager;
        }

        public String getSaveMethodName() {
            return this.saveMethodName;
        }

        public void setSaveMethod(String targetSaveMethodName) {
            this.saveMethodName = targetSaveMethodName;
        }

        public Boolean isSavingSuspended() {
            return this.isSavingSuspended;
        }

        public void suspendSaving() {
            this.isSavingSuspended = true;
        }

        public void resumeSaving() {
            this.isSavingSuspended = false;
        }

        public void saveLog() {
            this.saveLog(this.saveMethodName);
        }

        /**
        * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
        *              Saves any entries in Logger's buffer, using the specified save method for only this call.
        *              All subsequent calls to saveLog() will use the transaction save method.
        * @param  saveMethodName The String value of the save method to use for this specific save action.
        */
        @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
        public void saveLog(String targetSaveMethodName) {
            this.saveLogCallCount++;
            this.lastSaveMethodNameUsed = targetSaveMethodName;
            if (this.entryBuilderManager.getBuffer().isEmpty() || this.settingsManager.getUserSettings().IsSavingEnabled__c == false) {
                return;
            }

            // if (suspendSaving) {
            //     if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
            //         finest(getSuspendSavingLogSystemMessage());
            //     }

            //     return;
            // }

            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
                // finest(getSavingLogSystemMessage(saveMethodName));
            }

            List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
            for (LogEntryEventBuilder logEntryEventBuilder : this.entryBuilderManager.getBuffer()) {
                if (logEntryEventBuilder.shouldSave()) {
                    this.entryBuilderManager.finalizeEntry(logEntryEventBuilder);
                    logEntryEvents.add(logEntryEventBuilder.getLogEntryEvent());
                }
            }

            // Platform events don't support BEFORE_INSERT operations (only AFTER_INSERT is supported),
            // but here we are, getting ready to insert the records, but we haven't.... yet
            // It's... it's... almost like... this part of the code IS a BEFORE_INSERT context. Huzzah!
            // This gives us a chance to run the handler class & handler plugins before insert,
            // allowing the plugins to make further changes to the `LogEntryEvent__e` records
            // So, execute the handler, which internally then executes any plugins
            LoggerTriggerableContext logEntryEventsBeforeContext = new LoggerTriggerableContext(
                Schema.LogEntryEvent__e.SObjectType,
                TriggerOperation.BEFORE_INSERT,
                logEntryEvents
            );
            LoggerSObjectHandler.getHandler(Schema.LogEntryEvent__e.SObjectType)?.overrideTriggerableContext(logEntryEventsBeforeContext).execute();

            // Now that the plugins have run, double check to make sure that saving should still happen
            if (this.entryBuilderManager.getBuffer().size() == 0) {
                return;
            }

            switch on targetSaveMethodName {
                when 'EVENT_BUS' {
                    // List<Database.SaveResult> saveResults = LoggerDataStore.getEventBus().publishRecords(logEntryEvents, PLATFORM_EVENT_DML_OPTIONS);
                    // LoggerEmailSender.sendErrorEmail(Schema.LogEntryEvent__e.SObjectType, saveResults);
                }
                when 'QUEUEABLE' {
                    // LoggerDataStore.getJobQueue().enqueueJob(new QueueableSaver(logEntryEvents));
                }
                when 'REST' {
                    // If the user doesn't have a session ID (e.g., site guest user), the REST API call will fail
                    // To avoid that, use the EventBus instead (even though REST was specified)
                    // if (String.isBlank(USER_SESSION_ID)) {
                    //     saveLog(Logger.SaveMethod.EVENT_BUS);
                    // } else {
                    //     new RestApiSaver().insertRecords(logEntryEvents);
                    // }
                }
                when 'SYNCHRONOUS_DML' {
                    LoggerTriggerableContext logEntryEventsAfterContext = new LoggerTriggerableContext(
                        Schema.LogEntryEvent__e.SObjectType,
                        TriggerOperation.AFTER_INSERT,
                        logEntryEvents
                    );
                    LoggerSObjectHandler.getHandler(Schema.LogEntryEvent__e.SObjectType)?.overrideTriggerableContext(logEntryEventsAfterContext).execute();
                }
            }

            this.entryBuilderManager.flushBuffer();
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class ScenarioManager {
        private String currentEntryScenario;
        private List<String> orderedScenarios = new List<String>();
        private String transactionScenario;

        public ScenarioManager(SettingsManager settingsManager) {
            this.setScenario(settingsManager.getUserSettings().DefaultScenario__c);
        }

        public String getCurrentEntryScenario() {
            return this.currentEntryScenario;
        }

        public String getTransactionScenario() {
            return this.transactionScenario;
        }

        public void setScenario(String scenario) {
            // TODO
        }

        public void setScenario(String scenario, SaveManager saveManager, SettingsManager settingsManager) {
            if (LoggerParameter.USE_FIRST_SCENARIO_FOR_TRANSACTION == false || String.isBlank(transactionScenario)) {
                transactionScenario = scenario;
                // One of a few limited places in the codebase (except tests) that should use System.debug()
                // The rest of the codebase should use a method in Logger.cls
                if (String.isNotBlank(transactionScenario)) {
                    System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Transaction Scenario: ' + transactionScenario);
                }
            }

            if (String.isNotBlank(scenario) && scenario == currentEntryScenario) {
                return;
            }

            currentEntryScenario = scenario;
            this.orderedScenarios.add(scenario);
            // One of a few limited places in the codebase (except tests) that should use System.debug()
            // The rest of the codebase should use a method in Logger.cls
            if (String.isNotBlank(transactionScenario)) {
                System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Entry Scenario: ' + currentEntryScenario);
            }
            LoggerScenarioRule__mdt matchingScenarioRule = LoggerScenarioRule.getInstance(scenario);
            if (matchingScenarioRule != null) {
                LoggerSettings__c userSettings = settingsManager.getUserSettings();
                if (String.isNotBlank(matchingScenarioRule.IsLoggerEnabled__c)) {
                    userSettings.IsEnabled__c = Boolean.valueOf(matchingScenarioRule.IsLoggerEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.IsAnonymousModeEnabled__c)) {
                    userSettings.IsAnonymousModeEnabled__c = Boolean.valueOf(matchingScenarioRule.IsAnonymousModeEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.IsApexSystemDebugLoggingEnabled__c)) {
                    userSettings.IsApexSystemDebugLoggingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsApexSystemDebugLoggingEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.IsDataMaskingEnabled__c)) {
                    userSettings.IsDataMaskingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsDataMaskingEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.IsJavaScriptConsoleLoggingEnabled__c)) {
                    userSettings.IsJavaScriptConsoleLoggingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsJavaScriptConsoleLoggingEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.IsRecordFieldStrippingEnabled__c)) {
                    userSettings.IsRecordFieldStrippingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsRecordFieldStrippingEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.IsSavingEnabled__c)) {
                    userSettings.IsSavingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsSavingEnabled__c);
                }
                if (String.isNotBlank(matchingScenarioRule.SaveMethod__c)) {
                    saveManager.setSaveMethod(matchingScenarioRule.SaveMethod__c);
                }
                if (String.isNotBlank(matchingScenarioRule.UserLoggingLevel__c)) {
                    userSettings.LoggingLevel__c = matchingScenarioRule.UserLoggingLevel__c;
                }
            }
        }

        public void endScenario(String scenario) {
            if (String.isBlank(scenario) || scenario != this.currentEntryScenario || this.orderedScenarios.isEmpty()) {
                return;
            }

            Integer lastScenarioIndex = this.orderedScenarios.size() - 1;
            this.orderedScenarios.remove(lastScenarioIndex);
            String previousScenario;
            if (this.orderedScenarios.isEmpty() == false) {
                Integer previousScenarioIndex = this.orderedScenarios.size() - 1;
                previousScenario = this.orderedScenarios.remove(previousScenarioIndex);
            }
            if (String.isBlank(previousScenario)) {
                this.currentEntryScenario = null;
            }

            this.setScenario(previousScenario);
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public virtual class SettingsManager {
        private final Schema.User currentUser = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        private final Map<Id, LoggerSettings__c> userIdToSettings = new Map<Id, LoggerSettings__c>();

        private System.LoggingLevel currentUserLoggingLevel;
        private LoggerSettings__c currentUserSettings;

        public SettingsManager() {
            this.currentUserSettings = this.getUserSettings(this.currentUser);
        }

        public System.LoggingLevel getLoggingLevel(String loggingLevelName) {
            try {
                return System.LoggingLevel.valueOf(loggingLevelName?.trim().toUpperCase());
            } catch (NoSuchElementException ex) {
                if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
                    // LogMessage logMessage = new LogMessage(
                    //     'Logger - Unknown logging level {0} specified, using {1}',
                    //     loggingLevelName,
                    //     FALLBACK_LOGGING_LEVEL.name()
                    // );
                    // finest(logMessage);
                }
                System.LoggingLevel fallbackLoggingLevel = System.LoggingLevel.DEBUG;
                return fallbackLoggingLevel;
            }
        }

        Boolean isEnabled() {
            return this.getUserSettings().IsEnabled__c;
        }

        public LoggerSettings__c getUserSettings() {
            return this.currentUserSettings;
        }

        public LoggerSettings__c getUserSettings(Schema.User loggingUser) {
            LoggerSettings__c loggingUserSettings = this.userIdToSettings.get(loggingUser.Id);

            if (loggingUserSettings != null) {
                return loggingUserSettings;
            }

            loggingUserSettings = this.loadSettings(loggingUser);
            this.userIdToSettings.put(loggingUser.Id, loggingUserSettings);

            return loggingUserSettings;
        }

        public System.LoggingLevel getUserLoggingLevel() {
            if (this.currentUserLoggingLevel == null || this.currentUserLoggingLevel.name() != getUserSettings().LoggingLevel__c) {
                this.currentUserLoggingLevel = getLoggingLevel(getUserSettings().LoggingLevel__c);
            }
            return this.currentUserLoggingLevel;
        }

        public Boolean meetsUserLoggingLevel(System.LoggingLevel loggingLevel) {
            return this.isEnabled() && this.getUserLoggingLevel().ordinal() <= loggingLevel.ordinal();
        }

        protected virtual LoggerSettings__c loadSettings(Schema.User loggingUser) {
            // Typically, using LoggerSettings__c.getInstance() would be easier
            // However, some settings fields are expected to have null values, which conflicts with how `getInstance()` behaves
            // So, instead use LoggerSettings__c.getValues(Id userOrProfileId) to load exactly what's been configured (including nulls)
            // First, check for Schema.User-level settings
            LoggerSettings__c loggingUserSettings;
            if (loggingUser.Id != null && LoggerSettings__c.getValues(loggingUser.Id) != null) {
                LoggerSettings__c userSettings = LoggerSettings__c.getValues(loggingUser.Id);
                if (this.hasValidStartAndEndTimes(userSettings)) {
                    loggingUserSettings = userSettings;
                }
            }

            // Next, check for Profile-level settings
            if (loggingUserSettings == null && loggingUser.ProfileId != null && LoggerSettings__c.getValues(loggingUser.ProfileId) != null) {
                LoggerSettings__c profileSettings = LoggerSettings__c.getValues(loggingUser.ProfileId);
                if (this.hasValidStartAndEndTimes(profileSettings)) {
                    loggingUserSettings = profileSettings;
                }
            }

            // Next, use the org defaults (if configured)
            if (loggingUserSettings == null && loggingUser.Id != null && LoggerSettings__c.getOrgDefaults().Id != null) {
                LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
                if (this.hasValidStartAndEndTimes(orgDefaults)) {
                    loggingUserSettings = orgDefaults;
                }
            }

            // Finally, as a last resort, create an instance using default field values
            if (loggingUserSettings == null) {
                loggingUserSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
            }

            // If the settings were loaded from the org or profile level, clear the ID and make the user the SetupOwnerId (since the method is getUserSettings)
            // This allows the ability to then upsert the instance of LoggerSettings__c and it will always be specific to that user...
            // which avoids accidentally changing something at the org or profile levels
            if (loggingUser.Id != null && loggingUserSettings.SetupOwnerId != loggingUser.Id) {
                loggingUserSettings.Id = null;
                loggingUserSettings.SetupOwnerId = loggingUser.Id;
            }

            return loggingUserSettings;
        }

        private Boolean hasValidStartAndEndTimes(LoggerSettings__c settings) {
            Datetime nowish = System.now();
            Boolean isStartTimeValid = settings.StartTime__c == null || settings.StartTime__c <= nowish;
            Boolean isEndTimeValid = settings.EndTime__c == null || settings.EndTime__c >= nowish;
            return isStartTimeValid && isEndTimeValid;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public virtual class StatusApiClient {
        public virtual StatusApiResponse callStatusApi() {
            if (LoggerParameter.CALL_STATUS_API == false) {
                return null;
            }

            Schema.Organization organization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
            String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';

            System.HttpRequest request = new System.HttpRequest();
            request.setEndpoint(statusApiEndpoint);
            request.setMethod('GET');

            try {
                System.HttpResponse response = new System.Http().send(request);
                if (response.getStatusCode() >= 400) {
                    String errorMessage =
                        'Callout failed for ' +
                        statusApiEndpoint +
                        '\nReceived request status code ' +
                        response.getStatusCode() +
                        ', status message: ' +
                        response.getStatus();
                    throw new System.CalloutException(errorMessage);
                }

                StatusApiResponse statusApiResponse = (StatusApiResponse) JSON.deserialize(response.getBody(), StatusApiResponse.class);
                return statusApiResponse;
            } catch (Exception ex) {
                if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
                    // finest('Callout to api.status.salesforce.com failed').setExceptionDetails(ex);
                }
                return null;
            }
        }
    }

    @SuppressWarnings('PMD.ApexDoc, PMD.VariableNamingConventions')
    public class StatusApiResponse {
        public String location { get; set; }
        public String maintenanceWindow { get; set; }
        public String releaseNumber { get; set; }
        public String releaseVersion { get; set; }
        public List<StatusApiResponseProduct> Products { get; set; }
    }

    // Inner class used for deserializing data from the status API
    @SuppressWarnings('PMD.ApexDoc')
    public class StatusApiResponseProduct {
        public String key { get; set; }
        public String name { get; set; }
    }


    @SuppressWarnings('PMD.ApexDoc')
    public virtual class TransactionContextManager {
        public final System.Quiddity quiddity;
        public final String requestId;
        public final String transactionId;
        public final String userSessionId;

        public String parentLogTransactionId { get; private set;}

        public TransactionContextManager() {
            this.requestId = System.Request.getCurrent().getRequestId();
            this.transactionId = 'TODO System.UUID';

            this.userSessionId = this.loadUserSessionId();
            this.quiddity = this.loadQuiddity(this.userSessionId);
        }

        public String getParentLogTransactionId() {
            return this.parentLogTransactionId;
        }

        public void setParentLogTransactionId(String parentTransactionId) {
            if (parentTransactionId != this.transactionId) {
                this.parentLogTransactionId = parentTransactionId;
            }
        }

        private String loadUserSessionId() {
            // TODO Spring '24 release - simplify this (and other lazy-loaded values)
            // by switching to the fancy, new ?? null coalescing operator
            String userSessionId;
            try {
                userSessionId = System.UserInfo.getSessionId();
            } catch (Exception ex) {
                userSessionId = '';
            }
            // If System.UserInfo.getSessionId() returns null, set to an empty string to
            // avoid calling System.UserInfo.getSessionId() again
            return userSessionId == null ? '' : userSessionId;
        }

        private System.Quiddity loadQuiddity(String userSessionId) {
            return String.isNotBlank(userSessionId) ? System.Request.getCurrent().getQuiddity() : null;
        }
    }
}
