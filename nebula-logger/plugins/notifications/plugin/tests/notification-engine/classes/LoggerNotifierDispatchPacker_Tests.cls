//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifierDispatchPacker_Tests {
  @IsTest
  static void it_should_return_no_groups_for_null_or_empty_dispatches() {
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();

    System.Assert.areEqual(0, packer.pack(null).size(), 'A null dispatch list should produce no groups');
    System.Assert.areEqual(
      0,
      packer.pack(new List<LoggerNotificationAsyncDispatcher.PendingDispatch>()).size(),
      'An empty dispatch list should produce no groups'
    );
  }

  @IsTest
  static void it_should_pack_empty_set_notifiers_together_with_anything() {
    // Notifier that declares no primitives is packable with anything else - it does nothing tracked.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(NoOpNotifier.class.getName()),
      buildDispatch(CalloutNotifier.class.getName()),
      buildDispatch(DmlNotifier.class.getName()),
      buildDispatch(NoOpNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'No-op notifiers should not force isolation from callout+DML - all four pack together');
    System.Assert.areEqual(4, groups.get(0).size());
  }

  @IsTest
  static void it_should_pack_multiple_callout_only_notifiers_into_one_group() {
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(CalloutNotifier.class.getName()),
      buildDispatch(CalloutNotifier.class.getName()),
      buildDispatch(CalloutNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'Callouts after callouts are fine - all three pack together');
    System.Assert.areEqual(3, groups.get(0).size());
  }

  @IsTest
  static void it_should_pack_multiple_dml_only_notifiers_into_one_group() {
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(DmlNotifier.class.getName()),
      buildDispatch(DmlNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'DML after DML is fine - both pack together');
    System.Assert.areEqual(2, groups.get(0).size());
  }

  @IsTest
  static void it_should_pack_callout_before_dml_into_one_group() {
    // The reorder step ensures callout notifiers come first, so callout+DML in either enqueue order
    // packs into ONE group - CALLOUT then DML in the same transaction is safe.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(CalloutNotifier.class.getName()),
      buildDispatch(DmlNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'CALLOUT then DML in the same transaction is safe - one group');
    System.Assert.areEqual(2, groups.get(0).size());
    LoggerNotificationService__c firstService = groups.get(0).get(0).recipient.LoggerNotificationService__r;
    LoggerNotificationService__c secondService = groups.get(0).get(1).recipient.LoggerNotificationService__r;
    System.Assert.areEqual(CalloutNotifier.class.getName(), firstService.NotifierApexClassName__c, 'CALLOUT-only notifier should run first inside the group');
    System.Assert.areEqual(
      DmlNotifier.class.getName(),
      secondService.NotifierApexClassName__c,
      'DML-only notifier should run after CALLOUT-only inside the group'
    );
  }

  @IsTest
  static void it_should_reorder_dml_first_callout_second_into_callout_first_dml_second() {
    // Enqueue order is DML then CALLOUT (which would trigger "uncommitted work pending"); the
    // packer reorders so the callout runs first, then the DML, and both fit in one group.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(DmlNotifier.class.getName()),
      buildDispatch(CalloutNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'Reorder should collapse DML-then-CALLOUT into one group');
    System.Assert.areEqual(
      CalloutNotifier.class.getName(),
      groups.get(0).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c,
      'CALLOUT should have been moved before DML'
    );
    System.Assert.areEqual(DmlNotifier.class.getName(), groups.get(0).get(1).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
  }

  @IsTest
  static void it_should_isolate_email_from_callout_into_a_second_group() {
    // EMAIL is conservatively split from CALLOUT (and vice-versa) so a callout that runs first
    // doesn't affect Messaging.sendEmail.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(CalloutNotifier.class.getName()),
      buildDispatch(EmailNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(2, groups.size(), 'EMAIL after CALLOUT must be in its own group');
    System.Assert.areEqual(CalloutNotifier.class.getName(), groups.get(0).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
    System.Assert.areEqual(EmailNotifier.class.getName(), groups.get(1).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
  }

  @IsTest
  static void it_should_isolate_email_from_dml_into_a_second_group() {
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(DmlNotifier.class.getName()),
      buildDispatch(EmailNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(2, groups.size(), 'EMAIL after DML must be in its own group');
    System.Assert.areEqual(DmlNotifier.class.getName(), groups.get(0).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
    System.Assert.areEqual(EmailNotifier.class.getName(), groups.get(1).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
  }

  @IsTest
  static void it_should_isolate_callout_or_dml_when_they_would_run_after_email() {
    // Reorder pushes EMAIL to the end, so CALLOUT+DML+EMAIL in any enqueue order should still fit
    // into two groups: (CALLOUT, DML) then (EMAIL).
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(EmailNotifier.class.getName()),
      buildDispatch(DmlNotifier.class.getName()),
      buildDispatch(CalloutNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(2, groups.size(), 'CALLOUT+DML share a group; EMAIL gets its own after them');
    System.Assert.areEqual(2, groups.get(0).size());
    System.Assert.areEqual(CalloutNotifier.class.getName(), groups.get(0).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
    System.Assert.areEqual(DmlNotifier.class.getName(), groups.get(0).get(1).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
    System.Assert.areEqual(1, groups.get(1).size());
    System.Assert.areEqual(EmailNotifier.class.getName(), groups.get(1).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c);
  }

  @IsTest
  static void it_should_group_a_callout_and_dml_declaring_notifier_with_earlier_callouts() {
    // A notifier that declares BOTH CALLOUT and DML (its own sendNotification does the callouts first,
    // then the DML) fits in the same group as any earlier callout-only notifier.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(CalloutNotifier.class.getName()),
      buildDispatch(CalloutAndDmlNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'A CALLOUT+DML notifier packs with earlier callout notifiers');
    System.Assert.areEqual(2, groups.get(0).size());
  }

  @IsTest
  static void it_should_treat_unresolvable_notifier_class_as_empty_operation_set() {
    // A misconfigured service record with a bogus NotifierApexClassName__c should not cause the
    // packer to throw - it should treat the notifier as empty-set (packable with anything) and let
    // the dispatcher's per-invocation error handling report the missing class at run time.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch('SomeMissingApexClass'),
      buildDispatch(CalloutNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'Unresolvable notifier class should pack with anything');
    System.Assert.areEqual(2, groups.get(0).size());
  }

  @IsTest
  static void it_should_treat_a_class_that_is_not_a_notifier_as_empty_operation_set() {
    // If NotifierApexClassName__c resolves to a class that ISN'T a LoggerNotifier subclass, treat
    // it the same as an unresolvable class - empty operations, packable with anything.
    LoggerNotifierDispatchPacker packer = new LoggerNotifierDispatchPacker();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(NotANotifier.class.getName()),
      buildDispatch(DmlNotifier.class.getName())
    };

    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = packer.pack(dispatches);

    System.Assert.areEqual(1, groups.size(), 'Non-notifier class should pack with anything');
    System.Assert.areEqual(2, groups.get(0).size());
  }

  private static LoggerNotificationAsyncDispatcher.PendingDispatch buildDispatch(String apexClassName) {
    LoggerNotificationService__c service = new LoggerNotificationService__c(Name = 'Mock service', NotifierApexClassName__c = apexClassName);
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    LoggerNotificationRecipient__c recipient = (LoggerNotificationRecipient__c) System.JSON.deserialize(
      System.JSON.serialize(
        new Map<String, Object>{
          'attributes' => new Map<String, String>{ 'type' => 'LoggerNotificationRecipient__c' },
          'LoggerNotificationRule__r' => rule,
          'LoggerNotificationService__r' => service
        }
      ),
      LoggerNotificationRecipient__c.class
    );
    return new LoggerNotificationAsyncDispatcher.PendingDispatch(
      recipient,
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) },
      null
    );
  }

  public class NoOpNotifier extends LoggerNotifier {
    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      return null;
    }
  }

  public class CalloutNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.CALLOUT };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      return null;
    }
  }

  public class DmlNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.DML };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      return null;
    }
  }

  public class EmailNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.EMAIL };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      return null;
    }
  }

  public class CalloutAndDmlNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.CALLOUT, LoggerNotifier.Operation.DML };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      return null;
    }
  }

  public class NotANotifier {
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public NotANotifier() {
    }
  }
}
