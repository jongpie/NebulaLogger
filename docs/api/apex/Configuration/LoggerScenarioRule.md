---
layout: default
---

## LoggerScenarioRule class

Provides a centralized way to load scenario rules that override behavior within Nebula Logger

---

### Methods

#### `getAll()` → `Map<String, LoggerScenarioRule_t>`

Returns a map containing any enabled `LoggerScenarioRule_t` records with valid `StartTime__c` and `EndTime__c` values (null is considered valid)

##### Return

**Type**

Map&lt;String, LoggerScenarioRule_t&gt;

**Description**

The current transaction&apos;s cached `Map&lt;String, LoggerScenarioRule_t&gt;`, where the key

#### `getInstance(String scenario)` → `LoggerScenarioRule_t`

Returns the `LoggerScenarioRule_t` with the matching scenario, based on the field `LoggerScenarioRule_t.Scenario__c`

##### Parameters

| Param      | Description              |
| ---------- | ------------------------ |
| `scenario` | The name of the scenario |

##### Return

**Type**

LoggerScenarioRule_t

**Description**

The matching `LoggerScenarioRule_t` if one is found, or `null`

---
