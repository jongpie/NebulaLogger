//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description DTO returned by a `LoggerNotifiable` implementation describing the outcome of a delivery attempt.
 *              The `LoggerNotifier` runtime uses this to populate the corresponding `LoggerNotificationDelivery__c`
 *              row - status, HTTP details, external reference, error message, etc. All fields are optional; a
 *              notifier that returns a bare `new LoggerNotifiableResult()` (or `null`) is treated as a plain success.
 */
public class LoggerNotifiableResult {
  /**
   * @description Sentinel values the runtime writes for `Status__c`. The picklist is unrestricted so admins can
   *              add their own values without a package upgrade breaking existing rows.
   */
  public static final String STATUS_PENDING = 'Pending';
  public static final String STATUS_DELIVERED = 'Delivered';
  public static final String STATUS_FAILED = 'Failed';
  public static final String STATUS_SKIPPED = 'Skipped';
  public static final String STATUS_SUPPRESSED_BY_THRESHOLD = 'Suppressed by Threshold';

  /**
   * @description Outcome of the delivery attempt. Leave blank to let the runtime default to `Delivered` on
   *              non-throw or `Failed` on throw.
   */
  public String status;

  /**
   * @description HTTP status code returned by the callout, when applicable.
   */
  public Integer httpStatusCode;

  /**
   * @description HTTP status reason phrase returned by the callout (e.g. `OK`, `Bad Request`, `Unauthorized`).
   */
  public String httpStatusReason;

  /**
   * @description Response body captured from the callout. Notifiers should populate this on failures for
   *              troubleshooting; on successes it's optional and typically left blank.
   */
  public String responseBody;

  /**
   * @description Response headers captured from the callout, serialized as one `Key: value` per line.
   *              Notifiers should populate this on failures for troubleshooting.
   */
  public String responseHeaders;

  /**
   * @description Error message when the delivery failed but the notifier is reporting the failure explicitly
   *              rather than throwing. If a notifier throws, the runtime catches and stamps this itself.
   */
  public String errorMessage;

  /**
   * @description Apex stack trace captured when the notifier threw an exception. Populated automatically
   *              by the runtime alongside `errorMessage`; notifiers that report failure explicitly (rather
   *              than throwing) leave this blank.
   */
  public String errorStackTrace;

  /**
   * @description Identifier issued by the target system (Slack thread ts, PagerDuty incident id, etc.).
   */
  public String externalReferenceId;

  /**
   * @description Deep link to view this delivery in the target system's UI.
   */
  public String externalReferenceUrl;

  /**
   * @description URL the notifier called out to. Captured for troubleshooting so admins can see the
   *              resolved endpoint (e.g. `callout:SlackWebApi/chat.postMessage` for Named Credential
   *              mode, or the raw webhook URL). Populated by notifiers via `fromHttpRequestAndResponse`.
   */
  public String requestUrl;

  /**
   * @description HTTP method the notifier used (typically `POST`).
   */
  public String requestMethod;

  /**
   * @description Body the notifier sent to the remote service - typically the JSON payload. Trimmed by
   *              the runtime if excessively long.
   */
  public String requestBody;

  /**
   * @description Request headers the notifier sent, serialized as one `Key: value` per line. Because
   *              Apex `HttpRequest` has no `getHeaderKeys()`, the notifier passes every header name
   *              it set to `fromHttpRequestAndResponse` and the runtime reads each value back. See
   *              the plugin backlog for the admin-facing allowlist that would restrict this.
   */
  public String requestHeaders;

  /**
   * @description Apex Job ID of the Queueable that ran this delivery, when the caller is the async
   *              dispatcher. The runtime stamps this onto `LoggerNotificationDelivery__c.JobId__c`
   *              only when the row does not already have one, so re-enqueues past the callout limit
   *              keep the first attempt's job id. Left blank by notifiers themselves.
   */
  public Id jobId;

  /**
   * @description Default constructor - all fields left blank, treated as a plain success by the runtime.
   */
  public LoggerNotifiableResult() {
  }

