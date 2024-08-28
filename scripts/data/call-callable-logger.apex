// Option 0: strings, strings everywhere!
System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call('newEntry', new Map<String, Object>{
    'exception' => new System.DmlException('whoops'),
    'loggingLevel' => System.LoggingLevel.INFO,
    'message' => 'Some log entry message',
    'recordId' => '001220000000SOMEID',
    'record' => new Schema.Contact(LastName = 'Test Contact'),
    'tags' => new List<String>{ 'tag1', 'tag2' }
})));

// Option 1: string constants, using convention of prefixes "ACTION_" and "ARGUMENT_"
System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call(CallableLogger.ACTION_ERROR, new Map<String, Object>{
    CallableLogger.ARGUMENT_MESSAGE => 'Some error message',
    CallableLogger.ARGUMENT_EXCEPTION => new System.DmlException('whoops'),
    CallableLogger.ARGUMENT_RECORD_ID => '001220000000SOMEID',
    CallableLogger.ARGUMENT_RECORD => new Schema.Contact(LastName = 'Test Contact'),
    CallableLogger.ARGUMENT_TAGS => new List<String>{ 'tag1', 'tag2' }
})));

// Option 2: object constants, with final String properties
System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call(CallableLogger.ACTIONS.setScenario, new Map<String, Object>{
    CallableLogger.ARGUMENTS.scenario => 'some scenario'
})));
System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call(CallableLogger.ACTIONS.warn, new Map<String, Object>{
    CallableLogger.ARGUMENTS.apexException => new System.DmlException('whoops'),
    CallableLogger.ARGUMENTS.message => 'Some error message',
    CallableLogger.ARGUMENTS.recordId => '001220000000SOMEID',
    CallableLogger.ARGUMENTS.record => new Schema.Contact(LastName = 'Test Contact'),
    CallableLogger.ARGUMENTS.tags => new List<String>{ 'tag1', 'tag2' }
})));
System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call(CallableLogger.ACTIONS.endScenario, new Map<String, Object>{
    CallableLogger.ARGUMENTS.scenario => 'some scenario'
})));

// Option 3: object constants, with action-specific properties for supported arguments
System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call(CallableLogger.ACTION_SET_TRANSACTION_ID.name, new Map<String, Object>{
    CallableLogger.ACTION_SET_TRANSACTION_ID.argumentParentLogTransactionId.name => 'some transaction id'
})));

System.debug(System.JSON.serializePretty((LogEntryEventBuilder) new CallableLogger().call(CallableLogger.ACTION_NEW_ENTRY.name, new Map<String, Object>{
    CallableLogger.ACTION_NEW_ENTRY.argumentException.name => new System.DmlException('whoops'),
    CallableLogger.ACTION_NEW_ENTRY.argumentLoggingLevel.name => System.LoggingLevel.INFO,
    CallableLogger.ACTION_NEW_ENTRY.argumentMessage.name => 'Some log entry message',
    CallableLogger.ACTION_NEW_ENTRY.argumentRecordId.name => '001220000000SOMEID',
    CallableLogger.ACTION_NEW_ENTRY.argumentRecord.name => new Schema.Contact(LastName = 'Test Contact'),
    CallableLogger.ACTION_NEW_ENTRY.argumentTags.name => new List<String>{ 'tag1', 'tag2' }
})));
