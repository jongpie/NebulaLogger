module.exports = {
  'sfdx-project.json': () => {
    return `npm run package:version:number:fix`;
  },
  '*.{apex,cls,cmp,component,css,html,js,json,md,page,trigger,yaml,yml}': filenames => filenames.map(filename => `prettier --write "${filename}"`),
  '**/lwc/**': filenames => {
    // Scan only the staged LWC files, not the whole repo. Run the code-analyzer's ESLint rules
    // against the staged paths and then run the SLDS linter one file at a time (the SLDS CLI
    // accepts exactly one path argument per invocation; passing multiple emits "too many arguments
    // for 'lint'"). Kept parallel to the `scan:lwc` npm script's behavior otherwise.
    const workspaces = filenames.map(filename => `--workspace "${filename}"`).join(' ');
    return [
      `npx sf code-analyzer run --rule-selector "eslint:(1,2,3)" ${workspaces} --output-file ./code-analyzer-lwc-eslint-violations.json`,
      `node ./scripts/build/validateCodeAnalyzerOutput.js --path ./code-analyzer-lwc-eslint-violations.json`,
      ...filenames.map(filename => `npx @salesforce-ux/slds-linter@latest lint "${filename}"`)
    ];
  },
  '*.{cls,trigger}': filenames => {
    // Scan only the staged Apex files, not the whole repo. Same PMD rule selection + output
    // validation that `scan:apex` uses, just scoped to the changed files.
    const workspaces = filenames.map(filename => `--workspace "${filename}"`).join(' ');
    return [
      `npx sf code-analyzer run --rule-selector "pmd:(1,2,3)" ${workspaces} --output-file ./code-analyzer-apex-pmd-violations.json`,
      `node ./scripts/build/validateCodeAnalyzerOutput.js --path ./code-analyzer-apex-pmd-violations.json`
    ];
  }
};
