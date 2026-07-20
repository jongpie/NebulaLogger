// Suggested filter formulas per Source SObject Type, imported by loggerNotificationRuleGuidedForm.
// Admins click one on Step 1 to pre-populate the Source SObject Filter formula; they're free to
// edit the result afterward. Keys must match LoggerNotificationRule__c.SourceSObjectType__c picklist
// values exactly - a mismatch means the suggestions won't render for that SObject.
//
// This is a plain data module rather than a `.json` file because Salesforce's LWC compiler rejects
// non-standard suffixes inside a component bundle (allowed: .js, .html, .css, .svg, .xml). A sibling
// .js re-export is the pragmatic equivalent - the payload below is pure data, and moving it out of
// loggerNotificationRuleGuidedForm.js keeps the component's JS focused on behavior rather than
// content.
//
// Constraints when adding entries:
//   - Formulas MUST compile under `Formula.builder` - the same engine the guided form calls via
//     `validateSourceSObjectFilter` at Next-click AND the plugin's before-save trigger calls at
//     save time. That means `$User` references are rejected (the engine can't resolve them during
//     the wizard's stateless validation callout), and formula fields that INTERNALLY reference
//     `$User` are also rejected. `LogEntry__c.WasLoggedByCurrentUser__c` looks like a valid shortcut
//     but is a formula field wired to `$User.Id`, so it's out too.
//   - Picklist fields must use `ISPICKVAL()` rather than `=`; the docs call this out explicitly.
//   - Multi-line formulas are fine - the syntax-highlighted formula editor renders `\n` correctly
//     and admins can edit multi-line values in place.

const FILTER_SUGGESTIONS = {
  LogEntry__c: [
    {
      label: 'ERROR entries',
      formula: "ISPICKVAL(LoggingLevel__c, 'ERROR')"
    },
    {
      label: 'ERROR or WARN entries',
      formula: "OR(\n  ISPICKVAL(LoggingLevel__c, 'ERROR'),\n  ISPICKVAL(LoggingLevel__c, 'WARN')\n)"
    },
    {
      label: 'Entries mentioning "callout"',
      formula: "ISPICKVAL(LoggingLevel__c, 'ERROR') && CONTAINS(Message__c, 'callout')"
    },
    {
      label: 'Entries with an exception',
      formula: 'HasException__c'
    }
  ],
  Log__c: [
    {
      label: 'Logs with at least one ERROR entry',
      formula: 'TotalERRORLogEntries__c >= 1'
    },
    {
      label: 'Logs with 3+ ERROR entries',
      formula: 'TotalERRORLogEntries__c >= 3'
    }
  ]
};

export default FILTER_SUGGESTIONS;
