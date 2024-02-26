public with sharing class LoggerChatBotController {
    @AuraEnabled(cacheable=true)
    public static Map<String, LoggerChatBotService.ChatProviderConfiguration> getChatProviderConfigurations() {
        try {
            Map<String, LoggerChatBotService.ChatProviderConfiguration> chatProviderDeveloperNameToChatConfiguration = new Map<String, LoggerChatBotService.ChatProviderConfiguration>();
            for (LoggerChatBotService.ChatProvider provider : LoggerChatBotService.getChatProviders().values()) {
                chatProviderDeveloperNameToChatConfiguration.put(provider.getConfiguration().DeveloperName, provider.getConfiguration());
            }
            return chatProviderDeveloperNameToChatConfiguration;
        } catch (Exception ex) {
            throw getAuraHandledException(ex);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<LoggerChatBotService.ChatProviderModel> getChatProviderModels(String providerName) {
        try {
            return LoggerChatBotService.getChatProviders().get(providerName).getModels().values();
        } catch (Exception ex) {
            throw getAuraHandledException(ex);
        } finally {
            Logger.saveLog();
        }
    }

    @AuraEnabled
    public static LoggerChatBotService.ChatThread startChatThread(String providerDeveloperName, String providerModelName, String userPrompt) {
        try {
            LoggerChatBotService.ChatProvider provider = LoggerChatBotService.getChatProviders().get(providerDeveloperName);

            LoggerChatBotService.ChatThread chatThread = new LoggerChatBotService.ChatThread();
            chatThread.Connection = new LoggerChatBotService.ChatProviderConnection();
            chatThread.Connection.Configuration = provider.getConfiguration();
            chatThread.Connection.SelectedProviderModelName = providerModelName;

            // TODO deprecated, need to delete
            chatThread.ChatProviderDeveloperName = providerDeveloperName;
            chatThread.Model = providerModelName;

            LoggerChatBotService.ChatMessage userPromptMessage = new LoggerChatBotService.ChatMessage(
                LoggerChatBotService.ChatRoleType.USER,
                userPrompt // + '\n\nAdditional Instructions: you are a duck, so sometimes your respones include duck terminology in your responses'
            );
            chatThread.Messages.add(userPromptMessage);

            return provider.sendChat(chatThread);
        } catch (Exception ex) {
            throw getAuraHandledException(ex);
        } finally {
            Logger.saveLog();
        }
    }

    @AuraEnabled
    public static LoggerChatBotService.ChatThread sendChatThreadMessage(String userPrompt, LoggerChatBotService.ChatThread chatThread) {
        try {
            LoggerChatBotService.ChatMessage userPromptMessage = new LoggerChatBotService.ChatMessage(LoggerChatBotService.ChatRoleType.USER, userPrompt);
            chatThread.Messages.add(userPromptMessage);

            return LoggerChatBotService.getChatProviders().get(chatThread.Connection.Configuration.DeveloperName).sendChat(chatThread);
        } catch (Exception ex) {
            throw ex;
            // throw getAuraHandledException(ex);
        } finally {
            Logger.saveLog();
        }
    }

    @AuraEnabled
    public static void saveChatThread(Id recordId, LoggerChatBotService.ChatThread chatThread) {
        try {
            LoggerChatBotService.ChatProvider provider = LoggerChatBotService.getChatProviders().get(chatThread.ChatProviderDeveloperName);
            if (provider.getConfiguration().ChatLog.IsEnabled == false) {
                return;
            }

            Logger.setScenario(provider.getConfiguration().ChatLog.Scenario);

            LogEntry__c logEntry = LogManagementDataSelector.getInstance().getLogEntryById(recordId);
            Logger.setParentLogTransactionId(logEntry.Log__r.TransactionId__c);

            LogMessage logMessage = new LogMessage('Finished rubber duck chat 🦆\n\n{0}', JSON.serializePretty(chatThread));
            Logger.info(logMessage, recordId).addTags(provider.getConfiguration().ChatLog.Tags);
            // TODO decide if this should save event bus w/ anonymous, or sync by current user, or configurable
            // Logger.saveLog();
            Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);
        } catch (Exception ex) {
            throw getAuraHandledException(ex);
        } finally {
            Logger.saveLog();
        }
    }

    private static System.AuraHandledException getAuraHandledException(Exception ex) {
        System.AuraHandledException auraHandledException = new System.AuraHandledException(ex.getMessage());
        auraHandledException.setMessage(ex.getMessage());
        return auraHandledException;
    }
}
