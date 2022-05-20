---
layout: default
---

## LogViewerController class

Controller class for the LWC `logViewer`, used to provided different views on a `Log__c` record

---

### Methods

#### `getLog(Id logId)` → `Log__c`

Returns a Log\_\_c record from the database, using either the Salesforce ID or transaction ID

##### Parameters

| Param   | Description                                         |
| ------- | --------------------------------------------------- |
| `logId` | The Salesforce ID or TransactionId**c of the Log**c |

##### Return

**Type**

Log\_\_c

**Description**

The matching record, with all fields that the current user can access

---
