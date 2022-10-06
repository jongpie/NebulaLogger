//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

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
    static void it_adds_new_key_to_organization_and_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));

        LoggerCache.getOrganizationCache().put(mockKey, mockValue);

        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
        System.assertEquals(mockValue, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_updates_value_for_existing_key_in_organization_and_transaction_cache() {
        String mockKey = 'SomeKey';
        User oldMockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        LoggerCache.getOrganizationCache().put(mockKey, oldMockValue);
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
        Account newMockValue = new Account(Name = 'Some fake account');

        LoggerCache.getOrganizationCache().put(mockKey, newMockValue);

        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
        System.assertEquals(newMockValue, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_removes_value_for_existing_key_in_organization_and_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        LoggerCache.getOrganizationCache().put(mockKey, mockValue);
        System.assertEquals(true, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getOrganizationCache().get(mockKey));
        System.assertEquals(true, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
        System.assertEquals(mockValue, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));

        LoggerCache.getOrganizationCache().remove(mockKey);

        System.assertEquals(false, LoggerCache.getOrganizationCache().contains(mockKey));
        System.assertEquals(false, Cache.Org.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
    }

    @IsTest
    static void it_adds_new_key_to_session_and_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));

        LoggerCache.getSessionCache().put(mockKey, mockValue);

        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getSessionCache().get(mockKey));
        if (Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).isAvailable() == true) {
            System.assertEquals(true, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
            System.assertEquals(mockValue, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).get(mockKey));
        }
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_updates_value_for_existing_key_in_session_and_transaction_cache() {
        String mockKey = 'SomeKey';
        User oldMockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        LoggerCache.getSessionCache().put(mockKey, oldMockValue);
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getSessionCache().get(mockKey));
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(oldMockValue, LoggerCache.getTransactionCache().get(mockKey));
        Account newMockValue = new Account(Name = 'Some fake account');

        LoggerCache.getSessionCache().put(mockKey, newMockValue);

        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getSessionCache().get(mockKey));
        if (Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).isAvailable() == true) {
            System.assertEquals(true, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
            System.assertEquals(newMockValue, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).get(mockKey));
        }
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(newMockValue, LoggerCache.getTransactionCache().get(mockKey));
    }

    @IsTest
    static void it_removes_value_for_existing_key_in_session_and_transaction_cache() {
        String mockKey = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
        LoggerCache.getSessionCache().put(mockKey, mockValue);
        System.assertEquals(true, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getSessionCache().get(mockKey));
        if (Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).isAvailable() == true) {
            System.assertEquals(true, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
            System.assertEquals(mockValue, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).get(mockKey));
        }
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKey));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKey));

        LoggerCache.getSessionCache().remove(mockKey);

        System.assertEquals(false, LoggerCache.getSessionCache().contains(mockKey));
        System.assertEquals(false, Cache.Session.getPartition(LoggerCache.CACHE_PARTITION_NAME).contains(mockKey));
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKey));
    }
}
