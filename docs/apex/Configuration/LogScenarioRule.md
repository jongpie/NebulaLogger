---
layout: default
---

## LogScenarioRule class

Provides a centralized way to load scenario rules that override behavior within Nebula Logger

---

### Methods

#### `getAll()` → `Map<String, LogScenarioRule_t>`

Returns a map containing any enabled `LogScenarioRule_t` records with valid `StartTime__c` and `EndTime__c` values (null is considered valid)

##### Return

**Type**

Map&lt;String, LogScenarioRule_t&gt;

**Description**

The current transaction&apos;s cached `Map&lt;String, LogScenarioRule_t&gt;`, where the key

#### `getInstance(String scenario)` → `LogScenarioRule_t`

Returns the `LogScenarioRule_t` with the matching scenario, based on the field `LogScenarioRule_t.Scenario__c`

##### Parameters

| Param      | Description              |
| ---------- | ------------------------ |
| `scenario` | The name of the scenario |

##### Return

**Type**

LogScenarioRule_t

**Description**

The matching `LogScenarioRule_t` if one is found, or `null`

---
