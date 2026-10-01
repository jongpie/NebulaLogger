// For mysterious reasons, code-analyzer commands always return a 0 exit code, even when there are scan violations O_o
// So, this script is used to read code-analyzer output files & report on any scan violations

const fs = require('fs');
const path = require('path');
const { parseArgs } = require('util');

const { values } = parseArgs({
  options: {
    path: { type: 'string' }
  }
});

if (!values.path) {
  console.error('\x1b[31m%s\x1b[0m', '\n\n❌ No file path specified, specify a file path using --path\n\n');
  process.exit(1);
}

const resolvedPath = path.resolve(values.path);

if (!fs.existsSync(resolvedPath)) {
  console.error('\x1b[31m%s\x1b[0m', `\n\n❌ Could not find the specified file '${values.path}'\n\n`);
  process.exit(1);
}

const fileContents = Buffer.from(fs.readFileSync(resolvedPath));
const parsedFileContents = JSON.parse(fileContents.toString());
if (parsedFileContents.violationCounts.total > 0) {
  console.error(JSON.stringify(parsedFileContents, null, 2));
  console.error('\x1b[31m%s\x1b[0m', `\n\n❌ ${parsedFileContents.violationCounts.total} scan violations reported in '${values.path}'`);
  process.exit(1);
}

console.info('\x1b[32m%s\x1b[0m', `\n\n✅ No scan violations found in '${values.path}'\n\n`);
