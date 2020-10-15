/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
({
    queryLog: function (component, event) {
        let logId = component.get('v.recordId')
        console.log('querying log ID: ' + logId);

        let action = component.get('c.getLog');
        action.setParams({
            logId : logId
        });
        action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                let log = response.getReturnValue();
                component.set('v.log', log);

                var logJSON = JSON.stringify(log, null, '\t');
                console.log('logJSON=' + logJSON);
                component.set('v.logJSON', logJSON);
            } else if (response.getState() === 'ERROR') {
                // TODO this.processCallbackErrors(response);
            }
        });
        $A.enqueueAction(action);
    },
    copyValueToClipboard : function(value) {
        // Add a hidden input to store the JSON
        var hiddenJSONInput = document.createElement('input');
        hiddenJSONInput.setAttribute('value', value);
        document.body.appendChild(hiddenJSONInput);
        hiddenJSONInput.select();

        // Copy to clipboard
        document.execCommand('copy');
        document.body.removeChild(hiddenJSONInput);
    }
})