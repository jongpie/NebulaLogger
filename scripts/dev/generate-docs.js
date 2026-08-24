#!/usr/bin/env node

const { spawnSync } = require('node:child_process');
const { existsSync, mkdirSync, rmSync, writeFileSync, readFileSync, readdirSync, statSync } = require('node:fs');
const { join, relative, resolve } = require('node:path');
const { parseArgs } = require('node:util');

const REPO_ROOT = resolve(__dirname, '..', '..');
const APEX_OUTPUT_DIR = 'docs/src/content/docs/metadata-reference';
const LWC_OUTPUT_DIR = 'docs/src/content/docs/metadata-reference/lwc';
const PLUGINS_OUTPUT_DIR = 'docs/src/content/docs/metadata-reference/plugins';
const LWC_SOURCES = [
  {
    source: 'nebula-logger/core/main/logger-engine/lwc/logger/logger.js',
    outputFilename: 'logger.md',
    title: 'logger',
    description: 'Client-side Nebula Logger API for Lightning Web Components.'
  },
  {
    source: 'nebula-logger/core/main/logger-engine/lwc/logger/logEntryBuilder.js',
    outputFilename: 'logEntryBuilder.md',
    title: 'logEntryBuilder',
    description: 'LogEntryBuilder chainable API used by the LWC logger.'
  }
];

// Plugins to document under docs/src/content/docs/metadata-reference/plugins/<name>.
// logger-admin-dashboard is intentionally omitted - it has no Apex classes.
// The `plugin/` root folder pattern matches how the plugins are organized.
const PLUGIN_SOURCES = [
  { name: 'async-failure-additions', sourceDir: 'nebula-logger/plugins/async-failure-additions/plugin' },
  { name: 'big-object-archiving', sourceDir: 'nebula-logger/plugins/big-object-archiving/plugin' },
  { name: 'log-retention-rules', sourceDir: 'nebula-logger/plugins/log-retention-rules/plugin' },
  { name: 'slack', sourceDir: 'nebula-logger/plugins/slack/plugin' }
];

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: REPO_ROOT,
    stdio: options.captureOutput ? ['ignore', 'pipe', 'pipe'] : 'inherit',
    shell: process.platform === 'win32',
    encoding: 'utf8',
    ...options
  });
  if (result.status !== 0) {
    if (options.captureOutput) {
      process.stderr.write(result.stdout ?? '');
      process.stderr.write(result.stderr ?? '');
    }
    throw new Error(`Command failed: ${command} ${args.join(' ')} (exit code ${result.status})`);
  }
  return result;
}

function ensureDir(pathFromRoot) {
  const absolute = join(REPO_ROOT, pathFromRoot);
  if (!existsSync(absolute)) {
    mkdirSync(absolute, { recursive: true });
  }
}

function cleanApexOutput() {
  const absolute = join(REPO_ROOT, APEX_OUTPUT_DIR);
  if (!existsSync(absolute)) {
    return;
  }
  for (const entry of readdirSync(absolute)) {
    if (entry === 'lwc') {
      continue;
    }
    rmSync(join(absolute, entry), { recursive: true, force: true });
  }
}

function generateApexDocs() {
  console.log('[docs] Generating core Apex + trigger reference via @cparra/apexdocs.');
  cleanApexOutput();
  ensureDir(APEX_OUTPUT_DIR);
  run('npx', ['--yes', 'apexdocs', 'markdown'], {
    env: { ...process.env, NEBULA_DOCS_CONTEXT: 'core' }
  });
}

function generateCustomObjectDocs() {
  console.log('[docs] Generating custom object reference via metadata-reference-generator.');
  run('npx', ['--yes', 'tsx', 'scripts/dev/metadata-reference-generator/generate.ts']);
}

function generatePluginDocs() {
  console.log('[docs] Generating plugin reference via @cparra/apexdocs.');
  const pluginsRoot = join(REPO_ROOT, PLUGINS_OUTPUT_DIR);
  rmSync(pluginsRoot, { recursive: true, force: true });
  mkdirSync(pluginsRoot, { recursive: true });

  for (const plugin of PLUGIN_SOURCES) {
    console.log(`[docs]   ${plugin.name}`);
    const targetDir = `${PLUGINS_OUTPUT_DIR}/${plugin.name}`;
    run(
      'npx',
      [
        '--yes',
        'apexdocs',
        'markdown',
        '--sourceDir',
        plugin.sourceDir,
        '--targetDir',
        targetDir,
        '--scope',
        'public',
        '--referenceGuideTitle',
        `${plugin.name} plugin reference`
      ],
      {
        env: { ...process.env, NEBULA_DOCS_CONTEXT: `plugin:${plugin.name}` }
      }
    );
  }
}

function generateLwcDocs() {
  console.log('[docs] Generating LWC reference via jsdoc-to-markdown.');
  const outputDirAbsolute = join(REPO_ROOT, LWC_OUTPUT_DIR);
  rmSync(outputDirAbsolute, { recursive: true, force: true });
  mkdirSync(outputDirAbsolute, { recursive: true });

  for (const entry of LWC_SOURCES) {
    const result = run('npx', ['--yes', 'jsdoc-to-markdown', entry.source], { captureOutput: true });
    const cleanedBody = result.stdout.replace(/ ΓçÆ/g, '');
    const frontmatter = ['---', `title: ${entry.title}`, `description: ${entry.description}`, '---', ''].join('\n');
    writeFileSync(join(outputDirAbsolute, entry.outputFilename), frontmatter + cleanedBody, 'utf8');
  }

  writeFileSync(
    join(outputDirAbsolute, 'index.md'),
    [
      '---',
      'title: Lightning Web Components',
      'description: Reference for Nebula Logger Lightning Web Component APIs.',
      '---',
      '',
      '- [logger](./logger.md)',
      '- [logEntryBuilder](./logEntryBuilder.md)',
      ''
    ].join('\n'),
    'utf8'
  );
}

function formatOutput() {
  console.log('[docs] Formatting generated markdown with Prettier.');
  run('npx', ['--yes', 'prettier', '--write', APEX_OUTPUT_DIR]);
}

function verifyClean() {
  const result = spawnSync('git', ['status', '--porcelain', 'docs/'], {
    cwd: REPO_ROOT,
    encoding: 'utf8'
  });
  if (result.status !== 0) {
    throw new Error(`git status failed: ${result.stderr}`);
  }
  const uncommitted = result.stdout.trim();
  if (uncommitted) {
    process.stderr.write('[docs] Docs are out of date. The following files differ after regeneration:\n');
    process.stderr.write(uncommitted + '\n');
    process.stderr.write('[docs] Run `npm run docs:fix` locally and commit the result.\n');
    process.exit(1);
  }
  console.log('[docs] Docs are up to date.');
}

function main() {
  const { values } = parseArgs({
    options: {
      verify: { type: 'boolean', default: false },
      'apex-only': { type: 'boolean', default: false },
      'lwc-only': { type: 'boolean', default: false }
    }
  });

  const runApex = !values['lwc-only'];
  const runLwc = !values['apex-only'];

  if (runApex) {
    generateApexDocs();
    generateCustomObjectDocs();
    generatePluginDocs();
  }
  if (runLwc) {
    generateLwcDocs();
  }
  formatOutput();

  if (values.verify) {
    verifyClean();
  }
}

try {
  main();
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
}
