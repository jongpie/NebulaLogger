---
layout: default
---

## RelatedLogEntriesController class

Controller class for the lightning web component `related-log-entries`

---

### Methods

#### `getQueryResult(Id recordId,String fieldSetName,Integer rowLimit,String sortByFieldName,String sortDirection,String search,Boolean shouldEnableStrictSearch)` → `LogEntryQueryResult`

Used by the component relatedLogEntries to get log entries for a particular record (based on record ID)

##### Parameters

| Param                      | Description                                                                          |
| -------------------------- | ------------------------------------------------------------------------------------ |
| `recordId`                 | The recordId to search for amidst all Log Entry fields                               |
| `fieldSetName`             | The API/developer name of the field set                                              |
| `rowLimit`                 | The max number of rows to query                                                      |
| `sortByFieldName`          | The field to sort by                                                                 |
| `sortDirection`            | The direction to sort by (asc or desc)                                               |
| `search`                   | An optional search term to filter by                                                 |
| `shouldEnableStrictSearch` | When true, used to filter returned LogEntry**c records where RecordId**c == recordId |

##### Return

**Type**

LogEntryQueryResult

**Description**

The instance of LogEntryQueryResult, containing matching records and metadata

---

### Inner Classes

#### RelatedLogEntriesController.FieldMetadata class

An inner, wrapper class containing metadata information about an individual field.

---

##### Properties

###### `fieldName` → `String`

A string containing the API name of the field, in particular the field path as it relates to the parent field set.

###### `isNameField` → `Boolean`

Boolean that returns true if this field is the standard Name field for its parent object.

###### `label` → `String`

A string containing the label of the field.

###### `lookupDisplayFieldName` → `String`

A string used for lookup fields to indicate the display name of the lookup / relationship.

###### `relationshipName` → `String`

If the field is a lookup or master detail relationship, this string will return the relationship API name. For instance: Lookup**r instead of Lookup**c.

###### `sortable` → `Boolean`

Boolean that returns true if this field is sortable.

###### `type` → `String`

Returns the type of the field, matching the Schema.DisplayType ENUM values, but in all lowercase letters.

---

#### RelatedLogEntriesController.FieldSetMetadata class

Inner, wrapper class, containing metadata around the list of fields used in the related log entry query.

---

##### Properties

###### `fields` → `List<FieldMetadata>`

A list of field related metadata

###### `label` → `String`

Contains the label of the desired field set, fetched using a describe call on the field set.

###### `name` → `String`

A string containing the API name of the field set, including the namespace prefix, if applicable.

---

#### RelatedLogEntriesController.LogEntryQueryResult class

Inner, wrapper class that contains query result information after querying related log entries.

---

##### Properties

###### `fieldSet` → `FieldSetMetadata`

Contains the fieldSet associated with this query.

###### `isAccessible` → `Boolean`

Contains the result of the CRUD check, determining if the log entry is &quot;accessible&quot; for the current user.

###### `label` → `String`

Contains the label of the log entry sObject, fetched using a describe call in the constructor.

###### `labelPlural` → `String`

Contains the plural label of the log entry sObject, fetched using a describe call in the constructor.

###### `records` → `List<LogEntry__c>`

contains the log entry results from the query.

---
