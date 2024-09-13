//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogFinalizer_Tests {
  private static final String EXPECTED_ERROR_MESSAGE = 'Gack';
  @IsTest
  static void it_should_not_log_on_queueable_success() {
    System.Test.startTest();
    System.enqueueJob(new ExampleQueueable());
    System.Test.stopTest();
    System.Test.getEventBus().deliver();

    System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c], 'Should not log if no errors');
  }

  @IsTest
  static void it_should_log_on_queueable_error() {
    try {
      System.Test.startTest();
      System.enqueueJob(new ExampleFailedQueueable());
      System.Test.stopTest();
    } catch (System.Exception ex) {
      System.Assert.areEqual(EXPECTED_ERROR_MESSAGE, ex.getMessage());
    }
    System.Test.getEventBus().deliver();

    List<LogEntry__c> logEntries = [SELECT Message__c, ExceptionMessage__c FROM LogEntry__c];
    System.Assert.areEqual(2, logEntries.size(), 'Should log for errors');
    LogEntry__c firstEntry = logEntries.get(0);
    System.Assert.areEqual('There was an error during this queueable job', firstEntry.Message__c);
    LogEntry__c secondEntry = logEntries.get(1);
    System.Assert.areEqual('Error details', secondEntry.Message__c);
    System.Assert.areEqual(EXPECTED_ERROR_MESSAGE, secondEntry.ExceptionMessage__c);
  }

  private virtual class ExampleQueueable implements System.Queueable {
    public void execute(System.QueueableContext qc) {
      System.attachFinalizer(new LogFinalizer());
      this.innerExecute();
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void innerExecute() {
    }
  }

  private virtual class ExampleFailedQueueable extends ExampleQueueable {
    protected override void innerExecute() {
      throw new System.IllegalArgumentException(EXPECTED_ERROR_MESSAGE);
    }
  }
}
