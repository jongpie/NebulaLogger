/***********************************************************************************************
* This file is part of the Apex Callouts project, released under the MIT License.              *
* See LICENSE file or go to https://github.com/jongpie/ApexCallouts for full license details.  *
***********************************************************************************************/
public with sharing class RestApi {

    private static Boolean ALL_OR_NONE_DEFAULT       = true;
    private static String BASE_URL                   = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v49.0';
    private static String COMPOSITE_ENDPOINT         = BASE_URL + '/composite/sobjects';
    private static String LISTVIEW_ENDPOINT          = BASE_URL + '/sobjects/{0}/listviews/{1}';
    private static String LISTVIEW_DESCRIBE_ENDPOINT = LISTVIEW_ENDPOINT + '/describe';

    public static List<RestApi.SaveResult> insertRecords(List<SObject> records) {
        return insertRecords(records, ALL_OR_NONE_DEFAULT);
    }

    public static List<RestApi.SaveResult> insertRecords(List<SObject> records, Boolean allOrNone) {
        HttpResponse response = getRestApiCallout(COMPOSITE_ENDPOINT)
            .post(new RestApi.SaveRequest(records, allOrNone));

        return getSaveResults(response);
    }

    public static List<RestApi.SaveResult> updateRecords(List<SObject> records) {
        return updateRecords(records, ALL_OR_NONE_DEFAULT);
    }

    public static List<RestApi.SaveResult> updateRecords(List<SObject> records, Boolean allOrNone) {
        HttpResponse response = getRestApiCallout(COMPOSITE_ENDPOINT)
            .setParameter('_HttpMethod', 'PATCH')
            .post(new RestApi.SaveRequest(records, allOrNone));

        return getSaveResults(response);
    }

    public static List<RestApi.SaveResult> deleteRecords(List<SObject> records) {
        return deleteRecords(records, ALL_OR_NONE_DEFAULT);
    }

    public static List<RestApi.SaveResult> deleteRecords(List<SObject> records, Boolean allOrNone) {
        List<Id> recordIds = new List<Id>(new Map<Id, SObject>(records).keySet());

        return deleteRecords(recordIds, allOrNone);
    }

    public static List<RestApi.SaveResult> deleteRecords(List<Id> recordIds) {
        return deleteRecords(recordIds, ALL_OR_NONE_DEFAULT);
    }

    public static List<RestApi.SaveResult> deleteRecords(List<Id> recordIds, Boolean allOrNone) {
        HttpResponse response = getRestApiCallout(COMPOSITE_ENDPOINT)
            .setParameter('allOrNone', String.valueOf(allOrNone))
            .setParameter('ids', String.join(recordIds, ','))
            .del();

        return getSaveResults(response);
    }

    public static ListViewResult getListView(String sobjectName, Id listViewFilterId) {
        // In order to get all details about a list view, 2 callouts are needed
        // TODO see if there is a way to consolidate these into a single call
        List<String> endpointParameters = new List<String>{sobjectName, listViewFilterId};

        String listViewEndpoint       = String.format(LISTVIEW_ENDPOINT, endpointParameters);
        HttpResponse listViewResponse = getRestApiCallout(listViewEndpoint).get();

        String listViewDescribeEndpoint       = String.format(LISTVIEW_DESCRIBE_ENDPOINT, endpointParameters);
        HttpResponse listViewDescribeResponse = getRestApiCallout(listViewDescribeEndpoint).get();

        return getListViewResult(listViewResponse, listViewDescribeResponse);
    }

    public static Callout getRestApiCallout(String endpoint) {
        return new Callout(endpoint)
            .setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId())
            .setHeader('Content-Type', 'application/json');
    }

    private static ListViewResult getListViewResult(HttpResponse listViewResponse, HttpResponse listViewDescribeResponse) {
        ListViewResult listView         = (ListViewResult)Json.deserialize(listViewResponse.getBody(), ListViewResult.class);
        ListViewResult listViewDescribe = (ListViewResult)Json.deserialize(listViewDescribeResponse.getBody(), ListViewResult.class);

        listView.query = listViewDescribe.query;

        return listView;
    }

    private static List<RestApi.SaveResult> getSaveResults(HttpResponse response) {
        return (List<SaveResult>)Json.deserialize(response.getBody(), List<SaveResult>.class);
    }

    public class ListViewResult {
        public Id id                  {get; set;}
        public String developerName   {get; set;}
        public String label           {get; set;}
        public String sobjectType     {get; set;}
        public Boolean soqlCompatible {get; set;}
        public String query           {get; set;}
    }

    public class SaveRequest {
        public Boolean allOrNone     {get; set;}
        public List<SObject> records {get; set;}

        public SaveRequest(List<SObject> records, Boolean allOrNone) {
            this.allOrNone = allOrNone;
            this.records   = records;
        }
    }

    public class SaveResult {
        public Id id                          {get; set;}
        public Boolean success                {get; set;}
        public List<RestApi.SaveError> errors {get; set;}
    }

    public class SaveError {
        public String statusCode   {get; set;}
	    public String message      {get; set;}
        public List<String> fields {get; set;}
    }

}