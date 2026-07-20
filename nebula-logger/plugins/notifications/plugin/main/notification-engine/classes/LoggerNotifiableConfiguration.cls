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
 *                  { "field": "Log__r.LoggedBy__c",                                // object form
 *                    "displayField": "Log__r.LoggedBy__r.Username",                // optional value override
 *                    "displayLabel": "Logged By" }                                 // optional label override
 *                ]
 *              }
 */
public class LoggerNotifiableConfiguration {
  private static final LoggerNotifiableConfiguration EMPTY = new LoggerNotifiableConfiguration(new Map<String, Object>());

  private final Map<String, Object> rawConfig;

  private LoggerNotifiableConfiguration(Map<String, Object> rawConfig) {
    this.rawConfig = rawConfig;
  }

  /**
   * @description Parses the JSON on a recipient's `ConfigurationJson__c` field. A blank field or
   *              malformed JSON both return an empty config that notifiers can safely fall back on.
   * @param recipient The recipient whose configuration should be parsed. May be null.
   * @return A `LoggerNotifiableConfiguration` - never null.
   */
  public static LoggerNotifiableConfiguration fromRecipient(LoggerNotificationRecipient__c recipient) {
    if (recipient == null || String.isBlank(recipient.ConfigurationJson__c)) {
      return EMPTY;
    }
    try {
      Object parsed = System.JSON.deserializeUntyped(recipient.ConfigurationJson__c);
      if (parsed instanceof Map<String, Object>) {
        return new LoggerNotifiableConfiguration((Map<String, Object>) parsed);
      }
      return EMPTY;
    } catch (System.JSONException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('LoggerNotifiableConfiguration - could not parse ConfigurationJson__c on recipient ' + recipient.Id, ex);
      }
      return EMPTY;
    }
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
   *              `getSourceFieldSpecs()` instead.
   */
  public List<String> getSourceFields() {
    List<SourceFieldSpec> specs = this.getSourceFieldSpecs();
    if (specs == null) {
      return null;
    }
    List<String> result = new List<String>();
    for (SourceFieldSpec spec : specs) {
      result.add(spec.field);
    }
    return result;
  }

  /**
   * @description Returns the ordered list of source-field specs, each capturing the underlying `field` plus
   *              any `displayField` / `displayLabel` overrides. Returns null when `sourceFields` is absent
   *              from the config. An empty list is returned literally so admins can opt out of rendering
   *              any fields.
   */
  public List<SourceFieldSpec> getSourceFieldSpecs() {
    if (this.rawConfig.containsKey('sourceFields') == false) {
      return null;
    }
    Object value = this.rawConfig.get('sourceFields');
    if ((value instanceof List<Object>) == false) {
      return null;
    }
    List<SourceFieldSpec> result = new List<SourceFieldSpec>();
    for (Object entry : (List<Object>) value) {
      SourceFieldSpec spec = specFromRawEntry(entry);
      if (spec != null) {
        result.add(spec);
      }
    }
    return result;
  }

  private static SourceFieldSpec specFromRawEntry(Object entry) {
    if (entry == null) {
      return null;
    }
    if (entry instanceof String) {
      String fieldName = (String) entry;
      return String.isBlank(fieldName) ? null : new SourceFieldSpec(fieldName, null, null);
    }
    if ((entry instanceof Map<String, Object>) == false) {
      return null;
    }
    Map<String, Object> asMap = (Map<String, Object>) entry;
    Object fieldValue = asMap.get('field');
    if ((fieldValue instanceof String) == false || String.isBlank((String) fieldValue)) {
      return null;
    }
    Object displayFieldValue = asMap.get('displayField');
    Object displayLabelValue = asMap.get('displayLabel');
    return new SourceFieldSpec(
      (String) fieldValue,
      displayFieldValue instanceof String && String.isNotBlank((String) displayFieldValue) ? (String) displayFieldValue : null,
      displayLabelValue instanceof String && String.isNotBlank((String) displayLabelValue) ? (String) displayLabelValue : null
    );
  }

  /**
   * @description Describes one entry in a recipient's `sourceFields` config. The `field` API name drives
   *              hydration, linkification, and the default label / DisplayType lookup. The two optional
   *              overrides let admins tweak either the value (`displayField`) or the label (`displayLabel`)
   *              without changing what the underlying field points at.
   */
  public class SourceFieldSpec {
    /** @description The primary field API name / dotted path. Never blank. */
    public String field { get; private set; }

    /** @description Optional field API name / dotted path whose value replaces `field`'s value at render time. */
    public String displayField { get; private set; }

    /** @description Optional literal label used instead of the field's describe-provided label. */
    public String displayLabel { get; private set; }

    public SourceFieldSpec(String field, String displayField, String displayLabel) {
      this.field = field;
      this.displayField = displayField;
      this.displayLabel = displayLabel;
    }
  }
}
