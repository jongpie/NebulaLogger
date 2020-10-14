/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/

public without sharing class FlowLogRepo {

    /**
     * Returns the latest Log created to the Flow so that you can redirect a user to the Log record when required
     *
     * @param  `List<String>` - should be populated with the single Transaction Id for the Log you'd like to retrieve the Id for
     * @return `List<Log__c>` - due to current Flow limitations, we return a list, but it will only ever have one Log__c entry in it
     */
    @InvocableMethod(category='Logging' label='Retrieve Log Id by Transaction Id' description='Returns the created log. Please only pass one Transaction Id at a time')
    public static List<Log__c> getLogIds(List<String> transactionId) {
        return [SELECT Id FROM Log__c WHERE TransactionId__c = :transactionId LIMIT 1];
    }
}