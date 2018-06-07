# Apex Logger for Salesforce
[![Deploy to Salesforce](https://img.shields.io/badge/salesforce-deploy-blue.svg)](https://githubsfdeploy.herokuapp.com)
[![License: MIT](https://img.shields.io/badge/license-MIT-d742f4.svg)](https://opensource.org/licenses/MIT)
[![Travis CI](https://img.shields.io/travis/jongpie/ApexLogger/master.svg)](https://travis-ci.org/jongpie/ApexLogger)
[![Code Climate](https://img.shields.io/codeclimate/github/jongpie/ApexLogger.svg)](https://codeclimate.com/github/jongpie/ApexLogger)

Features
1. Generates 1 log per transaction that can be permanently stored in Salesforce
2. Supports adding log entries via Apex, Process Builder & Flow
3. Supports adding both debug & exception log entries to the log
4. Supports adding log entries as debug statements in Salesforce's [Debug Log](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_debugging_debug_log.htm)
5. Supports specifying a logging level for each log entry
6. Allows logging to be enabled/disabled for different users & profiles
7. Allows logging level to be configured for each user/profile
8. Allows different debug & exception log entries to be disabled/ignored without making code changes