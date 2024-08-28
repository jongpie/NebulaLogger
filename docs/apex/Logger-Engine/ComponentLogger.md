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

#### `saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries, String saveMethodName)` → `String`

saveComponentLogEntries Saves log entries created via lwc or aura components

##### Parameters

| Param                 | Description                                                          |
| --------------------- | -------------------------------------------------------------------- |
| `componentLogEntries` | The list of `ComponentLogEntry` objects to save via `Logger`         |
| `saveMethodName`      | String name of the instance of Logger.SaveMethod to use when saving. |

##### Return

**Type**

String

**Description**

return The transaction ID (based on `Logger.getTransactionId())`

---

### Inner Classes

#### ComponentLogger.ComponentBrowser class

A DTO object used to log details about the user&apos;s browser

---

##### Properties

###### `address` → `String`

The URL displayed in the user&apos;s browser

###### `formFactor` → `String`

The form factor of the user&apos;s browser

###### `language` → `String`

The language set in the user&apos;s browser

###### `screenResolution` → `String`

The resolution of the user&apos;s device

###### `userAgent` → `String`

The user agent of the user&apos;s browser

###### `windowResolution` → `String`

The resolution of the user&apos;s browser window

---

#### ComponentLogger.ComponentError class

A DTO object used to log details about a JavaScript error

---

##### Properties

###### `message` → `String`

The error&apos;s message

###### `stack` → `String`

`DEPRECATED` This property is no longer used, and will be removed in a future release. The error&apos;s stack trace string

###### `stackTrace` → `ComponentStackTrace`

Contains details about the origin of the error

###### `type` → `String`

The type of JavaScript error

---

#### ComponentLogger.ComponentLogEntry class

A DTO object used to create log entries for lightning components

---

##### Properties

###### `browser` → `ComponentBrowser`

Context about the user&apos;s browser, automatically captured by Nebula Logger

###### `error` → `ComponentError`

(Optional) A JavaScript Error to log

###### `fieldToValue` → `Map<String, Object>`

(Optional) A map containing key-value pairs of fields to set on `LogEntryEvent__e`

###### `loggingLevel` → `String`

The name of the `LoggingLevel` enum value

###### `message` → `String`

The value to use as the log entry&apos;s message

###### `originStackTrace` → `ComponentStackTrace`

Contains details about the origin of the component log entry

###### `record` → `SObject`

(Optional) The record to relate to the log entry - the record&apos;s JSON is also stored

###### `recordId` → `Id`

(Optional) The record ID to relate to the log entry

###### `scenario` → `String`

Optionally specify the name to use for the current transaction&apos;s scenario

###### `stack` → `String`

`DEPRECATED` This property is no longer used, and will be removed in a future release. The JavaScript stack trace from when the log entry was created

###### `tags` → `List<String>`

(Optional) A list of tags to associate with the log entry

###### `timestamp` → `Datetime`

The datetime that the log entry was created in the lightning component

---

#### ComponentLogger.ComponentLoggerSettings class

A DTO object used for passing `LoggerSettings__c` details to lightning components

---

##### Properties

###### `defaultSaveMethodName` → `String`

Indicates the save method that will be used by default if no other save method is specified, based on `LoggerSettings__c.DefaultSaveMethod__c`

###### `isConsoleLoggingEnabled` → `Boolean`

Indicates if logging via the browser&apos;s `console.log()` is enabled for the current user, based on `LoggerSettings__c.IsJavaScriptConsoleLoggingEnabled__c`

###### `isEnabled` → `Boolean`

Indicates if logging is enabled for the current user, based on `LoggerSettings__c.IsEnabled__c`

###### `isLightningLoggerEnabled` → `Boolean`

Indicates if logging via the standard LWC `lightning-logger` is enabled for the current user, based on `LoggerSettings__c.IsJavaScriptLightningLoggerEnabled__c`

###### `supportedLoggingLevels` → `Map<String, Integer>`

A map of the supported `LoggingLevel` enum values

###### `userLoggingLevel` → `ComponentLoggingLevel`

The configured `LoggingLevel` for the current user, based on `LoggerSettings__c.LoggingLevel__c`

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

#### ComponentLogger.ComponentStackTrace class

A DTO object used to log details about the origin of a JavaScript log entry

---

##### Properties

###### `componentName` → `String`

The component that generated the log entry

###### `functionName` → `String`

The component&apos;s function that generated the log entry

###### `metadataType` → `String`

The metadata type of the component that generated the log entry Possible values are `AuraDefinitionBundle` and `LightningComponentBundle`

###### `parsedStackTraceString` → `String`

The parsed stack trace used to determine the log entry origin

---
