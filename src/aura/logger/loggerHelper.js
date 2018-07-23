({
    addEntry : function(component, event) {
        var timestamp = new Date().toISOString();

        var logEntries = component.get('v.logEntries');
        if(logEntries == undefined || logEntries == null) logEntries = [];
        var args = event.getParam('arguments');

        var error;
        if(args.error && args.error.message) {
            error = {
                columnNumber:  args.error.columnNumber,
                lineNumber:    args.error.lineNumber,
                message:       args.error.message,
                stack:         args.error.stack
            };
        }

        var logEntry = {
            componentName:    args.component.getName(),
            message:          args.message,
            error:            error,
            loggingLevelName: args.loggingLevelName,
            originLocation:   args.originLocation,
            topics:           args.topics,
            timestamp:        timestamp
        };
        console.log('New Log Entry Added');
        console.log(logEntry);
        logEntries.push(logEntry);
        component.set('v.logEntries', logEntries);
    },
    save : function(component, event) {
        var logEntries = component.get('v.logEntries');

        if(logEntries.size == 0) return;

        var action = component.get('c.saveLightningEntries');
        action.setParams({
            logEntriesJson : JSON.stringify(logEntries)
        });
        action.setCallback(this, function(response) {
            if(response.getState() === 'SUCCESS') {
                component.set('v.logEntries', []);
            } else if(response.getState() === 'ERROR') {
                // TODO this.processCallbackErrors(response);
            }
        });
        $A.enqueueAction(action);
    }
})