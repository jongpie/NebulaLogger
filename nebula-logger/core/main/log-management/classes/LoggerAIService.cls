public with sharing class LoggerAIService {
    public LoggerAIService() {

    }

    public static LoggerAIService getInstance() {
        return null;
    }

    private ChatService getDefaultChatService() {
        // Check some LoggerParameter__mdt record for a default... thing?
        //      - Should it be the name of the Apex class/type?
        //      - Or should it be the name of another LoggerParameter__mdt record, containing the service's config?
    }



    // Public classes, used as generic controls for any supported AI service provider
    public class ChatInputConfiguration {
        public String ApexChatServiceClass { get; set; }
        public Integer MaxTokens { get; set; }
        public String Model { get; set; }
        // public transient String NamedCredential { get; set; }
    }

    public class ChatInput {
        public ChatInputConfiguration Configuration { get; set;}
        public List<String> Prompts { get; set; }
    }

    public class ChatOutput {
        public ChatInput Input { get; set; }
        public String Response { get; set; }
    }

    public abstract class ChatService {
        public ChatInputConfiguration InputConfiguration { get; set; }
        public String Name { get; set; }

        public abstract ChatOutput sendChatMessages(ChatInput input);
    }


    // ChatGPT-specific classes, used as Nebula Logger's default provider out-of-the-box
    private class ChatGPTMessage {
        public String role;
        public String content;
    }

    private class ChatGPTRequest {
        public String model;
        public List<ChatGPTMessage> messages = new List<ChatGPTMessage>();
    }

    private class ChatGPTResponse {
        public String id;
        // public String object;
        public String model;
        public String system_fingerprint;
        public List<ChatGPTMessage> choices = new List<ChatGPTMessage>();
    }
    /*
    {
        "id": "chatcmpl-123",
        "object": "chat.completion",
        "created": 1677652288,
        "model": "gpt-3.5-turbo-0613",
        "system_fingerprint": "fp_44709d6fcb",
        "choices": [{
            "index": 0,
            "message": {
            "role": "assistant",
            "content": "\n\nHello there, how may I assist you today?",
            },
            "logprobs": null,
            "finish_reason": "stop"
        }],
        "usage": {
            "prompt_tokens": 9,
            "completion_tokens": 12,
            "total_tokens": 21
        }
    }

    */

    private class ChatGPTService extends ChatService {
        private String namedCredentialName = 'Some_Named_Credential';

        // Docs: https://platform.openai.com/docs/api-reference/chat
        public override ChatOutput sendChatMessages(ChatInput input) {
            ChatOutput output = new ChatOutput();
            output.Input = input;

            System.HttpRequest calloutRequest = new System.HttpRequest();
            calloutRequest.setMethod('GET');
            // TODO need to figure out what URL lives in named credential vs what gets appended here in code
            calloutRequest.setEndpoint(this.namedCredentialName);
            calloutRequest.setBody(JSON.serializePretty(input));

            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);

            ChatGPTResponse chatGptResponse = (ChatGPTResponse) JSON.deserialize(calloutResponse.getBody(), ChatGPTResponse.class);

            if (chatGptResponse.choices != null && chatGptResponse.choices.size() > 0){
                output.Response = chatGptResponse.choices.get(0).content;
            }
            // TODO
            /*
                curl https://api.openai.com/v1/chat/completions \
                            -H "Content-Type: application/json" \
                            -H "Authorization: Bearer $OPENAI_API_KEY" \
                            -d '{
                                "model": "gpt-3.5-turbo",
                                "messages": [
                                {
                                    "role": "system",
                                    "content": "You are a helpful assistant."
                                },
                                {
                                    "role": "user",
                                    "content": "Hello!"
                                }
                                ]
                            }'
            */

            return output;
        }
    }
}
