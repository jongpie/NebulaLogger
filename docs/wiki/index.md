# Welcome to the Nebula Logger wiki!

Nebula Logger is an open source logging tool for Salesforce. It's designed for Salesforce admins, developers & architects, to aid in development, troubleshooting & monitoring of your Salesforce environments.

## Features

1. Easily add log entries via Apex, Lightning Components (lwc & aura), Flow & Process Builder to generate 1 consolidate log
2. Manage & report on logging data using the `Log__c` and `LogEntry__c` objects
3. Leverage `LogEntryEvent__e` platform events for real-time monitoring & integrations
4. Enable logging and set the logging level for different users & profiles using `LoggerSettings__c` custom hierarchy setting
   - In addition to the required fields on this Custom Setting record, `LoggerSettings__c` ships with `SystemLogMessageFormat__c`, which uses Handlebars-esque syntax to refer to fields on the `LogEntryEvent__e` Platform Event. You can use curly braces to denote merge field logic, eg: `{OriginLocation__c}\n{Message__c}` - this will output the contents of `LogEntryEvent__e.OriginLocation__c`, a line break, and then the contents of `LogEntryEvent__e.Message__c`
5. Automatically mask sensitive data by configuring `LogEntryDataMaskRule__mdt` custom metadata rules
6. View related log entries on any Lighting SObject flexipage by adding the 'Related Log Entries' component in App Builder
7. Dynamically assign tags to `Log__c` and `LogEntry__c` records for tagging/labeling your logs
8. Plugin framework: easily build or install plugins that enhance the `Log__c` and `LogEntry__c` objects, using Apex or Flow (not currently available in the managed package)
9. Event-Driven Integrations with [Platform Events](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_intro.htm), an event-driven messaging architecture. External integrations can subscribe to log events using the `LogEntryEvent__e` object - see more details at [the Platform Events Developer Guide site](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_cometd.htm)

## Learn More
Learn more about the design and history of the project on the [Joys Of Apex](https://www.jamessimone.net/blog/joys-of-apex/):
- [Advanced Logging Using Nebula Logger](https://www.jamessimone.net/blog/joys-of-apex/advanced-logging-using-nebula-logger/)
- [What's New With Nebula Logger](https://www.jamessimone.net/blog/joys-of-apex/whats-new-with-nebula-logger/)
