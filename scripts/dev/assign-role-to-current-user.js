#!/usr/bin/env node

const { spawnSync } = require('child_process');
const { parseArgs } = require('util');

const { values } = parseArgs({
  options: {
    role: { type: 'string' },
    'target-org': { type: 'string' }
  }
});

const roleName = values.role || 'Scratch Org User Role';
const targetOrg = values['target-org'];

const isWindows = process.platform === 'win32';

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

function escapeSoql(value) {
  return value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
}

function querySingle(soql) {
  const response = runSf(['data', 'query', '--query', soql]);
  return response.result.records?.[0];
}

const orgInfo = runSf(['org', 'display', '--verbose']);
const currentUsername = orgInfo.result.username;
if (!currentUsername) {
  console.error('Could not resolve the current org username.');
  process.exit(1);
}

const currentUser = querySingle(`SELECT Id, Username, UserRoleId FROM User WHERE Username = '${escapeSoql(currentUsername)}' LIMIT 1`);
if (!currentUser) {
  console.error(`Could not find user with Username '${currentUsername}'.`);
  process.exit(1);
}

if (currentUser.UserRoleId) {
  console.info('Current user already has a role.');
  console.info(`Username: ${currentUser.Username}`);
  console.info(`UserRoleId: ${currentUser.UserRoleId}`);
  process.exit(0);
}

let role = querySingle(`SELECT Id, Name FROM UserRole WHERE Name = '${escapeSoql(roleName)}' LIMIT 1`);
let roleId;
if (role) {
  roleId = role.Id;
  console.info(`Using existing role: ${roleName} (${roleId})`);
} else {
  const createResponse = runSf(['data', 'create', 'record', '--sobject', 'UserRole', '--values', `Name=${roleName}`]);
  roleId = createResponse.result.id;
  console.info(`Created role: ${roleName} (${roleId})`);
}

runSf(['data', 'update', 'record', '--sobject', 'User', '--record-id', currentUser.Id, '--values', `UserRoleId=${roleId}`]);

console.info('Assigned role to current user.');
console.info(`Username: ${currentUser.Username}`);
console.info(`UserRoleId: ${roleId}`);
