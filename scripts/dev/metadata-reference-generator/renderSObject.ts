import type { FieldMetadata, ObjectMetadata, PicklistDefinition } from './parseSObject.js';

const OBJECT_TYPE_LABEL: Record<ObjectMetadata['objectType'], string> = {
  'custom-object': 'Custom Object',
  'custom-metadata-type': 'Custom Metadata Type',
  'hierarchy-custom-setting': 'Hierarchy Custom Setting',
  'list-custom-setting': 'List Custom Setting',
  'platform-event': 'Platform Event',
  'big-object': 'Big Object'
};

const DEPRECATED_BUSINESS_STATUSES = new Set(['DeprecateCandidate', 'Deprecated', 'Retired']);

function escapeForTable(value: string | null | undefined): string {
  if (!value) {
    return '';
  }
  return value.replace(/\|/g, '\\|').replace(/\r?\n/g, ' ');
}

function escapeHtmlAttribute(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function isFieldDeprecated(field: FieldMetadata): boolean {
  return field.businessStatus != null && DEPRECATED_BUSINESS_STATUSES.has(field.businessStatus);
}

function renderPicklist(picklist: PicklistDefinition): string {
  if (picklist.globalPicklistName) {
    return `**Global Value Set:** \`${picklist.globalPicklistName}\``;
  }
  if (picklist.values.length === 0) {
    return '';
  }
  const rows = picklist.values.map(v => `| \`${v.apiName}\` | ${escapeForTable(v.label ?? v.apiName)} | ${v.isDefault ? 'Yes' : 'No'} |`);
  const notes: string[] = [];
  if (picklist.restricted) {
    notes.push('Restricted');
  }
  if (picklist.sorted) {
    notes.push('Sorted alphabetically');
  }
  const suffix = notes.length > 0 ? `\n\n_${notes.join(' - ')}_` : '';
  return ['**Picklist Values**', '', '| API Value | Label | Default |', '| --- | --- | --- |', ...rows].join('\n') + suffix;
}

interface FieldRenderOptions {
  showTrackHistory: boolean;
}

function renderFieldAttributes(field: FieldMetadata, options: FieldRenderOptions): string {
  const rows: Array<[string, string]> = [];

  if (field.label) {
    rows.push(['Label', escapeForTable(field.label)]);
  }
  rows.push(['Type', field.type]);
  if (field.length != null) {
    rows.push(['Length', String(field.length)]);
  }
  if (field.precision != null && field.scale != null) {
    rows.push(['Precision / Scale', `${field.precision} / ${field.scale}`]);
  } else if (field.precision != null) {
    rows.push(['Precision', String(field.precision)]);
  }
  rows.push(['Required', field.required ? 'Yes' : 'No']);
  if (field.unique) {
    rows.push(['Unique', 'Yes']);
  }
  if (field.externalId) {
    rows.push(['External ID', 'Yes']);
  }
  if (field.defaultValue) {
    rows.push(['Default Value', `\`${escapeForTable(field.defaultValue)}\``]);
  }
  if (field.referenceTo) {
    rows.push(['References', `\`${field.referenceTo}\``]);
  }
  if (field.relationshipName) {
    rows.push(['Relationship Name', `\`${field.relationshipName}\``]);
  }
  if (field.relationshipLabel) {
    rows.push(['Relationship Label', escapeForTable(field.relationshipLabel)]);
  }
  if (field.deleteConstraint) {
    rows.push(['Delete Constraint', field.deleteConstraint]);
  }
  if (options.showTrackHistory) {
    rows.push(['Track History', field.trackHistory ? 'Yes' : 'No']);
  }
  if (field.trackTrending) {
    rows.push(['Track Trending', 'Yes']);
  }
  if (field.complianceGroup) {
    rows.push(['Compliance Group', escapeForTable(field.complianceGroup)]);
  }
  if (field.securityClassification) {
    rows.push(['Security Classification', field.securityClassification]);
  }
  if (field.businessStatus) {
    rows.push(['Business Status', field.businessStatus]);
  }
  if (field.fieldManageability) {
    rows.push(['Field Manageability', field.fieldManageability]);
  }

  return ['| Attribute | Value |', '| --- | --- |', ...rows.map(([key, value]) => `| ${key} | ${value} |`)].join('\n');
}

function renderFieldBody(field: FieldMetadata, options: FieldRenderOptions): string {
  const parts: string[] = [];
  parts.push(`### \`${field.apiName}\``);
  parts.push('');

  if (field.description) {
    parts.push(escapeForMdx(field.description));
    parts.push('');
  }

  if (field.inlineHelpText && field.inlineHelpText !== field.description) {
    parts.push(`> ${escapeForMdx(field.inlineHelpText)}`);
    parts.push('');
  }

  parts.push(renderFieldAttributes(field, options));
  parts.push('');

  if (field.formula) {
    parts.push('**Formula**');
    parts.push('');
    parts.push('```');
    parts.push(field.formula);
    parts.push('```');
    if (field.formulaTreatBlanksAs) {
      parts.push('');
      parts.push(`_Treat blank values as: ${field.formulaTreatBlanksAs}_`);
    }
    parts.push('');
  }

  if (field.picklist) {
    const rendered = renderPicklist(field.picklist);
    if (rendered) {
      parts.push(rendered);
      parts.push('');
    }
  }

  return parts.join('\n');
}

function computeFieldTypes(field: FieldMetadata): string[] {
  const types = new Set<string>();
  if (field.type === 'MultiselectPicklist' || field.type === 'Picklist') {
    types.add('Picklist');
  } else if (field.type) {
    types.add(field.type);
  }
  if (field.formula) {
    types.add('Formula');
  }
  return Array.from(types).sort((a, b) => a.localeCompare(b));
}

function fieldSearchHaystack(field: FieldMetadata): string {
  return [field.apiName, field.label, field.description, field.inlineHelpText].filter(Boolean).join(' ').toLowerCase();
}

function renderFieldWrapper(field: FieldMetadata, options: FieldRenderOptions): string {
  const attributes: Record<string, string> = {
    'data-field-entry': 'true',
    'data-field-api-name': field.apiName,
    'data-field-types': computeFieldTypes(field).join(' '),
    'data-required': String(field.required),
    'data-deprecated': String(isFieldDeprecated(field)),
    'data-has-help-text': String(field.inlineHelpText != null),
    'data-has-description': String(field.description != null),
    'data-track-history': String(field.trackHistory),
    'data-search': fieldSearchHaystack(field)
  };
  const attrString = Object.entries(attributes)
    .map(([key, value]) => `${key}="${escapeHtmlAttribute(value)}"`)
    .join(' ');
  return `<div ${attrString}>\n\n${renderFieldBody(field, options)}\n\n</div>`;
}

function escapeForMdx(value: string): string {
  return value.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\{/g, '\\{').replace(/\}/g, '\\}');
}

