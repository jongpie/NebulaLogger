//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerChatBotService_Tests {
    @IsTest
    static void it_returns_filtered_google_gemini_models() {
        LoggerChatBotService.ChatProviderConfiguration mockConfiguration = new LoggerChatBotService.ChatProviderConfiguration();
        mockConfiguration.DeveloperName = 'SomeName';
        mockConfiguration.IsEnabled = true;
        mockConfiguration.Metadata.ApexClassName = LoggerChatBotService.GoogleGeminiService.class.getName();
        mockConfiguration.Metadata.NamedCredentialDeveloperName = 'SomeNamedCredentail';
        LoggerParameter__mdt mockConfigurationParameter = new LoggerParameter__mdt(
            DeveloperName = 'ChatProvider_Some_Value_After_The_Prefix',
            Value__c = JSON.serialize(mockConfiguration)
        );
        LoggerParameter.setMock(mockConfigurationParameter);
        LoggerChatBotService.GoogleGeminiModelsResponse mockGeminiModelsResponse = new LoggerChatBotService.GoogleGeminiModelsResponse();
        LoggerChatBotService.GoogleGeminiModel validGeminiModel = new LoggerChatBotService.GoogleGeminiModel();
        validGeminiModel.displayName = 'This model should be returned by the service';
        validGeminiModel.name = 'models/some-api-name-value';
        validGeminiModel.supportedGenerationMethods = new List<String>{ 'generateContent', 'someOtherValue' };
        mockGeminiModelsResponse.models.add(validGeminiModel);
        LoggerChatBotService.GoogleGeminiModel invalidGeminiModel = new LoggerChatBotService.GoogleGeminiModel();
        invalidGeminiModel.displayName = 'This model should NOT be returned by the service';
        invalidGeminiModel.name = 'models/another-api-name-value';
        invalidGeminiModel.supportedGenerationMethods = new List<String>{ 'any-value-that-is-not-generateContent' };
        mockGeminiModelsResponse.models.add(invalidGeminiModel);
        LoggerMockDataCreator.MockHttpCallout mockHttpCallout = LoggerMockDataCreator.createHttpCallout()
            .setStatusCode(200)
            .setResponseBody(System.JSON.serialize(mockGeminiModelsResponse));
        System.Test.setMock(System.HttpCalloutMock.class, mockHttpCallout);

        Map<String, LoggerChatBotService.ChatProviderModel> returnedModels = LoggerChatBotService.getChatProviders()
            .get(mockConfiguration.DeveloperName)
            .getModels();

        System.Assert.areEqual('callout:' + mockConfiguration.Metadata.NamedCredentialDeveloperName + '/v1/models', mockHttpCallout.request.getEndpoint());
        System.Assert.areEqual(System.JSON.serialize(mockGeminiModelsResponse), mockHttpCallout.response.getBody());
        System.Assert.areEqual(1, returnedModels.size());
        LoggerChatBotService.ChatProviderModel transformedValidGeminiModal = new LoggerChatBotService.ChatProviderModel();
        transformedValidGeminiModal.DeveloperName = validGeminiModel.name;
        transformedValidGeminiModal.Label = validGeminiModel.displayName + ' (' + validGeminiModel.name.substringAfter('models/') + ')';
        Map<String, LoggerChatBotService.ChatProviderModel> expectedModels = new Map<String, LoggerChatBotService.ChatProviderModel>{
            transformedValidGeminiModal.DeveloperName => transformedValidGeminiModal
        };
        System.Assert.areEqual(JSON.serializePretty(expectedModels), JSON.serializePretty(returnedModels));
    }

    @IsTest
    static void it_sends_google_gemini_chat_thread() {
        System.Assert.fail('TODO!');
    }

    @IsTest
    static void it_returns_filtered_open_ai_chat_gpt_models() {
        LoggerChatBotService.ChatProviderConfiguration mockConfiguration = new LoggerChatBotService.ChatProviderConfiguration();
        mockConfiguration.DeveloperName = 'SomeName';
        mockConfiguration.IsEnabled = true;
        mockConfiguration.Metadata.ApexClassName = LoggerChatBotService.OpenAIChatGPTService.class.getName();
        mockConfiguration.Metadata.NamedCredentialDeveloperName = 'SomeNamedCredentail';
        LoggerParameter__mdt mockConfigurationParameter = new LoggerParameter__mdt(
            DeveloperName = 'ChatProvider_Some_Value_After_The_Prefix',
            Value__c = JSON.serialize(mockConfiguration)
        );
        LoggerParameter.setMock(mockConfigurationParameter);
        LoggerChatBotService.OpenAIChatGPTModelsResponse mockChatGPTModelsResponse = new LoggerChatBotService.OpenAIChatGPTModelsResponse();
        LoggerChatBotService.OpenAIChatGPTModel validChatGPTModel = new LoggerChatBotService.OpenAIChatGPTModel();
        validChatGPTModel.id = 'some-api-name-value';
        validChatGPTModel.owned_by = 'openai';
        mockChatGPTModelsResponse.data.add(validChatGPTModel);
        LoggerChatBotService.OpenAIChatGPTModel invalidChatGPTModel = new LoggerChatBotService.OpenAIChatGPTModel();
        invalidChatGPTModel.id = 'another-api-name-value';
        invalidChatGPTModel.owned_by = 'Any other value';
        mockChatGPTModelsResponse.data.add(invalidChatGPTModel);
        LoggerMockDataCreator.MockHttpCallout mockHttpCallout = LoggerMockDataCreator.createHttpCallout()
            .setStatusCode(200)
            .setResponseBody(System.JSON.serialize(mockChatGPTModelsResponse));
        System.Test.setMock(System.HttpCalloutMock.class, mockHttpCallout);

        Map<String, LoggerChatBotService.ChatProviderModel> returnedModels = LoggerChatBotService.getChatProviders()
            .get(mockConfiguration.DeveloperName)
            .getModels();

        System.Assert.areEqual('callout:' + mockConfiguration.Metadata.NamedCredentialDeveloperName + '/v1/models', mockHttpCallout.request.getEndpoint());
        System.Assert.areEqual(System.JSON.serialize(mockChatGPTModelsResponse), mockHttpCallout.response.getBody());
        System.Assert.areEqual(1, returnedModels.size());
        LoggerChatBotService.ChatProviderModel transformedValidChatGPTModal = new LoggerChatBotService.ChatProviderModel();
        transformedValidChatGPTModal.DeveloperName = validChatGPTModel.id;
        transformedValidChatGPTModal.Label = validChatGPTModel.id;
        Map<String, LoggerChatBotService.ChatProviderModel> expectedModels = new Map<String, LoggerChatBotService.ChatProviderModel>{
            transformedValidChatGPTModal.DeveloperName => transformedValidChatGPTModal
        };
        System.Assert.areEqual(JSON.serializePretty(expectedModels), JSON.serializePretty(returnedModels));
    }

    @IsTest
    static void it_sends_open_ai_chat_gpt_chat_thread() {
        System.Assert.fail('TODO!');
    }
}
