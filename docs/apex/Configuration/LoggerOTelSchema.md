---
layout: default
---

## LoggerOTelSchema class

Class used to handle the translation between some Salesforce concepts and OpenTelemetry&apos;s (OTel) schema. None of this is specific to Nebula Logger, this only handles the translation between OTel &amp; what Salesforce provides out-of-the-box.

### Related

[LoggerOTelAdapter](LoggerOTelAdapter)

[LoggerRestResource](LoggerRestResource)

[LogEntryEventBuilder](LogEntryEventBuilder)

[LogViewerController](LogViewerController)

---

### Methods

#### `getSeverityLevels()` → `Map<String, SeverityLevel>`

getSeverityLevels description

##### Return

**Type**

Map&lt;String, SeverityLevel&gt;

**Description**

return description

---

### Inner Classes

#### LoggerOTelSchema.Attribute class

---

##### Constructors

###### `Attribute(String key, Boolean value)`

###### `Attribute(String key, Integer value)`

###### `Attribute(String key, String value)`

---

##### Properties

###### `key` → `String`

###### `value` → `AttributeValue`

---

##### Methods

###### `getPrimitiveValue()` → `Object`

---

#### LoggerOTelSchema.AttributeValue class

---

##### Constructors

###### `AttributeValue(Boolean value)`

###### `AttributeValue(Integer value)`

###### `AttributeValue(String value)`

---

##### Properties

###### `boolValue` → `Boolean`

###### `intValue` → `Integer`

###### `stringValue` → `String`

---

#### LoggerOTelSchema.LogRecord class

---

##### Properties

###### `attributes` → `List<Attribute>`

###### `body` → `AttributeValue`

###### `name` → `String`

###### `severityNumber` → `Integer`

###### `severityText` → `String`

###### `spanId` → `String`

###### `timeUnixNano` → `String`

###### `traceId` → `String`

---

##### Methods

###### `getSeverityLevel()` → `SeverityLevel`

---

#### LoggerOTelSchema.LogsPayload class

---

##### Properties

###### `resourceLogs` → `List<ResourceLog>`

---

#### LoggerOTelSchema.Resource class

---

##### Properties

###### `attributes` → `List<Attribute>`

---

#### LoggerOTelSchema.ResourceLog class

---

##### Properties

###### `resource` → `Resource`

###### `scopeLogs` → `List<ScopeLog>`

---

#### LoggerOTelSchema.Scope class

---

##### Properties

###### `name` → `String`

###### `version` → `String`

---

#### LoggerOTelSchema.ScopeLog class

---

##### Properties

###### `logRecords` → `List<LogRecord>`

###### `scope` → `Scope`

---

#### LoggerOTelSchema.SeverityLevel class

---

##### Constructors

###### `SeverityLevel(System.LoggingLevel systemLoggingLevel)`

###### `SeverityLevel(String severityText)`

###### `SeverityLevel(Integer severityNumber)`

###### `SeverityLevel(Integer severityNumber, String severityText)`

---

##### Properties

###### `SeverityNumber` → `Integer`

###### `SeverityText` → `String`

---

##### Methods

###### `toLoggingLevel()` → `System.LoggingLevel`

---
