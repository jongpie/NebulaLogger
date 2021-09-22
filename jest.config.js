const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        '^lightning/empApi$': '<rootDir>/nebula-logger/tests/common/jest-mocks/lightning/empApi'
    }
};
