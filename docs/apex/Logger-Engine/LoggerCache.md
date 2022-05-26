---
layout: default
---

## LoggerCache class

Class used to cache query results returned by the selector classes

---

### Methods

#### `getTransactionCache()` → `TransactionCache`

The instance `TransactionCache` used for any transaction-specific caching

##### Return

**Type**

TransactionCache

**Description**

The singleton instance of `TransactionCache`

---

### Inner Classes

#### LoggerCache.TransactionCache class

Manages any transaction-specific caching

---

##### Methods

###### `contains(String keyName)` → `Boolean`

Indicates if the specified key has already been added to the cache

####### Parameters

| Param     | Description                                                     |
| --------- | --------------------------------------------------------------- |
| `keyName` | The `String` key name to check for within the transaction cache |

####### Return

**Type**

Boolean

**Description**

The `Boolean` result

###### `get(String keyName)` → `Object`

Returns the cached value for the specified key, or `null` if the specified key does not exist in the transaction cache

####### Parameters

| Param     | Description                                                     |
| --------- | --------------------------------------------------------------- |
| `keyName` | The `String` key name to check for within the transaction cache |

####### Return

**Type**

Object

**Description**

return description

###### `put(String keyName, Object valueToCache)` → `void`

Adds the provided `Object` value to the current transaction&apos;s cache, using the specified `String` key name

####### Parameters

| Param          | Description                                            |
| -------------- | ------------------------------------------------------ |
| `keyName`      | The `String` key name to add to the transaction cache  |
| `valueToCache` | The `Object` value to cache for the specified key name |

---
