#!/usr/bin/env node

const { spawnSync } = require('child_process');
const { parseArgs } = require('util');

const { values } = parseArgs({
  options: {
    network: { type: 'string' },
    'auth-provider': { type: 'string' },
    'target-org': { type: 'string' }
  }
});

if (!values.network || !values['auth-provider']) {
  console.error(
    'Usage: node ./scripts/dev/link-community-auth-provider.js --network <name> --auth-provider <developer-name> [--target-org <alias>]'
  );
  process.exit(1);
}

const networkName = values.network;
const authProviderDeveloperName = values['auth-provider'];
const targetOrg = values['target-org'];

const isWindows = process.platform === 'win32';

// Quote each arg for a shell command line. On Windows, cmd.exe needs
// double-quoted args with internal `"` escaped; POSIX shells need single quotes
// with embedded `'` closed and re-quoted.
function quoteForShell(arg) {
  if (isWindows) {
    return `"${String(arg).replace(/"/g, '\\"')}"`;
  }
  return `'${String(arg).replace(/'/g, `'\\''`)}'`;
}

function runSf(args) {
  const fullArgs = [...args, '--json'];
  if (targetOrg) {
    fullArgs.push('--target-org', targetOrg);
  }
  // Use a single shell command string (instead of [cmd, args, {shell: true}])
  // to (a) let Windows resolve the `sf.cmd` shim and (b) avoid Node's DEP0190
  // deprecation warning that fires for the array+shell combination.
  const command = ['sf', ...fullArgs.map(quoteForShell)].join(' ');
  const result = spawnSync(command, { encoding: 'utf8', shell: true });
  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }
  if (result.status !== 0) {
    console.error(result.stderr || result.stdout);
    process.exit(result.status ?? 1);
  }
  return JSON.parse(result.stdout);
}

// SOQL string literals only need single quotes and backslashes escaped.
function escapeSoql(value) {
  return value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function querySingle(soql) {
  const response = runSf(['data', 'query', '--query', soql]);
  return response.result.records?.[0];
}

const network = querySingle(
  `SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = '${escapeSoql(networkName)}' LIMIT 1`
);
if (!network || !network.UrlPathPrefix) {
  console.error(`Could not find Network '${networkName}' or its UrlPathPrefix.`);
  process.exit(1);
}

const authProvider = querySingle(
  `SELECT Id, DeveloperName FROM AuthProvider WHERE DeveloperName = '${escapeSoql(authProviderDeveloperName)}' LIMIT 1`
);
if (!authProvider) {
  console.error(`Could not find AuthProvider with DeveloperName '${authProviderDeveloperName}'.`);
  process.exit(1);
}

const authConfig = querySingle(
  `SELECT Id, DeveloperName, Url, AuthOptionsAuthProvider FROM AuthConfig WHERE Type = 'Community' AND Url LIKE '%/${escapeSoql(network.UrlPathPrefix)}' LIMIT 1`
);
if (!authConfig) {
  console.error(`Could not find AuthConfig for Network '${networkName}' (urlPathPrefix '${network.UrlPathPrefix}').`);
  process.exit(1);
}

console.info(`Network: ${networkName} (${network.Id})`);
console.info(`AuthProvider: ${authProviderDeveloperName} (${authProvider.Id})`);
console.info(`AuthConfig: ${authConfig.Id}`);

const existingLink = querySingle(
  `SELECT Id FROM AuthConfigProviders WHERE AuthConfigId = '${authConfig.Id}' AND AuthProviderId = '${authProvider.Id}' LIMIT 1`
);

if (existingLink) {
  console.info(`Auth provider is already linked (AuthConfigProviders.Id=${existingLink.Id}).`);
} else {
  runSf([
    'data',
    'create',
    'record',
    '--sobject',
    'AuthConfigProviders',
    '--values',
    `AuthConfigId=${authConfig.Id} AuthProviderId=${authProvider.Id}`
  ]);
  console.info('Linked auth provider to community login configuration.');
}

console.info('Done.');
