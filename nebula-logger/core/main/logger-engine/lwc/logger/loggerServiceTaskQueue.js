//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/*
This class handles enqueueing & executing any provided functions in the order that they're specified,
regardless if they're sync or async functions. Some terminology used:
- "Action function": a JS function that needs to be executed - it could be sync or async
- "Task": refers to the action function + its arguments + any other info needed to process the action
- "Task queue"': refers to the collection of tasks that are enqueued, and need to be executed in order (serially)

Using a queue that execute tasks in the specified order ensures that a few areas behave as expected in the logger LWC:
- On initialization, the async Apex call to load LoggerSettings__c finishes first, before anything else that
  depends on the settings happens. For example, the settings need to be loaded before logger.newEntry() is used so that logger knows:
  - Is logging enabled for the current user
  - Does the entry's logging level (ERROR, WARN, INFO, etc.) match the current user's configured logging level
  - Is calling console.log() enabled for the current user
  - Is calling the lighting-logger LWC enabled for the current user
- When saveLog() is called, the async Apex call to save the data needs to be finished with the current/expected list of pending
  component log entries
- While saveLog() is running, adding additional log entries (based on other async operations, user interactions like
  button clicks, etc.) should be queued up in the buffer, waiting for another subsequent saveLog() call to be made
*/

/* eslint-disable @lwc/lwc/no-dupe-class-members */
export default class LoggerServiceTaskQueue {
  #isProcessing = false;
  #taskQueue = [];

  enqueueTask(actionFunction, ...actionArguments) {
    this.#taskQueue.push({ actionFunction, actionArguments });
  }

  async executeTasks() {
    const processedTasks = [];
    // Don't have multiple threads processing the same queue
    // Doing so results in the queue being processed wildly out of order
    if (this.#isProcessing) {
      return processedTasks;
    }

    this.#isProcessing = true;

    /* eslint-disable no-await-in-loop */
    while (this.#taskQueue.length > 0) {
      const task = this.#taskQueue.shift();
      task.output = task.actionFunction(...task.actionArguments);
      if (task.output instanceof Promise) {
        task.output = await task.output;
      }
      processedTasks.push(task);
    }

    this.#isProcessing = false;

    return processedTasks;
  }
}
