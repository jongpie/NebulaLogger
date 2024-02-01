// TODO - @IsTest can't be used on a virtual/abstract class,
// but some developers might want to be able to provide their own
// mock implementation
@IsTest
global class LoggerMockService extends LoggerService {
    private static LoggerService instance;

    // private List<LogEntryEventBuilder> flushedBuilders = new List<LogEntryEventBuilder>();
    // private List<LogEntryEvent__e> publishedEvents = new List<LogEntryEvent__e>();

    private LoggerMockService() {
        super();
        this.entryBuilderManager = new MockEntryBuilderManager();
        this.statusApiClient = new MockStatusApiClient();
        this.settingsManager = new MockSettingsManager();
    }

    public static LoggerService getInstance() {
        return instance;
    }

    public static void setInstance(LoggerService serviceInstance) {
        instance = serviceInstance;
    }

    public LoggerMockService useMock() {
        // TODO consider eliminating methods `LoggerDataStore.setMock()`
        // and instead have LoggerService store instances that could
        // be overridden with mock instances
        // e.g., LoggerService.databaseInstance = LoggerMockDataStore.getDatabase();
        // maybe
        LoggerDataStore.setMock(LoggerMockDataStore.getDatabase());
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());

        LoggerMockService mockService = new LoggerMockService();
        useMock(mockService);

        // // Clear custom metadata records that are automatically loaded
        // LoggerParameter.DEVELOPER_NAME_TO_RECORD.clear();
        // LoggerPlugin.DEVELOPER_NAME_TO_RECORD.clear();

        return this;
    }

    public LoggerMockService useMock(LoggerService mockService) {
        // TODO decide if an error should be thrown when `LoggerService.instance != null`
        instance = mockService;
        return this;
    }

    // public override void flushBuffer() {
    //     this.flushedBuilders.addAll(this.getBuffer());
    //     super.flushBuffer();
    // }

    // public List<LogEntryEvent__e> getPublishedLogEntryEvents() {
    //     return this.publishedEvents;
    // }

    // public LoggerDataStore.EventBus getDataStoreEventBus() {
    //     return LoggerMockDataStore.getEventBus();
    // }

    // public LoggerDataStore.Database getDataStoreDatabase() {
    //     return LoggerMockDataStore.getDatabase();
    // }

    // public LoggerDataStore.JobQueue getDataStoreJobQueue() {
    //     return LoggerMockDataStore.getJobQueue();
    // }

    private class MockEntryBuilderManager extends LoggerService.EntryBuilderManager {
        private List<LogEntryEventBuilder> flushedBuilders = new List<LogEntryEventBuilder>();
        private List<LogEntryEvent__e> publishedEvents = new List<LogEntryEvent__e>();

        public override void flushBuffer() {
            this.flushedBuilders.addAll(this.getBuffer());
            super.flushBuffer();
        }

        public List<LogEntryEventBuilder> getFlushedBuilders() {
            return this.flushedBuilders;
        }

        public List<LogEntryEvent__e> getPublishedLogEntryEvents() {
            return this.publishedEvents;
        }
    }

    private class MockStatusApiClient extends LoggerService.StatusApiClient {
        public override StatusApiResponse callStatusApi() {
            return new LoggerService.StatusApiResponse();
        }
    }

    private class MockSettingsManager extends LoggerService.SettingsManager {
        protected override LoggerSettings__c loadSettings(Schema.User loggingUser) {
            LoggerSettings__c loggingUserSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
            loggingUserSettings.Id = null;
            loggingUserSettings.SetupOwnerId = loggingUser.Id;
            return loggingUserSettings;
        }
    }
}
