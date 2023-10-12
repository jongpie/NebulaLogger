//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/* eslint-disable no-console */
import { LightningElement, api } from 'lwc';

import { createLogger } from 'c/logger';

export default class LoggerDemo extends LightningElement {
    @api
    logger;

    connectedCallback() {
        this.logger = createLogger();
        console.log('>>> start of connectedCallback()');
        try {
            throw new Error('A bad thing happened here');
        } catch (error) {
            this.logger.error('>>> connectedCallback error: ' + JSON.stringify(error));
            this.logger.saveLog().then(() => {
                console.log('done with async save');
            });
        }
    }
}
