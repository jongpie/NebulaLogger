//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
/**
 * @group Plugins
 * @description `System.Finalizer` implementation that can be used by subscribers to log errors
 */
public without sharing virtual class LogFinalizer implements System.Finalizer {
    /**
     * @description Is called by any `System.Queueable` where the finalizer is attached after the System.Queueable's `execute` method finishes
     * @param finalizerContext The `System.FinalizerContext` associated with the finalizer
     */
    public void execute(System.FinalizerContext finalizerContext) {
        Logger.setAsyncContext(finalizerContext);
        switch on finalizerContext.getResult() {
            when UNHANDLED_EXCEPTION {
                Logger.error('There was an error during this queueable job');
                Logger.error('Error details', finalizerContext.getException());
            }
        }
        this.innerExecute(finalizerContext);
        Logger.saveLog();
    }

    /**
     * @description Subscribers can optionally override this method with their own implementation to do further processing/re-queueing
     * @param finalizerContext The `System.FinalizerContext` associated with the finalizer
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    protected virtual void innerExecute(System.FinalizerContext finalizerContext) {
        // subscribers can override this to do their own post-processing if necessary, otherwise it's a no-op
    }
}
