module.exports = {
  'sfdx-project.json': () => {
    return `npm run package:version:number:fix`;
  },
  '*.{apex,cls,cmp,component,css,html,js,json,md,page,trigger,yaml,yml}': filenames => {
    return filenames.map(filename => `prettier --write '${filename}'`);
  },
  // Analyze & test Apex code
  '*.{cls,trigger}': filenames => {
    const testClasses = new Set(
      filenames
        .map(filename => {
          const match = filename.match(/([^\/]+?)(_Tests)?\.cls$/);
          return match ? `${match[1]}_Tests` : null;
        })
        .filter(Boolean)
    );

    return [
      ...filenames.map(f => `sf code-analyzer run --rule-selector pmd:1 --rule-selector pmd:2 --rule-selector pmd:3 --workspace '${f}'`),
      ...([...testClasses].length ? [`sf apex run test ${[...testClasses].map(testClass => `--class-names ${testClass}`).join(' ')}`] : [])
    ];
  },
  // Analyze & test LWC code
  '**/lwc/**/*.{js,ts,html}': filenames => {
    const uniqueLwcDirectories = [...new Set(filenames.map(f => f.match(/^(.*\/lwc\/[^\/]+)/)?.[1]).filter(Boolean))];

    return [
      ...filenames.map(filename => `sf code-analyzer run --rule-selector eslint --workspace '${filename}'`),
      ...uniqueLwcDirectories.map(directory => `npx sfdx-lwc-jest -- --findRelatedTests '${directory}'`)
    ];
  }
};
