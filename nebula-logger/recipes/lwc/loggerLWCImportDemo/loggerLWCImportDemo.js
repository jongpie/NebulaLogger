//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/* eslint-disable no-console */
import { api, LightningElement, wire } from 'lwc';
import returnSomeString from '@salesforce/apex/LoggerLWCDemoController.returnSomeString';
import throwSomeError from '@salesforce/apex/LoggerLWCDemoController.throwSomeError';
import { createLogger } from 'c/logger';

export default class LoggerLWCImportDemo extends LightningElement {
    someBoolean = false;

    message = 'Hello, world!';
    scenario = 'Some demo scenario';
    tagsString = 'Tag-one, Another tag here';
    /* eslint-disable @lwc/lwc/no-api-reassignments */
    @api
    logger;

    async connectedCallback() {
        this.logger = await createLogger();
        console.log('>>> start of connectedCallback()');
        try {
            this.logger.error('test error entry');
            this.logger.warn('test warn entry');
            this.logger.info('test info entry');
            this.logger.debug('test debug entry');
            this.logger.fine('test fine entry');
            this.logger.finer('test finer entry');
            this.logger.finest('test finest entry');
            throw new Error('A bad thing happened here');
        } catch (error) {
            this.logger.error('>>> connectedCallback error: ' + error.message).setError(error);
            this.logger.saveLog().then(() => {
                console.log('done with async save');
            });
        }
    }

    disconnectedCallback() {
        console.log('>>> start of disconnectedCallback()');
        this.logger.info('>>> running disconnectedCallback(), using createLogger()');
        this.logger.info('>>> adding an extra log entry');
        this.logger.saveLog();
        console.log('>>> done with disconnectedCallback()');
    }

    renderedCallback() {
        console.log('>>> start of renderedCallback()');
        this.logger?.info('>>> running renderedCallback(), using createLogger()');
        this.logger?.info('>>> adding an extra log entry');
        this.logger?.saveLog();
        console.log('>>> done with renderedCallback()');
    }

    @wire(returnSomeString)
    wiredReturnSomeString({ error, data }) {
        this.logger?.info('>>> logging inside a wire function');
        if (data) {
            this.logger?.info('>>> wire function return value: ' + data);
        }
        if (error) {
            this.logger?.error('>>> wire function error: ' + JSON.stringify(error));
        }
    }

    handleRerenderButton() {
        this.someBoolean = !this.someBoolean;
    }

    messageChange(event) {
        this.message = event.target.value;
    }

    scenarioChange(event) {
        this.scenario = event.target.value;
    }

    tagsStringChange(event) {
        this.tagsString = event.target.value;
    }

    async logApexErrorExample() {
        console.log('running logApexError for btn');
        console.log(JSON.parse(JSON.stringify(this.logger)));
        await throwSomeError()
            .then(result => {
                console.log('the result', JSON.parse(JSON.stringify(result)));
            })
            .catch(error => {
                console.log('apex error', error);
                console.log('and a stack trace', new Error().stack);
                const entry = this.logger.error(this.message).setError(error).addTag('lwc logging demo');
                console.log('entry==', JSON.parse(JSON.stringify(entry)));
            });
    }

    logErrorExample() {
        console.log('running logError for btn');
        console.log(this.logger);
        const someError = new TypeError('oops');
        const entry = this.logger.error(this.message).setError(someError).addTag('lwc logging demo');
        console.log('stack==' + entry.stack);
    }

    logWarnExample() {
        console.log('running logWarn for btn');
        console.log(this.logger);
        this.logger.warn(this.message).addTags(this.tagsString.split(','));
    }

    logInfoExample() {
        console.log('running logInfo for btn');
        console.log(this.logger);
        this.logger.info(this.message).addTags(this.tagsString.split(','));
    }

    logDebugExample() {
        console.log('running logDebug for btn');
        console.log(this.logger);
        this.logger.debug(this.message).addTags(this.tagsString.split(','));
    }

    logFineExample() {
        console.log('running logFine for btn');
        console.log(this.logger);
        this.logger.fine(this.message).addTags(this.tagsString.split(','));
    }

    logFinerExample() {
        console.log('running logFiner for btn');
        console.log(this.logger);
        this.logger.finer(this.message).addTags(this.tagsString.split(','));
    }

    logFinestExample() {
        console.log('running logFinest for btn');
        console.log(this.logger);
        this.logger.finest(this.message);
    }

    saveLogExample() {
        console.log('running saveLog for btn');
        this.logger.setScenario(this.scenario);
        console.log(this.logger);
        // this.logger.saveLog('QUEUEABLE');
        this.logger.saveLog();
    }
}
