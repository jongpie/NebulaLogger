//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description An example queueable job that will run several chained instances
 * Each instance uses the parentLogTransactionId to relate its log back to the original instance's log
 */
public with sharing class Account_Queueable_Logger_Example implements Database.AllowsCallouts, System.Queueable {
  private Integer numberOfJobsToChain;
  private String parentLogTransactionId;

  private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

  /**
   * @description Constructor.
   * @param numberOfJobsToChain An integer determining the number of jobs to chain.
   */
  public Account_Queueable_Logger_Example() {
    this(1, null);
  }

  public Account_Queueable_Logger_Example(Integer numberOfJobsToChain) {
    this(numberOfJobsToChain, null);
  }

  /**
   * @description Constructor.
   * @param numberOfJobsToChain An integer determining the number of jobs to chain.
   * @param parentLogTransactionId A string containing the id of the parent log / transaction.
   */
  public Account_Queueable_Logger_Example(Integer numberOfJobsToChain, String parentLogTransactionId) {
    this.numberOfJobsToChain = numberOfJobsToChain;
    this.parentLogTransactionId = parentLogTransactionId ?? Logger.getTransactionId();
  }

  /**
   * @description As part of the queueable interface, this method
   * contains logic that runs when the queue is kicked off.
   * @param queueableContext The context of this queueable instance.
   */
  public void execute(System.QueueableContext queueableContext) {
    Logger.setParentLogTransactionId(this.parentLogTransactionId);

    Logger.fine('queueableContext==' + queueableContext);
    Logger.info('this.numberOfJobsToChain==' + this.numberOfJobsToChain);
    Logger.info('this.parentLogTransactionId==' + this.parentLogTransactionId);

    this.callSomeEndpoint();

    Logger.saveLog();

    --this.numberOfJobsToChain;
    if (this.numberOfJobsToChain > 0) {
      String parentLogTransactionId = this.parentLogTransactionId != null ? this.parentLogTransactionId : Logger.getTransactionId();
      System.enqueueJob(new Account_Queueable_Logger_Example(this.numberOfJobsToChain, parentLogTransactionId));
    }
  }

  private void callSomeEndpoint() {
    System.HttpRequest httpRequest = new System.HttpRequest();
    httpRequest.setEndpoint('https://jsonplaceholder.typicode.com/todos/1');
    httpRequest.setHeader('some-header', 'some value');
    httpRequest.setHeader('another-header', 'another value');
    httpRequest.setMethod('GET');

    System.HttpResponse httpResponse = new System.Http().send(httpRequest);

    Logger.info('Example of logging an HTTP request & response')
      .setHttpRequestDetails(httpRequest, new List<String>{ 'some-header' })
      .setHttpResponseDetails(httpResponse);
  }
}
