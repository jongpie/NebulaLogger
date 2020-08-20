/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
({
    addDebugEntry : function(component, event, helper) {
        helper.addEntry(component, event);
    },
    addExceptionEntry : function(component, event, helper) {
        helper.addEntry(component, event);
    },
    save : function(component, event, helper) {
        helper.save(component, event);
    }
})