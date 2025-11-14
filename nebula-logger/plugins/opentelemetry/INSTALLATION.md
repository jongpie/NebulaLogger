# OpenTelemetry Plugin - Quick Installation Guide

## Prerequisites

- Nebula Logger v4.7.1 or newer must be installed in your Salesforce org
- An OpenTelemetry endpoint that accepts OTLP/HTTP JSON format

## Installation Steps

### 1. Deploy the Plugin

Deploy all files from the `nebula-logger/plugins/opentelemetry/plugin` directory to your Salesforce org:

```bash
# Using Salesforce CLI
sf project deploy start --source-dir nebula-logger/plugins/opentelemetry/plugin
```

Or deploy the metadata using your preferred deployment method (VS Code, Workbench, Change Sets, etc.)

### 2. Configure Remote Site Settings (if not using Named Credentials)

1. Go to **Setup** → **Remote Site Settings**
2. Click **New Remote Site**
3. Enter:
   - **Remote Site Name**: `OpenTelemetry`
   - **Remote Site URL**: Your OTLP endpoint base URL (e.g., `https://otel-collector.example.com`)
   - Check **Active**
4. Click **Save**

### 3. Configure Logger Parameters

1. Go to **Setup** → **Custom Metadata Types** → **Logger Parameter** → **Manage Records**

2. Click on **OpenTelemetry Endpoint**:
   - Set **Value**: Your OTLP endpoint URL (e.g., `https://otel-collector.example.com/v1/logs`)
   - Or use Named Credential: `callout:YourNamedCredential`
   - Click **Save**

3. Click on **OpenTelemetry Notification Logging Level**:
   - Set **Value**: The minimum logging level to export (e.g., `WARN`, `ERROR`, `INFO`)
   - Click **Save**

4. (Optional) Configure **OpenTelemetry Service Name**:
   - Set **Value**: A descriptive name for your Salesforce org (e.g., `Salesforce-Production`)
   - Default: `Salesforce`

5. (Optional) Configure **OpenTelemetry Service Version**:
   - Set **Value**: Version identifier (e.g., `1.0.0`, `2023-Q4`)
   - Default: `1.0.0`

6. (Optional) Configure **OpenTelemetry Auth Header** (if not using Named Credentials):
   - Set **Value**: Authentication header in format `HeaderName: HeaderValue`
   - Example: `Authorization: Bearer your-api-token`
   - Or: `x-api-key: your-api-key`
   - Leave blank if using Named Credentials

### 4. Enable the Plugin

1. Go to **Setup** → **Custom Metadata Types** → **Logger Plugin** → **Manage Records**
2. Click on **OpenTelemetry integration**
3. Ensure **Is Enabled** is checked
4. Click **Save**

### 5. Assign Permissions (Optional)

If you want users to be able to view/edit the OpenTelemetry fields on Log records:

1. Go to **Setup** → **Permission Sets**
2. Find **Nebula Logger: OpenTelemetry Plugin Admin**
3. Assign it to the appropriate users or integrate it into your permission set groups

### 6. Test the Integration

Create a test log to verify the integration:

```apex
// Execute in Anonymous Apex
Logger.error('Testing OpenTelemetry integration');
Logger.saveLog();
```

Then verify:
1. Check the **Log** record created
2. The **Send to OpenTelemetry** field should be checked (if the logging level meets the threshold)
3. After a few seconds, the **OpenTelemetry Export Date** field should be populated
4. Check your OpenTelemetry backend to see the log entry

---

## Troubleshooting

### Logs not appearing in OpenTelemetry

1. **Check Log Records**:
   - Go to the **Logs** tab
   - Open the list view **All Logs to be Exported to OpenTelemetry**
   - Verify logs appear here
   - Check if **OpenTelemetry Export Date** is populated

2. **Check Debug Logs**:
   - Go to **Setup** → **Debug Logs**
   - Create a debug log for the user
   - Create a new log entry
   - Review the debug log for any errors related to OpenTelemetry

3. **Verify Async Jobs**:
   - Go to **Setup** → **Apex Jobs**
   - Look for `OpenTelemetryLoggerPlugin` jobs
   - Check if any have failed

4. **Check Configuration**:
   - Verify the endpoint URL is correct and accessible
   - Verify authentication is properly configured
   - Ensure Remote Site Settings or Named Credentials are set up

### Common Issues

- **401 Unauthorized**: Check your authentication configuration (Auth Header or Named Credentials)
- **404 Not Found**: Verify the endpoint URL includes the full path (e.g., `/v1/logs`)
- **No callout**: Verify Remote Site Settings are configured for your endpoint domain

---

## Next Steps

1. Review the main [README.md](README.md) for detailed configuration options
2. Explore the data mapping and query examples
3. Configure custom attributes using Logger tags
4. Set up dashboards in your observability platform

## Support

For issues, questions, or contributions, please visit the [Nebula Logger GitHub repository](https://github.com/jongpie/NebulaLogger).

