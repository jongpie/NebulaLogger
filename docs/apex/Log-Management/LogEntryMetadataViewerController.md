---
layout: default
---

## LogEntryMetadataViewerController class

Controller class for the LWC `logEntryMetadataViewer`

---

### Methods

#### `getMetadata(Id recordId, String sourceMetadata)` → `LogEntryMetadata`

Returns an instance of the inner class `LogEntryMetadataViewerController.LogEntryMetadata`, which contains information about the log entry&apos;s origin and exception Apex classes

##### Parameters

| Param            | Description                              |
| ---------------- | ---------------------------------------- |
| `recordId`       | The `ID` of the `LogEntry__c` record     |
| `sourceMetadata` | Either the value `Origin` or `Exception` |

##### Return

**Type**

LogEntryMetadata

**Description**

An instance of `LogEntryMetadataViewerController.LogEntryMetadata`

---

### Inner Classes

#### LogEntryMetadataViewerController.LogEntryMetadata class

---

##### Properties

###### `Code` → `String`

###### `HasCodeBeenModified` → `Boolean`

---
