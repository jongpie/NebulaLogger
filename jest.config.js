const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = {
  ...jestConfig,
  coverageDirectory: './test-coverage/lwc',
  moduleNameMapper: {
    '^lightning/actions$': '<rootDir>/config/jest/mocks/lightning/actions',
    '^lightning/empApi$': '<rootDir>/config/jest/mocks/lightning/empApi',
    '^lightning/modal$': '<rootDir>/config/jest/mocks/lightning/modal',
    '^lightning/navigation$': '<rootDir>/config/jest/mocks/lightning/navigation'
  },
  // coveragePathIgnorePatterns: ['<rootDir>/nebula-logger/recipes/'],
  // modulePathIgnorePatterns: ['recipes'],
  testPathIgnorePatterns: ['<rootDir>/temp/', '<rootDir>/nebula-logger/plugins/notifications/e2e/']
};
