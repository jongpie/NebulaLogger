import { XMLParser } from 'fast-xml-parser';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { basename, join } from 'node:path';

export interface PicklistValue {
  apiName: string;
  label: string | null;
  isDefault: boolean;
}

export interface PicklistDefinition {
  globalPicklistName: string | null;
  values: PicklistValue[];
  restricted: boolean;
  sorted: boolean;
}

export interface FieldMetadata {
  apiName: string;
  label: string;
  type: string;
  description: string | null;
  inlineHelpText: string | null;
  required: boolean;
  unique: boolean;
  externalId: boolean;
  length: number | null;
  precision: number | null;
  scale: number | null;
  defaultValue: string | null;
  referenceTo: string | null;
  relationshipName: string | null;
  relationshipLabel: string | null;
  deleteConstraint: string | null;
  formula: string | null;
  formulaTreatBlanksAs: string | null;
  complianceGroup: string | null;
  securityClassification: string | null;
  businessStatus: string | null;
  fieldManageability: string | null;
  trackHistory: boolean;
  trackTrending: boolean;
  picklist: PicklistDefinition | null;
}

export interface CustomMetadataRecord {
  developerName: string;
  label: string | null;
  protected: boolean;
  values: Array<{ field: string; value: string | null }>;
}

export interface ObjectMetadata {
  apiName: string;
  label: string | null;
  pluralLabel: string | null;
  description: string | null;
  objectType: ObjectKind;
  functionalArea: string;
  sourcePath: string;
  apexTriggerName: string | null;
  flexiPageNames: string[];
  trackHistory: boolean;
  fields: FieldMetadata[];
  records: CustomMetadataRecord[];
}

export type ObjectKind = 'custom-object' | 'custom-metadata-type' | 'hierarchy-custom-setting' | 'list-custom-setting' | 'platform-event' | 'big-object';

const parser = new XMLParser({
  ignoreAttributes: true,
  parseTagValue: false,
  trimValues: true
});

function asString(value: unknown): string | null {
  if (value == null) {
    return null;
  }
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return null;
}

function asBoolean(value: unknown): boolean {
  return asString(value) === 'true';
}

function asNumber(value: unknown): number | null {
  const str = asString(value);
  if (str == null) {
    return null;
  }
  const parsed = Number(str);
  return Number.isFinite(parsed) ? parsed : null;
}

function asArray<T>(value: T | T[] | undefined): T[] {
  if (value == null) {
    return [];
  }
  return Array.isArray(value) ? value : [value];
}

function parsePicklist(field: any): PicklistDefinition | null {
  const valueSet = field.valueSet;
  if (!valueSet) {
    return null;
  }

  const globalPicklistName = asString(valueSet.valueSetName);
  if (globalPicklistName) {
    return {
      globalPicklistName,
      values: [],
      restricted: false,
      sorted: false
    };
  }

  const definition = valueSet.valueSetDefinition;
  if (!definition) {
    return null;
  }

  const rawValues = asArray(definition.value);
  const values: PicklistValue[] = rawValues.map(v => ({
    apiName: asString(v.fullName) ?? '',
    label: asString(v.label),
    isDefault: asBoolean(v.default)
  }));

  return {
    globalPicklistName: null,
    values,
    restricted: asBoolean(valueSet.restricted),
    sorted: asBoolean(definition.sorted)
  };
}

function parseFieldXml(xmlPath: string): FieldMetadata {
  const raw = readFileSync(xmlPath, 'utf8');
  const parsed = parser.parse(raw);
  const field = parsed.CustomField ?? {};

  return {
    apiName: asString(field.fullName) ?? basename(xmlPath).replace(/\.field-meta\.xml$/, ''),
    label: asString(field.label) ?? '',
    type: asString(field.type) ?? '',
    description: asString(field.description),
    inlineHelpText: asString(field.inlineHelpText),
    required: asBoolean(field.required),
    unique: asBoolean(field.unique),
    externalId: asBoolean(field.externalId),
    length: asNumber(field.length),
    precision: asNumber(field.precision),
    scale: asNumber(field.scale),
    defaultValue: asString(field.defaultValue),
    referenceTo: asString(field.referenceTo),
    relationshipName: asString(field.relationshipName),
    relationshipLabel: asString(field.relationshipLabel),
    deleteConstraint: asString(field.deleteConstraint),
    formula: asString(field.formula),
    formulaTreatBlanksAs: asString(field.formulaTreatBlanksAs),
    complianceGroup: asString(field.complianceGroup),
    securityClassification: asString(field.securityClassification),
    businessStatus: asString(field.businessStatus),
    fieldManageability: asString(field.fieldManageability),
    trackHistory: asBoolean(field.trackHistory),
    trackTrending: asBoolean(field.trackTrending),
    picklist: parsePicklist(field)
  };
}

function detectObjectKind(apiName: string, objectRoot: any): ObjectKind {
  if (apiName.endsWith('__mdt')) {
    return 'custom-metadata-type';
  }
  if (apiName.endsWith('__e')) {
    return 'platform-event';
  }
  if (apiName.endsWith('__b')) {
    return 'big-object';
  }
  if (asString(objectRoot.customSettingsType) === 'Hierarchy') {
    return 'hierarchy-custom-setting';
  }
  if (asString(objectRoot.customSettingsType) === 'List') {
    return 'list-custom-setting';
  }
  return 'custom-object';
}

