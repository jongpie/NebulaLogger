//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Integration test class used to validate that the bundled records in LoggerNotifierType__mdt
 *              have the expected default values.
 * @see LoggerNotifier
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CMDT_LoggerNotifierType_Tests {
  @IsTest
  static void it_has_correct_record_for_custom_notification() {
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
  static void it_has_correct_record_for_email() {
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
  static void it_has_correct_record_for_generic_webhook() {
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
  static void it_has_correct_record_for_google_chat() {
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
  static void it_has_correct_record_for_microsoft_teams() {
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
  static void it_has_correct_record_for_open_telemetry() {
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
  static void it_has_correct_record_for_pager_duty() {
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
  static void it_has_correct_record_for_slack() {
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
}
