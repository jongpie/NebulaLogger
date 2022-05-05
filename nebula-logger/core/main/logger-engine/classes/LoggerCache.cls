public without sharing class LoggerCache {
    private static final OrganizationCache ORGANIZATION_CACHE_INSTANCE = new OrganizationCache();
    private static final SessionCache SESSION_CACHE_INSTANCE = new SessionCache();
    private static final TransactionCache TRANSACTION_CACHE_INSTANCE = new TransactionCache();

    private static final String LOGGER_CACHE_PARTITION_NAME = 'LoggerCache';
    // private static final String LOGGER_CACHE_PARTITION_NAME = Namespace.getPrefixWithDelimiter('.') + 'LoggerCache';
    private static final Cache.OrgPartition ORG_CACHE_PARTITION = Cache.Org.getPartition(LOGGER_CACHE_PARTITION_NAME);
    private static final Cache.OrgPartition SESSION_CACHE_PARTITION = Cache.Org.getPartition(LOGGER_CACHE_PARTITION_NAME);

    private static final Boolean CACHE_IS_IMMUTABLE = true;
    private static final Integer CACHE_TTL_SECS = 86400; // 86,400 seconds == 24 hours
    private static final Cache.Visibility CACHE_VISIBILITY = Cache.Visibility.ALL;

    public static OrganizationCache getOrganizationCache() {
        return ORGANIZATION_CACHE_INSTANCE;
    }

    public static SessionCache getSessionCache() {
        return SESSION_CACHE_INSTANCE;
    }

    public static TransactionCache getTransactionCache() {
        return TRANSACTION_CACHE_INSTANCE;
    }

    public interface Cacheable {
        Boolean containsKey(String keyName);
        Object get(String keyName);
        void put(String keyName, Object valueToCache);
    }

    public class OrganizationCache implements Cacheable {
        @SuppressWarnings('PMD.EmptyStatementBlock')
        private OrganizationCache() {
        }

        public Boolean containsKey(String keyName) {
            return ORG_CACHE_PARTITION.contains(keyName);
        }

        public Object get(String keyName) {
            return ORG_CACHE_PARTITION.get(keyName);
        }

        public void put(String keyName, Object valueToCache) {
            ORG_CACHE_PARTITION.put(keyName, valueToCache, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
        }
    }

    public class SessionCache implements Cacheable {
        @SuppressWarnings('PMD.EmptyStatementBlock')
        private SessionCache() {
        }

        public Boolean containsKey(String keyName) {
            return SESSION_CACHE_PARTITION.contains(keyName);
        }

        public Object get(String keyName) {
            return SESSION_CACHE_PARTITION.get(keyName);
        }

        public void put(String keyName, Object valueToCache) {
            SESSION_CACHE_PARTITION.put(keyName, valueToCache, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
        }
    }

    public class TransactionCache implements Cacheable {
        private final Map<String, Object> cachedValues = new Map<String, Object>();

        @SuppressWarnings('PMD.EmptyStatementBlock')
        private TransactionCache() {
        }

        public Boolean containsKey(String keyName) {
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
