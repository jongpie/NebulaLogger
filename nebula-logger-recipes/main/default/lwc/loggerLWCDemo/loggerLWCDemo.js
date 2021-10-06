//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement } from 'lwc';

const LOGGER_NAME = 'c-logger';

export default class LoggerLWCDemo extends LightningElement {
    message = 'Hello, world!';
    scenario = 'Some demo scenario';
    tagsString = 'Tag-one, Another tag here';

    messageChange(event) {
        this.message = event.target.value;
    }

    scenarioChange(event) {
        this.scenario = event.target.value;
    }

    tagsStringChange(event) {
        this.tagsString = event.target.value;
    }

    logErrorExample() {
        console.log('running logError for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        const someError = new TypeError('oops');
        const entry = logger.error(this.message).setError(someError).addTag('lwc logging demo');
        console.log('stack==' + entry.stack);
    }

    logWarnExample() {
        console.log('running logWarn for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.warn(this.message, { tags: this.tagsString.split(',') });
    }

    logInfoExample() {
        console.log('running logInfo for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.info(this.message, { tags: this.tagsString.split(',') });
    }

    logDebugExample() {
        console.log('running logDebug for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.debug(this.message, { tags: this.tagsString.split(',') });
    }

    logFineExample() {
        console.log('running logFine for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.fine(this.message, { tags: this.tagsString.split(',') });
    }

    logFinerExample() {
        console.log('running logFiner for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.finer(this.message, { tags: this.tagsString.split(',') });
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
        logger.saveLog();
    }
}
