#!/usr/bin/env node

const { spawnSync } = require('node:child_process');
const { existsSync, mkdirSync, rmSync, writeFileSync, readFileSync, readdirSync, statSync } = require('node:fs');
const { join, relative, resolve } = require('node:path');
const { parseArgs } = require('node:util');

const REPO_ROOT = resolve(__dirname, '..', '..');
const APEX_OUTPUT_DIR = 'docs/src/content/docs/reference';
const LWC_OUTPUT_DIR = 'docs/src/content/docs/reference/lwc';
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
  console.log('[docs] Generating Apex + custom object reference via @cparra/apexdocs.');
  cleanApexOutput();
  ensureDir(APEX_OUTPUT_DIR);
  run('npx', ['--yes', 'apexdocs', 'markdown']);
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
