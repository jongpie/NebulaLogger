//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// A lot of this class's code originated in https://github.com/jongpie/ApexValidationRules        //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin for publishing a filtered list of `LogEntryEvent__e` records as `FilteredLogEntryEvent__e` records
 */
public without sharing class FilteredEventLoggerPlugin extends LoggerSObjectHandlerPlugin {
    // private static final List<LogEntryEventFilter__mdt> QUERIED_FILTERS = new List<LogEntryEventFilter__mdt>();

    private final Map<String, LogEntryEventFilter__mdt> filtersByDeveloperName = new Map<String, LogEntryEventFilter__mdt>();
    private final Map<String, List<LogEntryEventFilterCondition__mdt>> conditionsByFilterDeveloperName = new Map<String, List<LogEntryEventFilterCondition__mdt>>();

    private List<SObject> records;
    private Schema.SObjectType sobjectType;
    private String languageLocaleKey = UserInfo.getLanguage();

    public override void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    ) {
        switch on triggerOperationType {
            when AFTER_INSERT {
                List<LogEntryEvent__e> logEntryEvents = (List<LogEntryEvent__e>) triggerNew;
                this.createFilteredLogEntryEvents(logEntryEvents);
            }
        }
    }

    private void createFilteredLogEntryEvents(List<LogEntryEvent__e> logEntryEvents) {
        List<FilteredLogEntryEvent__e> filteredLogEntryEvents = new List<FilteredLogEntryEvent__e>();
        for (FilterResult filterResult : this.runFilters(logEntryEvents)) {
            if (filterResult.matchesFilter == true) {
                // The proper way to do this is to map each individual field from LogEntryEvent__e to FilteredLogEntryEvent__e
                // But the field names should match betwen objects, so a one-liner of JSON serialize/deserialize does it automatically
                FilteredLogEntryEvent__e filteredEvent = (FilteredLogEntryEvent__e) JSON.deserialize(
                    JSON.serialize(filterResult.record),
                    FilteredLogEntryEvent__e.class
                );
                filteredLogEntryEvents.add(filteredEvent);
            }
        }
        EventBus.publish(filteredLogEntryEvents);
    }

    // Private methods
    private void loadConfiguredFilters() {
        for (LogEntryEventFilter__mdt filter : [
            SELECT
                DeveloperName,
                ConditionLogicType__c,
                CustomConditionLogic__c,
                (SELECT FieldPath__c, Operator__c, ValueType__c, Value__c FROM LogEntryEventFilterConditions__r ORDER BY SortOrder__c NULLS LAST, DeveloperName)
            FROM LogEntryEventFilter__mdt
            WHERE IsActive__c = TRUE
        ]) {
            this.filtersByDeveloperName.put(filter.DeveloperName, filter);
            this.conditionsByFilterDeveloperName.put(filter.DeveloperName, filter.LogEntryEventFilterConditions__r);
        }
    }

    private List<FilterResult> runFilters(List<LogEntryEvent__e> logEntryEvents) {
        if (this.filtersByDeveloperName.isEmpty()) {
            this.loadConfiguredFilters();
        }

        List<FilterResult> results = new List<FilterResult>();
        for (SObject record : logEntryEvents) {
            for (String filterDeveloperName : this.filtersByDeveloperName.keySet()) {
                LogEntryEventFilter__mdt filter = this.filtersByDeveloperName.get(filterDeveloperName);
                List<LogEntryEventFilterCondition__mdt> filerConditions = this.conditionsByFilterDeveloperName.get(filter.DeveloperName);
                FilterResult filterResult = new FilterResult(record, filter, filerConditions);

                results.add(filterResult);
            }
        }
        return results;
    }

    private class FilterResult {
        public SObject record { get; private set; }
        public List<String> conditions { get; private set; }
        public String conditionsLogic { get; private set; }
        public String conditionsLogicType { get; private set; }
        public Boolean matchesFilter { get; private set; }

        private LogEntryEventFilter__mdt filter;
        private List<LogEntryEventFilterCondition__mdt> filerConditions;

        public FilterResult(SObject record, LogEntryEventFilter__mdt filter, List<LogEntryEventFilterCondition__mdt> filerConditions) {
            this.record = record;
            this.filter = filter;
            this.filerConditions = filerConditions;

            this.conditions = new List<String>();
            this.conditionsLogic = this.getFilterConditionsLogic();
            this.conditionsLogicType = filter.ConditionLogicType__c;

            this.process();
        }

        private void process() {
            List<String> booleanValues = new List<String>();
            for (LogEntryEventFilterCondition__mdt filerCondition : this.filerConditions) {
                FilterConditionResult filerConditionResult = new FilterConditionResult(this.record, filerCondition);
                this.conditions.add(filerConditionResult.getCondition());
                booleanValues.add(String.valueOf(filerConditionResult.matchesFilter));
            }

            String parsedConditionsLogic = String.format(this.getFilterConditionsLogic(), booleanValues);

            this.matchesFilter = new BooleanExpression().evaluate(parsedConditionsLogic);
        }

        private String getFilterConditionsLogic() {
            String conditionsLogic = String.isBlank(this.filter.CustomConditionLogic__c) ? '' : this.filter.CustomConditionLogic__c;

            if (this.filter.ConditionLogicType__c != 'Custom') {
                List<String> standardLogicPieces = new List<String>();
                for (Integer i = 0; i < this.filerConditions.size(); i++) {
                    standardLogicPieces.add(String.valueOf(i + 1));
                }
                conditionsLogic = '(' + String.join(standardLogicPieces, ' ' + this.filter.ConditionLogicType__c + ' ') + ')';
            }

            List<String> parsedCharacters = new List<String>();
            Boolean hasFoundNumbers = false;
            String foundNumberString = '';

            for (String character : conditionsLogic.split('')) {
                if (!character.isNumeric() && !hasFoundNumbers) {
                    parsedCharacters.add(character);
                } else if (!character.isNumeric() && hasFoundNumbers) {
                    hasFoundNumbers = false;
                    Integer foundNumber = Integer.valueOf(foundNumberString) - 1;
                    System.debug('foundNumber==' + foundNumber);

                    parsedCharacters.add('{' + foundNumber + '}');
                    foundNumberString = '';
                    parsedCharacters.add(character);
                } else if (character.isNumeric()) {
                    hasFoundNumbers = true;
                    foundNumberString += character;
                } else if (hasFoundNumbers && !character.isNumeric() && !String.isBlank(foundNumberString)) {
                    Integer foundNumber = Integer.valueOf(foundNumberString) - 1;
                    System.debug('foundNumber==' + foundNumber);

                    parsedCharacters.add('{' + foundNumber + '}');
                    foundNumberString = '';
                } else {
                    parsedCharacters.add(character);
                }
            }
            return String.join(parsedCharacters, '').toUpperCase();
        }
    }

    private class FilterConditionResult {
        private Boolean matchesFilter;
        private SObject record;
        private LogEntryEventFilterCondition__mdt filerCondition;
        private String sobjectApiName;

        private FilterConditionResult(SObject record, LogEntryEventFilterCondition__mdt filerCondition) {
            this.record = record;
            this.filerCondition = filerCondition;
            this.sobjectApiName = this.record.getSObjectType().getDescribe().getName();

            this.matchesFilter = this.matchesFilter();
        }

        public String getCondition() {
            return this.filerCondition.FieldPath__c +
                ' ' +
                this.filerCondition.Operator__c +
                ' ' +
                this.getComparisonValue() +
                ' (' +
                this.filerCondition.ValueType__c +
                ')';
        }

        public Boolean matchesFilter() {
            if (this.filerCondition.ValueType__c == 'RegEx') {
                return this.matchesRegEx();
            }

            Schema.SObjectField field = new FieldPath(this.sobjectApiName, this.filerCondition.FieldPath__c).getField();

            Object recordFieldValue = this.getFieldValue();
            Object comparisonValue = this.getComparisonValue();

            switch on field.getDescribe().getSoapType() {
                when BOOLEAN {
                    return this.compareBoolean((Boolean) recordFieldValue, this.getAsBoolean(comparisonValue));
                }
                when DOUBLE, INTEGER {
                    return this.compareDecimal((Decimal) recordFieldValue, this.getAsDecimal(comparisonValue));
                }
                when DATE {
                    return this.compareDate((Date) recordFieldValue, this.getAsDate(comparisonValue));
                }
                when DATETIME {
                    return this.compareDatetime((Datetime) recordFieldValue, this.getAsDatetime(comparisonValue));
                }
                when STRING, ID {
                    return this.compareString((String) recordFieldValue, String.valueOf(comparisonValue));
                }
                when TIME {
                    return this.compareTime((Time) recordFieldValue, this.getAsTime(comparisonValue));
                }
                when else {
                    throw new IllegalArgumentException('Could not process field path: ' + this.filerCondition.FieldPath__c);
                }
            }
        }

        private Boolean matchesRegEx() {
            Pattern pattern = Pattern.compile(this.filerCondition.Value__c);
            return pattern.matcher(String.valueOf(this.getFieldValue())).matches();
        }

        private Object getFieldValue() {
            return new FieldPath(this.sobjectApiName, this.filerCondition.FieldPath__c).getValue(this.record);
        }

        private Object getComparisonValue() {
            switch on this.filerCondition.ValueType__c {
                when 'Field' {
                    return new FieldPath(this.sobjectApiName, this.filerCondition.Value__c).getValue(this.record);
                }
                when 'RegEx' {
                    return this.filerCondition.Value__c;
                }
                when 'Value' {
                    return this.filerCondition.Value__c;
                }
                when else {
                    throw new IllegalArgumentException('Unknown Value Type, cannot parse comparison value');
                }
            }
        }

        // Helper methods for dealing with converting field values & strings
        // (stored in CMDT) to the appropriate data type
        private Boolean getAsBoolean(Object booleanValue) {
            if (booleanValue == null) {
                return null;
            } else if (booleanValue instanceof Boolean) {
                return (Boolean) booleanValue;
            } else {
                return Boolean.valueOf(booleanValue);
            }
        }

        private Date getAsDate(Object dateValue) {
            if (dateValue == null) {
                return null;
            } else if (dateValue instanceof Date) {
                return (Date) dateValue;
            } else {
                String dateString = (String) dateValue;
                return (Date) JSON.deserialize(dateString, Date.class);
            }
        }

        private Datetime getAsDatetime(Object datetimeValue) {
            if (datetimeValue == null) {
                return null;
            } else if (datetimeValue instanceof Datetime) {
                return (Datetime) datetimeValue;
            } else {
                String datetimeString = (String) datetimeValue;
                return (Datetime) JSON.deserialize(datetimeString, Datetime.class);
            }
        }

        private Decimal getAsDecimal(Object decimalValue) {
            if (decimalValue == null) {
                return null;
            } else if (decimalValue instanceof Decimal) {
                return (Decimal) decimalValue;
            } else {
                String decimalString = (String) decimalValue;
                return (Decimal) JSON.deserialize(decimalString, Decimal.class);
            }
        }

        private Time getAsTime(Object timeValue) {
            if (timeValue == null) {
                return null;
            } else if (timeValue instanceof Time) {
                return (Time) timeValue;
            } else {
                String timeString = (String) timeValue;
                return (Time) JSON.deserialize(timeString, Time.class);
            }
        }

        // In Apex, you can't use comparison operators on instances of Object, so several private methods are used for each data type
        // Example of what you can't do in Apex:
        //          Object today = System.today();
        //          Object yesterday = System.today().addDays(-1);
        //          System.assert(today > yesterday); // This line cannot execute since it's comparing Object
        private Boolean compareBoolean(Boolean recordFieldValue, Boolean comparisonValue) {
            switch on this.filerCondition.Operator__c {
                when 'EQUAL_TO' {
                    return recordFieldValue == comparisonValue;
                }
                when 'NOT_EQUAL_TO' {
                    return recordFieldValue != comparisonValue;
                }
                when else {
                    throw new IllegalArgumentException('Unsupported operator for Boolean: ' + this.filerCondition.Operator__c);
                }
            }
        }

        private Boolean compareDate(Date recordFieldValue, Date comparisonValue) {
            switch on this.filerCondition.Operator__c {
                when 'EQUAL_TO' {
                    return recordFieldValue == comparisonValue;
                }
                when 'NOT_EQUAL_TO' {
                    return recordFieldValue != comparisonValue;
                }
                when 'LESS_THAN' {
                    return recordFieldValue < comparisonValue;
                }
                when 'LESS_THAN_OR_EQUAL_TO' {
                    return recordFieldValue <= comparisonValue;
                }
                when 'GREATER_THAN' {
                    return recordFieldValue > comparisonValue;
                }
                when 'GREATER_THAN_OR_EQUAL_TO' {
                    return recordFieldValue >= comparisonValue;
                }
                when else {
                    throw new IllegalArgumentException('Unsupported operator for Date: ' + this.filerCondition.Operator__c);
                }
            }
        }

        private Boolean compareDatetime(Datetime recordFieldValue, Datetime comparisonValue) {
            switch on this.filerCondition.Operator__c {
                when 'EQUAL_TO' {
                    return recordFieldValue == comparisonValue;
                }
                when 'NOT_EQUAL_TO' {
                    return recordFieldValue != comparisonValue;
                }
                when 'LESS_THAN' {
                    return recordFieldValue < comparisonValue;
                }
                when 'LESS_THAN_OR_EQUAL_TO' {
                    return recordFieldValue <= comparisonValue;
                }
                when 'GREATER_THAN' {
                    return recordFieldValue > comparisonValue;
                }
                when 'GREATER_THAN_OR_EQUAL_TO' {
                    return recordFieldValue >= comparisonValue;
                }
                when else {
                    throw new IllegalArgumentException('Unsupported operator for Datetime: ' + this.filerCondition.Operator__c);
                }
            }
        }

        private Boolean compareDecimal(Decimal recordFieldValue, Decimal comparisonValue) {
            switch on this.filerCondition.Operator__c {
                when 'EQUAL_TO' {
                    return recordFieldValue == comparisonValue;
                }
                when 'NOT_EQUAL_TO' {
                    return recordFieldValue != comparisonValue;
                }
                when 'LESS_THAN' {
                    return recordFieldValue < comparisonValue;
                }
                when 'LESS_THAN_OR_EQUAL_TO' {
                    return recordFieldValue <= comparisonValue;
                }
                when 'GREATER_THAN' {
                    return recordFieldValue > comparisonValue;
                }
                when 'GREATER_THAN_OR_EQUAL_TO' {
                    return recordFieldValue >= comparisonValue;
                }
                when else {
                    throw new IllegalArgumentException('Unsupported operator for Decimal: ' + this.filerCondition.Operator__c);
                }
            }
        }

        private Boolean compareString(String recordFieldValue, String comparisonValue) {
            switch on this.filerCondition.Operator__c {
                when 'EQUAL_TO' {
                    return recordFieldValue == comparisonValue;
                }
                when 'NOT_EQUAL_TO' {
                    return recordFieldValue != comparisonValue;
                }
                when 'STARTS_WITH' {
                    return recordFieldValue.startsWith(comparisonValue);
                }
                when 'CONTAINS' {
                    return recordFieldValue.contains(comparisonValue);
                }
                when 'ENDS_WITH' {
                    return recordFieldValue.endsWith(comparisonValue);
                }
                when else {
                    throw new IllegalArgumentException('Unsupported operator for String: ' + this.filerCondition.Operator__c);
                }
            }
        }

        private Boolean compareTime(Time recordFieldValue, Time comparisonValue) {
            switch on this.filerCondition.Operator__c {
                when 'EQUAL_TO' {
                    return recordFieldValue == comparisonValue;
                }
                when 'NOT_EQUAL_TO' {
                    return recordFieldValue != comparisonValue;
                }
                when 'LESS_THAN' {
                    return recordFieldValue < comparisonValue;
                }
                when 'LESS_THAN_OR_EQUAL_TO' {
                    return recordFieldValue <= comparisonValue;
                }
                when 'GREATER_THAN' {
                    return recordFieldValue > comparisonValue;
                }
                when 'GREATER_THAN_OR_EQUAL_TO' {
                    return recordFieldValue >= comparisonValue;
                }
                when else {
                    throw new IllegalArgumentException('Unsupported operator for Time: ' + this.filerCondition.Operator__c);
                }
            }
        }
    }

    // Credit goes to this StackExchange post for the original BooleanExpression class -
    // below is a modified version of the class
    // https://salesforce.stackexchange.com/questions/113300/boolean-evaluation-in-apex/113308
    private class BooleanExpression {
        public Boolean evaluate(String x) {
            x = simplify(x);

            if (isSimpleExpression(x)) {
                return Boolean.valueOf(x);
            }

            if (x.contains('&&')) {
                return andJoin(x.split('&&', 2)[0], x.split('&&', 2)[1]);
            }

            if (x.contains('||')) {
                String p1 = x.split('\\|\\|', 2)[0];
                String p2 = x.split('\\|\\|', 2)[1];

                return orJoin(p1, p2);
            }

            if (x.startsWith('!')) {
                return !evaluate(x.substring(1));
            }

            return Boolean.valueOf(x);
        }

        private Boolean orJoin(String x, String y) {
            return evaluate(x) || evaluate(y);
        }

        private Boolean andJoin(String x, String y) {
            return evaluate(x) && evaluate(y);
        }

        private Boolean isSimpleExpression(String x) {
            return x == 'true' || x == 'false';
        }

        private String simplify(String x) {
            x = x.trim();
            x = x.replace('AND', '&&');
            x = x.replace('OR', '||');
            while (x.contains('(') == true) {
                String sub = x.substringAfterLast('(').substringBefore(')');
                x = x.replace('(' + sub + ')', String.valueOf(evaluate(sub)));
            }
            return x;
        }
    }

    private class FieldPath {
        private List<Schema.SObjectField> fieldChain;
        private Schema.DescribeFieldResult fieldDescribe;
        private String fieldPath;
        private Schema.SObjectType sobjectType;

        public FieldPath(String sobjectApiName, String fieldPath) {
            Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);

            this.fieldChain = this.getFieldChain(sobjectType, fieldPath);
            this.fieldPath = fieldPath;

            this.fieldDescribe = this.getLastFieldDescribe();
        }

        public Schema.SObjectField getField() {
            return this.fieldChain[this.fieldChain.size() - 1];
        }

        public Object getValue(SObject record) {
            Schema.SObjectType parentSObjectType = this.sobjectType;
            SObject parentRecord = record;

            for (Schema.SObjectField field : this.fieldChain) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                String relationshipName = fieldDescribe.getRelationshipName();

                if (fieldDescribe.getSoapType() != Schema.SoapType.Id) {
                    return parentRecord.get(fieldDescribe.getName());
                } else {
                    parentSObjectType = fieldDescribe.getReferenceTo().get(0);

                    SObject newParentRecord = parentRecord.getSObject(field);
                    if (newParentRecord == null) {
                        return null;
                    } else {
                        parentRecord = newParentRecord;
                    }
                }
            }

            return null;
        }

        private List<Schema.SObjectField> getFieldChain(Schema.SObjectType sobjectType, String fieldPath) {
            Schema.SObjectType currentSObjectType = sobjectType;

            List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
            List<String> fieldPathPieces = fieldPath.split('\\.');
            Integer lastFieldIndex = fieldPathPieces.size() <= 1 ? 0 : fieldPathPieces.size() - 1;

            for (Integer i = 0; i < fieldPathPieces.size(); i++) {
                String fieldPathPiece = fieldPathPieces[i];

                String fieldApiName;
                if (i == lastFieldIndex) {
                    fieldApiName = fieldPathPiece;
                } else if (fieldPathPiece.endsWith('__r')) {
                    fieldApiName = fieldPathPiece.replace('__r', '__c');
                } else {
                    fieldApiName = fieldPathPiece + 'Id';
                }

                Schema.SObjectField field = currentSObjectType.getDescribe().fields.getMap().get(fieldApiName);

                // TODO add support for polymorphic fields
                if (i < lastFieldIndex) {
                    currentSObjectType = field.getDescribe().getReferenceTo().get(0);
                }

                fields.add(field);
            }

            return fields;
        }

        private Schema.DescribeFieldResult getLastFieldDescribe() {
            Integer lastFieldIndex = this.fieldChain.size() - 1;
            return this.fieldChain[lastFieldIndex].getDescribe();
        }
    }
}
