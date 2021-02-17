//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement } from 'lwc';
import { getLoggingLevels, getDefaultLogEntryOptions, newEntry, error, warn, info, debug, saveLog } from 'c/logger';

export default class LoggerDemo extends LightningElement {
    message = 'Hello, world!';

    messageChange(event) {
        this.message = event.target.value;
    }

    logError() {
        error(this.message);
    }

    logWarn() {
        warn(this.message);
    }

    logInfo() {
        info(this.message);
    }

    logDebug() {
        debug(this.message);
    }

    saveLog() {
        saveLog();
    }

}


