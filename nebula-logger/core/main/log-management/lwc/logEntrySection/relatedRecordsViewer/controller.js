import template from './template.html';

const RelatedRecordsViewer = class {
    logEntryContext;
    // logEntry;

    setupParentController(parentController) {
        console.log('running RelatedRecordsViewer.setupParentController()', parentController);
        this.logEntryContext = parentController.logEntryContext;

        // this.logEntry = parentController.logEntry;
        // console.log('RelatedRecordsViewer now has this.logEntry', this.logEntry);
        // this.logEntryContext = parentController.logEntryContext;
        console.log('RelatedRecordsViewer now has this.logEntryContext', this.logEntryContext);

        // console.log('>>> eeeek', this.logEntryContext);
        // console.log('>>> got some record JSON!!!', this.logEntryContext?.logEntry?.RecordJson__c);
        console.log('RelatedRecordsViewer has this.columns', this.columns);
        parentController.columns = this.columns;
        console.log('parentController now has parentController.columns', parentController.columns);
        return this;
    }

    getTemplate() {
        console.log({ template });
        return template;
    }

    get columns() {
        const generatedColumns = [
            { fieldName: 'Id', label: 'Record ID', type: 'text' },
            { fieldName: 'Name', label: 'Name', type: 'text' }
        ];
        const tableRowActions = [{ label: 'View', name: 'view' }];
        generatedColumns.push({
            type: 'action',
            typeAttributes: {
                rowActions: tableRowActions,
                menuAlignment: 'auto'
            }
        });

        console.log('loaded columns', generatedColumns);
        // console.log('this.section', this.section);
        // console.log('this.recordId', this.recordId);
        return generatedColumns;
    }
};

export function getDelegateController(parentController) {
    console.log('running RelatedRecordsViewer.getDelegateController()', parentController);
    const controller = new RelatedRecordsViewer();
    controller.setupParentController(parentController);
    return controller;
}
