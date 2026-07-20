//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Handles trigger events for the `LoggerNotificationService__c` object. Stamps
 *              `OriginOrganizationId__c` on insert so that services cloned into a refreshed sandbox from
 *              another org are flagged as invalid until an admin re-saves them in the current org.
 *              Also validates `NotifierApexClassName__c` at save time - the referenced class must exist
 *              and must implement `LoggerNotifiable` - so admins cannot save a service whose notifier
 *              class would fail at runtime. Rejects services that configure both a Named Credential and
 *              a Webhook URL at once (Slack + similar notifiers only consume one endpoint - accepting
 *              both is ambiguous). When an admin changes `OriginOrganizationId__c` on an existing
 *              service, wipes the endpoint fields so that secrets cloned in from another org do not
 *              silently dispatch after the admin re-owns the record.
 */
public without sharing class LoggerNotificationServiceHandler extends LoggerSObjectHandler {
  /**
   * @description Returns the SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerNotificationService__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    this.stampOriginOrganizationId(triggerNew);
    this.validateEndpointFields(triggerNew);
    this.validateNotifierApexClassName(triggerNew, null);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    this.wipeEndpointFieldsWhenOriginOrganizationIdChanged(triggerNewMap.values(), triggerOldMap);
    this.validateEndpointFields(triggerNewMap.values());
    this.validateNotifierApexClassName(triggerNewMap.values(), triggerOldMap);
  }

  private void stampOriginOrganizationId(List<SObject> records) {
    String currentOrganizationId = System.UserInfo.getOrganizationId();
    for (SObject record : records) {
      ((LoggerNotificationService__c) record).OriginOrganizationId__c = currentOrganizationId;
    }
  }

  private void validateEndpointFields(List<SObject> records) {
    for (SObject record : records) {
      LoggerNotificationService__c service = (LoggerNotificationService__c) record;
      if (String.isNotBlank(service.NamedCredentialDeveloperName__c) && String.isNotBlank(service.WebhookUrl__c)) {
        service.NamedCredentialDeveloperName__c.addError(
          'A service cannot have both a Named Credential Developer Name and a Webhook URL configured - notifiers dispatch to exactly one endpoint. Clear one of the two fields before saving.'
        );
      }
    }
  }

  /**
   * @description When an admin re-owns a service by manually changing `OriginOrganizationId__c`, treat
   *              the endpoint config as stale and wipe it. The typical trigger is a sandbox refresh
   *              that carried a production service's Named Credential / Webhook URL over: those
   *              secrets point at the production destination and shouldn't fire from the new org
   *              until an admin re-enters them. Skips records whose `OriginOrganizationId__c` value
   *              was not touched on this update.
   */
  private void wipeEndpointFieldsWhenOriginOrganizationIdChanged(List<SObject> records, Map<Id, SObject> triggerOldMap) {
    if (triggerOldMap == null) {
      return;
    }
    for (SObject record : records) {
      LoggerNotificationService__c service = (LoggerNotificationService__c) record;
      LoggerNotificationService__c oldService = (LoggerNotificationService__c) triggerOldMap.get(service.Id);
      if (oldService == null) {
        continue;
      }
      if (oldService.OriginOrganizationId__c == service.OriginOrganizationId__c) {
        continue;
      }
      service.NamedCredentialDeveloperName__c = null;
      service.WebhookUrl__c = null;
    }
  }

  private void validateNotifierApexClassName(List<SObject> records, Map<Id, SObject> triggerOldMap) {
    for (SObject record : records) {
      LoggerNotificationService__c service = (LoggerNotificationService__c) record;
      if (String.isBlank(service.NotifierApexClassName__c)) {
        continue;
      }
      if (triggerOldMap != null) {
        LoggerNotificationService__c oldService = (LoggerNotificationService__c) triggerOldMap.get(service.Id);
        if (oldService != null && oldService.NotifierApexClassName__c == service.NotifierApexClassName__c) {
          continue;
        }
      }
      String validationError = validateNotifierClass(service.NotifierApexClassName__c);
      if (validationError != null) {
        service.NotifierApexClassName__c.addError(validationError);
      }
    }
  }

  @TestVisible
  private static String validateNotifierClass(String apexClassName) {
    System.Type resolved = resolveApexType(apexClassName);
    if (resolved == null) {
      return 'Apex class ' + apexClassName + ' was not found. Enter the developer name of an Apex class that implements LoggerNotifiable.';
    }
    Object instance;
    try {
      instance = resolved.newInstance();
    } catch (System.Exception ex) {
      return 'Apex class ' + apexClassName + ' could not be instantiated: ' + ex.getMessage();
    }
    if ((instance instanceof LoggerNotifiable) == false) {
      return 'Apex class ' + apexClassName + ' does not implement LoggerNotifiable.';
    }
    return null;
  }

  /**
   * @description Resolves an Apex class name to a `System.Type`. Stored class names typically use
   *              the unqualified local name (e.g. `SlackLoggerNotifier`); in managed-package installations
   *              the runtime name is namespace-prefixed (e.g. `Nebula.SlackLoggerNotifier`), so this method
   *              retries with `<namespace>.` when the raw lookup fails.
   * @param  apexClassName The stored Apex class name.
   * @return               The resolved `System.Type`, or `null` if it cannot be resolved.
   */
  private static System.Type resolveApexType(String apexClassName) {
    if (String.isBlank(apexClassName)) {
      return null;
    }
    System.Type resolved = System.Type.forName(apexClassName);
    if (resolved != null) {
      return resolved;
    }
    String namespacePrefix = Logger.getNamespacePrefix();
    if (String.isNotBlank(namespacePrefix) && apexClassName.contains('.') == false) {
      resolved = System.Type.forName(namespacePrefix + '.' + apexClassName);
    }
    return resolved;
  }
}
