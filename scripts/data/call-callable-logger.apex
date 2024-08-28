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
