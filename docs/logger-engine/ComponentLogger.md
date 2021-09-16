---
layout: default
---

## ComponentLogger class

Controller class used by the lightning web component `logger`

### Related

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Methods

#### `getSettings()` → `ComponentLoggerSettings`

Provides data to the frontend about `LoggerSettings__c` &amp; server-supported logging details

##### Return

**Type**

ComponentLoggerSettings

**Description**

return The instance of `ComponentLoggerSettings` for the current user

#### `saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries)` → `String`

saveComponentLogEntries Saves log entries created via lwc or aura components

##### Parameters

| Param                 | Description                                                  |
| --------------------- | ------------------------------------------------------------ |
| `componentLogEntries` | The list of `ComponentLogEntry` objects to save via `Logger` |

##### Return

**Type**

String

**Description**

return The transaction ID (based on `Logger.getTransactionId())`

---

### Inner Classes

#### ComponentLogger.ComponentError class

A DTO object used to log details about a JavaScript error

---

##### Properties

###### `message` → `String`

The error&apos;s message

###### `stack` → `String`

The error&apos;s stack trace

###### `type` → `String`

The type of JavaScript error

---

#### ComponentLogger.ComponentLogEntry class

A DTO object used to create log entries for lightning components

---

##### Properties

###### `error` → `ComponentError`

(Optional) A JavaScript Error to log

###### `loggingLevel` → `String`

The name of the `LoggingLevel` enum value

###### `message` → `String`

The value to use as the log entry&apos;s message

###### `record` → `SObject`

(Optional) The record to relate to the log entry - the record&apos;s JSON is also stored

###### `recordId` → `Id`

(Optional) The record ID to relate to the log entry

###### `stack` → `String`

The JavaScript stack trace from when the log entry was created

###### `tags` → `List<String>`

(Optional) A list of tags to associate with the log entry

###### `timestamp` → `Datetime`

The datetime that the log entry was created in the lightning component

---

#### ComponentLogger.ComponentLoggerSettings class

A DTO object used for passing `LoggerSettings__c` details to lightning components

---

##### Properties

###### `isEnabled` → `Boolean`

Indicates if logging is enabled for the current user, based on `Logger.isEnabled()`

###### `supportedLoggingLevels` → `Map<String, Integer>`

A map of the supported `LoggingLevel` enum values

###### `userLoggingLevel` → `ComponentLoggingLevel`

The configured `LoggingLevel` for the current user, based on `Logger.getUserLoggingLevel()`

---

#### ComponentLogger.ComponentLoggingLevel class

A DTO object used for passing `LoggingLevel` details to lightning components

---

##### Properties

###### `name` → `String`

The name of the `LoggingLevel` enum value

###### `ordinal` → `Integer`

The ordinal of the `LoggingLevel` enum value

---
