module.exports = {
  'sfdx-project.json': () => {
    return `npm run package:version:number:fix`;
  },
  '*.{apex,cls,cmp,component,css,html,js,json,md,page,trigger,yaml,yml}': filenames => filenames.map(filename => `prettier --write '${filename}'`),
  '**/lwc/**': filenames => {
    return [`eslint --config ./config/linters/.eslintrc.json ${filenames.join(' ')} --fix`];
    // FIXME this command should only run tests for the changed LWCs (instead of running tests for all LWCs)
    // return [`eslint --config ./config/linters/.eslintrc.json ${filenames.join(' ')} --fix`, `npm run test:lwc`];
  },
  '*.{cls,trigger}': filenames => {
    return filenames.map(filename => `sf scanner run --pmdconfig ./config/linters/pmd-ruleset.xml --engine pmd --severity-threshold 3 --target '${filename}'`);
    // return [`npm run scan:apex`, `npm run docs:fix && git add ./docs/ && git commit --amend --no-edit`];
  }
};
