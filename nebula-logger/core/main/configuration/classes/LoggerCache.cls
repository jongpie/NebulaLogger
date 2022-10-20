//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used to cache query results returned by the selector classes
 */
public without sharing class LoggerCache {
    private static final Boolean CACHE_IS_IMMUTABLE = false;
    @TestVisible
    private static final String CACHE_PARTITION_NAME = getQualifiedParitionName('LoggerCache');
    private static final Cache.Visibility CACHE_VISIBILITY = Cache.Visibility.NAMESPACE;
    private static final Cache.OrgPartition ORGANIZATION_CACHE_PARTITION = Cache.Org.getPartition(CACHE_PARTITION_NAME);
    private static final Integer ORGANIZATION_CACHE_TTL_SECONDS = 86400; // 86,400 seconds == 24 hours, max allowd for org cache
    private static final Cache.SessionPartition SESSION_CACHE_PARTITION = Cache.Session.getPartition(CACHE_PARTITION_NAME);
    private static final Integer SESSION_CACHE_TTL_SECONDS = 28800; // 28,800 seconds == 8 hours, max allowd for session cache

    private static final OrganizationCache ORGANIZATION_CACHE_INSTANCE = new OrganizationCache();
    private static final SessionCache SESSION_CACHE_INSTANCE = new SessionCache();
    private static final TransactionCache TRANSACTION_CACHE_INSTANCE = new TransactionCache();

    @SuppressWarnings('PMD.ApexDoc')
    private interface Cacheable {
        Boolean contains(String key);
        Object get(String key);
        void put(String key, Object value);
        void remove(String key);
    }

    /**
     * @description The instance of `OrganizationCache` used for any organization-specific caching.
     *              When Platform Cache is disabled or not available, the transaction cache is instead used.
     * @return      The singleton instance of `OrganizationCache`
     */
    public static OrganizationCache getOrganizationCache() {
        return ORGANIZATION_CACHE_INSTANCE;
    }

    /**
     * @description The instance of `SessionCache` used for any session-specific caching.
     *              When Platform Cache is disabled or not available, the transaction cache is instead used.
     * @return      The singleton instance of `SessionCache`
     */
    public static SessionCache getSessionCache() {
        return SESSION_CACHE_INSTANCE;
    }

    /**
     * @description The instance of `TransactionCache` used for any transaction-specific caching.
     *              Cached data is stored internally in-memory for the duration of the transaction.
     * @return      The singleton instance of `TransactionCache`
     */
    public static TransactionCache getTransactionCache() {
        return TRANSACTION_CACHE_INSTANCE;
    }

    /**
     * @description Manages any organization-specific caching, using org platform cache & transaction cache
     */
    public class OrganizationCache implements Cacheable {
        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the transaction cache
         * @return     The `Boolean` result that indicates if the specified key is contained in the cache
         */
        public Boolean contains(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || getTransactionCache().contains(key)) {
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
        public Object get(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || getTransactionCache().contains(key)) {
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
        public void put(String key, Object value) {
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
        public void remove(String key) {
            getTransactionCache().remove(key);

            if (LoggerParameter.USE_PLATFORM_CACHE == true) {
                ORGANIZATION_CACHE_PARTITION.remove(key);
            }
        }
    }

    /**
     * @description Manages any session-specific caching, using session platform cache & transaction cache
     */
    public class SessionCache implements Cacheable {
        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the session cache
         * @return     The `Boolean` result that indicates if the specified key is contained in the cache
         */
        public Boolean contains(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || getTransactionCache().contains(key) || SESSION_CACHE_PARTITION.isAvailable() == false) {
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
        public Object get(String key) {
            if (LoggerParameter.USE_PLATFORM_CACHE == false || getTransactionCache().contains(key) || SESSION_CACHE_PARTITION.isAvailable() == false) {
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
        public void put(String key, Object value) {
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
        public void remove(String key) {
            getTransactionCache().remove(key);

            if (LoggerParameter.USE_PLATFORM_CACHE == true && SESSION_CACHE_PARTITION.isAvailable() == true) {
                SESSION_CACHE_PARTITION.remove(key);
            }
        }
    }

    /**
     * @description Manages any transaction-specific caching, using static final `Map<String, Object>`
     */
    public class TransactionCache implements Cacheable {
        private final Map<String, Object> keyToValue = new Map<String, Object>();

        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  key The `String` key to check for within the transaction cache
         * @return     The `Boolean` result that indicates if the specified key is contained in the cache
         */
        public Boolean contains(String key) {
            return this.keyToValue.containsKey(key);
        }

        /**
         * @description Returns the cached value for the specified key, or `null` if
         *              the specified key does not exist in the transaction cache
         * @param  key  The `String` key to check for within the transaction cache
         * @return      The cached value, or null if no cached value is found for the specified key
         */
        public Object get(String key) {
            return this.keyToValue.get(key);
        }

        /**
         * @description Adds the provided `Object` value to the current transaction's cache,
         *              using the specified `String` key
         * @param  key   The `String` key to add to the transaction cache
         * @param  value The `Object` value to cache for the specified key
         */
        public void put(String key, Object value) {
            this.keyToValue.put(key, value);
        }

        /**
         * @description Removes the specified `String` key from the transaction cache
         * @param  key  The `String` key to remove from the transaction cache
         */
        public void remove(String key) {
            this.keyToValue.remove(key);
        }
    }

    private static String getQualifiedParitionName(String unqualifiedPartitionName) {
        String className = LoggerCache.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') + '.' : '';
        return namespacePrefix + unqualifiedPartitionName;
    }
}
