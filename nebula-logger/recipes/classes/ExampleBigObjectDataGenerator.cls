@SuppressWarnings('PMD.ApexDoc')
public with sharing class ExampleBigObjectDataGenerator implements System.Queueable {
  private Integer targetRecordCountToCreate;

  public ExampleBigObjectDataGenerator(Integer targetRecordCountToCreate) {
    this.targetRecordCountToCreate = targetRecordCountToCreate;
  }

  public void execute(System.QueueableContext queueableContext) {
    // Integer target = targetRecordCountToCreate <= 200 ? 200 : targetRecordCountToCreate;
    for (Integer i = 0; i < 150; i++) {
      Logger.info('hello, testing some bulk logging into big object via queueable job, record index is: ' + i);
      this.targetRecordCountToCreate--;
    }
    Logger.getUserSettings().DefaultSaveMethod__c = 'BIG_OBJECT_IMMEDIATE';
    Logger.saveLog();

    if (this.targetRecordCountToCreate > 0) {
      System.enqueueJob(new ExampleBigObjectDataGenerator(this.targetRecordCountToCreate));
    }
  }
}
