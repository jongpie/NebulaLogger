//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description When testing Platform Cache partitions, there is no way to directly mock the partitions. Furthermore, the partitions
 *              configured in the org are actually used in test contexts, so if a partition exists but does not have storage space
 *              allocated in the org, then any tests that try to assert that data is cached in the partitions will fail.
 *              To help overcome this platform limitation, this test class only runs in Nebula Logger's pipeline - this ensures that the tests
 *              are running in an org that has a platform cache partition with space allocated.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerCache_Tests_PlatformCache {
  @IsTest
  static void it_gracefully_handles_nonexistent_platform_cache_partition_name_for_organization_cache() {
    LoggerParameter__mdt platformCachePartitionNameParameter = new LoggerParameter__mdt(
      DeveloperName = 'PlatformCachePartitionName',
      Value__c = 'SomeValueThatWillHopefullyAndProbablyNeverExistForAPlatformCachePartitionName'
    );
    LoggerParameter.setMock(platformCachePartitionNameParameter);

    LoggerCache.Cacheable organizationCache = LoggerCache.getOrganizationCache();

    // Run the different Cacheable methods to ensure everything works
    String testKey = 'someKey';
    Object testValue = System.Datetime.now();
    System.Assert.isNotNull(organizationCache);
    System.Assert.isFalse(organizationCache.contains(testKey));
    System.Assert.areEqual(
      organizationCache.contains(testKey),
      LoggerCache.getTransactionCache().contains(testKey),
      'Organization and transaction cache should be in sync'
    );
    System.Assert.isNull(organizationCache.get(testKey));
    System.Assert.areEqual(
      organizationCache.get(testKey),
      LoggerCache.getTransactionCache().get(testKey),
      'Organization and transaction cache should be in sync'
    );
    organizationCache.remove(testKey);
    organizationCache.put(testKey, testValue);
    System.Assert.isTrue(organizationCache.contains(testKey));
    System.Assert.areEqual(
      organizationCache.contains(testKey),
      LoggerCache.getTransactionCache().contains(testKey),
      'Organization and transaction cache should be in sync'
    );
    System.Assert.areEqual(testValue, organizationCache.get(testKey));
    System.Assert.areEqual(
      organizationCache.get(testKey),
      LoggerCache.getTransactionCache().get(testKey),
      'Organization and transaction cache should be in sync'
    );
    organizationCache.remove(testKey);
    System.Assert.isNull(organizationCache.get(testKey));
    System.Assert.areEqual(
      organizationCache.get(testKey),
      LoggerCache.getTransactionCache().get(testKey),
      'Organization and transaction cache should be in sync'
    );
  }

  @IsTest
  static void it_gracefully_handles_nonexistent_platform_cache_partition_name_for_session_cache() {
    LoggerParameter__mdt platformCachePartitionNameParameter = new LoggerParameter__mdt(
      DeveloperName = 'PlatformCachePartitionName',
      Value__c = 'SomeValueThatWillHopefullyAndProbablyNeverExistForAPlatformCachePartitionName'
    );
    LoggerParameter.setMock(platformCachePartitionNameParameter);

    LoggerCache.Cacheable sessionCache = LoggerCache.getSessionCache();

    // Run the different Cacheable methods to ensure everything works
    String testKey = 'someKey';
    Object testValue = System.Datetime.now();
    System.Assert.isNotNull(sessionCache);
    System.Assert.isFalse(sessionCache.contains(testKey));
    System.Assert.areEqual(
      sessionCache.contains(testKey),
      LoggerCache.getTransactionCache().contains(testKey),
      'Session and transaction cache should be in sync'
    );
    System.Assert.isNull(sessionCache.get(testKey));
    System.Assert.areEqual(sessionCache.get(testKey), LoggerCache.getTransactionCache().get(testKey), 'Session and transaction cache should be in sync');
    sessionCache.remove(testKey);
    sessionCache.put(testKey, testValue);
    System.Assert.isTrue(sessionCache.contains(testKey));
    System.Assert.areEqual(
      sessionCache.contains(testKey),
      LoggerCache.getTransactionCache().contains(testKey),
      'Session and transaction cache should be in sync'
    );
    System.Assert.areEqual(testValue, sessionCache.get(testKey));
    System.Assert.areEqual(sessionCache.get(testKey), LoggerCache.getTransactionCache().get(testKey), 'Session and transaction cache should be in sync');
    sessionCache.remove(testKey);
    System.Assert.isNull(sessionCache.get(testKey));
    System.Assert.areEqual(sessionCache.get(testKey), LoggerCache.getTransactionCache().get(testKey), 'Session and transaction cache should be in sync');
  }

  @IsTest
  static void it_adds_new_key_to_organization_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User mockValue = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    System.Assert.isFalse(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));

    LoggerCache.getOrganizationCache().put(mockKey, mockValue);

    System.Assert.isTrue(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
    System.Assert.isTrue(Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
    System.Assert.areEqual(mockValue, Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getTransactionCache().get(mockKey));
  }

  @IsTest
  static void it_adds_new_key_with_null_value_to_organization_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User mockValue = null;
    System.Assert.isFalse(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));

    LoggerCache.getOrganizationCache().put(mockKey, mockValue);

    System.Assert.isTrue(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
    System.Assert.isTrue(Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
    System.Assert.areEqual(LoggerCache.PLATFORM_CACHE_NULL_VALUE, Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getTransactionCache().get(mockKey));
  }

  @IsTest
  static void it_updates_value_for_existing_key_in_organization_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User oldMockValue = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    LoggerCache.getOrganizationCache().put(mockKey, oldMockValue);
    System.Assert.isTrue(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.areEqual(oldMockValue, LoggerCache.getOrganizationCache().get(mockKey));
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
    Schema.Account newMockValue = new Schema.Account(Name = 'Some fake account');

    LoggerCache.getOrganizationCache().put(mockKey, newMockValue);

    System.Assert.isTrue(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.areEqual(newMockValue, LoggerCache.getOrganizationCache().get(mockKey));
    System.Assert.isTrue(Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
    System.Assert.areEqual(newMockValue, Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
  }

  @IsTest
  static void it_removes_value_for_existing_key_in_organization_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User mockValue = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    System.Assert.isFalse(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));
    LoggerCache.getOrganizationCache().put(mockKey, mockValue);
    System.Assert.isTrue(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
    System.Assert.isTrue(Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
    System.Assert.areEqual(mockValue, Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getTransactionCache().get(mockKey));

    LoggerCache.getOrganizationCache().remove(mockKey);

    System.Assert.isFalse(LoggerCache.getOrganizationCache().contains(mockKey));
    System.Assert.isFalse(Cache.Org.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));
  }

  @IsTest
  static void it_adds_new_key_to_session_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User mockValue = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    System.Assert.isFalse(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));

    LoggerCache.getSessionCache().put(mockKey, mockValue);

    System.Assert.isTrue(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getSessionCache().get(mockKey));
    // Depending on how you start Apex tests, you may or may not have an active session
    // during the test execution, so session cache may or may not be available (╯°□°)╯︵ ┻━┻
    if (Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).isAvailable()) {
      System.Assert.isTrue(Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
      System.Assert.areEqual(mockValue, Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    }
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getTransactionCache().get(mockKey));
  }

  @IsTest
  static void it_adds_new_key_with_null_value_to_session_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User mockValue = null;
    System.Assert.isFalse(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));

    LoggerCache.getSessionCache().put(mockKey, mockValue);

    System.Assert.isTrue(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getSessionCache().get(mockKey));
    // Depending on how you start Apex tests, you may or may not have an active session
    // during the test execution, so session cache may or may not be available (╯°□°)╯︵ ┻━┻
    if (Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).isAvailable()) {
      System.Assert.isTrue(Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
      System.Assert.areEqual(LoggerCache.PLATFORM_CACHE_NULL_VALUE, Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    }
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getTransactionCache().get(mockKey));
  }

  @IsTest
  static void it_updates_value_for_existing_key_in_session_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User oldMockValue = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    LoggerCache.getSessionCache().put(mockKey, oldMockValue);
    System.Assert.isTrue(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.areEqual(oldMockValue, LoggerCache.getSessionCache().get(mockKey));
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
    Schema.Account newMockValue = new Schema.Account(Name = 'Some fake account');

    LoggerCache.getSessionCache().put(mockKey, newMockValue);

    System.Assert.isTrue(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.areEqual(newMockValue, LoggerCache.getSessionCache().get(mockKey));
    // Depending on how you start Apex tests, you may or may not have an active session
    // during the test execution, so session cache may or may not be available (╯°□°)╯︵ ┻━┻
    if (Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).isAvailable()) {
      System.Assert.isTrue(Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
      System.Assert.areEqual(newMockValue, Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    }
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
  }

  @IsTest
  static void it_removes_value_for_existing_key_in_session_and_transaction_cache() {
    String mockKey = 'SomeKey';
    Schema.User mockValue = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    System.Assert.isFalse(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));
    LoggerCache.getSessionCache().put(mockKey, mockValue);
    System.Assert.isTrue(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getSessionCache().get(mockKey));
    // Depending on how you start Apex tests, you may or may not have an active session
    // during the test execution, so session cache may or may not be available (╯°□°)╯︵ ┻━┻
    if (Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).isAvailable()) {
      System.Assert.isTrue(Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
      System.Assert.areEqual(mockValue, Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).get(mockKey));
    }
    System.Assert.isTrue(LoggerCache.getTransactionCache().contains(mockKey));
    System.Assert.areEqual(mockValue, LoggerCache.getTransactionCache().get(mockKey));

    LoggerCache.getSessionCache().remove(mockKey);

    System.Assert.isFalse(LoggerCache.getSessionCache().contains(mockKey));
    System.Assert.isFalse(Cache.Session.getPartition(LoggerCache.PLATFORM_CACHE_PARTITION_NAME).contains(mockKey));
    System.Assert.isFalse(LoggerCache.getTransactionCache().contains(mockKey));
  }
}
