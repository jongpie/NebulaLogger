//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerCache_Tests {
    @IsTest
    static void it_adds_new_key_to_cache() {
        String mockKeyName = 'SomeKey';
        User mockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(false, LoggerCache.getTransactionCache().contains(mockKeyName));

        LoggerCache.getTransactionCache().put(mockKeyName, mockValue);

        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKeyName));
        System.assertEquals(mockValue, LoggerCache.getTransactionCache().get(mockKeyName));
    }

    @IsTest
    static void it_updates_value_for_existing_key_in_cache() {
        String mockKeyName = 'SomeKey';
        User oldMockValue = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        LoggerCache.getTransactionCache().put(mockKeyName, oldMockValue);
        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKeyName));
        System.assertEquals(oldMockValue, LoggerCache.getTransactionCache().get(mockKeyName));
        Account newMockValue = new Account(Name = 'Some fake account');

        LoggerCache.getTransactionCache().put(mockKeyName, newMockValue);

        System.assertEquals(true, LoggerCache.getTransactionCache().contains(mockKeyName));
        System.assertEquals(newMockValue, LoggerCache.getTransactionCache().get(mockKeyName));
    }
}
