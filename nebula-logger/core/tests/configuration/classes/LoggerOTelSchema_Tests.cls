//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerOTelSchema_Tests {
  @IsTest
  static void otel_severity_level_instance_correctly_maps_to_logging_level_when_severity_number_is_set() {
    Map<String, System.LoggingLevel> otelSeverityLevelToExpectedLoggingLevel = new Map<String, System.LoggingLevel>{
      'Error' => System.LoggingLevel.ERROR,
      'Warn' => System.LoggingLevel.WARN,
      'Info' => System.LoggingLevel.INFO,
      'Debug' => System.LoggingLevel.DEBUG,
      'Trace3' => System.LoggingLevel.FINE,
      'Trace2' => System.LoggingLevel.FINER,
      'Trace' => System.LoggingLevel.FINEST,
      'Anything else' => System.LoggingLevel.DEBUG
    };
  }

  @IsTest
  static void otel_severity_text_correctly_maps_to_logging_level() {
    Map<String, System.LoggingLevel> otelSeverityTextToExpectedLoggingLevel = new Map<String, System.LoggingLevel>{
      // TODO decide for sure if null severity text should be supported,
      // or if the mapping to logging level NONE should be handled differently (via LoggerRestResource?)
      // null => null,
      null => System.LoggingLevel.NONE,
      'FATAL4' => System.LoggingLevel.ERROR,
      'FATAL3' => System.LoggingLevel.ERROR,
      'FATAL2' => System.LoggingLevel.ERROR,
      'FATAL' => System.LoggingLevel.ERROR,
      'ERROR4' => System.LoggingLevel.ERROR,
      'ERROR3' => System.LoggingLevel.ERROR,
      'ERROR2' => System.LoggingLevel.ERROR,
      'ERROR' => System.LoggingLevel.ERROR,
      'WARN4' => System.LoggingLevel.WARN,
      'WARN3' => System.LoggingLevel.WARN,
      'WARN2' => System.LoggingLevel.WARN,
      'WARN' => System.LoggingLevel.WARN,
      'INFO4' => System.LoggingLevel.INFO,
      'INFO3' => System.LoggingLevel.INFO,
      'INFO2' => System.LoggingLevel.INFO,
      'INFO' => System.LoggingLevel.INFO,
      'DEBUG4' => System.LoggingLevel.DEBUG,
      'DEBUG3' => System.LoggingLevel.DEBUG,
      'DEBUG2' => System.LoggingLevel.DEBUG,
      'DEBUG' => System.LoggingLevel.DEBUG,
      'TRACE4' => System.LoggingLevel.FINE,
      'TRACE3' => System.LoggingLevel.FINER,
      'TRACE2' => System.LoggingLevel.FINEST,
      'TRACE' => System.LoggingLevel.INTERNAL
    };
    for (String otelSeverityText : otelSeverityTextToExpectedLoggingLevel.keySet()) {
      LoggerOTelSchema.SeverityLevel returnedSeverityLevel = new LoggerOTelSchema.SeverityLevel(otelSeverityText);

      System.LoggingLevel mappedLoggingLevel = returnedSeverityLevel.toLoggingLevel();

      System.LoggingLevel expectedLoggingLevel = otelSeverityTextToExpectedLoggingLevel.get(otelSeverityText);
      System.Assert.areEqual(expectedLoggingLevel.name(), mappedLoggingLevel?.name(), 'Wrong name for otelSeverityText ' + otelSeverityText);
      System.Assert.areEqual(expectedLoggingLevel.ordinal(), mappedLoggingLevel?.ordinal(), 'Wrong ordinal for otelSeverityText ' + otelSeverityText);
    }
  }

  @IsTest
  static void otel_severity_level_returns_is_valid_false_when_constructed_with_invalid_severity_number() {
    // OTel only has values 1-24, so any other integer should return isValid() == false
    Integer invalidSeverityNumber = 987654321;

    LoggerOTelSchema.SeverityLevel severityLevel = new LoggerOTelSchema.SeverityLevel(invalidSeverityNumber);

    System.Assert.isFalse(severityLevel.isValid());
    System.Assert.areEqual(invalidSeverityNumber, severityLevel.SeverityNumber);
    System.Assert.isNull(severityLevel.SeverityText);
    System.Assert.isNull(severityLevel.toLoggingLevel());
  }

  @IsTest
  static void otel_severity_level_returns_is_valid_false_when_constructed_with_invalid_severity_text() {
    String invalidSeverityText = 'Some value that is definitely not valid for SeverityText';

    LoggerOTelSchema.SeverityLevel severityLevel = new LoggerOTelSchema.SeverityLevel(invalidSeverityText);

    System.Assert.isFalse(severityLevel.isValid());
    System.Assert.isNull(severityLevel.SeverityNumber);
    System.Assert.areEqual(invalidSeverityText, severityLevel.SeverityText);
    System.Assert.isNull(severityLevel.toLoggingLevel());
  }

  @IsTest
  static void bool_otel_attribute_value_correctly_serializes_when_constructed_from_apex_data_type() {
    Object inputValue = false;

    LoggerOTelSchema.AttributeValue otelAttributeValue = new LoggerOTelSchema.AttributeValue(false);

    System.Assert.areEqual('{"boolValue":false}', System.JSON.serialize(otelAttributeValue, LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.areEqual(LoggerOTelSchema.AnyValueType.boolValue, otelAttributeValue.getDataValueType());
    System.Assert.areEqual(inputValue, otelAttributeValue.getDataValue());
    System.Assert.areEqual(inputValue, otelAttributeValue.boolValue);
    System.Assert.isNull(otelAttributeValue.arrayValue, 'Expected null for arrayValue, received: ' + otelAttributeValue.arrayValue);
    System.Assert.isNull(otelAttributeValue.doubleValue, 'Expected null for doubleValue, received: ' + otelAttributeValue.doubleValue);
    System.Assert.isNull(otelAttributeValue.intValue, 'Expected null for intValue, received: ' + otelAttributeValue.intValue);
    System.Assert.isNull(otelAttributeValue.kvlistValue, 'Expected null for kvlistValue, received: ' + otelAttributeValue.kvlistValue);
    System.Assert.isNull(otelAttributeValue.stringValue, 'Expected null for stringValue, received: ' + otelAttributeValue.stringValue);
  }

  @IsTest
  static void double_otel_attribute_value_correctly_serializes_when_constructed_from_apex_data_type() {
    Double inputValue = 123.45;

    LoggerOTelSchema.AttributeValue otelAttributeValue = new LoggerOTelSchema.AttributeValue(inputValue);

    System.Assert.areEqual('{"doubleValue":123.45}', System.JSON.serialize(otelAttributeValue, LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.areEqual(LoggerOTelSchema.AnyValueType.doubleValue, otelAttributeValue.getDataValueType());
    System.Assert.areEqual(inputValue, otelAttributeValue.getDataValue());
    System.Assert.areEqual(inputValue, otelAttributeValue.doubleValue);
    System.Assert.isNull(otelAttributeValue.arrayValue, 'Expected null for arrayValue, received: ' + otelAttributeValue.arrayValue);
    System.Assert.isNull(otelAttributeValue.boolValue, 'Expected null for boolValue, received: ' + otelAttributeValue.boolValue);
    System.Assert.isNull(otelAttributeValue.intValue, 'Expected null for intValue, received: ' + otelAttributeValue.intValue);
    System.Assert.isNull(otelAttributeValue.kvlistValue, 'Expected null for kvlistValue, received: ' + otelAttributeValue.kvlistValue);
    System.Assert.isNull(otelAttributeValue.stringValue, 'Expected null for stringValue, received: ' + otelAttributeValue.stringValue);
  }

  @IsTest
  static void int_otel_attribute_value_correctly_serializes_when_constructed_from_apex_data_type() {
    Integer inputValue = 456;

    LoggerOTelSchema.AttributeValue otelAttributeValue = new LoggerOTelSchema.AttributeValue(inputValue);

    System.Assert.areEqual('{"intValue":456}', System.JSON.serialize(otelAttributeValue, LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.areEqual(LoggerOTelSchema.AnyValueType.intValue, otelAttributeValue.getDataValueType());
    System.Assert.areEqual(inputValue, otelAttributeValue.getDataValue());
    System.Assert.areEqual(inputValue, otelAttributeValue.intValue);
    System.Assert.isNull(otelAttributeValue.arrayValue, 'Expected null for arrayValue, received: ' + otelAttributeValue.arrayValue);
    System.Assert.isNull(otelAttributeValue.boolValue, 'Expected null for boolValue, received: ' + otelAttributeValue.boolValue);
    System.Assert.isNull(otelAttributeValue.doubleValue, 'Expected null for doubleValue, received: ' + otelAttributeValue.doubleValue);
    System.Assert.isNull(otelAttributeValue.kvlistValue, 'Expected null for kvlistValue, received: ' + otelAttributeValue.kvlistValue);
    System.Assert.isNull(otelAttributeValue.stringValue, 'Expected null for stringValue, received: ' + otelAttributeValue.stringValue);
  }

  @IsTest
  static void string_otel_attribute_value_correctly_serializes_when_constructed_from_apex_data_type() {
    String inputValue = 'hello, world';

    LoggerOTelSchema.AttributeValue otelAttributeValue = new LoggerOTelSchema.AttributeValue(inputValue);

    System.Assert.areEqual('{"stringValue":"hello, world"}', System.JSON.serialize(otelAttributeValue, LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.areEqual(LoggerOTelSchema.AnyValueType.stringValue, otelAttributeValue.getDataValueType());
    System.Assert.areEqual(inputValue, otelAttributeValue.getDataValue());
    System.Assert.areEqual(inputValue, otelAttributeValue.stringValue);
    System.Assert.isNull(otelAttributeValue.arrayValue, 'Expected null for arrayValue, received: ' + otelAttributeValue.arrayValue);
    System.Assert.isNull(otelAttributeValue.boolValue, 'Expected null for boolValue, received: ' + otelAttributeValue.boolValue);
    System.Assert.isNull(otelAttributeValue.doubleValue, 'Expected null for doubleValue, received: ' + otelAttributeValue.doubleValue);
    System.Assert.isNull(otelAttributeValue.intValue, 'Expected null for intValue, received: ' + otelAttributeValue.intValue);
    System.Assert.isNull(otelAttributeValue.kvlistValue, 'Expected null for kvlistValue, received: ' + otelAttributeValue.kvlistValue);
  }

  // Below: tests for array & kvlist OTel attribute values. These are slightly more complex that other attribute value types,
  // as they both are collections of other OTel attribute values.
  @IsTest
  static void array_otel_attribute_value_correctly_serializes_when_constructed_from_apex_data_types() {
    // OTel arrays could contain a mix of different AnyTypes
    List<LoggerOTelSchema.AttributeValue> arrayValue = new List<LoggerOTelSchema.AttributeValue>{
      new LoggerOTelSchema.AttributeValue(false),
      new LoggerOTelSchema.AttributeValue('a text value')
    };
    Boolean boolValue = true;
    Double doubleValue = 123.45;
    Integer intValue = 987;
    Map<String, LoggerOTelSchema.AttributeValue> kvlistValue = new Map<String, LoggerOTelSchema.AttributeValue>{
      'hello' => new LoggerOTelSchema.AttributeValue('world')
    };
    String stringValue = 'Some string';

    List<LoggerOTelSchema.AttributeValue> inputValue = new List<LoggerOTelSchema.AttributeValue>{
      new LoggerOTelSchema.AttributeValue(arrayValue),
      new LoggerOTelSchema.AttributeValue(boolValue),
      new LoggerOTelSchema.AttributeValue(doubleValue),
      new LoggerOTelSchema.AttributeValue(intValue),
      new LoggerOTelSchema.AttributeValue(kvlistValue),
      new LoggerOTelSchema.AttributeValue(stringValue)
    };
    LoggerOTelSchema.AttributeValue otelAttributeValue = new LoggerOTelSchema.AttributeValue(inputValue);

    System.Assert.areEqual(LoggerOTelSchema.AnyValueType.arrayValue, otelAttributeValue.getDataValueType());
    Object expectedValue = '[{"arrayValue":[{"boolValue":false},{"stringValue":"a text value"}]},{"boolValue":true},{"doubleValue":123.45},{"intValue":987},{"kvlistValue":{"hello":{"stringValue":"world"}}},{"stringValue":"Some string"}]';
    System.Assert.areEqual(expectedValue, System.JSON.serialize(otelAttributeValue.getDataValue(), LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.areEqual(expectedValue, System.JSON.serialize(otelAttributeValue.arrayValue, LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.isNull(otelAttributeValue.boolValue, 'Expected null for boolValue, received: ' + otelAttributeValue.boolValue);
    System.Assert.isNull(otelAttributeValue.doubleValue, 'Expected null for doubleValue, received: ' + otelAttributeValue.doubleValue);
    System.Assert.isNull(otelAttributeValue.intValue, 'Expected null for intValue, received: ' + otelAttributeValue.intValue);
    System.Assert.isNull(otelAttributeValue.kvlistValue, 'Expected null for kvlistValue, received: ' + otelAttributeValue.kvlistValue);
    System.Assert.isNull(otelAttributeValue.stringValue, 'Expected null for stringValue, received: ' + otelAttributeValue.stringValue);
  }

  @IsTest
  static void kvlist_otel_attribute_value_correctly_serializes_when_constructed_from_apex_data_types() {
    // OTel kvlists could contain a mix of different AnyTypes
    List<LoggerOTelSchema.AttributeValue> arrayValue = new List<LoggerOTelSchema.AttributeValue>{
      new LoggerOTelSchema.AttributeValue(false),
      new LoggerOTelSchema.AttributeValue('a text value')
    };
    Boolean boolValue = true;
    Double doubleValue = 123.45;
    Integer intValue = 987;
    Map<String, LoggerOTelSchema.AttributeValue> kvlistValue = new Map<String, LoggerOTelSchema.AttributeValue>{
      'hello' => new LoggerOTelSchema.AttributeValue('world')
    };
    String stringValue = 'Some string';

    Map<String, LoggerOTelSchema.AttributeValue> inputValue = new Map<String, LoggerOTelSchema.AttributeValue>{
      'exampleArrayValue' => new LoggerOTelSchema.AttributeValue(arrayValue),
      'exampleBoolValue' => new LoggerOTelSchema.AttributeValue(true),
      'exampleDoubleValue' => new LoggerOTelSchema.AttributeValue(doubleValue),
      'exampleIntValue' => new LoggerOTelSchema.AttributeValue(intValue),
      'exampleKvlistValue' => new LoggerOTelSchema.AttributeValue(kvlistValue),
      'exampleStringValue' => new LoggerOTelSchema.AttributeValue(stringValue)
    };
    LoggerOTelSchema.AttributeValue otelAttributeValue = new LoggerOTelSchema.AttributeValue(inputValue);

    System.Assert.areEqual(LoggerOTelSchema.AnyValueType.kvlistValue, otelAttributeValue.getDataValueType());
    Object expectedValue = '{"exampleStringValue":{"stringValue":"Some string"},"exampleKvlistValue":{"kvlistValue":{"hello":{"stringValue":"world"}}},"exampleIntValue":{"intValue":987},"exampleDoubleValue":{"doubleValue":123.45},"exampleBoolValue":{"boolValue":true},"exampleArrayValue":{"arrayValue":[{"boolValue":false},{"stringValue":"a text value"}]}}';
    System.Assert.areEqual(expectedValue, System.JSON.serialize(otelAttributeValue.getDataValue(), LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.areEqual(expectedValue, System.JSON.serialize(otelAttributeValue.kvlistValue, LoggerOTelSchema.SUPPRESS_JSON_NULL_VALUES));
    System.Assert.isNull(otelAttributeValue.arrayValue, 'Expected null for arrayValue, received: ' + otelAttributeValue.arrayValue);
    System.Assert.isNull(otelAttributeValue.boolValue, 'Expected null for boolValue, received: ' + otelAttributeValue.boolValue);
    System.Assert.isNull(otelAttributeValue.doubleValue, 'Expected null for doubleValue, received: ' + otelAttributeValue.doubleValue);
    System.Assert.isNull(otelAttributeValue.intValue, 'Expected null for intValue, received: ' + otelAttributeValue.intValue);
    System.Assert.isNull(otelAttributeValue.stringValue, 'Expected null for stringValue, received: ' + otelAttributeValue.stringValue);
  }
}
