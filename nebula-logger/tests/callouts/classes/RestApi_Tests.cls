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

        User user = new User(
            FirstName = 'Test insert',
            Id        = UserInfo.getUserId()
        );
        List<User> users = new List<User>{user};

        Test.startTest();
        List<RestApi.SaveResult> saveResults = RestApi.insertRecords(users);
        Test.stopTest();

        System.assertEquals(1, saveResults.size());

        RestApi.SaveResult saveResult = saveResults.get(0);

        System.assertEquals(UserInfo.getUserId(), saveResult.id);
        System.assertEquals(true, saveResult.success);
        System.assertEquals(true, saveResult.errors.isEmpty());
    }

    @isTest
    static void it_should_update_records() {
        Test.setMock(HttpCalloutMock.class, new SaveResultCalloutMock());

        User user = new User(
            FirstName = 'Test update',
            Id        = UserInfo.getUserId()
        );
        List<User> users = new List<User>{user};

        Test.startTest();
        List<RestApi.SaveResult> saveResults = RestApi.updateRecords(users);
        Test.stopTest();

        System.assertEquals(1, saveResults.size());

        RestApi.SaveResult saveResult = saveResults.get(0);

        System.assertEquals(UserInfo.getUserId(), saveResult.id);
        System.assertEquals(true, saveResult.success);
        System.assertEquals(true, saveResult.errors.isEmpty());
    }

    @isTest
    static void it_should_delete_records() {
        Test.setMock(HttpCalloutMock.class, new SaveResultCalloutMock());

        User user = new User(
            FirstName = 'Test delete',
            Id        = UserInfo.getUserId()
        );
        List<User> users = new List<User>{user};

        Test.startTest();
        List<RestApi.SaveResult> saveResults = RestApi.deleteRecords(users);
        Test.stopTest();

        System.assertEquals(1, saveResults.size());

        RestApi.SaveResult saveResult = saveResults.get(0);

        System.assertEquals(UserInfo.getUserId(), saveResult.id);
        System.assertEquals(true, saveResult.success);
        System.assertEquals(true, saveResult.errors.isEmpty());
    }

    @isTest
    static void it_should_get_list_view() {
        Test.setMock(HttpCalloutMock.class, new ListViewResultCalloutMock());

        Test.startTest();
        RestApi.ListViewResult listViewResult = RestApi.getListView('Account', null);
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), listViewResult.id);
        System.assertEquals('some_name', listViewResult.developerName);
        System.assertEquals('some name', listViewResult.label);
        System.assertEquals('Account', listViewResult.sobjectType);
        System.assertEquals(true, listViewResult.soqlCompatible);
        System.assertEquals('SELECT Id FROM Account', listViewResult.query);
    }

}