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

    public static TransactionCache getTransactionCache() {
        return TRANSACTION_CACHE_INSTANCE;
    }

    public interface Cacheable {
        Boolean contains(String keyName);
        Object get(String keyName);
        void put(String keyName, Object valueToCache);
    }

    public class TransactionCache implements Cacheable {
        private final Map<String, Object> cachedValues = new Map<String, Object>();

        @SuppressWarnings('PMD.EmptyStatementBlock')
        private TransactionCache() {
        }

        public Boolean contains(String keyName) {
            return this.cachedValues.containsKey(keyName);
        }

        public Object get(String keyName) {
            return this.cachedValues.get(keyName);
        }

        public void put(String keyName, Object valueToCache) {
            this.cachedValues.put(keyName, valueToCache);
        }
    }
}
