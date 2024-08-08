//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/* eslint-disable no-console */
import { LightningElement } from 'lwc';
import throwSomeError from '@salesforce/apex/LoggerLWCDemoController.throwSomeError';

const LOGGER_NAME = 'c-logger';

export default class LoggerLWCEmbedDemo extends LightningElement {
    someBoolean = false;

    message = 'Hello, world!';
    scenario = 'Some demo scenario';
    tagsString = 'Tag-one, Another tag here';

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
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(JSON.parse(JSON.stringify(logger)));
        await throwSomeError()
            .then(result => {
                console.log('the result', JSON.parse(JSON.stringify(result)));
            })
            .catch(error => {
                console.log('apex error', error);
                console.log('and a stack trace', new Error().stack);
                const entry = logger.error(this.message).setError(error).addTag('lwc logging demo');
                console.log('entry==', JSON.parse(JSON.stringify(entry)));
            });
    }

    logErrorExample() {
        console.log('running logError for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        const someError = new TypeError('oops');
        logger.error(this.message).setError(someError).addTag('lwc logging demo');
    }

    logWarnExample() {
        console.log('running logWarn for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.warn(this.message).addTags(this.tagsString.split(','));
    }

    logInfoExample() {
        console.log('running logInfo for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.info(this.message).addTags(this.tagsString.split(','));
    }

    logDebugExample() {
        console.log('running logDebug for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.debug(this.message).addTags(this.tagsString.split(','));
    }

    logFineExample() {
        console.log('running logFine for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.fine(this.message).addTags(this.tagsString.split(','));
    }

    logFinerExample() {
        console.log('running logFiner for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.finer(this.message).addTags(this.tagsString.split(','));
    }

    logFinestExample() {
        console.log('running logFinest for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.finest(this.message);
    }

    saveLogExample() {
        console.log('running saveLog for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        logger.setScenario(this.scenario);
        console.log(logger);
        logger.saveLog('QUEUEABLE');
    }
}
