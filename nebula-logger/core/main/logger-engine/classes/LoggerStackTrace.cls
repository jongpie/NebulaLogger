//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Class used for tracking & parsing stack traces
 * @see Logger
 * @see LogEntryBuilder
 */
public without sharing class LoggerStackTrace {
    private final static Set<String> IGNORED_APEX_CLASSES = new Set<String>{ LoggerStackTrace.class.getName() };
    private final static String NAMESPACE_PREFIX = getNamespacePrefix();
    private final static String NEW_LINE_DELIMITER = '\n';

    public String apexTopLevelClassName { get; private set; }
    public String apexInnerClassName { get; private set; }
    public Integer apexCodeLineNumber { get; private set; }
    public String apexMethodName { get; private set; }
    public String originLocation { get; private set; }
    public String parsedStackTraceString { get; private set; }

    private transient final String originalStackTraceString;

    public static void ignoreOrigin(System.Type apexType) {
        IGNORED_APEX_CLASSES.add(apexType.getName());
    }

    private static String getNamespacePrefix() {
        String className = LoggerStackTrace.class.getName();
        return className.contains('.') ? className.substringBefore('.') : '';
    }

    public LoggerStackTrace() {
        this(new System.DmlException());
    }

    public LoggerStackTrace(Exception apexException) {
        this(apexException?.getStackTraceString());
    }

    public LoggerStackTrace(String apexStackTraceString) {
        this.originalStackTraceString = apexStackTraceString;

        this.setApexClassDetails();
    }

    // public Integer getApexCodeLineNumber() {
    //     return this.apexCodeLineNumber;
    // }

    // public String getApexTopLevelClassName() {
    //     return this.apexTopLevelClassName;
    // }

    // public String getApexMethodName() {
    //     return this.apexMethodName;
    // }

    // public String getOriginLocation() {
    //     return this.originLocation;
    // }

    // public String getParsedStackTraceString() {
    //     return this.parsedStackTraceString;
    // }

    private void setApexClassDetails() {
        if (this.isValidStackTrace(this.originalStackTraceString) == false) {
            return;
        }

        // In a managed package, we can end up with an invalid (unhelpful) stack trace, so only store when valid
        List<String> cleansedStackTraceLines = this.getCleansedStackTraceLines(this.originalStackTraceString);
        this.parsedStackTraceString = String.join(cleansedStackTraceLines, NEW_LINE_DELIMITER);
        if (this.isValidStackTrace(this.parsedStackTraceString)) {
            String firstStackTraceLine = cleansedStackTraceLines.get(0);
            String cleanedOriginLocation = firstStackTraceLine;
            if (cleanedOriginLocation.contains(':')) {
                cleanedOriginLocation = cleanedOriginLocation.substringBefore(':');
            }
            if (cleanedOriginLocation.startsWith('Class.')) {
                cleanedOriginLocation = cleanedOriginLocation.substringAfter('Class.');
            }

            this.originLocation = cleanedOriginLocation;

            // Example: Class.ExampleClassWithLogging.throwSomeException: line 25, column 1
            this.apexCodeLineNumber = Integer.valueOf(firstStackTraceLine.substringAfter('line ').substringBefore(','));
            this.apexTopLevelClassName = firstStackTraceLine.substringAfter('Class.').substringBefore('.');
            this.apexInnerClassName = firstStackTraceLine.substringAfter('Class.' + apexTopLevelClassName + '.').substringBeforeLast('.');
            this.apexMethodName = firstStackTraceLine.substringAfter(apexTopLevelClassName + '.').substringBefore(':');

            // TODO
            // String topLevelApexTopLevelClassName = logEntry.OriginLocation__c?.substringBefore('.');
            // ApexClass topLevelApexClass = classNameToApexClass.get(topLevelApexTopLevelClassName);
            // if (topLevelApexClass == null) {
            //     return;
            // }

            // String methodName = logEntry.OriginLocation__c.substringAfterLast('.');
            // String innerApexTopLevelClassName = logEntry.OriginLocation__c.substringAfter(topLevelApexTopLevelClassName + '.').substringBeforeLast('.');
            // if (innerApexTopLevelClassName == topLevelApexTopLevelClassName || innerApexTopLevelClassName == methodName) {
            //     innerApexTopLevelClassName = null;
            // } else if (innerApexTopLevelClassName.startsWith(topLevelApexTopLevelClassName + '.')) {
            //     innerApexTopLevelClassName = innerApexTopLevelClassName.substringAfter(topLevelApexTopLevelClassName + '.');
            // }
        }
    }

    private Boolean isValidStackTrace(String stackTraceString) {
        if (String.isBlank(stackTraceString) == true || stackTraceString == '()' || stackTraceString == '(' + NAMESPACE_PREFIX + ')') {
            return false;
        }

        return true;
    }

    private List<String> getCleansedStackTraceLines(String stackTraceString) {
        List<String> stackTraceLines = new List<String>();
        String previousStackTraceLine;
        for (String currentStackTraceLine : stackTraceString.split(NEW_LINE_DELIMITER)) {
            // Duplicate lines are sometimes introduced, so skip the current line if it's the same as the previous line
            if (currentStackTraceLine == previousStackTraceLine) {
                continue;
            }

            // Don't include the logging system's classes in the stack trace
            Boolean ignoreLine = false;
            for (String ignoredApexClass : IGNORED_APEX_CLASSES) {
                if (currentStackTraceLine.contains('.' + ignoredApexClass.trim() + '.')) {
                    ignoreLine = true;
                    continue;
                }
            }
            // Some lines, especially in the managed package, can result in '()' or '(Nebula)'
            if (this.isValidStackTrace(currentStackTraceLine) == false) {
                ignoreLine = true;
            }

            if (ignoreLine == false) {
                previousStackTraceLine = currentStackTraceLine;
                stackTraceLines.add(currentStackTraceLine);
            }
        }

        return stackTraceLines;
    }
}
