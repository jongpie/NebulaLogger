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
            calloutRequest.setBody(JSON.serializePretty(body));
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
        public String Label { get; set; }
        @AuraEnabled
        public ChatProviderMetadata Metadata { get; set; }
        @AuraEnabled
        public ChatProviderTermsOfUse TermsOfUse { get; set; }
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
        public List<ChatMessage> Messages { get; set; }
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

        public ChatMessage(ChatRoleType roleType, String text) {
            this.CreatedDate = System.now();
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
        public String role;
        public String content;
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
                if (openAIModel.id?.startsWith('gpt') == false) {
                    continue;
                }

                ChatProviderModel convertedModel = new ChatProviderModel();
                convertedModel.Name = openAIModel.id;
                convertedModels.add(convertedModel);
            }

            Logger.debug(JSON.serializePretty(convertedModels)).setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
            Logger.saveLog();

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
                // FIXME this should work in Apex, but the conversion is always in 1970
                // Ex: 1708404603 results in 1970-01-20T18:33:24.735Z,
                // but https://www.epochconverter.com/ correctly says it should be 2/20/2024 4:51:41 GMT
                returnedBotChatMessage.CreatedDate = Datetime.newInstance(chatGptResponse.created);
                chatThread.Messages.add(returnedBotChatMessage);
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

    // Google Gemini-specific classes
    // https://ai.google.dev/tutorials/rest_quickstart

    /*
        List Models GET Request - https://generativelanguage.googleapis.com/v1beta/models?key=$API_KEY
        Response:
            {
                "models": [
                    {
                    "name": "models/chat-bison-001",
                    "version": "001",
                    "displayName": "Chat Bison",
                    "description": "Chat-optimized generative language model.",
                    "inputTokenLimit": 4096,
                    "outputTokenLimit": 1024,
                    "supportedGenerationMethods": [
                        "generateMessage",
                        "countMessageTokens"
                    ],
                    "temperature": 0.25,
                    "topP": 0.95,
                    "topK": 40
                    },
                    {
                    "name": "models/text-bison-001",
                    "version": "001",
                    "displayName": "Text Bison",
                    "description": "Model targeted for text generation.",
                    "inputTokenLimit": 8196,
                    "outputTokenLimit": 1024,
                    "supportedGenerationMethods": [
                        "generateText",
                        "countTextTokens",
                        "createTunedTextModel"
                    ],
                    "temperature": 0.7,
                    "topP": 0.95,
                    "topK": 40
                    },
                    {
                    "name": "models/embedding-gecko-001",
                    "version": "001",
                    "displayName": "Embedding Gecko",
                    "description": "Obtain a distributed representation of a text.",
                    "inputTokenLimit": 1024,
                    "outputTokenLimit": 1,
                    "supportedGenerationMethods": [
                        "embedText",
                        "countTextTokens"
                    ]
                    },
                    {
                    "name": "models/embedding-gecko-002",
                    "version": "002",
                    "displayName": "Embedding Gecko 002",
                    "description": "Obtain a distributed representation of a text.",
                    "inputTokenLimit": 2048,
                    "outputTokenLimit": 1,
                    "supportedGenerationMethods": [
                        "embedText",
                        "countTextTokens"
                    ]
                    },
                    {
                    "name": "models/gemini-pro",
                    "version": "001",
                    "displayName": "Gemini Pro",
                    "description": "The best model for scaling across a wide range of tasks",
                    "inputTokenLimit": 30720,
                    "outputTokenLimit": 2048,
                    "supportedGenerationMethods": [
                        "generateContent",
                        "countTokens"
                    ],
                    "temperature": 0.9,
                    "topP": 1,
                    "topK": 1
                    },
                    {
                    "name": "models/gemini-pro-vision",
                    "version": "001",
                    "displayName": "Gemini Pro Vision",
                    "description": "The best image understanding model to handle a broad range of applications",
                    "inputTokenLimit": 12288,
                    "outputTokenLimit": 4096,
                    "supportedGenerationMethods": [
                        "generateContent",
                        "countTokens"
                    ],
                    "temperature": 0.4,
                    "topP": 1,
                    "topK": 32
                    },
                    {
                    "name": "models/gemini-ultra",
                    "version": "001",
                    "displayName": "Gemini Ultra",
                    "description": "The most capable model for highly complex tasks",
                    "inputTokenLimit": 30720,
                    "outputTokenLimit": 2048,
                    "supportedGenerationMethods": [
                        "generateContent",
                        "countTokens"
                    ],
                    "temperature": 0.9,
                    "topP": 1,
                    "topK": 32
                    },
                    {
                    "name": "models/embedding-001",
                    "version": "001",
                    "displayName": "Embedding 001",
                    "description": "Obtain a distributed representation of a text.",
                    "inputTokenLimit": 2048,
                    "outputTokenLimit": 1,
                    "supportedGenerationMethods": [
                        "embedContent",
                        "countTextTokens"
                    ]
                    },
                    {
                    "name": "models/aqa",
                    "version": "001",
                    "displayName": "Model that performs Attributed Question Answering.",
                    "description": "Model trained to return answers to questions that are grounded in provided sources, along with estimating answerable probability.",
                    "inputTokenLimit": 7168,
                    "outputTokenLimit": 1024,
                    "supportedGenerationMethods": [
                        "generateAnswer"
                    ],
                    "temperature": 0.2,
                    "topP": 1,
                    "topK": 40
                    }
                ]
            }
    */

    /*
        Count Tokens POST Request - https://ai.google.dev/tutorials/rest_quickstart#count_tokens

    */

    private class GeminiMessagePart {
        public String text;
    }

    private class GeminiMessage {
        public String role;
        public List<GeminiMessagePart> parts;
    }

    private class GeminiMessageRequest {
        public List<GeminiMessage> contents;
    }

    /*
        Chat POST Request - https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$API_KEY
        {
            "contents": [
                {
                "role": "user",
                "parts": [
                    {
                    "text": "Write the first line of a story about a magic backpack."
                    }
                ]
                },
                {
                "role": "model",
                "parts": [
                    {
                    "text": "In the bustling city of Meadow brook, lived a young girl named Sophie. She was a bright and curious soul with an imaginative mind."
                    }
                ]
                },
                {
                "role": "user",
                "parts": [
                    {
                    "text": "Can you set it in a quiet village in 1600s France?"
                    }
                ]
                }
            ]
        }
    */
}
