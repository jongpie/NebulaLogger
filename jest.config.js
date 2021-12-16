const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
module.exports = {
  ...jestConfig,
  moduleNameMapper: {
    "^lightning/empApi$":
      "<rootDir>/config/jest/mocks/lightning/empApi",
  },
  modulePathIgnorePatterns: ["recipes"],
};
