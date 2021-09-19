---
layout: default
---

## LoggerParameter class

Provides a centralized way to load parameters for SObject handlers &amp; plugins, and casts the parameters to common data types

---

### Methods

#### `getBoolean(String parameterDeveloperName)` → `Boolean`

Returns the configured value of the field `Value__c` as a `Boolean`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Boolean

**Description**

The `Boolean` value configured in the matching instance of `LoggerParameter_t`

#### `getBoolean(String parameterDeveloperName, Boolean defaultValue)` → `Boolean`

Returns the configured value of the field `Value__c` as a `Boolean`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Boolean

**Description**

The `Boolean` value configured in the matching instance of `LoggerParameter_t`

#### `getBooleanList(String parameterDeveloperName)` → `List<Boolean>`

Returns the configured value of the field `Value__c` as a `List&lt;Boolean&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Boolean&gt;

**Description**

The `List&lt;Boolean&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getBooleanList(String parameterDeveloperName, List<Boolean> defaultValue)` → `List<Boolean>`

Returns the configured value of the field `Value__c` as a `List&lt;Boolean&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Boolean&gt;

**Description**

The `List&lt;Boolean&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDate(String parameterDeveloperName)` → `Date`

Returns the configured value of the field `Value__c` as a `Date`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Date

**Description**

The `Date` value configured in the matching instance of `LoggerParameter_t`

#### `getDate(String parameterDeveloperName, Date defaultValue)` → `Date`

Returns the configured value of the field `Value__c` as a `Date`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Date

**Description**

The `Date` value configured in the matching instance of `LoggerParameter_t`

#### `getDateList(String parameterDeveloperName)` → `List<Date>`

Returns the configured value of the field `Value__c` as a `List&lt;Date&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Date&gt;

**Description**

The `List&lt;Date&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDateList(String parameterDeveloperName, List<Date> defaultValue)` → `List<Date>`

Returns the configured value of the field `Value__c` as a `List&lt;Date&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Date&gt;

**Description**

The `List&lt;Date&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDatetime(String parameterDeveloperName)` → `Datetime`

Returns the configured value of the field `Value__c` as a `Datetime`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Datetime

**Description**

The `Datetime` value configured in the matching instance of `LoggerParameter_t`

#### `getDatetime(String parameterDeveloperName, Datetime defaultValue)` → `Datetime`

Returns the configured value of the field `Value__c` as a `Datetime`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Datetime

**Description**

The `Datetime` value configured in the matching instance of `LoggerParameter_t`

#### `getDatetimeList(String parameterDeveloperName)` → `List<Datetime>`

Returns the configured value of the field `Value__c` as a `List&lt;Datetime&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Datetime&gt;

**Description**

The `List&lt;Datetime&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDatetimeList(String parameterDeveloperName, List<Datetime> defaultValue)` → `List<Datetime>`

Returns the configured value of the field `Value__c` as a `List&lt;Datetime&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Datetime&gt;

**Description**

The `List&lt;Datetime&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDecimal(String parameterDeveloperName)` → `Decimal`

Returns the configured value of the field `Value__c` as a `Decimal`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Decimal

**Description**

The `Decimal` value configured in the matching instance of `LoggerParameter_t`

#### `getDecimal(String parameterDeveloperName, Decimal defaultValue)` → `Decimal`

Returns the configured value of the field `Value__c` as a `Decimal`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Decimal

**Description**

The `Decimal` value configured in the matching instance of `LoggerParameter_t`

#### `getDecimalList(String parameterDeveloperName)` → `List<Decimal>`

Returns the configured value of the field `Value__c` as a `List&lt;Decimal&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Decimal&gt;

**Description**

The `List&lt;Decimal&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDecimalList(String parameterDeveloperName, List<Decimal> defaultValue)` → `List<Decimal>`

Returns the configured value of the field `Value__c` as a `List&lt;Decimal&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Decimal&gt;

**Description**

The `List&lt;Decimal&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDouble(String parameterDeveloperName)` → `Double`

Returns the configured value of the field `Value__c` as a `Double`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Double

**Description**

The `Double` value configured in the matching instance of `LoggerParameter_t`

#### `getDouble(String parameterDeveloperName, Double defaultValue)` → `Double`

Returns the configured value of the field `Value__c` as a `Double`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Double

**Description**

The `Double` value configured in the matching instance of `LoggerParameter_t`

#### `getDoubleList(String parameterDeveloperName)` → `List<Double>`