function triggerBaseNameFor(objectApiName: string): string {
  return objectApiName.replace(/__(c|mdt|e|b)$/, '');
}

function findApexTriggerName(sourceTreeRoot: string, objectApiName: string): string | null {
  const expectedTrigger = `${triggerBaseNameFor(objectApiName)}.trigger`;
  const match = walkFindFirst(sourceTreeRoot, entry => entry === expectedTrigger, 'triggers');
  return match ? basename(match, '.trigger') : null;
}

function findFlexiPageNames(sourceTreeRoot: string, objectApiName: string): string[] {
  return walkFindAll(sourceTreeRoot, (entry, fullPath) => {
    if (!entry.endsWith('.flexipage-meta.xml')) {
      return false;
    }
    const raw = readFileSync(fullPath, 'utf8');
    return raw.includes(`<sobjectType>${objectApiName}</sobjectType>`);
  }).map(path => basename(path, '.flexipage-meta.xml')).sort((a, b) => a.localeCompare(b));
}

function walkFindFirst(root: string, predicate: (entryName: string, fullPath: string) => boolean, requiredParentDir?: string): string | null {
  const results = walkFindAll(root, predicate, requiredParentDir, true);
  return results[0] ?? null;
}

function walkFindAll(root: string, predicate: (entryName: string, fullPath: string) => boolean, requiredParentDir?: string, stopOnFirstMatch = false): string[] {
  const matches: string[] = [];
  if (!existsSync(root)) {
    return matches;
  }
  const stack: string[] = [root];
  while (stack.length > 0) {
    const current = stack.pop()!;
    let entries: string[];
    try {
      entries = readdirSync(current);
    } catch {
      continue;
    }
    for (const entry of entries) {
      const full = join(current, entry);
      let stat;
      try {
        stat = statSync(full);
      } catch {
        continue;
      }
      if (stat.isDirectory()) {
        stack.push(full);
        continue;
      }
      if (requiredParentDir && basename(current) !== requiredParentDir) {
        continue;
      }
      if (predicate(entry, full)) {
        matches.push(full);
        if (stopOnFirstMatch) {
          return matches;
        }
      }
    }
  }
  return matches;
}

function parseCustomMetadataRecord(xmlPath: string): CustomMetadataRecord {
  const filename = basename(xmlPath).replace(/\.md-meta\.xml$/, '');
  const developerName = filename.includes('.') ? filename.slice(filename.indexOf('.') + 1) : filename;

  const raw = readFileSync(xmlPath, 'utf8');
  const parsed = parser.parse(raw);
  const root = parsed.CustomMetadata ?? {};

  const rawValues = asArray(root.values);
  const values = rawValues.map(entry => ({
    field: asString(entry.field) ?? '',
    value: asString(entry.value)
  }));

  return {
    developerName,
    label: asString(root.label),
    protected: asBoolean(root.protected),
    values
  };
}

function findCustomMetadataRecords(sourceTreeRoot: string, objectApiName: string): CustomMetadataRecord[] {
  if (!objectApiName.endsWith('__mdt')) {
    return [];
  }
  const cmdtDeveloperName = objectApiName.replace(/__mdt$/, '');
  const matches = walkFindAll(sourceTreeRoot, entry => {
    if (!entry.endsWith('.md-meta.xml')) {
      return false;
    }
    return entry.startsWith(`${cmdtDeveloperName}.`);
  }, 'customMetadata');
  return matches.map(parseCustomMetadataRecord).sort((a, b) => a.developerName.localeCompare(b.developerName));
}

export function parseSObject(objectDir: string, functionalArea: string, sourceTreeRoot: string): ObjectMetadata {
  const apiName = basename(objectDir);
  const objectMetaFilename = `${apiName}.object-meta.xml`;
  const objectMetaPath = join(objectDir, objectMetaFilename);

  const rawObject = readFileSync(objectMetaPath, 'utf8');
  const parsedObject = parser.parse(rawObject);
  const objectRoot = parsedObject.CustomObject ?? {};

  const fieldsDir = join(objectDir, 'fields');
  const fieldFiles = existsSync(fieldsDir) ? readdirSync(fieldsDir).filter(name => name.endsWith('.field-meta.xml')) : [];

  const fields = fieldFiles.map(name => parseFieldXml(join(fieldsDir, name))).sort((a, b) => a.apiName.localeCompare(b.apiName));

  return {
    apiName,
    label: asString(objectRoot.label),
    pluralLabel: asString(objectRoot.pluralLabel),
    description: asString(objectRoot.description),
    objectType: detectObjectKind(apiName, objectRoot),
    functionalArea,
    sourcePath: objectDir,
    apexTriggerName: findApexTriggerName(sourceTreeRoot, apiName),
    flexiPageNames: findFlexiPageNames(sourceTreeRoot, apiName),
    trackHistory: asBoolean(objectRoot.enableHistory),
    fields,
    records: findCustomMetadataRecords(sourceTreeRoot, apiName)
  };
}
