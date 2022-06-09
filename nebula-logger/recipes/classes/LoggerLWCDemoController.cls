@SuppressWarnings('PMD.ApexDoc')
public with sharing class LoggerLWCDemoController {
    @AuraEnabled
    public static void throwSomeError() {
        throw new DmlException('Some Error!!');
    }
}
