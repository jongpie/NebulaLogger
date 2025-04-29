for (System.LoggingLevel systemLoggingLevel : System.LoggingLevel.values()) {
    LoggerOTelSchema.SeverityLevel otelSeverityLevel = new LoggerOTelSchema.SeverityLevel(systemLoggingLevel);

    System.debug('log level ' + systemLoggingLevel.name() + ' converted to OTel: ' + System.JSON.serialize(otelSeverityLevel));
}


for (LoggerOTelSchema.SeverityLevel otelSeverityLevel : LoggerOTelSchema.getSeverityLevels().values()) {
    System.debug('sev level ' + otelSeverityLevel + ' converted to logging level: ' + otelSeverityLevel.toLoggingLevel());
}