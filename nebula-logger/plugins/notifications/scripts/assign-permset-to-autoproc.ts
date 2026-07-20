#!/usr/bin/env tsx
// Resolves the Automated Process user's org-scoped Username at runtime and hands it to
// `sf org assign permset --on-behalf-of`. `--on-behalf-of` needs a Username that varies per org
// (e.g. `autoproc@00dem00000tfgthmad`), so this helper avoids baking the org id into a script.

import { spawnSync } from 'node:child_process';
import { parseArgs } from 'node:util';

interface CliValues {
  permset?: string;
  'target-org'?: string;
}

const { values } = parseArgs({
  options: {
    permset: { type: 'string' },
    'target-org': { type: 'string' }
  }
}) as { values: CliValues };

const permsetName = values.permset;
const targetOrg = values['target-org'];

if (!permsetName) {
  console.error('Usage: tsx assign-permset-to-autoproc.ts --permset <PermissionSetName> [--target-org <alias>]');
  process.exit(1);
}

const isWindows = process.platform === 'win32';

function quoteForShell(arg: string): string {
  if (isWindows) {
    return `"${arg.replace(/"/g, '\\"')}"`;
  }
  return `'${arg.replace(/'/g, `'\\''`)}'`;
}

// sf CLI exits non-zero when a permset assignment already exists (returning a "Duplicate ..." failure
// entry in the JSON payload), so we always parse stdout as JSON and let the caller decide what counts
// as a real failure vs. an idempotent no-op.
function runSf<TResult = unknown>(args: string[]): { status?: number; result: TResult } {
  const fullArgs = [...args, '--json'];
  if (targetOrg) {
    fullArgs.push('--target-org', targetOrg);
  }
  const command = ['sf', ...fullArgs.map(quoteForShell)].join(' ');
  const result = spawnSync(command, { encoding: 'utf8', shell: true });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  try {
    return { status: result.status ?? undefined, ...JSON.parse(result.stdout) };
  } catch (parseError) {
    console.error(`sf command exited with status ${result.status} and did not return parseable JSON:`);
    console.error(`stderr: ${result.stderr}`);
    console.error(`stdout: ${result.stdout}`);
    process.exit(result.status ?? 1);
  }
}

const escapedPermsetName = permsetName.replace(/'/g, "\\'");
const soql = `SELECT Username FROM User WHERE Alias = 'autoproc' AND UserType = 'AutomatedProcess' LIMIT 1`;
const queryResponse = runSf<{ records: Array<{ Username: string }> }>(['data', 'query', '--query', soql]);
const autoProcUsername = queryResponse.result.records?.[0]?.Username;
if (!autoProcUsername) {
  console.error('Could not find the Automated Process user in this org.');
  process.exit(1);
}

const assignResponse = runSf<{ successes?: Array<unknown>; failures?: Array<{ message: string }> }>([
  'org',
  'assign',
  'permset',
  '--name',
  escapedPermsetName,
  '--on-behalf-of',
  autoProcUsername
]);

const failures = assignResponse.result.failures ?? [];
const alreadyAssigned = failures.every(failure => failure.message?.includes('Duplicate PermissionSetAssignment'));
if (failures.length === 0) {
  console.info(`Assigned ${permsetName} to Automated Process user (${autoProcUsername}).`);
} else if (alreadyAssigned) {
  console.info(`${permsetName} already assigned to Automated Process user (${autoProcUsername}) - no-op.`);
} else {
  console.error(`Failed to assign ${permsetName} to ${autoProcUsername}:`);
  for (const failure of failures) {
    console.error(`  - ${failure.message}`);
  }
  process.exit(1);
}
