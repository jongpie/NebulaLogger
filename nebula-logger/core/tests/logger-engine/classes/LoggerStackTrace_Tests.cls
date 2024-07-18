//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.FieldNamingConventions, PMD.MethodNamingConventions')
@IsTest
private class LoggerStackTrace_Tests {
    private static final String MOCK_LOGGER_COMPONENT_NAME = 'c/logger';

    static {
        LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
    }

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

    // @IsTest
    // static void it_should_parse_javascript_aura_component_stack_trace_string() {
    //     LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
    //     String expectedComponentApiName = 'c/loggerAuraDemo';
    //     String expectedComponentFunctionName = 'saveLogAuraExample';
    //     Integer expectedLineNumber = 123;
    //     String auraStackTraceString = getMockAuraComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

    //     LoggerStackTrace auraStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, auraStackTraceString);

    //     System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, auraStackTrace.Language);
    //     System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, auraStackTrace.Location);
    //     System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle, auraStackTrace.Source.MetadataType);
    //     System.Assert.areEqual(expectedComponentApiName, auraStackTrace.Source.ApiName);
    //     System.Assert.areEqual(expectedComponentFunctionName, auraStackTrace.Source.ActionName);
    //     System.Assert.areEqual(expectedLineNumber, auraStackTrace.Source.LineNumber);
    // }

    // @IsTest
    // static void it_should_parse_javascript_web_component_legacy_stack_trace_string() {
    //     LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
    //     String expectedComponentApiName = 'c/loggerWebDemo';
    //     String expectedComponentFunctionName = 'saveLogWebExample';
    //     Integer expectedLineNumber = 123;
    //     String modernLwcStackTraceString = getMockLegacyWebComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

    //     LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

    //     System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
    //     System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
    //     System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
    //     System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
    //     System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
    //     System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    // }

    // @IsTest
    // static void it_should_parse_javascript_web_component_modern_stack_trace_string() {
    //     LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
    //     String expectedComponentApiName = 'c/loggerWebDemo';
    //     String expectedComponentFunctionName = 'saveLogWebExample';
    //     Integer expectedLineNumber = 123;
    //     String modernLwcStackTraceString = getMockModernWebComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

    //     LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

    //     System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
    //     System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
    //     System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
    //     System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
    //     System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
    //     System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    // }

    // @IsTest
    // static void it_should_parse_javascript_chrome_web_component_stack_trace_string() {
    //     LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
    //     String expectedComponentApiName = 'c/loggerWebDemo';
    //     String expectedComponentFunctionName = 'saveLogWebExample';
    //     Integer expectedLineNumber = 123;
    //     String modernLwcStackTraceString = getMockChromeWebComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName, expectedLineNumber);

    //     LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

    //     System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
    //     System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
    //     System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
    //     System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
    //     System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
    //     System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    // }

    // @IsTest
    // static void it_should_parse_javascript_web_component_modern_stack_trace_string_for_connected_callback() {
    //     LoggerStackTrace.ignoreOrigin(LoggerStackTrace.SourceLanguage.JavaScript, MOCK_LOGGER_COMPONENT_NAME);
    //     String expectedComponentApiName = 'c/loggerWebDemo';
    //     String connectedCallbackFunctionName = 'connectedCallback/<';
    //     String expectedComponentFunctionName = 'connectedCallback';
    //     Integer expectedLineNumber = 123;
    //     String modernLwcStackTraceString = getMockModernWebComponentStackTrace(expectedComponentApiName, connectedCallbackFunctionName, expectedLineNumber);

    //     LoggerStackTrace lwcStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, modernLwcStackTraceString);

    //     System.Assert.areEqual(LoggerStackTrace.SourceLanguage.JavaScript, lwcStackTrace.Language);
    //     System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, lwcStackTrace.Location);
    //     System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, lwcStackTrace.Source.MetadataType);
    //     System.Assert.areEqual(expectedComponentApiName, lwcStackTrace.Source.ApiName);
    //     System.Assert.areEqual(expectedComponentFunctionName, lwcStackTrace.Source.ActionName);
    //     System.Assert.areEqual(expectedLineNumber, lwcStackTrace.Source.LineNumber);
    // }

