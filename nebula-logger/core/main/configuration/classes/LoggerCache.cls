//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used to cache query results returned by the selector classes
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class LoggerCache {
    private static final String DEFAULT_PARTITION_NAME = 'LoggerCache';
    private static final Boolean PLATFORM_CACHE_IS_IMMUTABLE = false;
    @TestVisible
    private static final String PLATFORM_CACHE_NULL_VALUE = '<{(CACHE_VALUE_IS_NULL)}>'; // Presumably, no one will ever use this as an actual value
    @TestVisible
    private static final String PLATFORM_CACHE_PARTITION_NAME = getQualifiedParitionName(LoggerParameter.PLATFORM_CACHE_PARTITION_NAME);
    private static final Cache.Visibility PLATFORM_CACHE_VISIBILITY = Cache.Visibility.NAMESPACE;
    private static final TransactionCache TRANSACTION_CACHE_INSTANCE = new TransactionCache();

    private static PlatformCachePartitionDelegate organizationPartitionDelegate = new PlatformCachePartitionDelegate(
        PlatformCachePartitionType.ORGANIZATION,
        PLATFORM_CACHE_PARTITION_NAME
    );
    private static PlatformCachePartitionDelegate sessionPartitionDelegate = new PlatformCachePartitionDelegate(
        PlatformCachePartitionType.SESSION,
        PLATFORM_CACHE_PARTITION_NAME
    );
    private static PlatformCache organizationCacheInstance;
    private static PlatformCache sessionCacheInstance;

    @TestVisible
    private enum PlatformCachePartitionType {
        ORGANIZATION,
        SESSION
    }

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
         * @param  key   The `String` key to add to the cache
         * @param  value The `Object` value to cache for the specified key
         */
        void put(String key, Object value);

        /**
         * @description Removes the specified `String` key from the cache
         * @param  key  The `String` key to remove from the cache
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
            Integer organizationCacheTtlSeconds = 86400; // 86,400 seconds == 24 hours, the max time-to-live (TTL) allowed for org cache
            organizationCacheInstance = new PlatformCache(getTransactionCache(), organizationPartitionDelegate, organizationCacheTtlSeconds);
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
            Integer sessionCacheTtlSeconds = 28800; // 28,800 seconds == 8 hours, the max time-to-live (TTL) allowed for session cache
            sessionCacheInstance = new PlatformCache(getTransactionCache(), sessionPartitionDelegate, sessionCacheTtlSeconds);
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
        // Since Nebula Logger includes a cache partition (LoggerCache), the included partition's name
        // needs to be qualified in order to work in the managed package. If a custom partition is being
        // used instead, then just use the partition name as-is - no namespace is added.
        if (unqualifiedPartitionName != DEFAULT_PARTITION_NAME) {
            return unqualifiedPartitionName;
        }

        String qualifiedClassName = LoggerCache.class.getName();
        String namespacePrefix = qualifiedClassName.contains('.') ? qualifiedClassName.substringBefore('.') + '.' : '';
        return namespacePrefix + unqualifiedPartitionName;
    }

    @TestVisible
    private static void setMockOrganizationPartitionDelegate(PlatformCachePartitionDelegate mockOrganizationPartitionDelegate) {
        organizationPartitionDelegate = mockOrganizationPartitionDelegate;
    }

    @TestVisible
    private static void setMockSessionPartitionDelegate(PlatformCachePartitionDelegate mockSessionPartitionDelegate) {
        sessionPartitionDelegate = mockSessionPartitionDelegate;
    }

    /**
     * @description Manages interacting with platform cache partitions, and can be mocked during unit tests
     *              so that tests don't have to rely on the actual platform cache partitions configured in the org.
     */
    @SuppressWarnings('PMD.ApexDoc, PMD.EmptyCatchBlock')
    @TestVisible
    private virtual class PlatformCachePartitionDelegate {
        private final Cache.Partition platformCachePartition;

        protected PlatformCachePartitionDelegate(PlatformCachePartitionType partitionType, String partitionName) {
            // Since orgs can customize the platform cache partition (via LoggerParameter__mdt.PlatformCachePartitionName),
            // some orgs could have problematic configurations (or may have even deleted the included LoggerCache partition),
            // and it seems better to eat the exceptions & fallback to the transaction cache (which doesn't rely on Platform Cache).
            // The alternative is a runtime exception, which isn't ideal.
            try {
                switch on partitionType {
                    when ORGANIZATION {
                        this.platformCachePartition = Cache.Org.getPartition(partitionName);
                    }
                    when SESSION {
                        this.platformCachePartition = Cache.Session.getPartition(partitionName);
                    }
                }
            } catch (Cache.Org.OrgCacheException orgCacheException) {
                // No-op if the partition can't be found - the rest of the code will fallback to using the transaction cache
            } catch (Cache.Session.SessionCacheException sessionCacheException) {
                // No-op if the partition can't be found - the rest of the code will fallback to using the transaction cache
            }
        }

        public virtual Boolean contains(String key) {
            return this.platformCachePartition != null && this.platformCachePartition.contains(key);
        }

        public virtual Object get(String key) {
            return this.platformCachePartition?.get(key);
        }

        public virtual Boolean isAvailable() {
            return this.platformCachePartition != null && this.platformCachePartition.isAvailable();
        }

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public virtual void put(String key, Object value, Integer cacheTtlSeconds, Cache.Visibility cacheVisiblity, Boolean isCacheImmutable) {
            this.platformCachePartition?.put(key, value, cacheTtlSeconds, cacheVisiblity, isCacheImmutable);
        }

        public virtual void remove(String key) {
            this.platformCachePartition?.remove(key);
        }
    }

    /**
     * @description Manages interacting with platform cache. The provided transaction cache instance is used internally as the primary
     *              caching method, and is further augmented by using Platform Cache to provide caching that spans multiple transactions.
     */
    @SuppressWarnings('PMD.ApexDoc')
    private class PlatformCache implements Cacheable {
        private final PlatformCachePartitionDelegate cachePartitionDelegate;
        private final Integer cacheTtlSeconds;
        private final Cacheable transactionCache;

        private PlatformCache(Cacheable transactionCache, PlatformCachePartitionDelegate cachePartitionDelegate, Integer cacheTtlSeconds) {
            this.transactionCache = transactionCache;
            this.cachePartitionDelegate = cachePartitionDelegate;
            this.cacheTtlSeconds = cacheTtlSeconds;
        }

        public Boolean contains(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || this.transactionCache.contains(key) || this.cachePartitionDelegate.isAvailable() == false) {
                return this.transactionCache.contains(key);
            } else {
                return this.cachePartitionDelegate.contains(key);
            }
        }

        public Object get(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || this.transactionCache.contains(key) || this.cachePartitionDelegate.isAvailable() == false) {
                return this.transactionCache.get(key);
            } else {
                Object value = this.cachePartitionDelegate.get(key);
                // Platform cache does not support storing null values, so a predefined value is used as a substitute
                if (value == PLATFORM_CACHE_NULL_VALUE) {
                    value = null;
                }
                this.transactionCache.put(key, value);
                return value;
            }
        }

        public void put(String key, Object value) {
            this.transactionCache.put(key, value);

            if (LoggerParameter.USE_PLATFORM_CACHE && this.cachePartitionDelegate.isAvailable()) {
                // Platform cache does not support storing null values, so a predefined value is used as a substitute
                if (value == null) {
                    value = PLATFORM_CACHE_NULL_VALUE;
                }
                this.cachePartitionDelegate.put(key, value, this.cacheTtlSeconds, PLATFORM_CACHE_VISIBILITY, PLATFORM_CACHE_IS_IMMUTABLE);
            }
        }

        public void remove(String key) {
            this.transactionCache.remove(key);

            if (LoggerParameter.USE_PLATFORM_CACHE && this.cachePartitionDelegate.isAvailable()) {
                this.cachePartitionDelegate.remove(key);
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
