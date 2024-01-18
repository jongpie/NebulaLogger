---
layout: default
---

## LogEntryFieldSetPicklist class

Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries

---

### Methods

#### `getDefaultValue()` → `VisualEditor.DataRow`

Returns the default `LogEntry__c` field set, based on the `LoggerParameter_t` record `DefaultLogEntryRelatedListFieldSet`

##### Return

**Type**

VisualEditor.DataRow

**Description**

And instance of `VisualEditor.DataRow` if a valid, matching field set exists, or `null`

#### `getValues()` → `VisualEditor.DynamicPickListRows`

Returns the list of fields sets on `LogEntry__c`, allowing admins to specify any field set for each instance of the `RelatedLogEntries` component

##### Return

**Type**

VisualEditor.DynamicPickListRows

**Description**

The list of field sets on the LogEntry\_\_c object

---
