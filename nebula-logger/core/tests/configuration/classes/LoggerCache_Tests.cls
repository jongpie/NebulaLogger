//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description When testing Platform Cache partitions, there is no way to directly mock the partitions. Furthermore, the partitions
 *              configured in the org are actually used in test contexts, so if a partition exists but does not have storage space
 *              allocated in the org, then any tests that try to assert that data is cached in the partitions will fail.
 *              To help overcome this platform limitation, a mock class - `MockPlatformCachePartitionDelegate` - is used
 *              to simulate how the code would behave with different partition configurations.
 *              Additional integration tests (that actually test real platform cache partitions) are used in Nebula Logger's pipeline
 *              but are not included in core package since those tests may fail in some orgs.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerCache_Tests {
    @IsTest
    static void it_adds_new_key_to_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));

        LoggerCache.getTransactionCache().put(mockKey, mockValue);

        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_adds_new_key_with_null_value_to_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = null;
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));

        LoggerCache.getTransactionCache().put(mockKey, mockValue);

        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_updates_value_for_existing_key_in_transaction_cache() {
        String mockKey = 'SomeKey';
        User oldMockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        LoggerCache.getTransactionCache().put(mockKey, oldMockValue);
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
        Account newMockValue = new Account(Name = 'Some fake account');

        LoggerCache.getTransactionCache().put(mockKey, newMockValue);

        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_removes_value_for_existing_key_in_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        LoggerCache.getTransactionCache().put(mockKey, mockValue);
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));

        LoggerCache.getTransactionCache().remove(mockKey);

        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
    }

    @IsTest
    static void it_adds_new_key_to_organization_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockOrganizationPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockOrganizationPartitionDelegate.isAvailable());
        LoggerCache.setMockOrganizationPartitionDelegate(mockOrganizationPartitionDelegate);
        System.assertEquals(0, mockOrganizationPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(1, mockOrganizationPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(0, mockOrganizationPartitionDelegate.putMethodCallCount);

        LoggerCache.getOrganizationCache().put(mockKey, mockValue);

        System.assertEquals(1, mockOrganizationPartitionDelegate.putMethodCallCount);
        System.assertEquals(true, mockOrganizationPartitionDelegate.contains(mockKey));
        System.assertEquals(mockValue, mockOrganizationPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_adds_new_key_with_null_value_to_organization_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User mockValue = null;
        MockPlatformCachePartitionDelegate mockOrganizationPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockOrganizationPartitionDelegate.isAvailable());
        LoggerCache.setMockOrganizationPartitionDelegate(mockOrganizationPartitionDelegate);
        System.assertEquals(0, mockOrganizationPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(1, mockOrganizationPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(0, mockOrganizationPartitionDelegate.putMethodCallCount);

        LoggerCache.getOrganizationCache().put(mockKey, mockValue);

        System.assertEquals(1, mockOrganizationPartitionDelegate.putMethodCallCount);
        System.assertEquals(true, mockOrganizationPartitionDelegate.contains(mockKey));
        System.assertEquals(mockValue, mockOrganizationPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_adds_new_key_to_only_transaction_cache_when_organization_platform_cache_is_not_available() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockOrganizationPartitionDelegate = new MockPlatformCachePartitionDelegate(false);
        System.assertEquals(false, mockOrganizationPartitionDelegate.isAvailable());
        LoggerCache.setMockOrganizationPartitionDelegate(mockOrganizationPartitionDelegate);
        System.assertEquals(0, mockOrganizationPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(0, mockOrganizationPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(0, mockOrganizationPartitionDelegate.putMethodCallCount);

        LoggerCache.getOrganizationCache().put(mockKey, mockValue);

        System.assertEquals(0, mockOrganizationPartitionDelegate.putMethodCallCount);
        System.assertEquals(false, mockOrganizationPartitionDelegate.contains(mockKey));
        System.assertEquals(null, mockOrganizationPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_updates_value_for_existing_key_in_organization_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User oldMockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockOrganizationPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockOrganizationPartitionDelegate.isAvailable());
        LoggerCache.setMockOrganizationPartitionDelegate(mockOrganizationPartitionDelegate);
        System.assertEquals(0, mockOrganizationPartitionDelegate.putMethodCallCount);
        LoggerCache.getOrganizationCache().put(mockKey, oldMockValue);
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
        Account newMockValue = new Account(Name = 'Some fake account');
        System.assertEquals(1, mockOrganizationPartitionDelegate.putMethodCallCount);

        LoggerCache.getOrganizationCache().put(mockKey, newMockValue);

        System.assertEquals(2, mockOrganizationPartitionDelegate.putMethodCallCount);
        System.assertEquals(true, mockOrganizationPartitionDelegate.contains(mockKey));
        System.assertEquals(newMockValue, mockOrganizationPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_returns_value_in_transaction_cache_when_organization_and_transaction_cache_both_contain_key() {
        String mockKey = 'SomeKey';
        User transactionCacheValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        Account organizationCacheValue = new Account(Name = 'Some fake account');
        MockPlatformCachePartitionDelegate mockOrganizationPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockOrganizationPartitionDelegate.isAvailable());
        LoggerCache.setMockOrganizationPartitionDelegate(mockOrganizationPartitionDelegate);
        mockOrganizationPartitionDelegate.put(mockKey, organizationCacheValue, 5, Cache.Visibility.NAMESPACE, false);
        System.assertEquals(true, mockOrganizationPartitionDelegate.contains(mockKey));
        LoggerCache.getTransactionCache().put(mockKey, transactionCacheValue);
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));

        Object returnedValue = LoggerCache.getOrganizationCache().get(mockKey);

        System.assertEquals(transactionCacheValue, returnedValue);
    }

    @IsTest
    static void it_removes_value_for_existing_key_in_organization_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockOrganizationPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockOrganizationPartitionDelegate.isAvailable());
        LoggerCache.setMockOrganizationPartitionDelegate(mockOrganizationPartitionDelegate);
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        LoggerCache.getOrganizationCache().put(mockKey, mockValue);
        System.assertEquals(true, mockOrganizationPartitionDelegate.contains(mockKey));
        System.assertEquals(mockValue, mockOrganizationPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
        System.assertEquals(0, mockOrganizationPartitionDelegate.removeMethodCallCount);

        LoggerCache.getOrganizationCache().remove(mockKey);

        System.assertEquals(1, mockOrganizationPartitionDelegate.removeMethodCallCount);
        System.assertEquals(false, mockOrganizationPartitionDelegate.contains(mockKey));
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
    }

    @IsTest
    static void it_adds_new_key_to_session_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockSessionPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockSessionPartitionDelegate.isAvailable());
        LoggerCache.setMockSessionPartitionDelegate(mockSessionPartitionDelegate);
        System.assertEquals(0, mockSessionPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(1, mockSessionPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(0, mockSessionPartitionDelegate.putMethodCallCount);

        LoggerCache.getSessionCache().put(mockKey, mockValue);

        System.assertEquals(1, mockSessionPartitionDelegate.putMethodCallCount);
        System.assertEquals(true, mockSessionPartitionDelegate.contains(mockKey));
        System.assertEquals(mockValue, mockSessionPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_adds_new_key_with_null_value_to_session_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User mockValue = null;
        MockPlatformCachePartitionDelegate mockSessionPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockSessionPartitionDelegate.isAvailable());
        LoggerCache.setMockSessionPartitionDelegate(mockSessionPartitionDelegate);
        System.assertEquals(0, mockSessionPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(1, mockSessionPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(0, mockSessionPartitionDelegate.putMethodCallCount);

        LoggerCache.getSessionCache().put(mockKey, mockValue);

        System.assertEquals(1, mockSessionPartitionDelegate.putMethodCallCount);
        System.assertEquals(true, mockSessionPartitionDelegate.contains(mockKey));
        System.assertEquals(mockValue, mockSessionPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_adds_new_key_to_only_transaction_cache_when_session_platform_cache_is_not_available() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockSessionPartitionDelegate = new MockPlatformCachePartitionDelegate(false);
        System.assertEquals(false, mockSessionPartitionDelegate.isAvailable());
        LoggerCache.setMockSessionPartitionDelegate(mockSessionPartitionDelegate);
        System.assertEquals(0, mockSessionPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(0, mockSessionPartitionDelegate.containsMethodCallCount);
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(0, mockSessionPartitionDelegate.putMethodCallCount);

        LoggerCache.getSessionCache().put(mockKey, mockValue);

        System.assertEquals(0, mockSessionPartitionDelegate.putMethodCallCount);
        System.assertEquals(false, mockSessionPartitionDelegate.contains(mockKey));
        System.assertEquals(null, mockSessionPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_updates_value_for_existing_key_in_session_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User oldMockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockSessionPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockSessionPartitionDelegate.isAvailable());
        LoggerCache.setMockSessionPartitionDelegate(mockSessionPartitionDelegate);
        System.assertEquals(0, mockSessionPartitionDelegate.putMethodCallCount);
        LoggerCache.getSessionCache().put(mockKey, oldMockValue);
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
        Account newMockValue = new Account(Name = 'Some fake account');
        System.assertEquals(1, mockSessionPartitionDelegate.putMethodCallCount);

        LoggerCache.getSessionCache().put(mockKey, newMockValue);

        System.assertEquals(2, mockSessionPartitionDelegate.putMethodCallCount);
        System.assertEquals(true, mockSessionPartitionDelegate.contains(mockKey));
        System.assertEquals(newMockValue, mockSessionPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_returns_value_in_transaction_cache_when_session_and_transaction_cache_both_contain_key() {
        String mockKey = 'SomeKey';
        User transactionCacheValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        Account sessionCacheValue = new Account(Name = 'Some fake account');
        MockPlatformCachePartitionDelegate mockSessionPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockSessionPartitionDelegate.isAvailable());
        LoggerCache.setMockSessionPartitionDelegate(mockSessionPartitionDelegate);
        mockSessionPartitionDelegate.put(mockKey, sessionCacheValue, 5, Cache.Visibility.NAMESPACE, false);
        System.assertEquals(true, mockSessionPartitionDelegate.contains(mockKey));
        LoggerCache.getTransactionCache().put(mockKey, transactionCacheValue);
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));

        Object returnedValue = LoggerCache.getSessionCache().get(mockKey);

        System.assertEquals(transactionCacheValue, returnedValue);
    }

    @IsTest
    static void it_removes_value_for_existing_key_in_session_and_transaction_cache_when_platform_cache_is_available() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        MockPlatformCachePartitionDelegate mockSessionPartitionDelegate = new MockPlatformCachePartitionDelegate(true);
        System.assertEquals(true, mockSessionPartitionDelegate.isAvailable());
        LoggerCache.setMockSessionPartitionDelegate(mockSessionPartitionDelegate);
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        LoggerCache.getSessionCache().put(mockKey, mockValue);
        System.assertEquals(true, mockSessionPartitionDelegate.contains(mockKey));
        System.assertEquals(mockValue, mockSessionPartitionDelegate.get(mockKey));
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
        System.assertEquals(0, mockSessionPartitionDelegate.removeMethodCallCount);

        LoggerCache.getSessionCache().remove(mockKey);

        System.assertEquals(1, mockSessionPartitionDelegate.removeMethodCallCount);
        System.assertEquals(false, mockSessionPartitionDelegate.contains(mockKey));
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
    }

    // Since the class `Cache.Partition` can't have be mocked & can't have its methods overridden,
    // the `LoggerCache` class internally uses a delegate to help abstract out the usage of the partition,
    // which lets us mock the delegate within (true) unit tests.
    private class MockPlatformCachePartitionDelegate extends LoggerCache.PlatformCachePartitionDelegate {
        private final Boolean isAvailable;
        // Since `Cache.Partition` can't be mocked, this mock delegate uses a map as a substitute
        private final Map<String, Object> keyToValue = new Map<String, Object>();

        public Integer isAvailableMethodCallCount = 0;
        public Integer containsMethodCallCount = 0;
        public Integer getMethodCallCount = 0;
        public Integer putMethodCallCount = 0;
        public Integer removeMethodCallCount = 0;

        private MockPlatformCachePartitionDelegate(Boolean isAvailable) {
            super(null);
            this.isAvailable = isAvailable;
        }

        public override Boolean isAvailable() {
            this.isAvailableMethodCallCount++;
            return this.isAvailable;
        }

        public override Boolean contains(String key) {
            this.containsMethodCallCount++;
            return this.keyToValue.containsKey(key);
        }

        public override Object get(String key) {
            this.getMethodCallCount++;
            return this.keyToValue.get(key);
        }

        @SuppressWarnings('PMD.ExcessiveParameterList')
        public override void put(String key, Object value, Integer cacheTtlSeconds, Cache.Visibility cacheVisiblity, Boolean isCacheImmutable) {
            this.putMethodCallCount++;
            this.keyToValue.put(key, value);
        }

        public override void remove(String key) {
            this.removeMethodCallCount++;
            this.keyToValue.remove(key);
        }
    }
}
