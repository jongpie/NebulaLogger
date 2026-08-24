import { existsSync, mkdirSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { parseSObject } from './parseSObject.js';
import { renderSObject } from './renderSObject.js';

const REPO_ROOT = resolve(__dirname, '..', '..', '..');
const SOURCE_TREE_ROOT = resolve(REPO_ROOT, 'nebula-logger/core/main');
const OUTPUT_ROOT = resolve(REPO_ROOT, 'docs/src/content/docs/metadata-reference/custom-objects');

interface FunctionalAreaConfig {
  label: string;
  order: number;
}

const FUNCTIONAL_AREA_CONFIG: Record<string, FunctionalAreaConfig> = {
  configuration: { label: 'Configuration', order: 1 },
  'logger-engine': { label: 'Logger Engine', order: 2 },
  'log-management': { label: 'Log Management', order: 3 }
};

function areaConfig(area: string): FunctionalAreaConfig {
  return FUNCTIONAL_AREA_CONFIG[area] ?? { label: area, order: 999 };
}

interface Discovered {
  objectDir: string;
  functionalArea: string;
}

function discoverObjects(rootDir: string): Discovered[] {
  const found: Discovered[] = [];
  if (!existsSync(rootDir)) {
    return found;
  }
  for (const functionalArea of readdirSync(rootDir)) {
    const areaDir = join(rootDir, functionalArea);
    if (!statSync(areaDir).isDirectory()) {
      continue;
    }
    const objectsDir = join(areaDir, 'objects');
    if (!existsSync(objectsDir)) {
      continue;
    }
    for (const objectApiName of readdirSync(objectsDir)) {
      const objectDir = join(objectsDir, objectApiName);
      if (!statSync(objectDir).isDirectory()) {
        continue;
      }
      const objectMetaPath = join(objectDir, `${objectApiName}.object-meta.xml`);
      if (!existsSync(objectMetaPath)) {
        continue;
      }
      found.push({ objectDir, functionalArea });
    }
  }
  return found;
}

function ensureCleanOutputDir(): void {
  if (existsSync(OUTPUT_ROOT)) {
    rmSync(OUTPUT_ROOT, { recursive: true, force: true });
  }
  mkdirSync(OUTPUT_ROOT, { recursive: true });
}

function sortedAreas(byArea: Map<string, string[]>): string[] {
  return Array.from(byArea.keys()).sort((a, b) => areaConfig(a).order - areaConfig(b).order);
}

function renderIndex(byArea: Map<string, string[]>): string {
  const lines: string[] = [];
  lines.push('---');
  lines.push('title: Custom Objects');
  lines.push('description: Every custom object, custom metadata type, hierarchy custom setting, and platform event Nebula Logger ships, grouped by functional area.');
  lines.push('sidebar:');
  lines.push('  label: Custom Objects');
  lines.push('  order: 1');
  lines.push('---');
  lines.push('');
  lines.push("Every custom object, custom metadata type, hierarchy custom setting, and platform event Nebula Logger ships, grouped by the functional area that owns it. Click any entry for the full field reference (labels, types, formulas, picklist values, security classification, and more).");
  lines.push('');
  for (const area of sortedAreas(byArea)) {
    lines.push(`## ${areaConfig(area).label}`);
    lines.push('');
    for (const name of byArea.get(area)!.slice().sort((a, b) => a.localeCompare(b))) {
      lines.push(`- [\`${name}\`](./${area}/${name.toLowerCase()}/)`);
    }
    lines.push('');
  }
  return lines.join('\n');
}


function main(): void {
  console.log('[metadata-reference] Discovering objects under nebula-logger/core/main...');
  const discovered = discoverObjects(SOURCE_TREE_ROOT);
  console.log(`[metadata-reference] Found ${discovered.length} objects.`);

  ensureCleanOutputDir();

  const byArea = new Map<string, string[]>();
  for (const { objectDir, functionalArea } of discovered) {
    const object = parseSObject(objectDir, functionalArea, SOURCE_TREE_ROOT);
    const markdown = renderSObject(object);
    const outputPath = join(OUTPUT_ROOT, functionalArea, `${object.apiName}.mdx`);
    mkdirSync(dirname(outputPath), { recursive: true });
    writeFileSync(outputPath, markdown, 'utf8');
    const existing = byArea.get(functionalArea) ?? [];
    existing.push(object.apiName);
    byArea.set(functionalArea, existing);
    console.log(`[metadata-reference]   ${functionalArea}/${object.apiName} (${object.objectType})`);
  }

  writeFileSync(join(OUTPUT_ROOT, 'index.md'), renderIndex(byArea), 'utf8');
  const total = Array.from(byArea.values()).reduce((sum, arr) => sum + arr.length, 0);
  console.log(`[metadata-reference] Wrote ${total} object pages across ${byArea.size} functional areas to ${OUTPUT_ROOT}`);
}

main();
