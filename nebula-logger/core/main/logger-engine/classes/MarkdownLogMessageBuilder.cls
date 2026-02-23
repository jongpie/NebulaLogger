public without sharing class MarkdownLogMessageBuilder extends LogMessage {
  private List<String> parts = new List<String>();

  // -----------------------
  // Text helpers
  // -----------------------

  public MarkdownLogMessageBuilder text(String value) {
    if (String.isNotBlank(value)) {
      this.parts.add(value + '\n');
    }
    return this;
  }

  public MarkdownLogMessageBuilder bold(String value) {
    if (String.isNotBlank(value)) {
      this.parts.add('**' + value + '**\n');
    }
    return this;
  }

  public MarkdownLogMessageBuilder italic(String value) {
    if (String.isNotBlank(value)) {
      this.parts.add('*' + value + '*\n');
    }
    return this;
  }

  public MarkdownLogMessageBuilder inlineCode(String value) {
    if (String.isNotBlank(value)) {
      this.parts.add('`' + escapeInlineCode(value) + '`\n');
    }
    return this;
  }

  public MarkdownLogMessageBuilder quote(String value) {
    if (String.isBlank(value))
      return this;

    for (String line : value.split('\\r?\\n')) {
      this.parts.add('> ' + line);
    }
    this.parts.add(''); // blank line
    return this;
  }

  public MarkdownLogMessageBuilder divider() {
    this.parts.add('---\n');
    return this;
  }

  // -----------------------
  // Headings
  // -----------------------

  public MarkdownLogMessageBuilder heading(Integer level, String value) {
    if (String.isNotBlank(value)) {
      level = Math.max(1, Math.min(level, 6));
      this.parts.add('\n' + repeat('#', level) + ' ' + value + '\n');
    }
    return this;
  }

  // -----------------------
  // Lists
  // -----------------------

  public MarkdownLogMessageBuilder bullet(String value) {
    if (String.isNotBlank(value)) {
      this.parts.add('- ' + value);
    }
    return this;
  }

  public MarkdownLogMessageBuilder bullets(List<String> values) {
    if (values != null) {
      for (String v : values) {
        this.bullet(v);
      }
      this.parts.add(''); // blank line
    }
    return this;
  }

  public MarkdownLogMessageBuilder numbered(Integer index, String value) {
    if (String.isNotBlank(value)) {
      this.parts.add(String.valueOf(index ?? 1) + '. ' + value);
    }
    return this;
  }

  // -----------------------
  // Key/Value convenience
  // -----------------------

  public MarkdownLogMessageBuilder kv(String key, Object value) {
    if (String.isNotBlank(key)) {
      this.parts.add('- **' + key + ':** ' + (value == null ? '' : String.valueOf(value)));
    }
    return this;
  }

  public MarkdownLogMessageBuilder kvTable(Map<String, Object> data) {
    if (data == null || data.isEmpty()) {
      return this;
    }

    List<String> keys = new List<String>(data.keySet());
    keys.sort();

    List<List<String>> rows = new List<List<String>>();
    for (String k : keys) {
      Object v = data.get(k);
      rows.add(new List<String>{ k, v == null ? '' : String.valueOf(v) });
    }

    return this.table(new List<String>{ 'Key', 'Value' }, rows);
  }

  // -----------------------
  // Code blocks / JSON
  // -----------------------

  public MarkdownLogMessageBuilder codeBlock(String code, String language) {
    this.parts.add('```' + (String.isBlank(language) ? '' : language));
    this.parts.add(code == null ? '' : code);
    this.parts.add('```\n');
    return this;
  }

  public MarkdownLogMessageBuilder json(Object obj) {
    return codeBlock(System.JSON.serializePretty(obj), 'json');
  }

  public MarkdownLogMessageBuilder exception(Exception e) {
    if (e == null) {
      return this;
    }

    this.parts.add('**' + e.getTypeName() + ':** ' + e.getMessage() + '\n');

    String stack = e.getStackTraceString();
    if (String.isNotBlank(stack)) {
      // "java" tends to look nicest in Prism for Apex stack traces
      codeBlock(stack.trim(), 'java');
    }
    return this;
  }

  // -----------------------
  // Tables
  // -----------------------

  public MarkdownLogMessageBuilder table(List<String> headers, List<List<String>> rows) {
    if (headers == null || headers.isEmpty()) {
      return this;
    }

    this.parts.add('\n| ' + joinRow(headers) + ' |');

    List<String> sep = new List<String>();
    for (Integer i = 0; i < headers.size(); i++) {
      sep.add('---');
    }
    this.parts.add('| ' + joinRow(sep) + ' |');

    if (rows != null) {
      for (List<String> row : rows) {
        this.parts.add('| ' + joinRow(normalizeRow(row, headers.size())) + ' |');
      }
    }

    this.parts.add('\n');
    return this;
  }

  public MarkdownLogMessageBuilder tableFromSObjects(List<SObject> records, List<String> fieldApiNames) {
    return tableFromSObjects(records, fieldApiNames, null);
  }

  public MarkdownLogMessageBuilder tableFromSObjects(List<SObject> records, List<String> fieldApiNames, Map<String, String> labelsOptional) {
    if (records == null || records.isEmpty()) {
      return this;
    }

    if (fieldApiNames == null || fieldApiNames.isEmpty()) {
      return this;
    }

    List<String> headers = new List<String>();
    for (String f : fieldApiNames) {
      headers.add((labelsOptional != null && labelsOptional.containsKey(f)) ? labelsOptional.get(f) : f);
    }

    List<List<String>> rows = new List<List<String>>();
    for (SObject r : records) {
      List<String> row = new List<String>();
      for (String f : fieldApiNames) {
        Object v;
        try {
          v = r.get(f);
        } catch (Exception ex) {
          v = null;
        }
        row.add(v == null ? '' : String.valueOf(v));
      }
      rows.add(row);
    }

    return this.table(headers, rows);
  }

  // -----------------------
  // Output
  // -----------------------

  public override String getMessage() {
    // Join with \n so lines added without trailing newlines are still separated
    return String.join(parts, '\n').trim() + '\n';
  }

  // public override String toString() {
  //   return build();
  // }

  // -----------------------
  // Internals
  // -----------------------

  private static List<String> normalizeRow(List<String> row, Integer width) {
    List<String> out = new List<String>();
    for (Integer i = 0; i < width; i++) {
      out.add((row != null && i < row.size() && row[i] != null) ? row[i] : '');
    }
    return out;
  }

  private static String joinRow(List<String> cols) {
    List<String> escaped = new List<String>();
    for (String c : cols)
      escaped.add(escapeTableCell(c));
    return String.join(escaped, ' | ');
  }

  private static String escapeTableCell(String value) {
    if (value == null)
      return '';
    String v = value.replace('|', '\\|');
    v = v.replace('\r\n', '<br/>').replace('\n', '<br/>').replace('\r', '<br/>');
    return v;
  }

  private static String escapeInlineCode(String value) {
    if (value == null)
      return '';
    return value.replace('`', 'ˋ');
  }

  private static String repeat(String s, Integer times) {
    if (times == null || times <= 0)
      return '';
    String out = '';
    for (Integer i = 0; i < times; i++)
      out += s;
    return out;
  }
}