    // New tests for testing stack traces
    @IsTest
    static void it_should_parse_chrome_aura_stack_trace_when_logger_is_embedded_in_markup() {
        Set<ComponentTarget> auraTargets = new Set<ComponentTarget>(ComponentTarget.values());
        // Aura components can't run in lightning web runtime (LWR), so skip this target
        auraTargets.remove(ComponentTarget.LightningCommunityPageLightningWebRuntime);
        Component mockComponent = new Component(new List<ComponentTarget>(auraTargets));
        for (ComponentTarget target : mockComponent.targets) {
            ChromeAuraEmbedStackTraceStringGenerator stackTraceStringGenerator = new ChromeAuraEmbedStackTraceStringGenerator(mockComponent, target);
            String mockStackTraceString = stackTraceStringGenerator.generate();

            LoggerStackTrace stackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockStackTraceString);

            System.Assert.isTrue(stackTraceStringGenerator.isValid(stackTrace));
        }
    }

    @IsTest
    static void it_should_parse_chrome_lwc_stack_trace_when_logger_is_embedded_in_markup() {
        Component mockComponent = new Component();
        for (ComponentTarget target : mockComponent.targets) {
            ChromeLWCEmbedStackTraceStringGenerator stackTraceStringGenerator = new ChromeLWCEmbedStackTraceStringGenerator(mockComponent, target);
            String mockStackTraceString = stackTraceStringGenerator.generate();

            LoggerStackTrace stackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockStackTraceString);

            System.Assert.isTrue(stackTraceStringGenerator.isValid(stackTrace));
        }
    }

    @IsTest
    static void it_should_parse_chrome_lwc_stack_trace_when_logger_is_imported_in_javascript() {
        Component mockComponent = new Component();
        for (ComponentTarget target : mockComponent.targets) {
            ChromeLWCImportStackTraceStringGenerator stackTraceStringGenerator = new ChromeLWCImportStackTraceStringGenerator(mockComponent, target);
            String mockStackTraceString = stackTraceStringGenerator.generate();

            LoggerStackTrace stackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockStackTraceString);

            System.Assert.isTrue(stackTraceStringGenerator.isValid(stackTrace));
        }
    }

    @IsTest
    static void it_should_parse_firefox_aura_stack_trace_when_logger_is_embedded_in_markup() {
        Set<ComponentTarget> auraTargets = new Set<ComponentTarget>(ComponentTarget.values());
        // Aura components can't run in lightning web runtime (LWR), so skip this target
        auraTargets.remove(ComponentTarget.LightningCommunityPageLightningWebRuntime);
        Component mockComponent = new Component(new List<ComponentTarget>(auraTargets));
        for (ComponentTarget target : mockComponent.targets) {
            FirefoxAuraEmbedStackTraceStringGenerator stackTraceStringGenerator = new FirefoxAuraEmbedStackTraceStringGenerator(mockComponent, target);
            String mockStackTraceString = stackTraceStringGenerator.generate();

            LoggerStackTrace stackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockStackTraceString);

            System.Assert.isTrue(stackTraceStringGenerator.isValid(stackTrace));
        }
    }

    @IsTest
    static void it_should_parse_firefox_lwc_stack_trace_when_logger_is_embedded_in_markup() {
        Component mockComponent = new Component();
        for (ComponentTarget target : mockComponent.targets) {
            FirefoxLWCEmbedStackTraceStringGenerator stackTraceStringGenerator = new FirefoxLWCEmbedStackTraceStringGenerator(mockComponent, target);
            String mockStackTraceString = stackTraceStringGenerator.generate();

            LoggerStackTrace stackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockStackTraceString);

            System.Assert.isTrue(stackTraceStringGenerator.isValid(stackTrace));
        }
    }

    @IsTest
    static void it_should_parse_firefox_lwc_stack_trace_when_logger_is_imported_in_javascript() {
        Component mockComponent = new Component();
        for (ComponentTarget target : mockComponent.targets) {
            FirefoxLWCImportStackTraceStringGenerator stackTraceStringGenerator = new FirefoxLWCImportStackTraceStringGenerator(mockComponent, target);
            String mockStackTraceString = stackTraceStringGenerator.generate();

            LoggerStackTrace stackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockStackTraceString);

            System.Assert.isTrue(stackTraceStringGenerator.isValid(stackTrace));
        }
    }

    /*
        ComponentTarget contains enum representations of each LWC target being tested.
        Aura components typically use a different list of interfaces, but to try to keep
        things a bit simpler, the tests re-use these same targets for LWC & Aura components.
        - lightning__AppPage
        - lightningCommunity__Page, using the older Aura framework runtime
        - lightningCommunity__Page, using the newer lightning web runtime (LWR)
        - lightning__FlowScreen
        - lightning__HomePage
        - lightning__RecordAction
        - lightning__RecordPage
        - lightning__Tab
        - lightning__UtilityBar
    */
    private enum ComponentTarget {
        LightningAppPage,
        LightningCommunityPageAuraRuntime,
        LightningCommunityPageLightningWebRuntime,
        LightningFlowScreen,
        LightningHomePage,
        LightningRecordAction,
        LightningRecordPage,
        LightningTab,
        LightningUtilityBar
    }

    private class Component {
        public String apiName;
        public String functionName;
        public Integer lineNumber;
        public List<ComponentTarget> targets;

        public Component() {
            this(ComponentTarget.values());
        }

        public Component(List<ComponentTarget> targets) {
            this.apiName = 'c/someComponent';
            this.functionName = 'someFunction';
            this.lineNumber = 123;
            this.targets = targets;
        }
    }

    private abstract class MockComponentStackTraceStringGenerator {
        private final Component component;
        private final ComponentTarget target;
        private final String originComponentName;
        private final String originFunctionName;
        private final Integer originLineNumber;

        public MockComponentStackTraceStringGenerator(Component component, ComponentTarget target) {
            this.component = component;
            this.target = target;
            // Old approach, still referenced
            this.originComponentName = component.apiName;
            this.originFunctionName = component.functionName;
            this.originLineNumber = component.lineNumber;
        }

        public String generate() {
            switch on target {
                when LightningAppPage {
                    return this.forLightningAppPage(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningCommunityPageAuraRuntime {
                    return this.forLightningCommunityPageAuraRuntime(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningCommunityPageLightningWebRuntime {
                    return this.forLightningCommunityPageLightningWebRuntime(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningFlowScreen {
                    return this.forLightningFlowScreen(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningHomePage {
                    return this.forLightningHomePage(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningRecordAction {
                    return this.forLightningRecordAction(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningRecordPage {
                    return this.forLightningRecordPage(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningTab {
                    return this.forLightningTab(originComponentName, originFunctionName, originLineNumber);
                }
                when LightningUtilityBar {
                    return this.forLightningUtilityBar(originComponentName, originFunctionName, originLineNumber);
                }
                when else {
                    throw new System.IllegalArgumentException('Unknown target ' + target.name());
                }
            }
        }

        public Boolean isValid(LoggerStackTrace stackTrace) {
            String mockStackTraceString = this.generate();
            System.Assert.areEqual(this.getSourceLanguage(), stackTrace.Language, 'Failed for target ' + this.target);
            System.Assert.areEqual(this.originComponentName + '.' + this.originFunctionName, stackTrace.Location, 'Failed for target ' + this.target);
            System.Assert.areEqual(this.getSourceMetadataType(), stackTrace.Source.MetadataType, 'Failed for target ' + this.target);
            System.Assert.areEqual(this.originComponentName, stackTrace.Source.ApiName, 'Failed for target ' + this.target);
            System.Assert.areEqual(this.originFunctionName, stackTrace.Source.ActionName, 'Failed for target ' + this.target);
            System.Assert.areEqual(this.originLineNumber, stackTrace.Source.LineNumber, 'Failed for target ' + this.target);
            System.Assert.areNotEqual(mockStackTraceString, stackTrace.ParsedStackTraceString);
            System.Assert.isFalse(
                stackTrace.ParsedStackTraceString.contains(MOCK_LOGGER_COMPONENT_NAME + '.js'),
                'Failed for target ' +
                    this.target +
                    ', parsed stack trace should not mention logger component, received:\n\n' +
                    stackTrace.ParsedStackTraceString +
                    '\n\nOriginal:\n\n' +
                    mockStackTraceString
            );
            System.Assert.isTrue(
                mockStackTraceString.endsWith(stackTrace.ParsedStackTraceString),
                'Failed for target ' +
                    this.target +
                    ', parsed stack trace should be a subset of the original stack trace, received:\n\n' +
                    stackTrace.ParsedStackTraceString +
                    '\n\nOriginal:\n\n' +
                    mockStackTraceString
            );

            // This is a mostly-useless boolean that will always return true, unless on of the asserts above fails.
            // This gives the calling @IsTest methods a value to assert on, which helps avoid a PMD scan violation
            // of tests not having any asserts.
            return true;
        }

        protected LoggerStackTrace.SourceLanguage getSourceLanguage() {
            return LoggerStackTrace.SourceLanguage.JavaScript;
        }

        protected abstract LoggerStackTrace.SourceMetadataType getSourceMetadataType();
        protected abstract String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningCommunityPageLightningWebRuntime(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber);
        protected abstract String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber);
    }

    private class ChromeAuraEmbedStackTraceStringGenerator extends MockComponentStackTraceStringGenerator {
        // The stack traces generated by each of the methods below are based on actual JavaScript stack traces from Chrome v126.0.6479.127,
        // when referencing c/logger in an Aura component running in the corresponding target
        public ChromeAuraEmbedStackTraceStringGenerator(Component component, ComponentTarget target) {
            super(component, target);
        }

        protected override LoggerStackTrace.SourceMetadataType getSourceMetadataType() {
            return LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle;
        }

        protected override String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/page/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageLightningWebRuntime(
            String originComponentName,
            String originFunctionName,
            Integer originLineNumber
        ) {
            System.Assert.fail('Not a valid target for Aura components!');
            return null;
        }

        protected override String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/page/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/page/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/page/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at self.<computed> [as info] (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage(
                        'at {1} (https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30)',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage()
            };
            return String.join(stackTracePieces, '\n');
        }
    }

    private class ChromeLWCEmbedStackTraceStringGenerator extends MockComponentStackTraceStringGenerator {
        // The stack traces generated by each of the methods below are based on actual JavaScript stack traces from Chrome v126.0.6479.127,
        // when referencing c/logger in an LWC running in the corresponding target
        public ChromeLWCEmbedStackTraceStringGenerator(Component component, ComponentTarget target) {
            super(component, target);
        }

        protected override LoggerStackTrace.SourceMetadataType getSourceMetadataType() {
            return LoggerStackTrace.SourceMetadataType.LightningComponentBundle;
        }

        protected override String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:464:112)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:16)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:464:112)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:2018:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38)',
                'at callHook (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15)',
                'at HTMLBridgeElement.<anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:2647:14)',
                'at https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:10756:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:589:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:540:196)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:16)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:2018:24)'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageLightningWebRuntime(
            String originComponentName,
            String originFunctionName,
            Integer originLineNumber
        ) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:464:112)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:2018:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38)',
                'at callHook (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15)',
                'at HTMLBridgeElement.<anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:2647:14)',
                'at https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:10756:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:589:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:540:196)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:16)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:2018:24)'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:3:6914)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)',
                'at en.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:67030)',
                'at mo (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:43179)',
                'at c.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:21644)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:85471',
                'at en.eval [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4751)',
                'at en.eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4255)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:4689)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:3:6914)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)',
                'at en.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:67030)',
                'at mo (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:43179)',
                'at c.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:21644)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:85471',
                'at en.eval [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4751)',
                'at en.eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4255)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:4689)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:3:6914)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)',
                'at en.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:67030)',
                'at mo (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:43179)',
                'at c.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:21644)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:85471',
                'at en.eval [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4751)',
                'at en.eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4255)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:4689)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:475:39)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at HTMLBridgeElement.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForOneOrMoreArgs$LWS [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:708:38)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrap$LWS (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:651:195)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:16)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:3:6914)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)',
                'at en.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:67030)',
                'at mo (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:43179)',
                'at c.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:21644)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:85471',
                'at en.eval [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4751)',
                'at en.eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4255)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:4689)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at Proxy.info (modules/{0}.js:3:6914)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)',
                'at en.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:67030)',
                'at mo (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:43179)',
                'at c.<anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:49:21644)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:85471',
                'at en.eval [as applyTrapForOneOrMoreArgs] (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4751)',
                'at en.eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:4255)',
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:4689)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_prod.js:105:98298), <anonymous>:3:23715)"'
            };
            return String.join(stackTracePieces, '\n');
        }
    }

    private class ChromeLWCImportStackTraceStringGenerator extends MockComponentStackTraceStringGenerator {
        // The stack traces generated by each of the methods below are based on actual JavaScript stack traces from Chrome v126.0.6479.127,
        // when referencing c/logger in an LWC running in the corresponding target
        public ChromeLWCImportStackTraceStringGenerator(Component component, ComponentTarget target) {
            super(component, target);
        }

        protected override LoggerStackTrace.SourceMetadataType getSourceMetadataType() {
            return LoggerStackTrace.SourceMetadataType.LightningComponentBundle;
        }

        protected override String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js}:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js}:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js}:254:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js}:373:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js}:296:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:253:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:372:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:295:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageLightningWebRuntime(
            String originComponentName,
            String originFunctionName,
            Integer originLineNumber
        ) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:253:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:372:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:295:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:2018:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38)',
                'at callHook (https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15)',
                'at https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5260:7'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:255:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:375:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:297:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:255:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:375:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:297:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:255:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:375:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:297:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:255:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:375:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:297:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:255:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:375:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:297:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13"'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                'Error',
                new LogMessage('at new ComponentLogEntry (modules/{0}.js:36:22)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at new LogEntryBuilder (modules/{0}.js:60:87)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at newLogEntry (modules/{0}.js:255:14)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService._newEntry (modules/{0}.js:375:33)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at LoggerService.info (modules/{0}.js:297:21)', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('at Proxy.{1} (modules/{0}.js:{2}:21)', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'at eval (eval at <anonymous> (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:37361:87), <anonymous>:2536:24)',
                'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38)',
                'at callHook (https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19)',
                'at https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:13"'
            };
            return String.join(stackTracePieces, '\n');
        }
    }

    private class FirefoxAuraEmbedStackTraceStringGenerator extends MockComponentStackTraceStringGenerator {
        // The stack traces generated by each of the methods below are based on actual JavaScript stack traces from Chrome v126.0.6479.127,
        // when referencing c/logger in an Aura component running in the corresponding target
        public FirefoxAuraEmbedStackTraceStringGenerator(Component component, ComponentTarget target) {
            super(component, target);
        }

        protected override LoggerStackTrace.SourceMetadataType getSourceMetadataType() {
            return LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle;
        }

        protected override String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/page/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'renderComponent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64026:6',
                'flushRenderingQueue/<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:28:16',
                'flushRenderingQueue@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:26:13',
                'FrameRequestCallback*requestRender@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:17:26',
                'AuraComponent/</<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:74:26',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59339:17',
                'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59240:12',
                'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58217:8',
                'createComponent/</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63990:14',
                'AuraInstance.prototype.$executeHotspot$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64818:5',
                'createComponent/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63989:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'createComponent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63987:8',
                'AuraComponent/<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:72:16',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'unpackDefinition@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65054:15',
                'collectDefinitions@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65087:15',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'AuraComponentService.prototype.$loadComponentDefs$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58753:5',
                'AuraInstance.prototype.$getDefinitions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65082:29',
                'AuraInstance.prototype.$getDefinition$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65053:8',
                'getDefinition/</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64012:14',
                'AuraInstance.prototype.$executeHotspot$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64818:5',
                'getDefinition/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64011:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'getDefinition@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64009:8',
                'AuraComponent@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:71:14',
                'create@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/auraWrapper.js:129:14',
                'renderedCallback@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/auraWrapper.js:58:39',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeComponentCallback/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10520:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageLightningWebRuntime(
            String originComponentName,
            String originFunctionName,
            Integer originLineNumber
        ) {
            System.Assert.fail('Not a valid target for Aura components!');
            return null;
        }

        protected override String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'renderComponent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64026:6',
                'flushRenderingQueue/<@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:43:24',
                'flushRenderingQueue@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:40:13',
                'FrameRequestCallback*requestRender@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:30:26',
                'AuraComponent/</<@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:101:26',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59339:17',
                'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59240:12',
                'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58217:8',
                'createComponent/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63993:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'createComponent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63987:8',
                'AuraComponent/<@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:96:22',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'unpackDefinition@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65054:15',
                'collectDefinitions@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65087:15',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'AuraComponentService.prototype.$loadComponentDefs$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58753:5',
                'AuraInstance.prototype.$getDefinitions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65082:29',
                'AuraInstance.prototype.$getDefinition$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65053:8',
                'getDefinition/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64015:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'getDefinition@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64009:8',
                'AuraComponent@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:95:20',
                'renderedCallback@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/auraField.js:200:40',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeComponentCallback/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10520:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeComponentCallback@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10519:34',
                'runRenderedCallback@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11017:36',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11010:32',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$rerenderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60031:33',
                'rerender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48957:33',
                'Component.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47988:28',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59675:36',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56568:10',
                'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56528:8',
                'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56297:10',
                'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56257:8',
                'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56244:12',
                'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56238:10',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64798:28',
                'promise callback*displayPage@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/page.js:124:17',
                'getPageDefAndDisplay/<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/page.js:255:30',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'Action.prototype.$finishActionInternal$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:53038:28',
                'AuraComponentService.prototype.$loadComponentDefs$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58753:5',
                'Action.prototype.$finishActionInternal$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:53027:37',
                'Action.prototype.$finishAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52989:31',
                'QueuedActionsMetricsPlugin.prototype.$actionFinishOverride$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66730:24',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                'AuraClientService.prototype.$singleAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:55391:14',
                'AuraClientService.prototype.$processResponsesInternal$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:57251:14',
                'AuraClientService.prototype.$processResponses$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:57164:35',
                'QueuedActionsMetricsPlugin.prototype.$actionsProcessResponses$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66753:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                '$processResponsesOverride$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66641:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'Aura.$Utils$.$Override$.prototype.start@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44921:30',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'render@https://drive-power-9433.scratch.lightning.force.com/components/forceChatter/publisherPresentation.js:9:23',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$rerenderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60031:33',
                'rerender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48781:32',
                'Component.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47988:28',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59675:36',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'renderComponent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64026:6',
                'flushRenderingQueue/<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:28:16',
                'flushRenderingQueue@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:26:13',
                'FrameRequestCallback*requestRender@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:17:26',
                'AuraComponent/</<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:74:26',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59339:17',
                'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59240:12',
                'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58217:8',
                'createComponent/</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63990:14',
                'AuraInstance.prototype.$executeHotspot$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64818:5',
                'createComponent/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63989:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'createComponent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:63987:8',
                'AuraComponent/<@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:72:16',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'unpackDefinition@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65054:15',
                'collectDefinitions@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65087:15',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'AuraComponentService.prototype.$loadComponentDefs$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58753:5',
                'AuraInstance.prototype.$getDefinitions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65082:29',
                'AuraInstance.prototype.$getDefinition$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:65053:8',
                'getDefinition/</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64012:14',
                'AuraInstance.prototype.$executeHotspot$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64818:5',
                'getDefinition/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64011:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'getDefinition@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64009:8',
                'AuraComponent@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/utils2.js:71:14',
                'create@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/auraWrapper.js:129:14',
                'renderedCallback@https://drive-power-9433.scratch.lightning.force.com/components/flexipage/auraWrapper.js:58:39',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeComponentCallback/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10520:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$rerenderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60031:33',
                'rerender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48957:33',
                'Component.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47988:28',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59675:36',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56568:10',
                'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56528:8',
                'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56297:10',
                'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56257:8',
                'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56244:12',
                'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56238:10',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64798:28',
                'promise callback*createContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/pageHost.js:590:48',
                'changePage@https://drive-power-9433.scratch.lightning.force.com/components/laf/pageHost.js:348:26',
                'onPageChange@https://drive-power-9433.scratch.lightning.force.com/components/laf/pageHost.js:38:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getActionCaller@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48436:20',
                'Aura.$Event$.$Event$.prototype.$executeHandlerIterator$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52276:19',
                'Aura.$Event$.$Event$.prototype.$executeHandlers$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52246:8',
                'Aura.$Event$.$Event$.prototype.$fire$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52323:10',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'Aura.$Event$.$Event$.prototype.$fire$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52321:6',
                'Component.prototype.$fireChangeEvent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47736:19',
                'Component.prototype.set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47691:12',
                'addNewContent/<@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:558:24',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'createWrapper/<@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:754:26',
                'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59339:17',
                'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59240:12',
                'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58217:8',
                'createWrapper@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:748:12',
                'addNewContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:546:14',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'executeContentProcessing@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:346:13',
                'contentSelected@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:292:14',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'selectContent/<@https://drive-power-9433.scratch.lightning.force.com/components/laf/standardLayoutContentSelector.js:21:21',
                'promise callback*selectContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/standardLayoutContentSelector.js:20:59',
                'selectContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/standardLayoutContentSelector.js:13:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'processPage@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:241:25',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50106:24',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage(
                        '{1}@https://drive-power-9433.scratch.lightning.force.com/lightning/n/components/{0}.js:{2}:30',
                        originComponentName,
                        originFunctionName,
                        originLineNumber
                    )
                    .getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34358:38',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34160:197',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Action.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52844:8',
                'handleClick@https://drive-power-9433.scratch.lightning.force.com/components/lightning/button.js:23:20',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                '$dispatchAction$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49232:12',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                '$dispatchAction$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49231:6',
                'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:66981:23',
                'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44943:20',
                'bound@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:44880:29',
                '$domEventHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49227:12',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'wrapperFn@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1505:29',
                'EventListener.handleEvent*patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2903:31',
                'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:43708:17',
                '$addNamedClickHandler$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49203:14',
                '$createHtmlAttribute$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49246:12',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49115:14',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:49122:27',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48777:45',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'Component.prototype.$superRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47479:34',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47958:17',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59947:29',
                'render@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48934:32',
                'Component.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47949:26',
                'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59614:36',
                'AuraRenderingService.prototype.$rerenderFacet$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60031:33',
                'rerender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48781:32',
                'Component.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47988:28',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59675:36',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56568:10',
                'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56528:8',
                'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56297:10',
                'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56257:8',
                'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56244:12',
                'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56238:10',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64798:28',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:627:20',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:613:14',
                'onDocked@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:687:14',
                'onDocked@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:108:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'layoutPanels/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:311:27',
                'layoutPanels@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:298:16',
                'addPanelToUI/<.onAfterShow<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:409:32',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'onShow@https://drive-power-9433.scratch.lightning.force.com/libraries/ui/containerManagerLib.containerManager.js:57:40',
                'showPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:310:25',
                'show@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:21:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'renderContainer@https://drive-power-9433.scratch.lightning.force.com/libraries/ui/containerManagerLib.containerManager.js:56:19',
                'addPanelToUI@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:399:45',
                'displayPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:634:20',
                'createPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:572:29',
                'createPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:35:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'create@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBar.js:305:16',
                '_internalCreate/<.callback<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBar.js:297:25',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'findOpenPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:136:24',
                'findOpenPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:25:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }
    }

    private class FirefoxLWCEmbedStackTraceStringGenerator extends MockComponentStackTraceStringGenerator {
        // The stack traces generated by each of the methods below are based on actual JavaScript stack traces from Firefox 128.0,
        // when referencing c/logger in an LWC running in the corresponding target
        public FirefoxLWCEmbedStackTraceStringGenerator(Component component, ComponentTarget target) {
            super(component, target);
        }

        protected override LoggerStackTrace.SourceMetadataType getSourceMetadataType() {
            return LoggerStackTrace.SourceMetadataType.LightningComponentBundle;
        }

        protected override String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/this.Aura.Engine@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createMembraneMarshall$LWS/createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/this.Aura.Engine@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'domListener/invokeListenersByPlacement/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageLightningWebRuntime(
            String originComponentName,
            String originFunctionName,
            Integer originLineNumber
        ) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker line 11770 > eval:2018:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15',
                'createMethodCaller/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:2647:14',
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:10756:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker line 11770 > eval:589:38',
                'applyOrConstructTrap$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker line 11770 > eval:540:196',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker line 11770 > eval:2018:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15',
                'invokeEventListener/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5260:16',
                'runWithBoundaryProtection@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5801:7',
                'invokeEventListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5256:30',
                'b/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:4761:26',
                'handleEvent@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15422:41',
                'invokeListenersByPlacement/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15465:36',
                'invokeListenersByPlacement@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15462:17',
                'domListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15474:35'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9597:26',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8981:22',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8886:29',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'updateComponentValue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5689:34',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:6794:37',
                'connectedCallback/<@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/lwcField.js:183:15',
                'promise callback*connectedCallback@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/lwcField.js:181:48',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeComponentCallback/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10520:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeComponentCallback@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10519:34',
                'runConnectedCallback@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11063:36',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9041:41',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7098:38',
                'setHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10706:9',
                'createSetter/cachedSetterByKey[key]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7501:24',
                'setProperty@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12276:13',
                'patchProps@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8496:28',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9210:19',
                'patchCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9063:47',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8889:35',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'updateComponentValue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5689:34',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7157:37',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9597:26',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'updateComponentValue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5689:34',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7157:37',
                'loadContent@https://drive-power-9433.scratch.lightning.force.com/components/interop/tab.js:78:9',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                '_showTabContentForTabValue@https://drive-power-9433.scratch.lightning.force.com/components/interop/tabset.js:379:13',
                '_selectTab@https://drive-power-9433.scratch.lightning.force.com/components/interop/tabset.js:362:14',
                'set activeTabValue@https://drive-power-9433.scratch.lightning.force.com/components/interop/tabset.js:197:18',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7127:25',
                'setHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10706:9',
                'createSetter/cachedSetterByKey[key]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7501:24',
                'setProperty@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12276:13',
                'patchProps@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8496:28',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9210:19',
                'patchCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9063:47',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8889:35',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8981:22',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8886:29',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:505:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('info@modules/{0}.js:475:39', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:36000:24',
                'applyOrConstructTrapForOneOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:708:38',
                'applyOrConstructTrap$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:651:195',
                new LogMessage('{1}@modules/{0}.js:{2}:16', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'connectRootElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10723:18',
                'callNodeSlot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12536:15',
                'replaceChild@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12566:29',
                'InteropComponent.prototype.$swapInteropElement$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50338:34',
                'InteropComponent.prototype.$invokeLwcRoutine$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50521:12',
                'InteropComponent.prototype.$swapInteropElement$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50337:8',
                'InteropComponent.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50384:10',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'afterRender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48969:8',
                'Component.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47970:18',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59708:14',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56568:10',
                'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56528:8',
                'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56297:10',
                'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56257:8',
                'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56244:12',
                'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56238:10',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64798:28',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:627:20',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:613:14',
                'onDocked@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:687:14',
                'onDocked@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:108:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'layoutPanels/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:311:27',
                'layoutPanels@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:298:16',
                'addPanelToUI/<.onAfterShow<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:409:32',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'onShow@https://drive-power-9433.scratch.lightning.force.com/libraries/ui/containerManagerLib.containerManager.js:57:40',
                'showPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:310:25',
                'show@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:21:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'renderContainer@https://drive-power-9433.scratch.lightning.force.com/libraries/ui/containerManagerLib.containerManager.js:56:19',
                'addPanelToUI@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:399:45',
                'displayPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:634:20',
                'createPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:572:29',
                'createPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:35:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'create@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBar.js:305:16',
                'transitionState/transitionCallback<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:610:25',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'transitionState/</<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:630:21',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:627:20',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }
    }

    private class FirefoxLWCImportStackTraceStringGenerator extends MockComponentStackTraceStringGenerator {
        // The stack traces generated by each of the methods below are based on actual JavaScript stack traces from Firefox 128.0,
        // when referencing c/logger in an LWC running in the corresponding target
        public FirefoxLWCImportStackTraceStringGenerator(Component component, ComponentTarget target) {
            super(component, target);
        }

        protected override LoggerStackTrace.SourceMetadataType getSourceMetadataType() {
            return LoggerStackTrace.SourceMetadataType.LightningComponentBundle;
        }

        protected override String forLightningAppPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageAuraRuntime(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/this.Aura.Engine@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'domListener/invokeListenersByPlacement/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggeraura/s/sfsites/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningCommunityPageLightningWebRuntime(
            String originComponentName,
            String originFunctionName,
            Integer originLineNumber
        ) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker line 11770 > eval:2018:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38',
                'callHook@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15',
                'invokeEventListener/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5260:16',
                'runWithBoundaryProtection@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5801:7',
                'invokeEventListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5256:30',
                'b/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:4761:26',
                'handleEvent@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15422:41',
                'invokeListenersByPlacement/<@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15465:36',
                'invokeListenersByPlacement@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15462:17',
                'domListener@https://drive-power-9433.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:15474:35'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningFlowScreen(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9597:26',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8981:22',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8886:29',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'updateComponentValue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5689:34',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:6794:37',
                'connectedCallback/<@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/lwcField.js:183:15',
                'promise callback*connectedCallback@https://drive-power-9433.scratch.lightning.force.com/components/flowruntime/lwcField.js:181:48',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeComponentCallback/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10520:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeComponentCallback@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10519:34',
                'runConnectedCallback@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11063:36',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9041:41',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningHomePage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordAction(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7098:38',
                'setHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10706:9',
                'createSetter/cachedSetterByKey[key]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7501:24',
                'setProperty@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12276:13',
                'patchProps@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8496:28',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9210:19',
                'patchCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9063:47',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8889:35',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'updateComponentValue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5689:34',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7157:37',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningRecordPage(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9597:26',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'flushRehydrationQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11032:26',
                'flushCallbackQueue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5299:25',
                'promise callback*addCallbackToNextTick@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5310:31',
                'scheduleRehydration@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11197:34',
                'getTemplateReactiveObserver/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10643:36',
                'notify@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5251:27',
                'valueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5177:24',
                'componentValueMutated@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5265:25',
                'updateComponentValue@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5689:34',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7157:37',
                'loadContent@https://drive-power-9433.scratch.lightning.force.com/components/interop/tab.js:78:9',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'createMethodCaller/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7511:20',
                '_showTabContentForTabValue@https://drive-power-9433.scratch.lightning.force.com/components/interop/tabset.js:379:13',
                '_selectTab@https://drive-power-9433.scratch.lightning.force.com/components/interop/tabset.js:362:14',
                'set activeTabValue@https://drive-power-9433.scratch.lightning.force.com/components/interop/tabset.js:197:18',
                'set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7127:25',
                'setHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10706:9',
                'createSetter/cachedSetterByKey[key]@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:7501:24',
                'setProperty@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12276:13',
                'patchProps@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8496:28',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9210:19',
                'patchCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9063:47',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8889:35',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8981:22',
                'patch@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8886:29',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9581:34',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningTab(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:300:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'connectRootElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10723:18',
                'callNodeSlot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12536:15',
                'replaceChild@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12566:29',
                'InteropComponent.prototype.$swapInteropElement$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50338:34',
                'InteropComponent.prototype.$invokeLwcRoutine$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50521:12',
                'InteropComponent.prototype.$swapInteropElement$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50337:8',
                'InteropComponent.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50384:10',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'afterRender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48969:8',
                'Component.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47970:18',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'afterRender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48779:6',
                'Component.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47970:18',
                'Component.prototype.$superAfterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47485:27',
                'Component.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47975:10',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59708:14',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56568:10',
                'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56528:8',
                'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56297:10',
                'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56257:8',
                'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56244:12',
                'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56238:10',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64798:28',
                'promise callback*createContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/pageHost.js:590:48',
                'changePage@https://drive-power-9433.scratch.lightning.force.com/components/laf/pageHost.js:348:26',
                'onPageChange@https://drive-power-9433.scratch.lightning.force.com/components/laf/pageHost.js:38:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getActionCaller@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48436:20',
                'Aura.$Event$.$Event$.prototype.$executeHandlerIterator$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52276:19',
                'Aura.$Event$.$Event$.prototype.$executeHandlers$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52246:8',
                'Aura.$Event$.$Event$.prototype.$fire$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52323:10',
                'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64916:12',
                'Aura.$Event$.$Event$.prototype.$fire$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52321:6',
                'Component.prototype.$fireChangeEvent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47736:19',
                'Component.prototype.set@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47691:12',
                'addNewContent/<@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:558:24',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'createWrapper/<@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:754:26',
                'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59339:17',
                'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59240:12',
                'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:58217:8',
                'createWrapper@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:748:12',
                'addNewContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:546:14',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'executeContentProcessing@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:346:13',
                'contentSelected@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:292:14',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'selectContent/<@https://drive-power-9433.scratch.lightning.force.com/components/laf/standardLayoutContentSelector.js:21:21',
                'promise callback*selectContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/standardLayoutContentSelector.js:20:59',
                'selectContent@https://drive-power-9433.scratch.lightning.force.com/components/laf/standardLayoutContentSelector.js:13:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'processPage@https://drive-power-9433.scratch.lightning.force.com/components/laf/singlePaneWindowManager.js:241:25',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }

        protected override String forLightningUtilityBar(String originComponentName, String originFunctionName, Integer originLineNumber) {
            List<String> stackTracePieces = new List<String>{
                new LogMessage('ComponentLogEntry@modules/{0}.js:36:22', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('LogEntryBuilder@modules/{0}.js:60:87', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('newLogEntry@modules/{0}.js:255:14', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('_newEntry@modules/{0}.js:375:44', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('info@modules/{0}.js:297:21', MOCK_LOGGER_COMPONENT_NAME).getMessage(),
                new LogMessage('{1}@modules/{0}.js:{2}:21', originComponentName, originFunctionName, originLineNumber).getMessage(),
                'createHooksCallback$LWS/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js line 37361 > eval:2536:24',
                'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:34227:38',
                'callHook@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10703:19',
                'invokeEventListener/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10588:21',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'invokeEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10583:34',
                'b/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9988:32',
                'handleEvent@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1592:49',
                'invokeListenersByPlacement/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1637:44',
                'invokeListenersByPlacement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1632:19',
                'domListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1647:37',
                'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1664:28',
                'addCustomElementEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:1689:28',
                'patchedAddEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:2881:48',
                'value@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:5669:53',
                'addEventListener@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12297:20',
                'applyEventListeners@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8614:29',
                'patchElementPropsAndAttrsAndRefs$1@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9200:32',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9031:43',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'mountElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8969:20',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8912:29',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'appendVM@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10731:18',
                'mountCustomElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9047:21',
                'mount@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8916:35',
                'mountVNodes@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9104:22',
                'updateStaticChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:9561:24',
                'patchChildren@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:8850:33',
                'patchShadowRoot/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10998:34',
                'runWithBoundaryProtection@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:11214:13',
                'patchShadowRoot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10993:42',
                'rehydrate@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10980:28',
                'connectRootElement@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:10723:18',
                'callNodeSlot@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12536:15',
                'replaceChild@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:12566:29',
                'InteropComponent.prototype.$swapInteropElement$/<@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50338:34',
                'InteropComponent.prototype.$invokeLwcRoutine$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50521:12',
                'InteropComponent.prototype.$swapInteropElement$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50337:8',
                'InteropComponent.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:50384:10',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'afterRender@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48969:8',
                'Component.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:47970:18',
                'AuraRenderingService.prototype.$afterRender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59742:13',
                'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:59708:14',
                'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:60278:14',
                'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56723:27',
                'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56568:10',
                'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56528:8',
                'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56297:10',
                'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56257:8',
                'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56244:12',
                'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:56238:10',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64798:28',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:627:20',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'setTimeout handler*nextTickAura@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:257:19',
                'transitionState@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:613:14',
                'onDocked@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:687:14',
                'onDocked@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:108:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'layoutPanels/<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:311:27',
                'layoutPanels@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:298:16',
                'addPanelToUI/<.onAfterShow<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:409:32',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'onShow@https://drive-power-9433.scratch.lightning.force.com/libraries/ui/containerManagerLib.containerManager.js:57:40',
                'showPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:310:25',
                'show@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBarPanel.js:21:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'renderContainer@https://drive-power-9433.scratch.lightning.force.com/libraries/ui/containerManagerLib.containerManager.js:56:19',
                'addPanelToUI@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:399:45',
                'displayPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:634:20',
                'createPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:572:29',
                'createPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:35:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'create@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBar.js:305:16',
                '_internalCreate/<.callback<@https://drive-power-9433.scratch.lightning.force.com/components/one/utilityBar.js:297:25',
                'callbackWrapper@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:64763:23',
                'findOpenPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:136:24',
                'findOpenPanel@https://drive-power-9433.scratch.lightning.force.com/components/one/utilPanelManager.js:25:16',
                'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:52857:36',
                'Component$getMethodHandler@https://static.lightning.force.com/cs219/auraFW/javascript/WFIwUmVJdmtIRnI3MTFpX0d6c1VwQWhZX25NdHFVdGpDN3BnWlROY1ZGT3cyNTAuOC4zLTYuNC41/aura_proddebug.js:48411:14',
                'aura_proddebug.js:36000:24'
            };
            return String.join(stackTracePieces, '\n');
        }
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

    private static String getMockChromeWebComponentStackTrace(String originComponentName, String originFunctionName, Integer expectedLineNumber) {
        List<String> lwcStackTraceLines = new List<String>{
            'Error',
            'at new ComponentLogEntry (modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:34:22)',
            'at new LogEntryBuilder (modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:58:87)',
            'at newLogEntry (modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:239:14)',
            'at LoggerService._newEntry (modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:358:33)',
            'at LoggerService.info (modules/' +
            MOCK_LOGGER_COMPONENT_NAME +
            '.js:281:21)',
            'at Proxy.' +
            originFunctionName +
            ' (modules/' +
            originComponentName +
            '.js:' +
            expectedLineNumber +
            ':21)',
            'at eval (eval at <anonymous> (https://speed-momentum-5634.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:11770:89), <anonymous>:2018:24)',
            'at BoundaryProxyHandler$LWS.applyOrConstructTrapForTwoOrMoreArgs$LWS (https://speed-momentum-5634.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/c7f375a5ad/dev/lwr_bootstrap_locker:9369:38)',
            'at callHook (https://speed-momentum-5634.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5344:15)',
            'at https://speed-momentum-5634.scratch.live-preview.salesforce-experience.com/loggerlwr/s/webruntime/framework/a72b9e0524/dev/lwr_lwc:5260:7',
            '...blah,blah,blah more javascript code goes here, etc.'
        };
        return String.join(lwcStackTraceLines, '\n');
    }

    private class DebugStringExample {
        private System.Exception constructorStackTraceStringGenerator;
        private System.Exception methodStackTraceStringGenerator;
        private LoggerStackTrace stackTrace;

        public DebugStringExample() {
            this.constructorStackTraceStringGenerator = new System.DmlException();
        }

        public String getConstructorStackTraceString() {
            return this.constructorStackTraceStringGenerator.getStackTraceString();
        }

        public String getMethodStackTraceString() {
            if (this.methodStackTraceStringGenerator == null) {
                this.methodStackTraceStringGenerator = new System.DmlException();
            }
            return this.methodStackTraceStringGenerator.getStackTraceString();
        }

        public LoggerStackTrace getStackTrace() {
            if (this.stackTrace == null) {
                this.stackTrace = new LoggerStackTrace();
            }
            return this.stackTrace;
        }
    }
}
