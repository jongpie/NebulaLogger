import { LightningElement, track } from 'lwc';
import getChatProviderConfigurations from '@salesforce/apex/LoggerChatBotController.getChatProviderConfigurations';
import getProviderModels from '@salesforce/apex/LoggerChatBotController.getProviderModels';
import sendChatThreadMessage from '@salesforce/apex/LoggerChatBotController.sendChatThreadMessage';
import sendChat from '@salesforce/apex/LoggerChatBotController.sendChat';

export default class LoggerChatBot extends LightningElement {
    hasAcceptedTermsOfUse = false;
    isLoading = false;
    selectedProvider;
    selectedProviderModelOptions;
    selectedProviderModel;
    showChat = false;
    showModal = false;
    title = 'Logger AI Chat';

    aiProviderOptions;
    aiProviderSupportedModelOptions;
    chatStartMessage;
    currentUserMessage;
    @track
    messages;

    // isSendMessageButtonDisabled = true;

    get isStartChatButtonDisabled() {
        return !this.selectedProvider || !this.selectedProviderModel || !this.hasAcceptedTermsOfUse;
    }

    get isSendMessageButtonDisabled() {
        return !this.currentUserMessage?.trim();
    }

    connectedCallback() {
        console.info('>>> starting connectedCallback()');
        this.isLoading = true;
        getChatProviderConfigurations()
            .then(results => {
                this.aiProviders = {};
                const providersPicklistOptions = [{ label: '--None--', value: '' }];
                console.info('>>> processing provider parameters', results, results.ChatGPT.Label);
                // console.info('>>> cloned', JSON.parse(JSON.stringify(results)));

                const providerConfigurations = Object.values(results);
                providerConfigurations.sort((a, b) => {
                    const fa = a.Label.toLowerCase();
                    const fb = b.Label.toLowerCase();
                    if (fa < fb) {
                        return -1;
                    }
                    if (fa > fb) {
                        return 1;
                    }
                    return 0;
                });
                console.info('>>> sorted provider parameters', providerConfigurations);
                const providerSupportedModelOptions = {};

                providerConfigurations.forEach(providerConfiguration => {
                    console.info('>>> processing a provider configuration ', providerConfiguration);
                    // console.info('>>> processing a provider details ', result.Provider);
                    // console.info('>>> processing a provider supported models ', result.SupportedModels);
                    // console.info('>>> processing a provider Value__c ', result.Value__c);
                    // const teeeeemp = result.Value__c;
                    // console.info('>>> teeeeemp ', teeeeemp);
                    // console.info('>>> processing a provider paaaarse Value__c ', JSON.parse(result.Value__c));
                    // // TODO handle namespacing
                    // const providerConfiguration = JSON.parse(result.Value__c);
                    // providerSupportedModelOptions[result.DeveloperName] = [{ label: '--None--', value: '' }];
                    // result.SupportedModels.forEach(supportedModel => {
                    //     console.info('>>> converted supportedModel', supportedModel);
                    //     providerSupportedModelOptions[result.DeveloperName].push({ label: supportedModel, value: supportedModel });
                    // });
                    console.log('>>> created providerSupportedModelOptions', providerSupportedModelOptions);
                    providersPicklistOptions.push({
                        label: providerConfiguration.Label,
                        value: providerConfiguration.DeveloperName
                    });
                    this.aiProviders[providerConfiguration.DeveloperName] = providerConfiguration;
                });
                this.aiProviderOptions = providersPicklistOptions;
                this.aiProviderSupportedModelOptions = providerSupportedModelOptions;
                console.info('>>> loaded provider option', this.aiProviderOptions);
                console.info('>>> loaded provider supported models options', this.aiProviderSupportedModelOptions);
                this.isLoading = false;
            })
            .catch(error => {
                // TODO improve frontend error handling, including displaying errors to users,
                // with lightning base components & slds chat classes
                console.error('>>> error loading chat provider configurations', error);
                alert('>>> error loading chat provider configurations');
            });
    }

    handleProviderChange(event) {
        console.info('>>> running handleProviderChange, event', event);
        const providerName = event.detail.value;
        this.selectedProviderModel = undefined;
        this.selectedProvider = providerName ? this.aiProviders[event.detail.value] : undefined;
        // this.selectedProviderModelOptions = providerName ? this.aiProviderSupportedModelOptions[this.selectedProvider.DeveloperName] : undefined;
        console.log('>>> this.selectedProvider', this.selectedProvider);
        if (!this.selectedProvider) {
            return;
        }

        this.isLoading = true;
        getProviderModels({ providerName: this.selectedProvider.DeveloperName })
            .then(providerModels => {
                console.log('>>> ran getProviderModels()', providerModels);
                const providerModelOptions = [{ label: '--None--', value: '' }];
                providerModels.forEach(providerModel => {
                    const modelLabel = providerModel.Label ?? providerModel.DeveloperName;
                    providerModelOptions.push({ label: modelLabel, value: providerModel.DeveloperName });
                });
                this.selectedProviderModelOptions = providerModelOptions;
                this.isLoading = false;
            })
            .catch(error => {
                // TODO improve frontend error handling, including displaying errors to users with lightning base components & slds chat classes
                console.error('>>> error loading chat provider models', error);
                alert('>>> error loading chat provider models');
                this.isLoading = false;
            });
    }