function distinctFieldTypes(fields: FieldMetadata[]): string[] {
  const set = new Set<string>();
  for (const field of fields) {
    for (const type of computeFieldTypes(field)) {
      set.add(type);
    }
  }
  return Array.from(set).sort((a, b) => a.localeCompare(b));
}

export function renderSObject(object: ObjectMetadata): string {
  const description = object.description ?? `Reference for the ${object.apiName} ${OBJECT_TYPE_LABEL[object.objectType].toLowerCase()}.`;
  const frontmatter = ['---', `title: ${object.apiName}`, `description: ${JSON.stringify(description)}`, '---', ''].join('\n');

  const isSettingsOrMetadata = object.objectType === 'custom-metadata-type' || object.objectType === 'hierarchy-custom-setting' || object.objectType === 'list-custom-setting';
  const supportsFlexiPage = !isSettingsOrMetadata && object.objectType !== 'platform-event';

  const headerRows: Array<[string, string]> = [];
  headerRows.push(['Object Type', OBJECT_TYPE_LABEL[object.objectType]]);
  if (object.label) {
    headerRows.push(['Label', object.label]);
  }
  if (object.pluralLabel && object.pluralLabel !== object.label) {
    headerRows.push(['Plural Label', object.pluralLabel]);
  }
  if (!isSettingsOrMetadata) {
    headerRows.push(['Apex Trigger', object.apexTriggerName ? `\`${object.apexTriggerName}\`` : 'None']);
    if (supportsFlexiPage) {
      const flexiPageValue = object.flexiPageNames.length > 0 ? object.flexiPageNames.map(name => `\`${name}\``).join(', ') : 'None';
      headerRows.push(['FlexiPage', flexiPageValue]);
    }
    headerRows.push(['Track History', object.trackHistory ? 'Yes' : 'No']);
  }

  const totalFieldCount = object.fields.length;
  const deprecatedFieldCount = object.fields.filter(isFieldDeprecated).length;
  const activeFieldCount = totalFieldCount - deprecatedFieldCount;
  headerRows.push(['Fields', deprecatedFieldCount > 0 ? `${totalFieldCount} (${activeFieldCount} active, ${deprecatedFieldCount} deprecated)` : String(totalFieldCount)]);

  const fieldTypes = distinctFieldTypes(object.fields);
  const fieldTypesLiteral = JSON.stringify(fieldTypes);

  const body: string[] = [];
  body.push(`import FieldFilters from '/src/components/FieldFilters.astro';`);
  body.push('');
  if (object.description) {
    body.push(escapeForMdx(object.description));
    body.push('');
  }
  body.push('<div class="sobject-attributes">');
  body.push('');
  body.push('| Attribute | Value |');
  body.push('| --- | --- |');
  for (const [key, value] of headerRows) {
    body.push(`| ${key} | ${value} |`);
  }
  body.push('');
  body.push('</div>');
  body.push('');

  if (totalFieldCount > 0) {
    const fieldOptions: FieldRenderOptions = { showTrackHistory: object.trackHistory };
    const trackHistoryLiteral = JSON.stringify(object.trackHistory);
    body.push(`<h2 id="fields-heading" data-field-total="${totalFieldCount}">Fields (<span data-field-visible-count>${totalFieldCount}</span> of ${totalFieldCount})</h2>`);
    body.push('');
    body.push(`<FieldFilters types={${fieldTypesLiteral}} showTrackHistoryFilter={${trackHistoryLiteral}} />`);
    body.push('');
    for (const field of object.fields) {
      body.push(renderFieldWrapper(field, fieldOptions));
      body.push('');
    }
  }

  if (object.records.length > 0) {
    body.push(`## Records (${object.records.length})`);
    body.push('');
    for (const record of object.records) {
      body.push(renderRecordCard(record, object.fields));
      body.push('');
    }
  }

  return frontmatter + body.join('\n');
}

