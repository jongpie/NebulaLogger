import { LightningElement, api, track } from 'lwc';
import LightningAlert from 'lightning/alert';
import getChatProviderConfigurations from '@salesforce/apex/LoggerChatBotController.getChatProviderConfigurations';
import getProviderModels from '@salesforce/apex/LoggerChatBotController.getProviderModels';
import startChatThread from '@salesforce/apex/LoggerChatBotController.startChatThread';
import sendChatThreadMessage from '@salesforce/apex/LoggerChatBotController.sendChatThreadMessage';
import saveChatThread from '@salesforce/apex/LoggerChatBotController.saveChatThread';

export default class LoggerChatBot extends LightningElement {
    @api
    recordId;

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

    get endChatLabel() {
        return this.selectedProvider?.ChatLog?.IsEnabled ? 'Save & End Chat' : 'End Chat';
    }

    async connectedCallback() {
        console.info('>>> starting connectedCallback(), this.recordId: ' + this.recordId);
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
                    providersPicklistOptions.push({
                        label: providerConfiguration.Label,
                        value: providerConfiguration.DeveloperName
                    });
                    this.aiProviders[providerConfiguration.DeveloperName] = providerConfiguration;
                });
                this.aiProviderOptions = providersPicklistOptions;
                this.aiProviderSupportedModelOptions = providerSupportedModelOptions;
                this.isLoading = false;
            })
            .catch(async error => {
                await LightningAlert.open({
                    label: 'Error!',
                    message: `Error loading chat provider configurations: ${JSON.stringify(error)}`,
                    theme: 'error'
                });
                console.error('>>> error loading chat provider configurations', error);
            });
    }

    async handleProviderChange(event) {
        console.info('>>> running handleProviderChange, event', event);
        const providerName = event.detail.value;
        this.selectedProviderModel = undefined;
        this.selectedProvider = providerName ? this.aiProviders[event.detail.value] : undefined;
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
            .catch(async error => {
                await LightningAlert.open({
                    label: 'Error!',
                    message: `Error loading chat provider models: ${JSON.stringify(error)}`,
                    theme: 'error'
                });
                console.error('>>> error loading chat provider models', error);
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

    async handleStartChat() {
        this.isLoading = true;
        this.chatStartMessage = `Chat started with ${this.selectedProvider.Label}`;
        // startChat(String providerName, String providerModelName, String initialPrompt) {
        const userPrompt = 'How to I write Apex??';
        // console.log('>>> Well, who is this.selectedProvider?!', this.selectedProvider);
        startChatThread({ providerDeveloperName: this.selectedProvider.DeveloperName, providerModelName: this.selectedProviderModel, userPrompt })
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
                    let liClass;
                    let contentClass;
                    let sentBySummary;
                    if (chatMessage.Role.toLowerCase() === 'user') {
                        liClass = 'slds-chat-listitem slds-chat-listitem_outbound';
                        contentClass = 'slds-chat-message__text slds-chat-message__text_outbound';
                        sentBySummary = `Me • ${chatMessage.CreatedDate}`;
                    } else {
                        liClass = 'slds-chat-listitem slds-chat-listitem_inbound';
                        contentClass = 'slds-chat-message__text slds-chat-message__text_inbound';
                        sentBySummary = `${this.selectedProviderModel} • ${chatMessage.CreatedDate}`;
                    }

                    convertedMessages.push({
                        id: 'message-' + chatMessageCounter++,
                        classes: {
                            li: liClass,
                            content: contentClass
                        },
                        content: chatMessage.Text,
                        sentBySummary
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
            .catch(async error => {
                await LightningAlert.open({
                    label: 'Error!',
                    message: `Error starting chat thread: ${JSON.stringify(error)}`,
                    theme: 'error'
                });
                console.error('>>> error starting chat thread', error);
                this.isLoading = false;
            });
    }

    handleUserMessageChange(event) {
        this.currentUserMessage = event.detail.value?.trim();
    }

    handleSendMessage() {
        this.isLoading = true;
        const userPrompt = this.currentUserMessage;
        this.template.querySelector('[data-id="message-input"]').value = undefined;
        this.currentUserMessage = undefined;
        const messageInputs = this.template.querySelectorAll('[data-id="message-input"]');
        messageInputs.forEach(messageInput => (messageInput.value = undefined));

        sendChatThreadMessage({
            providerDeveloperName: this.selectedProvider.DeveloperName,
            providerModelName: this.selectedProviderModel,
            userPrompt,
            chatThread: this.chatThread
        })
            .then(chatThread => {
                console.log('>>> called sendChatThreadMessage', chatThread);
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
            .catch(async error => {
                await LightningAlert.open({
                    label: 'Error!',
                    message: `Error starting chat thread: ${JSON.stringify(error)}`,
                    theme: 'error'
                });
                console.error('>>> error starting chat thread', error);
                this.isLoading = false;
            });

        // Set timeout (or similar approach) is needed because the updated messages
        // need to re-render in the component before the scrollHeight is recalculated
        setTimeout(() => {
            const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
            chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
        }, 0);
    }

    handleEndChat() {
        this.isLoading = true;
        saveChatThread({ recordId: this.recordId, chatThread: this.chatThread })
            .then(() => {
                this.hasAcceptedTermsOfUse = false;
                this.showChat = false;
                this.selectedProvider = undefined;
                this.selectedProviderModelOptions = undefined;
                this.selectedProviderModel = undefined;
                this.isLoading = false;
            })
            .catch(async error => {
                await LightningAlert.open({
                    label: 'Error!',
                    message: `Error starting chat thread: ${JSON.stringify(error)}`,
                    theme: 'error'
                });
                console.error('>>> error starting chat thread', error);
                this.isLoading = false;
            });
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
