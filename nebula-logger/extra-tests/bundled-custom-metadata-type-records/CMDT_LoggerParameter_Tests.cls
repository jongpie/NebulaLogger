//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Integration test class used to validate that the bundled records in LoggerParameter__mdt
 *              have the expected default values.
 * @see LoggerConfigurationSelector
 * @see LoggerParameter
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CMDT_LoggerParameter_Tests {
  @IsTest
  static void it_has_correct_record_for_call_status_api() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('CallStatusApi');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Call Status API', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_default_log_entry_related_list_field_set() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('DefaultLogEntryRelatedListFieldSet');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Default Log Entry Related List Field Set', bundledRecord.Label);
    System.Assert.areEqual('Related_List_Defaults', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_enable_log_entry_event_stream() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('EnableLogEntryEventStream');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Enable Log Entry Event Stream', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_enable_stack_trace_parsing() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('EnableStackTraceParsing');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Enable Stack Trace Parsing', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_enable_logger_system_messages() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('EnableLoggerSystemMessages');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Enable Logger System Messages', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_enable_tagging() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('EnableTagging');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Enable Tagging', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_normalize_scenario_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('NormalizeScenarioData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Normalize Scenario Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_normalize_tag_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('NormalizeTagData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Normalize Tag Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_platform_cache_partition_name() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('PlatformCachePartitionName');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Platform Cache Partition Name', bundledRecord.Label);
    System.Assert.areEqual('LoggerCache', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_apex_class_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryApexClassData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Apex Class Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_apex_trigger_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryApexTriggerData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Apex Trigger Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_auth_session_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryAuthSessionData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Auth Session Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_auth_session_data_synchronously() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryAuthSessionDataSynchronously');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Auth Session Data Synchronously', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_flow_definition_view_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryFlowDefinitionViewData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Flow Definition View Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_omni_process_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryOmniProcessData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query OmniProcess Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_network_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryNetworkData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Network Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_network_data_synchronously() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryNetworkDataSynchronously');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Network Data Synchronously', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_organization_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryOrganizationData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Organization Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_organization_data_synchronously() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryOrganizationDataSynchronously');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Organization Data Synchronously', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_related_record_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryRelatedRecordData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query Related Record Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_user_data() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryUserData');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query User Data', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_query_user_data_synchronously() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('QueryUserDataSynchronously');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Query User Data Synchronously', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_require_scenario_usage() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('RequireScenarioUsage');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Require Scenario Usage', bundledRecord.Label);
    System.Assert.areEqual('false', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_send_error_email_notifications() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('SendErrorEmailNotifications');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Send Error Email Notifications', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_heap_size_limit() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreHeapSizeLimit');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store Heap Size Limit', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_http_request_header_values() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreHttpRequestHeaderValues');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store HTTP Request Header Values', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_http_response_header_values() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreHttpResponseHeaderValues');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store HTTP Response Header Values', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_organization_limits() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreOrganizationLimits');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store Organization Limits', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_rest_request_header_values() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreRestRequestHeaderValues');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store REST Request Header Values', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_rest_response_header_values() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreRestResponseHeaderValues');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store REST Response Header Values', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_store_transaction_limits() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('StoreTransactionLimits');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Store Transaction Limits', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_system_debug_message_format() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('SystemDebugMessageFormat');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('System.debug() Message Format', bundledRecord.Label);
    System.Assert.areEqual('{OriginLocation__c}\\n{Message__c}', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_use_first_specified_scenario() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('UseFirstSpecifiedScenario');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Use First Specified Scenario', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_use_platform_cache() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('UsePlatformCache');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Use Platform Cache', bundledRecord.Label);
    System.Assert.areEqual('true', bundledRecord.Value__c);
  }

  @IsTest
  static void it_has_correct_record_for_use_topics_for_tags() {
    LoggerParameter__mdt bundledRecord = LoggerParameter__mdt.getInstance('UseTopicsForTags');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isNull(bundledRecord.Comments__c, 'Comments should be null/blank');
    System.Assert.isNotNull(bundledRecord.Description__c, 'Description is missing');
    System.Assert.areEqual('Use Topics for Tags', bundledRecord.Label);
    System.Assert.areEqual('false', bundledRecord.Value__c);
  }

  /*
// LoggerParameter__mdt checks
// The field LoggerParameter__mdt.Description__c is a long textarea field, so it can't be marked as required - but every record
// should have the field populated before being added to the unlocked & managed packages.
for (LoggerParameter__mdt record : [SELECT DeveloperName, Description__c FROM LoggerParameter__mdt ORDER BY DeveloperName]) {
  if (record.Description__c == null) {
    throw new System.IllegalArgumentException('😡 Description__c field should be populated for LoggerParameter.' + record.DeveloperName);
  }
}
System.debug('🥳 LoggerParameter__mdt records have been correctly populated with a description!');

// LoggerSObjectHandler__mdt checks
// The field LoggerSObjectHandler__mdt.IsEnabled__c should be set to true for any records included in the packages.
for (LoggerSObjectHandler__mdt record : [SELECT DeveloperName, IsEnabled__c FROM LoggerSObjectHandler__mdt ORDER BY DeveloperName]) {
  if (record.IsEnabled__c == false) {
    throw new System.IllegalArgumentException('😡 IsEnabled__c field should be set to true for LoggerSObjectHandler.' + record.DeveloperName);
  }
}
System.debug('🥳 LoggerSObjectHandler__mdt records have been correctly enabled!');

// LogStatus__mdt checks
// The field LogStatus__mdt.IsActive__c should be set to true for any records included in the packages.
for (LogStatus__mdt record : [SELECT DeveloperName, IsActive__c FROM LogStatus__mdt ORDER BY DeveloperName]) {
  // TODO rename LogStatus__mdt.IsActive__c to IsEnabled__c for consistency with other objects
  if (record.IsActive__c == false) {
    throw new System.IllegalArgumentException('😡 IsActive__c field should be set to true for LogStatus.' + record.DeveloperName);
  }
}
System.debug('🥳 LogStatus__mdt records records have been correctly enabled!');
    */
}
