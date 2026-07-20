//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`
 *
 *              Plugins can register additional SObject types by implementing `LoggerPlugin.Purgeable`
 *              and returning a list of `LoggerPurgeRegistration` values that
 *              specify the SObject type + the field that carries its retention date. Registered
 *              types are purged BEFORE the core log objects on each run so plugin data with
 *              parent-child references to `Log__c` / `LogEntry__c` gets cleaned up first and the
 *              core delete cascade is not blocked by dangling plugin records.
 * @see LogBatchPurgeScheduler
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList')
global with sharing class LogBatchPurger implements Database.Batchable<SObject>, Database.Stateful {
  private static final String NO_DELETE_ACCESS_EXCEPTION_MESSAGE = 'User does not have access to delete logs';
  private static final Date RETENTION_END_DATE = System.today();

  @TestVisible
  private Integer chainedBatchSize = getDefaultBatchSize();
  @TestVisible
  private Schema.SObjectType currentSObjectType;
  private PurgePluginRunner pluginRunner;
  private PurgeQueryPlanner queryPlanner;
  private String originalTransactionId;
  private Integer totalProcessedRecords;

  /**
   * @description Returns the default batch size used when running `LogBatchPurger`
   * @return   The `Integer` value configured in the custom metadata record `LoggerParameter.LogBatchPurgerDefaultBatchSize`, or `500` as the default
   */
  public static Integer getDefaultBatchSize() {
    return LoggerParameter.LOG_BATCH_PURGER_DEFAULT_BATCH_SIZE;
  }

  /**
   * @description Returns the ordered list of SObject types that plugins have registered with this purger
   *              instance via `LoggerPlugin.Purgeable`. Public read-only accessor so controllers /
   *              plugins can inspect the registered set.
   * @return Copy of the registered types in registration order.
   */
  public List<Schema.SObjectType> getRegisteredSObjectTypes() {
    return this.pluginRunner.getRegisteredSObjectTypes();
  }

  /**
   * @description Returns the SOQL query the purger built for a plugin-registered SObject type, or `null`
   *              if that type isn't in this instance's registry. Public read-only accessor.
   * @param sobjectType The registered SObject type to look up.
   * @return The purger-owned SOQL string used to select records for deletion.
   */
  public String getRegisteredQuery(Schema.SObjectType sobjectType) {
    return this.pluginRunner.getRegisteredQuery(sobjectType);
  }

  /**
   * @description Returns the `LoggerPlugin__mdt.DeveloperName` of the plugin that registered the given
   *              SObject type, or `null` if that type isn't in this instance's registry. Lets the LWC
   *              display "registered by plugin X" without needing a second round-trip. Public read-only
   *              accessor.
   * @param sobjectType The registered SObject type to look up.
   * @return The registering plugin's `DeveloperName`.
   */
  public String getRegisteringPluginDeveloperName(Schema.SObjectType sobjectType) {
    return this.pluginRunner.getRegisteringPluginDeveloperName(sobjectType);
  }

  /**
   * @description Default constructor, sets up instance of LogBatchPurger class.
   */
  global LogBatchPurger() {
    this.totalProcessedRecords = 0;
    // PurgePluginRunner loads its own plugin configurations and invokes the LoggerPlugin.Purgeable
    // registrars from its constructor, so by the time it returns the registration state is populated
    // and the query planner can read through it.
    this.pluginRunner = new PurgePluginRunner();
    this.queryPlanner = new PurgeQueryPlanner(this.pluginRunner);
  }

  /**
   * @description Required by the Database.Batchable interface.  Collects the records /
   * objects passed in to the batch instance and returns a Databae.QueryLocator reference representing
   * the current iteration.
   * @param batchableContext contains the context of the batch job
   * @return an instance of the Database.QueryLocator class
   * @throws NoAccessException when there is no delete access to Logs
   */
  global Database.QueryLocator start(Database.BatchableContext batchableContext) {
    if (Schema.Log__c.SObjectType.getDescribe().isDeletable() == false) {
      NoAccessException noDeleteAccessException = new NoAccessException();
      noDeleteAccessException.setMessage(NO_DELETE_ACCESS_EXCEPTION_MESSAGE);
      throw noDeleteAccessException;
    }

    Logger.setAsyncContext(batchableContext);
    // Each batchable method runs in a separate transaction,
    // so store the first transaction ID to later relate the other transactions
    this.originalTransactionId = Logger.getTransactionId();

    Schema.SObjectType initialSObjectType = this.queryPlanner.getInitialSObjectType();
    LoggerBatchableContext input = new LoggerBatchableContext(batchableContext, initialSObjectType);
    this.pluginRunner.dispatchStart(input);
    this.currentSObjectType = input.sobjectType;

    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.info('Nebula Logger - Starting LogBatchPurger job for SObject type: ' + this.currentSObjectType);
    }
    Logger.saveLog();

    return this.queryPlanner.getQueryLocator(this.currentSObjectType);
  }

  /**
   * @description Required by the Database.Batchable interface, this method executes the logic for purging
   * log records.
   * @param batchableContext - The context of the current batch job.
   * @param logRecords - The log records to purge.
   */
  global void execute(Database.BatchableContext batchableContext, List<Log__c> logRecords) {
    // Legacy support: this batch job originally used this method, but List<SObject> is now used
    // However, the original method can't be removed from the managed package, so this is just
    // here for backwards compatability
    this.execute(batchableContext, (List<SObject>) logRecords);
  }

  /**
   * @description Required by the Database.Batchable interface, this method executes the logic for purging
   * log records.
   * @param batchableContext - The context of the current batch job.
   * @param scopeRecords - The log records to purge.
   */
  global void execute(Database.BatchableContext batchableContext, List<SObject> scopeRecords) {
    Logger.setAsyncContext(batchableContext);
    Logger.setParentLogTransactionId(this.originalTransactionId);
    try {
      this.totalProcessedRecords += scopeRecords.size();
      LoggerBatchableContext input = new LoggerBatchableContext(batchableContext, this.currentSObjectType);
      this.pluginRunner.dispatchExecute(input, scopeRecords);

      LoggerDataStore.getDatabase().hardDeleteRecords(scopeRecords);
      Logger.saveLog();
    } catch (System.Exception apexException) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.error('Nebula Logger - Error deleting logs', apexException);
      }
      Logger.saveLog();
      throw apexException;
    }
  }

  /**
   * @description Required by the Database.Batchable interface.  This method runs after all batch jobs are complete.
   * This method writes a status to the Log__c object indicating that the purge has finished.
   * @param batchableContext - The context of the batch jobs
   */
  global void finish(Database.BatchableContext batchableContext) {
    Logger.setAsyncContext(batchableContext);
    Logger.setParentLogTransactionId(this.originalTransactionId);
    LoggerBatchableContext input = new LoggerBatchableContext(batchableContext, this.currentSObjectType);
    this.pluginRunner.dispatchFinish(input);

    // The Log__c pass is the last step in the chain. Every other pass (registered plugin types +
    // LogEntryTag__c + LogEntry__c) chains to a fresh batch instance whose start() reads the current
    // state via getInitialSObjectType() - so completed registered types naturally fall through to
    // LogEntryTag__c on the next enqueue once their record count reaches zero.
    Id nextBatchJobId;
    if (this.currentSObjectType != Schema.Log__c.SObjectType) {
      nextBatchJobId = System.Database.executeBatch(this, this.chainedBatchSize);
    }

    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.info(
        new LogMessage(
          'Nebula Logger - Finished LogBatchPurger job for {0}, {1} total log records processed',
          this.currentSObjectType,
          this.totalProcessedRecords
        )
      );
      if (nextBatchJobId != null) {
        Logger.info(new LogMessage('Nebula Logger - Starting a new instance of LogBatchPurger job, job ID is: {0}', nextBatchJobId));
      }
      Logger.saveLog();
    }
  }

  /**
   * @description The `LogBatchPurger` job is designed to run several instances - typically, it runs on `LogEntryTag__c`,
   *              then `LogEntry__c`, and finally `Log__c`. This method provides a way to control the batch size used for
   *              the chained instances of `LogBachPurger`
   * @param  chainedBatchSize The batch size to use for any subsequent chained instances of `LogBatchPurger`
   * @return                  The same instance of `LogBatchPurger`, useful for chaining methods
   */
  public LogBatchPurger setChainedBatchSize(Integer chainedBatchSize) {
    this.chainedBatchSize = chainedBatchSize ?? LogBatchPurger.getDefaultBatchSize();

    return this;
  }

  // Owns the plugin-driven registration state (SObject types + built queries + registering plugin
  // names) and dispatches every batch lifecycle hook (start / execute / finish) to Apex- and Flow-
  // based plugins. Registration state has to live on the instance, not on a static, because the
  // purger's constructor runs in the enqueueing transaction while start() runs in a fresh async
  // transaction where static state is reset. Database.Stateful preserves instance fields on the
  // outer LogBatchPurger across that boundary (and across every chained re-enqueue from finish()),
  // and by extension across every field this runner holds - so registration performed here
  // survives to start() and to every subsequent transaction in the chain.
  //
  // Ordered so registration order = deletion order. Registered types are deleted first (before
  // LogEntryTag__c / LogEntry__c / Log__c) so plugin data with FKs into the core log objects
  // is removed before the core cascade tries to delete its parent records.
  private with sharing class PurgePluginRunner {
    // SObject types plugins are forbidden from registering. Log__c / LogEntry__c / LogEntryTag__c
    // are already purged by the built-in cascade at the end of every run - letting a plugin also
    // register them would produce two passes over the same records in a single job (and the
    // plugin's SOQL could override the retention semantics the core cascade enforces).
    // LoggerScenario__c and LoggerTag__c are intentionally NOT purged - they hold long-lived
    // reference data - so plugins must not be able to sneak them into the cascade either.
    private final Set<Schema.SObjectType> blockedRegistrationSObjectTypes = new Set<Schema.SObjectType>{
      Schema.LoggerScenario__c.SObjectType,
      Schema.Log__c.SObjectType,
      Schema.LogEntry__c.SObjectType,
      Schema.LogEntryTag__c.SObjectType,
      Schema.LoggerTag__c.SObjectType
    };

    private final List<Schema.SObjectType> registeredSObjectTypes = new List<Schema.SObjectType>();
    private final Map<Schema.SObjectType, String> registeredQueriesBySObjectType = new Map<Schema.SObjectType, String>();
    private final Map<Schema.SObjectType, String> registeringPluginDeveloperNamesBySObjectType = new Map<Schema.SObjectType, String>();
    private final List<LoggerPlugin__mdt> pluginConfigurations;

    private PurgePluginRunner() {
      this.pluginConfigurations = LoggerPlugin.getFilteredPluginConfigurations(
        new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.BatchPurgerApexClass__c, Schema.LoggerPlugin__mdt.BatchPurgerFlowName__c },
        Schema.LoggerPlugin__mdt.BatchPurgerExecutionOrder__c
      );
      this.invokePurgeableRegistrars();
    }

    private List<Schema.SObjectType> getRegisteredSObjectTypes() {
      return this.registeredSObjectTypes.clone();
    }

    private String getRegisteredQuery(Schema.SObjectType sobjectType) {
      return this.registeredQueriesBySObjectType.get(sobjectType);
    }

    private Boolean hasRegisteredQuery(Schema.SObjectType sobjectType) {
      return this.registeredQueriesBySObjectType.containsKey(sobjectType);
    }

    private String getRegisteringPluginDeveloperName(Schema.SObjectType sobjectType) {
      return this.registeringPluginDeveloperNamesBySObjectType.get(sobjectType);
    }

    private void dispatchStart(LoggerBatchableContext input) {
      for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
        if (String.isNotBlank(pluginConfiguration.BatchPurgerApexClass__c)) {
          try {
            LoggerPlugin.Batchable apexPlugin = LoggerPlugin.newBatchableInstance(pluginConfiguration.BatchPurgerApexClass__c);
            apexPlugin.start(pluginConfiguration, input);
          } catch (TypeException ex) {
            this.warnUnknownApexClass(pluginConfiguration, ex);
          }
        }
        if (String.isNotBlank(pluginConfiguration.BatchPurgerFlowName__c)) {
          this.dispatchFlow(pluginConfiguration, this.buildFlowInputs(pluginConfiguration, input, null));
        }
      }
    }

    private void dispatchExecute(LoggerBatchableContext input, List<SObject> scopeRecords) {
      for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
        if (String.isNotBlank(pluginConfiguration.BatchPurgerApexClass__c)) {
          try {
            LoggerPlugin.Batchable apexPlugin = LoggerPlugin.newBatchableInstance(pluginConfiguration.BatchPurgerApexClass__c);
            apexPlugin.execute(pluginConfiguration, input, scopeRecords);
          } catch (TypeException ex) {
            this.warnUnknownApexClass(pluginConfiguration, ex);
          }
        }
        if (String.isNotBlank(pluginConfiguration.BatchPurgerFlowName__c)) {
          this.dispatchFlow(pluginConfiguration, this.buildFlowInputs(pluginConfiguration, input, scopeRecords));
        }
      }
    }

    private void dispatchFinish(LoggerBatchableContext input) {
      for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
        if (String.isNotBlank(pluginConfiguration.BatchPurgerApexClass__c)) {
          try {
            LoggerPlugin.Batchable apexPlugin = LoggerPlugin.newBatchableInstance(pluginConfiguration.BatchPurgerApexClass__c);
            apexPlugin.finish(pluginConfiguration, input);
          } catch (TypeException ex) {
            this.warnUnknownApexClass(pluginConfiguration, ex);
          }
        }
        if (String.isNotBlank(pluginConfiguration.BatchPurgerFlowName__c)) {
          this.dispatchFlow(pluginConfiguration, this.buildFlowInputs(pluginConfiguration, input, null));
        }
      }
    }

    private void invokePurgeableRegistrars() {
      // Plugins that put an Apex class name in LoggerPlugin__mdt.BatchPurgeRegistrarApexClass__c
      // and implement LoggerPlugin.Purgeable get their getPurgeRegistrations() method
      // called here. The returned list is a declaration of "which SObjects do you want the purger to
      // include and which field carries their retention date"; the purger builds the actual SOQL
      // from each entry and adds it to the shared registry. List iteration order is preserved so a
      // plugin with parent + child SObjects can order the child before the parent.
      List<LoggerPlugin__mdt> registrarConfigurations = LoggerPlugin.getFilteredPluginConfigurations(
        new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.BatchPurgeRegistrarApexClass__c },
        Schema.LoggerPlugin__mdt.BatchPurgerExecutionOrder__c
      );
      for (LoggerPlugin__mdt pluginConfiguration : registrarConfigurations) {
        LoggerPlugin.Purgeable registrar = LoggerPlugin.newPurgeableInstance(pluginConfiguration.BatchPurgeRegistrarApexClass__c);
        if (registrar == null) {
          if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
            Logger.warn(
              'Nebula Logger - Purger registrar class ' +
                pluginConfiguration.BatchPurgeRegistrarApexClass__c +
                ' could not be instantiated or does not implement LoggerPlugin.Purgeable, skipping'
            );
          }
          continue;
        }
        List<LoggerPurgeRegistration> registrations = registrar.getPurgeRegistrations();
        if (registrations == null) {
          continue;
        }
        for (LoggerPurgeRegistration registration : registrations) {
          if (registration == null) {
            continue;
          }
          try {
            this.registerObjectToPurge(registration, pluginConfiguration.DeveloperName);
          } catch (System.IllegalArgumentException ex) {
            // A bad registration in one plugin should not crash the whole purger. Surface the
            // rejection to the admin via Logger.warn and keep processing the remaining
            // registrations from this plugin and every other configured plugin.
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
              Logger.warn(
                'Nebula Logger - Purger registrar class ' + pluginConfiguration.BatchPurgeRegistrarApexClass__c + ' rejected: ' + ex.getMessage(),
                pluginConfiguration,
                ex
              );
            }
          }
        }
      }
    }

    /**
     * @description Records a `LoggerPurgeRegistration` in this purger instance's registry. Only the
     *              runner itself calls this - from `invokePurgeableRegistrars` when iterating a
     *              `LoggerPlugin.Purgeable` implementation's return value. Kept private so plugin
     *              code can't reach behind the `Purgeable` interface and mutate the registry
     *              directly, and so query construction stays a runner-owned concern.
     *
     *              **Guardrails.** Registration accepts a plugin-declared SObject, so an
     *              unrestricted registry would let a hostile `Purgeable` implementation schedule
     *              wholesale deletes against standard objects (Account, Contact, Case, ...) or
     *              double up on the core cascade's own targets. To narrow the blast radius the
     *              registrar rejects (a) anything that isn't a **custom** SObject, (b) anything
     *              whose API name doesn't contain the substring `Log`, (c) any of Nebula Logger's
     *              own core SObjects (`Log__c` / `LogEntry__c` / `LogEntryTag__c` are already
     *              purged by the built-in cascade; `LoggerScenario__c` / `LoggerTag__c` are
     *              intentionally never purged), and (d) any SObject type that has already been
     *              registered in this purger instance. Rejections throw
     *              `System.IllegalArgumentException` so the failing plugin is surfaced to the
     *              admin rather than being silently ignored.
     */
    private void registerObjectToPurge(LoggerPurgeRegistration registration, String registeringPluginDeveloperName) {
      Schema.SObjectType sobjectType = registration.sobjectType;
      Schema.DescribeSObjectResult describe = sobjectType.getDescribe();
      if (describe.isCustom() == false) {
        throw new System.IllegalArgumentException('LogBatchPurger.registerObjectToPurge only accepts custom SObjects. Rejected: ' + describe.getName());
      }
      // Nebula Logger has a strict naming convention that all custom objects (in fact, all of its metadata items) always contain
      // the word 'Log' somewhere in the name. So, to prevent malicious code from trying to delete data in SObjects that
      // are completely unrelated to Nebula Logger, the naming convention is used as a way to restrict purging to log-related objects.
      if (describe.getName().contains('Log') == false) {
        throw new System.IllegalArgumentException(
          'LogBatchPurger.registerObjectToPurge requires the SObject API name to contain "Log". Rejected: ' + describe.getName()
        );
      }
      if (this.blockedRegistrationSObjectTypes.contains(sobjectType)) {
        throw new System.IllegalArgumentException(
          'LogBatchPurger.registerObjectToPurge cannot accept a core Nebula Logger SObject. Rejected: ' + describe.getName()
        );
      }
      if (this.registeredQueriesBySObjectType.containsKey(sobjectType)) {
        throw new System.IllegalArgumentException(
          'LogBatchPurger.registerObjectToPurge rejected a duplicate registration for ' +
            describe.getName() +
            '. Each SObject type may be registered at most once per purger instance.'
        );
      }
      this.registeredSObjectTypes.add(sobjectType);
      this.registeredQueriesBySObjectType.put(sobjectType, registration.buildQuery());
      this.registeringPluginDeveloperNamesBySObjectType.put(sobjectType, registeringPluginDeveloperName);
    }

    private Map<String, Object> buildFlowInputs(LoggerPlugin__mdt pluginConfiguration, LoggerBatchableContext input, List<SObject> scopeRecords) {
      Map<String, Object> flowInputs = new Map<String, Object>();
      flowInputs.put('pluginConfiguration', pluginConfiguration);
      flowInputs.put('pluginInput', input);
      if (scopeRecords != null) {
        flowInputs.put('scopeRecords', scopeRecords);
      }
      return flowInputs;
    }

    private void dispatchFlow(LoggerPlugin__mdt pluginConfiguration, Map<String, Object> flowInputs) {
      try {
        Flow.Interview flowPlugin = Flow.Interview.createInterview(pluginConfiguration.BatchPurgerFlowName__c, flowInputs);
        flowPlugin.start();
      } catch (TypeException ex) {
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
          Logger.warn('Unknown Flow ' + pluginConfiguration.BatchPurgerFlowName__c + ', skipping plugin execution', pluginConfiguration, ex);
        }
      }
    }

    private void warnUnknownApexClass(LoggerPlugin__mdt pluginConfiguration, TypeException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('Unknown Apex class ' + pluginConfiguration.BatchPurgerApexClass__c + ', skipping plugin execution', pluginConfiguration, ex);
      }
    }
  }

  // Given the plugin-driven registration state (via a PurgePluginRunner), decides which SObject
  // type this batch instance should run against next and hands back the Database.QueryLocator to
  // feed the Batchable framework.
  private with sharing class PurgeQueryPlanner {
    private final PurgePluginRunner pluginRunner;

    private PurgeQueryPlanner(PurgePluginRunner pluginRunner) {
      this.pluginRunner = pluginRunner;
    }

    private Schema.SObjectType getInitialSObjectType() {
      // Registered plugin types first, in registration order. The purger then falls back to the core
      // LogEntryTag__c -> LogEntry__c -> Log__c chain once every registered type has been purged.
      Schema.SObjectType registeredType = this.getFirstRegisteredTypeWithRecordsToPurge();
      if (registeredType != null) {
        return registeredType;
      }
      if (this.getLogEntryTagCount() > 0) {
        return Schema.LogEntryTag__c.SObjectType;
      }
      if (this.getLogEntryCount() > 0) {
        return Schema.LogEntry__c.SObjectType;
      }
      return Schema.Log__c.SObjectType;
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    private Database.QueryLocator getQueryLocator(Schema.SObjectType sobjectType) {
      if (this.pluginRunner.hasRegisteredQuery(sobjectType)) {
        return System.Database.getQueryLocator(this.pluginRunner.getRegisteredQuery(sobjectType));
      }
      Database.QueryLocator queryLocator;

      switch on sobjectType.newSObject() {
        when LogEntryTag__c logEntryTag {
          queryLocator = System.Database.getQueryLocator(
            [
              SELECT Id
              FROM LogEntryTag__c
              WHERE LogEntry__r.Log__r.LogRetentionDate__c <= :RETENTION_END_DATE AND LogEntry__r.Log__r.LogRetentionDate__c != NULL
              ORDER BY LogEntry__r.Log__r.LogRetentionDate__c, LogEntry__r.Log__c
            ]
          );
        }
        when LogEntry__c logEntry {
          queryLocator = System.Database.getQueryLocator(
            [
              SELECT Id
              FROM LogEntry__c
              WHERE Log__r.LogRetentionDate__c <= :RETENTION_END_DATE AND Log__r.LogRetentionDate__c != NULL
              ORDER BY Log__r.LogRetentionDate__c, Log__c
            ]
          );
        }
        when Log__c log {
          queryLocator = System.Database.getQueryLocator(
            [
              SELECT Id
              FROM Log__c
              WHERE (LogRetentionDate__c <= :RETENTION_END_DATE AND LogRetentionDate__c != NULL) OR TotalLogEntries__c = 0
              ORDER BY LogRetentionDate__c
            ]
          );
        }
      }

      return queryLocator;
    }

    private Schema.SObjectType getFirstRegisteredTypeWithRecordsToPurge() {
      for (Schema.SObjectType sobjectType : this.pluginRunner.getRegisteredSObjectTypes()) {
        if (this.registeredTypeHasRecordsToPurge(sobjectType)) {
          return sobjectType;
        }
      }
      return null;
    }

    private Boolean registeredTypeHasRecordsToPurge(Schema.SObjectType sobjectType) {
      String soql = this.pluginRunner.getRegisteredQuery(sobjectType);
      if (String.isBlank(soql)) {
        return false;
      }
      try {
        // Run the plugin's SOQL as-is (it may already carry ORDER BY / LIMIT) and just check whether
        // the first record exists. This is cheaper than counting because we only need the yes/no answer,
        // and safer than trying to inject LIMIT 1 into an arbitrary caller-supplied query.
        List<SObject> sample = System.Database.query(soql);
        return sample.isEmpty() == false;
      } catch (System.QueryException ex) {
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
          Logger.warn('Nebula Logger - Failed to evaluate registered purge query for ' + sobjectType + ': ' + ex.getMessage());
        }
        return false;
      }
    }

    private Integer getLogEntryTagCount() {
      return [
        SELECT COUNT()
        FROM LogEntryTag__c
        WHERE LogEntry__r.Log__r.LogRetentionDate__c <= :RETENTION_END_DATE AND LogEntry__r.Log__r.LogRetentionDate__c != NULL
      ];
    }

    private Integer getLogEntryCount() {
      return [SELECT COUNT() FROM LogEntry__c WHERE Log__r.LogRetentionDate__c <= :RETENTION_END_DATE AND Log__r.LogRetentionDate__c != NULL];
    }
  }
}
