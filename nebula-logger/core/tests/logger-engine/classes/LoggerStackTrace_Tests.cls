@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest
private class LoggerStackTrace_Tests {
    private final static String APEX_SOURCE_TYPE_ANONYMOUS_BLOCK = 'ApexAnonymousBlock';
    private final static String APEX_SOURCE_TYPE_CLASS = 'ApexClass';
    private final static String APEX_SOURCE_TYPE_TRIGGER = 'ApexTrigger';

    @IsTest
    static void it_should_set_details_for_parameterless_constructor() {
        String topLevelClassName = LoggerStackTrace_Tests.class.getName();
        String methodName = 'it_should_set_details_for_parameterless_constructor';
        String expectedOriginLocation = topLevelClassName + '.' + methodName;
        Integer expectedSourceLineNumber = new System.DmlException().getLineNumber() + 2; // Expected value is the line number below where parameterlessStackTrace is initialized

        LoggerStackTrace parameterlessStackTrace = new LoggerStackTrace();

        System.Assert.areEqual(topLevelClassName, parameterlessStackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_CLASS, parameterlessStackTrace.originSourceType);
        System.Assert.isNull(parameterlessStackTrace.apexTriggerName);
        System.Assert.areEqual(topLevelClassName, parameterlessStackTrace.apexTopLevelClassName);
        System.Assert.isNull(parameterlessStackTrace.apexInnerClassName);
        System.Assert.areEqual(expectedSourceLineNumber, parameterlessStackTrace.apexCodeLineNumber);
        System.Assert.areEqual(methodName, parameterlessStackTrace.apexMethodName);
        System.Assert.areEqual(expectedOriginLocation, parameterlessStackTrace.originLocation);
        System.Assert.isTrue(parameterlessStackTrace.parsedStackTraceString.startsWith('Class.' + expectedOriginLocation));
    }

