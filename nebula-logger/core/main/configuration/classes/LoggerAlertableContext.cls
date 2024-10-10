//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used by the logging system for alert contextual details
 * @see LoggerAlertService
 * @see LoggerPlugin
 */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class LoggerAlertableContext {
  public List<SObject> loggingRecords;
  public LoggerAlert__c alert;
  public transient Schema.SObjectType sobjectType;
  public String sobjectTypeName;

  /**
   * @description Constructor used to set the details of the SObject Type & records for a notification
   * @param  loggingRecords      The `List<SObject>` of records that triggered the notification
   */
  public LoggerAlertableContext(LoggerAlert__c alert, List<SObject> loggingRecords) {
    this.alert = alert;
    this.loggingRecords = loggingRecords;
    this.sobjectType = loggingRecords.getSObjectType();

    this.sobjectTypeName = this.sobjectType?.toString();
  }
}
