//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LoggerAlert__c` object
 */
public without sharing class LoggerAlertHandler extends LoggerSObjectHandler {
  /**
   * @description Returns SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerAlert__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    List<LoggerAlert__c> loggerNotifications = (List<LoggerAlert__c>) triggerNew;

    setOrganizationId(loggerNotifications);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    List<LoggerAlert__c> loggerNotifications = (List<LoggerAlert__c>) triggerNewMap.values();

    setOrganizationId(loggerNotifications);
  }

  private static void setOrganizationId(List<LoggerAlert__c> loggerNotifications) {
    for (LoggerAlert__c loggerNotification : loggerNotifications) {
      loggerNotification.OriginOrganizationId__c = System.UserInfo.getOrganizationId();
    }
  }
}
