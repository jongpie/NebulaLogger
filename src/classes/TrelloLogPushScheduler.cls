/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class TrelloLogPushScheduler implements System.Schedulable {

    public static void scheduleEveryXMinutes(Integer x) {
        for(Integer i = 0; i < 60; i += x) {
            scheduleHourly(i);
        }
    }

    public static void scheduleHourly(Integer startingMinuteInHour) {
        String minuteString = String.valueOf(startingMinuteInHour);
        minuteString = minuteString.leftPad(2, '0');
        scheduleHourly(startingMinuteInHour, 'Trello Log Sync: Every Hour at ' + minuteString);
    }

    public static void scheduleHourly(Integer startingMinuteInHour, String jobName) {
        System.schedule(jobName, '0 ' + startingMinuteInHour + ' * * * ?', new TrelloLogPushScheduler());
    }

    public void execute(SchedulableContext sc) {
        // Salesforce has a limit of 5 running batch jobs
        // If there are already 5 jobs running, then don't run this job
        // Any records that need to be processed will be processed the next time the job executes
        if(this.getNumberOfRunningBatchJobs() >= 5) return;

        Database.executebatch(new TrelloLogPusher(), 100);
    }

    private Integer getNumberOfRunningBatchJobs() {
        return [SELECT COUNT() FROM AsyncApexJob WHERE JobType='BatchApex' AND Status IN ('Processing', 'Preparing', 'Queued')];
    }

}