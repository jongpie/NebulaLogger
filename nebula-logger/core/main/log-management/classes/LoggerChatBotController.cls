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
    public static List<LoggerChatBotService.ChatProviderModel> getProviderModels(String providerName) {
        try {
            return LoggerChatBotService.getChatProviders().get(providerName).getModels();
        } catch (Exception ex) {
            throw getAuraHandledException(ex);
        }
    }

    @AuraEnabled
    public static LoggerChatBotService.ChatThread startChatThread(String providerDeveloperName, String providerModelName, String initialPrompt) {
        Logger.debug('providerDeveloperName: ' + providerDeveloperName);
        Logger.debug('providerModelName: ' + providerModelName);
        Logger.debug('initialPrompt: ' + initialPrompt);
        Logger.saveLog();
        try {
            LoggerChatBotService.ChatThread chatThread = new LoggerChatBotService.ChatThread();
            chatThread.ChatProviderDeveloperName = providerDeveloperName;
            chatThread.Model = providerModelName;

            LoggerChatBotService.ChatMessage userPromptMessage = new LoggerChatBotService.ChatMessage(LoggerChatBotService.ChatRoleType.USER, initialPrompt);
            chatThread.Messages.add(userPromptMessage);

            return LoggerChatBotService.getChatProviders().get(providerDeveloperName).sendChat(chatThread);
        } catch (Exception ex) {
            // throw getAuraHandledException(ex);
            throw ex;
        }
    }

    @AuraEnabled
    public static LoggerChatBotService.ChatThread sendChatThreadMessage(
        String providerDeveloperName,
        String providerModelName,
        String userPrompt,
        String chatThreadJSON,
        LoggerChatBotService.ChatThread chatThread
    ) {
        Logger.debug('providerDeveloperName: ' + providerDeveloperName);
        Logger.debug('providerModelName: ' + providerModelName);
        Logger.debug('userPrompt: ' + userPrompt);
        Logger.debug('chatThreadJSON: ' + chatThreadJSON);
        Logger.debug('chatThread: ' + chatThread);
        Logger.saveLog();
        try {
            if (chatThread == null && String.isNotBlank(chatThreadJSON)) {
                chatThread = (LoggerChatBotService.ChatThread) JSON.deserialize(chatThreadJSON, LoggerChatBotService.ChatThread.class);
            } else if (chatThread == null) {
                chatThread = new LoggerChatBotService.ChatThread();
                chatThread.ChatProviderDeveloperName = providerDeveloperName;
                chatThread.Model = providerModelName;
            }

            LoggerChatBotService.ChatMessage userPromptMessage = new LoggerChatBotService.ChatMessage(LoggerChatBotService.ChatRoleType.USER, userPrompt);
            chatThread.Messages.add(userPromptMessage);

            return LoggerChatBotService.getChatProviders().get(providerDeveloperName).sendChat(chatThread);
        } catch (Exception ex) {
            // throw getAuraHandledException(ex);
            throw ex;
        }
    }

    @AuraEnabled
    public static LoggerChatBotService.ChatThread sendChat(String providerName, LoggerChatBotService.ChatThread chatThread) {
        try {
            return LoggerChatBotService.getChatProviders().get(providerName).sendChat(chatThread);
        } catch (Exception ex) {
            throw getAuraHandledException(ex);
        }
    }

    private static System.AuraHandledException getAuraHandledException(Exception ex) {
        System.AuraHandledException auraHandledException = new System.AuraHandledException(ex.getMessage());
        auraHandledException.setMessage(ex.getMessage());
        return auraHandledException;
    }
}
