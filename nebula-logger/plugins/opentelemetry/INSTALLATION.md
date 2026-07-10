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

### 2. Configure Remote Site Settings OR Named Credentials

You must configure either Remote Site Settings (Option A) OR Named Credentials (Option B - Recommended).

**Option A: Remote Site Settings** (if NOT using Named Credentials)

1. Go to **Setup** → **Remote Site Settings**
2. Click **New Remote Site**
3. Enter:
   - **Remote Site Name**: `OpenTelemetry`
   - **Remote Site URL**: Your OTLP endpoint base URL (e.g., `https://otel-collector.example.com`)
   - Check **Active**
4. Click **Save**

**Option B: Named Credentials** (Recommended - More Secure)

Named Credentials provide better security and don't require Remote Site Settings. See the [detailed Named Credentials setup guide in the main README](README.md#setting-up-named-credentials) for complete instructions.

Quick setup:
1. **Setup** → **Named Credentials** → **External Credentials** → **New**
2. Create External Credential with appropriate authentication protocol
3. Add a principal with your credentials (API key, token, etc.)
4. Add header key value pair in case you are setting the key via header
5. **Named Credentials** → **New** → Link to External Credential and add endpoint URL
6. Select the External Credentials which you created in step 1~3
7. Select callout options (e.g. Generating Auth Header, Allow Formulas in HTTP Header, etc.)
8. **IMPORTANT**: Grant the Automated Process user access to the External Credential (see detailed steps below)

### 3. Grant Access to External Credential (Required for Named Credentials)

If you're using Named Credentials, you MUST grant the Automated Process user access to the External Credential. Without this, you'll get an error: "We couldn't access the credential(s)."

**Steps to Grant Access:**

1. Go to **Setup** → **Permission Sets** → Click **New**
2. Create a new permission set:
   - **Label**: `OpenTelemetry External Credential Access` (or any name you prefer)
   - **API Name**: `OpenTelemetry_External_Credential_Access`
   - **License**: Select `--None--`
3. Click **Save**

4. On the permission set detail page:
   - Scroll down to **External Credential Principal Access** section
   - Click **Edit**
   - Find your External Credential Principal (e.g., "honeycomb - Default" or whatever you named it)
   - Select it and click **Add** to move it to the **Enabled External Credential Principal Access** section
   - Click **Save**

5. Assign the permission set to the Automated Process user:
   - Still on the permission set detail page, click **Manage Assignments**
   - Click **Add Assignment**
   - In the search box, type "Automated Process"
   - Select the **Automated Process** user (it should show "System User" as the User Type)
   - Click **Assign**
   - Click **Done**

6. Verify the assignment:
   - Go back to the permission set detail page
   - You should see "Automated Process" in the list of assigned users

**Troubleshooting:**
- If you can't find "Automated Process" user, make sure you're searching for it (not filtering by profile)
- If the error persists, verify the External Credential name matches exactly what you configured in the Named Credential
- Check that the External Credential Principal is not expired or disabled

### 4. Configure Logger Parameters

1. Go to **Setup** → **Custom Metadata Types** → **Logger Parameter** → **Manage Records**

2. Click on **OpenTelemetry Endpoint**:
   - **Using Direct URL**: Set **Value** to your OTLP endpoint URL (e.g., `https://otel-collector.example.com/v1/logs`)
   - **Using Named Credential** (Recommended): Set **Value** to `callout:YourNamedCredentialAPIName` (e.g., `callout:OpenTelemetryCollector`)
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

### 5. Enable the Plugin

1. Go to **Setup** → **Custom Metadata Types** → **Logger Plugin** → **Manage Records**
2. Click on **OpenTelemetry integration**
3. Ensure **Is Enabled** is checked
4. Click **Save**

### 6. Assign Permissions (Optional)

If you want users to be able to view/edit the OpenTelemetry fields on Log records:

1. Go to **Setup** → **Permission Sets**
2. Find **Nebula Logger: OpenTelemetry Plugin Admin**
3. Assign it to the appropriate users or integrate it into your permission set groups

### 7. Test the Integration

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

- **"We couldn't access the credential(s)" error**: 
  - **MOST COMMON ISSUE**: The Automated Process user doesn't have access to the External Credential Principal
  - **Solution**: Follow the steps in Section 3 above to grant access via a permission set
  - Verify the External Credential name matches exactly (case-sensitive)
  - Ensure the permission set assignment to Automated Process user was successful
  
- **401 Unauthorized**: 
  - Check your Named Credential authentication configuration
  - Verify the External Credential Principal has correct credentials
  - Ensure "Generate Authorization Header" is checked on the Named Credential if using Bearer token authentication
  
- **404 Not Found**: Verify the endpoint URL includes the full path (e.g., `/v1/logs`)

- **No callout**: 
  - If using direct URL: Verify Remote Site Settings are configured for your endpoint domain
  - If using Named Credentials: Verify the Automated Process user has access to the External Credential Principal (via permission set)

- **"You do not have the level of access necessary"**: The Automated Process user needs the permission set with External Credential Principal Access assigned (see Section 3)

---

## Next Steps

1. Review the main [README.md](README.md) for detailed configuration options
2. Explore the data mapping and query examples
3. Configure custom attributes using Logger tags
4. Set up dashboards in your observability platform

## Support

For issues, questions, or contributions, please visit the [Nebula Logger GitHub repository](https://github.com/jongpie/NebulaLogger).

