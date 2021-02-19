public without sharing class RelatedLogEntriesFieldSetPicklist extends VisualEditor.DynamicPickList {
    private static final SObjectType LOG_ENTRY_SOJECT_TYPE = Schema.LogEntry__c.SObjectType;

    private VisualEditor.DesignTimePageContext context;

    public RelatedLogEntriesFieldSetPicklist(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    public override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows picklistRows = new VisualEditor.DynamicPickListRows();

        Map<String, FieldSet> fieldSetNameToFieldSet = LOG_ENTRY_SOJECT_TYPE.getDescribe().fieldSets.getMap();
        for (FieldSet fieldSet : fieldSetNameToFieldSet.values()) {
            String namespacePrefix = String.isEmpty(fieldSet.getNameSpace()) ? '' : fieldSet.getNameSpace() + '__';

            VisualEditor.DataRow picklistRow = new VisualEditor.DataRow(
                fieldSet.getLabel(),
                namespacePrefix + fieldSet.getName()
            );
            picklistRows.addRow(picklistRow);
        }

        return picklistRows;
    }
}
