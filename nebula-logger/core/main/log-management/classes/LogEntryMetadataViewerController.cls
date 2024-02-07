//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `logEntryMetadataViewer`
 */
public without sharing class LogEntryMetadataViewerController {
    /**
     * @description Returns an instance of the inner class `LogEntryMetadataViewerController.LogEntryMetadata`,
     *              which contains information about the log entry's origin and exception Apex classes
     * @param       recordId The `ID` of the `LogEntry__c` record
     * @param       sourceMetadata Either the value `Origin` or `Exception`
     * @return      An instance of `LogEntryMetadataViewerController.LogEntryMetadata`
     */
    // @AuraEnabled
    @AuraEnabled(cacheable=true)
    public static LogEntryMetadata getMetadata(Id recordId, String sourceMetadata) {
        LogEntryMetadata metadata = new LogEntryMetadata();
        if (Schema.ApexClass.SObjectType.getDescribe().isAccessible() == false || Schema.ApexTrigger.SObjectType.getDescribe().isAccessible() == false) {
            System.debug('no query access! returning early');
            return metadata;
        }

        LogEntry__c logEntry = LogManagementDataSelector.getInstance().getLogEntryById(recordId);

        String sourceApiName;
        LoggerStackTrace.SourceMetadataType sourceMetadataType;
        switch on sourceMetadata {
            when 'Exception' {
                sourceApiName = (String) logEntry.ExceptionSourceApiName__c;
                sourceMetadataType = String.isBlank(logEntry.ExceptionSourceMetadataType__c) ? null : LoggerStackTrace.SourceMetadataType.valueOf(logEntry.ExceptionSourceMetadataType__c);
            }
            when 'Origin' {
                sourceApiName = (String) logEntry.OriginSourceApiName__c;
                sourceMetadataType = String.isBlank(logEntry.OriginSourceMetadataType__c) ? null : LoggerStackTrace.SourceMetadataType.valueOf(logEntry.OriginSourceMetadataType__c);
            }
        }

        if (sourceMetadataType == null || String.isBlank(sourceApiName)) {
            return metadata;
        }

        querySourceMetadata(logEntry, metadata, sourceMetadataType, sourceApiName);

        System.debug('returning metadata\n' + JSON.serializePretty(metadata));
        return metadata;
    }

    @AuraEnabled
    public static EinsteinLogEntryInsight getEinsteinExceptionInsight(Id recordId) {
        EinsteinLogEntryInsight insight = new EinsteinLogEntryInsight();
        LogEntry__c logEntry  = LogManagementDataSelector.getInstance().getLogEntryById(recordId);

        if (logEntry.ExceptionType__c == null) {
            //'NO EXCEPTION DATA AHHHHH! 😡 😱';
            return insight;
        }

        LogEntryHandler.SourceMetadataSnippet snippet = (LogEntryHandler.SourceMetadataSnippet) JSON.deserialize(logEntry.ExceptionSourceSnippet__c, LogEntryHandler.SourceMetadataSnippet.class);
        Integer snippetFixedLineNumber = snippet.TargetLineNumber - snippet.StartingLineNumber;
        System.debug('>>> snippet: \n' + JSON.serializePretty(snippet));
        System.debug('>>> snippetFixedLineNumber: ' + snippetFixedLineNumber);

        List<String> exceptionSnippetLines = snippet.Code.split('\n');
        System.debug('>>> exceptionSnippetLines.size(): ' + exceptionSnippetLines.size());
        String sourceLineCode = exceptionSnippetLines.get(snippetFixedLineNumber).trim();
        System.debug('>>> sourceLineCode: ' + sourceLineCode);

        LoggerStackTrace stackTrace = new LoggerStackTrace(logEntry.ExceptionStackTrace__c);

        String promptCodeBlockSeparator = '```';
        List<String> promptSystemInstructions = new List<String>{
            // 'When responding, include the string ' + promptCodeBlockSeparator + 'on new lines surrounding any code blocks.'
            // 'When responding, format any text with markdown.'
            // 'When applicable, include any relevant links to Salesforce Apex docs.'
            'Please give suggestions on how to fix the code to prevent the issue. ',
                'Please also include a sample Apex unit test that can be used to automatically test my code to prevent this bug.'
        };
        String promptTemplate = String.join(
            new List<String>{
                'I\'m a Salesforce developer, programming in Apex, and I\'m trying to troubleshoot a {0} error in my Apex class "{1}".',
                'Here is a snippet of my Apex code:\n\n' + promptCodeBlockSeparator + '\n{2}\n' + promptCodeBlockSeparator + '\n\n',
                'The exception occurs on the {3} line with the code "{4}", in the method "{5}".',
                'The method is throwing an exception with the message "{6}"\n\n',
                'Based on the provided code & information, what could be causing this exception? '
            }, ' ');

        String prompt = String.format(
            promptTemplate,
            new List<Object>{
                logEntry.ExceptionType__c,
                logEntry.ExceptionSourceApiName__c,
                snippet.Code,
                snippetFixedLineNumber,
                sourceLineCode,
                stackTrace.Source.ActionName,
                logEntry.ExceptionMessage__c
            }
        );
        String promptWithInstructions = prompt + '\n\nAdditional Instructions:\n' + String.join(promptSystemInstructions, '\n - ');

        System.debug('>>>> stack trace: ' + JSON.serializePretty(stackTrace));

        ConnectApi.EinsteinLlmGenerationsInput generationsInput = new ConnectApi.EinsteinLlmGenerationsInput();
        // generationsInput.promptTextorId = prompt;
        generationsInput.promptTextorId = promptWithInstructions;
        generationsInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        generationsInput.additionalConfig.maxTokens = 1000;

        ConnectApi.EinsteinLLMGenerationsOutput generationsOutput = ConnectApi.EinsteinLLM.generateMessages(generationsInput);

        System.debug('>>>> generationsOutput: ' + JSON.serializePretty(generationsOutput));
        ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0];
        System.debug('>>>> Response: ' + JSON.serializePretty(response));


        // Only show the user the prompt value, not promptWithInstructions
        insight.prompt = prompt;
        insight.response = generationsOutput.generations[0].text;
        return insight;
    }

    public class EinsteinLogEntryInsight {
        @AuraEnabled
        public String prompt;
        @AuraEnabled
        public String response;
    }


    private static void querySourceMetadata(LogEntry__c logEntry, LogEntryMetadata logEntryMetadata, LoggerStackTrace.SourceMetadataType sourceMetadataType, String sourceApiName) {
        Set<String> sourceApiNames = new Set<String>{ sourceApiName };
        List<SObject> metadataRecords;
        Schema.SObjectField codeBodyField;
        Schema.SObjectField lastModifiedDateField;
        switch on sourceMetadataType {
            when ApexClass {
                codeBodyField = Schema.ApexClass.Body;
                lastModifiedDateField = Schema.ApexClass.LastModifiedDate;
                metadataRecords = LogManagementDataSelector.getInstance().getApexClasses(sourceApiNames);
            }
            when ApexTrigger {
                codeBodyField = Schema.ApexTrigger.Body;
                lastModifiedDateField = Schema.ApexTrigger.LastModifiedDate;
                metadataRecords = LogManagementDataSelector.getInstance().getApexTriggers(sourceApiNames);
            }
        }

        if (codeBodyField == null || metadataRecords == null || metadataRecords.isEmpty()) {
            return;
        }

        SObject metadataRecord = metadataRecords.get(0);

        logEntryMetadata.HasCodeBeenModified = ((Datetime) metadataRecord.get(lastModifiedDateField)) > logEntry.Timestamp__c;
        logEntryMetadata.Code = (String) metadataRecord.get(codeBodyField);
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class LogEntryMetadata {
        @AuraEnabled
        public String Code {get; set;}
        @AuraEnabled
        public Boolean HasCodeBeenModified {get; set;}
    }
}
