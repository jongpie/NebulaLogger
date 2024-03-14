Nebula Logger provides the ability to automatically mask sensitive data (such as credit card numbers, social security numbers, etc.) within the "Message" and "Record JSON" fields. Specifically, it covers masking data in:

-   `LogEntryEvent__e.Message__c` (platform event)
-   `LogEntryEvent__e.RecordJson__c` (platform event)
-   `LogEntry__c.Message__c` (custom object)
-   `LogEntry__c.RecordJson__c` (custom object)

## `LogEntryDataMaskRule__mdt` Custom Metadata Type (CMDT)

Pre-built rules are included for Visa credit card numbers, Mastercard credit card numbers, and social security numbers - additional rules can be configured by creating additional `LogEntryDataMaskRule__mdt` records.

![image](https://user-images.githubusercontent.com/1267157/132450774-e9dcf673-3c83-4d41-a47a-b002d8c3f0ce.png)

## Data Masking Example

Any time log entries are created, any enabled data mask rules are automatically applied. For example, this Apex script creates 1 `Log__c` record with 3 `LogEntry__c` records, which include (fake) credit card & social security number data.

```java
Logger.error('Here is my fake Visa credit card 4000-1111-2222-0004, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.warn('Here is my fake Mastercard credit card 5000-1111-2222-0005, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.info('In case you want to steal my identity, my fake social is 400-11-9999, thanks', currentUser).addTag('data masking rule').addTag('an informational tag');
Logger.saveLog();
```

With data mask rules enabled, the sensitive data is automatically masked. The screenshot below shows the first two entries have masked credit card numbers, and the third entry has a masked social security number.

![image](https://user-images.githubusercontent.com/1267157/132449528-4ea453ba-3d60-48ea-85ee-31e73b7befaa.png)

## Disabling Data Mask Rules for Certain Users

Using the hiearchy custom setting `LoggerSettings__c`, you can choose to enable/data mask rules at the org, profile or user-level.

![image](https://user-images.githubusercontent.com/1267157/130894194-d4cc14f2-265d-4ef9-bb48-ae1e53154a2d.png)
