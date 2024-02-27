//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerChatBotController_Tests {
    private static String mockBotResponse = 'Some bot response';
    private static String mockChatId = 'Some-Chat-ID-1234';
    private static List<LoggerChatBotService.ChatProviderModel> mockProviderModels = new List<LoggerChatBotService.ChatProviderModel>();

    @IsTest
    static void it_should_return_provider_models() {
        LoggerChatBotService.ChatProviderConfiguration mockConfiguration = setupMockChatProviderConfiguration('SomeName');
        LoggerChatBotService.ChatProviderModel mockProviderModel = new LoggerChatBotService.ChatProviderModel();
        mockProviderModels.add(mockProviderModel);

        List<LoggerChatBotService.ChatProviderModel> returnedModels = LoggerChatBotController.getChatProviderModels(mockConfiguration.DeveloperName);

        System.Assert.areEqual(JSON.serializePretty(mockProviderModels), JSON.serializePretty(returnedModels));
    }

    @IsTest
    static void it_should_start_chat_thread() {
        String providerDeveloperName = 'mockProviderDeveloperName';
        String providerModelName = 'mockProviderModelName';
        LogEntry__c logEntry = null; // TODO;
        String userPromptType = 'mockUserPromptType';
        setupMockChatProviderConfiguration(providerDeveloperName);
        LoggerChatBotService.ChatProviderModel mockProviderModel = new LoggerChatBotService.ChatProviderModel();
        mockProviderModels.add(mockProviderModel);

        LoggerChatBotService.ChatThread returnedChatThread = LoggerChatBotController.startChatThread(
            providerDeveloperName,
            providerModelName,
            logEntry.Id,
            userPromptType
        );

        System.Assert.areEqual(mockChatId, returnedChatThread.ChatId);
        System.Assert.areEqual(providerDeveloperName, returnedChatThread.ChatProviderDeveloperName);
        System.Assert.areEqual(providerModelName, returnedChatThread.Model);
        System.Assert.areEqual(2, returnedChatThread.Messages.size());
        System.Assert.areEqual(LoggerChatBotService.ChatRoleType.USER.name().toLowerCase(), returnedChatThread.Messages.get(0).Role);
        System.Assert.areEqual(
            'TODO! This used to be `userPrompt`, but that no longer exists, it is now `userPromptType`.',
            returnedChatThread.Messages.get(0).Text
        );
        System.Assert.areEqual(LoggerChatBotService.ChatRoleType.BOT.name().toLowerCase(), returnedChatThread.Messages.get(1).Role);
        System.Assert.areEqual(mockBotResponse, returnedChatThread.Messages.get(1).Text);
    }

    @IsTest
    static void it_should_send_chat_thread_message() {
        System.Assert.fail('TODO');
    }

    @IsTest
    static void it_should_save_chat_thread() {
        System.Assert.fail('TODO');
    }

    private static LoggerChatBotService.ChatProviderConfiguration setupMockChatProviderConfiguration(String mockProviderDeveloperName) {
        LoggerChatBotService.ChatProviderConfiguration mockConfiguration = new LoggerChatBotService.ChatProviderConfiguration();
        mockConfiguration.DeveloperName = mockProviderDeveloperName;
        mockConfiguration.IsEnabled = true;
        mockConfiguration.Metadata.ApexClassName = MockChatProvider.class.getName();
        mockConfiguration.Metadata.NamedCredentialDeveloperName = 'SomeNamedCredential';
        LoggerParameter__mdt mockConfigurationParameter = new LoggerParameter__mdt(
            DeveloperName = 'ChatProvider_Some_Value_After_The_Prefix',
            Value__c = JSON.serialize(mockConfiguration)
        );
        LoggerParameter.setMock(mockConfigurationParameter);
        return mockConfiguration;
    }

    public class MockChatProvider extends LoggerChatBotService.ChatProvider {
        public override Map<String, LoggerChatBotService.ChatProviderModel> getModels() {
            Map<String, LoggerChatBotService.ChatProviderModel> mockProviderModelNameToProviderModel = new Map<String, LoggerChatBotService.ChatProviderModel>();
            for (LoggerChatBotService.ChatProviderModel chatProviderModel : mockProviderModels) {
                mockProviderModelNameToProviderModel.put(chatProviderModel.DeveloperName, chatProviderModel);
            }
            return mockProviderModelNameToProviderModel;
        }

        public override LoggerChatBotService.ChatThread sendChat(LoggerChatBotService.ChatThread chatThread) {
            chatThread.ChatId = mockChatId;
            LoggerChatBotService.ChatMessage botChatMessage = new LoggerChatBotService.ChatMessage(LoggerChatBotService.ChatRoleType.BOT, mockBotResponse);
            chatThread.Messages.add(botChatMessage);

            return chatThread;
        }
    }
}
