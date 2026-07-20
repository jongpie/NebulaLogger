//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifiableResult_Tests {
  @IsTest
  static void fromHttpResponse_should_mark_2xx_as_delivered_and_capture_response_body_and_headers() {
    System.HttpResponse response = buildResponse(200, 'OK', '{"ok":true}');
    response.setHeader('Content-Type', 'application/json');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpResponse(response);

    System.Assert.areEqual(LoggerNotifiableResult.STATUS_DELIVERED, result.status);
    System.Assert.areEqual(200, result.httpStatusCode);
    System.Assert.areEqual('OK', result.httpStatusReason);
    System.Assert.areEqual('{"ok":true}', result.responseBody, 'Response body should be captured on successful deliveries too');
    System.Assert.isTrue(
      result.responseHeaders.contains('Content-Type: application/json'),
      'Response headers should be captured on success: ' + result.responseHeaders
    );
  }

  @IsTest
  static void fromHttpResponse_should_mark_non_2xx_as_failed_and_capture_response_body_and_headers() {
    System.HttpResponse response = buildResponse(500, 'Internal Server Error', '{"error":"boom"}');
    response.setHeader('Content-Type', 'application/json');
    response.setHeader('X-Trace-Id', 'abc-123');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpResponse(response);

    System.Assert.areEqual(LoggerNotifiableResult.STATUS_FAILED, result.status);
    System.Assert.areEqual('{"error":"boom"}', result.responseBody, 'Failure responses capture the body for troubleshooting');
    System.Assert.isTrue(result.responseHeaders.contains('Content-Type: application/json'), 'Failure responses capture headers: ' + result.responseHeaders);
    System.Assert.isTrue(
      result.responseHeaders.contains('X-Trace-Id: abc-123'),
      'All response headers should be captured on failure: ' + result.responseHeaders
    );
  }

  @IsTest
  static void fromHttpRequestAndResponse_should_capture_request_url_method_and_body_always() {
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint('https://example.com/webhook');
    request.setMethod('POST');
    request.setBody('{"payload":"body"}');
    System.HttpResponse response = buildResponse(200, 'OK', '');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, null);

    // Request fields are captured on successful deliveries too - the whole point is troubleshooting.
    System.Assert.areEqual('https://example.com/webhook', result.requestUrl);
    System.Assert.areEqual('POST', result.requestMethod);
    System.Assert.areEqual('{"payload":"body"}', result.requestBody);
    System.Assert.isNull(result.requestHeaders, 'A null allowlist should skip header capture entirely');
  }

  @IsTest
  static void fromHttpRequestAndResponse_should_only_capture_headers_the_notifier_names() {
    // Apex HttpRequest offers no getHeaderKeys(), so the runtime can only capture headers the notifier
    // hands forward. Whatever names the notifier passes get captured verbatim - this is enumeration,
    // not a security filter. Admin-facing allowlisting is tracked as a separate backlog item.
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint('https://example.com/webhook');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('X-Trace-Id', 'trace-abc-123');
    request.setHeader('X-Never-Announced', 'invisible-because-notifier-did-not-name-it');
    System.HttpResponse response = buildResponse(200, 'OK', '');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, new List<String>{ 'Content-Type', 'X-Trace-Id' });

    System.Assert.isTrue(result.requestHeaders.contains('Content-Type: application/json'), 'Named headers should appear: ' + result.requestHeaders);
    System.Assert.isTrue(result.requestHeaders.contains('X-Trace-Id: trace-abc-123'), 'Named headers should appear: ' + result.requestHeaders);
    System.Assert.isFalse(
      result.requestHeaders.contains('X-Never-Announced'),
      'Headers the notifier did not hand forward cannot be captured (no getHeaderKeys() on HttpRequest): ' + result.requestHeaders
    );
  }

  @IsTest
  static void fromHttpRequestAndResponse_should_return_null_headers_when_no_names_supplied() {
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint('https://example.com/webhook');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    System.HttpResponse response = buildResponse(200, 'OK', '');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, new List<String>());

    System.Assert.isNull(result.requestHeaders, 'An empty header-name list should skip header capture, same as null');
  }

  @IsTest
  static void fromHttpRequestAndResponse_should_omit_named_headers_that_were_never_set() {
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint('https://example.com/webhook');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    System.HttpResponse response = buildResponse(200, 'OK', '');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, new List<String>{ 'Content-Type', 'X-Never-Set' });

    System.Assert.isTrue(result.requestHeaders.contains('Content-Type'), 'Set headers should appear: ' + result.requestHeaders);
    System.Assert.isFalse(result.requestHeaders.contains('X-Never-Set'), 'Named headers that were not set should not appear: ' + result.requestHeaders);
  }

  @IsTest
  static void fromHttpRequestAndResponse_should_still_carry_response_fields_forward() {
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint('https://example.com/webhook');
    request.setMethod('POST');
    System.HttpResponse response = buildResponse(500, 'Internal Server Error', '{"error":"boom"}');

    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, null);

    System.Assert.areEqual(LoggerNotifiableResult.STATUS_FAILED, result.status);
    System.Assert.areEqual(500, result.httpStatusCode);
    System.Assert.areEqual('{"error":"boom"}', result.responseBody, 'Response body should still be captured on non-2xx');
  }

  private static System.HttpResponse buildResponse(Integer statusCode, String statusReason, String body) {
    System.HttpResponse response = new System.HttpResponse();
    response.setStatusCode(statusCode);
    response.setStatus(statusReason);
    response.setBody(body);
    return response;
  }
}
