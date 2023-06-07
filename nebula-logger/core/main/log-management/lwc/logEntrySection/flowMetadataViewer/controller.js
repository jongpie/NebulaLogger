import template from './template.html';

const FlowMetadataViewer = class {
    logEntryContext;

    setupParentController(parentController) {
        this.logEntry = parentController.logEntry;
        console.log('FlowMetadataViewer now has this.logEntry', this.logEntry);

        parentController.flowBuilderIframeStyle = this.flowBuilderIframeStyle;
        parentController.flowBuilderIframeUrl = this.flowBuilderIframeUrl;
        parentController.handleOpenFlowBuilder = this.handleOpenFlowBuilder;
        return this;
    }

    getTemplate() {
        console.log({ template });
        return template;
    }

    get flowBuilderIframeStyle() {
        const style = 'border: none; min-height: calc(100vh - 300px); width: 100%; overflow-y:scroll';
        console.log('>>> style', style);
        return style;
    }

    get flowBuilderIframeUrl() {
        const url = window.location.origin + '/builder_platform_interaction/flowBuilder.app?flowId=' + this.logEntry?.FlowActiveVersionId__c;
        console.log('>>> url', url);
        return url;
    }

    handleOpenFlowBuilder() {
        window.open(this.flowBuilderIframeUrl, '_blank');
    }
};

export function getDelegateController(parentController) {
    console.log('running FlowMetadataViewer.getDelegateController()', parentController);
    const controller = new FlowMetadataViewer();
    controller.setupParentController(parentController);
    console.log('finished running FlowMetadataViewer.getDelegateController()', parentController);
    return controller;
}
