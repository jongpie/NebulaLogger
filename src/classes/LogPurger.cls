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
            SELECT Id, Name, CreatedDate, CreatedBy.Name
            FROM Log__c
            WHERE CreatedDate <= :purgeDate
            ORDER By CreatedDate
        ]);
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> scope) {
        delete scope;
        Database.emptyRecycleBin(scope);
    }

    public void finish(Database.BatchableContext batchableContext) { }

}