The hierarchy custom settings object `LoggerSettings__c` is used to control the behavior of several aspects of the logging system. It can be configured at the org, profile, and/or user levels, referred to as the "Setup Owner".

![Logger Settings](./images/logger-settings.png)

<table>
    <thead>
        <tr>
            <td>Setting Field Name</td>
            <td>Default Value</td>
            <td>Description</td>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>IsEnabled__c</td>
            <td>true</td>
            <td>Determines if Logger runs for the specified Setup Owner</td>
        </tr>
        <tr>
            <td>LoggingLevel__c</td>
            <td>DEBUG</td>
            <td>
                The name of the <a href="https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_system.htm#system_logging_level_enum" target="_blank">Logging Level enum value</a> to use for the specified Setup Owner. Only log entries that meet the specified logging level will be logged for the Setup Owner - for example, when 'INFO' is used for a particular user, only log entries with logging level 'ERROR', 'WARN' or 'INFO' will be logged. Possible values:
                <ul>
                    <li>ERROR</li>
                    <li>WARN</li>
                    <li>INFO</li>
                    <li>DEBUG</li>
                    <li>FINE</li>
                    <li>FINER</li>
                    <li>FINEST</li>
                </ul>
            </td>
        </tr>
        <tr>
            <td>DefaultSaveMethod__c</td>
            <td>EVENT_BUS</td>
            <td>This controls the default save method used by Logger when calling saveLog(). Possible values come from the enum <code>Logger.SaveMethod</code>:
                <ul>
                    <li>EVENT_BUS - The default save method, this uses the `EventBus` class to publish `LogEntryEvent__e` records. The default save method can also be controlled declaratively by updating the field `LoggerSettings__c.DefaultSaveMethod__c`</li>
                    <li>QUEUEABLE - This save method will trigger `Logger` to save any pending records asynchronously using a queueable job. This is useful when you need to defer some CPU usage and other limits consumed by Logger.</li>
                    <li>REST - This save method will use the current user’s session ID to make a synchronous callout to the org’s REST API. This is useful when you have other callouts being made and you need to avoid mixed DML operations.</li>
                    <li>SYNCHRONOUS_DML - This save method will skip publishing the `LogEntryEvent__e` platform events, and instead immediately creates `Log__c` and `LogEntry__c` records. This is useful when you are logging from within the context of another platform event and/or you do not anticipate any exceptions to occur in the current transaction. **Note**: when using this save method, any exceptions will prevent your log entries from being saved - Salesforce will rollback any DML statements, including your log entries! Use this save method cautiously.</li>
                </ul>
            </td>
        </tr>
        <tr>
            <td>ApplyDataMaskRules__c</td>
            <td>true</td>
            <td>When enabled, any [configured data mask rules](./Configuring-Data-Mask-Rules) will run for the specified Setup Owner</td>
        </tr>
        <tr>
            <td>StripInaccessibleRecordFields__c</td>
            <td>false</td>
            <td>Disabled by default, when enabled, any time an `SObject` record is logged (or a `List<SObject>` is logged), only fields that the specified Setup Owner can access will be included in the record's JSON. This is useful in orgs where end-users have access to view `Log__c` and `LogEntry__c` records.</td>
        </tr>
        <tr>
            <td>AnonymousMode__c</td>
            <td>false</td>
            <td>
                When enabled, logs for the specified Setup Owner are stored anonymously - data stored in the custom objects Log__c and LogEntry__c will not contain any user-identifying info. The audit fields CreatedById and LastModifiedById will (continue to) be the 'Automated Process' system-user. Notes:
                <ul>
                    <li>Anonymous Mode is intended to work when using the save method EVENT_BUS - for any other save method, the (QUEUEABLE, REST and SYNCHRONOUS_DML), the Log__c and LogEntry__c audit fields (CreaetdById, LastModifiedById, etc.) will show as the current user.</li>
                    <li>The platform event records in LogEntryEvent__e cannot be made fully anonymous - Salesforce automatically sets the field LogEntryEvent__e.CreatedById to the current user. All other user-related fields on LogEntryEvent__e will be set to null (just like on Log__c and LogEntry__c).</li>
                </ul>
            </td>
        </tr>
        <tr>
            <td>SystemLogMessageFormat__c</td>
            <td>{OriginType__c}\n{Message__c}</td>
            <td>
                Logger automatically calls <code>System.debug()</code> - the output can be configured using Handlebars-esque syntax to refer to fields on the `LogEntryEvent__e` Platform Event. You can use curly braces to denote merge field logic, eg: `{OriginLocation__c}\n{Message__c}` - this will output the contents of `LogEntryEvent__e.OriginLocation__c`, a line break, and then the contents of `LogEntryEvent__e.Message__c`
            </td>
        </tr>
        <tr>
            <td>DefaultLogShareAccessLevel__c</td>
            <td>Read</td>
            <td>
                Uses Apex managed sharing to grants users read or edit access to their log records (on insert only). When no access level is specified, no Apex sharing logic is executed. This only gives record-level access - users will still need to be granted access to the Log__c object using permission sets or profiles. Possible Values:
                <ul>
                    <li>blank (null)</li>
                    <li>Read</li>
                    <li>Edit</li>
                </ul>
            </td>
        </tr>
        <tr>
            <td>DefaultNumberOfDaysToRetainLogs__c</td>
            <td>14</td>
            <td>
                This value is used to set the field Log__c.LogRetentionDate__c,  which is then used by the LogBatchPurger batch job to delete old logs. To keep logs indefinitely for the specified Setup Owner, set this field to blank (null).
            </td>
        </tr>
        <tr>
            <td>EnableSystemMessages__c</td>
            <td>14</td>
            <td>
                When enabled, log entries may be generated that contain additional details about the logging system. For example, when the batch job LogBatchPurger runs and EnableSystemMessages__c == true, it will create additional log entries with information about how many records are being deleted.
            </td>
        </tr>
    </tbody>
</table>
