//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
trigger Log on Log__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    LoggerSObjectHandler.getHandler(Schema.Log__c.SObjectType, new LogHandler()).execute();
}
