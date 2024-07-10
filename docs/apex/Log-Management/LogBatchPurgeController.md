---
layout: default
---

## LogBatchPurgeController class

Controller class for lwc `logBatchPurge`, used to provide metrics of `Log__c`, `LogEntry__c`, `LogEntryTag__c` records to purge and allow user to manually run `LogBatchPurger` from the UI.

---

### Methods

#### `canUserRunLogBatchPurger()` → `Boolean`

Returns true if the current user has delete permission on the Log\_\_c object or

##### Return

**Type**

Boolean

**Description**

true if the current user has delete permission on the Log\_\_c object.

#### `getBatchPurgeJobRecords()` → `List<Schema.AsyncApexJob>`

Returns `List&lt;Schema.AsyncApexJob&gt;` to display logBatchPurger jobs details in a Datatable.

##### Return

**Type**

List&lt;Schema.AsyncApexJob&gt;

**Description**

The instance of `List&lt;Schema.AsyncApexJob&gt;`, containing list of logBatchPurge jobs.

#### `getMetrics(String dateFilterOption)` → `Map<String, Object>`

return a `Map&lt;String,Object&gt;` contains metrics for number of `Log__c`, `LogEntry__c`, `LogEntryTag__c` records to purge, for the given timeframe TODAY/ THIS_WEEK/ THIS_MONTH. The metrics is grouped by `Log__c.LogPurgeAction__c`.

##### Parameters

| Param              | Description                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------------- |
| `dateFilterOption` | a Date Literal used to filter log records. Possible values are TODAY, THIS_WEEK, THIS_MONTH |

##### Return

**Type**

Map&lt;String, Object&gt;

**Description**

The instance of `Map&lt;String,Object&gt;`,contains keys as `Log__c`, `LogEntry__c`, `LogEntryTag__c` and value as metrics for the corresponding object records to purge

#### `getPurgeActionOptions()` → `List<PicklistOption>`

Returns all of the PurgeAction options to display the log metrics in UI

##### Return

**Type**

List&lt;PicklistOption&gt;

**Description**

The instance of `List&lt;PicklistOption&gt;`, containing all picklist options for purge Action.

#### `runBatchPurge()` → `String`

execute the logBatchPurger batch with batch size 2000

##### Return

**Type**

String

**Description**

Returns the ID of the Schema.AsyncApexJob object associated with the LogBatchPurger job as a string

---

### Inner Classes

#### LogBatchPurgeController.PicklistOption class

Inner class for returning all custom `List&lt;PicklistOption&gt;` in a single Apex method call

---

##### Properties

###### `label` → `String`

###### `value` → `String`

---
