/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class LogPurgeScheduler implements System.Schedulable {

    private Integer batchSize;
    private Integer daysToKeep;

    public static Id scheduleDaily(Integer startingHourInDay, Integer batchSize, Integer daysToKeep) {
        String startingHourString = String.valueOf(startingHourInDay);
        startingHourString = startingHourString.leftPad(2, '0');

        String jobName = 'Log Purge: Daily at ' + startingHourString;
        return System.schedule(jobName, '0 ' + startingHourInDay + ' * * * ?', new LogPurgeScheduler(batchSize, daysToKeep));
    }

    public LogPurgeScheduler(Integer batchSize, Integer daysToKeep) {
        this.batchSize  = batchSize;
        this.daysToKeep = daysToKeep;
    }

    public void execute(SchedulableContext sc) {
        // Salesforce has a limit of 5 running batch jobs
        // If there are already 5 jobs running, then don't run this job
        // Any records that need to be processed will be processed the next time the job executes
        if(this.getNumberOfRunningBatchJobs() >= 5) return;

        Database.executebatch(new LogPurger(this.daysToKeep), this.batchSize);
    }

    private Integer getNumberOfRunningBatchJobs() {
        return [SELECT COUNT() FROM AsyncApexJob WHERE JobType='BatchApex' AND Status IN ('Processing', 'Preparing', 'Queued')];
    }

}