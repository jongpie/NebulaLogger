import LoggerServiceTaskQueue from '../loggerServiceTaskQueue';

describe('logger task queue tests', () => {
  afterEach(async () => {
    jest.clearAllMocks();
  });

  it('correctly executes a single sync task action', async () => {
    const firstInput = 'first string';
    const secondInput = 'second string';
    const syncActionFunction = (firstInput, secondInput) => {
      const output = `Sync firstInput was "${firstInput}", secondInput was "${secondInput}"`;
      return output;
    };
    const taskQueue = new LoggerServiceTaskQueue();

    taskQueue.enqueueTask(syncActionFunction, firstInput, secondInput);
    const processedTasks = await taskQueue.executeTasks();

    expect(processedTasks.length).toEqual(1);
    expect(processedTasks[0].actionFunction).toEqual(syncActionFunction);
    expect(processedTasks[0].actionArguments.length).toEqual(2);
    expect(processedTasks[0].actionArguments[0]).toEqual(firstInput);
    expect(processedTasks[0].actionArguments[1]).toEqual(secondInput);
    expect(processedTasks[0].output).toEqual('Sync firstInput was "first string", secondInput was "second string"');
  });

  it('correctly executes a single async task action', async () => {
    const input = 'some string';
    const asyncActionFunction = async input => {
      const output = 'Async input was: ' + input;
      return output;
    };
    const taskQueue = new LoggerServiceTaskQueue();

    taskQueue.enqueueTask(asyncActionFunction, input);
    const processedTasks = await taskQueue.executeTasks();

    expect(processedTasks.length).toEqual(1);
    expect(processedTasks[0].actionFunction).toEqual(asyncActionFunction);
    expect(processedTasks[0].actionArguments.length).toEqual(1);
    expect(processedTasks[0].actionArguments[0]).toEqual(input);
    expect(processedTasks[0].output).toEqual('Async input was: ' + input);
  });

  it('correctly executes a mix of sync and async tasks in order', async () => {
    const pendingTasks = [];
    for (let i = 0; i < 3; i++) {
      const task = {
        isAsync: false,
        actionFunction: () => {
          return i;
        },
        actionArguments: [i]
      };
      // Make one task, somewhere in the middle of the queue, an async task
      if (i == 1) {
        task.isAsync = true;
        task.actionFunction = async () => {
          return i;
        };
      }
      pendingTasks.push(task);
    }
    const taskQueue = new LoggerServiceTaskQueue();

    // taskQueue.disableAutoProcessing();
    pendingTasks.forEach(task => {
      taskQueue.enqueueTask(task.actionFunction, task.actionArguments);
    });
    const processedTasks = await taskQueue.executeTasks();

    expect(processedTasks.length).toEqual(3);
    const expectedCombinedOutput = '012';
    const actualCombinedOutput = processedTasks.reduce((accumulator, currentTask) => {
      return accumulator + currentTask.output;
    }, '');
    expect(actualCombinedOutput).toEqual(expectedCombinedOutput);
  });
});
