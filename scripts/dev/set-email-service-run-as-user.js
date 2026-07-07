#!/usr/bin/env node

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ENV_VAR_NAME = 'EMAIL_SERVICE_RUN_AS_USER';
const envFilePath = path.resolve(process.cwd(), '.env');

const sfResult = spawnSync('sf', ['org', 'display', '--json'], { encoding: 'utf8', shell: true });
if (sfResult.status !== 0) {
  console.error(sfResult.stderr || sfResult.stdout);
  process.exit(sfResult.status ?? 1);
}
const orgInfo = JSON.parse(sfResult.stdout);
const username = orgInfo.result?.username;
if (!username) {
  console.error('Could not resolve the current org username from `sf org display --json`.');
  process.exit(1);
}

const newLine = `${ENV_VAR_NAME}=${username}`;
const existingContents = fs.existsSync(envFilePath) ? fs.readFileSync(envFilePath, 'utf8') : '';
const lines = existingContents.length > 0 ? existingContents.split(/\r?\n/) : [];

const matcher = new RegExp(`^${ENV_VAR_NAME}=`);
const matchingIndex = lines.findIndex(line => matcher.test(line));

if (matchingIndex >= 0) {
  lines[matchingIndex] = newLine;
} else {
  if (lines.length > 0 && lines[lines.length - 1] === '') {
    lines.splice(lines.length - 1, 0, newLine);
  } else {
    lines.push(newLine);
  }
}

let updatedContents = lines.join('\n');
if (!updatedContents.endsWith('\n')) {
  updatedContents += '\n';
}
fs.writeFileSync(envFilePath, updatedContents);

console.info(`${matchingIndex >= 0 ? 'Updated' : 'Added'} ${ENV_VAR_NAME} in ${envFilePath}`);
console.info(newLine);