  /**
   * @description Convenience constructor for a simple delivered outcome with just an HTTP status code.
   * @param status The status to record (typically `STATUS_DELIVERED` or `STATUS_FAILED`).
   * @param httpStatusCode The HTTP status code returned by the callout.
   */
  public LoggerNotifiableResult(String status, Integer httpStatusCode) {
    this.status = status;
    this.httpStatusCode = httpStatusCode;
  }

  /**
   * @description Convenience factory that builds a result from an `HttpResponse`. Sets status based on
   *              the response's 2xx/non-2xx classification and always captures the HTTP status code,
   *              reason, body, and serialized headers so admins can inspect what came back regardless
   *              of whether the delivery succeeded or failed.
   * @param response The HTTP response returned by the callout.
   * @return A populated `LoggerNotifiableResult` ready to hand back to the runtime.
   */
  public static LoggerNotifiableResult fromHttpResponse(System.HttpResponse response) {
    LoggerNotifiableResult result = new LoggerNotifiableResult();
    if (response == null) {
      return result;
    }
    Integer statusCode = response.getStatusCode();
    result.httpStatusCode = statusCode;
    result.httpStatusReason = response.getStatus();
    Boolean isSuccess = statusCode != null && statusCode >= 200 && statusCode < 300;
    result.status = isSuccess ? STATUS_DELIVERED : STATUS_FAILED;
    result.responseBody = response.getBody();
    result.responseHeaders = serializeResponseHeaders(response);
    return result;
  }

  /**
   * @description Factory that captures both request and response context. Notifiers should prefer this
   *              over `fromHttpResponse` so `LoggerNotificationDelivery__c` rows retain the URL, method,
   *              body, and every header the notifier set alongside the response side. Both request and
   *              response bodies are captured on every delivery so admins can inspect exactly what was
   *              sent and received on both successful and failed deliveries.
   *
   *              Apex `HttpRequest` exposes no `getHeaderKeys()`, so the runtime cannot enumerate the
   *              headers a notifier set on its own. The notifier passes `knownRequestHeaders` naming
   *              every header it set - the runtime then reads each name via `request.getHeader(name)` to
   *              capture the value. This is not a security filter (see the Backlog for the admin-facing
   *              allowlist that IS a security filter, and lives on the service record); it exists only
   *              because Apex has no other way to enumerate outgoing headers.
   * @param request The HTTP request the notifier sent.
   * @param response The HTTP response returned by the callout.
   * @param knownRequestHeaders Every header name the notifier set on the request, so the runtime can
   *                            read its value back. Blank/null skips request-header capture.
   * @return A populated `LoggerNotifiableResult` ready to hand back to the runtime.
   */
  public static LoggerNotifiableResult fromHttpRequestAndResponse(System.HttpRequest request, System.HttpResponse response, List<String> knownRequestHeaders) {
    LoggerNotifiableResult result = fromHttpResponse(response);
    if (request != null) {
      result.requestUrl = request.getEndpoint();
      result.requestMethod = request.getMethod();
      result.requestBody = request.getBody();
      result.requestHeaders = serializeRequestHeaders(request, knownRequestHeaders);
    }
    return result;
  }

  private static String serializeResponseHeaders(System.HttpResponse response) {
    String[] headerKeys = response.getHeaderKeys();
    if (headerKeys == null || headerKeys.isEmpty()) {
      return null;
    }
    List<String> lines = new List<String>();
    for (String key : headerKeys) {
      lines.add(key + ': ' + response.getHeader(key));
    }
    return String.join(lines, '\n');
  }

  private static String serializeRequestHeaders(System.HttpRequest request, List<String> knownHeaderNames) {
    if (knownHeaderNames == null || knownHeaderNames.isEmpty()) {
      return null;
    }
    List<String> lines = new List<String>();
    for (String headerName : knownHeaderNames) {
      if (String.isBlank(headerName)) {
        continue;
      }
      String value = request.getHeader(headerName);
      if (value != null) {
        lines.add(headerName + ': ' + value);
      }
    }
    return lines.isEmpty() ? null : String.join(lines, '\n');
  }
}