    handleProviderModelChange(event) {
        console.info('>>> running handleProviderModelChange, event', event);
        this.selectedProviderModel = event.detail.value;
    }

    handleAcceptTermsOfUse(event) {
        console.info('>>> handleAcceptTermsOfUse', event, event.detail.checked);
        this.hasAcceptedTermsOfUse = event.detail.checked;
    }

    handleStartChat() {
        this.isLoading = true;
        this.chatStartMessage = `Chat started with ${this.selectedProvider.Label}`;
        // startChat(String providerName, String providerModelName, String initialPrompt) {
        const userPrompt = 'How to I write Apex??';
        // console.log('>>> Well, who is this.selectedProvider?!', this.selectedProvider);
        sendChatThreadMessage({ providerDeveloperName: this.selectedProvider.DeveloperName, providerModelName: this.selectedProviderModel, userPrompt })
            .then(chatThread => {
                console.log('>>> called sendChatThreadMessage', chatThread);
                this.chatThread = chatThread;
                console.log('>>> called this.chatThread', this.chatThread);
                // chatThread.Messages.push(userPromptMessage);
                // TODO process each message & add corresponding CSS classes, etc.
                // this.messages = chatThread.Messages;
                const convertedMessages = [];
                let chatMessageCounter = 0;
                chatThread.Messages.forEach(chatMessage => {
                    const liClass =
                        chatMessage.Role.toLowerCase() === 'user'
                            ? 'slds-chat-listitem slds-chat-listitem_outbound'
                            : 'slds-chat-listitem slds-chat-listitem_inbound';
                    const contentClass =
                        chatMessage.Role.toLowerCase() === 'user'
                            ? 'slds-chat-message__text slds-chat-message__text_outbound'
                            : 'slds-chat-message__text slds-chat-message__text_inbound';
                    convertedMessages.push({
                        id: 'message-' + chatMessageCounter++,
                        classes: {
                            // li: 'slds-chat-listitem slds-chat-listitem_outbound',
                            li: liClass,
                            // content: 'slds-chat-message__text slds-chat-message__text_outbound'
                            content: contentClass
                        },
                        content: chatMessage.Text,
                        // sentBySummary: 'Me • 5:01 PM',
                        sentBySummary: 'TODO'
                    });
                });

                this.messages = convertedMessages;
                this.showChat = true;
                this.isLoading = false;

                setTimeout(() => {
                    const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
                    chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
                }, 0);
            })
            .catch(error => {
                // TODO improve frontend error handling, including displaying errors to users with lightning base components & slds chat classes
                console.error('>>> error starting chat thread', error);
                alert('>>> error starting chat thread');
                this.isLoading = false;
            });

        // this.messages = [
        //     {
        //         id: 'some-value-1',
        //         classes: {
        //             li: 'slds-chat-listitem slds-chat-listitem_outbound',
        //             content: 'slds-chat-message__text slds-chat-message__text_outbound'
        //         },
        //         content: 'some user prompt',
        //         sentBySummary: 'Me • 5:01 PM',
        //         role: 'user'
        //     },
        //     {
        //         id: 'some-value-2',
        //         classes: {
        //             li: 'slds-chat-listitem slds-chat-listitem_inbound',
        //             content: 'slds-chat-message__text slds-chat-message__text_inbound'
        //         },
        //         content: 'some LLM AI GPT response',
        //         sentBySummary: `${this.selectedProvider.DeveloperName} • 5:01 PM`,
        //         role: 'bot'
        //     }
        // ];
    }

    handleUserMessageChange(event) {
        this.currentUserMessage = event.detail.value?.trim();
        // Disable the button if the user has not entered a value (or they've cleared the value)
        // this.isSendMessageButtonDisabled = !event.detail.value?.trim();
    }

    handleEndChat() {
        this.hasAcceptedTermsOfUse = false;
        this.showChat = false;
        this.selectedProvider = undefined;
        this.selectedProviderModelOptions = undefined;
        this.selectedProviderModel = undefined;
    }

