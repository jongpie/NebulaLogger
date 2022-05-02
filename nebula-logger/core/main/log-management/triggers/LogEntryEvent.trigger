//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
trigger LogEntryEvent on LogEntryEvent__e(after insert) {
    LoggerSObjectHandler.getHandler(Schema.LogEntryEvent__e.SObjectType, new LogEntryEventHandler()).execute();
}
