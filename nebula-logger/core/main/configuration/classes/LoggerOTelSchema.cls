/**
 * @group Configuration
 * @description Class used to handle the translation between some Salesforce concepts
 *              and OpenTelemetry's (OTel) schema. None of this is specific to Nebula Logger,
 *              this only handles the translation between OTel & what Salesforce provides out-of-the-box.
 * @see LoggerOTelAdapter
 * @see LoggerRestResource
 * @see LogEntryEventBuilder
 * @see LogViewerController
 */
public without sharing class LoggerOTelSchema {
  public static final Boolean SUPPRESS_JSON_NULL_VALUES = true;
  // Docs: https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-severitytext
  // In general, OTel best practice is to rely on severity number over severity text.
  // But for this particular mapping between OTel & Nebula Logger, it's fairly safe to use severity text,
  // with the benefit being that it's human readable, making maintenance muuuuch easier compared to using severity number.

  // Apex has 2 secret-ish/seldomly used enum value System.LoggingLevel: INTERNAL and NONE.
  // Neither are currently used in Nebula Logger, but just in case that ever changes,
  // and for the sake of completeness, both are mapped here.
  private static final Map<String, System.LoggingLevel> SEVERITY_TEXT_TO_LOGGING_LEVEL = LoggerOTelSchema.getSeverityTextToLoggingLevelMappings();
  private static final Map<System.LoggingLevel, String> LOGGING_LEVEL_TO_SEVERITY_TEXT = getLoggingLevelToSeverityText();
  private static final Map<Integer, String> SEVERITY_NUMBER_TO_TEXT = LoggerOTelSchema.getSeverityNumberToText();
  private static final Map<String, Integer> SEVERITY_TEXT_TO_NUMBER = LoggerOTelSchema.reverseMap(SEVERITY_NUMBER_TO_TEXT);

  public static Map<String, SeverityLevel> getSeverityLevels() {
    Map<String, SeverityLevel> severityTextToSeverityLevel = new Map<String, SeverityLevel>();
    for (String severityText : SEVERITY_TEXT_TO_NUMBER.keySet()) {
      severityTextToSeverityLevel.put(severityText, new SeverityLevel(SEVERITY_TEXT_TO_NUMBER.get(severityText)));
    }

    return severityTextToSeverityLevel;
  }

  public static Datetime fromEpochNanos(Long nanos) {
    return nanos == null ? null : Datetime.newInstance(nanos / 1000000);
  }

  public static Long toEpochNanos(Datetime dt) {
    return dt == null ? null : dt.getTime() * 1000000L;
  }

  private static Map<System.LoggingLevel, String> getLoggingLevelToSeverityText() {
    return new Map<System.LoggingLevel, String>{
      System.LoggingLevel.NONE => null,
      System.LoggingLevel.ERROR => 'ERROR4',
      System.LoggingLevel.WARN => 'WARN4',
      System.LoggingLevel.INFO => 'INFO4',
      System.LoggingLevel.DEBUG => 'DEBUG4',
      System.LoggingLevel.FINE => 'TRACE4',
      System.LoggingLevel.FINER => 'TRACE3',
      System.LoggingLevel.FINEST => 'TRACE2',
      System.LoggingLevel.INTERNAL => 'TRACE'
    };
  }

  private static Map<Integer, String> getSeverityNumberToText() {
    // This mapping could be represented using an enum --> use enum.name() & enum.ordinal().
    // But the OTel severity number is not equal to enum.ordinal(), it would be ordinal().
    // To avoid confusion & possible bugs with that approach, this map is instead used.
    return new Map<Integer, String>{
      24 => 'FATAL4',
      23 => 'FATAL3',
      22 => 'FATAL2',
      21 => 'FATAL',
      20 => 'ERROR4',
      19 => 'ERROR3',
      18 => 'ERROR2',
      17 => 'ERROR',
      16 => 'WARN4',
      15 => 'WARN3',
      14 => 'WARN2',
      13 => 'WARN',
      12 => 'INFO4',
      11 => 'INFO3',
      10 => 'INFO2',
      9 => 'INFO',
      8 => 'DEBUG4',
      7 => 'DEBUG3',
      6 => 'DEBUG2',
      5 => 'DEBUG',
      4 => 'TRACE4',
      3 => 'TRACE3',
      2 => 'TRACE2',
      1 => 'TRACE'
    };
  }

  private static Map<String, System.LoggingLevel> getSeverityTextToLoggingLevelMappings() {
    // OTel has signifcantly more severity levels (text & numbers) compared to Apex's System.LoggingLevel enum.
    // As a result, multiple OTel severity levels (intentionally) map to the same values in System.LoggingLevel.
    return new Map<String, System.LoggingLevel>{
      // The rarely-used NONE logging level
      null => System.LoggingLevel.NONE,
      // ERROR logging level
      'FATAL4' => System.LoggingLevel.ERROR,
      'FATAL3' => System.LoggingLevel.ERROR,
      'FATAL2' => System.LoggingLevel.ERROR,
      'FATAL' => System.LoggingLevel.ERROR,
      'ERROR4' => System.LoggingLevel.ERROR,
      'ERROR3' => System.LoggingLevel.ERROR,
      'ERROR2' => System.LoggingLevel.ERROR,
      'ERROR' => System.LoggingLevel.ERROR,
      // WARN logging level
      'WARN4' => System.LoggingLevel.WARN,
      'WARN3' => System.LoggingLevel.WARN,
      'WARN2' => System.LoggingLevel.WARN,
      'WARN' => System.LoggingLevel.WARN,
      // INFO logging level
      'INFO4' => System.LoggingLevel.INFO,
      'INFO3' => System.LoggingLevel.INFO,
      'INFO2' => System.LoggingLevel.INFO,
      'INFO' => System.LoggingLevel.INFO,
      // DEBUG logging level
      'DEBUG4' => System.LoggingLevel.DEBUG,
      'DEBUG3' => System.LoggingLevel.DEBUG,
      'DEBUG2' => System.LoggingLevel.DEBUG,
      'DEBUG' => System.LoggingLevel.DEBUG,
      // FINE, FINER, FINEST, and the rarely-used INTERNAL logging levels
      'TRACE4' => System.LoggingLevel.FINE,
      'TRACE3' => System.LoggingLevel.FINER,
      'TRACE2' => System.LoggingLevel.FINEST,
      'TRACE' => System.LoggingLevel.INTERNAL
    };
  }

  /*
      For reference/dev: this is an example of what Nebula Logger's data could/should look like when converted to OTel

      {
        "resource": {
          "attributes": [
            { "key": "service.name", "value": { "stringValue": "Salesforce" } },
            { "key": "salesforce.org_id", "value": { "stringValue": "00DXXXXXXXXXXXX" } },
            { "key": "salesforce.env_type", "value": { "stringValue": "sandbox" } },
            { "key": "salesforce.env_name", "value": { "stringValue": "Full Sandbox - UAT" } }
          ]
        },
        "scopeLogs": [
          {
            "scope": {
              "name": "NebulaLogger",
              "version": "6.1.0"
            },
            "logRecords": [
              {
                "timeUnixNano": 1713891845000000000,
                "severityNumber": 17,
                "severityText": "ERROR",
                "body": { "stringValue": "An unexpected error occurred during lead processing." },
                "attributes": [
                  { "key": "logger.category", "value": { "stringValue": "LeadProcessing" } },
                  { "key": "exception.type", "value": { "stringValue": "NullPointerException" } },
                  { "key": "exception.message", "value": { "stringValue": "Attempt to de-reference a null object" } },
                  { "key": "user.id", "value": { "stringValue": "005XXXXXXXXXXXX" } }
                ],
                "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
                "spanId": "00f067aa0ba902b7"
              }
            ]
          }
        ]
      }

  */

  // Arguably, this class could instead be an enum. But enums in Apex are limited, and there is some (small-ish)
  // complexity with the mapping to & from OTel & Nebula Logger/Apex/Salesforce:
  //    1. The OTel severity number is not equal to enum.ordinal() (it would be ordinal() + 1).
  //    2. Somewhere in Nebula Logger, there needs to be code to convert to & from System.LoggingLevel & OTel severity levels.
  //       Making `SeverityLevel` a class (instead of an enum) helps encapsulate the conversion responsbility.
  //    3. The alternative - using an enum - would require still either a class or set of methods to handle the conversion
  //       to & from System.LoggingLevel & OTel severity levels. Might as well make it a class instead of an enum + separate methods 🤷
  public class SeverityLevel {
    public final Integer SeverityNumber { get; private set; }
    public final String SeverityText { get; private set; }

    private transient System.LoggingLevel systemLoggingLevel;

    public SeverityLevel(System.LoggingLevel providedSystemLoggingLevel) {
      this(LOGGING_LEVEL_TO_SEVERITY_TEXT.get(providedSystemLoggingLevel));

      this.systemLoggingLevel = providedSystemLoggingLevel;
    }

    public SeverityLevel(String severityText) {
      this(null, severityText);
    }

    public SeverityLevel(Integer severityNumber) {
      this(severityNumber, null);
    }

    private SeverityLevel(Integer providedSeverityNumber, String providedSeverityText) {
      this.SeverityNumber = providedSeverityNumber ?? SEVERITY_TEXT_TO_NUMBER.get(providedSeverityText?.toUpperCase());
      this.SeverityText = providedSeverityText ?? SEVERITY_NUMBER_TO_TEXT.get(providedSeverityNumber);
    }

    public Boolean isValid() {
      return SEVERITY_NUMBER_TO_TEXT.containsKey(this.SeverityNumber) && SEVERITY_TEXT_TO_NUMBER.containsKey(this.SeverityText);
    }

    public System.LoggingLevel toLoggingLevel() {
      this.systemLoggingLevel = this.systemLoggingLevel ?? SEVERITY_TEXT_TO_LOGGING_LEVEL.get(this.SeverityText);
      return this.systemLoggingLevel;
    }
  }

  // OpenTelemetry classes - these correspond to OTel v1.36.0's HTTP JSON format for the logs data model
  // https://opentelemetry.io/docs/specs/otel/logs/data-model/
  // https://opentelemetry.io/docs/specs/otel/protocol/file-exporter/#examples
  // https://github.com/open-telemetry/opentelemetry-proto/blob/main/examples/logs.json
  public class LogsPayload {
    public final List<ResourceLog> resourceLogs {
      get {
        resourceLogs = resourceLogs ?? new List<ResourceLog>();
        return resourceLogs;
      }
      set;
    }
  }

  public class ResourceLog {
    public final Resource resource {
      get {
        resource = resource ?? new Resource();
        return resource;
      }
      set;
    }

    public final List<ScopeLog> scopeLogs {
      get {
        scopeLogs = scopeLogs ?? new List<ScopeLog>();
        return scopeLogs;
      }
      set;
    }
  }

  // OTel attributes supports a few additional types (like float64Value) that probably should be incoprorated
  // to try to fully align to the OTel logs data model standard.
  //
  // But, there's not currently a need for them in Nebula Logger's data model for the moment, so they're lower priority.
  // TODO implement all of the supported OTel types for AnyType/attributes
  public class Attribute {
    public final String key;

    public final AttributeValue value {
      get {
        value = value ?? new AttributeValue();
        return value;
      }
      set;
    }

    public Attribute(String key, Boolean value) {
      this.key = key;
      this.value = new AttributeValue(value);
    }

    // public Attribute(String key, Decimal value) {
    //   this.key = key;
    //   this.value = new AttributeValue(value);
    // }

    public Attribute(String key, Integer value) {
      this.key = key;
      this.value = new AttributeValue(value);
    }

    public Attribute(String key, String value) {
      this.key = key;
      this.value = new AttributeValue(value);
    }
  }

  @TestVisible
  private enum AnyValueType {
    arrayValue,
    boolValue,
    doubleValue,
    intValue,
    kvlistValue,
    stringValue
  }

  // For now, bytesValue is not supported in Nebula Logger,
  // even though its part of OTel's AnyType implementation.
  public class AttributeValue {
    public final List<AttributeValue> arrayValue;
    public final Boolean boolValue;
    public final Double doubleValue;
    public final Integer intValue;
    public final Map<String, Object> kvlistValue;
    public final String stringValue;

    private transient final AnyValueType dataValueType;
    private transient final Object dataValue;

    // TODO need to revisit how to handle arrays when mapping to SObject fields
    public AttributeValue(List<AttributeValue> value) {
      this.arrayValue = value;
      this.dataValueType = AnyValueType.arrayValue;
      this.dataValue = value;
    }

    public AttributeValue(Boolean value) {
      this.boolValue = value;
      this.dataValueType = AnyValueType.boolValue;
      this.dataValue = value;
    }

    public AttributeValue(Decimal value) {
      this.doubleValue = value;
      this.dataValueType = AnyValueType.doubleValue;
      this.dataValue = value;
    }

    public AttributeValue(Integer value) {
      this.intValue = value;
      this.dataValueType = AnyValueType.intValue;
      this.dataValue = value;
    }

    public AttributeValue(Map<String, AttributeValue> value) {
      this.kvlistValue = value;
      this.dataValueType = AnyValueType.kvlistValue;
      this.dataValue = value;
    }

    public AttributeValue(String value) {
      this.stringValue = value;
      this.dataValueType = AnyValueType.stringValue;
      this.dataValue = value;
    }

    private AttributeValue() {
      // TODO revisit this:
      // No-op, used by lazy-loading getters in Attribute
    }

    public AnyValueType getDataValueType() {
      return this.dataValueType;
    }

    public Object getDataValue() {
      if (this.dataValue != null) {
        return this.dataValue;
      }

      // Because OTel data will be deserialized in LoggerRestResource,
      // the code can't rely on `this.dataValue` always being set via a constructor,
      // it needs to be handled here-ish to ensure it works for deserialized instances.
      if (this.boolValue != null) {
        return this.boolValue;
      } else if (this.intValue != null) {
        return this.intValue;
      } else if (this.stringValue != null) {
        return this.stringValue;
      } else if (this.arrayValue != null) {
        return this.arrayValue;
      } else {
        return null;
      }
    }
  }

  // Resource == Shared metadata about the origin of the data (e.g., host, service, cloud info)
  //    - 'Salesforce' for any OTel data generated by Nebula Logger
  public class Resource {
    public List<Attribute> attributes {
      get {
        attributes = attributes ?? new List<Attribute>();
        return attributes;
      }
      set;
    }
  }

  // Metadata about the code that generated telemetry (library name, version)
  //    - 'NebulaLogger' for any OTel data generated by Nebula Logger
  public class Scope {
    public String name;
    public String version;
  }

  public class ScopeLog {
    public Scope scope;

    public List<LogRecord> logRecords {
      get {
        logRecords = logRecords ?? new List<LogRecord>();
        return logRecords;
      }
      set;
    }
  }

  // The individual log entries (including a message, timestamp, attributes)
  public class LogRecord {
    public AttributeValue body;
    // public String name;
    public Long observedTimeUnixNano;
    public Integer severityNumber;
    public String severityText;
    // TODO revisit mapping for spanId
    public String spanId;
    public Long timeUnixNano;
    // TODO revisit mapping for traceId
    public String traceId;

    public List<Attribute> attributes {
      get {
        attributes = attributes ?? new List<Attribute>();
        return attributes;
      }
      set;
    }

    public SeverityLevel getSeverityLevel() {
      // TODO revisit to decide if null should be returned if numb & txt are both null
      return new SeverityLevel(this.severityNumber, this.severityText);
    }
  }

  private static Map<String, System.LoggingLevel> reverseMap(Map<System.LoggingLevel, String> originalMap) {
    Map<String, System.LoggingLevel> reversedMap = new Map<String, System.LoggingLevel>();
    for (System.LoggingLevel originalKey : originalMap.keySet()) {
      String originalValue = originalMap.get(originalKey);

      reversedMap.put(originalValue, originalKey);
    }

    return reversedMap;
  }

  private static Map<String, Integer> reverseMap(Map<Integer, String> originalMap) {
    Map<String, Integer> reversedMap = new Map<String, Integer>();
    for (Integer originalKey : originalMap.keySet()) {
      String originalValue = originalMap.get(originalKey);

      reversedMap.put(originalValue, originalKey);
    }

    return reversedMap;
  }
}
