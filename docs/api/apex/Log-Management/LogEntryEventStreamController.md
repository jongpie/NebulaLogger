---
layout: default
---

## LogEntryEventStreamController class

Controller class for lwc `logEntryEventStream`, used to stream Log Entries in console and Tabular view.

---

### Methods

#### `getDatatableDisplayFields()` → `List<String>`

Returns the list of columns to be displayed in LogEntryEventStream datatable. The fields are configured in the custom metadata record LoggerParameter_t.LogEntryEventStreisplayFields.

##### Return

**Type**

List&lt;String&gt;

**Description**

The instance of `List&lt;String&gt;`, containing the list of columns to be displayed in

#### `isEnabled()` → `Boolean`

Indicates if the LWC `logEntryEventStream` has been enabled (default) or disabled

##### Return

**Type**

Boolean

**Description**

The `Boolean` value of the `LoggerParameter_t` record `LoggerParameter.EnableLogEntryEventStream`

---
