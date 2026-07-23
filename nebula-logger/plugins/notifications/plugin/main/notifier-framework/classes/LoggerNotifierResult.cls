//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description DTO returned by a `LoggerNotifier` implementation describing the outcome of a delivery attempt.
 *              The `LoggerNotificationProcessor` runtime uses this to populate the corresponding `LoggerNotificationDelivery__c`
 *              record - status, HTTP details, external reference, error message, etc. All fields are optional; a
 *              notifier that returns a bare `new LoggerNotifierResult()` (or `null`) is treated as a plain success.
 */
public class LoggerNotifierResult {
  // TODO move statuses somewhere else, perhaps?
  /**
   * @description Sentinel values the runtime writes for `Status__c`. The picklist is unrestricted so admins can
   *              add their own values without a package upgrade breaking existing records.
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
   *              mode, or the raw webhook URL). Populated by notifiers via the `HttpRequest` constructor.
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
   *              it set to the `HttpRequest` constructor and the runtime reads each value back. See
   *              the plugin backlog for the admin-facing allowlist that would restrict this.
   */
  public String requestHeaders;

  /**
   * @description Apex Job ID of the Queueable that ran this delivery, when the caller is the async
   *              dispatcher. The runtime stamps this onto `LoggerNotificationDelivery__c.JobId__c`
   *              only when the record does not already have one, so re-enqueues past the callout limit
   *              keep the first attempt's job id. Left blank by notifiers themselves.
   */
  public Id jobId;

  /**
   * @description Default constructor - all fields left blank, treated as a plain success by the runtime.
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  public LoggerNotifierResult() {
  }

  /**
   * @description Convenience constructor for a simple delivered outcome with just an HTTP status code.
   * @param status The status to record (typically `STATUS_DELIVERED` or `STATUS_FAILED`).
   * @param httpStatusCode The HTTP status code returned by the callout.
   */
  public LoggerNotifierResult(String status, Integer httpStatusCode) {
    this.status = status;
    this.httpStatusCode = httpStatusCode;
  }

  /**
   * @description Convenience constructor that builds a result from an `HttpResponse`. Sets status based on
   *              the response's 2xx/non-2xx classification and always captures the HTTP status code,
   *              reason, body, and serialized headers so admins can inspect what came back regardless
   *              of whether the delivery succeeded or failed.
   * @param response The HTTP response returned by the callout.
   */
  public LoggerNotifierResult(System.HttpResponse response) {
    if (response == null) {
      return;
    }
    Integer statusCode = response.getStatusCode();
    this.httpStatusCode = statusCode;
    this.httpStatusReason = response.getStatus();
    Boolean isSuccess = statusCode != null && statusCode >= 200 && statusCode < 300;
    this.status = isSuccess ? STATUS_DELIVERED : STATUS_FAILED;
    this.responseBody = response.getBody();
    this.responseHeaders = serializeResponseHeaders(response);
  }

  /**
   * @description Constructor that captures both request and response context. Notifiers should prefer this
   *              over the response-only constructor so `LoggerNotificationDelivery__c` records retain the URL,
   *              method, body, and every header the notifier set alongside the response side. Both request
   *              and response bodies are captured on every delivery so admins can inspect exactly what was
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
   */
  public LoggerNotifierResult(System.HttpRequest request, System.HttpResponse response, List<String> knownRequestHeaders) {
    this(response);
    if (request != null) {
      this.requestUrl = request.getEndpoint();
      this.requestMethod = request.getMethod();
      this.requestBody = request.getBody();
      this.requestHeaders = serializeRequestHeaders(request, knownRequestHeaders);
    }
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

  /**
   * @description Copies this result's fields onto every delivery record for one (rule, recipient) dispatch
   *              and stamps the timing fields. Called by both the sync runtime and the async dispatcher.
   *              A blank `status` on this result defaults to `STATUS_DELIVERED`.
   * @param deliveries The delivery records to update.
   * @param dispatchStart When the notifier invocation started.
   * @param dispatchEnd When the notifier invocation returned.
   */
  public void finalizeDeliveries(List<LoggerNotificationDelivery__c> deliveries, Datetime dispatchStart, Datetime dispatchEnd) {
    if (deliveries == null || deliveries.isEmpty()) {
      return;
    }
    String effectiveStatus = String.isNotBlank(this.status) ? this.status : STATUS_DELIVERED;
    Long durationMs = dispatchStart != null && dispatchEnd != null ? (dispatchEnd.getTime() - dispatchStart.getTime()) : null;
    String truncatedRequestUrl = LoggerDataStore.truncateFieldValue(Schema.LoggerNotificationDelivery__c.RequestUrl__c, this.requestUrl);
    String truncatedRequestMethod = LoggerDataStore.truncateFieldValue(Schema.LoggerNotificationDelivery__c.RequestMethod__c, this.requestMethod);
    String truncatedRequestBody = LoggerDataStore.truncateFieldValue(Schema.LoggerNotificationDelivery__c.RequestBody__c, this.requestBody);
    String truncatedRequestHeaders = LoggerDataStore.truncateFieldValue(Schema.LoggerNotificationDelivery__c.RequestHeaders__c, this.requestHeaders);
    for (LoggerNotificationDelivery__c delivery : deliveries) {
      delivery.Status__c = effectiveStatus;
      delivery.HttpStatusCode__c = this.httpStatusCode;
      delivery.HttpStatusReason__c = this.httpStatusReason;
      delivery.ResponseBody__c = this.responseBody;
      delivery.ResponseHeaders__c = this.responseHeaders;
      delivery.ErrorMessage__c = this.errorMessage;
      delivery.ErrorStackTrace__c = this.errorStackTrace;
      delivery.ExternalReferenceId__c = this.externalReferenceId;
      delivery.ExternalReferenceUrl__c = this.externalReferenceUrl;
      delivery.RequestUrl__c = truncatedRequestUrl;
      delivery.RequestMethod__c = truncatedRequestMethod;
      delivery.RequestBody__c = truncatedRequestBody;
      delivery.RequestHeaders__c = truncatedRequestHeaders;
      delivery.DispatchTimestamp__c = dispatchStart;
      delivery.CompletedTimestamp__c = dispatchEnd;
      delivery.DurationMilliseconds__c = durationMs;
      delivery.AttemptCount__c = (delivery.AttemptCount__c == null ? 0 : delivery.AttemptCount__c) + 1;
      if (this.jobId != null && String.isBlank(delivery.JobId__c)) {
        delivery.JobId__c = this.jobId;
      }
    }
  }
}
