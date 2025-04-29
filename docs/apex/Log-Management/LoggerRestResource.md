---
layout: default
---

## LoggerRestResource class

REST Resource class for external integrations to interact with Nebula Logger

---

### Properties

#### `body` → `String`

#### `errors` → `List<EndpointError>`

#### `headerKeys` → `List<String>`

#### `httpMethod` → `String`

#### `isSuccess` → `Boolean`

#### `message` → `String`

#### `name` → `String`

#### `parameters` → `Map<String, String>`

#### `particle` → `String`

#### `statusCode` → `Integer`

#### `type` → `String`

#### `uri` → `String`

---

### Methods

#### `EndpointError(System.Exception apexException)` → `public`

#### `EndpointError(String message)` → `public`

#### `EndpointError(String message, String type)` → `public`

#### `EndpointRequest(System.RestRequest restRequest)` → `public`

#### `addError(System.Exception apexException)` → `EndpointResponse`

#### `addError(EndpointError endpointError)` → `EndpointResponse`

#### `handlePost()` → `void`

Processes any HTTP POST requests sent

#### `handlePost(EndpointRequest endpointRequest)` → `EndpointResponse`

#### `handlePost(EndpointRequest endpointRequest)` → `EndpointResponse`

#### `handlePost(EndpointRequest endpointRequest)` → `EndpointResponse`

#### `setStatusCode(Integer statusCode)` → `EndpointResponse`

---

### Inner Classes

#### LoggerRestResource.OTelAttribute class

---

##### Constructors

###### `OTelAttribute(String key, Boolean value)`

###### `OTelAttribute(String key, Integer value)`

###### `OTelAttribute(String key, String value)`

---

##### Properties

###### `key` → `String`

###### `value` → `OTelAttributeValue`

---

#### LoggerRestResource.OTelAttributeValue class

---

##### Constructors

###### `OTelAttributeValue(Boolean value)`

###### `OTelAttributeValue(Integer value)`

###### `OTelAttributeValue(String value)`

---

##### Properties

###### `boolValue` → `Boolean`

###### `intValue` → `Integer`

###### `stringValue` → `String`

---

#### LoggerRestResource.OTelLogRecord class

---

##### Properties

###### `attributes` → `List<OTelAttribute>`

###### `body` → `OTelAttributeValue`

###### `name` → `String`

###### `severityNumber` → `Integer`

###### `severityText` → `String`

###### `spanId` → `String`

###### `timeUnixNano` → `String`

###### `traceId` → `String`

---

##### Methods

###### `getLogEntryEvent()` → `LogEntryEvent__e`

---

#### LoggerRestResource.OTelLogsPayload class

---

##### Properties

###### `resourceLogs` → `List<OTelResourceLog>`

---

##### Methods

###### `getConvertedLogEntryEvents()` → `List<LogEntryEvent__e>`

---

#### LoggerRestResource.OTelResource class

---

##### Properties

###### `attributes` → `List<OTelAttribute>`

---

#### LoggerRestResource.OTelResourceLog class

---

##### Properties

###### `resource` → `OTelResource`

###### `scopeLogs` → `List<OTelScopeLog>`

---

##### Methods

###### `getLogEntryEvents()` → `List<LogEntryEvent__e>`

---

#### LoggerRestResource.OTelScope class

---

##### Properties

###### `name` → `String`

###### `version` → `String`

---

#### LoggerRestResource.OTelScopeLog class

---

##### Properties

###### `logRecords` → `List<OTelLogRecord>`

###### `scope` → `OTelScope`

---
