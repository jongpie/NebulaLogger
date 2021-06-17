// Basic prototype to show what the structure could look like for building a plugin that creates Big Object records
// It's by no means functional - this is more of a general outline of what would be needed
public without sharing class BigObjectLoggerPlugin extends LoggerSObjectHandlerPlugin {
    // Constants used for loading parameters from CMDT objects
    private static final String PARAM_SKIP_PLATFORM_EVENTS = 'BigObject_SkipPlatformEvents';

    @testVisible
    private static Boolean skipPlatformEvents;

    static {
        // TODO the plugin framework will eventually have a simpler way to load parameters,
        // so this can/will eventually be simplified
        LoggerSObjectHandlerPluginParameter__mdt skipPlatformEventsParameter = LoggerSObjectHandlerPluginParameter__mdt.getInstance(PARAM_SKIP_PLATFORM_EVENTS);
        if (skipPlatformEventsParameter != null && skipPlatformEventsParameter.IsEnabled__c == true) {
            Boolean skipPlatformEvents = (Boolean) JSON.deserialize(skipPlatformEventsParameter?.Value__c, Boolean.class);
        }
    }

    private List<LogEntryEvent__e> logEntryEvents;

    // Constructors
    public BigObjectLoggerPlugin() {
    }

    // Instance methods
    public override void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    ) {
        switch on triggerOperationType {
            when BEFORE_INSERT {
                this.logEntryEvents = (List<LogEntryEvent__e>) triggerNew;

                this.createLogEntryEventArchives();
                this.skipPlatformEvents();
            }
        }
    }

    private void createLogEntryEventArchives() {
        // List<LogEntryArchive__b> logEntryArchives = new List<LogEntryArchive__b>();
        for (LogEntryEvent__e logEntryEvent : this.logEntryEvents) {
            // TODO - convert the log entry event records into BIG object records
        }
        // TODO: Save the list of big object records
    }

    private void skipPlatformEvents() {
        // If the config says to skip platform events, then we can just flush the buffer
        // to avoid any platform events from being published
        if (skipPlatformEvents == true) {
            Logger.flushBuffer();
        }
    }
}
