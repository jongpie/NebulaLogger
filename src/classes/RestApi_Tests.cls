/***********************************************************************************************
* This file is part of the Apex Callouts project, released under the MIT License.              *
* See LICENSE file or go to https://github.com/jongpie/ApexCallouts for full license details.  *
***********************************************************************************************/
@isTest
private class RestApi_Tests {

    public class SaveResultCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            RestApi.SaveResult saveResult = new RestApi.SaveResult();
            saveResult.id      = UserInfo.getUserId();
            saveResult.success = true;
            saveResult.errors  = new List<RestApi.SaveError>();

            List<RestApi.SaveResult> saveResults = new List<RestApi.SaveResult>();
            saveResults.add(saveResult);

            HttpResponse response = new HttpResponse();
            response.setBody(Json.serialize(saveResults));
            response.setStatusCode(200);
            return response;
        }
    }

    public class ListViewResultCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            RestApi.ListViewResult listViewResult = new RestApi.ListViewResult();
            listViewResult.id             = UserInfo.getUserId();
            listViewResult.developerName  = 'some_name';
            listViewResult.label          = 'some name';
            listViewResult.sobjectType    = 'Account';
            listViewResult.soqlCompatible = true;
            listViewResult.query          = 'SELECT Id FROM Account';

            HttpResponse response = new HttpResponse();
            response.setBody(Json.serialize(listViewResult));
            response.setStatusCode(200);
            return response;
        }
    }

    @isTest
    static void it_should_insert_records() {
        Test.setMock(HttpCalloutMock.class, new SaveResultCalloutMock());

        List<Account> accounts = new List<Account>();
        Account account = new Account();
        new TestDataFactory(account).populateRequiredFields();
        accounts.add(account);

        Test.startTest();
        RestApi.insertRecords(accounts);
        Test.stopTest();
    }

    @isTest
    static void it_should_update_records() {
        Test.setMock(HttpCalloutMock.class, new SaveResultCalloutMock());

        List<Account> accounts = new List<Account>();
        Account account = new Account();
        new TestDataFactory(account).populateRequiredFields();
        accounts.add(account);

        Test.startTest();
        RestApi.updateRecords(accounts);
        Test.stopTest();
    }

    @isTest
    static void it_should_delete_records() {
        Test.setMock(HttpCalloutMock.class, new SaveResultCalloutMock());

        List<User> users = [SELECT Id FROM User LIMIT 2];

        Test.startTest();
        RestApi.deleteRecords(users);
        Test.stopTest();
    }

    @isTest
    static void it_should_get_list_view() {
        Test.setMock(HttpCalloutMock.class, new ListViewResultCalloutMock());

        List<Account> accounts = new List<Account>();
        Account account = new Account();
        new TestDataFactory(account).populateRequiredFields();
        accounts.add(account);

        Test.startTest();
        RestApi.getListView('Account', null);
        Test.stopTest();
    }

}