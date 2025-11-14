# OpenTelemetry plugin for Nebula Logger

> :information_source: This plugin requires `v4.7.1` or newer of Nebula Logger's unlocked package

Adds an OpenTelemetry integration for the unlocked package edition of Nebula Logger. Any logs with log entries that meet a certain (configurable) logging level will automatically be exported to your OpenTelemetry endpoint via an asynchronous `Queueable` job using the OTLP (OpenTelemetry Protocol) JSON format.

---

## What's Included

This plugin includes some add-on metadata for Nebula Logger to support the OpenTelemetry integration

1. Apex class `OpenTelemetryLoggerPlugin` and corresponding tests in `OpenTelemetryLoggerPlugin_Tests`
2. Plugin configuration details stored in Logger's CMDT objects `LoggerPlugin__mdt` and `LoggerParameter__mdt`
3. Custom fields `Log__c.SendToOpenTelemetry__c` and `Log__c.OpenTelemetryExportDate__c`
4. Field-level security (FLS) via a new permission set `LoggerOpenTelemetryPluginAdmin` to provide access to the custom OpenTelemetry fields
5. Two custom list views for the `Log__c` object to see any `Log__c` records that have been, or should be, exported to OpenTelemetry

---

## OpenTelemetry Overview

OpenTelemetry (OTEL) is an open-source observability framework that provides vendor-neutral APIs and tools for collecting telemetry data (logs, metrics, and traces). This plugin sends Salesforce logs to any OpenTelemetry-compatible backend such as:

- OpenTelemetry Collector
- Grafana Loki
- Elastic Stack
- Datadog
- New Relic
- Honeycomb
- AWS X-Ray
- Azure Monitor
- Google Cloud Operations
- And many more...

### OTLP Format

This plugin uses the OTLP (OpenTelemetry Protocol) JSON format for sending logs. Each Salesforce log is converted into OpenTelemetry LogRecords with:

- **Timestamp**: Nanosecond precision timestamp
- **Severity**: Mapped from Salesforce logging levels to OTEL severity numbers
- **Body**: The main log message
- **Attributes**: Key-value pairs including:
  - Transaction ID
  - User information
  - Organization ID
  - Exception details
  - Stack traces
  - Salesforce limits information
- **Trace Context**: Using Transaction ID as trace ID for distributed tracing correlation

---

## Installation Steps

In order to use the OpenTelemetry plugin, there are some configuration changes needed in both your OpenTelemetry backend and Salesforce.

### OpenTelemetry Backend Setup

You'll need an OpenTelemetry endpoint that accepts OTLP/HTTP JSON format. Options include:

1. **OpenTelemetry Collector** - Deploy your own collector that can forward logs to multiple backends
2. **Managed Services** - Use a managed observability platform that supports OTLP (e.g., Grafana Cloud, Datadog, New Relic)
3. **Self-hosted backends** - Configure backends like Loki, Elasticsearch, etc. to accept OTLP

The endpoint URL should be the OTLP HTTP endpoint, typically ending in `/v1/logs` (e.g., `https://otel-collector.example.com/v1/logs`)

### Salesforce Setup

