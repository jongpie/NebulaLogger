---
title: LogEntryDataMaskRule__mdt
description: 'Nebula Logger customobject reference: LogEntryDataMaskRule__mdt.'
---

# Log Entry Data Mask Rule

Used to configure regex-based rules in Nebula Logger to mask sensitive data in log entry fields, such as LogEntryEvent**e.Message**c and LogEntry**c.Message**c

## API Name

`LogEntryDataMaskRule__mdt`

## Fields

### DEPRECATED: Apply to Message

**API Name**

`ApplyToMessage__c`

**Type**

_Checkbox_

---

### Apply to Record JSON

**API Name**

`ApplyToRecordJson__c`

**Type**

_Checkbox_

---

### Is Enabled

**API Name**

`IsEnabled__c`

**Type**

_Checkbox_

---

### Replacement RegEx

**Required**

**API Name**

`ReplacementRegEx__c`

**Type**

_Text_

---

### Sensitive Data RegEx

**Required**

**API Name**

`SensitiveDataRegEx__c`

**Type**

_Text_

## Records

### American Express Credit Card Number

**API Name**

`LogEntryDataMaskRule.AmericanExpressCreditCardNumber`

---

### Mastercard Credit Card Number

**API Name**

`LogEntryDataMaskRule.MastercardCreditCardNumber`

---

### Social Security Number

**API Name**

`LogEntryDataMaskRule.SocialSecurityNumber`

---

### Visa Credit Card Number

**API Name**

`LogEntryDataMaskRule.VisaCreditCardNumber`
