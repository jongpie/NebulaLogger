public with sharing class LogEntryDataMaskManager {
    private static final Map<String, LogEntryDataMaskRule__mdt> CACHED_DATA_MASK_RULES {
        get {
            if (CACHED_DATA_MASK_RULES == null) {
                CACHED_DATA_MASK_RULES = loadDataMaskRules();
            }
            return CACHED_DATA_MASK_RULES;
        }
        set;
    }

    public SObject applyRules(SObject record) {
        String recordJson = JSON.serialize(record);
        recordJson = this.applyRules(recordJson);
        SObject maskedRecord = (SObject) JSON.deserializeStrict(recordJson, SObject.class);
        return maskedRecord;
    }

    public List<SObject> applyRules(List<SObject> records) {
        String recordsJson = JSON.serialize(records);
        recordsJson = this.applyRules(recordsJson);
        List<SObject> maskedRecords = (List<SObject>) JSON.deserialize(recordsJson, List<SObject>.class);
        return maskedRecords;
    }

    public Map<Id, SObject> applyRules(Map<Id, SObject> recordIdToRecord) {
        String recordIdToRecordJson = JSON.serialize(recordIdToRecord);
        recordIdToRecordJson = this.applyRules(recordIdToRecordJson);
        Map<Id, SObject> maskedRecords = (Map<Id, SObject>) JSON.deserialize(recordIdToRecordJson, Map<Id, SObject>.class);
        return maskedRecords;
    }

    public String applyRules(String unmaskedString) {
        if (String.isBlank(unmaskedString) == true) {
            return unmaskedString;
        }

        String maskedString = unmaskedString;
        for (LogEntryDataMaskRule__mdt dataMaskRule : CACHED_DATA_MASK_RULES.values()) {
            if (dataMaskRule.IsEnabled__c == true) {
                maskedString = maskedString.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);
            }
        }
        return maskedString;
    }

    @TestVisible
    private static void setMock(LogEntryDataMaskRule__mdt dataMaskRule) {
        CACHED_DATA_MASK_RULES.put(dataMaskRule.DeveloperName, dataMaskRule);
    }

    // public String applyRules(String unmaskedString) {
    //     return 'TODO';
    // }

    private static Map<String, LogEntryDataMaskRule__mdt> loadDataMaskRules() {
        Map<String, LogEntryDataMaskRule__mdt> activeDataMaskRules = new Map<String, LogEntryDataMaskRule__mdt>();
        for (LogEntryDataMaskRule__mdt dataMaskRule : LogEntryDataMaskRule__mdt.getAll().values()) {
            if (dataMaskRule.IsEnabled__c == true) {
                activeDataMaskRules.put(dataMaskRule.DeveloperName, dataMaskRule);
            }
        }
        if (System.Test.isRunningTest() == true) {
            // Tests shouldn't rely on the actual CMDT rules in the org
            // Clear the org's loaded records during tests, and mock via setMockDataMaskRule()
            activeDataMaskRules.clear();
        }
        return activeDataMaskRules;
    }
}
