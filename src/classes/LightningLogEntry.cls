/*************************************************************************************************
* This file is part of the Nebula Framework project, released under the MIT License.             *
* See LICENSE file or go to https://github.com/jongpie/NebulaFramework for full license details. *
*************************************************************************************************/
public without sharing class LightningLogEntry {

    @AuraEnabled public String componentName    {get; set;}
    @AuraEnabled public String loggingLevelName {get; set;}
    @AuraEnabled public String message          {get; set;}
    @AuraEnabled public Error error             {get; set;}
    @AuraEnabled public String originLocation   {get; set;}
    @AuraEnabled public Datetime timestamp      {get; set;}
    @AuraEnabled public List<String> topics     {get; set;}

    public class Error {
        @AuraEnabled public Integer columnNumber {get; set;}
        @AuraEnabled public Integer lineNumber   {get; set;}
        @AuraEnabled public String message       {get; set;}
        @AuraEnabled public String stack         {get; set;}
    }

}