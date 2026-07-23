//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Integration test class used to validate that the bundled CMDT records in the
 *              notifications plugin have the expected default values.
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CMDT_LoggerNotificationsPlugin_Tests {
  @IsTest
  static void it_has_correct_record_for_logger_notifications_plugin() {
    LoggerPlugin__mdt bundledRecord = LoggerPlugin__mdt.getInstance('LoggerNotifications');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.areEqual(LoggerNotificationsPlugin.class.getName(), bundledRecord.BatchPurgeRegistrarApexClass__c);
    System.Assert.isNull(bundledRecord.BatchPurgerApexClass__c);
    System.Assert.isNull(bundledRecord.BatchPurgerExecutionOrder__c);
    System.Assert.isNull(bundledRecord.BatchPurgerFlowName__c);
    System.Assert.areEqual(
      'Adds the ability to configure notification rules for logging records and sends notifications to each rule\'s configured recipients (Slack, email, etc.).',
      bundledRecord.Description__c
    );
    System.Assert.isNull(bundledRecord.ExecutionOrder__c);
    System.Assert.isTrue(bundledRecord.IsEnabled__c);
    System.Assert.isNull(bundledRecord.Link__c);
    System.Assert.areEqual('Logger Notifications', bundledRecord.Label);
    System.Assert.isNull(bundledRecord.PluginApiName__c);
    System.Assert.areEqual('Apex', bundledRecord.PluginType__c);
    System.Assert.areEqual(LoggerNotificationsPlugin.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.areEqual(100.0, bundledRecord.SObjectHandlerExecutionOrder__c);
    System.Assert.isNull(bundledRecord.SObjectHandlerFlowName__c);
    System.Assert.isNull(bundledRecord.SObjectType__c);
    System.Assert.areEqual('v1.0.0', bundledRecord.VersionNumber__c);
  }

  @IsTest
  static void it_does_not_have_record_for_logger_notification_delivery_sobject_handler() {
    List<LoggerSObjectHandler__mdt> bundledRecords = [
      SELECT Id
      FROM LoggerSObjectHandler__mdt
      WHERE SObjectType__r.QualifiedApiName = :Schema.LoggerNotificationDelivery__c.SObjectType.getDescribe().getLocalName()
    ];

    System.Assert.isTrue(bundledRecords.isEmpty(), 'No record or handler should be present for LoggerNotificationDelivery__c');
  }

  @IsTest
  static void it_does_not_have_record_for_logger_notification_match_sobject_handler() {
    List<LoggerSObjectHandler__mdt> bundledRecords = [
      SELECT Id
      FROM LoggerSObjectHandler__mdt
      WHERE SObjectType__r.QualifiedApiName = :Schema.LoggerNotificationMatch__c.SObjectType.getDescribe().getLocalName()
    ];

    System.Assert.isTrue(bundledRecords.isEmpty(), 'No record or handler should be present for LoggerNotificationMatch__c');
  }

  @IsTest
  static void it_has_correct_record_for_logger_notification_recipient_sobject_handler() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LoggerNotificationRecipientHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LoggerNotificationRecipient__c config', bundledRecord.Label);
    System.Assert.areEqual(LoggerNotificationRecipientHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(Schema.LoggerNotificationRecipient__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_logger_notification_rule_sobject_handler() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LoggerNotificationRuleHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LoggerNotificationRule__c config', bundledRecord.Label);
    System.Assert.areEqual(LoggerNotificationRuleHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(Schema.LoggerNotificationRule__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_logger_notification_Service_sobject_handler() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LoggerNotificationServiceHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LoggerNotificationService__c config', bundledRecord.Label);
    System.Assert.areEqual(LoggerNotificationServiceHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(Schema.LoggerNotificationService__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_custom_notification_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('CustomNotification');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredServiceFields__c, 'AtLeastOneRequiredServiceFields should be null');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Salesforce Custom Notification', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isTrue(bundledRecord.IsUserRequired__c, 'IsUserRequired should be true');
    System.Assert.areEqual('Salesforce Custom Notification', bundledRecord.Label);
    System.Assert.areEqual(CustomNotificationLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isFalse(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be false');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isFalse(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be false');
    System.Assert.isTrue(bundledRecord.SupportsUser__c, 'SupportsUser should be true');
    System.Assert.isFalse(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be false');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_email_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('Email');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.areEqual(
      Schema.LoggerNotificationRecipient__c.User__c.toString() + '\n' + Schema.LoggerNotificationRecipient__c.EmailAddress__c.toString(),
      bundledRecord.AtLeastOneRequiredRecipientFields__c
    );
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredServiceFields__c, 'AtLeastOneRequiredServiceFields should be null');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Email', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('Email', bundledRecord.Label);
    System.Assert.areEqual(EmailLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isFalse(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be false');
    System.Assert.isTrue(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be true');
    System.Assert.isFalse(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be false');
    System.Assert.isTrue(bundledRecord.SupportsUser__c, 'SupportsUser should be true');
    System.Assert.isFalse(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be false');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_generic_webhook_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('GenericWebhook');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.areEqual(
      Schema.LoggerNotificationService__c.WebhookUrl__c.toString() + '\n' + Schema.LoggerNotificationService__c.NamedCredentialDeveloperName__c.toString(),
      bundledRecord.AtLeastOneRequiredServiceFields__c
    );
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Generic Webhook', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('Generic Webhook', bundledRecord.Label);
    System.Assert.areEqual(GenericWebhookLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isTrue(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be true');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isTrue(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be true');
    System.Assert.isFalse(bundledRecord.SupportsUser__c, 'SupportsUser should be false');
    System.Assert.isTrue(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be true');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_google_chat_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('GoogleChat');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.areEqual(
      Schema.LoggerNotificationService__c.WebhookUrl__c.toString() + '\n' + Schema.LoggerNotificationService__c.NamedCredentialDeveloperName__c.toString(),
      bundledRecord.AtLeastOneRequiredServiceFields__c
    );
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Google Chat', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('Google Chat', bundledRecord.Label);
    System.Assert.areEqual(GoogleChatLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isFalse(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be false');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isTrue(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be true');
    System.Assert.isFalse(bundledRecord.SupportsUser__c, 'SupportsUser should be false');
    System.Assert.isTrue(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be true');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_microsoft_teams_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('MicrosoftTeams');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.areEqual(
      Schema.LoggerNotificationService__c.WebhookUrl__c.toString() + '\n' + Schema.LoggerNotificationService__c.NamedCredentialDeveloperName__c.toString(),
      bundledRecord.AtLeastOneRequiredServiceFields__c
    );
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Microsoft Teams', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('Microsoft Teams', bundledRecord.Label);
    System.Assert.areEqual(MicrosoftTeamsLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isFalse(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be false');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isTrue(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be true');
    System.Assert.isFalse(bundledRecord.SupportsUser__c, 'SupportsUser should be false');
    System.Assert.isTrue(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be true');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_open_telemetry_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('OpenTelemetry');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.areEqual(
      Schema.LoggerNotificationService__c.WebhookUrl__c.toString() + '\n' + Schema.LoggerNotificationService__c.NamedCredentialDeveloperName__c.toString(),
      bundledRecord.AtLeastOneRequiredServiceFields__c
    );
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('OpenTelemetry (OTLP HTTP)', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('OpenTelemetry (OTLP HTTP)', bundledRecord.Label);
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isFalse(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be false');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isTrue(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be true');
    System.Assert.isFalse(bundledRecord.SupportsUser__c, 'SupportsUser should be false');
    System.Assert.isTrue(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be true');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_pager_duty_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('PagerDuty');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.areEqual(
      Schema.LoggerNotificationService__c.WebhookUrl__c.toString() + '\n' + Schema.LoggerNotificationService__c.NamedCredentialDeveloperName__c.toString(),
      bundledRecord.AtLeastOneRequiredServiceFields__c
    );
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('PagerDuty', bundledRecord.DisplayLabel__c);
    System.Assert.isFalse(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be false');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('PagerDuty', bundledRecord.Label);
    System.Assert.areEqual(PagerDutyLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isFalse(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be false');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isTrue(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be true');
    System.Assert.isFalse(bundledRecord.SupportsUser__c, 'SupportsUser should be false');
    System.Assert.isTrue(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be true');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  @IsTest
  static void it_has_correct_record_for_slack_notifier_type() {
    LoggerNotifierType__mdt bundledRecord = LoggerNotifierType__mdt.getInstance('Slack');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.AtLeastOneRequiredRecipientFields__c, 'AtLeastOneRequiredRecipientFields should be null');
    System.Assert.areEqual(
      Schema.LoggerNotificationService__c.WebhookUrl__c.toString() + '\n' + Schema.LoggerNotificationService__c.NamedCredentialDeveloperName__c.toString(),
      bundledRecord.AtLeastOneRequiredServiceFields__c
    );
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Slack', bundledRecord.DisplayLabel__c);
    System.Assert.isTrue(bundledRecord.IsChannelIdentifierRequired__c, 'IsChannelIdentifierRequired should be true');
    System.Assert.isFalse(bundledRecord.IsEmailAddressRequired__c, 'IsEmailAddressRequired should be false');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'IsEnabled should be true');
    System.Assert.isFalse(bundledRecord.IsUserRequired__c, 'IsUserRequired should be false');
    System.Assert.areEqual('Slack', bundledRecord.Label);
    System.Assert.areEqual(SlackLoggerNotifier.class.getName(), bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(bundledRecord.SetupGuidanceMarkdown__c, 'SetupGuidanceMarkdown is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson is missing');
    System.Assert.isTrue(bundledRecord.SupportsChannelIdentifier__c, 'SupportsChannelIdentifier should be true');
    System.Assert.isFalse(bundledRecord.SupportsEmailAddress__c, 'SupportsEmailAddress should be false');
    System.Assert.isTrue(bundledRecord.SupportsNamedCredential__c, 'SupportsNamedCredential should be true');
    System.Assert.isFalse(bundledRecord.SupportsUser__c, 'SupportsUser should be false');
    System.Assert.isTrue(bundledRecord.SupportsWebhookUrl__c, 'SupportsWebhookUrl should be true');
    System.Type resolvedApexClass = System.Type.forName(bundledRecord.NotifierApexClassName__c);
    System.Assert.isNotNull(resolvedApexClass, 'Configured Apex class should resolve at runtime');
    System.Assert.isInstanceOfType(resolvedApexClass.newInstance(), LoggerNotifier.class, 'Configured Apex class should extend LoggerNotifier');
  }

  // Regression coverage for the Slack notifier's SuggestedConfigurationJson__c. The stored value used to
  // spell the object-form primary key as `field`; the notifier framework parses `sourceField`, so every
  // object entry silently deserialized with a null `sourceField` and the field was excluded from the Slack
  // message at runtime. These tests validate that the bundled JSON parses via LoggerNotifierConfiguration
  // AND that every configured source-field path resolves against the org schema, which catches both the
  // key mismatch and a stale field API name in a single assertion.

  @IsTest
  static void it_has_slack_suggested_configuration_json_that_deserializes_cleanly() {
    LoggerNotifierType__mdt bundledRecord = querySuggestedConfigurationJson('Slack');
    Map<String, LoggerNotifierConfiguration> configurationsBySObjectKey = deserializeSuggestedConfigurations(bundledRecord);

    LoggerNotifierConfiguration logEntryConfiguration = configurationsBySObjectKey.get(Schema.LogEntry__c.SObjectType.toString());
    System.Assert.isNotNull(logEntryConfiguration, 'Slack SuggestedConfigurationJson__c should include a LogEntry__c entry');
    assertAllSourceFieldsHaveNonBlankSourceField(logEntryConfiguration, Schema.LogEntry__c.SObjectType);

    LoggerNotifierConfiguration logConfiguration = configurationsBySObjectKey.get(Schema.Log__c.SObjectType.toString());
    System.Assert.isNotNull(logConfiguration, 'Slack SuggestedConfigurationJson__c should include a Log__c entry');
    assertAllSourceFieldsHaveNonBlankSourceField(logConfiguration, Schema.Log__c.SObjectType);

    LoggerNotifierConfiguration wildcardConfiguration = configurationsBySObjectKey.get('*');
    System.Assert.isNotNull(wildcardConfiguration, 'Slack SuggestedConfigurationJson__c should include the "*" wildcard entry');
    List<LoggerNotifierConfiguration.SourceFieldDefinition> wildcardSourceFields = wildcardConfiguration.getSourceFields();
    System.Assert.isNotNull(wildcardSourceFields, 'Wildcard entry should carry a sourceFields list');
    System.Assert.isFalse(wildcardSourceFields.isEmpty(), 'Wildcard entry should carry at least one source field');
    for (LoggerNotifierConfiguration.SourceFieldDefinition definition : wildcardSourceFields) {
      System.Assert.isNotNull(definition.sourceField, 'Every wildcard sourceFields entry should populate its sourceField property');
      System.Assert.isTrue(String.isNotBlank(definition.sourceField), 'Every wildcard sourceFields entry should populate its sourceField property');
    }
  }

  @IsTest
  static void it_has_email_suggested_configuration_json_that_deserializes_cleanly() {
    // Email doesn't use object-form entries today, but the same guardrail applies: if a future edit
    // introduces one with the wrong key, the test breaks before the notifier silently drops the field.
    LoggerNotifierType__mdt bundledRecord = querySuggestedConfigurationJson('Email');
    Map<String, LoggerNotifierConfiguration> configurationsBySObjectKey = deserializeSuggestedConfigurations(bundledRecord);

    LoggerNotifierConfiguration logEntryConfiguration = configurationsBySObjectKey.get(Schema.LogEntry__c.SObjectType.toString());
    System.Assert.isNotNull(logEntryConfiguration, 'Email SuggestedConfigurationJson__c should include a LogEntry__c entry');
    assertAllSourceFieldsHaveNonBlankSourceField(logEntryConfiguration, Schema.LogEntry__c.SObjectType);

    LoggerNotifierConfiguration logConfiguration = configurationsBySObjectKey.get(Schema.Log__c.SObjectType.toString());
    System.Assert.isNotNull(logConfiguration, 'Email SuggestedConfigurationJson__c should include a Log__c entry');
    assertAllSourceFieldsHaveNonBlankSourceField(logConfiguration, Schema.Log__c.SObjectType);
  }

  @IsTest
  static void it_has_custom_notification_suggested_configuration_json_that_deserializes_cleanly() {
    LoggerNotifierType__mdt bundledRecord = querySuggestedConfigurationJson('CustomNotification');
    Map<String, LoggerNotifierConfiguration> configurationsBySObjectKey = deserializeSuggestedConfigurations(bundledRecord);
    System.Assert.isFalse(
      configurationsBySObjectKey.isEmpty(),
      'CustomNotification SuggestedConfigurationJson__c should deserialize into at least one SObject-keyed entry'
    );
    // The parser accepts absent sourceFields lists (falls back to notifier defaults) - the only invariant
    // worth asserting for CustomNotification is that whatever list IS present populates sourceField.
    for (String sobjectKey : configurationsBySObjectKey.keySet()) {
      List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = configurationsBySObjectKey.get(sobjectKey).getSourceFields();
      if (sourceFields == null) {
        continue;
      }
      for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
        System.Assert.isNotNull(definition.sourceField, 'Entry under key "' + sobjectKey + '" is missing its sourceField property (likely wrong JSON key)');
        System.Assert.isTrue(String.isNotBlank(definition.sourceField), 'Entry under key "' + sobjectKey + '" has a blank sourceField');
      }
    }
  }

  @IsTest
  static void it_has_slack_suggested_configuration_json_that_resolves_the_reference_style_source_field() {
    // Narrow, high-signal regression assertion for the exact defect - the LogEntry__c entry's first
    // sourceField is the object form { "sourceField": "Log__r.LoggedBy__c", ... }. Under the pre-fix
    // parser (which read the `field` key), definition.sourceField came back null and the notifier
    // silently dropped the LoggedBy attachment. Asserting the resolved path here directly reproduces
    // the failure the bug caused in production Slack messages.
    LoggerNotifierType__mdt bundledRecord = querySuggestedConfigurationJson('Slack');
    Map<String, LoggerNotifierConfiguration> configurationsBySObjectKey = deserializeSuggestedConfigurations(bundledRecord);
    LoggerNotifierConfiguration logEntryConfiguration = configurationsBySObjectKey.get(Schema.LogEntry__c.SObjectType.toString());
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = logEntryConfiguration.getSourceFields();

    System.Assert.isNotNull(sourceFields, 'LogEntry__c entry should carry a sourceFields list');
    System.Assert.isFalse(sourceFields.isEmpty(), 'LogEntry__c entry should carry at least one source field');
    LoggerNotifierConfiguration.SourceFieldDefinition firstDefinition = sourceFields.get(0);
    System.Assert.areEqual('Log__r.LoggedBy__c', firstDefinition.sourceField, 'Object-form entry should populate its sourceField from the JSON');
    System.Assert.areEqual('Log__r.LoggedBy__r.Username', firstDefinition.displayField, 'Object-form entry should populate its displayField from the JSON');
  }

  private static LoggerNotifierType__mdt querySuggestedConfigurationJson(String developerName) {
    // LoggerNotifierType__mdt.getInstance() returns Long Text Area fields truncated at 255 chars, which
    // silently corrupts JSON longer than that. Round-trip via SOQL so the full JSON reaches the parser.
    return [SELECT DeveloperName, SuggestedConfigurationJson__c FROM LoggerNotifierType__mdt WHERE DeveloperName = :developerName];
  }

  private static Map<String, LoggerNotifierConfiguration> deserializeSuggestedConfigurations(LoggerNotifierType__mdt bundledRecord) {
    System.Assert.isNotNull(bundledRecord, 'Notifier type record is missing');
    System.Assert.isNotNull(bundledRecord.SuggestedConfigurationJson__c, 'SuggestedConfigurationJson__c should not be blank');
    Object parsed;
    try {
      parsed = System.JSON.deserializeUntyped(bundledRecord.SuggestedConfigurationJson__c);
    } catch (System.JSONException ex) {
      System.Assert.fail('SuggestedConfigurationJson__c on ' + bundledRecord.DeveloperName + ' failed to parse: ' + ex.getMessage());
    }
    System.Assert.isInstanceOfType(
      parsed,
      Map<String, Object>.class,
      'SuggestedConfigurationJson__c on ' + bundledRecord.DeveloperName + ' should be an SObject-keyed map'
    );
    Map<String, Object> parsedMap = (Map<String, Object>) parsed;
    Map<String, LoggerNotifierConfiguration> configurationsBySObjectKey = new Map<String, LoggerNotifierConfiguration>();
    for (String sobjectKey : parsedMap.keySet()) {
      // Re-serialize the per-SObject value so a LoggerNotificationRecipient__c stand-in can round-trip it
      // through the same parser the notifier framework uses at runtime.
      String perSObjectJson = System.JSON.serialize(parsedMap.get(sobjectKey));
      LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = perSObjectJson);
      configurationsBySObjectKey.put(sobjectKey, new LoggerNotifierConfiguration(recipient));
    }
    return configurationsBySObjectKey;
  }

  private static void assertAllSourceFieldsHaveNonBlankSourceField(LoggerNotifierConfiguration configuration, Schema.SObjectType sourceType) {
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = configuration.getSourceFields();
    System.Assert.isNotNull(sourceFields, 'Per-SObject entry should carry a sourceFields list');
    System.Assert.isFalse(sourceFields.isEmpty(), 'Per-SObject entry should carry at least one source field');
    for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
      System.Assert.isNotNull(definition.sourceField, 'Every sourceFields entry should populate its sourceField property');
      System.Assert.isTrue(String.isNotBlank(definition.sourceField), 'Every sourceFields entry should populate its sourceField property');
      Schema.DescribeFieldResult describe = LoggerNotifier.getDescribeByPath(sourceType, definition.sourceField);
      System.Assert.isNotNull(describe, 'sourceField "' + definition.sourceField + '" should resolve to a real field on ' + sourceType);
      if (String.isNotBlank(definition.displayField)) {
        Schema.DescribeFieldResult displayDescribe = LoggerNotifier.getDescribeByPath(sourceType, definition.displayField);
        System.Assert.isNotNull(displayDescribe, 'displayField "' + definition.displayField + '" should resolve to a real field on ' + sourceType);
      }
    }
  }
}
