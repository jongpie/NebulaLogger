public with sharing class LoggerChatBotService {
    private static final Map<String, ChatProvider> PROVIDER_NAME_TO_PROVIDER = loadEnabledChatProviders();

    // Public enum & classes used to abstract away each provider's implementation
    public enum ChatRoleType {
        BOT,
        USER
    }

    public abstract class ChatProvider {
        private ChatProviderConfiguration configuration;

        public ChatProviderConfiguration getConfiguration() {
            return this.configuration;
        }

        public abstract List<ChatProviderModel> getModels();
        public abstract ChatThread sendChat(ChatThread content);

        protected System.HttpRequest buildHttpRequest(String method, String endpoint, Object body) {
            System.HttpRequest calloutRequest = this.buildHttpRequest(method, endpoint);
            String jsonBody = JSON.serialize(body);
            calloutRequest.setBody(jsonBody);
            return calloutRequest;
        }

        protected System.HttpRequest buildHttpRequest(String method, String endpoint) {
            Integer thirtySecondsInMilliseconds = 30 * 1000;

            System.HttpRequest calloutRequest = new System.HttpRequest();
            calloutRequest.setEndpoint('callout:' + this.getConfiguration().Metadata.NamedCredentialDeveloperName + endpoint);
            calloutRequest.setHeader('Content-Type', 'application/json');
            calloutRequest.setMethod(method);
            calloutRequest.setTimeout(thirtySecondsInMilliseconds);

            return calloutRequest;
        }

        private void setConfiguration(ChatProviderConfiguration configuration) {
            this.configuration = configuration;
        }
    }

    // Chat configuration classes - details for each provider are stored as JSON in the field LoggerParameter__mdt.Value__c
    public class ChatProviderConfiguration {
        @AuraEnabled
        public String DeveloperName { get; set; }
        @AuraEnabled
        public Boolean IsEnabled = false;
        @AuraEnabled
        public Boolean IsLoggingEnabled = false;
        @AuraEnabled
        public String Label { get; set; }
        @AuraEnabled
        public ChatProviderMetadata Metadata { get; set; }
        @AuraEnabled
        public ChatProviderTermsOfUse TermsOfUse { get; set; }

        // TODO remove for the initial release? Or keep??
        @AuraEnabled
        public Map<String, String> DefaultParameters { get; set; }
    }

    public class ChatProviderMetadata {
        @AuraEnabled
        public String ApexClassName { get; set; }
        @AuraEnabled
        public String NamedCredentialDeveloperName { get; set; }
    }

    public class ChatProviderTermsOfUse {
        @AuraEnabled
        public String Text { get; set; }
    }

    public class ChatProviderModel {
        @AuraEnabled
        public String Label { get; set; }
        // TODO rename Name to DeveloperName (LWC needs to be updated too)
        @AuraEnabled
        public String Name { get; set; }
    }

    // Actual chat classes
    public class ChatThread {
        @AuraEnabled
        public String ChatId { get; set; }
        // TODO decide if this makes sense here - it was added as extra context for logging/JSON.serializePretty(chatThread)
        // (it doesn't feel like it belongs here, yet Model is here... hmmm)
        @AuraEnabled
        public String ChatProviderDeveloperName { get; set; }
        @AuraEnabled
        public List<ChatMessage> Messages {
            get {
                if (Messages == null) {
                    Messages = new List<ChatMessage>();
                }
                return Messages;
            }
            set;
        }
        @AuraEnabled
        public String Model { get; set; }

        public ChatThread() {
            this.Messages = new List<ChatMessage>();
        }
    }

    public class ChatMessage {
        @AuraEnabled
        public Datetime CreatedDate { get; set; }
        @AuraEnabled
        public String Role { get; set; }
        @AuraEnabled
        public String Text { get; set; }

        public ChatMessage() {
            this.CreatedDate = System.now();
        }

        public ChatMessage(ChatRoleType roleType, String text) {
            this();
            this.Role = roleType.name().toLowerCase();
            this.Text = text;
        }
    }

    // Static methods
    public static Map<String, ChatProvider> getChatProviders() {
        return PROVIDER_NAME_TO_PROVIDER;
    }

    private static Map<String, ChatProvider> loadEnabledChatProviders() {
        Map<String, ChatProvider> providerNameToProvider = new Map<String, ChatProvider>();
        // TODO revist if matchOnPrefix() is the best option, or a new field on LoggerParameter__mdt
        for (LoggerParameter__mdt loggerProviderParameter : LoggerParameter.matchOnPrefix('ChatProvider')) {
            ChatProviderConfiguration configuration = (ChatProviderConfiguration) JSON.deserialize(
                loggerProviderParameter.Value__c,
                ChatProviderConfiguration.class
            );
            if (configuration.IsEnabled && configuration.Metadata?.ApexClassName != null) {
                System.Type providerSystemType = System.Type.forName(configuration.Metadata.ApexClassName);
                if (providerSystemType == null) {
                    continue;
                }

                ChatProvider provider = (ChatProvider) providerSystemType.newInstance();
                provider.setConfiguration(configuration);
                providerNameToProvider.put(configuration.DeveloperName, provider);
            }
        }
        return providerNameToProvider;
    }

    // ChatGPT models
    private class OpenAIChatGPTModelsResponse {
        public List<OpenAIChatGPTModel> data = new List<OpenAIChatGPTModel>();
    }

    private class OpenAIChatGPTModel {
        public Long created;
        public String id;
        public String owned_by;
    }

    // ChatGPT chat
    private class OpenAIChatGPTMessage {
        public String content;
        public String role;
    }

    private class OpenAIChatGPTChatRequest {
        public String model;
        public List<OpenAIChatGPTMessage> messages = new List<OpenAIChatGPTMessage>();
    }

    private class OpenAIChatGPTChatResponse {
        public String id;
        // public String object;
        public Long created;
        public String model;
        // public String system_fingerprint;
        public List<OpenAIChatGPTMessageChoice> choices = new List<OpenAIChatGPTMessageChoice>();
    }

    private class OpenAIChatGPTMessageChoice {
        public Integer index;
        public OpenAIChatGPTMessage message;
    }

    // TODO this may need to be promoted to global to work in the managed package
    public class OpenAIChatGPTService extends ChatProvider {
        public override List<ChatProviderModel> getModels() {
            System.HttpRequest calloutRequest = this.buildHttpRequest('GET', '/v1/models');
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            OpenAIChatGPTModelsResponse modelsResponse = (OpenAIChatGPTModelsResponse) JSON.deserialize(
                calloutResponse.getBody(),
                OpenAIChatGPTModelsResponse.class
            );

            List<ChatProviderModel> convertedModels = new List<ChatProviderModel>();
            for (OpenAIChatGPTModel openAIModel : modelsResponse.data) {
                if (openAIModel.owned_by != 'openai') {
                    // if (openAIModel.id?.startsWith('gpt') == false) {
                    continue;
                }

                ChatProviderModel convertedModel = new ChatProviderModel();
                convertedModel.Label = openAIModel.id;
                convertedModel.Name = openAIModel.id;
                convertedModels.add(convertedModel);
            }

            if (this.getConfiguration().IsLoggingEnabled) {
                // TODO relate this to a parent log, but in the LoggerChatBotController
                Logger.debug(JSON.serializePretty(convertedModels)).setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
                Logger.saveLog();
            }

            return convertedModels;
        }

        public override ChatThread sendChat(ChatThread chatThread) {
            OpenAIChatGPTChatRequest chatGptChatRequest = new OpenAIChatGPTChatRequest();
            chatGptChatRequest.model = chatThread.Model;
            chatGptChatRequest.messages = this.convertMessages(chatThread.Messages);

            System.HttpRequest calloutRequest = this.buildHttpRequest('POST', '/v1/chat/completions', chatGptChatRequest);
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            OpenAIChatGPTChatResponse chatGptResponse = (OpenAIChatGPTChatResponse) JSON.deserialize(
                calloutResponse.getBody(),
                OpenAIChatGPTChatResponse.class
            );

            chatThread.ChatId = chatGptResponse.id;
            chatThread.ChatProviderDeveloperName = this.getConfiguration().DeveloperName;
            if (chatGptResponse.choices != null && chatGptResponse.choices.size() > 0) {
                ChatMessage returnedBotChatMessage = new ChatMessage(ChatRoleType.BOT, chatGptResponse.choices.get(0).message.content);
                Integer millisecondsInOneSecond = 1000;
                returnedBotChatMessage.CreatedDate = Datetime.newInstance(chatGptResponse.created * millisecondsInOneSecond);
                chatThread.Messages.add(returnedBotChatMessage);
            } else {
                // TODO improve error handling
                throw new System.CalloutException('I dunno, something broke, probably.\n' + calloutResponse.getBody());
            }

            if (this.getConfiguration().IsLoggingEnabled) {
                // TODO relate this to a parent log, but in the LoggerChatBotController
                Logger.debug(JSON.serializePretty(chatThread)).setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
                Logger.saveLog();
            }

            return chatThread;
        }

        private List<OpenAIChatGPTMessage> convertMessages(List<ChatMessage> messages) {
            List<OpenAIChatGPTMessage> convertedMessages = new List<OpenAIChatGPTMessage>();
            for (ChatMessage message : messages) {
                OpenAIChatGPTMessage convertedMessage = new OpenAIChatGPTMessage();
                convertedMessage.content = message.Text;
                switch on message.Role {
                    when 'bot' {
                        convertedMessage.role = 'assistant';
                    }
                    when 'user' {
                        convertedMessage.role = 'user';
                    }
                }
                convertedMessages.add(convertedMessage);
            }
            return convertedMessages;
        }
    }

    // Google Gemini-specific classes
    // https://ai.google.dev/tutorials/rest_quickstart

    // TODO this may need to be promoted to global to work in the managed package
    public class GoogleGeminiService extends ChatProvider {
        public override List<ChatProviderModel> getModels() {
            System.HttpRequest calloutRequest = this.buildHttpRequest('GET', '/v1/models');
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            GoogleGeminiModelsResponse modelsResponse = (GoogleGeminiModelsResponse) JSON.deserialize(
                calloutResponse.getBody(),
                GoogleGeminiModelsResponse.class
            );
            if (this.getConfiguration().IsLoggingEnabled) {
                // TODO relate this to a parent log, but in the LoggerChatBotController
                Logger.debug('deserialized modelsResponse:\n' + JSON.serializePretty(modelsResponse));
            }
            List<ChatProviderModel> convertedModels = new List<ChatProviderModel>();
            for (GoogleGeminiModel geminiModel : modelsResponse.models) {
                if (new Set<String>(geminiModel.supportedGenerationMethods).contains('generateContent') == false) {
                    continue;
                }

                ChatProviderModel convertedModel = new ChatProviderModel();
                convertedModel.Label = geminiModel.displayName + ' (' + geminiModel.name.substringAfter('models/') + ')';
                convertedModel.Name = geminiModel.name;
                convertedModels.add(convertedModel);
            }

            if (this.getConfiguration().IsLoggingEnabled) {
                // TODO relate this to a parent log, but in the LoggerChatBotController
                // Logger.debug(JSON.serializePretty(convertedModels)).setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
                if (this.getConfiguration().IsLoggingEnabled) {
                    // TODO relate this to a parent log, but in the LoggerChatBotController
                }
                Logger.debug('got gemini models').setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
                Logger.saveLog();
            }

            return convertedModels;
        }

        public override ChatThread sendChat(LoggerChatBotService.ChatThread chatThread) {
            GoogleGeminiChatRequest geminiChatRequest = new GoogleGeminiChatRequest();
            geminiChatRequest.contents = this.convertMessages(chatThread.Messages);

            System.HttpRequest calloutRequest = this.buildHttpRequest('POST', '/v1/' + chatThread.Model + ':generateContent', geminiChatRequest);
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            if (this.getConfiguration().IsLoggingEnabled) {
                // TODO relate this to a parent log, but in the LoggerChatBotController
                Logger.debug('got a gemini response').setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
                Logger.saveLog();
            }
            GoogleGeminiChatResponse geminiChatResponse = (GoogleGeminiChatResponse) JSON.deserialize(
                calloutResponse.getBody(),
                GoogleGeminiChatResponse.class
            );

            chatThread.ChatProviderDeveloperName = this.getConfiguration().DeveloperName;
            if (geminiChatResponse?.candidates != null && geminiChatResponse.candidates.size() > 0) {
                ChatMessage returnedBotChatMessage = new ChatMessage(ChatRoleType.BOT, geminiChatResponse.candidates.get(0).content.parts.get(0).text);
                chatThread.Messages.add(returnedBotChatMessage);
            } else {
                // TODO improve error handling
                throw new System.CalloutException('I dunno, something broke, probably.\n' + calloutResponse.getBody());
            }

            if (this.getConfiguration().IsLoggingEnabled) {
                // TODO relate this to a parent log, but in the LoggerChatBotController
                Logger.debug(JSON.serializePretty(chatThread)).setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
                Logger.saveLog();
            }

            return chatThread;
        }

        private List<GoogleGeminiChatMessage> convertMessages(List<ChatMessage> messages) {
            List<GoogleGeminiChatMessage> convertedMessages = new List<GoogleGeminiChatMessage>();
            for (ChatMessage message : messages) {
                GoogleGeminiChatMessage convertedMessage = new GoogleGeminiChatMessage();
                GoogleGeminiChatMessagePart convertedMessagePart = new GoogleGeminiChatMessagePart();
                convertedMessagePart.text = message.Text;
                convertedMessage.parts.add(convertedMessagePart);
                switch on message.Role {
                    when 'bot' {
                        convertedMessage.role = 'model';
                    }
                    when 'user' {
                        convertedMessage.role = 'user';
                    }
                }
                convertedMessages.add(convertedMessage);
            }
            return convertedMessages;
        }
    }

    // Gemini models
    private class GoogleGeminiModelsResponse {
        public List<GoogleGeminiModel> models = new List<GoogleGeminiModel>();
    }

    private class GoogleGeminiModel {
        public String displayName;
        public String name;
        public List<String> supportedGenerationMethods;
    }

    // Gemini chat
    private class GoogleGeminiChatRequest {
        public List<GoogleGeminiChatMessage> contents = new List<GoogleGeminiChatMessage>();
    }

    private class GoogleGeminiChatResponse {
        public List<GoogleGeminiChatResponseCandidate> candidates;
    }

    private class GoogleGeminiChatResponseCandidate {
        public GoogleGeminiChatMessage content;
        public String role;
    }

    private class GoogleGeminiChatMessage {
        public List<GoogleGeminiChatMessagePart> parts = new List<GoogleGeminiChatMessagePart>();
        public String role;
    }

    private class GoogleGeminiChatMessagePart {
        public String text;
    }
}