    @IsTest
    static void it_should_set_details_for_apex_exception_constructor() {
        System.Exception apexException = new System.DmlException('oops, some DML broke');
        LoggerStackTrace stringBasedStackTrace = new LoggerStackTrace(apexException.getStackTraceString());

        LoggerStackTrace exceptionBasedStackTrace = new LoggerStackTrace(apexException);

        System.Assert.areEqual(stringBasedStackTrace.apexTopLevelClassName, exceptionBasedStackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_CLASS, exceptionBasedStackTrace.originSourceType);
        System.Assert.isNull(exceptionBasedStackTrace.apexTriggerName);
        System.Assert.areEqual(stringBasedStackTrace.apexTopLevelClassName, exceptionBasedStackTrace.apexTopLevelClassName);
        System.Assert.areEqual(stringBasedStackTrace.apexInnerClassName, exceptionBasedStackTrace.apexInnerClassName);
        System.Assert.areEqual(stringBasedStackTrace.apexCodeLineNumber, exceptionBasedStackTrace.apexCodeLineNumber);
        System.Assert.areEqual(stringBasedStackTrace.apexMethodName, exceptionBasedStackTrace.apexMethodName);
        System.Assert.areEqual(stringBasedStackTrace.originLocation, exceptionBasedStackTrace.originLocation);
        System.Assert.areEqual(stringBasedStackTrace.parsedStackTraceString, exceptionBasedStackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_set_details_for_inner_class_constructor_trace_string() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LoggerStackTrace.class.getName().contains('.') == true) {
            return;
        }

        String topLevelClassName = LoggerStackTrace_Tests.class.getName();
        String innerClassName = DebugStringExample.class.getName().substringAfter(topLevelClassName + '.');
        String constructorMethodName = '<init>';
        String expectedOriginLocation = topLevelClassName + '.' + innerClassName + '.' + constructorMethodName;
        DebugStringExample constructedClass = new DebugStringExample();
        String expectedStackTrace = constructedClass.getStackTraceString();

        LoggerStackTrace stackTrace = new LoggerStackTrace(constructedClass.getStackTraceString());

        System.Assert.areEqual(topLevelClassName, stackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_CLASS, stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.areEqual(topLevelClassName, stackTrace.apexTopLevelClassName);
        System.Assert.areEqual(innerClassName, stackTrace.apexInnerClassName);
        // Just a null check for the code line number because it's difficult to try to determine the specific line number in a test
        System.Assert.isNotNull(stackTrace.apexCodeLineNumber);
        System.Assert.areEqual(constructorMethodName, stackTrace.apexMethodName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.originLocation);
        System.Assert.areEqual(expectedStackTrace, stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_set_details_for_inner_class_method_stack_trace_string() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LoggerStackTrace.class.getName().contains('.') == true) {
            return;
        }

        String topLevelClassName = LoggerStackTrace_Tests.class.getName();
        String methodName = 'it_should_set_details_for_inner_class_method_stack_trace_string';
        String expectedOriginLocation = topLevelClassName + '.' + methodName;
        System.DmlException stackTraceGenerator = new System.DmlException();
        String expectedStackTrace = stackTraceGenerator.getStackTraceString();

        LoggerStackTrace stackTrace = new LoggerStackTrace(stackTraceGenerator.getStackTraceString());

        System.Assert.areEqual(topLevelClassName, stackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_CLASS, stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.areEqual(topLevelClassName, stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        // Just a null check for the code line number because it's difficult to try to determine the specific line number in a test
        System.Assert.isNotNull(stackTrace.apexCodeLineNumber);
        System.Assert.areEqual(methodName, stackTrace.apexMethodName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.originLocation);
        System.Assert.areEqual(expectedStackTrace, stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_ignore_stack_trace_line_when_matching_class_type_has_been_ignored() {
        String ignoredTopLevelClassName = LoggerStackTrace_Tests.class.getName();
        String ignoredMethodName = 'it_should_ignore_stack_trace_line_when_matching_class_type_has_been_ignored';
        String ignoredStackTraceLine = 'Class.' + ignoredTopLevelClassName + '.' + ignoredMethodName + ': line 99999, column 1';
        String nonIgnoredTopLevelClassName = 'TheNextClassNameInTheStack';
        Integer nonIgnoredTopLevelClassLineNumber = 987;
        String nonIgnoredMethodName = 'doSomething';
        String expectedOriginLocation = nonIgnoredTopLevelClassName + '.' + nonIgnoredMethodName;
        String relevantStackTraceLines =
            'Class.' +
            expectedOriginLocation +
            ': line ' +
            nonIgnoredTopLevelClassLineNumber +
            ', column 1' +
            '\nAnonymousBlock: line 1, column 1';
        String mockStackTrace = ignoredStackTraceLine + '\n' + relevantStackTraceLines;

        LoggerStackTrace.ignoreOrigin(LoggerStackTrace_Tests.class);
        LoggerStackTrace stackTrace = new LoggerStackTrace(mockStackTrace);

        System.Assert.areEqual(nonIgnoredTopLevelClassName, stackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_CLASS, stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.areEqual(nonIgnoredTopLevelClassName, stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        System.Assert.areEqual(nonIgnoredTopLevelClassLineNumber, stackTrace.apexCodeLineNumber);
        System.Assert.areEqual(nonIgnoredMethodName, stackTrace.apexMethodName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.originLocation);
        System.Assert.areEqual(relevantStackTraceLines, stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_set_details_for_trigger_apex_stack_trace_string() {
        String expectedOriginLocation = 'SomeTrigger';
        String mockAnonymousApexStackTraceString = 'Trigger.SomeTrigger: line 9, column 1';

        LoggerStackTrace stackTrace = new LoggerStackTrace(mockAnonymousApexStackTraceString);

        System.Assert.areEqual(expectedOriginLocation, stackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_TRIGGER, stackTrace.originSourceType);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.apexTriggerName);
        System.Assert.isNull(stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        System.Assert.areEqual(9, stackTrace.apexCodeLineNumber);
        System.Assert.isNull(stackTrace.apexMethodName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.originLocation);
        System.Assert.areEqual(mockAnonymousApexStackTraceString, stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_set_details_for_anonymous_apex_stack_trace_string() {
        String expectedOriginLocation = 'AnonymousBlock';
        String mockAnonymousApexStackTraceString = 'AnonymousBlock: line 9, column 1';

        LoggerStackTrace stackTrace = new LoggerStackTrace(mockAnonymousApexStackTraceString);

        System.Assert.isNull(stackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_ANONYMOUS_BLOCK, stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.isNull(stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        System.Assert.areEqual(9, stackTrace.apexCodeLineNumber);
        System.Assert.isNull(stackTrace.apexMethodName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.originLocation);
        System.Assert.areEqual(mockAnonymousApexStackTraceString, stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_deduplicate_sequential_lines_in_stack_trace_string() {
        String deduplicatedStackTraceString = 'AnonymousBlock: line 9, column 1';
        String duplicatedStackTraceString = deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString;

        LoggerStackTrace stackTrace = new LoggerStackTrace(duplicatedStackTraceString);

        System.Assert.isNull(stackTrace.originSourceApiName);
        System.Assert.areEqual(APEX_SOURCE_TYPE_ANONYMOUS_BLOCK, stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.isNull(stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        System.Assert.areEqual(9, stackTrace.apexCodeLineNumber);
        System.Assert.isNull(stackTrace.apexMethodName);
        System.Assert.areEqual('AnonymousBlock', stackTrace.originLocation);
        System.Assert.areEqual(deduplicatedStackTraceString, stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_not_set_details_for_empty_parenthesis_trace_string() {
        final String emptyParenthesisStackTrace = '()';

        LoggerStackTrace stackTrace = new LoggerStackTrace(emptyParenthesisStackTrace);

        System.Assert.isNull(stackTrace.originSourceApiName);
        System.Assert.isNull(stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.isNull(stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        System.Assert.isNull(stackTrace.apexCodeLineNumber);
        System.Assert.isNull(stackTrace.apexMethodName);
        System.Assert.isNull(stackTrace.originLocation);
        System.Assert.isNull(stackTrace.parsedStackTraceString);
    }

    @IsTest
    static void it_should_not_set_details_for_namespaced_parenthesis_stack_trace_string() {
        final String namespacedPparenthesisStackTrace = '(Some_Namespace)';

        LoggerStackTrace stackTrace = new LoggerStackTrace(namespacedPparenthesisStackTrace);

        System.Assert.isNull(stackTrace.originSourceApiName);
        System.Assert.isNull(stackTrace.originSourceType);
        System.Assert.isNull(stackTrace.apexTriggerName);
        System.Assert.isNull(stackTrace.apexTopLevelClassName);
        System.Assert.isNull(stackTrace.apexInnerClassName);
        System.Assert.isNull(stackTrace.apexCodeLineNumber);
        System.Assert.isNull(stackTrace.apexMethodName);
        System.Assert.isNull(stackTrace.originLocation);
        System.Assert.isNull(stackTrace.parsedStackTraceString);
    }

    private class DebugStringExample {
        public final String loggingString = 'Inside DebugStringExample.myMethod!';
        private System.Exception stackTraceGenerator;

        public DebugStringExample() {
            this.stackTraceGenerator = new System.DmlException();
        }

        public String getStackTraceString() {
            return this.stackTraceGenerator.getStackTraceString();
        }

        public Integer myMethod(Integer firstValue, Integer secondValue) {
            return firstValue + secondValue;
        }
    }
}
