//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
/**
 * @group Plugins
 * @description `FlowExecutionErrorEvent` messages are created and fired by the platform when Screen Flows have unhandled errors, and this creates logs for them
 */
public without sharing class LogFlowExecutionErrorEventHandler {
    @TestVisible
    private static final String PARAMETER_DEV_NAME = 'FlowExecutionErrorEventHandled';

    @InvocableMethod(category='Logging' description='Adds error handling for unhandled errors in Screen Flows')
    public static void logErrors(List<FlowExecutionErrorEvent> flowErrorEvents) {
        if (LoggerParameter.getBoolean(PARAMETER_DEV_NAME, false) == false) {
            return;
        }
        for (FlowExecutionErrorEvent flowExecutionErrorEvent : flowErrorEvents) {
            Logger.warn('unhandled screen flow exception');
        }
        Logger.saveLog();
    }
}
