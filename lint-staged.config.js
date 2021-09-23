module.exports = {
    '*.{cls,cmp,component,css,html,js,json,md,page,trigger,yaml,yml}': filenames => filenames.map(filename => `prettier --write '${filename}'`),
    '**/lwc/**': filenames => {
        return [`eslint ${filenames.join(' ')} --fix`, `npm run test:lwc`];
    },
    '*.{cls,trigger}': () => {
        return [`npm run scan`, `npm run docs:generate && git add ./docs/ && git commit --amend --no-edit`];
    }
};
