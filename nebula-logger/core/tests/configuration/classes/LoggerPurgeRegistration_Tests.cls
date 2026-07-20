//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerPurgeRegistration_Tests {
  @IsTest
  static void it_should_build_query_that_orders_by_a_single_sort_field_when_registration_takes_the_single_field_constructor() {
    LoggerPurgeRegistration registration = new LoggerPurgeRegistration(
      Schema.Log__c.SObjectType,
      Schema.Log__c.LogRetentionDate__c,
      Schema.Log__c.LogRetentionDate__c
    );

    String query = registration.buildQuery();

    System.Assert.isTrue(query.endsWith('ORDER BY LogRetentionDate__c'), 'Single-field ORDER BY should have a single column with no comma: ' + query);
  }

  @IsTest
  static void it_should_build_query_that_orders_by_multiple_sort_fields_when_registration_takes_the_list_constructor() {
    // Multi-field ORDER BY is the reason the list-taking constructor overload exists: a plugin can
    // cluster its rows first by parent (to reduce lock scope on cascade delete) then by row age.
    LoggerPurgeRegistration registration = new LoggerPurgeRegistration(
      Schema.Log__c.SObjectType,
      Schema.Log__c.LogRetentionDate__c,
      new List<Schema.SObjectField>{ Schema.Log__c.LoggedBy__c, Schema.Log__c.LogRetentionDate__c }
    );

    String query = registration.buildQuery();

    System.Assert.isTrue(
      query.endsWith('ORDER BY LoggedBy__c, LogRetentionDate__c'),
      'Multi-field ORDER BY should join the columns in declaration order with a comma: ' + query
    );
  }

  @IsTest
  static void it_should_reject_a_null_sobject_type() {
    System.IllegalArgumentException thrown;
    try {
      new LoggerPurgeRegistration(null, Schema.Log__c.LogRetentionDate__c, Schema.Log__c.LogRetentionDate__c);
    } catch (System.IllegalArgumentException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A null sobjectType should be rejected in the constructor');
    System.Assert.isTrue(thrown.getMessage().contains('sobjectType'), 'Error message should identify the invalid field: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_reject_a_null_retention_date_field() {
    System.IllegalArgumentException thrown;
    try {
      new LoggerPurgeRegistration(Schema.Log__c.SObjectType, null, Schema.Log__c.LogRetentionDate__c);
    } catch (System.IllegalArgumentException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A null retentionDateField should be rejected in the constructor');
    System.Assert.isTrue(thrown.getMessage().contains('retentionDateField'), 'Error message should identify the invalid field: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_reject_a_null_sort_by_fields_list() {
    System.IllegalArgumentException thrown;
    try {
      new LoggerPurgeRegistration(Schema.Log__c.SObjectType, Schema.Log__c.LogRetentionDate__c, (List<Schema.SObjectField>) null);
    } catch (System.IllegalArgumentException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A null sortByFields list should be rejected in the constructor');
    System.Assert.isTrue(thrown.getMessage().contains('sortByFields'), 'Error message should identify the invalid field: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_reject_an_empty_sort_by_fields_list() {
    System.IllegalArgumentException thrown;
    try {
      new LoggerPurgeRegistration(Schema.Log__c.SObjectType, Schema.Log__c.LogRetentionDate__c, new List<Schema.SObjectField>());
    } catch (System.IllegalArgumentException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'An empty sortByFields list should be rejected in the constructor');
    System.Assert.isTrue(thrown.getMessage().contains('sortByFields'), 'Error message should identify the invalid field: ' + thrown.getMessage());
  }

  @IsTest
  static void it_should_reject_a_sort_by_fields_list_with_a_null_entry() {
    System.IllegalArgumentException thrown;
    try {
      new LoggerPurgeRegistration(
        Schema.Log__c.SObjectType,
        Schema.Log__c.LogRetentionDate__c,
        new List<Schema.SObjectField>{ Schema.Log__c.LogRetentionDate__c, null }
      );
    } catch (System.IllegalArgumentException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A sortByFields list containing a null entry should be rejected in the constructor');
    System.Assert.isTrue(thrown.getMessage().contains('sortByFields'), 'Error message should identify the invalid field: ' + thrown.getMessage());
  }
}