const HIDDEN_CMDT_RECORD_FIELDS = new Set(['Comments__c']);
const PLAIN_TEXT_CMDT_RECORD_FIELDS = new Set(['Description__c']);

function renderRecordCard(record: import('./parseSObject.js').CustomMetadataRecord, fields: FieldMetadata[]): string {
  const fieldOrder = new Map<string, number>();
  fields.forEach((f, index) => fieldOrder.set(f.apiName, index));
  const visibleValues = record.values.filter(v => !HIDDEN_CMDT_RECORD_FIELDS.has(v.field));
  const sortedValues = visibleValues.slice().sort((a, b) => {
    const orderA = fieldOrder.get(a.field) ?? Number.MAX_SAFE_INTEGER;
    const orderB = fieldOrder.get(b.field) ?? Number.MAX_SAFE_INTEGER;
    if (orderA !== orderB) {
      return orderA - orderB;
    }
    return a.field.localeCompare(b.field);
  });

  const attrs = [
    'data-cmdt-record="true"',
    `data-cmdt-record-name="${escapeHtmlAttribute(record.developerName)}"`
  ].join(' ');

  const parts: string[] = [];
  parts.push(`<div ${attrs}>`);
  parts.push('');
  parts.push(`### \`${record.developerName}\``);
  parts.push('');
  if (record.label && record.label !== record.developerName) {
    parts.push(`_${escapeForMdx(record.label)}_`);
    parts.push('');
  }
  parts.push('| Field | Value |');
  parts.push('| --- | --- |');
  for (const { field, value } of sortedValues) {
    let displayValue: string;
    if (value == null || value === '') {
      displayValue = '_(empty)_';
    } else if (PLAIN_TEXT_CMDT_RECORD_FIELDS.has(field)) {
      displayValue = escapeForTable(escapeForMdx(value));
    } else {
      displayValue = `\`${escapeForTable(value)}\``;
    }
    parts.push(`| \`${field}\` | ${displayValue} |`);
  }
  parts.push('');
  parts.push('</div>');
  return parts.join('\n');
}
