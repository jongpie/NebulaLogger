# Filtered Log Entry Events plugin for Nebula Logger

TODO

Reported in: https://github.com/jongpie/NebulaLogger/issues/183

Issue: 50,000 daily limit for CometD subscribers: https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm

Long-Term Solution: Channels https://help.salesforce.com/s/articleView?id=release-notes.rn_platform_events_filtering_pilot.htm&type=5&release=232

Short-Term Solution: this plugin

TODO screenshots



PE EVENT:
============
A duplicate of the LogEntryEvent__e object, used as a way for external systems to subscribe to a subset of LogEntryEvent__e platform events. Filters can be configured using the custom metadata types LogEntryEventFilter__mdt and LogEntryEventFilterCondition__mdt. This is useful in situations where the 24-hour limit is exceeded for the number of delivered event notifications.

Event Delivery details &amp; limits can be found at: https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm

Long term, platform event channels will potentially replace the need for this:
https://help.salesforce.com/s/articleView?language=en_US&amp;type=5&amp;release=232&amp;id=release-notes.rn_platform_events_filtering_pilot.htm



FILTER CMDT:
=============
A filter rule to apply to LogEntryEvent__e platform events - any matching events will be duplicated &amp; published as a FilteredLogEntryEvent__e platform events. Each filter consists of 1 or more conditions, stored in LogEntryEventFilterCondition__mdt





FILTER CONDITION CMDT:
=============
A field-level condition to check on LogEntryEvent__e platform events for a particular filter - conditions can be added for a specific value, regular expression (regex), or field comparison.

