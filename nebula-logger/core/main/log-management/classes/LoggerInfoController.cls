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
    /**
     * @description Returns the current version number of Nebula Logger
     * @return The current version number, in the format `v0.0.0`
     */
    @AuraEnabled(cacheable=true)
    public static String getVersionNumber() {
        return Logger.getVersionNumber();
    }

    /**
     * @description Returns the current namespace of Nebula Logger
     * @return   The current namespace prefix, or an empty string when no namespace is being used
     */
    @AuraEnabled(cacheable=true)
    public static String getNamespacePrefix() {
        return Logger.getNamespacePrefix();
    }

    /**
     * @description Returns the list of plugins installed/deployed to the org
     * @return   The list of configured plugins, based on the custom metadata type `LoggerPlugin__mdt`
     */
    @AuraEnabled
    public static List<LoggerPlugin__mdt> getPlugins() {
        List<LoggerPlugin__mdt> plugins = LoggerPlugin__mdt.getAll().values();
        plugins.sort();
        return plugins;
    }
}
