---
layout: default
---

## LoggerCache class

Class used to cache query results &amp; data used in other parts of Nebula Logger

---

### Methods

#### `contains(String key)` → `Boolean`

Manages interacting with platform cache partitions, and can be mocked during unit tests so that tests don&apos;t have to rely on the actual platform cache partitions configured in the org.

#### `contains(String key)` → `Boolean`

Manages interacting with platform cache. The provided transaction cache instance is used internally as the primary caching method, and is further augmented by using Platform Cache to provide caching that spans multiple transactions.

#### `contains(String key)` → `Boolean`

Manages any transaction-specific caching, using `Map&lt;String, Object&gt;`

#### `get(String key)` → `Object`

#### `get(String key)` → `Object`

#### `get(String key)` → `Object`

#### `getOrganizationCache()` → `Cacheable`

The instance of `Cacheable` used for any organization-specific caching via Platform Cache. When Platform Cache is disabled or not available, the transaction cache is instead used.

##### Return

**Type**

Cacheable

**Description**

The singleton instance of `Cacheable`

#### `getSessionCache()` → `Cacheable`

The instance of `Cacheable` used for any session-specific caching via Platform Cache. When Platform Cache is disabled or not available, the transaction cache is instead used.

##### Return

**Type**

Cacheable

**Description**

The singleton instance of `Cacheable`

#### `getTransactionCache()` → `Cacheable`

The instance of `Cacheable` used for any transaction-specific caching. Cached data is stored internally in-memory for the duration of the transaction.

##### Return

**Type**

Cacheable

**Description**

The singleton instance of `Cacheable`

#### `isAvailable()` → `Boolean`

#### `put(String key, Object value, Integer cacheTtlSeconds, Cache.Visibility cacheVisiblity, Boolean isCacheImmutable)` → `void`

#### `put(String key, Object value)` → `void`

#### `put(String key, Object value)` → `void`

#### `remove(String key)` → `void`

#### `remove(String key)` → `void`

#### `remove(String key)` → `void`

---

### Inner Classes

#### LoggerCache.Cacheable interface

Interface used to define caches that can be used to store values via different mechanisms

---

##### Methods

###### `contains(String key)` → `Boolean`

Indicates if the specified key has already been added to the cache

####### Parameters

| Param | Description                                    |
| ----- | ---------------------------------------------- |
| `key` | The `String` key to check for within the cache |

####### Return

**Type**

Boolean

**Description**

The `Boolean` result that indicates if the specified key is contained in the cache

###### `get(String key)` → `Object`

Returns the cached value for the specified key, or `null` if the specified key does not exist in the cache

####### Parameters

| Param | Description                                    |
| ----- | ---------------------------------------------- |
| `key` | The `String` key to check for within the cache |

####### Return

**Type**

Object

**Description**

The cached value, or null if no cached value is found for the specified key

###### `put(String key, Object value)` → `void`

Adds the provided `Object` value to the cache, using the specified `String` key

####### Parameters

| Param   | Description                                       |
| ------- | ------------------------------------------------- |
| `key`   | The `String` key to add to the cache              |
| `value` | The `Object` value to cache for the specified key |

###### `remove(String key)` → `void`

Removes the specified `String` key from the cache

####### Parameters

| Param | Description                               |
| ----- | ----------------------------------------- |
| `key` | The `String` key to remove from the cache |

---
