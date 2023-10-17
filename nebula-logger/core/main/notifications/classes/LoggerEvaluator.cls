/* TODO use a modified version of Apex Rollup's RollupEvaluator class for parsing SOQL WHERE clauses
*  https://github.com/jamessimone/apex-rollup/blob/v1.5.88/rollup/core/classes/RollupEvaluator.cls
*/
public without sharing class LoggerEvaluator {
    public LoggerEvaluator() {

    }

    public Boolean matches(String whereClause, SObject record) {
        return false;
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

    public Boolean isValid(String whereClause, Schema.SObjectType sobjectType) {
        return false;
    }

}
