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

        public abstract Map<String, ChatProviderModel> getModels();
        public abstract ChatThread sendChat(ChatThread chatThread);

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
            calloutRequest.setMethod(method);
            calloutRequest.setTimeout(thirtySecondsInMilliseconds);

            return calloutRequest;
        }

        protected Object sendHttpRequest(System.HttpRequest calloutRequest, System.Type returnType) {
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            Logger.fine('Sent chat to chat provider').setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
            return JSON.deserialize(calloutResponse.getBody(), returnType);
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
        public ChatLogConfiguration ChatLog {
            get {
                if (ChatLog == null) {
                    ChatLog = new ChatLogConfiguration();
                }
                return ChatLog;
            }
            set;
        }
        @AuraEnabled
        public ChatProviderMetadata Metadata {
            get {
                if (Metadata == null) {
                    Metadata = new ChatProviderMetadata();
                }
                return Metadata;
            }
            set;
        }
        @AuraEnabled
        public ChatProviderTermsOfUse TermsOfUse {
            get {
                if (TermsOfUse == null) {
                    TermsOfUse = new ChatProviderTermsOfUse();
                }
                return TermsOfUse;
            }
            set;
        }
    }

    public class ChatLogConfiguration {
        @AuraEnabled
        public Boolean IsEnabled = false;
        @AuraEnabled
        public String Scenario { get; set; }
        @AuraEnabled
        public List<String> Tags = new List<String>();
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
        public String DeveloperName { get; set; }
        @AuraEnabled
        public String Label { get; set; }
    }

    public class ChatProviderConnection {
        @AuraEnabled
        public ChatProviderConfiguration Configuration { get; set; }
        @AuraEnabled
        public String SelectedProviderModelName { get; set; }
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
        public ChatProviderConnection Connection { get; set; }

        // TODO revisit - should this be a string, or an object?
        // Which class handles sending it to each LLM?
        @AuraEnabled
        public String GroundingText { get; set; }

        // TODO revisit
        // @AuraEnabled
        // public ChatProviderConnection Connection { get; set; }
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

    // Google Gemini-specific classes
    // https://ai.google.dev/tutorials/rest_quickstart

    // TODO this may need to be promoted to global to work in the managed package
    public class GoogleGeminiService extends ChatProvider {
        public override Map<String, ChatProviderModel> getModels() {
            System.HttpRequest calloutRequest = this.buildHttpRequest('GET', '/v1/models');
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            // TODO add better error handling of JSON, as well as error-handling of errors
            // returned by the HTTP callout
            GoogleGeminiModelsResponse modelsResponse = (GoogleGeminiModelsResponse) this.sendHttpRequest(calloutRequest, GoogleGeminiModelsResponse.class);
            Map<String, ChatProviderModel> convertedModels = new Map<String, ChatProviderModel>();
            for (GoogleGeminiModel geminiModel : modelsResponse.models) {
                if (new Set<String>(geminiModel.supportedGenerationMethods).contains('generateContent') == false) {
                    continue;
                }

                String cleanedModelDeveloperName = geminiModel.name.startsWith('models/') ? geminiModel.name.substringAfter('models/') : geminiModel.name;
                ChatProviderModel convertedModel = new ChatProviderModel();
                convertedModel.DeveloperName = geminiModel.name;
                convertedModel.Label = geminiModel.displayName + ' (' + geminiModel.name.substringAfter('models/') + ')';
                convertedModels.put(geminiModel.name, convertedModel);
            }

            return convertedModels;
        }

        public override ChatThread sendChat(ChatThread chatThread) {
            GoogleGeminiChatRequest geminiChatRequest = new GoogleGeminiChatRequest();
            geminiChatRequest.contents = this.convertMessages(chatThread.Messages);

            System.HttpRequest calloutRequest = this.buildHttpRequest('POST', '/v1/' + chatThread.Model + ':generateContent', geminiChatRequest);
            // TODO add better error handling of JSON, as well as error-handling of errors
            // returned by the HTTP callout
            GoogleGeminiChatResponse geminiChatResponse = (GoogleGeminiChatResponse) this.sendHttpRequest(calloutRequest, GoogleGeminiChatResponse.class);
            if (geminiChatResponse?.candidates != null && geminiChatResponse.candidates.size() > 0) {
                Integer lastMessageIndex = geminiChatResponse.candidates.size() - 1;
                ChatMessage returnedBotChatMessage = new ChatMessage(
                    ChatRoleType.BOT,
                    geminiChatResponse.candidates.get(lastMessageIndex).content.parts.get(0).text
                );
                chatThread.Messages.add(returnedBotChatMessage);
            } else {
                // TODO improve backend error handling, probably
                // throw new System.CalloutException('I dunno, something broke, probably.\n' + calloutResponse.getBody());
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

    // TODO this may need to be promoted to global to work in the managed package
    public class OpenAIChatGPTService extends ChatProvider {
        public override Map<String, ChatProviderModel> getModels() {
            System.HttpRequest calloutRequest = this.buildHttpRequest('GET', '/v1/models');
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            // TODO add better error handling of JSON, as well as error-handling of errors
            // returned by the HTTP callout
            OpenAIChatGPTModelsResponse modelsResponse = (OpenAIChatGPTModelsResponse) this.sendHttpRequest(calloutRequest, OpenAIChatGPTModelsResponse.class);
            Map<String, ChatProviderModel> convertedModels = new Map<String, ChatProviderModel>();
            for (OpenAIChatGPTModel openAIModel : modelsResponse.data) {
                if (openAIModel.owned_by != 'openai') {
                    // if (openAIModel.id?.startsWith('gpt') == false) {
                    continue;
                }

                ChatProviderModel convertedModel = new ChatProviderModel();
                convertedModel.DeveloperName = openAIModel.id;
                convertedModel.Label = openAIModel.id;
                convertedModels.put(openAIModel.id, convertedModel);
            }

            return convertedModels;
        }

        public override ChatThread sendChat(ChatThread chatThread) {
            OpenAIChatGPTChatRequest chatGptChatRequest = new OpenAIChatGPTChatRequest();
            chatGptChatRequest.model = chatThread.Model;
            chatGptChatRequest.messages = this.convertMessages(chatThread.Messages);

            System.HttpRequest calloutRequest = this.buildHttpRequest('POST', '/v1/chat/completions', chatGptChatRequest);
            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            // TODO add better error handling of JSON, as well as error-handling of errors
            // returned by the HTTP callout
            OpenAIChatGPTChatResponse chatGptResponse = (OpenAIChatGPTChatResponse) this.sendHttpRequest(calloutRequest, OpenAIChatGPTChatResponse.class);
            chatThread.ChatId = chatGptResponse.id;
            // TODO make sure this handle elsewhere, using chatThread.Connection
            chatThread.ChatProviderDeveloperName = this.getConfiguration().DeveloperName;
            if (chatGptResponse.choices != null && chatGptResponse.choices.size() > 0) {
                ChatMessage returnedBotChatMessage = new ChatMessage(ChatRoleType.BOT, chatGptResponse.choices.get(0).message.content);
                Integer millisecondsInOneSecond = 1000;
                returnedBotChatMessage.CreatedDate = Datetime.newInstance(chatGptResponse.created * millisecondsInOneSecond);
                chatThread.Messages.add(returnedBotChatMessage);
            } else {
                // TODO improve backend error handling, probably
                throw new System.CalloutException('I dunno, something broke, probably.\n' + calloutResponse.getBody());
            }

            Logger.debug(JSON.serializePretty(chatThread)).setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
            Logger.saveLog();

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

    // Start of Google Gemini DTOs
    // Google Gemini models
    @TestVisible
    private class GoogleGeminiModelsResponse {
        public List<GoogleGeminiModel> models = new List<GoogleGeminiModel>();
    }

    @TestVisible
    private class GoogleGeminiModel {
        public String displayName;
        public String name;
        public List<String> supportedGenerationMethods = new List<String>();
    }

    // Google Gemini chat
    @TestVisible
    private class GoogleGeminiChatRequest {
        public List<GoogleGeminiChatMessage> contents = new List<GoogleGeminiChatMessage>();
    }

    @TestVisible
    private class GoogleGeminiChatResponse {
        public List<GoogleGeminiChatResponseCandidate> candidates = new List<GoogleGeminiChatResponseCandidate>();
    }

    @TestVisible
    private class GoogleGeminiChatResponseCandidate {
        public GoogleGeminiChatMessage content;
        public String role;
    }

    @TestVisible
    private class GoogleGeminiChatMessage {
        public List<GoogleGeminiChatMessagePart> parts = new List<GoogleGeminiChatMessagePart>();
        public String role;
    }

    @TestVisible
    private class GoogleGeminiChatMessagePart {
        public String text;
    }

    // Start of OpenAI ChatGPT DTOs
    // OpenAI ChatGPT models
    @TestVisible
    private class OpenAIChatGPTModelsResponse {
        public List<OpenAIChatGPTModel> data = new List<OpenAIChatGPTModel>();
    }

    @TestVisible
    private class OpenAIChatGPTModel {
        public Long created;
        public String id;
        public String owned_by;
    }

    // OpenAI ChatGPT chat
    @TestVisible
    private class OpenAIChatGPTMessage {
        public String content;
        public String role;
    }

    @TestVisible
    private class OpenAIChatGPTChatRequest {
        public String model;
        public List<OpenAIChatGPTMessage> messages = new List<OpenAIChatGPTMessage>();
    }

    @TestVisible
    private class OpenAIChatGPTChatResponse {
        public String id;
        public Long created;
        public String model;
        public List<OpenAIChatGPTMessageChoice> choices = new List<OpenAIChatGPTMessageChoice>();
    }

    @TestVisible
    private class OpenAIChatGPTMessageChoice {
        public Integer index;
        public OpenAIChatGPTMessage message;
    }
}
