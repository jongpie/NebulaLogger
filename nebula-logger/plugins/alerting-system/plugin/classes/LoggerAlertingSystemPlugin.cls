//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that integrates with Slack to send alerts for important logs
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class LoggerAlertingSystemPlugin implements LoggerPlugin.Triggerable {
  private static final List<LoggerAlert__c> ALERT_RULES = new List<LoggerAlert__c>();
  @TestVisible
  private static final Set<Schema.SObjectType> SUPPORTED_SOBJECT_TYPES = new Set<Schema.SObjectType>{
    Schema.Log__c.SObjectType,
    Schema.LogEntry__c.SObjectType,
    Schema.LogEntryTag__c.SObjectType
  };

  /**
   * @description Interface used to create plugins that can be used within Nebula Logger's alert system `LoggerAlertService`
   */
  @SuppressWarnings('PMD.ApexDoc')
  public interface Alertable {
    void dispatch(LoggerPlugin__mdt configuration, LoggerAlertableContext input);
  }

  /**
   * @description Creates an instance of the class `LoggerPlugin.Alertable` based on the provided `LoggerPlugin__mdt` configuration
   * @param  apexClassTypeName The name of the Apex class that implements `LoggerPlugin.Alertable`
   * @return                     The dynamically created instance of `LoggerPlugin.Alertable`,
   *                             or `null` if an instance could not be created based on the provided configuration
   */
  public static Alertable newAlertableInstance(String apexClassTypeName) {
    Object pluginInstance = System.Type.forName(apexClassTypeName)?.newInstance();
    Boolean isValidInstance = pluginInstance instanceof Alertable;
    return (Alertable) (isValidInstance ? pluginInstance : null);
  }

  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext context) {
    if (
      context.triggerOperationType != System.TriggerOperation.AFTER_INSERT ||
      SUPPORTED_SOBJECT_TYPES.contains(context.sobjectType) == false ||
      ALERT_RULES.isEmpty()
    ) {
      return;
    }

    // TODO call LoggerAlertService
    LoggerAlertService.getInstance().process(context.triggerNew);
  }
}
