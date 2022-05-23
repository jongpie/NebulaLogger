//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Class used to cache query results returned by the selector classes
 */
public without sharing class LoggerCache {
    private static final TransactionCache TRANSACTION_CACHE_INSTANCE = new TransactionCache();

    @SuppressWarnings('PMD.ApexDoc')
    private interface Cacheable {
        Boolean contains(String keyName);
        Object get(String keyName);
        void put(String keyName, Object valueToCache);
    }

    /**
     * @description The instance `TransactionCache` used for any transaction-specific caching
     * @return   The singleton instance of `TransactionCache`
     */
    public static TransactionCache getTransactionCache() {
        return TRANSACTION_CACHE_INSTANCE;
    }

    /**
     * @description Manages any transaction-specific caching
     */
    public class TransactionCache implements Cacheable {
        private final Map<String, Object> cachedValues = new Map<String, Object>();

        @SuppressWarnings('PMD.EmptyStatementBlock')
        private TransactionCache() {
        }

        /**
         * @description Indicates if the specified key has already been added to the cache
         * @param  keyName The `String` key name to check for within the transaction cache
         * @return         The `Boolean` result
         */
        public Boolean contains(String keyName) {
            return this.cachedValues.containsKey(keyName);
        }

        /**
         * @description Returns the cached value for the specified key, or `null` if
         *              the specified key does not exist in the transaction cache
         * @param  keyName The `String` key name to check for within the transaction cache
         * @return         return description
         */
        public Object get(String keyName) {
            return this.cachedValues.get(keyName);
        }

        /**
         * @description Adds the provided `Object` value to the current transaction's cache,
         *              using the specified `String` key name
         * @param  keyName      The `String` key name to add to the transaction cache
         * @param  valueToCache The `Object` value to cache for the specified key name
         */
        public void put(String keyName, Object valueToCache) {
            this.cachedValues.put(keyName, valueToCache);
        }
    }
}
