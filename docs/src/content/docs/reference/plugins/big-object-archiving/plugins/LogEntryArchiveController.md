---
title: LogEntryArchiveController
description: >-
  Nebula Logger big-object-archiving plugin class (public API):
  LogEntryArchiveController.
---

# LogEntryArchiveController Class

`SUPPRESSWARNINGS`

Controller class used by the LWC `logEntryArchives` to display `LogEntryArchive__b` data

**Group** Plugins

**See** [LogEntryArchivePlugin](LogEntryArchivePlugin.md)

**See** [LogEntryArchiveBuilder](LogEntryArchiveBuilder.md)

## Methods

### `getLogEntryArchives(startDate, endDate, rowLimit, minimumLoggingLevelOrdinal, messageSearchTerm)`

`SUPPRESSWARNINGS`
`AURAENABLED`

Returns a list of `LogEntryArchive__b` records, based on the current user&#x27;s record access + an optional search term for `Message__c`

#### Signature

```apex
public static List<LogEntryArchive__b> getLogEntryArchives(Date startDate, Date endDate, Integer rowLimit, Integer minimumLoggingLevelOrdinal, String messageSearchTerm)
```

#### Parameters

| Name                       | Type    | Description                                                                                                              |
| -------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| startDate                  | Date    | The initial date to check for matching `LogEntryArchive__b` records, used to filter on `LogEntryArchive__b.Timestamp__c` |
| endDate                    | Date    | The last date to check for matching `LogEntryArchive__b` records, used to filter on `LogEntryArchive__b.Timestamp__c`    |
| rowLimit                   | Integer | The max number of rows to return                                                                                         |
| minimumLoggingLevelOrdinal | Integer | Optional filter for a minimal logging level ordinal, applied to the field `LoggingLevelOrdinal__c`                       |
| messageSearchTerm          | String  | Optional filter for text contained within the field `Message__c`                                                         |

#### Return Type

**List<LogEntryArchive\_\_b>**

The list of matching `LogEntryArchive__b` records
