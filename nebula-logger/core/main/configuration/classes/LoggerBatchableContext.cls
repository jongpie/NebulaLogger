//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used by the logging system for batch contextual details
 * @see LogBatchPurger
 * @see LoggerPlugin
 */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class LoggerBatchableContext {
    @AuraEnabled
    public Database.BatchableContext batchableContext;
    public transient Schema.SObjectType sobjectType;
    @AuraEnabled
    public String sobjectTypeName;

    /**
     * @description Constructor used to set the 2 properties
     * @param  batchableContext The instance of `Database.BatchableContextbatchableContext`, provided by the platform at run-time
     * @param  sobjectType      The `SObjectType` that will be queried & purged
     */
    public LoggerBatchableContext(Database.BatchableContext batchableContext, Schema.SObjectType sobjectType) {
        this.batchableContext = batchableContext;
        this.sobjectType = sobjectType;
        this.sobjectTypeName = sobjectType?.getDescribe().getName();
    }
}
