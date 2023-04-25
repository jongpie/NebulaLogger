---
layout: default
---

## LogMassDeleteExtension class

Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view

---

### Constructors

#### `LogMassDeleteExtension(ApexPages.StandardSetController controller)`

Constructor for Visual Force list page / StandardSetController.

##### Parameters

| Param        | Description                                                       |
| ------------ | ----------------------------------------------------------------- |
| `controller` | The standard set controller (passed in automatically via VF page) |

---

### Methods

#### `deleteSelectedLogs()` → `PageReference`

Deletes the list of selected `Log__c` records (if the current user has delete access for the `Log__c` object)

##### Return

**Type**

PageReference

**Description**

The PageReference of the previous page (based on `controller.cancel()`)

#### `getDeletableLogs()` → `List<Log__c>`

Filters the list of selected `Log__c` records to only include records that the current user can delete (based on object-level access)

##### Return

**Type**

List&lt;Log\_\_c&gt;

**Description**

The matching `Log__c` records that the current user has access to delete

---
