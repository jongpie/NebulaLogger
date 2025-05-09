//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
private class CMDT_DataMaskingRules_Tests {
  @IsTest
  static void it_includes_a_valid_data_mask_rule_for_mastercard_credit_card_number() {
    // This is an integration test that intentionally relies on the org's LogEntryDataMaskRule__mdt record,
    // since this is a rule that's included as part of Nebula Logger.
    LogEntryDataMaskRule__mdt dataMaskRule = LogEntryDataMaskRule__mdt.getInstance('MastercardCreditCardNumber');
    System.Assert.isNotNull(dataMaskRule);
    Map<String, String> inputToExpectedOutput = new Map<String, String>{
      // ✅ Valid matches that should be masked.
      // Set 1
      '5555 4444 3333 1111' => '****-****-****-1111',
      'some text before 5555 4444 3333 1111' => 'some text before ****-****-****-1111',
      '5555 4444 3333 1111 some text after' => '****-****-****-1111 some text after',
      'some text before 5555 4444 3333 1111 some text after' => 'some text before ****-****-****-1111 some text after',
      // Set 2
      '2221-1234-5678-9012' => '****-****-****-9012',
      'some text before 2221-1234-5678-9012' => 'some text before ****-****-****-9012',
      '2221-1234-5678-9012 some text after' => '****-****-****-9012 some text after',
      'some text before 2221-1234-5678-9012 some text after' => 'some text before ****-****-****-9012 some text after',
      // Set 3
      '5300000000000001' => '****-****-****-0001',
      'some text before 5300000000000001' => 'some text before ****-****-****-0001',
      '5300000000000001 some text after' => '****-****-****-0001 some text after',
      'some text before 5300000000000001 some text after' => 'some text before ****-****-****-0001 some text after',
      // Set 4
      '2720 9999 8888 7777' => '****-****-****-7777',
      'some text before 2720 9999 8888 7777' => 'some text before ****-****-****-7777',
      '2720 9999 8888 7777 some text after' => '****-****-****-7777 some text after',
      'some text before 2720 9999 8888 7777 some text after' => 'some text before ****-****-****-7777 some text after',
      // Set 5
      '5234-5678-9012-3456' => '****-****-****-3456',
      'some text before 5234-5678-9012-3456' => 'some text before ****-****-****-3456',
      '5234-5678-9012-3456 some text after' => '****-****-****-3456 some text after',
      'some text before 5234-5678-9012-3456 some text after' => 'some text before ****-****-****-3456 some text after',
      // Set 6
      '2221000011112222' => '****-****-****-2222',
      'some text before 2221000011112222' => 'some text before ****-****-****-2222',
      '2221000011112222 some text after' => '****-****-****-2222 some text after',
      'some text before 2221000011112222 some text after' => 'some text before ****-****-****-2222 some text after',
      // ❌ Invalid matches - null is used as a placeholder here to indicate no masking should occur.
      // Discover, not Mastercard
      '6011 1234 5678 9012' => null,
      // Visa, wrong prefix
      '4111 1111 1111 1111' => null,
      // Mixed separators
      '5525-3344 1122-0000' => null,
      // BIN too low
      '2220 1234 5678 9012' => null,
      // BIN too high
      '2721 1111 2222 3333' => null,
      // Too many digits (19)
      '5500000000000000000' => null,
      // Too short (15 digits)
      '5300-0000-0000-000' => null
    };
    for (String input : inputToExpectedOutput.keySet()) {
      String expectedOutput = inputToExpectedOutput.get(input) ?? input;

      String maskedOutput = input.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);

      System.Assert.areEqual(expectedOutput, maskedOutput);
    }
  }

  @IsTest
  static void it_includes_a_valid_data_mask_rule_for_visa_credit_card_number() {
    // This is an integration test that intentionally relies on the org's LogEntryDataMaskRule__mdt record,
    // since this is a rule that's included as part of Nebula Logger.
    LogEntryDataMaskRule__mdt dataMaskRule = LogEntryDataMaskRule__mdt.getInstance('VisaCreditCardNumber');
    System.Assert.isNotNull(dataMaskRule);
    Map<String, String> inputToExpectedOutput = new Map<String, String>{
      // ✅ Valid matches that should be masked.
      // Set 1
      '4111 1111 1111 1111' => '****-****-****-1111',
      'some text before 4111 1111 1111 1111' => 'some text before ****-****-****-1111',
      '4111 1111 1111 1111 some text after' => '****-****-****-1111 some text after',
      'some text before 4111 1111 1111 1111 some text after' => 'some text before ****-****-****-1111 some text after',
      // Set 2
      '4000-1234-5678-9876' => '****-****-****-9876',
      'some text before 4000-1234-5678-9876' => 'some text before ****-****-****-9876',
      '4000-1234-5678-9876 some text after' => '****-****-****-9876 some text after',
      'some text before 4000-1234-5678-9876 some text after' => 'some text before ****-****-****-9876 some text after',
      // Set 3
      '4444111122223333' => '****-****-****-3333',
      'some text before 4444111122223333' => 'some text before ****-****-****-3333',
      '4444111122223333 some text after' => '****-****-****-3333 some text after',
      'some text before 4444111122223333 some text after' => 'some text before ****-****-****-3333 some text after',
      // ❌ Invalid matches - null is used as a placeholder here to indicate no masking should occur.
      // Mixed separators
      '4111-1111 1111-1111' => null,
      // Too long
      '4111 1111 1111 11112222' => null,
      // Wrong prefix
      '1234411111111111' => null,
      // Too short
      '4444 1111 2222' => null
    };
    for (String input : inputToExpectedOutput.keySet()) {
      String expectedOutput = inputToExpectedOutput.get(input) ?? input;

      String maskedOutput = input.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);

      System.Assert.areEqual(expectedOutput, maskedOutput);
    }
  }

  @IsTest
  static void it_includes_a_valid_data_mask_rule_for_social_security_number() {
    // This is an integration test that intentionally relies on the org's LogEntryDataMaskRule__mdt record,
    // since this is a rule that's included as part of Nebula Logger.
    LogEntryDataMaskRule__mdt dataMaskRule = LogEntryDataMaskRule__mdt.getInstance('SocialSecurityNumber');
    System.Assert.isNotNull(dataMaskRule);
    Map<String, String> inputToExpectedOutput = new Map<String, String>{
      // ✅ Valid matches that should be masked.
      '123-45-6789' => '***-**-6789',
      '123456789' => '***-**-6789',
      '123 45 6789' => '***-**-6789',
      'xyz 123-45-6789.' => 'xyz ***-**-6789.',
      // ❌ Invalid matches - null is used as a placeholder here to indicate no masking should occur.
      // v1 SSN-looking value is part of a bigger string, so could be a false positive
      '123-45-6789abc' => null,
      // v2 SSN-looking value is part of a bigger string, so could be a false positive
      'abc123456789' => null,
      // v3 SSN-looking value is part of a bigger string, so could be a false positive
      'a123 45 6789' => null,
      // Fake Account ID - in previous versions of Nebula Logger, some of the numbers were incorrectly interpretted as SSNs
      '001000000000000001' => null,
      // Too long
      '123456789000' => null,
      // Too long
      '112233445566' => null,
      // Invalid SSN structure
      '12-34-5678' => null
    };
    for (String input : inputToExpectedOutput.keySet()) {
      String expectedOutput = inputToExpectedOutput.get(input) ?? input;

      String maskedOutput = input.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);

      System.Assert.areEqual(expectedOutput, maskedOutput);
    }
  }
}
