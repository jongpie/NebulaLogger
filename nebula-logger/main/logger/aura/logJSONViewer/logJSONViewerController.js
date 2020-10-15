/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
({
    doInit : function(component, event, helper) {
        helper.queryLog(component, event);
    },
    copyToClipboard : function(component, event, helper) {
        var logJSON = component.get('v.logJSON');

        // Add a hidden input to store the JSON
        var hiddenJSONInput = document.createElement('input');
        hiddenJSONInput.setAttribute('value', logJSON);
        document.body.appendChild(hiddenJSONInput);
        hiddenJSONInput.select();

        // Copy to clipboard
        document.execCommand('copy');
        document.body.removeChild(hiddenJSONInput);

        // Update the button to show that the JSON has been copied
        event.getSource().set('v.iconName' , 'utility:check');
        event.getSource().set('v.label', 'JSON Copied');
        event.getSource().set('v.variant', 'success');
    }
})