public with sharing class LoggerOpenTelemetryConverter {
    public enum AttributeType {
        boolValue,
        float64Value,
        intValue,
        stringValue
    }

    public class OpenTelemetryLoggingLevel {
        public String SeverityText { get; private set; }
        public Integer SeverityNumber { get; private set; }
    }

    public static AttributeType getAttributeType(Schema.SoapType soapType) {
        // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_enum_Schema_SOAPType.htm
        // https://opentelemetry.io/docs/specs/otel/common/attribute-type-mapping/
        AttributeType openTelemetryAttributeType;
        switch on soapType {
            when Boolean {
                openTelemetryAttributeType = AttributeType.boolValue;
            }
            when Double {
                openTelemetryAttributeType = AttributeType.float64Value;
            }
            when Integer {
                openTelemetryAttributeType = AttributeType.intValue;
            }
            when else {
                openTelemetryAttributeType = AttributeType.stringValue;
            }
        }
        return openTelemetryAttributeType;
    }

    public static OpenTelemetryLoggingLevel convertLoggingLevel(System.LoggingLevel systemLoggingLevel) {
        // return new OpenTelemetryLoggingLevel(systemLoggingLevel);
        OpenTelemetryLoggingLevel openTelemetryLoggingLevel = new OpenTelemetryLoggingLevel();
        switch on systemLoggingLevel {
            when ERROR {
                openTelemetryLoggingLevel.SeverityText = 'ERROR';
                openTelemetryLoggingLevel.SeverityNumber = 17;
            }
            when WARN {
                openTelemetryLoggingLevel.SeverityText = 'WARN';
                openTelemetryLoggingLevel.SeverityNumber = 13;
            }
            when INFO {
                openTelemetryLoggingLevel.SeverityText = 'INFO';
                openTelemetryLoggingLevel.SeverityNumber = 9;
            }
            when DEBUG {
                openTelemetryLoggingLevel.SeverityText = 'DEBUG';
                openTelemetryLoggingLevel.SeverityNumber = 5;
            }
            when FINE {
                openTelemetryLoggingLevel.SeverityText = 'TRACE3';
                openTelemetryLoggingLevel.SeverityNumber = 3;
            }
            when FINER {
                openTelemetryLoggingLevel.SeverityText = 'TRACE2';
                openTelemetryLoggingLevel.SeverityNumber = 2;
            }
            when FINEST {
                openTelemetryLoggingLevel.SeverityText = 'TRACE';
                openTelemetryLoggingLevel.SeverityNumber = 1;
            }
        }
        return openTelemetryLoggingLevel;
    }

    public static System.LoggingLevel convertLoggingLevel(OpenTelemetryLoggingLevel openTelemetryLoggingLevel) {
        System.LoggingLevel systemLoggingLevel;
        switch on openTelemetryLoggingLevel.SeverityText {
            when 'ERROR' {
                systemLoggingLevel = System.LoggingLevel.ERROR;
            }
            when 'WARN' {
                systemLoggingLevel = System.LoggingLevel.WARN;
            }
            when 'INFO' {
                systemLoggingLevel = System.LoggingLevel.INFO;
            }
            when 'DEBUG' {
                systemLoggingLevel = System.LoggingLevel.DEBUG;
            }
            when 'TRACE3' {
                systemLoggingLevel = System.LoggingLevel.FINE;
            }
            when 'TRACE2' {
                systemLoggingLevel = System.LoggingLevel.FINER;
            }
            when 'TRACE' {
                systemLoggingLevel = System.LoggingLevel.FINEST;
            }
        }
        return systemLoggingLevel;
    }

    public LoggerOpenTelemetryConverter() {
    }

    public class OpenTelemetryData {
        public List<ResourceLog> resourceLogs = new List<ResourceLog>();
    }

    public class ResourceLog {
        public Resource resource = new Resource();
        public List<ScopeLog> scopeLogs = new List<ScopeLog>();
    }

    public class Resource {
        public List<Attribute> attributes = new List<Attribute>();
    }

    public class Scope {
    }

    public class ScopeLog {
        public Scope scope;
        public List<LogRecord> logRecords = new List<LogRecord>();
    }

    public class LogRecord {
        public String timeUnixNano;
        public Integer severityNumber;
        public String severityText;
        // public AttributeValue body;
        public Map<String, String> body;
        public List<Attribute> attributes = new List<Attribute>();
        public Integer droppedAttributesCount;
        public String traceId;
        public String spanId;
    }

    // public class AttributeValue {
    //     public String stringValue;

    //     public AttributeValue(String name, String value) {
    //         this.stringValue = value;
    //     }
    // }

    public class Attribute {
        public String key;
        // public AttributeValue value;
        public Map<String, String> value;

        public Attribute(String key, AttributeType type, String value) {
            this.key = key;
            this.value = new Map<String, String>{ type.name() => value };
        }
    }



    // public static JSON2Apex parse(String json) {
    //     return (JSON2Apex) System.JSON.deserialize(json, JSON2Apex.class);
    // }

    /*
    {
        "resourceLogs": [
            {
                "resource": {
                    "attributes": [
                        {
                            "key": "resource-attr",
                            "value": { "stringValue": "resource-attr-val-1" }
                        }
                    ]
                },
                "scopeLogs": [
                    {
                        "scope": {},
                        "logRecords": [
                            {
                                "timeUnixNano": "1581452773000000789",
                                "severityNumber": 9,
                                "severityText": "Info",
                                "body": { "stringValue": "This is a log message" },
                                "attributes": [
                                    { "key": "app", "value": { "stringValue": "server" } },
                                    { "key": "instance_num", "value": { "intValue": "1" } }
                                ],
                                "droppedAttributesCount": 1,
                                "traceId": "08040201000000000000000000000000",
                                "spanId": "0102040800000000"
                            },
                            {
                                "timeUnixNano": "1581452773000000789",
                                "severityNumber": 9,
                                "severityText": "Info",
                                "body": { "stringValue": "something happened" },
                                "attributes": [
                                    { "key": "customer", "value": { "stringValue": "acme" } },
                                    { "key": "env", "value": { "stringValue": "dev" } }
                                ],
                                "droppedAttributesCount": 1,
                                "traceId": "",
                                "spanId": ""
                            }
                        ]
                    }
                ]
            }
        ]
    }
    */
}
