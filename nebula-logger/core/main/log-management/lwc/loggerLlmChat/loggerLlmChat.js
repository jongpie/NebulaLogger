import { LightningElement, track } from 'lwc';
import getProviderConfigurations from '@salesforce/apex/LoggerLlmChatController.getProviderConfigurations';

export default class LoggerLlmChat extends LightningElement {
    hasAcceptedTermsOfUse = false;
    isLoaded = false;
    selectedProvider;
    selectedProviderModelOptions;
    selectedProviderModel;
    showChat = false;
    showModal = false;
    title = 'Logger AI Chat';

    aiProviderOptions;
    aiProviderSupportedModelOptions;
    chatStartMessage;
    @track
    messages;

    get isInsightsButtonDisabled() {
        return !this.selectedProvider || !this.selectedProviderModel || !this.hasAcceptedTermsOfUse;
    }

    connectedCallback() {
        console.info('>>> starting connectedCallback()');
        getProviderConfigurations()
            .then(results => {
                this.aiProviders = {};
                const providersPicklistOptions = [{ label: '--None--', value: '' }];
                console.info('>>> processing provider parameters', results);
                results.sort((a, b) => {
                    const fa = a.Provider.Label.toLowerCase();
                    const fb = b.Provider.Label.toLowerCase();
                    if (fa < fb) {
                        return -1;
                    }
                    if (fa > fb) {
                        return 1;
                    }
                    return 0;
                });
                console.info('>>> sorted provider parameters', results);
                const providerSupportedModelOptions = {};

                results.forEach(result => {
                    console.info('>>> processing a provider configuration ', result);
                    console.info('>>> processing a provider details ', result.Provider);
                    console.info('>>> processing a provider supported models ', result.Provider.SupportedModels);
                    // console.info('>>> processing a provider Value__c ', result.Value__c);
                    // const teeeeemp = result.Value__c;
                    // console.info('>>> teeeeemp ', teeeeemp);
                    // console.info('>>> processing a provider paaaarse Value__c ', JSON.parse(result.Value__c));
                    // // TODO handle namespacing
                    // const providerConfiguration = JSON.parse(result.Value__c);
                    providerSupportedModelOptions[result.Provider.Name] = [{ label: '--None--', value: '' }];
                    result.Provider.SupportedModels.forEach(supportedModel => {
                        console.info('>>> converted supportedModel', supportedModel);
                        providerSupportedModelOptions[result.Provider.Name].push({ label: supportedModel, value: supportedModel });
                    });
                    console.log('>>> created providerSupportedModelOptions', providerSupportedModelOptions);
                    providersPicklistOptions.push({
                        label: result.Provider.Label,
                        value: result.Provider.Name
                    });
                    this.aiProviders[result.Provider.Name] = result.Provider;
                });
                this.aiProviderOptions = providersPicklistOptions;
                this.aiProviderSupportedModelOptions = providerSupportedModelOptions;
                console.info('>>> loaded provider option', this.aiProviderOptions);
                console.info('>>> loaded provider supported models options', this.aiProviderSupportedModelOptions);
                this.isLoaded = true;
            })
            .catch(error => console.error('>>> error loading provider parameters', error));
    }

    handleAcceptTermsOfUse(event) {
        console.info('>>> handleAcceptTermsOfUse', event, event.detail.checked);
        this.hasAcceptedTermsOfUse = event.detail.checked;
    }

    handleStartChat() {
        this.chatStartMessage = `Chat started with ${this.selectedProvider.Label}`;
        this.showChat = true;

        this.messages = [
            {
                id: 'some-value-1',
                classes: {
                    li: 'slds-chat-listitem slds-chat-listitem_outbound',
                    content: 'slds-chat-message__text slds-chat-message__text_outbound'
                },
                content: 'some user prompt',
                sentBySummary: 'Me • 5:01 PM',
                role: 'user'
            },
            {
                id: 'some-value-2',
                classes: {
                    li: 'slds-chat-listitem slds-chat-listitem_inbound',
                    content: 'slds-chat-message__text slds-chat-message__text_inbound'
                },
                content: 'some LLM AI GPT response',
                sentBySummary: `${this.selectedProvider.Name} • 5:01 PM`,
                role: 'assistant'
            }
        ];
    }

    handleEndChat() {
        this.hasAcceptedTermsOfUse = false;
        this.showChat = false;
        this.selectedProvider = undefined;
        this.selectedProviderModelOptions = undefined;
        this.selectedProviderModel = undefined;
    }

    handleViewConfiguration() {
        alert('TODO!');
    }

    handleSendMessage(event) {
        console.info('>>> running handleSendMessage()', event);
        const updatedMessages = [...this.messages];
        updatedMessages.push(
            {
                id: 'some-value-3',
                classes: {
                    li: 'slds-chat-listitem slds-chat-listitem_outbound',
                    content: 'slds-chat-message__text slds-chat-message__text_outbound'
                },
                content: 'another user question',
                sentBySummary: 'Me • 4:57 PM',
                role: 'user'
            },
            {
                id: 'some-value-4',
                classes: {
                    li: 'slds-chat-listitem slds-chat-listitem_inbound',
                    content: 'slds-chat-message__text slds-chat-message__text_inbound'
                },
                content: 'yet another LLM AI GPT response',
                sentBySummary: `${this.selectedProvider.Name} • 4:57 PM`,
                role: 'assistant'
            }
        );
        this.messages = updatedMessages;
        console.info('>>> updated messages!', updatedMessages, this.messages);

        // Set timeout (or similar approach) is needed because the updated messages
        // need to re-render in the component before the scrollHeight is recalculated
        setTimeout(() => {
            const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
            chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
        }, 0);
    }

    handleShowModal() {
        this.showModal = true;
        setTimeout(() => {
            const chatThreads = this.template.querySelectorAll('[data-id="chat-thread"]');
            chatThreads.forEach(chatThread => (chatThread.scrollTop = chatThread.scrollHeight));
        }, 0);
    }

    handleHideModal() {
        this.showModal = false;
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.handleHideModal();
        }
    }

    handleProviderChange(event) {
        console.info('>>> running handleProviderChange, event', event);
        const providerName = event.detail.value;
        this.selectedProviderModel = undefined;
        this.selectedProvider = providerName ? this.aiProviders[event.detail.value] : undefined;
        this.selectedProviderModelOptions = providerName ? this.aiProviderSupportedModelOptions[this.selectedProvider.Name] : undefined;
    }

    handleProviderModelChange(event) {
        console.info('>>> running handleProviderModelChange, event', event);
        this.selectedProviderModel = event.detail.value;
    }
}
