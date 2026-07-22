//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationServiceHandler_Tests {
  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_return_the_loggerNotificationService_sobjectType() {
    System.Assert.areEqual(Schema.LoggerNotificationService__c.SObjectType, new LoggerNotificationServiceHandler().getSObjectType());
  }

  @IsTest
  static void it_should_stamp_origin_organization_id_on_insert() {
    LoggerNotificationService__c service = buildValidService();
    service.OriginOrganizationId__c = null;

    LoggerDataStore.getDatabase().insertRecord(service);

    LoggerNotificationService__c requeriedService = [
      SELECT Id, OriginOrganizationId__c, IsOriginOrganizationIdValid__c
      FROM LoggerNotificationService__c
      WHERE Id = :service.Id
    ];
    System.Assert.areEqual(System.UserInfo.getOrganizationId(), requeriedService.OriginOrganizationId__c);
    System.Assert.isTrue(requeriedService.IsOriginOrganizationIdValid__c, 'IsOriginOrganizationIdValid__c should be true after insert in the current org');
  }

  @IsTest
  static void it_should_overwrite_origin_organization_id_supplied_on_insert() {
    String otherOrganizationId = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    LoggerNotificationService__c service = buildValidService();
    service.OriginOrganizationId__c = otherOrganizationId;

    LoggerDataStore.getDatabase().insertRecord(service);

    LoggerNotificationService__c requeriedService = [SELECT Id, OriginOrganizationId__c FROM LoggerNotificationService__c WHERE Id = :service.Id];
    System.Assert.areEqual(
      System.UserInfo.getOrganizationId(),
      requeriedService.OriginOrganizationId__c,
      'Handler should have overwritten the supplied org id'
    );
  }

  @IsTest
  static void it_should_not_re_stamp_origin_organization_id_on_update() {
    // OriginOrganizationId__c is intentionally stamped only on insert. A service cloned into a refreshed
    // sandbox carries the source org's id and stays flagged as invalid until an admin explicitly re-saves
    // it (which is a hard delete + insert in the admin UI). A regular update must leave the field alone.
    LoggerNotificationService__c service = buildValidService();
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerSObjectHandler.shouldExecute(false);
    Id foreignOrgId = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    service.OriginOrganizationId__c = foreignOrgId;
    LoggerDataStore.getDatabase().updateRecord(service);
    LoggerSObjectHandler.shouldExecute(true);

    service.Description__c = 'triggering an update';
    LoggerDataStore.getDatabase().updateRecord(service);

    LoggerNotificationService__c afterUpdate = [
      SELECT Id, OriginOrganizationId__c, IsOriginOrganizationIdValid__c
      FROM LoggerNotificationService__c
      WHERE Id = :service.Id
    ];
    System.Assert.areEqual(foreignOrgId, afterUpdate.OriginOrganizationId__c, 'Update should not have re-stamped the origin org id');
    System.Assert.isFalse(afterUpdate.IsOriginOrganizationIdValid__c, 'Formula should still evaluate to false against the foreign org id');
  }

  @IsTest
  static void it_should_reject_a_service_whose_notifier_class_does_not_exist() {
    LoggerNotificationService__c service = buildValidService();
    service.NotifierApexClassName__c = 'NoSuchApexClassThatDoesNotExist';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(service);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A missing notifier class should have blocked the insert');
    System.Assert.isTrue(thrown.getMessage().contains('was not found'), 'Error message should identify the missing-class failure: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_reject_a_service_whose_notifier_class_does_not_extend_the_base_class() {
    LoggerNotificationService__c service = buildValidService();
    // Any concrete class that does not extend LoggerNotifier - Logger itself is a safe pick.
    service.NotifierApexClassName__c = 'Logger';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(service);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A non-LoggerNotifier class should have blocked the insert');
    System.Assert.isTrue(
      thrown.getMessage().contains('does not extend LoggerNotifier'),
      'Error message should identify the base-class failure: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_accept_a_service_with_a_valid_notifier_class() {
    LoggerNotificationService__c service = buildValidService();
    service.NotifierApexClassName__c = 'SlackLoggerNotifier';

    LoggerDataStore.getDatabase().insertRecord(service);

    LoggerNotificationService__c requeried = [SELECT Id, NotifierApexClassName__c FROM LoggerNotificationService__c WHERE Id = :service.Id];
    System.Assert.areEqual('SlackLoggerNotifier', requeried.NotifierApexClassName__c);
  }

  @IsTest
  static void it_should_skip_notifier_class_revalidation_on_update_when_field_is_unchanged() {
    LoggerNotificationService__c service = buildValidService();
    service.NotifierApexClassName__c = 'SlackLoggerNotifier';
    LoggerDataStore.getDatabase().insertRecord(service);

    service.Description__c = 'unrelated tweak';
    LoggerDataStore.getDatabase().updateRecord(service);

    System.Assert.areEqual('unrelated tweak', [SELECT Description__c FROM LoggerNotificationService__c WHERE Id = :service.Id].Description__c);
  }

  @IsTest
  static void it_should_reject_a_service_that_configures_both_a_named_credential_and_a_webhook_url() {
    LoggerNotificationService__c service = buildValidService();
    service.NamedCredentialDeveloperName__c = 'SlackWebApi';
    service.WebhookUrl__c = 'https://example.com/webhook';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(service);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A service with both endpoint options should have been rejected');
    System.Assert.isTrue(thrown.getMessage().contains('cannot have both'), 'Error message should identify the dual-endpoint failure: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_reject_an_update_that_adds_a_webhook_url_alongside_an_existing_named_credential() {
    LoggerNotificationService__c service = buildValidService();
    service.NamedCredentialDeveloperName__c = 'SlackWebApi';
    LoggerDataStore.getDatabase().insertRecord(service);

    service.WebhookUrl__c = 'https://example.com/webhook';
    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().updateRecord(service);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'Adding a Webhook URL to a service that already has a Named Credential should have been rejected');
    System.Assert.isTrue(thrown.getMessage().contains('cannot have both'), 'Error message should identify the dual-endpoint failure: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_wipe_endpoint_fields_when_origin_organization_id_is_changed_on_update() {
    LoggerNotificationService__c service = buildValidService();
    service.NamedCredentialDeveloperName__c = 'SlackWebApi';
    LoggerDataStore.getDatabase().insertRecord(service);

    Id foreignOrgId = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    service.OriginOrganizationId__c = foreignOrgId;
    LoggerDataStore.getDatabase().updateRecord(service);

    LoggerNotificationService__c requeried = [
      SELECT Id, NamedCredentialDeveloperName__c, WebhookUrl__c, OriginOrganizationId__c
      FROM LoggerNotificationService__c
      WHERE Id = :service.Id
    ];
    System.Assert.isNull(requeried.NamedCredentialDeveloperName__c, 'Named credential should have been wiped when OriginOrganizationId__c changed');
    System.Assert.isNull(requeried.WebhookUrl__c, 'Webhook URL should have been wiped when OriginOrganizationId__c changed');
    System.Assert.areEqual(foreignOrgId, requeried.OriginOrganizationId__c, 'The admin-supplied org id should have been persisted');
  }

  @IsTest
  static void it_should_wipe_webhook_url_when_origin_organization_id_is_changed_on_update() {
    LoggerNotificationService__c service = buildValidService();
    service.WebhookUrl__c = 'https://example.com/webhook';
    LoggerDataStore.getDatabase().insertRecord(service);

    service.OriginOrganizationId__c = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    LoggerDataStore.getDatabase().updateRecord(service);

    LoggerNotificationService__c requeried = [
      SELECT Id, NamedCredentialDeveloperName__c, WebhookUrl__c
      FROM LoggerNotificationService__c
      WHERE Id = :service.Id
    ];
    System.Assert.isNull(requeried.WebhookUrl__c, 'Webhook URL should have been wiped when OriginOrganizationId__c changed');
    System.Assert.isNull(requeried.NamedCredentialDeveloperName__c, 'Named credential should stay null');
  }

  @IsTest
  static void it_should_leave_endpoint_fields_alone_when_origin_organization_id_is_unchanged_on_update() {
    LoggerNotificationService__c service = buildValidService();
    service.NamedCredentialDeveloperName__c = 'SlackWebApi';
    LoggerDataStore.getDatabase().insertRecord(service);

    service.Description__c = 'unrelated tweak';
    LoggerDataStore.getDatabase().updateRecord(service);

    LoggerNotificationService__c requeried = [
      SELECT Id, NamedCredentialDeveloperName__c, Description__c
      FROM LoggerNotificationService__c
      WHERE Id = :service.Id
    ];
    System.Assert.areEqual(
      'SlackWebApi',
      requeried.NamedCredentialDeveloperName__c,
      'Named credential should not be wiped when OriginOrganizationId__c did not change'
    );
    System.Assert.areEqual('unrelated tweak', requeried.Description__c);
  }

  // LoggerMockDataCreator.populateRequiredFields() generates a placeholder for NotifierApexClassName__c
  // that won't resolve to a real class - overwrite it with a real notifier so the new validation passes.
  private static LoggerNotificationService__c buildValidService() {
    LoggerNotificationService__c service = (LoggerNotificationService__c) LoggerMockDataCreator.createDataBuilder(
        Schema.LoggerNotificationService__c.SObjectType
      )
      .populateRequiredFields()
      .getRecord();
    service.NotifierApexClassName__c = 'SlackLoggerNotifier';
    return service;
  }
}
