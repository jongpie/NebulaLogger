//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEngineDataSelector_Tests_Network {
    private static final String EXPERIENCE_CLOUD_GUEST_PROFILE_NAME = 'Logger Test LWR Site Guest Profile';
    private static final String EXPERIENCE_CLOUD_NETWORK_NAME = 'Logger Test LWR Site';
    private static final String GUEST_USER_TYPE = 'Guest';
    private static final String LOG_CREATOR_PERMISSION_SET_NAME = 'LoggerLogCreator';

    @IsTest
    static void it_returns_cached_network() {
        if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        Id expectedNetworkId = (Id) getExperienceCloudNetwork().get('Id');
        System.Assert.isNotNull(expectedNetworkId);
        System.Assert.areEqual(1, System.Limits.getQueries());
        Integer expectedQueryCount = System.Limits.getQueries() + 1;

        LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);

        System.Assert.isNotNull(returnedNetworkProxy);
        System.Assert.areEqual(expectedQueryCount, System.Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);
        System.Assert.areEqual(expectedQueryCount, System.Limits.getQueries(), 'Query results should have been cached');
        System.Assert.areEqual(expectedNetworkId, returnedNetworkProxy?.Id);
    }

    @IsTest
    static void it_returns_null_when_network_id_is_null() {
        if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkData', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_NETWORK_DATA);
        Id expectedNetworkId = null;
        System.Assert.areEqual(0, System.Limits.getQueries());

        LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);

        System.Assert.areEqual(0, System.Limits.getQueries());
        System.Assert.isNull(returnedNetworkProxy);
    }

    @IsTest
    static void it_returns_null_when_querying_network_is_disabled() {
        if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkData', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_NETWORK_DATA);
        Id expectedNetworkId = (Id) getExperienceCloudNetwork().get('Id');
        System.Assert.areEqual(1, System.Limits.getQueries());

        LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);

        System.Assert.areEqual(1, System.Limits.getQueries());
        System.Assert.isNull(returnedNetworkProxy);
    }

    static SObject getExperienceCloudNetwork() {
        return System.Database.query('SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = :EXPERIENCE_CLOUD_NETWORK_NAME');
    }
}
