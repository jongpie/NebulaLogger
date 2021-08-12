public with sharing class ExampleClassWithLogging {
    public ExampleClassWithLogging() {
        LogMessage logMessage = new LogMessage('new instance of {0} initialized', ExampleClassWithLogging.class.getName());
        Logger.info(logMessage);
    }

    public void doSomething() {
        Logger.info('running doSomething() method!');

        new ExampleInnerClass().doAnInnerSomething();

        Logger.saveLog();
    }

    public class ExampleInnerClass {
        ExampleInnerClass() {
            LogMessage logMessage = new LogMessage('new instance of {0} initialized', ExampleInnerClass.class.getName());
            Logger.info(logMessage);
        }

        public void doAnInnerSomething() {
            Logger.info('running doAnInnerSomething() method!');
        }
    }
}
