/**
 * @description An example trigger to demo logging Account records, using all trigger operations.
 * You should use a trigger handler framework, but this trigger is just for demo purposes
 */
public with sharing class Account_Batch_Logger_Example implements Database.Batchable<SObject>, Database.Stateful {
    private String originalTransactionId;

    /**
     * @description Required by the Database.Batchable interface, this method contains logic that
     * runs when the batch job is first initiated, before any individual jobs run.
     * @param batchableContext The initial context of the batch class before jobs run.
     * @return The database query locator instance, used by the batch interface to fetch lists of records.
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        // Each batchable method runs in a separate transaction,
        // so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        Logger.info('Starting Account_Batch_Logger_Example');
        Logger.saveLog();

        // Just as an example, query 100 accounts
        return System.Database.getQueryLocator([SELECT Id, Name, OwnerId, Owner.Name, Type FROM Account LIMIT 100]);
    }

    /**
     * @description Required by the batchable interface, this method contains the logic that is
     * executed with each job instance.
     * @param batchableContext The current batch job context.
     * @param scope The list of accounts for the particular batch job.
     */
    public void execute(Database.BatchableContext batchableContext, List<Schema.Account> scope) {
        // One-time call (per transaction) to set the parent log
        Logger.fine('this.originalTransactionId==' + this.originalTransactionId);
        Logger.setParentLogTransactionId(this.originalTransactionId);

        for (Schema.Account account : scope) {
            // TODO add your batch job's logic

            // Then log the result
            Logger.info('Processed an account record', account);
        }

        Logger.debug('Saving account records', scope);
        update scope;

        Logger.saveLog();
    }

    /**
     * @description This method is part of the batchable interface
     * and runs after all jobs have finished.
     * @param batchableContext The final context of this batch class after all batch
     * jobs have run.
     */
    public void finish(Database.BatchableContext batchableContext) {
        // The finish method runs in yet-another transaction, so set the parent log again
        Logger.fine('this.originalTransactionId==' + this.originalTransactionId);
        Logger.setParentLogTransactionId(this.originalTransactionId);

        Logger.info('Finishing running Account_Batch_Logger_Example');
        Logger.saveLog();
    }
}