1. Ensure that you have the unlocked package version of Nebula Logger installed in your org
2. Deploy the OpenTelemetry plugin metadata to your org
3. Go to Setup --> Custom Metadata Types --> Logger Parameters. Configure the following parameters:

   - **Parameter 'OpenTelemetry Endpoint'** - You can configure this endpoint in 1 of 2 ways:
     - Easier but less secure: Paste the OTLP endpoint URL into the `Value__c` field and save the Parameter record
     - More secure: Create a new Named Credential ([see section below for step-by-step instructions](#setting-up-named-credentials)), using the endpoint URL. Within the Parameter 'OpenTelemetry Endpoint', enter `callout:<your named credential>` into the `Value__c` field and save the Parameter record
   
   - **Parameter 'OpenTelemetry Notification Logging Level'** - Set the desired logging level value that should trigger logs to be exported to OpenTelemetry. It controls which logging level (ERROR, WARN, INFO, DEBUG, FINE, FINER, or FINEST) will trigger the exports.
   
   - **Parameter 'OpenTelemetry Service Name'** (Optional) - Set the service name to identify your Salesforce org in the observability platform. Defaults to 'Salesforce' if not specified.
   
   - **Parameter 'OpenTelemetry Service Version'** (Optional) - Set the service version. Defaults to '1.0.0' if not specified.
   
   - **Parameter 'OpenTelemetry Auth Header'** (Optional) - If your endpoint requires authentication and you're not using Named Credentials, you can specify the authentication header here in the format `HeaderName: HeaderValue` (e.g., `Authorization: Bearer your-token` or `x-api-key: your-key`). Leave blank if using Named Credentials or if no authentication is required.

4. If not using Named Credentials, add a Remote Site Setting for your OpenTelemetry endpoint:
   - Go to Setup --> Remote Site Settings --> New Remote Site
   - Enter a name (e.g., 'OpenTelemetry')
   - Enter your OTLP endpoint URL (e.g., `https://otel-collector.example.com`)
   - Check 'Active' and save

The OpenTelemetry integration should now be setup & working - any new logs that meet the specified notification logging level will be exported to your OpenTelemetry backend.

#### Setting up Named Credentials

_Note: these instructions are for setting up the improved Named Credentials, as legacy credentials are deprecated as of Winter '23. For more info, see [Salesforce's documentation](https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm&type=5)._

1. **Create a new External Credential.** This will define how Salesforce should authenticate with the OTLP endpoint.

   - Go to the Named Credentials page in setup, click `New` under the External Credentials tab.
   - Enter a name (for example, `OpenTelemetry Endpoint`)
   - Select the appropriate Authentication Protocol:
     - For API key authentication: Select `Password Authentication` and configure accordingly
     - For bearer token: Select `JWT` or `Password Authentication`
     - For no authentication: Select `No Authentication`

2. **Create a Principle for the External Credential.** This will define the credentials that should be used when calling out to the OTLP endpoint.

   - In the Principals section of the External Credential you just created, click `New`.
   - Enter a parameter name (for example: `Default` or `Standard`).
   - If using authentication, enter the required credentials (API key, username/password, etc.)

3. **Create a new Named Credential.** This is where the OTLP endpoint URL will be stored.

   - Go back to the main Named Credentials page and click `New` in the Named Credentials tab.
   - Enter a name for the Named Credential (for example: `OpenTelemetry_Collector`).
   - Paste the OTLP endpoint URL into the URL field (e.g., `https://otel-collector.example.com/v1/logs`).
   - In the External Credential dropdown, select the one you created in step 1.

4. **Grant the Platform Integration User access to the External Credential.** This will allow the Platform Integration user (the running user for queueable jobs) to make callouts to the OTLP endpoint.

   - Create a new permission set or open an existing one
   - Go to the External Credential Principal Access section of the permission set and grant access to the External Credential you created in step 1.
   - Assign the permission set to the user that runs async jobs (typically the Automated Process user or the user whose context the queueable runs in).

---

## Data Mapping

### Logging Level to Severity Mapping

Salesforce logging levels are mapped to OpenTelemetry severity numbers as follows:

| Salesforce Level | OTEL Severity Number | OTEL Severity Name |
|-----------------|---------------------|-------------------|
| FINEST          | 1                   | TRACE             |
| FINER           | 5                   | DEBUG             |
| FINE            | 9                   | DEBUG2            |
| DEBUG           | 9                   | DEBUG2            |
| INFO            | 13                  | INFO2             |
| WARN            | 17                  | WARN2             |
| ERROR           | 21                  | ERROR2            |

### LogRecord Attributes

The plugin includes the following attributes in each LogRecord:

#### Standard Attributes

- `transaction.id` - Salesforce transaction ID
- `user.name` - Username of the user who created the log
- `organization.id` - Salesforce organization ID
- `api.version` - Salesforce API version used

#### Exception Attributes (when applicable)

- `exception.type` - Exception type (e.g., NullPointerException)
- `exception.message` - Exception message
- `exception.stacktrace` - Exception stack trace

#### Code Attributes

- `code.stacktrace` - Apex stack trace

#### Record Attributes (when applicable)

- `record.id` - Salesforce record ID associated with the log entry

#### Limits Attributes (when applicable)

- `limits.aggregate_queries` - Number of aggregate queries used
- `limits.cpu_time` - CPU time used in milliseconds
- `limits.heap_size` - Heap size used in bytes

### Trace Context

The plugin includes trace context to enable correlation with distributed traces:

- **Trace ID**: Generated from the Salesforce Transaction ID (32-character hex string)
- **Span ID**: Generated from the Log Entry ID (16-character hex string)

This allows you to correlate logs with traces in your observability platform, providing a complete view of transactions across systems.

---

## Usage Examples

### Basic Usage

Once configured, the plugin works automatically. Logs that meet the configured logging level threshold will be automatically exported:

```apex
// This log entry will be exported if the threshold is WARN or lower
Logger.error('Payment processing failed for order ' + orderId);
Logger.saveLog();
```

### With Exception Details

Exception information is automatically captured and mapped to OTEL attributes:

```apex
try {
    processOrder(orderId);
} catch (Exception e) {
    Logger.error('Order processing failed', e);
    Logger.saveLog();
}
```

### With Custom Attributes

Use tags to add custom attributes:

```apex
Logger.error('API call failed')
    .addTag('api.endpoint', 'https://api.example.com/v1/orders')
    .addTag('http.status_code', '500');
Logger.saveLog();
```

---

## Querying Logs in OpenTelemetry

Once your logs are in an OpenTelemetry-compatible backend, you can query them using the platform's query language. Here are some example queries:

### Grafana Loki (LogQL)

```logql
# Find all ERROR logs from the last hour
{service_name="Salesforce"} |= "ERROR"

# Find logs for a specific transaction
{service_name="Salesforce"} | json | transaction_id="1234-5678-90ab"

# Find logs with exceptions
{service_name="Salesforce"} | json | exception_type != ""
```

### Elasticsearch

```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "resource.attributes.service.name": "Salesforce" }},
        { "range": { "severityNumber": { "gte": 17 }}}
      ]
    }
  }
}
```

---

## Troubleshooting

### Logs are not being exported

1. Check that the plugin is enabled:
   - Go to Setup --> Custom Metadata Types --> Logger Plugins
   - Verify that the 'OpenTelemetry integration' record has `IsEnabled__c` = true

2. Check the logging level threshold:
   - Go to Setup --> Custom Metadata Types --> Logger Parameters
   - Verify that 'OpenTelemetry Notification Logging Level' is set to the desired level
   - Ensure your logs meet or exceed this threshold

3. Check the endpoint configuration:
   - Verify the 'OpenTelemetry Endpoint' parameter is correctly configured
   - If using a direct URL, ensure a Remote Site Setting is configured
   - If using Named Credentials, verify the credential is properly configured and has the correct permissions

4. Check for errors:
   - Look for logs created by the plugin itself (they should contain "OpenTelemetry" in the message)
   - Check the custom fields on your Log records:
     - `SendToOpenTelemetry__c` should be true for logs that should be exported
     - `OpenTelemetryExportDate__c` should be populated after successful export

### HTTP Callout Errors

If you're seeing HTTP errors:

1. **401 Unauthorized**: Check your authentication configuration
   - Verify the `OpenTelemetry Auth Header` parameter or Named Credential credentials
   
2. **404 Not Found**: Verify the endpoint URL is correct
   - Ensure it includes the full path (e.g., `/v1/logs`)
   
3. **SSL/TLS Errors**: Ensure your endpoint uses a valid SSL certificate
   - Self-signed certificates may require additional configuration in Salesforce

### Governor Limits

The plugin is designed to handle governor limits efficiently:

- Callouts are made asynchronously via queueable jobs
- If the callout limit is reached, remaining logs are queued in a new job
- Each log is processed individually to prevent bulk failures

---

## Performance Considerations

- **Async Processing**: All OpenTelemetry exports are performed asynchronously to avoid impacting user transactions
- **Batch Processing**: Multiple log entries from the same transaction are sent together
- **Governor Limits**: The plugin respects Salesforce governor limits and chains queueable jobs when needed
- **Network Overhead**: Each export requires an HTTP callout; consider the logging level threshold to balance observability with network overhead

---

## Security Best Practices

1. **Use Named Credentials**: Instead of storing endpoint URLs and API keys directly in custom metadata, use Named Credentials for better security
2. **Restrict Field Access**: Use the provided permission set to control who can view/edit the OpenTelemetry fields
3. **Monitor Callouts**: Regularly review callout logs to detect any unauthorized access attempts
4. **Secure Your Endpoint**: Ensure your OTLP endpoint uses HTTPS and proper authentication
5. **Data Sensitivity**: Be mindful of sensitive data in logs; Nebula Logger's data masking features apply before export

---

## Compatibility

- **Nebula Logger**: Requires v4.7.1 or newer
- **Salesforce API**: Tested with API version 62.0
- **OTLP Version**: Supports OTLP/HTTP JSON format 1.0.0
- **OpenTelemetry Specification**: Complies with OpenTelemetry Logs Data Model specification

---

## Contributing

Found a bug or have a feature request? Please open an issue on the [Nebula Logger GitHub repository](https://github.com/jongpie/NebulaLogger/issues).

---

## License

This plugin is released under the MIT License as part of the Nebula Logger project. See the main project LICENSE file for details.

