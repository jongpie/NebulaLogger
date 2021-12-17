const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
module.exports = {
  ...jestConfig,
  coverageDirectory: "./test-coverage/lwc",
  moduleNameMapper: {
    "^lightning/empApi$": "<rootDir>/config/jest/mocks/lightning/empApi",
  },
  modulePathIgnorePatterns: ["recipes"],
};
