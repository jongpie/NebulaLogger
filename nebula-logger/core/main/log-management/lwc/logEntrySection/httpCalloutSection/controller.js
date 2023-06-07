import template from './template.html';

const HttpCalloutSection = class {
    logEntryContext;

    setupParentController(parentController) {
        console.log('running HttpCalloutSection.setupParentController()', parentController);
        this.logEntryContext = parentController.logEntryContext;
        parentController.showComponent = this.showComponent;
        console.log('HttpCalloutSection now has this.logEntryContext', this.logEntryContext);
        return this;
    }

    getTemplate() {
        console.log({ template });
        return template;
    }

    get showComponent() {
        const showComponentResult = true; // !!this.logEntryContext?.logEntry;
        console.log('>>>> got showComponentResult', { showComponentResult });
        return showComponentResult;
    }
};

export function getDelegateController(parentController) {
    console.log('running HttpCalloutSection.getDelegateController()', parentController);
    const controller = new HttpCalloutSection();
    controller.setupParentController(parentController);
    return controller;
}
