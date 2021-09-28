//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Provides a centralized way to load & update the custom hierarchy setting `LoggerSettings__c`
 */
public with sharing class LoggerSettings {
    private static LoggerSettings__c userSettings;

    private static LoggingLevel userLoggingLevel {
        get {
            if (userLoggingLevel == null || userLoggingLevel.name() != getUserSettings().LoggingLevel__c) {
                userLoggingLevel = getLoggingLevel(getUserSettings().LoggingLevel__c);
            }
            return userLoggingLevel;
        }
        set;
    }

    /**
     * @description Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isEnabled() {
        return getUserSettings().IsEnabled__c;
    }

    /**
     * @description Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param  loggingLevel - The logging level to check
     * @return Boolean
     */
    public static Boolean isEnabled(LoggingLevel loggingLevel) {
        return isEnabled() && meetsUserLoggingLevel(loggingLevel);
    }

    /**
     * @description Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isErrorEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.ERROR);
    }

    /**
     * @description Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isWarnEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.WARN);
    }

    /**
     * @description Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isInfoEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.INFO);
    }

    /**
     * @description Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isDebugEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.DEBUG);
    }

    /**
     * @description Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isFineEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINE);
    }

    /**
     * @description Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isFinerEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINER);
    }

    /**
     * @description Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean isFinestEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINEST);
    }

    /**
     * @description Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    public static Boolean meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel) {
        return userLoggingLevel.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    /**
     * @description Returns the logging level for the current user, based on the custom setting LoggerSettings__c
     * @return LoggingLevel - The matching instance of LoggingLevel
     */
    public static LoggingLevel getUserLoggingLevel() {
        return userLoggingLevel;
    }

    // TODO: remove once Winter '22 release has the new Enum.valueOf(String) feature
    private static LoggingLevel getLoggingLevel(String loggingLevelName) {
        if (loggingLevelName != null) {
            loggingLevelName = loggingLevelName.trim().toUpperCase();
        }

        switch on loggingLevelName {
            when 'NONE' {
                return LoggingLevel.NONE;
            }
            when 'ERROR' {
                return LoggingLevel.ERROR;
            }
            when 'WARN' {
                return LoggingLevel.WARN;
            }
            when 'INFO' {
                return LoggingLevel.INFO;
            }
            when 'DEBUG' {
                return LoggingLevel.DEBUG;
            }
            when 'FINE' {
                return LoggingLevel.FINE;
            }
            when 'FINER' {
                return LoggingLevel.FINER;
            }
            when 'FINEST' {
                return LoggingLevel.FINEST;
            }
            when else {
                return null;
            }
        }
    }

    /**
     * @description Returns the current user's instance of `LoggerSettings__c`
     * @return LoggerSettings__c - The current user's instance of the custom settings
     */
    // TODO make this method `public` in a future release
    public static LoggerSettings__c getUserSettings() {
        // Only load the current user's settings once - this allows the instance to be modified in memory (as well as upserted if any changes should be persisted)
        if (userSettings == null) {
            User currentUser = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
            userSettings = getUserSettings(currentUser);
        }
        return userSettings;
    }

    /**
     * @description Returns the specified user's instance of `LoggerSettings__c`
     * @param  user The user record - at a minimum, this record should have the user Id and Profile fields populated
     * @return      LoggerSettings__c - The specified user's instance of the custom settings
     */
    // TODO make this method `public` in a future release
    public static LoggerSettings__c getUserSettings(User loggingUser) {
        // Typically, using LoggerSettings__c.getInstance() would be easier
        // However, some settings fields are expected to have null values, which conflicts with how `getInstance()` behaves
        // So, instead use LoggerSettings__c.getValues(Id userOrProfileId) to load exactly what's been configured (including nulls)

        LoggerSettings__c loggingUserSettings;
        if (loggingUser.Id != null && LoggerSettings__c.getValues(loggingUser.Id) != null) {
            // Check for User-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.Id);
        } else if (loggingUserSettings == null && loggingUser.ProfileId != null && LoggerSettings__c.getValues(loggingUser.ProfileId) != null) {
            // Next, check for Profile-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.ProfileId);
        } else if (LoggerSettings__c.getOrgDefaults().Id != null) {
            // Next, use the org defaults (if configured)
            loggingUserSettings = LoggerSettings__c.getOrgDefaults();
        } else {
            loggingUserSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
        }

        // If the settings were loaded from the org or profile level, clear the ID and make the user the SetupOwnerId (since the method is getUserSettings)
        // This allows the ability to then upsert the instance of LoggerSettings__c and it will always be specific to that user...
        // which avoids accidentally changing something at the org or profile levels
        if (loggingUser.Id != null && loggingUserSettings.SetupOwnerId != loggingUser.Id) {
            loggingUserSettings.Id = null;
            loggingUserSettings.SetupOwnerId = loggingUser.Id;
        }

        return loggingUserSettings;
    }
}
