// This script runs in the pipeline to validate different custom metadata records to ensure that they're configured correctly
// before being added to the unlocked & managed packages.

// LogEntryDataMaskRule__mdt checks
// The field LogEntryDataMaskRule__mdt.IsEnabled__c should be set to true for any records included in the packages.
for (LogEntryDataMaskRule__mdt record : [SELECT DeveloperName, IsEnabled__c FROM LogEntryDataMaskRule__mdt ORDER BY DeveloperName]) {
  if (record.IsEnabled__c == false) {
    throw new System.IllegalArgumentException('😡 IsEnabled__c field should be set to true for LogEntryDataMaskRule.' + record.DeveloperName);
  }
}
System.debug('🥳 LogEntryDataMaskRule__mdt records have been correctly enabled!');

// LogEntryDataMaskRule__mdt checks
// The fields SensitiveDataRegEx__c and ReplacementRegEx__c should contain valid regex patterns that mask the appropriate data.
// US social security number rule
LogEntryDataMaskRule__mdt socialSecurityNumberRule = LogEntryDataMaskRule__mdt.getInstance('SocialSecurityNumber');
System.Assert.areEqual(
  '>>> Here is a number XXX-XX-6789 which is the correct length for US SSN',
  '>>> Here is a number 123-45-6789 which is the correct length for US SSN'
    .replaceAll(socialSecurityNumberRule.SensitiveDataRegEx__c, socialSecurityNumberRule.ReplacementRegEx__c)
);
System.Assert.areEqual(
  '>>> Here is a number XXX-XX-6789 which is the correct length for US SSN',
  '>>> Here is a number 123 45 6789 which is the correct length for US SSN'
    .replaceAll(socialSecurityNumberRule.SensitiveDataRegEx__c, socialSecurityNumberRule.ReplacementRegEx__c)
);
List<String> invalidSSNLookalikes = new List<String>{
  '0123-45-6789',
  '0123-45-67890',
  '23-45-678',
  '23-45-6789',
  '123-45-678',
  // US phone number formats
  '111-555-1234',
  '111 555 1234',
  '(111) 555-1234'
};
for (String lookalike : invalidSSNLookalikes) {
  String originalInput = '>>> Here is a value ' + lookalike + ' and it is not a valid form for US SSN, so masking should not occur';
  System.Assert.areEqual(
    originalInput,
    originalInput.replaceAll(socialSecurityNumberRule.SensitiveDataRegEx__c, socialSecurityNumberRule.ReplacementRegEx__c)
  );
}
System.debug(
  '🥳 LogEntryDataMaskRule__mdt record \'SocialSecurityNumber\' has been correctly configured with functioning regexes for sensitive data & replacement!'
);

// Mastercard credit card rule
LogEntryDataMaskRule__mdt mastercardCreditCardNumberRule = LogEntryDataMaskRule__mdt.getInstance('MastercardCreditCardNumber');
System.Assert.areEqual(
  '>>> Here is a credit card number ****-****-****-0005 which is the correct length for Mastercard',
  '>>> Here is a credit card number 5000-1111-2222-0005 which is the correct length for Mastercard'
    .replaceAll(mastercardCreditCardNumberRule.SensitiveDataRegEx__c, mastercardCreditCardNumberRule.ReplacementRegEx__c)
);
List<String> invalidMastercardLookalikes = new List<String>{
  '05000-1111-2222-0005',
  '05000-1111-2222-00050',
  '000-1111-2222-000',
  '000-1111-2222-0005',
  '5000-1111-2222-000'
};
for (String lookalike : invalidMastercardLookalikes) {
  String originalInput = '>>> Here is a value ' + lookalike + ' and it is not a valid form for Mastercard, so masking should not occur';
  System.Assert.areEqual(
    originalInput,
    originalInput.replaceAll(socialSecurityNumberRule.SensitiveDataRegEx__c, socialSecurityNumberRule.ReplacementRegEx__c)
  );
}
System.debug(
  '🥳 LogEntryDataMaskRule__mdt record \'MastercardCreditCardNumber\' has been correctly configured with functioning regexes for sensitive data & replacement!'
);

// Visa credit card rule
LogEntryDataMaskRule__mdt visaCreditCardNumberRule = LogEntryDataMaskRule__mdt.getInstance('VisaCreditCardNumber');
System.Assert.areEqual(
  '>>> Here is a credit card number ****-****-****-0004 which is the correct length for Visa',
  '>>> Here is a credit card number 4000-1111-2222-0004 which is the correct length for Visa'
    .replaceAll(visaCreditCardNumberRule.SensitiveDataRegEx__c, visaCreditCardNumberRule.ReplacementRegEx__c)
);
List<String> invalidVisaLookalikes = new List<String>{
  '04000-1111-2222-0004',
  '04000-1111-2222-00040',
  '000-1111-2222-000',
  '000-1111-2222-0004',
  '4000-1111-2222-000'
};
for (String lookalike : invalidVisaLookalikes) {
  String originalInput = '>>> Here is a value ' + lookalike + ' and it is not a valid form for Visa, so masking should not occur';
  System.Assert.areEqual(
    originalInput,
    originalInput.replaceAll(socialSecurityNumberRule.SensitiveDataRegEx__c, socialSecurityNumberRule.ReplacementRegEx__c)
  );
}
System.debug(
  '🥳 LogEntryDataMaskRule__mdt record \'VisaCreditCardNumber\' has been correctly configured with functioning regexes for sensitive data & replacement!'
);

// LoggerParameter__mdt checks
// The field LoggerParameter__mdt.Description__c is a long textarea field, so it can't be marked as required - but every record
// should have the field populated before being added to the unlocked & managed packages.
for (LoggerParameter__mdt record : [SELECT DeveloperName, Description__c FROM LoggerParameter__mdt ORDER BY DeveloperName]) {
  if (record.Description__c == null) {
    throw new System.IllegalArgumentException('😡 Description__c field should be populated for LoggerParameter.' + record.DeveloperName);
  }
}
System.debug('🥳 LoggerParameter__mdt records have been correctly populated with a description!');

// LoggerSObjectHandler__mdt checks
// The field LoggerSObjectHandler__mdt.IsEnabled__c should be set to true for any records included in the packages.
for (LoggerSObjectHandler__mdt record : [SELECT DeveloperName, IsEnabled__c FROM LoggerSObjectHandler__mdt ORDER BY DeveloperName]) {
  if (record.IsEnabled__c == false) {
    throw new System.IllegalArgumentException('😡 IsEnabled__c field should be set to true for LoggerSObjectHandler.' + record.DeveloperName);
  }
}
System.debug('🥳 LoggerSObjectHandler__mdt records have been correctly enabled!');

// LogStatus__mdt checks
// The field LogStatus__mdt.IsActive__c should be set to true for any records included in the packages.
for (LogStatus__mdt record : [SELECT DeveloperName, IsActive__c FROM LogStatus__mdt ORDER BY DeveloperName]) {
  // TODO rename LogStatus__mdt.IsActive__c to IsEnabled__c for consistency with other objects
  if (record.IsActive__c == false) {
    throw new System.IllegalArgumentException('😡 IsActive__c field should be set to true for LogStatus.' + record.DeveloperName);
  }
}
System.debug('🥳 LogStatus__mdt records records have been correctly enabled!');
