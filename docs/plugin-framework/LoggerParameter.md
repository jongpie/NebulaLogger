---
layout: default
---

## LoggerParameter class

Provides a centralized way to load T parameters for SObject handlers & plugins, and casts the parameters to common data types

---

### Properties

#### `Handler` → `LoggerParameter`

An instance of `LoggerParameter` that loads SObject Handler parameters from the object `LoggerSObjectHandlerParameter_t`

#### `Plugin` → `LoggerParameter`

An instance of `LoggerParameter` that loads SObject Handler Plugin parameters from the object `LoggerSObjectHandlerPluginParameter_t`

---

### Methods

#### `getBoolean(String parameterDeveloperName)` → `Boolean`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Boolean`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Boolean

**Description**

The `Boolean` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getBoolean(String parameterDeveloperName, Boolean defaultValue)` → `Boolean`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Boolean`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Boolean

**Description**

The `Boolean` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getBooleanList(String parameterDeveloperName)` → `List<Boolean>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Boolean>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Boolean>

**Description**

The `List<Boolean>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getBooleanList(String parameterDeveloperName, List<Boolean> defaultValue)` → `List<Boolean>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Boolean>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Boolean>

**Description**

The `List<Boolean>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDate(String parameterDeveloperName)` → `Date`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Date`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Date

**Description**

The `Date` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDate(String parameterDeveloperName, Date defaultValue)` → `Date`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Date`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Date

**Description**

The `Date` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDateList(String parameterDeveloperName)` → `List<Date>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Date>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Date>

**Description**

The `List<Date>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDateList(String parameterDeveloperName, List<Date> defaultValue)` → `List<Date>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Date>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Date>

**Description**

The `List<Date>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDatetime(String parameterDeveloperName)` → `Datetime`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Datetime`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Datetime

**Description**

The `Datetime` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDatetime(String parameterDeveloperName, Datetime defaultValue)` → `Datetime`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Datetime`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Datetime

**Description**

The `Datetime` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDatetimeList(String parameterDeveloperName)` → `List<Datetime>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Datetime>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Datetime>

**Description**

The `List<Datetime>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDatetimeList(String parameterDeveloperName, List<Datetime> defaultValue)` → `List<Datetime>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Datetime>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Datetime>

**Description**

The `List<Datetime>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDecimal(String parameterDeveloperName)` → `Decimal`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Decimal`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Decimal

**Description**

The `Decimal` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDecimal(String parameterDeveloperName, Decimal defaultValue)` → `Decimal`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Decimal`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Decimal

**Description**

The `Decimal` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDecimalList(String parameterDeveloperName)` → `List<Decimal>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Decimal>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Decimal>

**Description**

The `List<Decimal>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDecimalList(String parameterDeveloperName, List<Decimal> defaultValue)` → `List<Decimal>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Decimal>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Decimal>

**Description**

The `List<Decimal>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDouble(String parameterDeveloperName)` → `Double`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Double`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Double

**Description**

The `Double` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDouble(String parameterDeveloperName, Double defaultValue)` → `Double`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Double`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Double

**Description**

The `Double` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDoubleList(String parameterDeveloperName)` → `List<Double>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Double>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Double>

**Description**

The `List<Double>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getDoubleList(String parameterDeveloperName, List<Double> defaultValue)` → `List<Double>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Double>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Double>

**Description**

The `List<Double>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getId(String parameterDeveloperName)` → `Id`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Id`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Id

**Description**

The `Id` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getId(String parameterDeveloperName, Id defaultValue)` → `Id`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Id`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Id

**Description**

The `Id` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getIdList(String parameterDeveloperName)` → `List<Id>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Id>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Id>

**Description**

The `List<Id>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getIdList(String parameterDeveloperName, List<Id> defaultValue)` → `List<Id>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Id>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Id>

**Description**

The `List<Id>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getInteger(String parameterDeveloperName)` → `Integer`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Integer`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Integer

**Description**

The `Integer` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getInteger(String parameterDeveloperName, Integer defaultValue)` → `Integer`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Integer`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Integer

**Description**

The `Integer` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getIntegerList(String parameterDeveloperName)` → `List<Integer>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Integer>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Integer>

**Description**

The `List<Integer>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getIntegerList(String parameterDeveloperName, List<Integer> defaultValue)` → `List<Integer>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Integer>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Integer>

**Description**

The `List<Integer>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getLong(String parameterDeveloperName)` → `Long`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Long`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

Long

**Description**

The `Long` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getLong(String parameterDeveloperName, Long defaultValue)` → `Long`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `Long`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

Long

**Description**

The `Long` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getLongList(String parameterDeveloperName)` → `List<Long>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Long>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<Long>

**Description**

The `List<Long>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getLongList(String parameterDeveloperName, List<Long> defaultValue)` → `List<Long>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<Long>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<Long>

**Description**

The `List<Long>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getSObject(String parameterDeveloperName)` → `SObject`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `SObject`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

SObject

**Description**

The `SObject` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getSObject(String parameterDeveloperName, SObject defaultValue)` → `SObject`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `SObject`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

SObject

**Description**

The `SObject` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getSObjectList(String parameterDeveloperName)` → `List<SObject>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<SObject>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<SObject>

**Description**

The `List<SObject>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getSObjectList(String parameterDeveloperName, List<SObject> defaultValue)` → `List<SObject>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<SObject>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |
| `defaultValue`           | A default value to return instead of null                                     |

##### Return

**Type**

List<SObject>

**Description**

The `List<SObject>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getString(String parameterDeveloperName)` → `String`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `String`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

String

**Description**

The `String` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getString(String parameterDeveloperName, String defaultValue)` → `String`

#### `getStringList(String parameterDeveloperName)` → `List<String>`

Returns the configured value of the field `LoggerSObjectHandlerPluginParameter_t.Value__c` as a `List<String>`

##### Parameters

| Param                    | Description                                                                   |
| ------------------------ | ----------------------------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerSObjectHandlerPluginParameter_t` |

##### Return

**Type**

List<String>

**Description**

The `List<String>` value configured in the matching instance of `LoggerSObjectHandlerPluginParameter_t`,

#### `getStringList(String parameterDeveloperName, List<String> defaultValue)` → `List<String>`

---
