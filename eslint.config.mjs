export default [
  { files: ['**/__tests__/*.js'], rules: { 'no-conditional-expect': 'off', '@lwc/lwc/no-unexpected-wire-adapter-usages': 'off' } },
  { ignores: ['.github/', '.husky/', '.sf/', '.sfdx/', '.vscode/', 'temp/', 'test-coverage/', '**/*.html', '**/*.css', '**/*js-meta.xml', '**/*.json'] }
];
