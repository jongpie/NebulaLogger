//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used to cache query results returned by the selector classes
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessivePublicCount')
public without sharing class LoggerCache {
  private static final String DEFAULT_PARTITION_NAME = 'LoggerCache';
  private static final Boolean PLATFORM_CACHE_IS_IMMUTABLE = false;
  @TestVisible
  private static final String PLATFORM_CACHE_NULL_VALUE = '<{(CACHE_VALUE_IS_NULL)}>'; // Presumably, no one will ever use this as an actual value
  @TestVisible
  private static final String PLATFORM_CACHE_PARTITION_NAME = getQualifiedParitionName(LoggerParameter.PLATFORM_CACHE_PARTITION_NAME);
  private static final Cache.Visibility PLATFORM_CACHE_VISIBILITY = Cache.Visibility.NAMESPACE;
  private static final TransactionCache TRANSACTION_CACHE_INSTANCE = new TransactionCache();
  
  // Cache statistics tracking
  @TestVisible
  private static final Map<String, CacheStatistics> CACHE_STATISTICS = new Map<String, CacheStatistics>();

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
     * @description Returns multiple cached values for the specified keys
     * @param  keys The `Set<String>` keys to retrieve from the cache
     * @return      Map<String, Object> of key-value pairs found in the cache
     */
    Map<String, Object> getBulk(Set<String> keys);

    /**
     * @description Adds the provided `Object` value to the cache,
     *              using the specified `String` key
     * @param  key   The `String` key to add to the cache
     * @param  value The `Object` value to cache for the specified key
     */
    void put(String key, Object value);
    
    /**
     * @description Adds multiple key-value pairs to the cache in a single operation
     * @param  keyToValueMap The map of keys and values to cache
     */
    void putBulk(Map<String, Object> keyToValueMap);

    /**
     * @description Removes the specified `String` key from the cache
     * @param  key  The `String` key to remove from the cache
     */
    void remove(String key);
    
    /**
     * @description Removes multiple keys from the cache in a single operation
     * @param  keys The set of keys to remove from the cache
     */
    void removeBulk(Set<String> keys);
  }

  /**
   * @description The instance of `Cacheable` used for any organization-specific caching via Platform Cache.
   *              When Platform Cache is disabled or not available, the transaction cache is instead used.
   * @return      The singleton instance of `Cacheable`
   */
  public static Cacheable getOrganizationCache() {
    if (organizationCacheInstance == null) {
      Integer organizationCacheTtlSeconds = 86400; // 86,400 seconds == 24 hours, the max time-to-live (TTL) allowed for org cache
      organizationCacheInstance = new PlatformCache('Organization', getTransactionCache(), organizationPartitionDelegate, organizationCacheTtlSeconds);
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
      sessionCacheInstance = new PlatformCache('Session', getTransactionCache(), sessionPartitionDelegate, sessionCacheTtlSeconds);
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
  
  /**
   * @description Returns cache statistics for monitoring cache performance
   * @return      Map of cache name to CacheStatistics
   */
  public static Map<String, CacheStatistics> getCacheStatistics() {
    return CACHE_STATISTICS.clone();
  }

  private static String getQualifiedParitionName(String unqualifiedPartitionName) {
    // Since Nebula Logger includes a cache partition (LoggerCache), the included partition's name
    // needs to be qualified in order to work in the managed package. If a custom partition is being
    // used instead, then just use the partition name as-is - no namespace is added.
    if (unqualifiedPartitionName != DEFAULT_PARTITION_NAME) {
      return unqualifiedPartitionName;
    }

    // Cache the class name to avoid repeated calls to getName()
    static String qualifiedClassName;
    if (qualifiedClassName == null) {
      qualifiedClassName = LoggerCache.class.getName();
    }
    
    // Only perform string operations if needed
    return qualifiedClassName.contains('.') 
      ? qualifiedClassName.substringBefore('.') + '.' + unqualifiedPartitionName 
      : unqualifiedPartitionName;
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
   * @description Class for tracking cache performance statistics
   */
  public class CacheStatistics {
    public Integer hits = 0;
    public Integer misses = 0;
    public Integer puts = 0;
    public Integer removes = 0;
    
    public void incrementHits() {
      this.hits++;
    }
    
    public void incrementMisses() {
      this.misses++;
    }
    
    public void incrementPuts() {
      this.puts++;
    }
    
    public void incrementRemoves() {
      this.removes++;
    }
    
    public Decimal getHitRatio() {
      Integer totalRequests = this.hits + this.misses;
      return totalRequests > 0 ? (Decimal)this.hits / totalRequests : 0;
    }
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
    
    public virtual Map<String, Object> getBulk(Set<String> keys) {
      if (this.platformCachePartition == null) {
        return new Map<String, Object>();
      }
      
      Map<String, Object> results = new Map<String, Object>();
      for (String key : keys) {
        if (this.platformCachePartition.contains(key)) {
          results.put(key, this.platformCachePartition.get(key));
        }
      }
      return results;
    }

    public virtual Boolean isAvailable() {
      return this.platformCachePartition != null && this.platformCachePartition.isAvailable();
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public virtual void put(String key, Object value, Integer cacheTtlSeconds, Cache.Visibility cacheVisiblity, Boolean isCacheImmutable) {
      this.platformCachePartition?.put(key, value, cacheTtlSeconds, cacheVisiblity, isCacheImmutable);
    }
    
    public virtual void putBulk(Map<String, Object> keyToValueMap, Integer cacheTtlSeconds, Cache.Visibility cacheVisiblity, Boolean isCacheImmutable) {
      if (this.platformCachePartition == null) {
        return;
      }
      
      for (String key : keyToValueMap.keySet()) {
        this.platformCachePartition.put(key, keyToValueMap.get(key), cacheTtlSeconds, cacheVisiblity, isCacheImmutable);
      }
    }

    public virtual void remove(String key) {
      this.platformCachePartition?.remove(key);
    }
    
    public virtual void removeBulk(Set<String> keys) {
      if (this.platformCachePartition == null) {
        return;
      }
      
      for (String key : keys) {
        this.platformCachePartition.remove(key);
      }
    }
  }

  /**
   * @description Manages interacting with platform cache. The provided transaction cache instance is used internally as the primary
   *              caching method, and is further augmented by using Platform Cache to provide caching that spans multiple transactions.
   */
  @SuppressWarnings('PMD.ApexDoc')
  private class PlatformCache implements Cacheable {
    private final String cacheName;
    private final PlatformCachePartitionDelegate cachePartitionDelegate;
    private final Integer cacheTtlSeconds;
    private final Cacheable transactionCache;
    private final Boolean isPlatformCacheEnabled;

    private PlatformCache(String cacheName, Cacheable transactionCache, PlatformCachePartitionDelegate cachePartitionDelegate, Integer cacheTtlSeconds) {
      this.cacheName = cacheName;
      this.transactionCache = transactionCache;
      this.cachePartitionDelegate = cachePartitionDelegate;
      this.cacheTtlSeconds = cacheTtlSeconds;
      // Cache this value to avoid repeated parameter lookups
      this.isPlatformCacheEnabled = LoggerParameter.USE_PLATFORM_CACHE && this.cachePartitionDelegate.isAvailable();
      
      // Initialize statistics for this cache
      if (!CACHE_STATISTICS.containsKey(this.cacheName)) {
        CACHE_STATISTICS.put(this.cacheName, new CacheStatistics());
      }
    }

    public Boolean contains(String key) {
      // Check transaction cache first as it's faster than platform cache
      if (this.transactionCache.contains(key)) {
        return true;
      }
      // Only check platform cache if enabled and available
      if (this.isPlatformCacheEnabled) {
        return this.cachePartitionDelegate.contains(key);
      }
      return false;
    }

    public Object get(String key) {
      CacheStatistics stats = CACHE_STATISTICS.get(this.cacheName);
      
      // Check transaction cache first for better performance
      if (this.transactionCache.contains(key)) {
        stats.incrementHits();
        return this.transactionCache.get(key);
      }
      
      // Only check platform cache if enabled and available
      if (this.isPlatformCacheEnabled) {
        Object value = this.cachePartitionDelegate.get(key);
        // Platform cache does not support storing null values, so a predefined value is used as a substitute
        if (value == PLATFORM_CACHE_NULL_VALUE) {
          value = null;
        }
        // Store in transaction cache for future lookups
        this.transactionCache.put(key, value);
        
        if (value != null) {
          stats.incrementHits();
        } else {
          stats.incrementMisses();
        }
        
        return value;
      }
      
      // If we get here, the key doesn't exist in either cache
      stats.incrementMisses();
      return null;
    }
    
    public Map<String, Object> getBulk(Set<String> keys) {
      if (keys == null || keys.isEmpty()) {
        return new Map<String, Object>();
      }
      
      CacheStatistics stats = CACHE_STATISTICS.get(this.cacheName);
      Map<String, Object> results = new Map<String, Object>();
      Set<String> keysToFetchFromPlatformCache = new Set<String>();
      
      // First check transaction cache for all keys
      for (String key : keys) {
        if (this.transactionCache.contains(key)) {
          results.put(key, this.transactionCache.get(key));
          stats.incrementHits();
        } else {
          keysToFetchFromPlatformCache.add(key);
        }
      }
      
      // Only check platform cache for keys not found in transaction cache
      if (!keysToFetchFromPlatformCache.isEmpty() && this.isPlatformCacheEnabled) {
        Map<String, Object> platformCacheResults = this.cachePartitionDelegate.getBulk(keysToFetchFromPlatformCache);
        
        for (String key : keysToFetchFromPlatformCache) {
          if (platformCacheResults.containsKey(key)) {
            Object value = platformCacheResults.get(key);
            // Handle null value placeholder
            if (value == PLATFORM_CACHE_NULL_VALUE) {
              value = null;
            }
            results.put(key, value);
            this.transactionCache.put(key, value);
            stats.incrementHits();
          } else {
            stats.incrementMisses();
          }
        }
      } else if (!keysToFetchFromPlatformCache.isEmpty()) {
        // If platform cache is not enabled, count all missing keys as misses
        stats.incrementMisses();
      }
      
      return results;
    }

    public void put(String key, Object value) {
      CacheStatistics stats = CACHE_STATISTICS.get(this.cacheName);
      stats.incrementPuts();
      
      this.transactionCache.put(key, value);

      if (this.isPlatformCacheEnabled) {
        // Platform cache does not support storing null values, so a predefined value is used as a substitute
        if (value == null) {
          value = PLATFORM_CACHE_NULL_VALUE;
        }
        this.cachePartitionDelegate.put(key, value, this.cacheTtlSeconds, PLATFORM_CACHE_VISIBILITY, PLATFORM_CACHE_IS_IMMUTABLE);
      }
    }
    
    public void putBulk(Map<String, Object> keyToValueMap) {
      if (keyToValueMap == null || keyToValueMap.isEmpty()) {
        return;
      }
      
      CacheStatistics stats = CACHE_STATISTICS.get(this.cacheName);
      stats.incrementPuts();
      
      // Store all values in transaction cache
      for (String key : keyToValueMap.keySet()) {
        this.transactionCache.put(key, keyToValueMap.get(key));
      }
      
      // Store in platform cache if enabled
      if (this.isPlatformCacheEnabled) {
        Map<String, Object> platformCacheMap = new Map<String, Object>();
        
        for (String key : keyToValueMap.keySet()) {
          Object value = keyToValueMap.get(key);
          // Handle null values
          if (value == null) {
            platformCacheMap.put(key, PLATFORM_CACHE_NULL_VALUE);
          } else {
            platformCacheMap.put(key, value);
          }
        }
        
        this.cachePartitionDelegate.putBulk(platformCacheMap, this.cacheTtlSeconds, PLATFORM_CACHE_VISIBILITY, PLATFORM_CACHE_IS_IMMUTABLE);
      }
    }

    public void remove(String key) {
      CacheStatistics stats = CACHE_STATISTICS.get(this.cacheName);
      stats.incrementRemoves();
      
      this.transactionCache.remove(key);

      if (this.isPlatformCacheEnabled) {
        this.cachePartitionDelegate.remove(key);
      }
    }
    
    public void removeBulk(Set<String> keys) {
      if (keys == null || keys.isEmpty()) {
        return;
      }
      
      CacheStatistics stats = CACHE_STATISTICS.get(this.cacheName);
      stats.incrementRemoves();
      
      // Remove from transaction cache
      for (String key : keys) {
        this.transactionCache.remove(key);
      }
      
      // Remove from platform cache if enabled
      if (this.isPlatformCacheEnabled) {
        this.cachePartitionDelegate.removeBulk(keys);
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
      return key != null && this.keyToValue.containsKey(key);
    }

    public Object get(String key) {
      return key != null ? this.keyToValue.get(key) : null;
    }
    
    public Map<String, Object> getBulk(Set<String> keys) {
      if (keys == null || keys.isEmpty()) {
        return new Map<String, Object>();
      }
      
      Map<String, Object> results = new Map<String, Object>();
      for (String key : keys) {
        if (key != null && this.keyToValue.containsKey(key)) {
          results.put(key, this.keyToValue.get(key));
        }
      }
      return results;
    }

    public void put(String key, Object value) {
      if (key != null) {
        this.keyToValue.put(key, value);
      }
    }
    
    public void putBulk(Map<String, Object> keyToValueMap) {
      if (keyToValueMap == null || keyToValueMap.isEmpty()) {
        return;
      }
      
      for (String key : keyToValueMap.keySet()) {
        if (key != null) {
          this.keyToValue.put(key, keyToValueMap.get(key));
        }
      }
    }

    public void remove(String key) {
      if (key != null) {
        this.keyToValue.remove(key);
      }
    }
    
    public void removeBulk(Set<String> keys) {
      if (keys == null || keys.isEmpty()) {
        return;
      }
      
      for (String key : keys) {
        if (key != null) {
          this.keyToValue.remove(key);
        }
      }
    }
  }
}
