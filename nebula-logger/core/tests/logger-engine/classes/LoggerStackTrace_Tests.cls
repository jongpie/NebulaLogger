@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest
private class LoggerStackTrace_Tests {
    private static final String MOCK_LOGGER_COMPONENT_NAME = 'c/loggerProbablyMaybe';

    @IsTest
    static void it_should_gracefully_handle_parsing_null_stack_trace_string() {
        String nullStackTraceString = null;

        LoggerStackTrace parameterlessStackTrace = new LoggerStackTrace(nullStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, parameterlessStackTrace.Language);
        System.Assert.isNull(parameterlessStackTrace.Location);
        System.Assert.isNull(parameterlessStackTrace.ParsedStackTraceString);
        System.Assert.isNull(parameterlessStackTrace.Source);
    }

    @IsTest
    static void it_should_set_details_for_parameterless_constructor_for_top_level_class() {
        String topLevelClassName = LoggerStackTrace_Tests.class.getName();
        String methodName = 'it_should_set_details_for_parameterless_constructor_for_top_level_class';
        String expectedOriginLocation = topLevelClassName + '.' + methodName;
        Integer expectedSourceLineNumber = new System.DmlException().getLineNumber() + 2; // Expected value is the line number below where parameterlessStackTrace is initialized

        LoggerStackTrace parameterlessStackTrace = new LoggerStackTrace();

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, parameterlessStackTrace.Language);
        System.Assert.areEqual(topLevelClassName, parameterlessStackTrace.Source.ApiName);
        System.Assert.areEqual(methodName, parameterlessStackTrace.Source.ActionName);
        System.Assert.areEqual(expectedSourceLineNumber, parameterlessStackTrace.Source.LineNumber);
        System.Assert.areEqual(expectedOriginLocation, parameterlessStackTrace.Location);
        System.Assert.isTrue(parameterlessStackTrace.ParsedStackTraceString.startsWith('Class.' + expectedOriginLocation));
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass, parameterlessStackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_set_details_for_parameterless_constructor_for_inner_class() {
        String topLevelClassName = LoggerStackTrace_Tests.class.getName();
        String unqualifiedInnerClassName = DebugStringExample.class.getName().substringAfter(topLevelClassName + '.');
        String methodName = 'getStackTrace';
        String expectedOriginLocation = topLevelClassName + '.' + unqualifiedInnerClassName + '.' + methodName;

        LoggerStackTrace parameterlessStackTrace = new DebugStringExample().getStackTrace();

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, parameterlessStackTrace.Language);
        System.Assert.areEqual(topLevelClassName, parameterlessStackTrace.Source.ApiName);
        System.Assert.areEqual(unqualifiedInnerClassName + '.' + methodName, parameterlessStackTrace.Source.ActionName);
        // TODO need to revisit to see if there's a easy-to-maintain way to know the expected line number
        // System.Assert.areEqual(expectedSourceLineNumber, parameterlessStackTrace.Source.LineNumber);
        System.Assert.areEqual(expectedOriginLocation, parameterlessStackTrace.Location);
        System.Assert.isTrue(parameterlessStackTrace.ParsedStackTraceString.startsWith('Class.' + expectedOriginLocation));
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass, parameterlessStackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_set_details_for_apex_exception_constructor() {
        System.Exception apexException = new System.DmlException('oops, some DML broke');
        LoggerStackTrace stringBasedStackTrace = new LoggerStackTrace(apexException.getStackTraceString());

        LoggerStackTrace exceptionBasedStackTrace = new LoggerStackTrace(apexException);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, exceptionBasedStackTrace.Language);
        System.Assert.areEqual(stringBasedStackTrace.Source.ApiName, exceptionBasedStackTrace.Source.ApiName);
        System.Assert.areEqual(stringBasedStackTrace.Location, exceptionBasedStackTrace.Location);
        System.Assert.areEqual(stringBasedStackTrace.ParsedStackTraceString, exceptionBasedStackTrace.ParsedStackTraceString);
        System.Assert.areEqual(stringBasedStackTrace.Source.ApiName, exceptionBasedStackTrace.Source.ApiName);
        System.Assert.areEqual(stringBasedStackTrace.Source.ActionName, exceptionBasedStackTrace.Source.ActionName);
        System.Assert.areEqual(stringBasedStackTrace.Source.LineNumber, exceptionBasedStackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass, exceptionBasedStackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_set_details_for_apex_inner_class_constructor_trace_string() {
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
        String expectedStackTraceString = constructedClass.getConstructorStackTraceString();

        LoggerStackTrace stackTrace = new LoggerStackTrace(constructedClass.getConstructorStackTraceString());

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.areEqual(topLevelClassName, stackTrace.Source.ApiName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.Location);
        System.Assert.areEqual(expectedStackTraceString, stackTrace.ParsedStackTraceString);
        System.Assert.areEqual(topLevelClassName, stackTrace.Source.ApiName);
        System.Assert.areEqual(innerClassName + '.' + constructorMethodName, stackTrace.Source.ActionName);
        // Just a null check for the code line number because it's difficult to try to determine the specific line number in a test
        System.Assert.isNotNull(stackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass, stackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_set_details_for_apex_inner_class_method_stack_trace_string() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LoggerStackTrace.class.getName().contains('.') == true) {
            return;
        }

        String topLevelClassName = LoggerStackTrace_Tests.class.getName();
        String innerClassName = DebugStringExample.class.getName().substringAfter(topLevelClassName + '.');
        String constructorMethodName = 'getMethodStackTraceString';
        String expectedOriginLocation = topLevelClassName + '.' + innerClassName + '.' + constructorMethodName;
        DebugStringExample constructedClass = new DebugStringExample();
        String expectedStackTraceString = constructedClass.getMethodStackTraceString();

        LoggerStackTrace stackTrace = new LoggerStackTrace(constructedClass.getMethodStackTraceString());

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.areEqual(topLevelClassName, stackTrace.Source.ApiName);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.Location);
        System.Assert.areEqual(expectedStackTraceString, stackTrace.ParsedStackTraceString);
        System.Assert.areEqual(topLevelClassName, stackTrace.Source.ApiName);
        System.Assert.areEqual(innerClassName + '.' + constructorMethodName, stackTrace.Source.ActionName);
        // Just a null check for the code line number because it's difficult to try to determine the specific line number in a test
        System.Assert.isNotNull(stackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass, stackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_ignore_stack_trace_line_when_matching_apex_class_type_has_been_ignored() {
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

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.Location);
        System.Assert.areEqual(relevantStackTraceLines, stackTrace.ParsedStackTraceString);
        System.Assert.areEqual(nonIgnoredTopLevelClassName, stackTrace.Source.ApiName);
        System.Assert.areEqual(nonIgnoredMethodName, stackTrace.Source.ActionName);
        System.Assert.areEqual(nonIgnoredTopLevelClassLineNumber, stackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass, stackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_set_details_for_trigger_apex_stack_trace_string() {
        String expectedOriginLocation = 'SomeTrigger';
        String mockAnonymousApexStackTraceString = 'Trigger.SomeTrigger: line 9, column 1';

        LoggerStackTrace stackTrace = new LoggerStackTrace(mockAnonymousApexStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.Location);
        System.Assert.areEqual(mockAnonymousApexStackTraceString, stackTrace.ParsedStackTraceString);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.Source.ApiName);
        System.Assert.isNull(stackTrace.Source.ActionName);
        System.Assert.areEqual(9, stackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexTrigger, stackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_set_details_for_anonymous_apex_stack_trace_string() {
        String expectedOriginLocation = 'AnonymousBlock';
        String mockAnonymousApexStackTraceString = 'AnonymousBlock: line 9, column 1';

        LoggerStackTrace stackTrace = new LoggerStackTrace(mockAnonymousApexStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.areEqual(expectedOriginLocation, stackTrace.Location);
        System.Assert.areEqual(mockAnonymousApexStackTraceString, stackTrace.ParsedStackTraceString);
        System.Assert.isNull(stackTrace.Source.ApiName);
        System.Assert.isNull(stackTrace.Source.ActionName);
        System.Assert.areEqual(9, stackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.AnonymousBlock, stackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_deduplicate_sequential_lines_in_apex_stack_trace_string() {
        String deduplicatedStackTraceString = 'AnonymousBlock: line 9, column 1';
        String duplicatedStackTraceString = deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString;

        LoggerStackTrace stackTrace = new LoggerStackTrace(duplicatedStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.areEqual('AnonymousBlock', stackTrace.Location);
        System.Assert.areEqual(deduplicatedStackTraceString, stackTrace.ParsedStackTraceString);
        System.Assert.isNull(stackTrace.Source.ApiName);
        System.Assert.isNull(stackTrace.Source.ActionName);
        System.Assert.areEqual(9, stackTrace.Source.LineNumber);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.AnonymousBlock, stackTrace.Source.MetadataType);
    }

    @IsTest
    static void it_should_not_set_details_for_empty_parenthesis_trace_string() {
        String emptyParenthesisStackTrace = '()';

        LoggerStackTrace stackTrace = new LoggerStackTrace(emptyParenthesisStackTrace);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.isNull(stackTrace.Location);
        System.Assert.isNull(stackTrace.ParsedStackTraceString);
        System.Assert.isNull(stackTrace.Source);
    }

    @IsTest
    static void it_should_not_set_details_for_namespaced_parenthesis_stack_trace_string() {
        String namespacedPparenthesisStackTrace = '(Some_Namespace)';

        LoggerStackTrace stackTrace = new LoggerStackTrace(namespacedPparenthesisStackTrace);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.Apex, stackTrace.Language);
        System.Assert.isNull(stackTrace.Location);
        System.Assert.isNull(stackTrace.ParsedStackTraceString);
        System.Assert.isNull(stackTrace.Source);
    }

    @IsTest
    static void it_should_parse_javascript_aura_component_stack_trace_string() {
        LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
        String expectedComponentApiName = 'c/loggerAuraDemo';
        String expectedComponentFunctionName = 'saveLogAuraExample';
        Integer expectedLineNumber = 123;
        String auraStackTraceString = getMockAuraComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

        LoggerStackTrace auraStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, auraStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, auraStackTrace.Language);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, auraStackTrace.Location);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle, auraStackTrace.Source.MetadataType);
        System.Assert.areEqual(expectedComponentApiName, auraStackTrace.Source.ApiName);
        System.Assert.areEqual(expectedComponentFunctionName, auraStackTrace.Source.ActionName);
        System.Assert.areEqual(expectedLineNumber, auraStackTrace.Source.LineNumber);
    }

    @IsTest
    static void it_should_parse_javascript_web_component_legacy_stack_trace_string() {
        LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
        String expectedComponentApiName = 'c/loggerWebDemo';
        String expectedComponentFunctionName = 'saveLogWebExample';
        Integer expectedLineNumber = 123;
        String modernLwcStackTraceString = getMockLegacyWebComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

        LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
        System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
        System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
        System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    }

    @IsTest
    static void it_should_parse_javascript_web_component_modern_stack_trace_string() {
        LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
        String expectedComponentApiName = 'c/loggerWebDemo';
        String expectedComponentFunctionName = 'saveLogWebExample';
        Integer expectedLineNumber = 123;
        String modernLwcStackTraceString = getMockModernWebComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

        LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
        System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
        System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
        System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    }

    @IsTest
    static void it_should_parse_javascript_web_component_modern_stack_trace_string_for_connected_callback() {
        LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
        String expectedComponentApiName = 'c/loggerWebDemo';
        String connectedCallbackFunctionName = 'connectedCallback/<';
        String expectedComponentFunctionName = 'connectedCallback';
        Integer expectedLineNumber = 123;
        String modernLwcStackTraceString = getMockModernWebComponentStackTrace(expectedComponentApiName, connectedCallbackFunctionName, expectedLineNumber);

        LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

        System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
        System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
        System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
        System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    }

    private static String getMockAuraComponentStackTrace(String originComponentName, String originFunctionName, Integer expectedLineNumber) {
        // This is a modified partial-copy of an actual stack trace generated from c/loggerAuraDemo in August 2021
        List<String> auraStackTraceLines = new List<String>{
            'LogEntryBuilder@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:28:24' +
            'newLogEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:172:14',
            '_newEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:349:44',
            'info@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:253:21',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'createMethodCaller/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:7822:18',
            'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:45047:24',
            'createFilteredMethod/<.value<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:30260:46',
            originFunctionName +
            '@https://flow-ability-5496.lightning.force.com/lightning/n/components/' +
            originComponentName +
            '.js:' +
            expectedLineNumber +
            ':30',
            'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47648:36',
            'Action.prototype.$run$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47635:8',
            'handleClick@https://flow-ability-5496.lightning.force.com/components/lightning/button.js:23:20',
            'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47648:36',
            '$dispatchAction$/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44173:12',
            'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59193:12',
            '$dispatchAction$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44172:6',
            'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:61246:23',
            'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:39996:20',
            'bound@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:39933:29',
            '$domEventHandler$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44168:12',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59040:23',
            'wrapperFn@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:505:29',
            'EventListener.handleEvent*patchedAddEventListener$1@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:3249:31',
            'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:38804:17',
            '$addNamedClickHandler$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44144:14',
            '$createHtmlAttribute$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44187:12',
            'render@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44056:14',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42890:26',
            'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54033:34',
            'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54337:29',
            'render@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43718:45',
            '\nloggerAuraDemo.js:17:17'
        };
        return String.join(auraStackTraceLines, '\n');
    }

    private static String getMockLegacyWebComponentStackTrace(String originComponentName, String originFunctionName, Integer expectedLineNumber) {
        // This is a modified partial-copy of an actual stack trace generated from c/loggerLWCDemo in August 2021
        List<String> lwcStackTraceLines = new List<String>{
            'LogEntryBuilder@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:28:24',
            'newLogEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:172:14',
            '_newEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:349:44',
            'error@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:233:21',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'createMethodCaller/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:7822:18',
            'createFilteredMethodStateless/<.value<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:30288:47',
            originFunctionName +
            '@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            originComponentName +
            '.js:' +
            expectedLineNumber +
            ':30',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'invokeEventListener/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:9992:19',
            'runWithBoundaryProtection@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:10696:7',
            'invokeEventListener@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:9987:32',
            'b/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:9352:30',
            'customElementWrappedListener@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:575:28',
            'invokeListenersByPlacement/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:617:32',
            'invokeListenersByPlacement@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:612:19',
            'domListener@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:627:37'
        };
        return String.join(lwcStackTraceLines, '\n');
    }

    private static String getMockModernWebComponentStackTrace(String originComponentName, String originFunctionName, Integer expectedLineNumber) {
        // This is a modified partial-copy of an actual stack trace generated from c/loggerLWCDemo in January 2024
        List<String> lwcStackTraceLines = new List<String>{
            '@modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:33:22',
            'LogEntryBuilder@modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:59:87',
            'newLogEntry@modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:189:14',
            '_newEntry@modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:397:44',
            'error@modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:264:21',
            originFunctionName +
            '@modules/' +
            originComponentName +
            '.js:' +
            expectedLineNumber +
            ':35',
            'createHooksCallback$LWS/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js line 35465 > eval:2583:24',
            'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:32254:38',
            'callHook@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:10035:19',
            'invokeEventListener/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:9926:21',
            'runWithBoundaryProtection@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:10517:13',
            'invokeEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:9921:34',
            'b/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:9365:32',
            'handleEvent@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1615:51',
            'invokeListenersByPlacement/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1660:46',
            'invokeListenersByPlacement@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1655:21',
            'domListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1670:39',
            'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1687:30',
            'addCustomElementEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1712:30',
            'patchedAddEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:3022:50',
            'value@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:5567:53',
            'addEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:11554:20',
            'applyEventListeners@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:8200:29',
            '...blah,blah,blah more javascript code goes here, etc.'
        };
        return String.join(lwcStackTraceLines, '\n');
    }

    private class DebugStringExample {
        private System.Exception constructorStackTraceGenerator;
        private System.Exception methodStackTraceGenerator;
        private LoggerStackTrace stackTrace;

        public DebugStringExample() {
            this.constructorStackTraceGenerator = new System.DmlException();
        }

        public String getConstructorStackTraceString() {
            return this.constructorStackTraceGenerator.getStackTraceString();
        }

        public String getMethodStackTraceString() {
            if (this.methodStackTraceGenerator == null) {
                this.methodStackTraceGenerator = new System.DmlException();
            }
            return this.methodStackTraceGenerator.getStackTraceString();
        }

        public LoggerStackTrace getStackTrace() {
            if (this.stackTrace == null) {
                this.stackTrace = new LoggerStackTrace();
            }
            return this.stackTrace;
        }
    }
}
