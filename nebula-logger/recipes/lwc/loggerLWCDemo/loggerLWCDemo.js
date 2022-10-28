//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/* eslint-disable no-console */
import { LightningElement } from 'lwc';
import throwSomeError from '@salesforce/apex/LoggerLWCDemoController.throwSomeError';
import { createLogger } from 'c/lwcLogger';

export default class LoggerLWCDemo extends LightningElement {
    message = 'Hello, world!';
    scenario = 'Some demo scenario';
    tagsString = 'Tag-one, Another tag here';
    logger = createLogger();

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
        this.logger.saveLog('QUEUEABLE');
    }

    connectedCallback() {
        this.logger.info('running connected callback');
    }
}
