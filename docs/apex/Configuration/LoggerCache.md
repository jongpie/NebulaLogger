---
layout: default
---

## LoggerCache class

Class used to cache query results returned by the selector classes

---

### Methods

#### `getOrganizationCache()` → `OrganizationCache`

The instance of `OrganizationCache` used for any organization-specific caching. When Platform Cache is disabled or not available, the transaction cache is instead used.

##### Return

**Type**

OrganizationCache

**Description**

The singleton instance of `OrganizationCache`

#### `getSessionCache()` → `SessionCache`

The instance of `SessionCache` used for any session-specific caching. When Platform Cache is disabled or not available, the transaction cache is instead used.

##### Return

**Type**

SessionCache

**Description**

The singleton instance of `SessionCache`

#### `getTransactionCache()` → `TransactionCache`

The instance of `TransactionCache` used for any transaction-specific caching. Cached data is stored internally in-memory for the duration of the transaction.

##### Return

**Type**

TransactionCache

**Description**

The singleton instance of `TransactionCache`

---

### Inner Classes

#### LoggerCache.OrganizationCache class

Manages any organization-specific caching, using org platform cache &amp; transaction cache

---

##### Methods

###### `contains(String key)` → `Boolean`

Indicates if the specified key has already been added to the cache

####### Parameters

| Param | Description                                                |
| ----- | ---------------------------------------------------------- |
| `key` | The `String` key to check for within the transaction cache |

####### Return

**Type**

Boolean

**Description**

The `Boolean` result that indicates if the specified key is contained in the cache

###### `get(String key)` → `Object`

Returns the cached value for the specified key, or `null` if the specified key does not exist in the transaction cache

####### Parameters

| Param | Description                                                |
| ----- | ---------------------------------------------------------- |
| `key` | The `String` key to check for within the transaction cache |

####### Return

**Type**

Object

**Description**

The cached value, or null if no cached value is found for the specified key

###### `put(String key, Object value)` → `void`

Adds the provided `Object` value to the current organization&apos;s cache, using the specified `String` key

####### Parameters

| Param   | Description                                       |
| ------- | ------------------------------------------------- |
| `key`   | The `String` key to add to the organization cache |
| `value` | The `Object` value to cache for the specified key |

###### `remove(String key)` → `void`

Removes the specified `String` key from the organization cache

####### Parameters

| Param | Description                                            |
| ----- | ------------------------------------------------------ |
| `key` | The `String` key to remove from the organization cache |

---

#### LoggerCache.SessionCache class

Manages any session-specific caching, using session platform cache &amp; transaction cache

---

##### Methods

###### `contains(String key)` → `Boolean`

Indicates if the specified key has already been added to the cache

####### Parameters

| Param | Description                                            |
| ----- | ------------------------------------------------------ |
| `key` | The `String` key to check for within the session cache |

####### Return

**Type**

Boolean

**Description**

The `Boolean` result that indicates if the specified key is contained in the cache

###### `get(String key)` → `Object`

Returns the cached value for the specified key, or `null` if the specified key does not exist in the session cache

####### Parameters

| Param | Description                                            |
| ----- | ------------------------------------------------------ |
| `key` | The `String` key to check for within the session cache |

####### Return

**Type**

Object

**Description**

The cached value, or null if no cached value is found for the specified key

###### `put(String key, Object value)` → `void`

Adds the provided `Object` value to the current session&apos;s cache, using the specified `String` key

####### Parameters

| Param   | Description                                       |
| ------- | ------------------------------------------------- |
| `key`   | The `String` key to add to the session cache      |
| `value` | The `Object` value to cache for the specified key |

###### `remove(String key)` → `void`

Removes the specified `String` key from the session cache

####### Parameters

| Param | Description                                       |
| ----- | ------------------------------------------------- |
| `key` | The `String` key to remove from the session cache |

---

#### LoggerCache.TransactionCache class

Manages any transaction-specific caching, using static final `Map&lt;String, Object&gt;`

---

##### Methods

###### `contains(String key)` → `Boolean`

Indicates if the specified key has already been added to the cache

####### Parameters

| Param | Description                                                |
| ----- | ---------------------------------------------------------- |
| `key` | The `String` key to check for within the transaction cache |

####### Return

**Type**

Boolean

**Description**

The `Boolean` result that indicates if the specified key is contained in the cache

###### `get(String key)` → `Object`

Returns the cached value for the specified key, or `null` if the specified key does not exist in the transaction cache

####### Parameters

| Param | Description                                                |
| ----- | ---------------------------------------------------------- |
| `key` | The `String` key to check for within the transaction cache |

####### Return

**Type**

Object

**Description**

The cached value, or null if no cached value is found for the specified key

###### `put(String key, Object value)` → `void`

Adds the provided `Object` value to the current transaction&apos;s cache, using the specified `String` key

####### Parameters

| Param   | Description                                       |
| ------- | ------------------------------------------------- |
| `key`   | The `String` key to add to the transaction cache  |
| `value` | The `Object` value to cache for the specified key |

###### `remove(String key)` → `void`

Removes the specified `String` key from the transaction cache

####### Parameters

| Param | Description                                           |
| ----- | ----------------------------------------------------- |
| `key` | The `String` key to remove from the transaction cache |

---
