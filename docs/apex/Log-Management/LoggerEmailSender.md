---
layout: default
---

## LoggerEmailSender class

Builds and sends email notifications when internal exceptions occur within the logging system

---

### Methods

#### `sendErrorEmail(Schema.SObjectType sobjectType, List<Database.SaveResult> saveResults)` → `void`

Sends an error email notification to the org&apos;s list of Apex Exception Email recipients, configured under Setup --&gt; Email --&gt; Apex Exception Email

##### Parameters

| Param         | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| `sobjectType` | The SObjectType of records being saved.                        |
| `saveResults` | The list of Database.SaveResult instances to use in the email. |

#### `sendErrorEmail(Schema.SObjectType sobjectType, List<Database.UpsertResult> upsertResults)` → `void`

Sends an error email notification to the org&apos;s list of Apex Exception Email recipients, configured under Setup --&gt; Email --&gt; Apex Exception Email

##### Parameters

| Param           | Description                                                      |
| --------------- | ---------------------------------------------------------------- |
| `sobjectType`   | The SObjectType of records being saved.                          |
| `upsertResults` | The list of Database.UpsertResult instances to use in the email. |

---
