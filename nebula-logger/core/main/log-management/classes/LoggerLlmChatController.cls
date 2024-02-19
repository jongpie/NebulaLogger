public with sharing class LoggerLlmChatController {
    @AuraEnabled
    // public static List<LoggerParameter__mdt> getProviderConfigurations() {
    public static List<Map<String, Object>> getProviderConfigurations() {
        try {
            List<Map<String, Object>> providerConfigurations = new List<Map<String, Object>>();
            for (LoggerParameter__mdt providerParameter : LoggerParameter.matchOnPrefix('GenerativeAIProvider')) {
                Map<String, Object> providerConfiguration = (Map<String, Object>) JSON.deserializeUntyped(providerParameter.Value__c);
                providerConfigurations.add(providerConfiguration);
            }
            return providerConfigurations;
        } catch (Exception e) {
            // throw new System.AuraHandledException(e.getMessage());
            throw e;
        }
    }

    @AuraEnabled
    public static string startChat(Id recordId) {
        try {
            return 'TODO';
        } catch (Exception e) {
            throw new System.AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string sendChatMessage(Id recordId, String chatMessageContent) {
        try {
            LoggerLLMService.AIPromptMessage chatMessage = new LoggerLLMService.AIPromptMessage();
            chatMessage.Content = chatMessageContent;
            chatMessage.Role = 'user';
            LoggerLLMService.AIPromptInput promptInput = new LoggerLLMService.AIPromptInput();
            promptInput.Prompt = chatMessageContent;
            return 'TODO';
        } catch (Exception e) {
            throw new System.AuraHandledException(e.getMessage());
        }
    }
}
