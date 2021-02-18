//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement } from 'lwc';
import { getDefaultLogEntryOptions, error, warn, info, debug, fine, finer, finest, saveLog } from 'c/logger';

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
        error(this.message, { exception: new Error('boo it broke'), recordId: '001zzzzzzz', topics: this.topicsString.split(',') });
    }

    logWarn() {
        warn(this.message, { topics: this.topicsString.split(',') });
    }

    logInfo() {
        info(this.message, { topics: this.topicsString.split(',') });
    }

    logDebug() {
        debug(this.message, { topics: this.topicsString.split(',') });
    }

    logFine() {
        fine(this.message, { topics: this.topicsString.split(',') });
    }

    logFiner() {
        finer(this.message, { topics: this.topicsString.split(',') });
    }

    logFinest() {
        finest(this.message);
    }

    saveLog() {
        saveLog();
    }
}
