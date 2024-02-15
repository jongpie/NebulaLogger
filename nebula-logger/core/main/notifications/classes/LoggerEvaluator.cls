/* TODO use a modified version of Apex Rollup's RollupEvaluator class for parsing SOQL WHERE clauses
 *  https://github.com/jamessimone/apex-rollup/blob/v1.5.88/rollup/core/classes/RollupEvaluator.cls
 */
public without sharing class LoggerEvaluator {
    public List<String> getFieldPaths(String whereClause) {
        return null;
    }

    public List<SObject> getMatches(String whereClause, List<SObject> records) {
        List<SObject> matchingRecords = new List<SObject>();
        for (SObject record : records) {
            if (this.matches(whereClause, record)) {
                matchingRecords.add(record);
            }
        }
        return matchingRecords;
    }

    public Boolean matches(String whereClause, SObject record) {
        return false;
    }

    public Boolean isValid(String whereClause, Schema.SObjectType sobjectType) {
        // TODO switch to validating in-memory with describe calls, instead of burning queries
        // Using queries works, but isn't scalable if there are hundreds of records
        Boolean isValid = false;
        try {
            Database.query('SELECT Id FROM ' + sobjectType + ' WHERE ' + whereClause + ' LIMIT 0');
            isValid = true;
        } catch (Exception ex) {
            isValid = false;
        }
        return isValid;
    }
}
