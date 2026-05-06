const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = {
  ...jestConfig,
  coverageDirectory: './test-coverage/lwc',
  moduleNameMapper: {
    '^lightning/empApi$': '<rootDir>/config/jest/mocks/lightning/empApi',
    '^lightning/navigation$': '<rootDir>/config/jest/mocks/lightning/navigation'
  },
  // coveragePathIgnorePatterns: ['<rootDir>/nebula-logger/recipes/'],
  // modulePathIgnorePatterns: ['recipes'],
  testPathIgnorePatterns: ['<rootDir>/temp/']
};
