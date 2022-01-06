//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description The core class for logging
 * @see LogEntryEventBuilder
 * @see LogMessage
 */
/**
 * @group Log Management
 * @description Controller class for lwc `loggerInfo`, used to display system information about Nebula Logger
 */
public without sharing class LoggerInfoController {
    @AuraEnabled
    public static String getVersionNumber() {
        return Logger.getVersionNumber();
    }
    @AuraEnabled
    public static String getNamespacePrefix() {
        return Logger.getNamespacePrefix();
    }

    @AuraEnabled
    public static List<LoggerPlugin__mdt> getPlugins() {
        List<LoggerPlugin__mdt> plugins = LoggerPlugin__mdt.getAll().values();
        plugins.sort();
        return plugins;
    }
}
