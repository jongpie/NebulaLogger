//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement } from 'lwc';

const LOGGER_NAME = 'c-logger';

export default class LoggerDemo extends LightningElement {
    message = 'Hello, world!';
    topicsString = 'Topic-one, Another topic here';

    messageChange(event) {
        this.message = event.target.value;
    }

    topicsStringChange(event) {
        this.topicsString = event.target.value;
    }

    logError() {
        console.log('running logError for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.error(this.message, { exception: new Error('boo it broke'), recordId: '001zzzzzzz', topics: this.topicsString.split(',') });
    }

    logWarn() {
        console.log('running logWarn for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.warn(this.message, { topics: this.topicsString.split(',') });
    }

    logInfo() {
        console.log('running logInfo for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.info(this.message, { topics: this.topicsString.split(',') });
    }

    logDebug() {
        console.log('running logDebug for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.debug(this.message, { topics: this.topicsString.split(',') });
    }

    logFine() {
        console.log('running logFine for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.fine(this.message, { topics: this.topicsString.split(',') });
    }

    logFiner() {
        console.log('running logFiner for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.finer(this.message, { topics: this.topicsString.split(',') });
    }

    logFinest() {
        console.log('running logFinest for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.finest(this.message);
    }

    saveLog() {
        console.log('running saveLog for btn');
        const logger = this.template.querySelector(LOGGER_NAME);
        console.log(logger);
        logger.saveLog();
    }
}
