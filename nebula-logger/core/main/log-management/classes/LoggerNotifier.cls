//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Service class used for orchestrating & sending notifications for logging data,
 *              based on org-specific rules configured in `LoggerNotification__c`
 */
public without sharing class LoggerNotifier {
  private static final LoggerNotifier INSTANCE = new LoggerNotifier();

  private final List<LoggerNotification__c> notificationRules;
  private final List<LoggerPlugin__mdt> pluginConfigurations;

  public static LoggerNotifier getInstance() {
    return INSTANCE;
  }

  private LoggerNotifier() {
    // TODO improve where/how querying works, etc.
    this.notificationRules = [SELECT Id FROM LoggerNotification__c WHERE IsEnabled__c = TRUE];

    // TODO add new fields on LoggerPlugin__mdt for notification Apex & Flow & NotificationExecutionOrder__c?
    this.pluginConfigurations = LoggerPlugin.getFilteredPluginConfigurations(
      new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.SObjectHandlerApexClass__c, Schema.LoggerPlugin__mdt.SObjectHandlerFlowName__c },
      Schema.LoggerPlugin__mdt.SObjectHandlerExecutionOrder__c
    );
  }

  public void sendNotifications(List<SObject> loggingRecords) {
    for (LoggerNotification__c notificationRule : this.notificationRules) {
      this.executePlugins(notificationRule, loggingRecords);
    }
  }

  private void executePlugins(LoggerNotification__c notificationRule, List<SObject> loggingRecords) {
    if (this.pluginConfigurations == null || this.pluginConfigurations.isEmpty()) {
      return;
    }

    // for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
    //   // TODO add new fields on LoggerPlugin__mdt for notification Apex & Flow & NotificationExecutionOrder__c?
    //   if (String.isNotBlank(pluginConfiguration.SObjectHandlerApexClass__c)) {
    //     LoggerNotifiableContext context = new LoggerNotifiableContext(notificationRule, loggingRecords);
    //     this.executeApexPlugin(pluginConfiguration, context);
    //   }
    //   if (String.isNotBlank(pluginConfiguration.SObjectHandlerFlowName__c)) {
    //     this.executeFlowPlugin(pluginConfiguration);
    //   }
    // }
  }

  private List<LoggerPlugin.Notifiable> getNotificationPlugin(LoggerNotification__c notificationRule) {
    List<LoggerPlugin.Notifiable> notifiers = new List<LoggerPlugin.Notifiable>();
    for (LoggerNotificationRecipient__c recipient : notificationRule.LoggerNotificationRecipients__r) {
      String apexClassName;
      switch on recipient.Type__c {
        when 'Email' {
          apexClassName = 'TODO Email';
        }
        when 'OpenTelemetry' {
          // return getOpenTelemetryProviderPlugin();
          return null;
        }
        when 'Slack' {
          apexClassName = 'TODO Slack';
        }
      }
      notifiers.add(LoggerPlugin.newNotifiableInstance(apexClassName));
    }
    return notifiers;
  }

  // TODO move these to a OTel-specific class?
  private abstract class OpenTelemetryProvider {
  }

  private class DatadogOpenTelemetryProvider extends OpenTelemetryProvider {
  }
  private class ElasticOpenTelemetryProvider extends OpenTelemetryProvider {
  }
  private class HoneycombOpenTelemetryProvider extends OpenTelemetryProvider {
  }
  private class SplunkOpenTelemetryProvider extends OpenTelemetryProvider {
  }

  private static OpenTelemetryProvider getOpenTelemetryProviderPluginName(String otelProviderName) {
    OpenTelemetryProvider otelProvider;
    switch on otelProviderName {
      when 'Custom' {
        otelProvider = (OpenTelemetryProvider) System.Type.forName(otelProviderName)?.newInstance();
      }
      when 'Datadog' {
        otelProvider = new DatadogOpenTelemetryProvider();
      }
      when 'Elastic' {
        otelProvider = new ElasticOpenTelemetryProvider();
      }
      when 'Honeycomb' {
        otelProvider = new HoneycombOpenTelemetryProvider();
      }
      when 'Splunk' {
        otelProvider = new SplunkOpenTelemetryProvider();
      }
    }

    return otelProvider;
  }

  private void executeApexPlugin(LoggerPlugin__mdt configuration, LoggerNotifiableContext context) {
    // TODO add new fields on LoggerPlugin__mdt for notification Apex & Flow & NotificationExecutionOrder__c?
    LoggerPlugin.Notifiable apexPlugin = LoggerPlugin.newNotifiableInstance(configuration.SObjectHandlerApexClass__c);
    apexPlugin?.sendNotification(configuration, context);
  }

  private void executeFlowPlugin(LoggerPlugin__mdt configuration) {
    // TODO figure out inputs & outputs for Flow plugins

    // try {
    //   Map<String, Object> flowInputs = new Map<String, Object>();
    //   flowInputs.put(FLOW_PLUGIN_CONFIGURATION_INPUT_NAME, configuration);
    //   flowInputs.put(FLOW_PLUGIN_INPUT_NAME, this.input);

    //   Flow.Interview flowPlugin = Flow.Interview.createInterview(configuration.SObjectHandlerFlowName__c, flowInputs);
    //   flowPlugin.start();

    //   List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
    //   if (updatedTriggerNew != null && updatedTriggerNew.size() == this.input.triggerNew.size()) {
    //     this.input.triggerNew.clear();
    //     this.input.triggerNew.addAll(updatedTriggerNew);
    //     if (this.input.triggerNewMap != null) {
    //       this.input.triggerNewMap.clear();
    //       this.input.triggerNewMap.putAll(new Map<Id, SObject>(updatedTriggerNew));
    //     }
    //   }
    //   if (System.Test.isRunningTest() && flowPlugin != null) {
    //     this.executedFlowPlugins.add(flowPlugin);
    //   }
    // } catch (TypeException ex) {
    //   if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
    //     Logger.warn('Unknown Flow ' + configuration.SObjectHandlerFlowName__c + ', skipping plugin execution', configuration, ex);
    //   }
    // }
  }
  private class NotificationRuleEvaluator {
    private final List<NotificationCondition> parsedConditions;

    public NotificationRuleEvaluator(LoggerNotification__c notificationRule, List<LoggerNotificationCondition__c> configuredConditions) {
      this.parsedConditions = new List<NotificationCondition>();

      for (LoggerNotificationCondition__c configuredCondition : configuredConditions) {
        NotificationCondition condition = new NotificationCondition(configuredCondition);
      }
    }

    public List<SObject> getMatches(List<SObject> inputRecords) {
      List<SObject> matchingRecords = new List<SObject>();

      for (SObject inputRecord : inputRecords) {
        Boolean matches = true;
        for (NotificationCondition condition : this.parsedConditions) {
          if (condition.matches(inputRecord) == false) {
            matches = false;
            break;
          }
        }

        if (matches) {
          matchingRecords.add(inputRecord);
        }
      }
      return matchingRecords;
    }
  }

  private class NotificationCondition {
    public NotificationCondition(LoggerNotificationCondition__c configuredCondition) {
      // TODO
    }

    public Boolean matches(SObject inputRecord) {
      // TODO
      return false;
    }
  }
}
