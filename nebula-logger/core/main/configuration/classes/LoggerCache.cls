//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used to cache query results returned by the selector classes
 */
public without sharing class LoggerCache {
    private static final Boolean PLATFORM_CACHE_IS_IMMUTABLE = false;
    @TestVisible
    private static final String PLATFORM_CACHE_PARTITION_NAME = getQualifiedParitionName('LoggerCache');
    private static final Cache.Visibility PLATFORM_CACHE_VISIBILITY = Cache.Visibility.NAMESPACE;
    private static final TransactionCache TRANSACTION_CACHE_INSTANCE = new TransactionCache();

    private static PlatformCache organizationCacheInstance;
    private static PlatformCache sessionCacheInstance;

    /**
     * @description Interface used to define caches that can be used to store values via different mechanisms
     */
    public interface Cacheable {
        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the cache
         * @return     The `Boolean` result that indicates if the specified key is contained in the cache
         */
        Boolean contains(String key);

        /**
         * @description Returns the cached value for the specified key, or `null` if
         *              the specified key does not exist in the cache
         * @param  key  The `String` key to check for within the cache
         * @return      The cached value, or null if no cached value is found for the specified key
         */
        Object get(String key);

        /**
         * @description Adds the provided `Object` value to the cache,
         *              using the specified `String` key
         * @param  key   The `String` key to add to the organization cache
         * @param  value The `Object` value to cache for the specified key
         */
        void put(String key, Object value);

        /**
         * @description Removes the specified `String` key from the session cache
         * @param  key  The `String` key to remove from the session cache
         */
        void remove(String key);
    }

    /**
     * @description The instance of `Cacheable` used for any organization-specific caching via Platform Cache.
     *              When Platform Cache is disabled or not available, the transaction cache is instead used.
     * @return      The singleton instance of `Cacheable`
     */
    public static Cacheable getOrganizationCache() {
        if (organizationCacheInstance == null) {
            Cache.Partition organizationPartition = Cache.Org.getPartition(PLATFORM_CACHE_PARTITION_NAME);
            Integer organizationCacheTtlSeconds = 86400; // 86,400 seconds == 24 hours, the max time-to-live (TTL) allowed for org cache
            organizationCacheInstance = new PlatformCache(getTransactionCache(), organizationPartition, organizationCacheTtlSeconds);
        }
        return organizationCacheInstance;
    }

    /**
     * @description The instance of `Cacheable` used for any session-specific caching via Platform Cache.
     *              When Platform Cache is disabled or not available, the transaction cache is instead used.
     * @return      The singleton instance of `Cacheable`
     */
    public static Cacheable getSessionCache() {
        if (sessionCacheInstance == null) {
            Cache.Partition sessionPartition = Cache.Session.getPartition(PLATFORM_CACHE_PARTITION_NAME);
            Integer sessionCacheTtlSeconds = 28800; // 28,800 seconds == 8 hours, the max time-to-live (TTL) allowed for session cache
            sessionCacheInstance = new PlatformCache(getTransactionCache(), sessionPartition, sessionCacheTtlSeconds);
        }
        return sessionCacheInstance;
    }

    /**
     * @description The instance of `Cacheable` used for any transaction-specific caching.
     *              Cached data is stored internally in-memory for the duration of the transaction.
     * @return      The singleton instance of `Cacheable`
     */
    public static Cacheable getTransactionCache() {
        return TRANSACTION_CACHE_INSTANCE;
    }

    private static String getQualifiedParitionName(String unqualifiedPartitionName) {
        String className = LoggerCache.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') + '.' : '';
        return namespacePrefix + unqualifiedPartitionName;
    }

    /**
     * @description Manages interacting with platform cache partitions.
     *              The provided transaction cache instance is used internally as the primary caching method,
     *              and is further augmented by using Platform Cache to provide caching that spans multiple transactions.
     */
    @SuppressWarnings('PMD.ApexDoc')
    private class PlatformCache implements Cacheable {
        private final Cache.Partition cachePartition;
        private final Integer cacheTtlSeconds;
        private final Cacheable transactionCache;

        private PlatformCache(Cacheable transactionCache, Cache.Partition cachePartition, Integer cacheTtlSeconds) {
            this.transactionCache = transactionCache;
            this.cachePartition = cachePartition;
            this.cacheTtlSeconds = cacheTtlSeconds;
        }

        public Boolean contains(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || this.transactionCache.contains(key) || this.cachePartition.isAvailable() == false) {
                return this.transactionCache.contains(key);
            } else {
                return this.cachePartition.contains(key);
            }
        }

        public Object get(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || this.transactionCache.contains(key) || this.cachePartition.isAvailable() == false) {
                return this.transactionCache.get(key);
            } else {
                Object value = this.cachePartition.get(key);
                this.transactionCache.put(key, value);
                return value;
            }
        }

        public void put(String key, Object value) {
            this.transactionCache.put(key, value);

            // Platform cache does not support storing null values
            if (LoggerParameter.USE_PLATFORM_CACHE == true && value != null && this.cachePartition.isAvailable() == true) {
                this.cachePartition.put(key, value, this.cacheTtlSeconds, PLATFORM_CACHE_VISIBILITY, PLATFORM_CACHE_IS_IMMUTABLE);
            }
        }

        public void remove(String key) {
            this.transactionCache.remove(key);

            if (LoggerParameter.USE_PLATFORM_CACHE == true && this.cachePartition.isAvailable() == true) {
                this.cachePartition.remove(key);
            }
        }
    }

    /**
     * @description Manages any transaction-specific caching, using `Map<String, Object>`
     */
    @SuppressWarnings('PMD.ApexDoc')
    private class TransactionCache implements Cacheable {
        private final Map<String, Object> keyToValue = new Map<String, Object>();

        public Boolean contains(String key) {
            return this.keyToValue.containsKey(key);
        }

        public Object get(String key) {
            return this.keyToValue.get(key);
        }

        public void put(String key, Object value) {
            this.keyToValue.put(key, value);
        }

        public void remove(String key) {
            this.keyToValue.remove(key);
        }
    }
}
