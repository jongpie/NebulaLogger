# Log Entry Page Section LWC

This Lightning Web Component provides a flexible way to display different sections of LogEntry__c data on record pages. It reuses the `loggerPageSection` component and dynamically displays fields based on the selected section type.

## Features

- **Scalable Design**: Easy to add new section types in the future
- **Dynamic Field Display**: Only shows fields that have data
- **Consistent UI**: Uses the same `loggerPageSection` component for consistent styling
- **Admin Configurable**: Section type is selected when adding to flexipages
- **Code Viewer Integration**: Uses `loggerCodeViewer` for structured data fields
- **Namespace Aware**: Works in both unlocked and managed package scenarios

## Available Section Types

1. **Message** - Displays the log entry message using code viewer
2. **Exception** - Shows exception details including message, type, stack trace, and location
3. **HTTP Request** - Displays HTTP request method, endpoint, headers, and body
4. **HTTP Response** - Shows HTTP response status code, headers, and body
5. **Related Record Details** - Displays related record information

## Code Viewer Integration

The component automatically uses `loggerCodeViewer` for the following fields:

- **Message__c** - Displayed as text
- **ExceptionMessage__c** - Displayed as text
- **HttpRequestBody__c** - Displayed as JSON
- **HttpResponseBody__c** - Displayed as JSON
- **HttpRequestHeaders__c** - Displayed as JSON
- **HttpResponseHeaders__c** - Displayed as JSON
- **ExceptionStackTrace__c** - Displayed as text

Other fields are displayed using standard Lightning components (lightning-textarea for long text, lightning-formatted-text for regular fields).

### Namespace Compatibility

The component is designed to work in both unlocked and managed package scenarios:

- **Unlocked Package**: Field names like `Message__c` work as expected
- **Managed Package**: Field names like `YourNamespace__Message__c` are automatically handled

The code viewer logic uses helper functions that properly handle namespace prefixes by:
1. Removing the `__c` suffix first
2. Splitting on `__` to identify namespace parts
3. Extracting the base field name (the last part)
4. Adding back the `__c` suffix for matching

This ensures compatibility across different deployment scenarios.

## Usage

### Adding to a Flexipage

1. In Lightning App Builder, edit a LogEntry__c record page
2. Add the "Nebula Logger: Log Entry Page Section" component
3. Configure the "Section Type" property to choose which section to display
4. Save and activate the page

### Adding New Section Types

To add a new section type:

1. Add the new section to the `SECTION_FIELD_SETS` constant in `logEntryPageSection.js`
2. Add the corresponding configuration to the `sectionConfig` getter
3. Update the datasource in the meta.xml file
4. Add any new field imports as needed
5. If the new section includes fields that should use code viewer, add them to `CODE_VIEWER_FIELDS`

### Example: Adding a "Browser Information" Section

```javascript
// In logEntryPageSection.js
import BROWSER_USER_AGENT_FIELD from '@salesforce/schema/LogEntry__c.BrowserUserAgent__c';
import BROWSER_ADDRESS_FIELD from '@salesforce/schema/LogEntry__c.BrowserAddress__c';

const SECTION_FIELD_SETS = {
  // ... existing sections
  'Browser Information': [
    BROWSER_USER_AGENT_FIELD,
    BROWSER_ADDRESS_FIELD
  ]
};

// In the sectionConfig getter
get sectionConfig() {
  const configs = {
    // ... existing configs
    'Browser Information': {
      title: 'Browser Information',
      icon: 'utility:desktop'
    }
  };
  return configs[this.sectionType] || { title: this.sectionType, icon: 'utility:info' };
}

// If browser fields should use code viewer
const CODE_VIEWER_FIELDS = {
  // ... existing fields
  'BrowserUserAgent__c': 'text',
  'BrowserAddress__c': 'text'
};
```

## Component Structure

- **JavaScript**: Handles data fetching, field processing, and section configuration
- **HTML**: Uses `c-logger-page-section` for consistent styling and layout
- **Meta XML**: Configures the component for use in Lightning App Builder

## Dependencies

- `c-logger-page-section`: Provides the collapsible section container
- `c-logger-code-viewer`: Provides syntax highlighting for code and structured data
- Lightning UI Record API: For data fetching
- LogEntry__c object: The source of all displayed data

## Namespace Handling

The component includes three helper functions to handle namespace-aware field matching:

- `getCodeViewerFieldName(fieldApiName)`: Extracts the base field name by properly handling namespace prefixes and the `__c` suffix
- `shouldUseCodeViewer(fieldApiName)`: Determines if a field should use the code viewer
- `getCodeViewerLanguage(fieldApiName)`: Gets the appropriate language for syntax highlighting

### Namespace Logic Examples

```javascript
// Unlocked package
getCodeViewerFieldName('Message__c') // Returns 'Message__c'
shouldUseCodeViewer('Message__c') // Returns true

// Managed package
getCodeViewerFieldName('YourNamespace__Message__c') // Returns 'Message__c'
shouldUseCodeViewer('YourNamespace__Message__c') // Returns true

// Complex namespace
getCodeViewerFieldName('Org__Package__Message__c') // Returns 'Message__c'
shouldUseCodeViewer('Org__Package__Message__c') // Returns true
```

This ensures the component works correctly whether deployed as an unlocked package or managed package.
