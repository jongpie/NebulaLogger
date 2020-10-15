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

        helper.copyValueToClipboard(logJSON);

        component.set('v.jsonCopied', true);
    }
})