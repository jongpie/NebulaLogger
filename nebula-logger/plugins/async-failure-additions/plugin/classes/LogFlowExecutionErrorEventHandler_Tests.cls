//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc')
@IsTest(IsParallel=true)
private class LogFlowExecutionErrorEventHandler_Tests {
    @IsTest
    static void it_does_not_log_when_plugin_parameter_disabled() {
        LoggerParameter__mdt mockParam = new LoggerParameter__mdt(DeveloperName = LogFlowExecutionErrorEventHandler.PARAMETER_DEV_NAME, Value__c = '0');
        LoggerParameter.setMock(mockParam);

        Test.startTest();
        LogFlowExecutionErrorEventHandler.logErrors(new List<FlowExecutionErrorEvent>{ new FlowExecutionErrorEvent() });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);
    }
}
