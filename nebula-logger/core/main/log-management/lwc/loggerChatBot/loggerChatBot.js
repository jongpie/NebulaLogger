import { LightningElement, api, track } from 'lwc';
import LightningAlert from 'lightning/alert';
import getChatProviderConfigurations from '@salesforce/apex/LoggerChatBotController.getChatProviderConfigurations';
import getChatProviderModels from '@salesforce/apex/LoggerChatBotController.getChatProviderModels';
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
    selectedUserPromptType;
    showChat = false;
    showModal = false;
    title = '🦆 Rubber Duck Debugger Chat Bot-o-matic 5000 🦆';

    aiProviderOptions;
    aiProviderSupportedModelOptions;
    chatStartMessage;
    currentUserMessage;
    @track
    messages;

    get userPromptOptions() {
        return [
            { label: '--None--', value: '' },
            { label: 'Help me troubleshoot this exception', value: 'exception_insights' }
        ];
    }

    _userPrompts = {
        exception_insights: {
            label: 'Help me troubleshoot this exception'
        }
    };

    handleUserPromptChange(event) {
        this.selectedUserPromptType = event.detail.value;
        console.info('>>> this.selectedUserPromptType', this.selectedUserPromptType);
    }

    get isStartChatButtonDisabled() {
        return !this.selectedProvider || !this.selectedProviderModel || !this.selectedUserPromptType || !this.hasAcceptedTermsOfUse;
    }

    get isSendMessageButtonDisabled() {
        return !this.currentUserMessage?.trim();
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
        this.selectedUserPromptType = undefined;
        this.selectedProvider = providerName ? this.aiProviders[event.detail.value] : undefined;
        console.log('>>> this.selectedProvider', this.selectedProvider);
        if (!this.selectedProvider) {
            return;
        }

        this.isLoading = true;
        getChatProviderModels({ providerName: this.selectedProvider.DeveloperName })
            .then(providerModels => {
                console.log('>>> ran getChatProviderModels()', providerModels);
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
        // const userPrompt = 'How do I write Apex??';
        // console.log('>>> Well, who is this.selectedProvider?!', this.selectedProvider);
        console.log('>>> about to call sendChatThread', this.selectedUserPromptType);
        startChatThread({
            providerDeveloperName: this.selectedProvider.DeveloperName,
            providerModelName: this.selectedProviderModel,
            recordId: this.recordId,
            userPromptType: this.selectedUserPromptType
        })
            .then(chatThread => {
                console.log('>>> called sendChatThreadMessage', chatThread);
                this.chatThread = chatThread;

                const convertedMessages = [];
                chatThread.Messages.forEach(chatMessage => {
                    convertedMessages.push(this._convertChatMessageForMarkup(chatMessage));
                });

                this.messages = convertedMessages;
                this.showChat = true;
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

    handleUserMessageChange(event) {
        this.currentUserMessage = event.detail.value?.trim();
    }

    _addUserMessage(userPrompt) {
        // Create a UI version of the prompt message to display prior to actually
        // sending to the LLM, so the user knows what is being sent
        const serviceUserChatMessage = {
            CreatedDate: new Date(),
            Role: 'user',
            Text: userPrompt
        };
        this.messages.push(this._convertChatMessageForMarkup(serviceUserChatMessage));
    }

    handleSendMessage() {
        this.isLoading = true;
        const userPrompt = this.currentUserMessage;
        this.template.querySelector('[data-id="message-input"]').value = undefined;
        this._addUserMessage(userPrompt);
        this.showChat = true;
        this.currentUserMessage = undefined;
        const messageInputs = this.template.querySelectorAll('[data-id="message-input"]');
        messageInputs.forEach(messageInput => (messageInput.value = undefined));

        sendChatThreadMessage({
            // providerDeveloperName: this.selectedProvider.DeveloperName,
            // providerModelName: this.selectedProviderModel,
            userPrompt,
            chatThread: this.chatThread
        })
            .then(chatThread => {
                console.log('>>> called sendChatThreadMessage', chatThread);
                const convertedMessages = [];
                chatThread.Messages.forEach(chatMessage => {
                    console.log('>>> converting message', chatMessage);
                    convertedMessages.push(this._convertChatMessageForMarkup(chatMessage));
                });

                this.messages = convertedMessages;
                // this.showChat = true;
                this.isLoading = false;
                this._scrollToBottomOfChatThreadContainers();
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

    handleSaveChat() {
        this.isLoading = true;
        saveChatThread({ recordId: this.recordId, chatThread: this.chatThread })
            .then(() => {
                this.handleEndChat();
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

    handleEndChat() {
        this.hasAcceptedTermsOfUse = false;
        this.showChat = false;
        this.selectedProvider = undefined;
        this.selectedProviderModelOptions = undefined;
        this.selectedProviderModel = undefined;
        this.selectedUserPromptType = undefined;
    }

    handleShowModal() {
        this.currentUserMessage = undefined;
        const messageInputs = this.template.querySelectorAll('[data-id="message-input"]');
        messageInputs.forEach(messageInput => (messageInput.value = undefined));
        this.showModal = true;
        this._scrollToBottomOfChatThreadContainers();
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

    _convertChatMessageForMarkup(serviceChatMessage) {
        let liClass;
        let contentClass;
        let sentBySummary;
        const userLocaleCreatedDate = !serviceChatMessage.CreatedDate ? '' : new Date(serviceChatMessage.CreatedDate).toLocaleString();
        if (serviceChatMessage.Role.toLowerCase() === 'user') {
            liClass = 'slds-chat-listitem slds-chat-listitem_outbound';
            contentClass = 'slds-chat-message__text slds-chat-message__text_outbound';
            sentBySummary = `Me • ${userLocaleCreatedDate}`;
        } else {
            liClass = 'slds-chat-listitem slds-chat-listitem_inbound';
            contentClass = 'slds-chat-message__text slds-chat-message__text_inbound';
            sentBySummary = `${this.selectedProviderModel} • ${userLocaleCreatedDate}`;
        }

        const convertedMessage = {
            // id: 'message-' + chatMessageCounter++,
            classes: {
                li: liClass,
                content: contentClass
            },
            content: serviceChatMessage.Text,
            sentBySummary
        };

        return convertedMessage;
    }

    _scrollToBottomOfChatThreadContainers() {
        // Set timeout (or similar approach) is needed because the updated messages
        // need to re-render in the component before the scrollHeight is recalculated
        /* eslint-disable @lwc/lwc/no-async-operation */
        setTimeout(() => {
            const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
            chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
        }, 0);
    }
}
