Nebula Logger is available as both an unlocked package and a managed package. The metadata is the same in both packages, but there are some differences in the available functionality & features. All examples in the documentation are for the unlocked package (no namespace) - simply add the `Nebula` namespace to the examples if you are using the managed package.

<table>
    <thead>
        <tr>
            <th></th>
            <th>Unlocked Package (Recommended)</th>
            <th>Managed Package</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Namespace</td>
            <td>none</td>
            <td><code>Nebula</code></td>
        </tr>
        <tr>
            <td>Future Releases</td>
            <td>Faster release cycle: new patch versions are released (e.g., <code>v4.4.x</code>) for new enhancements & bugfixes that are merged to the <code>main</code> branch in GitHub</td>
            <td>Slower release cycle: the managed package only receives new minor versions (e.g., v4.x). It now follows Salesforce's release cycle - it will have 3 planned releases/year (Spring, Summer, and Winter releases). You can reference <a href="https://github.com/jongpie/NebulaLogger/milestones">the list of milestones</a> to see what's planned for each release.</td>
        </tr>
        <tr>
            <td>Public & Protected Apex Methods</td>
            <td>Any <code>public</code> and <code>protected</code> Apex methods are subject to change in the future - they can be used, but you may encounter deployment issues if future changes to <code>public</code> and <code>protected</code> methods are not backwards-compatible</td>
            <td>Only <code>global</code> methods are available in managed packages - any <code>global</code> Apex methods available in the managed package will be supported for the foreseeable future</td>
        </tr>
        <tr>
            <td>Apex Debug Statements</td>
            <td><code>System.debug()</code> is automatically called - the output can be configured with <code>LoggerSettings__c.SystemLogMessageFormat__c</code> to use any field on <code>LogEntryEvent__e</code></td>
            <td>Requires adding your own calls for <code>System.debug()</code> due to Salesforce limitations with managed packages</td>
        </tr>
        <tr>
            <td>Apex Stack Traces</td>
            <td>Automatically stored in <code>LogEntry__c.StackTrace__c</code> when calling methods like <code>Logger.debug('my message');</code></td>
            <td>Requires calling <code>parseStackTrace()</code> due to Salesforce limitations with managed packages. For example:<br><code>Logger.debug('my message').parseStackTrace(new DmlException().getStackTrace());</code></td>
        </tr>
        <tr>
            <td>Logger Plugin Framework</td>
            <td>Leverage Apex or Flow to build your own "plugins" for Logger - easily add your own automation to the any of the included objects: <code>LogEntryEvent__e</code>, <code>Log__c</code>, <code>LogEntry__c</code>, <code>LogEntryTag__c</code> and <code>LoggerTag__c</code>. The logger system will then automatically run your plugins for each trigger event (BEFORE_INSERT, BEFORE_UPDATE, AFTER_INSERT, AFTER_UPDATE, and so on).</td>
            <td>This functionality is not currently available in the managed package</td>
        </tr>
    </tbody>
</table>
