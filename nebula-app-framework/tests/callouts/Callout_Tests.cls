/***********************************************************************************************
* This file is part of the Apex Callouts project, released under the MIT License.              *
* See LICENSE file or go to https://github.com/jongpie/ApexCallouts for full license details.  *
***********************************************************************************************/
@isTest
private class Callout_Tests {

    public class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(200);
            return response;
        }
    }

    public class FailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(400);
            return response;
        }
    }

    @isTest
    static void it_should_set_compressed_and_return_get_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Callout callout = new Callout('myNamedCredential', '/test').setCompressed();
        callout.get();

        System.assert(callout.request.getCompressed());
    }

    @isTest
    static void it_should_set_compressed_and_return_get_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Callout callout = new Callout('https://example.com').setCompressed();
        callout.get();

        System.assert(callout.request.getCompressed());
    }

    @isTest
    static void it_should_set_headers_and_return_get_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        String headerKey = 'myKey';
        String headerValue = 'myValue';

        Callout callout = new Callout('myNamedCredential', '/test').setHeader(headerKey, headerValue);
        callout.get();

        System.assertEquals(headerValue, callout.request.getHeader(headerKey));
    }

    @isTest
    static void it_should_set_headers_and_return_get_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        String headerKey = 'myKey';
        String headerValue = 'myValue';

        Callout callout = new Callout('https://example.com').setHeader(headerKey, headerValue);
        callout.get();

        System.assertEquals(headerValue, callout.request.getHeader(headerKey));
    }

    @isTest
    static void it_should_set_parameters_and_return_get_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        String parameterKey = 'myKey';
        String parameterValue = 'myValue';

        Callout callout = new Callout('myNamedCredential', '/test').setParameter(parameterKey, parameterValue);
        callout.get();

        String parameter = parameterKey + '=' + parameterValue;
        System.assert(callout.request.getEndpoint().contains(parameter), callout.request.getEndpoint());
    }

    @isTest
    static void it_should_set_parameters_and_return_get_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        String parameterKey = 'myKey';
        String parameterValue = 'myValue';

        Callout callout = new Callout('https://example.com').setParameter(parameterKey, parameterValue);
        callout.get();

        String parameter = parameterKey + '=' + parameterValue;
        System.assert(callout.request.getEndpoint().contains(parameter), callout.request.getEndpoint());
    }

    @isTest
    static void it_should_set_timeout_and_return_get_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Callout callout = new Callout('myNamedCredential', '/test').setTimeout(600);
        callout.get();
    }

    @isTest
    static void it_should_set_timeout_and_return_get_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Callout callout = new Callout('https://example.com').setTimeout(600);
        callout.get();
    }

    @isTest
    static void it_should_return_del_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').del();
    }

    @isTest
    static void it_should_return_del_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').del();
    }

    @isTest
    static void it_should_return_get_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').get();
    }

    @isTest
    static void it_should_return_get_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').get();
    }

    @isTest
    static void it_should_return_head_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').head();
    }

    @isTest
    static void it_should_return_head_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').head();
    }

    @isTest
    static void it_should_return_patch_for_blob_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Blob theBlob = Blob.valueof('StringToBlob');
        HttpResponse response = new Callout('myNamedCredential', '/test').patch(theBlob);
    }

    @isTest
    static void it_should_return_patch_for_blob_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Blob theBlob = Blob.valueof('StringToBlob');
        HttpResponse response = new Callout('https://example.com').patch(theBlob);
    }

    @isTest
    static void it_should_return_patch_for_dom_document_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Dom.Document domDocument = new Dom.Document();
        domDocument.load('<myxmlnode />');
        HttpResponse response = new Callout('myNamedCredential', '/test').patch(domDocument);
    }

    @isTest
    static void it_should_return_patch_for_dom_document_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Dom.Document domDocument = new Dom.Document();
        domDocument.load('<myxmlnode />');
        HttpResponse response = new Callout('https://example.com').patch(domDocument);
    }

    @isTest
    static void it_should_return_patch_for_sobject_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').patch(new Account(Name='Test'));
    }

    @isTest
    static void it_should_return_patch_for_sobject_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').patch(new Account(Name='Test'));
    }

    @isTest
    static void it_should_return_post_for_blob_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Blob theBlob = Blob.valueof('StringToBlob');
        HttpResponse response = new Callout('myNamedCredential', '/test').post(theBlob);
    }

    @isTest
    static void it_should_return_post_for_blob_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Blob theBlob = Blob.valueof('StringToBlob');
        HttpResponse response = new Callout('https://example.com').post(theBlob);
    }

    @isTest
    static void it_should_return_post_for_dom_document_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').post(new Account(Name='Test'));
    }

    @isTest
    static void it_should_return_post_for_dom_document_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Dom.Document domDocument = new Dom.Document();
        domDocument.load('<myxmlnode />');
        HttpResponse response = new Callout('https://example.com').post(domDocument);
    }

    @isTest
    static void it_should_return_post_for_sobject_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Dom.Document domDocument = new Dom.Document();
        domDocument.load('<myxmlnode />');
        HttpResponse response = new Callout('myNamedCredential', '/test').post(domDocument);
    }

    @isTest
    static void it_should_return_post_for_sobject_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').post(new Account(Name='Test'));
    }

    @isTest
    static void it_should_return_put_for_blob_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Blob theBlob = Blob.valueof('StringToBlob');
        HttpResponse response = new Callout('myNamedCredential', '/test').put(theBlob);
    }

    @isTest
    static void it_should_return_put_for_blob_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Blob theBlob = Blob.valueof('StringToBlob');
        HttpResponse response = new Callout('https://example.com').put(theBlob);
    }

    @isTest
    static void it_should_return_put_for_dom_document_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Dom.Document domDocument = new Dom.Document();
        domDocument.load('<myxmlnode />');
        HttpResponse response = new Callout('myNamedCredential', '/test').put(domDocument);
    }

    @isTest
    static void it_should_return_put_for_dom_document_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Dom.Document domDocument = new Dom.Document();
        domDocument.load('<myxmlnode />');
        HttpResponse response = new Callout('https://example.com').put(domDocument);
    }

    @isTest
    static void it_should_return_put_for_sobject_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').put(new Account(Name='Test'));
    }

    @isTest
    static void it_should_return_put_for_sobject_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').put(new Account(Name='Test'));
    }

    @isTest
    static void it_should_return_trace_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('myNamedCredential', '/test').trace();
    }

    @isTest
    static void it_should_return_trace_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        HttpResponse response = new Callout('https://example.com').trace();
    }

    @isTest
    static void it_should_throw_exception_for_status_code_400_for_named_credential_endpoint() {
        Test.setMock(HttpCalloutMock.class, new FailureCalloutMock());

        try {
            HttpResponse response = new Callout('myNamedCredential', '/test').get();
            System.assert(false, 'Exception expected here');
        } catch(Callout.HttpResponseException e) {
            System.assert(e.getMessage().startsWith('Callout failed'));
        }
    }

    @isTest
    static void it_should_throw_exception_for_status_code_400_for_full_endpoint() {
        Test.setMock(HttpCalloutMock.class, new FailureCalloutMock());

        try {
            HttpResponse response = new Callout('https://example.com').get();
            System.assert(false, 'Exception expected here');
        } catch(Callout.HttpResponseException e) {
            System.assert(e.getMessage().startsWith('Callout failed'));
        }
    }

}