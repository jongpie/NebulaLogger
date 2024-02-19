public with sharing class LoggerLLMService {
    private static final String CHAT_GPT_NAMED_CREDENTIAL = 'LoggerOpenAI';

    public enum AIServiceProvider {
        CHAT_GPT,
        EINSTEIN
    }

    // public class AIPromptInputConfiguration {
    //     // TODO should the CMDT records just store Map<String, Object>
    //     // for any provider-specific parameters?
    //     public Integer MaxTokens { get; set; }
    //     public String Model { get; set; }
    // }
    public class AIPromptProvider {
        public String ApexClassName { get; set; }
        public String Label { get; set; }
        public String Name { get; set; }
        public String NamedCredential { get; set; }
    }

    public class AIPromptInputConfiguration {
        // TODO should the CMDT records just store Map<String, Object>
        // for any provider-specific parameters?
        public Boolean IsEnabled { get; set; }
        public AIPromptProvider Provider { get; set; }
        public Map<String, Object> ProviderParameters = new Map<String, Object>();
    }

    public class AIPromptMessage {
        public String ChatId { get; set; }
        public String Role { get; set; }
        public String Content { get; set; }
    }

    public class AIPromptInput {
        public String ChatId { get; set; }
        public Map<String, Object> Configuration = new Map<String, Object>();
        // public AIPromptInputConfiguration Configuration { get; set; }
        public String Prompt { get; set; }
        public List<AIPromptMessage> Messages = new List<AIPromptMessage>(); // { get; set; }
    }

    public class AIPromptOutput {
        public AIPromptInput Input { get; set; }
        public String Response { get; set; }
        public List<AIPromptMessage> Messages = new List<AIPromptMessage>(); // { get; set; }
    }

    public abstract class AIChatService {
        public abstract AIPromptOutput sendMessage(AIPromptInput input);
    }

    public static AIPromptOutput sendMessage(AIServiceProvider provider, AIPromptInput input) {
        switch on provider {
            when CHAT_GPT {
                return new ChatGPTService(CHAT_GPT_NAMED_CREDENTIAL).sendMessage(input);
            }
            when else {
                throw new System.IllegalArgumentException('Not implemented!');
            }
        }
    }

    // ChatGPT-specific classes, used as Nebula Logger's default provider out-of-the-box
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

    private class ChatGPTService extends AIChatService {
        private String namedCredentialName;

        public ChatGPTService(String namedCredentialName) {
            this.namedCredentialName = namedCredentialName;
        }

        // Docs: https://platform.openai.com/docs/api-reference/chat
        public override AIPromptOutput sendMessage(AIPromptInput input) {
            AIPromptOutput output = new AIPromptOutput();
            output.Input = input;

            ChatGPTRequest chatGPTRequest = new ChatGPTRequest();
            chatGPTRequest.model = (String) input.Configuration.get('model');
            ChatGPTMessage chatGPTMessage = new ChatGPTMessage();
            chatGPTMessage.content = input.Prompt;
            chatGPTMessage.role = 'user';
            chatGPTRequest.messages.add(chatGPTMessage);

            System.HttpRequest calloutRequest = new System.HttpRequest();
            calloutRequest.setMethod('POST');
            // TODO need to figure out what URL lives in named credential vs what gets appended here in code
            // calloutRequest.setEndpoint('callout:' + this.namedCredentialName);
            calloutRequest.setEndpoint('callout:' + this.namedCredentialName + '/v1/chat/completions');
            // calloutRequest.setBody(JSON.serializePretty(input));
            calloutRequest.setBody(JSON.serializePretty(chatGPTRequest));

            System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
            Logger.debug('Called ChatGPT API').setHttpRequestDetails(calloutRequest).setHttpResponseDetails(calloutResponse);
            Logger.saveLog();

            ChatGPTResponse chatGptResponse = (ChatGPTResponse) JSON.deserialize(calloutResponse.getBody(), ChatGPTResponse.class);

            if (chatGptResponse.choices != null && chatGptResponse.choices.size() > 0) {
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

    // Source: https://unofficialsf.com/tap-into-the-power-of-chatgpt-via-flow/
    /* @invocableMethod
    public static List<openAiOutputs> connect(List<openAiInputs> inputs) {
        //defines the output list
        List<openAiOutputs> outputs = new List<openAiOutputs>();
        for (openAiInputs curInput : inputs) {
            String userInput = curInput.openaiInput;
            String instruction = curInput.openaiInstruction;
            String prompt = curInput.openaiPrompt;
            String model = curInput.settingsModel;
            Integer tokens = curInput.settingsTokens;
            Double temperature = curInput.settingsTemperature;
            String endpoint = curInput.settingsEndpoint;
            openAiOutputs output = new openAiOutputs();
            String openAiTextOutput = '';
            String openAiMessage = '';
            String finishReason = '';
            String replyID = '';
            Integer tokensUsed = 0;

            //set default values for prompt, model, tokens and maximum temperature if not provided by Flow
            if (prompt == '' || prompt == null) {
                prompt = userInput + ' ' + instruction;
            }
            if (model == null || model == '') {
                model = 'text-davinci-003';
                system.debug('Modell: ' + model);
            }
            if (tokens < 0 || tokens > 4096 || tokens == null) {
                tokens = 1000;
                system.debug('Tokens: ' + tokens);
            }
            if (temperature < 0 || temperature > 1 || temperature == null) {
                temperature = 0.1;
                system.debug('Temperature: ' + temperature);
            }
            System.HttpRequest req = new System.HttpRequest();
            //set the endpoint to the endpoint defined in named credentials of Salesforce
            req.setEndpoint('callout:' + endpoint + '/v1/completions');
            //set the timeout to 2 minutes
            req.setTimeout(120000);
            //define POST for method endpoint
            req.setMethod('POST');
            //set the body of the request
            req.setBody(
                '{"model": "' + model + '", "prompt": "' + prompt + '", "max_tokens": ' + tokens + ', "temperature": ' + temperature + ', "top_p": 0.2, "n": 1}'
            );
            //create a new HTTP object
            System.Http http = new System.Http();
            //send the request
            System.HttpResponse res = http.send(req);

            //create a new JSON parser
            JSONParser parser = JSON.createParser(res.getBody());
            //create variables to store the reason for finishing and the reply ID

            Logger.debug('Got a response from OpenAI').setHttpRequestDetails(req).setHttpResponseDetails(res);
            Logger.saveLog();

            //loop through the response
            while (parser.nextToken() != null) {
                //if the current token is a field name and the text is 'text'
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'text')) {
                    // Get the value.
                    parser.nextToken();
                    // Add the text to the output variable
                    output.openAiTextOutput = parser.getText();
                }
                //if the current token is a field name and the text is 'id'
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'id')) {
                    // Get the value.
                    parser.nextToken();
                    // Add the text to the output variable
                    output.replyID = parser.getText();
                }
                //if the current token is a field name and the text is 'finish_reason'
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'finish_reason')) {
                    // Get the value.
                    parser.nextToken();
                    // Add the text to the output variable
                    output.finishReason = parser.getText();
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'total_tokens')) {
                    // Get the value.
                    parser.nextToken();
                    // Add the integer to the output variable
                    output.tokensUsed = parser.getIntegerValue();
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'message')) {
                    // Get the value.
                    parser.nextToken();
                    // Add the integer to the output variable
                    openAiTextOutput = parser.getText();
                }
            }
            // Check the status code of the response
            if (res.getStatusCode() == 200) {
                System.debug('Response Body: ' + res.getBody());
                System.debug('ReplyID: ' + replyID);
                System.debug('finishReason: ' + finishReason);
                System.debug('tokensUsed: ' + tokensUsed);
            } else {
                output.openAiTextOutput = openAiMessage;
                System.debug('Error connecting to OpenAI: ' + res.getStatusCode() + '' + res.getStatus() + '' + res.getBody());
            }
            //add the output to the output list
            outputs.add(output);
        }
        //return the output list
        return outputs;
    }

    public class openAiInputs {
        @InvocableVariable(required=false label='Open AI Instruction' description='Is what the AI should do with the input')
        public String openaiInstruction;
        @InvocableVariable(required=false label='Open AI Input' description='Is the input into the AI model')
        public String openaiInput;
        @InvocableVariable(
            required=false
            label='Open AI Prompt'
            description='Is a composition of Input and Instruction. Leave empty if Input and Instruction are provided'
        )
        public String openaiPrompt;
        @InvocableVariable(required=false label='Open AI Model' description='Defines the model used of the AI.')
        public String settingsModel;
        @InvocableVariable(required=false label='Tokens' description='Maximum Tokens to be used.')
        public Integer settingsTokens;
        @InvocableVariable(required=false label='Temperature' description='Temperature of the model to be used.')
        public Double settingsTemperature;
        @InvocableVariable(required=false label='Open AI Endpoint Name' description='Endpoint to which you want to call.')
        public String settingsEndpoint;
    }
    public class openAiOutputs {
        @InvocableVariable(required=false label='Open AI Text Output' description='Provides the text response from OpenAI model as a String.')
        public String openAiTextOutput;
        @InvocableVariable(required=false label='ReplyId' description='ReplyID of the Ai response')
        public String replyID;
        @InvocableVariable(required=false label='Finish Reason' description='Reason the AI stopped responding')
        public String finishReason;
        @InvocableVariable(required=false label='Tokens Used' description='Amount of tokens used.')
        public Integer tokensUsed;
    }
 */
}
