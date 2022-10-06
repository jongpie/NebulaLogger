//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Class used to cache query results returned by the selector classes
 */
public without sharing class LoggerCache {
    private static final Boolean CACHE_IS_IMMUTABLE = false;
    @TestVisible
    private static final String CACHE_PARTITION_NAME = getNamespacePrefix('.') + 'LoggerCache';
    private static final Cache.Visibility CACHE_VISIBILITY = Cache.Visibility.ALL;
    private static final Cache.OrgPartition ORGANIZATION_CACHE_PARTITION = Cache.Org.getPartition(CACHE_PARTITION_NAME);
    private static final Integer ORGANIZATION_CACHE_TTL_SECONDS = 86400; // 86,400 seconds == 24 hours, max allowd for org cache
    private static final Cache.SessionPartition SESSION_CACHE_PARTITION = Cache.Session.getPartition(CACHE_PARTITION_NAME);
    private static final Integer SESSION_CACHE_TTL_SECONDS = 28800; // 28,800 seconds == 8 hours, max allowd for session cache

    private static OrganizationCache organizationCacheInstance = new OrganizationCache();
    private static SessionCache sessionCacheInstance = new SessionCache();
    private static TransactionCache transactionCacheInstance = new TransactionCache();

    @SuppressWarnings('PMD.ApexDoc')
    private interface Cacheable {
        Boolean contains(String key);
        Object get(String key);
        void put(String key, Object value);
        void remove(String key);
    }

    /**
     * @description The instance of `OrganizationCache` used for any organization-specific caching.
     *              When Platform Cache is disabled, the transaction cache is instead used.
     * @return      The singleton instance of `OrganizationCache`
     */
    public static OrganizationCache getOrganizationCache() {
        return organizationCacheInstance;
    }

    /**
     * @description The instance of `SessionCache` used for any session-specific caching.
     *              When Platform Cache is disabled, the transaction cache is instead used.
     * @return      The singleton instance of `SessionCache`
     */
    public static SessionCache getSessionCache() {
        return sessionCacheInstance;
    }

    /**
     * @description The instance of `TransactionCache` used for any transaction-specific caching.
     *              Cached data is stored internally in-memory for the duration of the transaction.
     * @return      The singleton instance of `TransactionCache`
     */
    public static TransactionCache getTransactionCache() {
        return transactionCacheInstance;
    }

    /**
     * @description Manages any organization-specific caching
     */
    public virtual class OrganizationCache implements Cacheable {
        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the transaction cache
         * @return     The `Boolean` result
         */
        public virtual Boolean contains(String key) {
            if (getTransactionCache().contains(key) || LoggerParameter.USE_PLATFORM_CACHE == false) {
                return getTransactionCache().contains(key);
            } else {
                return ORGANIZATION_CACHE_PARTITION.contains(key);
            }
        }

        /**
         * @description Returns the cached value for the specified key, or `null` if
         *              the specified key does not exist in the transaction cache
         * @param  key  The `String` key to check for within the transaction cache
         * @return      The cached value, or null if no cached value is found for the specified key
         */
        public virtual Object get(String key) {
            if (getTransactionCache().contains(key) || LoggerParameter.USE_PLATFORM_CACHE == false) {
                return getTransactionCache().get(key);
            } else {
                Object value = ORGANIZATION_CACHE_PARTITION.get(key);
                getTransactionCache().put(key, value);
                return value;
            }
        }

        /**
         * @description Adds the provided `Object` value to the current organization's cache,
         *              using the specified `String` key
         * @param  key   The `String` key to add to the organization cache
         * @param  value The `Object` value to cache for the specified key
         */
        public virtual void put(String key, Object value) {
            getTransactionCache().put(key, value);

            // Platform cache does not support storing null values
            if (LoggerParameter.USE_PLATFORM_CACHE == true && value != null) {
                ORGANIZATION_CACHE_PARTITION.put(key, value, ORGANIZATION_CACHE_TTL_SECONDS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            }
        }

        /**
         * @description Removes the specified `String` key from the organization cache
         * @param  key  The `String` key to remove from the organization cache
         */
        public virtual void remove(String key) {
            getTransactionCache().remove(key);

            if (LoggerParameter.USE_PLATFORM_CACHE == true) {
                ORGANIZATION_CACHE_PARTITION.remove(key);
            }
        }
    }

    /**
     * @description Manages any session-specific caching
     */
    public virtual class SessionCache implements Cacheable {
        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the session cache
         * @return     The `Boolean` result
         */
        public virtual Boolean contains(String key) {
            if (getTransactionCache().contains(key) || LoggerParameter.USE_PLATFORM_CACHE == false || SESSION_CACHE_PARTITION.isAvailable() == false) {
                return getTransactionCache().contains(key);
            } else {
                return SESSION_CACHE_PARTITION.contains(key);
            }
        }

        /**
         * @description Returns the cached value for the specified key, or `null` if
         *              the specified key does not exist in the session cache
         * @param  key  The `String` key to check for within the session cache
         * @return      The cached value, or null if no cached value is found for the specified key
         */
        public virtual Object get(String key) {
            if (getTransactionCache().contains(key) || LoggerParameter.USE_PLATFORM_CACHE == false || SESSION_CACHE_PARTITION.isAvailable() == false) {
                return getTransactionCache().get(key);
            } else {
                Object value = SESSION_CACHE_PARTITION.get(key);
                getTransactionCache().put(key, value);
                return value;
            }
        }

        /**
         * @description Adds the provided `Object` value to the current session's cache,
         *              using the specified `String` key
         * @param  key   The `String` key to add to the session cache
         * @param  value The `Object` value to cache for the specified key
         */
        public virtual void put(String key, Object value) {
            getTransactionCache().put(key, value);

            // Platform cache does not support storing null values
            if (LoggerParameter.USE_PLATFORM_CACHE == true && value != null && SESSION_CACHE_PARTITION.isAvailable() == true) {
                SESSION_CACHE_PARTITION.put(key, value, SESSION_CACHE_TTL_SECONDS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            }
        }

        /**
         * @description Removes the specified `String` key from the session cache
         * @param  key  The `String` key to remove from the session cache
         */
        public virtual void remove(String key) {
            getTransactionCache().remove(key);

            if (LoggerParameter.USE_PLATFORM_CACHE == true && SESSION_CACHE_PARTITION.isAvailable() == true) {
                SESSION_CACHE_PARTITION.remove(key);
            }
        }
    }

    /**
     * @description Manages any transaction-specific caching
     */
    public virtual class TransactionCache implements Cacheable {
        private final Map<String, Object> cachedValues = new Map<String, Object>();

        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the transaction cache
         * @return     The `Boolean` result
         */
        public virtual Boolean contains(String key) {
            return this.cachedValues.containsKey(key);
        }

        /**
         * @description Returns the cached value for the specified key, or `null` if
         *              the specified key does not exist in the transaction cache
         * @param  key  The `String` key to check for within the transaction cache
         * @return      The cached value, or null if no cached value is found for the specified key
         */
        public virtual Object get(String key) {
            return this.cachedValues.get(key);
        }

        /**
         * @description Adds the provided `Object` value to the current transaction's cache,
         *              using the specified `String` key
         * @param  key   The `String` key to add to the transaction cache
         * @param  value The `Object` value to cache for the specified key
         */
        public virtual void put(String key, Object value) {
            this.cachedValues.put(key, value);
        }

        /**
         * @description Removes the specified `String` key from the transaction cache
         * @param  key  The `String` key to remove from the transaction cache
         */
        public virtual void remove(String key) {
            this.cachedValues.remove(key);
        }
    }

    @TestVisible
    private static void setMock(OrganizationCache organizationCache) {
        organizationCacheInstance = organizationCache;
    }

    @TestVisible
    private static void setMock(SessionCache sessionCache) {
        sessionCacheInstance = sessionCache;
    }

    @TestVisible
    private static void setMock(TransactionCache transactionCache) {
        transactionCacheInstance = transactionCache;
    }

    private static String getNamespacePrefix(String delimiter) {
        String className = LoggerCache.class.getName();
        return className.contains('.') ? className.substringBefore('.') + delimiter : '';
    }
}
