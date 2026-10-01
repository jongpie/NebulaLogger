//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries
 */
public without sharing class LogEntryFieldSetPicklist extends VisualEditor.DynamicPickList {
  /**
   * @description Returns the default `LogEntry__c` field set, based on the `LoggerParameter__mdt` record `DefaultLogEntryRelatedListFieldSet`
   * @return And instance of `VisualEditor.DataRow` if a valid, matching field set exists, or `null`
   */
  public override VisualEditor.DataRow getDefaultValue() {
    if (String.isBlank(LoggerParameter.DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET)) {
      return null;
    }

    Schema.FieldSet configuredFieldSet = Schema.SObjectType.LogEntry__c.fieldSets.getMap().get(LoggerParameter.DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET);
    return configuredFieldSet == null ? null : this.createDataRow(configuredFieldSet);
  }

  /**
   * @description Returns the list of fields sets on `LogEntry__c`, allowing admins to specify any
   *   field set for each instance of the `RelatedLogEntries` component
   * @return   The list of field sets on the LogEntry__c object
   */
  public override VisualEditor.DynamicPickListRows getValues() {
    VisualEditor.DynamicPickListRows picklistRows = new VisualEditor.DynamicPickListRows();

    List<Schema.FieldSet> fieldSets = Schema.SObjectType.LogEntry__c.fieldSets.getMap().values();
    for (Schema.FieldSet fieldSet : fieldSets) {
      picklistRows.addRow(this.createDataRow(fieldSet));
    }

    return picklistRows;
  }

  private VisualEditor.DataRow createDataRow(Schema.FieldSet fieldSet) {
    String namespacePrefix = String.isBlank(fieldSet.getNamespace()) ? '' : fieldSet.getNamespace() + '__';
    return new VisualEditor.DataRow(fieldSet.getLabel(), namespacePrefix + fieldSet.getName());
  }
}