    handleSendMessage() {
        this.isLoading = true;
        // const userMessageText = this.template.querySelector('[data-id="message-input"]').value;
        const userPrompt = this.currentUserMessage;
        this.template.querySelector('[data-id="message-input"]').value = undefined;
        this.currentUserMessage = undefined;
        const messageInputs = this.template.querySelectorAll('[data-id="message-input"]');
        messageInputs.forEach(messageInput => (messageInput.value = undefined));
        // this.isSendMessageButtonDisabled = true;

        console.info('>>> chatThread: this.chatThread', this.chatThread);
        console.info('>>> chatThread: this.chatThread.Messages', this.chatThread.Messages);

        const clonedChatThread = { ...this.chatThread };
        clonedChatThread.Messages = [...this.chatThread.Messages];
        console.info('>>> clonedChatThread:', clonedChatThread);
        console.info('>>> JSON.stringify(clonedChatThread):', JSON.stringify(clonedChatThread));

        sendChatThreadMessage({
            providerDeveloperName: this.selectedProvider.DeveloperName,
            providerModelName: this.selectedProviderModel,
            userPrompt,
            // chatThreadJSON: JSON.stringify(clonedChatThread)
            // chatThreadJSON: JSON.stringify(this.chatThread)
            // chatThread: JSON.parse(JSON.stringify(this.chatThread))
            chatThread: this.chatThread

            // chatThread: this.chatThread
        })
            .then(chatThread => {
                console.log('>>> called sendChatThreadMessage', chatThread);
                // chatThread.Messages.push(userPromptMessage);
                // TODO process each message & add corresponding CSS classes, etc.
                // this.messages = chatThread.Messages;
                const convertedMessages = [];
                let chatMessageCounter = 0;
                chatThread.Messages.forEach(chatMessage => {
                    const liClass =
                        chatMessage.Role.toLowerCase() === 'user'
                            ? 'slds-chat-listitem slds-chat-listitem_outbound'
                            : 'slds-chat-listitem slds-chat-listitem_inbound';
                    const contentClass =
                        chatMessage.Role.toLowerCase() === 'user'
                            ? 'slds-chat-message__text slds-chat-message__text_outbound'
                            : 'slds-chat-message__text slds-chat-message__text_inbound';
                    convertedMessages.push({
                        id: 'message-' + chatMessageCounter++,
                        classes: {
                            // li: 'slds-chat-listitem slds-chat-listitem_outbound',
                            li: liClass,
                            // content: 'slds-chat-message__text slds-chat-message__text_outbound'
                            content: contentClass
                        },
                        content: chatMessage.Text,
                        // sentBySummary: 'Me • 5:01 PM',
                        sentBySummary: 'TODO'
                    });
                });

                this.messages = convertedMessages;
                this.showChat = true;
                this.isLoading = false;

                setTimeout(() => {
                    const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
                    chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
                }, 0);
            })
            .catch(error => {
                // TODO improve frontend error handling, including displaying errors to users with lightning base components & slds chat classes
                console.error('>>> error starting chat thread', error);
                alert('>>> error starting chat thread');
                this.isLoading = false;
            });
        // const updatedMessages = [...this.messages];
        // updatedMessages.push(
        //     {
        //         id: 'some-value-3',
        //         classes: {
        //             li: 'slds-chat-listitem slds-chat-listitem_outbound',
        //             content: 'slds-chat-message__text slds-chat-message__text_outbound'
        //         },
        //         content: userMessageText,
        //         sentBySummary: 'Me • 4:57 PM',
        //         role: 'user'
        //     },
        //     {
        //         id: 'some-value-4',
        //         classes: {
        //             li: 'slds-chat-listitem slds-chat-listitem_inbound',
        //             content: 'slds-chat-message__text slds-chat-message__text_inbound'
        //         },
        //         content: 'yet another LLM AI GPT response',
        //         sentBySummary: `${this.selectedProvider.DeveloperName} • 4:57 PM`,
        //         role: 'bot'
        //     }
        // );
        // this.messages = updatedMessages;
        // console.info('>>> updated messages!', updatedMessages, this.messages);

        // this.isLoading = false;

        // Set timeout (or similar approach) is needed because the updated messages
        // need to re-render in the component before the scrollHeight is recalculated
        setTimeout(() => {
            const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
            chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
        }, 0);
    }

    handleShowModal() {
        this.currentUserMessage = undefined;
        const messageInputs = this.template.querySelectorAll('[data-id="message-input"]');
        messageInputs.forEach(messageInput => (messageInput.value = undefined));
        this.showModal = true;
        setTimeout(() => {
            const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
            chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
        }, 0);
    }

    handleHideModal() {
        this.currentUserMessage = undefined;
        const messageInputs = this.template.querySelectorAll('[data-id="message-input"]');
        messageInputs.forEach(messageInput => (messageInput.value = undefined));
        this.showModal = false;
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.handleHideModal();
        }
    }
}
