//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Typed accessor over the JSON payload stored in `LoggerNotificationRecipient__c.ConfigurationJson__c`.
 *              Notifiers read config values from here instead of parsing raw JSON themselves. Missing keys,
 *              blank input, and malformed JSON all resolve to an empty config, so notifiers can safely fall
 *              back to their built-in defaults.
 *
 *              Current schema (all fields optional):
 *              {
 *                "sourceFields": [
 *                  "LoggingLevel__c",                                              // bare string form
 *                  { "sourceField": "Log__r.LoggedBy__c",                          // object form
 *                    "displayField": "Log__r.LoggedBy__r.Username",                // optional value override
 *                    "displayLabel": "Logged By",                                  // optional label override
 *                    "maxLength": 50                                               // optional truncation cap
 *                  }
 *                ]
 *              }
 */
public class LoggerNotifierConfiguration {
  private final Map<String, Object> rawConfig;

  /**
   * @description Parses the JSON on a recipient's `ConfigurationJson__c` field. A blank field or
   *              malformed JSON both yield an empty configuration that notifiers can safely fall back on.
   * @param recipient The recipient whose configuration should be parsed. May be null.
   */
  public LoggerNotifierConfiguration(LoggerNotificationRecipient__c recipient) {
    this.rawConfig = parseRawConfig(recipient);
  }

  /**
   * @description Returns the string value stored at `key` in the config JSON. Returns null when the key
   *              is absent, when its value is not a string, or when its value is a blank string. Callers
   *              relying on a required key should treat null as "not configured".
   */
  public String getString(String key) {
    Object value = this.rawConfig.get(key);
    if ((value instanceof String) == false) {
      return null;
    }
    String asString = (String) value;
    return String.isBlank(asString) ? null : asString;
  }

  /**
   * @description Returns the Boolean value stored at `key` in the config JSON. Returns `defaultValue`
   *              when the key is absent or its value is not a JSON Boolean. Notifiers use this for
   *              toggle-style options (e.g. Slack's `includeNullValues`) where the built-in behavior
   *              is applied unless the admin explicitly opts out or in.
   */
  @SuppressWarnings('PMD.AvoidBooleanMethodParameters')
  public Boolean getBoolean(String key, Boolean defaultValue) {
    if (this.rawConfig.containsKey(key) == false) {
      return defaultValue;
    }
    Object value = this.rawConfig.get(key);
    return value instanceof Boolean ? (Boolean) value : defaultValue;
  }

  /**
   * @description Returns the list of string values stored at `key` in the config JSON. Returns null when
   *              the key is absent or its value is not a JSON array. Blank / null entries within the array
   *              are dropped. An explicit empty array yields an empty list literally so callers can tell
   *              "not configured" (null) from "explicitly empty" (size 0).
   */
  public List<String> getStringList(String key) {
    if (this.rawConfig.containsKey(key) == false) {
      return null;
    }
    Object value = this.rawConfig.get(key);
    if ((value instanceof List<Object>) == false) {
      return null;
    }
    List<String> result = new List<String>();
    for (Object entry : (List<Object>) value) {
      if (entry == null) {
        continue;
      }
      String asString = String.valueOf(entry);
      if (String.isNotBlank(asString)) {
        result.add(asString);
      }
    }
    return result;
  }

  /**
   * @description Returns the flat list of source-record field API names (just the `field` value of each
   *              entry) that the notifier should render. Bare-string entries yield their own name; object
   *              entries yield their `field` value. Returns null if the config does not specify
   *              `sourceFields` at all (meaning: use the notifier's built-in default set).
   *
   *              Notifiers that need the display overrides (label, display field) should use
   *              `getSourceFields()` instead.
   */
  public List<String> getSourceFieldPaths() {
    List<SourceFieldDefinition> sourceFields = this.getSourceFields();
    if (sourceFields == null) {
      return null;
    }
    List<String> result = new List<String>();
    for (SourceFieldDefinition definition : sourceFields) {
      result.add(definition.sourceField);
    }
    return result;
  }

