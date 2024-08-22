@SuppressWarnings('PMD.ApexDoc')
public with sharing class LoggerLWCDemoController {
  @AuraEnabled(cacheable=true)
  public static String returnSomeString() {
    return 'SomeString';
  }

  @AuraEnabled
  public static void throwSomeError() {
    throw new System.DmlException('Some Error!!');
  }
}
