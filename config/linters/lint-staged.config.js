module.exports = {
    'sfdx-project.json': () => {
        return `npm run package:version:number:fix`;
    },
    '*.{cls,cmp,component,css,html,js,json,md,page,trigger,xml,yaml,yml}': filenames => filenames.map(filename => `prettier --write '${filename}'`),
    '**/lwc/**': filenames => {
        return [`eslint --config ./config/linters/.eslintrc.json ${filenames.join(' ')} --fix`, `npm run test:lwc`];
    }
    // FIXME this command should only scan the changed Apex files (instead of scanning all Apex files)
    // '*.{cls,trigger}': () => {
    //     return [`npm run scan:apex`];
    //     // return [`npm run scan:apex`, `npm run docs:fix && git add ./docs/ && git commit --amend --no-edit`];
    // }
};
