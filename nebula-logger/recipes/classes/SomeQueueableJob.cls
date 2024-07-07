public with sharing class SomeQueueableJob implements Queueable {
    private final String parentLogTransactionId = Logger.getTransactionId();

    public void execute(System.QueueableContext qc) {
        Logger.setAsyncContext(qc);
        Logger.setParentLogTransactionId(this.parentLogTransactionId);

        Logger.info('Executing some queueable job');
        Boolean someCondition = true;
        if (someCondition) {
            Logger.fine('Some condition is true, requeue the job');
            System.enqueueJob(this);
        }
        Logger.info('Finished some queueable job');
        Logger.saveLog();
    }
}
