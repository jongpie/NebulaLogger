/**
 * @description An example Apex class for utilizing Nebula Logger.
 */
public with sharing class ExampleClassWithLogging {
    /**
     * @description Default constructor, logs initial message but does not save said log.
     */
    public ExampleClassWithLogging() {
        LogMessage logMessage = new LogMessage('new instance of {0} initialized', ExampleClassWithLogging.class.getName());
        Logger.info(logMessage);
    }

    /**
     * @description Example method for logging that saves log and writes a log entry.
     */
    public void doSomething() {
        Logger.info('running doSomething() method!');

        new ExampleInnerClass().doAnInnerSomething();

        Logger.saveLog();
    }

    /**
     * @description Example inner class.
     */
    public class ExampleInnerClass {
        /**
         * @description Example constructor
         */
        ExampleInnerClass() {
            LogMessage logMessage = new LogMessage('new instance of {0} initialized', ExampleInnerClass.class.getName());
            Logger.info(logMessage);
        }

        /**
         * @description example method in inner class.
         */
        public void doAnInnerSomething() {
            Logger.info('running doAnInnerSomething() method!');
        }
    }
}
