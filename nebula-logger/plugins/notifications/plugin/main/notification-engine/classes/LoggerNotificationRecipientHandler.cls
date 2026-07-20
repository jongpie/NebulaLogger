//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Handles trigger events for the `LoggerNotificationRecipient__c` object. Validates that
 *              `ConfigurationJson__c` (when populated) is a JSON object whose top-level shape
 *              parses as `Map<String, Object>`. Blocks the save with a field-level error otherwise so
 *              admins cannot persist a config JSON that the notifier runtime would refuse to consume.
 */
public without sharing class LoggerNotificationRecipientHandler extends LoggerSObjectHandler {
  private static final String INVALID_JSON_ERROR_PREFIX = 'Configuration JSON is not valid JSON: ';
  private static final String TOP_LEVEL_SHAPE_ERROR_MESSAGE = 'Configuration JSON must be a JSON object (Map<String, Object>). Top-level arrays, strings, numbers, booleans, and nulls are not allowed.';

  /**
   * @description Returns the SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerNotificationRecipient__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    this.validateConfigurationJson(triggerNew, null);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    this.validateConfigurationJson(triggerNewMap.values(), triggerOldMap);
  }

  private void validateConfigurationJson(List<SObject> records, Map<Id, SObject> triggerOldMap) {
    for (SObject record : records) {
      LoggerNotificationRecipient__c recipient = (LoggerNotificationRecipient__c) record;
      if (String.isBlank(recipient.ConfigurationJson__c)) {
        continue;
      }
      if (triggerOldMap != null) {
        LoggerNotificationRecipient__c oldRecipient = (LoggerNotificationRecipient__c) triggerOldMap.get(recipient.Id);
        if (oldRecipient != null && oldRecipient.ConfigurationJson__c == recipient.ConfigurationJson__c) {
          continue;
        }
      }
      Object parsed;
      try {
        parsed = System.JSON.deserializeUntyped(recipient.ConfigurationJson__c);
      } catch (System.JSONException parseException) {
        recipient.ConfigurationJson__c.addError(INVALID_JSON_ERROR_PREFIX + parseException.getMessage());
        continue;
      }
      if ((parsed instanceof Map<String, Object>) == false) {
        recipient.ConfigurationJson__c.addError(TOP_LEVEL_SHAPE_ERROR_MESSAGE);
      }
    }
  }
}