Returns the configured value of the field `Value__c` as a `List&lt;Double&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Double&gt;

**Description**

The `List&lt;Double&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDoubleList(String parameterDeveloperName, List<Double> defaultValue)` → `List<Double>`

Returns the configured value of the field `Value__c` as a `List&lt;Double&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Double&gt;

**Description**

The `List&lt;Double&gt;` value configured in the matching instance of LLoggerParameter_t`

#### `getId(String parameterDeveloperName)` → `Id`

Returns the configured value of the field `Value__c` as a `Id`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Id

**Description**

The `Id` value configured in the matching instance of `LoggerParameter_t`

#### `getId(String parameterDeveloperName, Id defaultValue)` → `Id`

Returns the configured value of the field `Value__c` as a `Id`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Id

**Description**

The `Id` value configured in the matching instance of `LoggerParameter_t`

#### `getIdList(String parameterDeveloperName)` → `List<Id>`

Returns the configured value of the field `Value__c` as a `List&lt;Id&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Id&gt;

**Description**

The `List&lt;Id&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getIdList(String parameterDeveloperName, List<Id> defaultValue)` → `List<Id>`

Returns the configured value of the field `Value__c` as a `List&lt;Id&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Id&gt;

**Description**

The `List&lt;Id&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getInteger(String parameterDeveloperName)` → `Integer`

Returns the configured value of the field `Value__c` as a `Integer`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Integer

**Description**

The `Integer` value configured in the matching instance of `LoggerParameter_t`

#### `getInteger(String parameterDeveloperName, Integer defaultValue)` → `Integer`

Returns the configured value of the field `Value__c` as a `Integer`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Integer

**Description**

The `Integer` value configured in the matching instance of `LoggerParameter_t`

#### `getIntegerList(String parameterDeveloperName)` → `List<Integer>`

Returns the configured value of the field `Value__c` as a `List&lt;Integer&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Integer&gt;

**Description**

The `List&lt;Integer&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getIntegerList(String parameterDeveloperName, List<Integer> defaultValue)` → `List<Integer>`

Returns the configured value of the field `Value__c` as a `List&lt;Integer&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Integer&gt;

**Description**

The `List&lt;Integer&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getLong(String parameterDeveloperName)` → `Long`

Returns the configured value of the field `Value__c` as a `Long`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

Long

**Description**

The `Long` value configured in the matching instance of `LoggerParameter_t`

#### `getLong(String parameterDeveloperName, Long defaultValue)` → `Long`

Returns the configured value of the field `Value__c` as a `Long`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Long

**Description**

The `Long` value configured in the matching instance of `LoggerParameter_t`

#### `getLongList(String parameterDeveloperName)` → `List<Long>`

Returns the configured value of the field `Value__c` as a `List&lt;Long&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;Long&gt;

**Description**

The `List&lt;Long&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getLongList(String parameterDeveloperName, List<Long> defaultValue)` → `List<Long>`

Returns the configured value of the field `Value__c` as a `List&lt;Long&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Long&gt;

**Description**

The `List&lt;Long&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getSObject(String parameterDeveloperName)` → `SObject`

Returns the configured value of the field `Value__c` as a `SObject`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

SObject

**Description**

The `SObject` value configured in the matching instance of `LoggerParameter_t`

#### `getSObject(String parameterDeveloperName, SObject defaultValue)` → `SObject`

Returns the configured value of the field `Value__c` as a `SObject`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

SObject

**Description**

The `SObject` value configured in the matching instance of `LoggerParameter_t`

#### `getSObjectList(String parameterDeveloperName)` → `List<SObject>`

Returns the configured value of the field `Value__c` as a `List&lt;SObject&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;SObject&gt;

**Description**

The `List&lt;SObject&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getSObjectList(String parameterDeveloperName, List<SObject> defaultValue)` → `List<SObject>`

Returns the configured value of the field `Value__c` as a `List&lt;SObject&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;SObject&gt;

**Description**

The `List&lt;SObject&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getString(String parameterDeveloperName)` → `String`

Returns the configured value of the field `Value__c` as a `String`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

String

**Description**

The `String` value configured in the matching instance of `LoggerParameter_t`

#### `getString(String parameterDeveloperName, String defaultValue)` → `String`

#### `getStringList(String parameterDeveloperName)` → `List<String>`

Returns the configured value of the field `Value__c` as a `List&lt;String&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |

##### Return

**Type**

List&lt;String&gt;

**Description**

The `List&lt;String&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getStringList(String parameterDeveloperName, List<String> defaultValue)` → `List<String>`

---
