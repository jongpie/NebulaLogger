module.exports = {
    'sfdx-project.json': () => {
        return `npm run package:version:number:fix`;
    },
    '*.{cls,cmp,component,css,html,js,json,md,page,trigger,yaml,yml}': filenames => filenames.map(filename => `prettier --write '${filename}'`),
    '**/lwc/**': filenames => {
        return [`eslint --config ./config/linters/.eslintrc.json ${filenames.join(' ')} --fix`, `npm run test:lwc`];
    },
    '*.{cls,trigger}': () => {
        return [`npm run lint:verify:apex`];
        // return [`npm run lint:verify:apex`, `npm run docs:fix && git add ./docs/ && git commit --amend --no-edit`];
    }
};
