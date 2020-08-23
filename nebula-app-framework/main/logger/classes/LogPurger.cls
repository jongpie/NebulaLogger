/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class LogPurger implements Database.Batchable<SObject>, Database.Stateful {

    private Integer daysToKeep;

    public LogPurger() {
        this(7);
    }

    public LogPurger(Integer daysToKeep) {
        this.daysToKeep = Math.abs(daysToKeep);
    }

    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        Date purgeDate = System.today() - daysToKeep;

        return Database.getQueryLocator([
            SELECT Id, (SELECT Id FROM LogEntries__r)
            FROM Log__c
            WHERE CreatedDate <= :purgeDate
        ]);
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> scope) {
        List<SObject> recordsToDelete = new List<SObject>();

        for(Log__c log : scope) {
            recordsToDelete.addAll(log.LogEntries__r);
            recordsToDelete.add(log);
        }

        delete recordsToDelete;
        Database.emptyRecycleBin(recordsToDelete);
    }

    public void finish(Database.BatchableContext batchableContext) { }

}