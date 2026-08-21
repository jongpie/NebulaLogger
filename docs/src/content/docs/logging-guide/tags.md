---
title: Tags
description: Labeling individual log entries for taxonomy-based filtering and reporting.
---

Where a **scenario** applies to the whole transaction, a **tag** applies to a specific entry. Multiple tags per entry are supported, tag names are free-text, and new tag names auto-create new `LoggerTag__c` records.

## Adding tags

Chain `.addTag(...)` off the level-specific call.

```apex
Logger
  .warn('Credit check returned warnings')
  .setRecord(account)
  .addTag('credit-check')
  .addTag('customer-onboarding');

Logger.saveLog();
```

In LWC:

```js
this.logger.info('Payment submitted').addTag('payment').addTag('checkout').setRecord(this.paymentId);

await this.logger.saveLog();
```

In Flow, the `Tags` input on any `Add Log Entry*` action accepts a semicolon-delimited list: `credit-check;customer-onboarding`.

In OmniStudio, pass `tags` as a `List<String>` input to a `newEntry` Remote Action call.

## Storage model

- Each unique tag name becomes a `LoggerTag__c` record. Reusing an existing tag name reuses the record.
- The join between a `LogEntry__c` and its tags is stored in `LogEntryTag__c` (a junction object).

The console renders tags on the log entry record page and lets you filter list views by them.

## Choosing a tagging mode (unlocked package only)

The default storage above (`LoggerTag__c` + `LogEntryTag__c`) is one of two supported modes. The unlocked package also supports storing tags as Salesforce **Chatter Topics** on each `LogEntry__c` record via the standard `Topic` and `TopicAssignment` objects.

| Aspect                   | Default: `LoggerTag__c` + `LogEntryTag__c`                                                   | Alternative: `Topic` + `TopicAssignment`                                                                                                          |
| ------------------------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Availability**         | Both packages                                                                                | Unlocked package only                                                                                                                             |
| **Data location**        | Custom objects                                                                               | Standard Chatter objects                                                                                                                          |
| **Data visibility**      | Sharing/OWD on `LoggerTag__c`. Junction records inherit access from the related entry + tag. | Every Chatter user can see all `Topic` records org-wide. `TopicAssignment` records are gated by access to the entry.                              |
| **Reports & dashboards** | Full custom-object reporting.                                                                | Chatter Topics [have partial reporting support](https://trailblazer.salesforce.com/ideaView?id=08730000000l12wAAA).                               |
| **List view filtering**  | Standard `LoggerTag__c` filters.                                                             | Chatter Topics filter list views [natively](http://releasenotes.docs.salesforce.com/en-us/winter20/release-notes/rn_lex_lists_topic_filters.htm). |
| **Best for**             | Most orgs. Full control, private-by-default, reportable.                                     | Orgs already invested in Chatter Topics and comfortable with tag names being globally visible.                                                    |

Choose the mode that matches your access-control posture. Neither mode is available for admins to switch on the fly - the choice is a configuration decision made once per org.

## Taxonomy conventions

Because tag names are free-text, teams need a convention or the taxonomy sprawls. Adopt a prefix-per-namespace pattern early.

Common namespaces:

- `domain:*` - what part of the business (`domain:billing`, `domain:orders`).
- `feature:*` - what feature or capability (`feature:credit-check`, `feature:sync`).
- `incident:*` - live incidents (`incident:2026-08-12-payments`).
- `severity:*` - if you need more nuance than the logging level (`severity:actionable`, `severity:info-only`).

Prefixing keeps the taxonomy scannable and lets a list view filter cover a whole namespace at once.

## Auto-tagging via `LogEntryTagRule__mdt`

For tags that should attach to entries automatically based on their content, define a `LogEntryTagRule__mdt` record. Each rule matches on a field's value (`Message__c`, `OriginLocation__c`, etc.) and applies one or more tags when it matches.

Useful when a tag should be applied consistently across every entry meeting a condition - e.g. auto-tag anything logged from `PaymentService.processPayment` with `feature:payments`, or auto-tag anything whose message contains `Rate limit` with `incident:rate-limiting`.

![LogEntryTagRule example](/images/tag-rule-example.png)

Auto-applied tags stack with any tags added at the point of logging - they don't replace them.

## Tags vs scenarios vs logging level

Three orthogonal axes.

- **Logging level** is a severity gradient. `ERROR` -> `FINEST`. Determines whether an entry persists at all (via `LoggerSettings__c.LoggingLevel__c`).
- **Scenario** is the business process the whole transaction is part of. One per transaction. Drives per-scenario retention and reporting.
- **Tags** are freeform labels on individual entries. Many per entry. Drives taxonomy filtering.

Don't overload one axis to do another's job. If you find yourself using tags to indicate severity, use logging level instead. If you find yourself using scenarios to label individual entries, use tags instead.

## Where next

- [Scenarios](/NebulaLogger/logging-guide/scenarios/) - the transaction-level counterpart.
- [Console & Operations](/NebulaLogger/console/logger-console-app/) - filtering by tag in the console.
