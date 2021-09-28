---
layout: default
---

## LoggerSettings class

Provides a centralized way to load &amp; update the custom hierarchy setting `LoggerSettings__c`

---

### Methods

#### `getUserLoggingLevel()` → `LoggingLevel`

Returns the logging level for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

LoggingLevel

**Description**

LoggingLevel - The matching instance of LoggingLevel

#### `getUserSettings()` → `LoggerSettings__c`

Returns the current user&apos;s instance of `LoggerSettings__c`

##### Return

**Type**

LoggerSettings\_\_c

**Description**

LoggerSettings\_\_c - The current user&apos;s instance of the custom settings

#### `getUserSettings(User loggingUser)` → `LoggerSettings__c`

Returns the specified user&apos;s instance of `LoggerSettings__c`

##### Parameters

| Param  | Description                                                                                      |
| ------ | ------------------------------------------------------------------------------------------------ |
| `user` | The user record - at a minimum, this record should have the user Id and Profile fields populated |

##### Return

**Type**

LoggerSettings\_\_c

**Description**

LoggerSettings\_\_c - The specified user&apos;s instance of the custom settings

#### `isDebugEnabled()` → `Boolean`

Indicates if logging level &apos;DEBUG&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled()` → `Boolean`

Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled(LoggingLevel loggingLevel)` → `Boolean`

Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Parameters

| Param          | Description                  |
| -------------- | ---------------------------- |
| `loggingLevel` | - The logging level to check |

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isErrorEnabled()` → `Boolean`

Indicates if logging level &apos;ERROR&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFineEnabled()` → `Boolean`

Indicates if logging level &apos;FINE&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinerEnabled()` → `Boolean`

Indicates if logging level &apos;FINER&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinestEnabled()` → `Boolean`

Indicates if logging level &apos;FINEST&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isInfoEnabled()` → `Boolean`

Indicates if logging level &apos;INFO&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isWarnEnabled()` → `Boolean`

Indicates if logging level &apos;WARN&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel)` → `Boolean`

Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

---