  /**
   * @description Returns the ordered list of `SourceFieldDefinition` entries, each capturing the underlying
   *              `sourceField` plus any `displayField` / `displayLabel` overrides. Returns null when
   *              `sourceFields` is absent from the config. An empty list is returned literally so admins
   *              can opt out of rendering any fields.
   */
  public List<SourceFieldDefinition> getSourceFields() {
    if (this.rawConfig.containsKey('sourceFields') == false) {
      return null;
    }
    Object value = this.rawConfig.get('sourceFields');
    if ((value instanceof List<Object>) == false) {
      return null;
    }
    List<SourceFieldDefinition> result = new List<SourceFieldDefinition>();
    for (Object rawSourceField : (List<Object>) value) {
      SourceFieldDefinition definition = sourceFieldFromRawValue(rawSourceField);
      if (definition != null) {
        result.add(definition);
      }
    }
    return result;
  }

  private static Map<String, Object> parseRawConfig(LoggerNotificationRecipient__c recipient) {
    if (recipient == null || String.isBlank(recipient.ConfigurationJson__c)) {
      return new Map<String, Object>();
    }
    try {
      Object parsed = System.JSON.deserializeUntyped(recipient.ConfigurationJson__c);
      if (parsed instanceof Map<String, Object>) {
        return (Map<String, Object>) parsed;
      }
      return new Map<String, Object>();
    } catch (System.JSONException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('LoggerNotifierConfiguration - could not parse ConfigurationJson__c on recipient ' + recipient.Id, ex);
      }
      return new Map<String, Object>();
    }
  }

  private static SourceFieldDefinition sourceFieldFromRawValue(Object rawSourceField) {
    if (rawSourceField == null) {
      return null;
    }
    if (rawSourceField instanceof String) {
      String fieldName = (String) rawSourceField;
      return String.isBlank(fieldName) ? null : new SourceFieldDefinition(fieldName, null, null);
    }
    if ((rawSourceField instanceof Map<String, Object>) == false) {
      return null;
    }
    Map<String, Object> sourceFieldMap = (Map<String, Object>) rawSourceField;
    Object sourceFieldValue = sourceFieldMap.get('sourceField');
    if ((sourceFieldValue instanceof String) == false || String.isBlank((String) sourceFieldValue)) {
      return null;
    }
    Object displayFieldValue = sourceFieldMap.get('displayField');
    Object displayLabelValue = sourceFieldMap.get('displayLabel');
    Object maxLengthValue = sourceFieldMap.get('maxLength');
    Integer maxLength = maxLengthValue instanceof Integer && ((Integer) maxLengthValue) > 0 ? (Integer) maxLengthValue : null;
    return new SourceFieldDefinition(
      (String) sourceFieldValue,
      displayFieldValue instanceof String && String.isNotBlank((String) displayFieldValue) ? (String) displayFieldValue : null,
      displayLabelValue instanceof String && String.isNotBlank((String) displayLabelValue) ? (String) displayLabelValue : null,
      maxLength
    );
  }

  /**
   * @description Describes one entry in a recipient's `sourceFields` config. The `sourceField` API name drives
   *              the re-query, linkification, and the default label / DisplayType lookup. The three optional
   *              overrides let admins tweak either the value (`displayField`), the label (`displayLabel`), or
   *              the maximum rendered length (`maxLength`) without changing what the underlying field points at.
   *              `maxLength` is a hint for notifiers - each notifier decides how (or whether) to apply it.
   *              Notifiers that already enforce a per-field ceiling (e.g. Slack's ~2000-character attachment
   *              limit) treat the configured value as a further clamp within that ceiling.
   */
  public class SourceFieldDefinition {
    /** @description The primary field API name / dotted path. Never blank. */
    public final String sourceField;

    /** @description Optional field API name / dotted path whose value replaces `sourceField`'s value at render time. */
    public final String displayField;

    /** @description Optional literal label used instead of the field's describe-provided label. */
    public final String displayLabel;

    /**
     * @description Optional positive integer specifying the maximum number of characters that should be
     *              rendered for this field. Notifiers that honor it truncate longer values (usually with
     *              an ellipsis) at render time. Null / absent means "no admin-configured cap"; the notifier
     *              is free to apply its own default.
     */
    public final Integer maxLength;

    public SourceFieldDefinition(String sourceField, String displayField, String displayLabel) {
      this(sourceField, displayField, displayLabel, null);
    }

    public SourceFieldDefinition(String sourceField, String displayField, String displayLabel, Integer maxLength) {
      this.sourceField = sourceField;
      this.displayField = displayField;
      this.displayLabel = displayLabel;
      this.maxLength = maxLength;
    }
  }
}
