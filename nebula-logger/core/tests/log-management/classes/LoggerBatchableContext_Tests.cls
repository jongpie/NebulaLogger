//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerBatchableContext_Tests {
    @IsTest
    static void it_constructs_instance_when_both_parameters_provided() {
        Database.BatchableContext mockBatchableContext = LoggerMockDataCreator.createBatchableContext('some_fake_job_id');
        Schema.SObjectType sobjectType = Schema.LogEntryEvent__e.SObjectType;

        LoggerBatchableContext context = new LoggerBatchableContext(mockBatchableContext, sobjectType);

        System.assertEquals(mockBatchableContext, context.batchableContext);
        System.assertEquals(sobjectType, context.sobjectType);
        System.assertEquals(sobjectType.getDescribe().getName(), context.sobjectTypeName);
    }

    @IsTest
    static void it_constructs_instance_when_neither_parameters_provided() {
        Database.BatchableContext nullBatchableContext = null;
        Schema.SObjectType nullSObjectType = null;

        LoggerBatchableContext context = new LoggerBatchableContext(nullBatchableContext, nullSObjectType);

        System.assertEquals(null, context.batchableContext);
        System.assertEquals(null, context.sobjectType);
        System.assertEquals(null, context.sobjectTypeName);
    }
}
