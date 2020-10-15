/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/

public without sharing class FlowLogRepo {

    /**
     * Returns the current Log created to the Flow so that you can redirect a user to the Log record when required
     *
     * @param  `List<String>` - should be populated with the single Transaction Id for the Log you'd like to retrieve the Id for
     * @return `List<Log__c>` - due to current Flow limitations, we return a list, but it will only ever have one Log__c entry in it
     */
    @InvocableMethod(category='Logging' label='Retrieve current Log ID' description='Returns the created log to aid in record redirects if desired.')
    public static List<Log__c> getLogIds() {
        List<Log__c> logs = [SELECT Id FROM Log__c WHERE TransactionId__c = :Logger.getTransactionId() LIMIT 1];
        return logs.isEmpty() ? null : logs;
    }
}