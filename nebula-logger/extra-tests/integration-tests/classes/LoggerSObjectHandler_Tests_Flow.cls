//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LoggerSObjectHandler_Tests_Flow {
  // This Flow simply returns a string variable called 'someExampleVariable'
  // that's used in tests below to verify if the Flow was dynamically executed
  private static final String MOCK_FLOW_NAME = 'MockLoggerSObjectHandlerPlugin';
  private static final String MOCK_FLOW_OUTPUT_VARIABLE_VALUE = 'Hello, world';

  @IsTest
  static void it_should_execute_flow_plugin() {
    LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
      DeveloperName = 'ExampleFlowPlugin',
      IsEnabled__c = true,
      SObjectHandlerFlowName__c = MOCK_FLOW_NAME
    );
    LoggerTestConfigurator.setMock(mockPluginConfiguration);
    MockLogHandler mockHandler = new MockLogHandler();
    mockHandler.triggerOperationType = System.TriggerOperation.BEFORE_INSERT;
    mockHandler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
    mockHandler.triggerNewMap = null;
    mockHandler.triggerOldMap = null;

    mockHandler.execute();

    System.Assert.areEqual(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations().toString());
    System.Assert.areEqual(1, mockHandler.getExecutedFlowPlugins().size(), mockHandler.getExecutedFlowPlugins().toString());
    Flow.Interview executedFlowPlugin = mockHandler.getExecutedFlowPlugins().get(0);
    System.Assert.areEqual(mockPluginConfiguration, executedFlowPlugin.getVariableValue('pluginConfiguration'));
    System.Assert.areEqual(mockHandler.input, executedFlowPlugin.getVariableValue('pluginInput'));
    System.Assert.areEqual(MOCK_FLOW_OUTPUT_VARIABLE_VALUE, executedFlowPlugin.getVariableValue('someExampleVariable'));
  }

  private class MockLogHandler extends LoggerSObjectHandler {
    public override Schema.SObjectType getSObjectType() {
      return Schema.Log__c.SObjectType;
    }
  }
}
