// import { track } from 'lwc';

import LightningPrompt from 'lightning/prompt';
import template from './template.html';

const InformtionSection = class {
    showTags = true;
    // @track
    tags = [
        {
            label: 'My Pill',
            name: 'mypill'
        },
        {
            type: 'avatar',
            label: 'Avatar Pill',
            name: 'avatarpill',
            src: '/my/path/avatar.jpg',
            fallbackIconName: 'standard:user',
            variant: 'circle',
            alternativeText: 'User avatar'
        },
        {
            type: 'icon',
            label: 'Icon Pill',
            name: 'iconpill',
            iconName: 'standard:account',
            alternativeText: 'Account'
        }
    ];

    // tags = [{ Id: '123', Name: 'Some tag' }];

    setupParentController(parentController) {
        console.log('zzz setting up parent controller', parentController);

        if (!parentController?.logEntryContext) {
            console.log('>>> no op!');
            return;
        }

        this.logEntryContext = JSON.parse(JSON.stringify(parentController.logEntryContext));
        console.log('>>> checking tags', this.logEntryContext.logEntryTags);
        const processedLogEntryTags = [];
        if (this.logEntryContext.logEntryTags) {
            console.log('>>> found some tags to process');
            this.logEntryContext.logEntryTags?.forEach(logEntryTag => {
                console.log('>>> processing tagggggg', logEntryTag);
                // const processedLogEntryTag = { ...logEntryTag };
                logEntryTag.Tag__r__Link = '/' + logEntryTag.Tag__c;
                console.log('>>> processed tag', logEntryTag);
                processedLogEntryTags.push(logEntryTag);
            });
        }
        console.log('>>> processed tags', processedLogEntryTags);
        this.logEntryContext.logEntryTags = processedLogEntryTags;
        console.log('>>> logEntryContext with processed tags', this.logEntryContext.logEntryTags);

        console.log('this.logEntryContext', this.logEntryContext);
        console.log('parentController.logEntryContext', parentController.logEntryContext);

        parentController.handleAddTag = this.handleAddTag;
        parentController.handleRemoveTag = this.handleRemoveTag;
        parentController.showTags = this.showTags;
        parentController.shouldDisplay = this.shouldDisplay;
        parentController.tags = this.tags;

        console.log('>>> ze tags', this.tags);
        return this;
    }

    get shouldDisplay() {
        return !!this.logEntryContext?.logEntry;
    }

    getTemplate() {
        console.log({ template });
        return template;
    }

    handleAddTag(event) {
        // const _items = [...this.items];
        // _items.push({ label: 'neeeeewy Pill', name: 'zzzzzzmypill' });
        // this.items = _items;
        LightningPrompt.open({
            label: 'Add Tag',
            message: 'Enter a tag to add to this log entry'
        }).then(result => {
            // prompt modal has been closed
            console.log('this.tags before', JSON.parse(JSON.stringify(this.tags)));
            const tmp = [this.tags];
            this.tags = null;
            this.showTags = false;
            console.log('running handleAddTag()', event);
            tmp.push({ label: result, name: result });

            this.tags = tmp;
            console.log('this.tags after', JSON.parse(JSON.stringify(this.tags)));
            this.showTags = true;
        });
    }

    handleViewTag(event) {
        console.log('running handleViewTag(event)', event);
    }

    handleRemoveTag(event) {
        this.showTags = false;
        console.log('handleRemoveTag', event);
        // const name = event.detail.item.name;
        console.log('event.detail', event.detail);
        console.log('event.detail.index', event.detail.index);
        // alert(name + ' pill was removed!');
        const index = event.detail.index;
        this.logEntryContext.logEntryTags.splice(index, 1);
        // this.showTags = false;
    }
};

export function getDelegateController(parentController) {
    console.log('running InformtionSection.getDelegateController()', parentController);
    const controller = new InformtionSection();
    controller.setupParentController(parentController);
    return controller;
}
