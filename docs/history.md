# History

<!-- latest-start -->

## v3.80.0 (2023-09-29)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Allow setting Major and Minor Version in upload_production task by [@jain-naman-sf](https://github.com/jain-naman-sf) in [#3651](https://github.com/SFDO-Tooling/CumulusCI/pull/3651)
-   Add better error handling for empty or invalid org and service env vars by [@prescod](https://github.com/prescod) in [#3365](https://github.com/SFDO-Tooling/CumulusCI/pull/3365)
-   Query with install_key in promote_package_version (via @zenibako) by [@davidmreed](https://github.com/davidmreed) in [#3654](https://github.com/SFDO-Tooling/CumulusCI/pull/3654)
-   Trim whitespaces during service data entry by [@aditya-balachander](https://github.com/aditya-balachander) in [#3661](https://github.com/SFDO-Tooling/CumulusCI/pull/3661)
-   Display namespace in output of `cci org info` by [@jain-naman-sf](https://github.com/jain-naman-sf) in [#3662](https://github.com/SFDO-Tooling/CumulusCI/pull/3662)
-   Extend `deploy` task to support REST API deployment by [@aditya-balachander](https://github.com/aditya-balachander) in [#3650](https://github.com/SFDO-Tooling/CumulusCI/pull/3650)
-   Add `ApexTestSuite` support in the `run_tests` task by [@mjawadtp](https://github.com/mjawadtp) in [#3660](https://github.com/SFDO-Tooling/CumulusCI/pull/3660)
-   Implement variable substitution for nested structures in cumulusci.yml by [@aditya-balachander](https://github.com/aditya-balachander) in [#3665](https://github.com/SFDO-Tooling/CumulusCI/pull/3665)
-   Add XPath-based 'find_replace' functionality to `deploy` by [@aditya-balachander](https://github.com/aditya-balachander) in [#3655](https://github.com/SFDO-Tooling/CumulusCI/pull/3655)
-   Improve message description handling for scratch org cli `not_found` error by [@lakshmi2506](https://github.com/lakshmi2506) in [#3659](https://github.com/SFDO-Tooling/CumulusCI/pull/3659)
-   Add `deactivate_flows` task by [@lakshmi2506](https://github.com/lakshmi2506) in [#3664](https://github.com/SFDO-Tooling/CumulusCI/pull/3664)

### Issues Fixed 🩴

-   Add guard for empty body to github_release_report by [@jstvz](https://github.com/jstvz) in [#3645](https://github.com/SFDO-Tooling/CumulusCI/pull/3645)

## New Contributors

-   @zenibako made their first contribution in [#3654](https://github.com/SFDO-Tooling/CumulusCI/pull/3654)

*   @jain-naman-sf made their first contribution in [#3651](https://github.com/SFDO-Tooling/CumulusCI/pull/3651)
*   @aditya-balachander made their first contribution in [#3661](https://github.com/SFDO-Tooling/CumulusCI/pull/3661)
*   @mjawadtp made their first contribution in [#3660](https://github.com/SFDO-Tooling/CumulusCI/pull/3660)
*   @lakshmi2506 made their first contribution in [#3659](https://github.com/SFDO-Tooling/CumulusCI/pull/3659)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.79.0...v3.80.0

<!-- latest-stop -->

## v3.79.0 (2023-09-07)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Added workarounds to support Vlocity local compilation in CI by [@jstvz](https://github.com/jstvz) in [#3642](https://github.com/SFDO-Tooling/CumulusCI/pull/3642)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.78.0...v3.79.0

## v3.78.0 (2023-08-10)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Updated Permission Set preflights to handle Permission Set Groups by [@jkasturi-sf](https://github.com/jkasturi-sf) in [#3623](https://github.com/SFDO-Tooling/CumulusCI/pull/3623)
-   Added the `create_pull_request_on_conflict` option to automerge tasks by [@BenjaminFrench](https://github.com/ BenjaminFrench) in [#3632](https://github.com/SFDO-Tooling/CumulusCI/pull/3632)

### Issues Fixed 🩴

-   Fixed issues with uploading some Unlocked Packages by [@jstvz](https://github.com/jstvz) in [#3636](https://github.com/SFDO-Tooling/CumulusCI/pull/3636)
-   Corrected behavior of the `skip_future_releases` option by [@jstvz](https://github.com/jstvz) in [#3624](https://github.com/SFDO-Tooling/CumulusCI/pull/3624)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.77.0...v3.78.0

## v3.77.0 (2023-07-07)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Add preflight check for PSL assignments by [@davidmreed](https://github.com/davidmreed) in [#3616](https://github.com/SFDO-Tooling/CumulusCI/pull/3616)
-   Use Marketing Cloud's validate endpoint to update deployment packages by [@davidmreed](https://github.com/davidmreed) and [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3598](https://github.com/SFDO-Tooling/CumulusCI/pull/3598)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.76.0...v3.77.0

## v3.76.0.dev0 (2023-05-25)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Use Marketing Cloud's validate endpoint to update deployment packages by [@davidmreed](https://github.com/davidmreed) and [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3598](https://github.com/SFDO-Tooling/CumulusCI/pull/3598)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.76.0...v3.76.0.dev0

## v3.76.0 (2023-05-25)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Added opt-in Pydantic-based task option parsing. by [@prescod](https://github.com/prescod) in [#1618](https://github.com/SFDO-Tooling/CumulusCI/pull/1618)
-   Add deploy transform to inject org URLs by [@davidmreed](https://github.com/davidmreed) in [#3596](https://github.com/SFDO-Tooling/CumulusCI/pull/3596)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.75.1...v3.76.0

## v3.75.1 (2023-04-14)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Issues Fixed 🩴

-   Ensure that top-level 'tasks' directory is read for custom tasks by [@prescod](https://github.com/prescod) in [#3582](https://github.com/SFDO-Tooling/CumulusCI/pull/3582)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.75.0...v3.75.1

## v3.75.0 (2023-04-13)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Fix bug that prevented "api" declaration in `extract_declaration` from being respected during `capture_sample_dataset`. by [@prescod](https://github.com/prescod) in [#3568](https://github.com/SFDO-Tooling/CumulusCI/pull/3568)
-   Update windows install steps by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3571](https://github.com/SFDO-Tooling/CumulusCI/pull/3571)
-   CCI projects can now run tasks from their "sources" even when they are custom tasks coded in Python. By [@prescod](https://github.com/prescod) in [#3345](https://github.com/SFDO-Tooling/CumulusCI/pull/3345)
-   The `capture_sample_data` task now looks for a `datasetname.load.yml` file to influence how it generates its .mapping file for subquent loads. By [@prescod](https://github.com/prescod) in [#3569](https://github.com/SFDO-Tooling/CumulusCI/pull/3569)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.74.0...v3.75.0

## v3.74.0 (2023-03-06)

<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed

### Changes 🎉

-   Allow use of static release notes on GitHub by [@davidmreed](https://github.com/davidmreed) in [#3550](https://github.com/SFDO-Tooling/CumulusCI/pull/3550)
-   `cci service update` by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3481](https://github.com/SFDO-Tooling/CumulusCI/pull/3481)
-   Add TimelineObjectDefinition metadata type by [@jstvz](https://github.com/jstvz) in [#3551](https://github.com/SFDO-Tooling/CumulusCI/pull/3551)

### Issues Fixed 🩴

-   Fix an issue with `capture_sample_data` and record type capturing. by [@prescod](https://github.com/prescod) in [#3552](https://github.com/SFDO-Tooling/CumulusCI/pull/3552)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.73.0...v3.74.0

## v3.73.0 (2023-02-16)

No changes (other than dependency updates) since v3.72.1.dev2 . Please see the changes below.

## v3.72.1.dev2 (2023-02-10)

## What's Changed

### Changes 🎉

-   Include `modelVersion` in MCPM Payload by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3523](https://github.com/SFDO-Tooling/CumulusCI/pull/3523)
-   Fix MCPM deploy again by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3526](https://github.com/SFDO-Tooling/CumulusCI/pull/3526)
-   Mask invalid oauth token by [@jstvz](https://github.com/jstvz) in [#3529](https://github.com/SFDO-Tooling/CumulusCI/pull/3529)
-   Include nearly everything in the wheel by [@jstvz](https://github.com/jstvz) in [#3531](https://github.com/SFDO-Tooling/CumulusCI/pull/3531)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.72.1...v3.72.1.dev2

## v3.72.1.dev1 (2023-02-08)

## What's Changed

### Changes 🎉

-   Include `modelVersion` in MCPM Payload by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3523](https://github.com/SFDO-Tooling/CumulusCI/pull/3523)
-   Fix MCPM deploy again by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3526](https://github.com/SFDO-Tooling/CumulusCI/pull/3526)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.72.1...v3.72.1.dev1

## v3.72.1.dev0 (2023-02-08)

## What's Changed

### Changes 🎉

-   Change `deploy_marketing_cloud_package` task to include `modelVersion` in MCPM Payload by [@TheBitShepherd](https://github.com/TheBitShepherd) in [#3523](https://github.com/SFDO-Tooling/CumulusCI/pull/3523)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.72.1...v3.72.1.dev0

## v3.72.1 (2023-02-07)

## What's Changed

### Issues Fixed 🩴

-   Fixed an issue preventing installation of CumulusCI's sdist in [#3520](https://github.com/SFDO-Tooling/CumulusCI/pull/3520)

## v3.72.0 (2023-02-03)

## What's Changed

### Changes 🎉

-   Improve documentation of tasks w.r.t required/option/defauled fields. by [@prescod](https://github.com/prescod) in [#3447](https://github.com/SFDO-Tooling/CumulusCI/pull/3447)

### Issues Fixed 🩴

-   Ensure that products have a slug before publishing translations by [@prescod](https://github.com/prescod) in [#3483](https://github.com/SFDO-Tooling/CumulusCI/pull/3483)
-   Remove deprecated Playwright keywords by [@jstvz](https://github.com/jstvz) in [#3503](https://github.com/SFDO-Tooling/CumulusCI/pull/3503)
-   Stricter check on what counts as a dataset by [@prescod](https://github.com/prescod) in [#3502](https://github.com/SFDO-Tooling/CumulusCI/pull/3502)

**Full Changelog**: https://github.com/SFDO-Tooling/CumulusCI/compare/v3.71.0...v3.72.0

## 3.71.0 (2022-12-20)

Critical Changes 🎉

-   A few weeks ago we soft-launched a `load_data` feature that matched the dataset loaded to the `org_shape`. If you had discovered and used the `load_data` option called `org_shape_match_only`, you should switch to the new task because eventually we will remove the option and only use the new `load_sample_data` task. (#3455)

Changes 🎉

-   CumulusCI has two new tasks for working with sample data: `load_sample_data` and `capture_sample_data`. (#3455)
-   CumulusCI now offers the ability to inject arbitrary IDs into a project's metadata components. See the [Find-and-Replace Id Injection](https://cumulusci.readthedocs.io/en/latest/deploy.html#find-and-replace-id-injection) source transform for more information. (#3460)
-   CumulusCI now allows for injecting the current running user's username into a project's metadata components. See the [Find-and-Replace Id Injection](https://cumulusci.readthedocs.io/en/latest/deploy.html#find-and-replace-current-username-injection) source transform for more information. (#3460)

## 3.70.0 (2022-11-29)

-   The `retrieve_changes` and `list_changes` tasks now properly exclude metadata types that `SFDX` is unable to process. These include: `AuraDefinition`, `ExperienceResource`, and `LightningComponentResource` by @jstvz in https://github.com/SFDO-Tooling/CumulusCI/pull/3443
-   The `deploy_remote_site_settings` task has been updated to load the correct Remote Site Settings records for OmniStudio by @jofsky in https://github.com/SFDO-Tooling/CumulusCI/pull/3444

## 3.69.0 (2022-11-14)

Changes 🎉

-   Added support for debugging and breakpoints in Playwright-based
    Robot Framework by @boakley in
    https://github.com/SFDO-Tooling/CumulusCI/pull/3408
-   Added option for deploy task to remove selected components from the
    bundle by @jkasturi-sf in
    https://github.com/SFDO-Tooling/CumulusCI/pull/3421
-   Added documentation for using OmniStudio in Cumulus flows by
    @bethbrains in https://github.com/SFDO-Tooling/CumulusCI/pull/3427
-   Update creation of OmniStudio Remote Site Settings for new
    Salesforce domain patterns (e.g. .\*scratch.my.salesforce,
    \*.demo.my.salesforce, etc.) by @jofsky in
    https://github.com/SFDO-Tooling/CumulusCI/pull/3424
-   Added --debug flag to the deploy_marketing_cloud_package task by
    @TheBitShepherd in
    https://github.com/SFDO-Tooling/CumulusCI/pull/3430

## 3.68.1 (2022-11-01)

-   Revert a change in parsing config files which was incompatible with some configs

## 3.68.0 (2022-10-31)

Critical Changes 🎉

-   Upgraded Robot Framework from version 4.1.3 to version 6. As with most Robot Framework updates, there are a host of new features and a few deprecated features and backwards incompatibilities. For a complete list consult the [Robot Framework release notes](https://github.com/robotframework/robotframework/releases) in https://github.com/SFDO-Tooling/CumulusCI/pull/3417

Changes 🎉

-   Add support for InstallKey, sourceOrg, release keys on 2GP version create by @davidmreed in https://github.com/SFDO-Tooling/CumulusCI/pull/3403
-   We now support the `Territory2`, `Territory2Model`, `Territory2Type`, and `Territory2Rule` MetaData types. by @TheBitShepherd in https://github.com/SFDO-Tooling/CumulusCI/pull/3406
-   Add `push_upgrade_org` flow to test in simulated push upgrade environment by @davidmreed in https://github.com/SFDO-Tooling/CumulusCI/pull/3286
-   Fixed bug preventing the `deploy_omni_studio_site_settings` task from deploying to scratch orgs with the new `.scratch.` domain names by @jofsky in https://github.com/SFDO-Tooling/CumulusCI/pull/3411
-   All new keychain details are serialized using JSON, not pickle by @bethbrains in https://github.com/SFDO-Tooling/CumulusCI/pull/3390
-   Snowfakery (upgraded to 3.4) can now generate Event or Meeting Schedules similar to Calendar Apps
-   Snowfakery now has a Salesforce.ContentFile feature for generating Content Versions

Issues Fixed 🩴

-   Bumped key_size from 2048 to 4096 on advice from a security audit by @boakley in https://github.com/SFDO-Tooling/CumulusCI/pull/3389
-   Fixed an issue where unknown deploy statuses could cause polling to hang in the deploy_marketing_cloud_package task by @TheBitShepherd in https://github.com/SFDO-Tooling/CumulusCI/pull/3394
-   Fixed an injection vulnerability related to unquoted csv writers by @TheBitShepherd in https://github.com/SFDO-Tooling/CumulusCI/pull/3404

## 3.67.1 (2022-10-14)

Issues Fixed

-   We added some javascript files that were missing from the 3.67.0 release

## 3.67.0 (2022-10-13)

Critical Changes

-   CumulusCI now supports GitHub Enterprise. (#3256)
-   CumulusCI will no longer be supporting installations via `brew`. See our docs for the officially supported install method via pipx.(#3382)

Changes

-   When using Playwright instead of Selenium, we now have limited support for writing keywords in JavaScript. For more information, see the topic "Writing keywords in JavaScript" in the documentation under "Playwright Technology Preview". (#3378)
-   Auto-load dataset matching org shape name(#3384)
-   Updated the dependency resolvers used for commit-status builds (2GP and Unlocked Package parallel testing) to allow resolution to "fall back" from release branches like `feature/240` to the repository's main branch.(#3386)
-   There is a new Playwright-based keyword `Wait until salesforce is ready`. This keyword is automatically called by the Open Test Browser keyword in the SalesforcePlaywright library. In addition to waiting for the page to be rendered, it will auto attempt to detect a classic page on initial render, and automatically switch to a lightning page if one is detected.(#3387)
-   CumulusCI now supports the `CustomIndex` metadata type.(#3391)
-   CumulusCI now supports performing source transformations during the `deploy` task, including find-and-replace of user-defined tokens. (#3383)
-   Includes [Snowfakery 3.3](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v3.3.0) with new datetime features and find_record optimization.

Issues Fixed

-   Fixed a bug when using blank dates in upserts and updates.(#3361)
-   Fixed an issue where committing changes to a repository above a certain size caused timeouts to occur. (#3379)
-   CumulusCI now uses the `defusedxml` library to more securely parse xml.(#3375)

## 3.66.0 (2022-09-29)

Changes 🎉

-   New Metadata ETL task `set_object_settings` to enable and disable settings on standard and custom objects (thanks \@jlantz) (#3364)
-   For Robot tests on the Firefox profile, we now accept all cookies to prevent lightning pages from failing to render due to cross-domain cookies. (#3366)
-   Improved the method that playwright-based tests use to wait for the browser to initialize (#3366)
-   The following Robot Framework keywords now automatically generate screenshots on failure: `Click related list button`, `Click related item popup link`, `Close modal`, `Current app should be`, `Field value should be`, `Get field value`, `Populate field`, `Populate lookup field`, and `Wait until modal is closed`. (#3370)
-   CumulusCI now supports the following Metadata type: `AIApplicationConfig` (#3368)
-   CumulusCI now supports the following types from [Net Zero Cloud\'s Tooling API](https://developer.salesforce.com/docs/atlas.en-us.netzero_cloud_dev_guide.meta/netzero_cloud_dev_guide/netzero_cloud_tooling_api_parent.htm): `BldgEnrgyIntensityCnfg`, `StnryAssetEnvSrcCnfg`, `VehicleAssetEmssnSrcCnfg`. (#3372)

Issues Fixed 🩴

-   A failure when calling `capture page screenshot` no longer causes a Robot test to fail (#3366)
-   Fixed an issue where the `cci --version` command failed to output the current version (#3367)
-   A bug that prevented keywords decorated with `@capture_screenshot_on_failure` from returning a value has been fixed. (#3370)
-   Fixed a bug where requests were not being logged while running tasks or flows with the `--debug` flag. (#3371)

## 3.65.0 (2022-09-16)

Changes 🎉

-   Improve logging and add error handling for Vlocity tasks by \@prescod in (#3357)

## 3.64.0 (2022-08-18)

Changes 🎉

-   Support for upcoming Salesforce 240 Release in Robot by \@boakley (#3321)

Issues Fixed 🩴

-   Fix crash with unusual Unicode characters in metadata on Windows running `update_package_xml` by \@prescod (#3323)
-   Fix Scratch org creation in latest sfdx by \@prescod (#3334)

## 3.63.0 (2022-08-04)

Changes 🎉

-   CumulusCI can now validate MetaDeploy plans in cumulusci.yml by @jstvz in (#3298)
-   Sensitive service info is now masked in the `cci service info` command - by @bethbrains in (#3295)
-   Updated documentation for GitHub Actions framework by @davidmreed in (#3302)
-   New MetaData ETL Task for deploying remote site settings - `add_remote_site_settings` by @Br4nd0R in (#3303)
-   New task for deploying remote site settings that are required by OmniStudio - `deploy_omni_studio_site_settings` by @Br4nd0R in (#3303)
-   Added new robot keywords available when using the SalesforcePlaywright library; get current record id, wait until loading is complete and go to record home. These keywords work in a similar fashion to the existing keywords of the same name that are based on Selenium - by @boakley in (#3310)

Issues Fixed 🩴

-   Fixed two issues which prevented the `set_recently_viewed` feature from working by @prescod in (#3305)
-   The GithubIssuesParser class will now fall back if issues are disabled by @davidmreed in (#3293)

## 3.62.0 (2022-07-21)

Changes 🎉

-   CumulusCI now supports pinning dependencies on other projects by @davidmreed in (#3270)
-   Add extract declarations concept to CumulusCI by @prescod in (#3285)
-   Make `delete_data` task freezable by @jstvz in (#3294)
-   Omnistudio vlocity build tool wrapper tasks `vlocity_pack_export` and `vlocity_pack_deploy` to support datapack export and deployments by @Br4nd0R in (#3296)

## 3.61.1 (2022-07-10)

Issues Fixed 🩴

-   Fix `metadeploy_publish` error caused by supported_orgs case-sensitivity (#3277)

## 3.61.0 (2022-07-09)

Changes 🎉

-   `metadeploy_publish` consumes legal targets for supported orgs (#3239)
-   Add update_profile support for record type layouts by (#3243)
-   Add `custom` key to cumulusci.yml schema (#3238)
-   Make OrgSettings also deploy objectSettings, if present (#3235)
-   Import persistent orgs from the SFDX keychain (#3253)
-   Speed up Snowfakery handling of small batch sizes (#3188)

Issues Fixed 🩴

-   Fix JWT audience for sandboxes (#3240)
-   Fixed a bug where scratch org attributes configured via cumulusci.yml were
    not taking effect. (#3209)
-   Correct FeatureParameterString to FeatureParameterDate (#3254)
-   No postinstall script for unlocked package builds (#3247)

## 3.60.0 (2022-06-09)

Changes

-   We added a new dependency resolution strategy, `unlocked`. Like our existing dependency strategies using parallel 2GP package builds, this strategy installs parallel unlocked package builds. (#3223)
-   We added the flows `build_unlocked_test_package`, `install_unlocked_commit`, and `qa_org_unlocked` to support use of parallel unlocked packages. (#3223)
-   We added a property, `is_survey_advanced_features_enabled`, to the org_config entity available in when clauses. (#3149)
-   Robot framework API and performance keywords have been moved into separate libraries. They are still automatically imported when using Salesforce.robot so it is not necessary to modify any existing test files. (#3216)
-   There are new robot framework keyword libraries with limited support for `Playwright <https://playwright.dev/>`_ via the `robotframework-browser library <https://robotframework-browser.org/>`_. To use, import the resource file `cumulusci/robotframework/SalesforcePlaywright.robot` instead of `cumulusci/robotframework/Salesforce.robot`. Note, Playwright is not yet supported by MetaCI. (#3216)
-   `cumulusci.robotframework.BaseLibrary` can be used when creating new libraries in order to get some useful properties (`self.salesforce`, `self.salesforce_api`, `self.cumulusci`, etc) (#3216)
-   Snowfakery 3.2 is included, with the following changes
-   Snowfakery can now do random_reference to nicknames.
-   We removed some limitations on what Snowfakery can do with objects referenced through random_reference, especially using a.b.c.d syntax.
-   We added a unique option for random_reference to allow for 1-1 relationships across random references and no-duplicates many-to-many join relationships like Account->CampaignMember->Campaign

## 3.59.1 (2022-05-31)

Issues Closed

-   Fixed a regression relating to lookup of variables like `$project_config.repo_branch`. Identified as a problem in the `github_automerge_main` task, but potentially there might be other tasks that were broken and are fixed by this branch. (#3220)

## 3.59.0 (2022-05-26)

Changes

-   Setting `repo_url` in your project config is no longer required to run `metadeploy_publish`. (#3200)
-   Adds new commands `cci robot install_playwright` and `cci robot uninstall_playwright` for installing and uninstalling experimental support for the Robot Framework `Browser` library, which is based on Playwright. For more information see the section "Playwright Technology Preview" in the public documentation. (#3194)
-   Programs using CumulusCI as a library may generate warnings when getting values from config objects. A new method `config.lookup` is the preferred way to look up these values. (#3026)

## 3.58.0 (2022-05-16)

Changes

-   CumulusCI Robot Framework support has been tested on prerelease orgs (#3187)
-   Upgraded the Snowfakery dependency to version 3.1.0. When embedded in CumulusCI, Snowfakery can now do SObject Upserts. (#3195)

Issues Closed

-   Fix bug when setting the 'options' option in the robot task from the command line (#3173)

## 3.57.0 (2022-04-28)

Changes

-   Support `useralias` in `Open Test Browser` for connected orgs (#3169)

Issues Closed

-   More reliable way to find latest chronological release in GitHub (#3164)

-   Add IP Ranges Metadata ETL task (#3146)

## 3.56.0 (2022-04-07)

Changes

-   Added support for Lightning radiobuttons in the Robot keyword input form data. (#3142)

Issues Closed

-   Fixed an issue where CumulusCI was incorrectly merging task option overrides. (#3145)

## 3.55.0 (2022-03-24)

Changes

-   CumulusCI now provides an option to verify server certificates using
    root CA certs loaded from the system, instead of the default set of
    CA certs bundled with the Python requests library. This is
    considered experimental, so must be opted in by setting the
    `CUMULUSCI_SYSTEM_CERTS` environment variable to `True` (#3114)
-   Improvements to the custom locator strategy used by the Robot
    Framework keyword `input form data` to find form fields and
    lightning components based on label text. This locator strategy
    (`label:`) is now up to 10x faster at finding non-lightning form
    components, and is able to find elements with more complicated
    labels (eg: labels with text inside of nested spans). (#3117)
-   Fixed a bug that prevented the use of aliases for Robot Framework
    page objects.(#3120)
-   The Robot Framework keyword `input form data` now does a better job
    of working with non-lightning checkboxes. (#3122)

Issues Closed

-   Fixed an error that could occur when loading a project that uses
    very old flow syntax with tasks instead of steps. (#3118)
-   Fixed a bug when using `sources` to access another project from a
    github branch, where the branch context was not available to
    branch-based dependency resolvers. (#3123)
-   The `drop_missing_schema` option was not respected by the
    `snowfakery` task. Now it is. (#3125)

## 3.54.0 (2022-03-10)

Changes

-   The `install_managed` and `update_dependencies` tasks:
    -   Now support `apex_compile_type` and `upgrade_type` options for
        performing Unlocked Package installations. (#3105)
    -   Accept the options `interactive` and `base-package-url-format`,
        which pause the automation and wait for the user to confirm the
        list of packages to be installed. (#3093)
-   The `update_package_xml` task now supports new Slack metadata types
    (#3103)
-   We added the ability to do Upserts during Data Loading
    ([documentation](https://cumulusci.readthedocs.io/en/stable/data.html#upserts)).
    (#3099)
-   Robot Framework tests can now pass a locator when calling
    `Go To Page` for one of our bulit-in page objects (Listing, Detail,
    Home), and the keyword will wait until that locator is visible. This
    is mostly useful for custom pages where you need to wait for an
    iframe or custom component to be available. (#3098)
-   We improved our caching mechanisms to better handle projects whose
    cross-project sources themselves have cross-project sources. (#3092)

Issues Closed

-   Fixed a bug running the `snowfakery` task in parallel mode with orgs
    connected using a Connected App. (#3109)

## 3.53.0 (2022-02-24)

Critical Changes

-   CumulusCI now ships with Snowfakery 3.0. See the [Snowfakery release
    notes](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v3.0.0).
    Snowfakery 3.0 ships with opt-in features that will become the
    default in June 2022; please [test your
    recipes](https://snowfakery.readthedocs.io/en/latest/##snowfakery-3)
    now with `snowfakery_version: 3` to ensure compatibility.

Changes

-   CumulusCI now has an `update_data` task that allows updates to
    existing datasets, in coordination with Snowfakery 3.0.
-   Orgs connected using `cci org connect` now keep track of which
    `connected_app` service was used to connect them, and will use the
    same `connected_app` service when getting a fresh access token, even
    if it isn't currently the default `connected_app` service. This
    makes it easier to use CumulusCI with multiple `connected_app`
    services. (Orgs that were connected before this update will continue
    to use the default `connected_app` service.)
-   When connecting a custom `connected_app` service, a default
    `login_url` can be specified (to use a login URL other than
    <https://login.salesforce.com> when connecting orgs using this
    `connected_app` service).
-   The `deploy_marketing_cloud_package` task now utilizes the new API
    endpoint for deployments.
-   CumulusCI commands are more resilient in the face of corrupted or
    impossible to decode org config files.
-   We added documentation about managing Robot Framework locators
-   CumulusCI will now warn Windows users if long pathname support is
    not set up correctly.

Issues Closed

-   Fixed a bug in the JSON format output of cci service list --json

## 3.52.0 (2022-02-03)

Changes

-   Flow steps can now be replaced with the same syntax for all step
    types! (Current step types are: 'task' or 'flow'). See the
    \[replacing a flow
    step\](<https://cumulusci.readthedocs.io/en/latest/config.html?highlight=override##replace-a-flow-step>)
    docs for more details. CumulusCI is still compatible with the old
    syntax which required setting the current step type to `None` when
    replacing with a step of a differing type. (#3043)
-   Whenever possible, while running the `robot_libdoc` task libdoc
    generates relative pathnames when creating CSV output (#3058)
-   Added a new option `--preview` to the `robot_libdoc` task. When set
    to `true` it automatically opens a browser window to the generated
    documentation. (#3057)
-   The robot keyword `Locate element by label` has been removed from
    the Salesforce.py library. This wasn't designed to be a keyword but
    was accidentally exported as one. If you want to find an input or
    textarea element by its label you can use a locator of the form
    `label:<text>` (eg: `label:First Name`) (#3048)
-   Updated to [Snowfakery
    2.5.0](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v2.5.0)
-   If you have Python code that is importing CumulusCI's config
    classes, some of them have been reorganized into modules with a
    snake_case name. The old CamelCase imports should still work, but
    the new names are preferred for consistency with other parts of the
    codebase.

Issues Closed

-   Fixed an issue where overriding flow steps was not working as
    documented. (#3043)
-   We fixed a bug where the `Run Task` and `Run Task Class` robot
    keywords throw an error like
    `AttributeError: module 'robot.api.logger' has no attribute 'log'`
    in rare cases (#3053)
-   Fixed a bug in the [](snowfakery) task which caused Unique
    IDs to not always be actually unique. (#3059)

## 3.51.1 (2022-01-25)

Issues Closed

-   We fixed an issue that could cause `create_package_version` to fail
    when the `version_base` option is set to `latest_github_release` and
    the latest GitHub release is a 1GP package version.

## 3.51.0 (2022-01-20)

Changes

-   The `cci flow doc` command now only includes CumulusCI's standard
    flows unless the `--project` option is specified. (#3033)
-   The `run_tests` task now has a
    `required_per_class_code_coverage_percent` which ensures that every
    class in your project meets the code coverage level specified.
    (#3027)
-   Marketing Cloud tasks:
    -   Added the `marketing_cloud_get_user_info` task to retrieve user
        information from the Marketing Cloud REST API `userinfo`
        endpoint. (#3039)
    -   The `marketing_cloud_create_user` task now creates an unlocked
        user with a notification email address so that it is possible
        for the user to log in. This task also has a new option,
        `activate_if_existing`, which can be set to `true` to ensure
        that if the user already exists in an inactive state, it will be
        activated. (#3040)

Issues Closed

-   Fixed an issue preventing step-level preflight checks from working
    correctly in MetaDeploy when run in a cross-project flow. (#3034)
-   The `github_parent_pr_notes` task now handles child pull requests
    with an empty body. (#3038)
-   The `metadeploy_publish` task now displays a clear error message if
    you supply the wrong API URL for MetaDeploy. (#3034)
-   The `cci service default --project` command presents a better error
    message when called outside of a project directory. (#3037)
-   Fixed a bug where the `cci flow doc` command would break when using
    cross-project flows. (#3033)

## 3.50.0 (2022-01-06)

Changes

-   Robot keywords have been updated to support the Spring 22' release.
    (#3021)
-   Using channel declarations in `load.yml`, users can now do synthetic
    data loads across multiple user accounts at once. This is faster for
    some very large orgs. (#3016)

Issues Closed

-   Added a missing image to the "Windows Install Steps" portion of
    the docs. (#3013)
-   Fixed a bug that prevented `Get webelements` from returning an empty
    list if the locator was a custom locator created via the
    `register_locators` function of
    `cumulusci.robotframework.locator_manager`. (#3004)
-   Fixed a bug that prevented the locator
    `SF:object.button:Assign Reviewers` from working properly. (#3002)
-   Fixed an issue where the `--json` flag was not outputting properly
    formatted `JSON` with the `cci task list` command. (#3011)

## 3.49.0 (2021-12-09)

Critical Changes

-   **Python versions 3.6 and 3.7 are no longer supported.** Please
    ensure you have Python version 3.8, 3.9, or 3.10. (#2959)
-   The `dx_convert_from` task now uses a custom Python task class
    instead of `cumulusci.tasks.sfdx.SFDXBaseTask`. In most cases this
    will have no visible impact, but if you have customized this task
    config to change the command option, make sure you have also
    explicitly set its `class_path` to
    `cumulusci.tasks.sfdx.SFDXBaseTask`. (#2981)

Changes

-   You can now get the CumulusCI version with `cci --version`. The
    output is the same as the `cci version` command. (#2974)
-   A new feature has been added to the `robot_libdoc` task. You can now
    use `--f csv` to generate a CSV file with all of the keywords.
    (#2985)
-   New keywords `Select Rows` and `Unselect Rows` have been added to
    the robot Listing page object (#2995)
-   Queries passed to the `SOQL Query` keyword can now span multiple
    lines. (#3006)

Issues Closed

-   Fixed an issue where deleted components could still deploy into
    persistent orgs. (#2981)

## 3.48.2 (2021-11-16)

-   Fixed a regression which broke `cci project init` in CumulusCI
    3.48.0 and 3.48.1. (#2986)

## 3.48.1 (2021-11-12)

Issues Closed

-   Fixed a packaging issue which caused an error when installing on
    systems without a C compiler.

## 3.48.0 (2021-11-11)

Critical Changes

-   CumulusCI will be dropping support for Python 3.6 and 3.7 within the
    next few releases. Please ensure you're running Python 3.8 or
    above.

Changes

-   We added a new command, `cci plan info`. Similar to `cci task info`,
    this command displays detailed information about a MetaDeploy
    `plan`, and includes a `--messages` option to display user-facing
    text. (#2946)
-   Improved logging to show reduced timestamps, and provide some syntax
    highlighting of output. (#2941)
-   [Snowfakery
    2.2](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v2.2)
    is now included with CumulusCI. New features include unique IDs and
    Numeric Counters. (#2962)

Issues Closed

-   We added an improved error message when `metadeploy_publish` is
    passed a lightweight tag. (#2955)
-   Adjusted a check for .lightning. domains in the `cci org connect`
    command. (#2970)
-   We fixed an issue where stacktraces for some Apex test failures were
    truncated. (#2961)

## 3.47.0 (2021-10-28)

Changes

-   Added a `cci plan list` command for displaying a list of
    MetaDeploy plans (#2940)
-   Task options can now be marked as "sensitive". These task options
    that will be obfuscated when displayed at the beginning of each task
    in a flow. (#2939)
-   Improved error message when
    [](uninstall-packaged-incremental) is run in an
    SFDX-format project without converting to Metadata API format first
    (#2929)
-   Improved error messaging for multiple scenarios where tasks are
    improperly configured in `cumulusci.yml`. (#2923)
-   We added a new task [](create-blank-profile) that can be
    used to create a new profile from scratch without any permissions
    enabled. (This new task requires a Winter 22 Org or API 53.0)
    (#2908)
-   We've added a user-friendly error message when installing a package
    using `security_type` "PUSH" with a 04t Package
    Version ID. (#2935)

## 3.46.0 (2021-10-14)

Critical Changes

-   Backwards incompatibility: the robot task option `debug`
    has been renamed to `robot_debug`. (#2909)

Changes

-   CumulusCI now has a schema published
    [here](https://github.com/SFDO-Tooling/CumulusCI/tree/main/cumulusci/schema/cumulusci.jsonschema.json).
    This is primarily intended to be use for enabling linting in VS
    Code, but could be used for any schema-aware editor or any
    validation purpose. (#2902)
-   We added a new task [](create-blank-profile) that can be
    used to create a new profile from scratch without any permissions
    enabled. (#2908)
-   Manually creating a Personal Access Token and pasting it into the
    CLI is no longer required to connect a GitHub service. Instead,
    CumulusCI now supports GitHub's device authentication flow,
    allowing you to authenticate via browser using a temporary device
    code. (#2911)
-   `cci service info` for a github service now displays
    expiration dates for GitHub personal access tokens, if set. (#2912)
-   Improved error messaging for multiple scenarios where tasks are
    improperly configured in `cumulusci.yml`. (#2923)

Issues Fixed

-   Fixed a bug where connecting a GitHub service with `cci service connect` was failing silently. (#2888)
-   Fixed an issue where MetaDeploy steps using the old
    `filename_token` and `namespace_token`
    options could not be used. (#2914)

## 3.45.0 (2021-09-30)

Changes

-   Updated the `deploy_marketing_cloud_package` task for compatibility
    with the October 2021 release of Marketing Cloud. (#2899)
-   The `--max-lines` option on the `cci error info` command has been
    removed. (#2895)

Issues fixed

-   Removed the unused `--skip` option for the `cci flow run` command.
    (#2884)
-   Flow descriptions no longer generate a warning. (#2885)
-   We changed how the output from some commands and tasks are displayed
    in the CLI. (#2887)
-   Fixed a bug in freezing the `load_dataset` task options for
    MetaDeploy. (#2900)
-   The marketing cloud `deploy` task now properly exits when a result
    status of `FATAL_ERROR` is returned. (#2897)
-   We fixed a regression in the `push_list` task that affected 2GP push
    upgrades (#2898)

## 3.44.1 (2021-09-17)

Issues Fixed

-   We fixed a regression that resulted in upload failures for 2GP
    packages that extend 1GP packages (closes ##2880).

## 3.44.0 (2021-09-16)

Changes

-   CumulusCI uses package version Ids from 1GP releases wherever
    available, reducing the need to install 1GP packages in an org to
    build 2GP dependencies. (#2832)
-   We added `metadata_package_id` and `version_id` options to allow
    passing `MetadataPackage` (prefix 033) and `MetadataPackageVersion`
    (prefix 04t) IDs to the push upgrade tasks. (#2837)
-   `cci flow info` will now output all flow options defined. (#2845)
-   We improved error messages for incorrect data mapping files (#2831).
-   The `snowfakery` task supports specifying the `loading_rules` option
    (#2861)
-   The `snowfakery` task supports recipe options being supplied to
    recipes using the `recipe_options` option (#2861).

Issues Fixed

-   We fixed some errors in the documentation (#2854)
-   We fixed an issue causing CumulusCI to fail to install releases that
    contain an Unlocked Package without a namespace. (#2851)
-   We added handling for issues that occur when running the
    `generate_dataset_mapping` task for very large orgs (#2860).
-   We fixed a regression in using cross-project sources in MetaDeploy
    installers (#2875).

## 3.43.0 (2021-09-02)

Critical Changes

-   We now support all package installation options for the
    `update_dependencies` and `install_managed` tasks, including
    `activate_remote_site_settings`, `security_type`,
    `name_conflict_resolution`, and `password` (password not available
    for `update_dependencies`). (#2811)

    We also fixed a minor inconsistency in defaulting the
    `activate_remote_site_settings` (or formerly `activateRSS`) option.
    Projects that define custom tasks based on the
    `InstallPackageVersion` class should ensure they explicitly set the
    `activate_remote_site_settings` option, or accept the new default of
    True.

    MetaDeploy install plans now _do not_ freeze defaulted package
    install options. If your install plans are dependent on specific
    install options, we recommend explicitly specifying them. Install
    plans without explicit options will use the defaults at the time of
    execution.

Changes

-   The `sources` feature, which allows CumulusCI projects to consume
    automation from other projects, now supports specifying a
    `resolution_strategy`, just like dependencies. Sources can now
    resolve to the same GitHub refs as corresponding dependencies,
    including branch matching. The default behavior is to use the
    `production` resolution strategy. (#2807)
-   Added several new tasks for configuring Marketing Cloud:
    `marketing_cloud_create_subscriber_attribute`,
    `marketing_cloud_create_user`, and
    `marketing_cloud_update_user_role`. (#2838)
-   In the mapping file for the `load_dataset` task, the `batch_size`
    can now be specified for Bulk API steps in addition to REST API
    steps. (#2813)
-   The `snowfakery` task now supports the `ignore_row_errors` option to
    continue loading even if there are row errors. (#2819)
-   We made significant updates to the [documentation for Robot
    Framework](https://cumulusci.readthedocs.io/en/stable/robot.html).
    (#2834, ##2847)
-   We improved option validation for the `add_page_layout_fields` task.
    (#2828)

Issues Fixed

-   Fixed handling of timezones when the `start_time` option is
    specified for the push tasks. (#2814)
-   Fixed the `deploy_marketing_cloud_package` task to handle changes to
    the Marketing Cloud API. (#2816)
-   Fixed an issue where MetaDeploy install steps that used 04t package
    version Ids, including 2GP installations, were frozen with incorrect
    titles. (#2817)
-   Fixed an issue causing 2GP commit-status builds to fail when the
    local Git repository has a detached HEAD (#2818)
-   Fixed a bug in the `dry_run` option for the `metadeploy_publish`
    task where explicitly setting the option to `False` did not disable
    the dry run. (#2836)
-   Improved the error message shown by the `load_dataset` task if a
    table is missing from the dataset. (#2813)
-   Improved the warning message shown when CumulusCI can't encrypt org
    and service config files. (#2839)

Internal Changes

-   CumulusCI has improved infrastructure for its own integration tests.
    (#2783)
-   Filing a CumulusCI issue on GitHub now presents a form to enter
    details. (#2829)
-   Added a linter to ensure consistent formatting of YAML files within
    the CumulusCI codebase. (#2844)

## 3.42.0 (2021-08-19)

Critical Changes

-   The `github_release` task now requires the `tag_prefix` option to be
    passed, because for 2nd-generation packages we can't tell from the
    version number whether it is a beta or not. We've updated the
    standard release flows to set the `tag_prefix` appropriately, but if
    you have custom flows using this task you will need to update them.
    (#2792)
-   In order to run the `github_copy_subtree` task for a specific
    package version, you must now use the `tag_name` option instead of
    the `version` option. Using the `version` option set to `latest` or
    `latest_beta` is deprecated; it's preferred to pass these values in
    the `tag_name` option instead. (#2792)

Changes

-   The `uninstall_packaged_incremental` task now defaults to ignoring
    non-deletable `CustomObjectTranslation` metadata. If your project
    customizes the `ignore_types` option on
    `uninstall_packaged_incremental`, we recommend you add
    `CustomObjectTranslation` to this option. (#2790)

Issues Fixed

-   Fixed an issue where bulk job results were being miscounted. (Thanks
    \@sfdcale!) (#2789)
-   Fixed an issue where GitHub tags for a 2GP package would always
    include the "release" prefix (even for Beta package versions).
    (#2792)

## 3.41.0 (2021-08-05)

Changes

-   We added a new Metadata ETL task,
    [](add-page-layout-fields), that allows adding fields to
    existing layouts. (#2766)
-   We added a task to enable an Einstein prediction:
    [](enable-einstein-prediction) (thanks, \@erikperkins!)
    (#2778)
-   We added standard flows for releasing unlocked packages:
    [](release-unlocked-beta)] and [](release-unlocked-production) (#2768)
-   We added
    [documentation](https://cumulusci.readthedocs.io/en/stable/packaging.html)
    for using CumulusCI to build managed 2GP packages, unlocked
    packages, and extending NPSP and EDA with 2GP packages. (#2768)
-   Contributions to CCI now require verification by isort, which
    ensures consistency in the order that imports are used. (#2770)
-   CumulusCI now supports deploying unmanaged dependencies in SFDX
    source format. (#2735)
-   The [](create-package-version)] task now handles
    dependencies that use a `zip_url`. (#2735)
-   Updates to Github Actions configuration documentation. Thanks
    \@Julian88Tex (#2773)
-   CumulusCI now automatically recognizes services and orgs configured
    via environment variables. See the
    [docs](https://cumulusci.readthedocs.io/en/stable/headless.html) for
    more details. (#2676 and ##2776)
-   We've updated the Push Upgrade tasks ([](push-list),
    [](push-sandbox), etc) task option `start_time` to accept ISO-8601
    formatted datetimes. (#2769)
-   You can now specify "sandbox": true on a `CUMULUSCI_ORG_*`
    variable in headless environments to indicate that the org you want
    to connect to is a sandbox. when connecting sandbox orgs in a
    headless environment. (#2753)

Issues Closed

-   Fixed an issue where scratch orgs failed to be deleted in CI
    environments. (#2676)
-   Fixed an issue where deleting an org failed to mark the org as
    deleted on CumulusCI's keychain. (#2676)
-   Fixed an issue where CumulusCI would fail on Linux distributions
    that were incompatible with the `keyring` package.
    (#2676)
-   We fixed an issue causing the [](release-2gp-production)
    flow to fail with a dependency parsing error. (#2767)
-   Fixed a couple issues with connecting CumulusCI to sandboxes using
    enhanced domains. (#2753 and ##2765)
-   Fixed a bug where the github_release task was not marking the "This
    is a pre-release" checkbox for beta releases. (#2788)

## 3.40.1 (2021-07-22)

Issues Closed

-   Fixed an issue where a missing dependency was causing the homebrew
    installer formula to break.

## 3.40.0 (2021-07-22)

Critical Changes

-   The `create_package_version` task no longer creates Unlocked
    Packages from the `unpackaged/pre` and `unpackaged/post` directories
    of dependencies, or local `unpackaged/pre` directories by default.
    This behavior is now opt-in via the
    `create_unlocked_dependency_packages` option, which defaults to
    False. Projects using the old default behavior must explicitly set
    this option. We believe the new behavior is a more sane default for
    most 2GP projects. (#2741)

Changes

-   The `add_standard_value_set_entries` task now supports value sets
    for `LeadStatus`. (#2695, with thanks to \@naicigam)
-   We updated the default API version to 52.0. (#2740)

Issues Closed

-   Fixed an issue where the the built-in connected app was not
    accessible when running CumulusCI in a headless environment. (#2737)
-   The `create_package_version` task now supports `objectSettings` in
    the org definition file. (#2741)
-   We fixed issues in working with files containing Unicode characters
    on some Windows systems when using source-tracking commands. (#2739)
-   Fixed a bug where the `anon_apex` task had option text that was
    missing spaces. (#2736)

## 3.39.1 (2021-07-08)

Changes:

-   Fix a bug with the integration of CumulusCI and the new SOQLQuery
    Feature

## 3.39.0 (2021-07-08)

Changes:

-   A new `snowfakery` task with better usability and
    multi-processor support. Look at the CumulusCI docs to learn the new
    syntax:
    <https://cumulusci.readthedocs.io/en/stable/data.html#generate-fake-data>
    (#2705)
-   CumulusCI now uses Snowfakery 2.0, with various new features,
    especially the ability to query into orgs. More information:
    <https://github.com/SFDO-Tooling/Snowfakery/releases/tag/2.0>
    (#2705)
-   We improved our Robot documentation so that it's possible to link
    to keyword documentation instead of having to download it locally
    (#2696)
-   CumulusCI uses a new port (7788) for the built-in connected app to
    lessen the chances that the port is in use. (#2698)
-   CumulusCI now checks if the port associated with a callback
    URL/redirect URI is in use during OAuth2 flows, and if so, raises a
    more friendly error. (#2698)
-   The `generate_data_dictionary` task now includes Custom Settings,
    Custom Metadata Types, and Platform Events. (#2712)
-   The `generate_data_dictionary` task now excludes any schema with
    visibility set to Protected. This behavior can be turned off
    (including protected schema) with the `include_protected_schema`
    option. (#2712)
-   The `generate_data_dictionary` task now parses object and field
    metadata anywhere in a Salesforce DX release other than in the
    `unpackaged/` directory tree. (#2712)
-   Builds that install feature-test 2GP packages now present a cleaner
    error message when the current commit is not found on GitHub.
    (#2713)
-   SFDX and CumulusCI both support noancestors as a Scratch org config
    option but CumulusCI generated a warning if users tried to specify
    the option in cumulusci.yml. (#2721)

Issues closed:

-   Fixed issue where CumulusCI did not correctly convert a package
    version specified as a number in YAML to a string. This now raises a
    warning. (#2692)
-   Fixed a bug where OAuth errors were not reported in detail. (#2694)
-   Fixed an issue where CumulusCI did not grant permissions to Custom
    Tabs when running `update_admin_profile` without a custom
    `package.xml`. Projects that use a custom `package.xml` with
    `update_admin_profile` should update their manifest to include a
    `CustomTab` wildcard for the same outcome. (#2699)
-   Fixed an issue where the `dx`, `dx_push`, and `dx_pull` tasks did
    not refresh the org's access token. (#2703)
-   Fixed issues in the `generate_data_dictionary` task that resulted in
    failures when processing fields with blank Help Text or processing
    standard fields. (#2706)
-   Fixed an issue preventing `generate_data_dictionary` from working
    with four-digit (1.0.0.0) 2GP version numbers. (#2712)
-   Fixed an issue causing `release_2gp_beta` to fail to create a GitHub
    release with a dependency-parsing error. (#2720)

## 3.38.0 (2021-06-24)

Changes:

-   The built-in connected app that CumulusCI uses by default is now
    visible in the output of the `cci service list` command. This makes
    it possible to switch back and forth between this connected app and
    another one as the current default when multiple connected_app
    services are configured. The built-in connected_app service has the
    name `built-in` and cannot be renamed or removed. (#2664)
-   The `generate_data_dictionary` task includes a new option,
    `include_prerelease`. If set to `True`, CumulusCI will include
    unreleased schema in the data dictionary from the current branch on
    GitHub, with the version listed as "Prerelease". (#2671)
-   Added a new task, `gather_release_notes`, which generates an HTML
    file with release notes from multiple repositories. (#2633)
-   The `deploy_marketing_cloud_package` task includes a new option,
    `custom_inputs`, which can be used to specify values to fill in for
    inputs in a Marketing Cloud package. (#2683)
-   Mappings for the `extract_dataset` task can now specify a
    `soql_filter` to restrict which records are extracted. Thanks
    \@sfdcale (#2663)
-   Robot Framework: The `Scroll Element Into View` keyword in the
    Salesforce library now scrolls the center of the element into view
    rather than the top. (#2689)

Issues closed:

-   Fixed a bug where CumulusCI could not parse the repository owner and
    name from an ssh git remote URL if it used an ssh alias instead of
    `github.com`. (#2684)
-   Fixed a bug where `cci service info <service_type>` would display
    `None` as the name for the default service if no name was provided.
    (#2664)
-   Fixed a missing dependency on the `contextvars` Python package in
    Python 3.6.

## 3.37.0 (2021-06-10)

Changes

-   The `install_managed` task now supports 2GP releases (#2655).
-   We changed the behavior of the `release_2gp_beta` flow to always
    upload a package version, even if metadata has not changed (#2651).
-   We now support sourcing install keys for packages from environment
    variables via the `password_env_name` dependency key (#2622).

Robot Framework

-   We upgraded SeleniumLibrary to 5.x (#2660).
-   We added a new keyword "select window" to Salesforce library, to
    replace the keyword of the same name which was renamed in
    SeleniumLibrary 5.x to 'switch window'. We will be removing this
    keyword in a future release; tests should use 'switch window'
    instead.

Issues Closed

-   We corrected some JavaScript issues that were occurring with
    Chrome 91. (#2652)
-   We fixed a bug impacting the `generate_data_dictionary` task when
    used with dependencies (#2653).
-   We fixed an issue causing `sfdx` commands that had options with
    spaces to fail to execute on Windows (#2656).
-   We fixed an issue causing the creation of incorrect 2GP beta tags
    (#2651).

## 3.36.0 (2021-05-27)

Changes

-   Added the option `tag_prefix` to the `github_release` task. This
    option can be set to specify what prefix you would like to use when
    CumulusCI creates a release tag for you in GitHub. (#2642)
-   The `deploy_marketing_cloud_package` task has been updated to match
    changes to the Marketing Cloud Package Manager API. It also now
    raises an exception if the deployment failed. (#2632)

Robot Framework

-   Improved the output of the `robot_libdoc` task. (#2627)

Data generation with Snowfakery:

-   Updated to [Snowfakery
    1.12](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.12)
    (#2538)

Issues Closed

-   Fixed an issue where flow reference documentation was rendering with
    an error. (#2646)
-   CumulusCI will now remove orgs when the `--delete-org` option is
    passed to `cci flow run`, even if an error occurs while running the
    flow. (#2644)
-   Fixed a bug where beta tags created via the `release_2gp_beta` flow
    were not receiving the proper tag prefix. (#2642)
-   Fixed namespace injection for filenames with a `___NAMESPACE___`
    token in sfdx format. (#2631) (Thanks \@bethbrains)
-   Fixed a bug in `cci org connect` where the `--sandbox` flag was
    directing users to login at `login.salesforce.com` instead of
    `test.salesforce.com`. (#2630)
-   Fixed a regression where the `skip` key for a dependency could no
    longer be specified as a single string instead of a list. (#2629)
-   Fixed a regression in freezing the `deploy_pre`/`deploy_post` tasks
    for MetaDeploy install plans. (#2626)
-   Fixed bugs in the `deploy_marketing_cloud_package` task's payload
    construction. (#2620, ##2621)

## 3.35.0 (2021-05-13)

Critical Changes

-   Upgraded Robot Framework to 4.x. For information about new features
    and some backward incompatibilities see the [Robot Framework 4.0
    release
    notes](https://github.com/robotframework/robotframework/blob/master/doc/releasenotes/rf-4.0.rst).
    (#2603)
-   The `update_dependencies` task now guarantees to resolve unpackaged
    metadata directories (subdirectories of `unpackaged/pre` and
    `unpackaged/post`) in alphabetical order, matching the behavior of
    `deploy_pre` and `deploy_post`. `unpackaged/pre/bar` will deploy
    prior to `unpackaged/pre/foo`. The previous behavior was undefined,
    which caused rare problems. This change is critical only for
    projects that have deployment-order dependencies between unpackaged
    directories located in upstream dependencies and rely on the current
    undefined load order. (#2588)

Changes

-   The CumulusCI documentation has a new section: [Testing with
    Second-Generation
    Packaging](https://cumulusci.readthedocs.io/en/latest/2gp-testing.html)
    (#2597)
-   CumulusCI has two new service types: `oauth2_client` &
    `marketing_cloud`. These are considered experimental. (#2602)
-   The `marketing_cloud` service allows users to connect to a Marketing
    Cloud tenant via OAuth so that tasks that work with Marketing Cloud
    can make API calls on the user's behalf. (#2602)
-   The `oauth2_client` service takes information for an individual
    OAuth2 client which can then be used in place of the default client.
    This currently applies only to the `marketing_cloud` service. To
    setup a Marketing Cloud service with a specific OAuth2 client use:
    `cci service connect marketing-cloud <name-of-service> --oauth_client <name-of-oauth-client>`.
    (#2602)
-   CumulusCI has a new task: `deploy_marketing_cloud_package`. This
    task allows a user to pass the path to a .zip file to a Marketing
    Cloud package (downloaded from the Marketing Cloud Package Manager)
    and deploy the package via a `marketing_cloud` service (see above).
    Note that successfully deploying a package using this task may
    require permissions that are not generally available. (#2602)
-   The `install_managed` and `install_managed_beta` tasks now take no
    action if the specified package is already installed in the target
    org. (#2590)
-   The `cci org list` command can now output in `JSON` format by
    passing it the `--json` flag. (#2593)

Issues Closed

-   Fixed an issue parsing `cumulusci.yml` files that contained Unicode
    characters on Windows. (#2617)
-   Fixed an issue in the `github_copy_subtree` task where CumulusCI
    would silently generate incorrect or truncated commits when a
    directory was passed to the `include` task option. (#2601)
-   The `deploy_pre` and `deploy_post` tasks avoid warnings by freezing
    installer steps that match current expectations. (#2589)

## 3.34.1 (2021-04-30)

Issues Closed

-   Fixed a regression in the `load_dataset` task where some sObjects
    could not be loaded without explicitly turning off the new
    `set_recently_viewed` option.

## 3.34.0 (2021-04-29)

Critical Changes:

-   If you have custom flows that utilize the `github_release` task,
    they will need to be updated to include the `package_type` option
    (which is required). (#2546)

Changes:

-   The `github_release` task now has a `package_type` option which is included in the information written to GitHub release tags. The following standard library "release" flows have been updated with hardcoded values (either `1GP` or `2GP`) for this option:

    : - `release_beta` (1GP) - `release_production` (1GP) - `release_2gp_beta` (2GP) - `release_2gp_production` (2GP)

    (#2546)

-   The `update_dependencies` task now supports a `packages_only`
    option, which suppresses the installation of unpackaged metadata
    dependencies. This option is intended to support building
    update-only or idempotent installers. (#2587)

-   The `github_automerge_main` task has a new option,
    `skip_future_releases`, which can be set to `False` to disable the
    default behavior of skipping branches that are numeric (and thus
    considered release branches) but not the lowest number. (#2582)

-   Added an new option `set_recently_viewed` to the `load_dataset` task
    that sets newly inserted data as recently viewed. This changes the
    default behavior. By default (if you do not specify the option), the
    first 1000 records inserted via the Bulk API will be set as recently
    viewed. If fewer than 1000 records are inserted, existing objects of
    the same type being inserted will also be set as recently viewed.
    (#2578)

-   The `update_dependencies` task can now consume 2GP releases in
    upstream repositories, provided they're stored in release tags as
    generated by CumulusCI. (#2557)

-   The `extract_dataset` and `load_datast` tasks now support adding or
    removing a namespace from a mapping file to match the target org for
    sObjects and not just fields. (#2532)

-   The `create_package_version` task can now increment package version
    numbers when the package is not in a released state. (#2547)

-   Includes [Snowfakery
    1.10](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.10)
    with upgrades to its Fake data functions.

Issues Closed

-   Fixed an error in the `github_automerge_main` task when using a
    branch prefix that doesn't contain a slash. (#2582)
-   Fixed logic in the `push_sandbox` and `push_all` tasks which was
    selecting the wrong package versions. (#2577)
-   Improved logging of errors from sfdx while converting sfdx format
    metadata to deploy via the Metadata API, so that they are not lost
    when CumulusCI is embedded in another system like MetaCI or Metecho.
    (#2574)

## 3.33.1 (2021-04-20)

Changes:

-   The `create_package_version` task now accepts an `--ancestor-id`
    option to specify the 04t Id of the package version that should be
    considered the ancestor of a new managed package version. The option
    can also be set to `latest_github_release` to look up the 04t Id of
    the project's most recent release on GitHub. (#2540)

Issues closed:

-   Fixed a regression where the `release_beta` flow would throw an
    error if the project has unmanaged github dependencies. (#2566)
-   Fixed a regression where the `cci service connect` command could no
    longer connect a service without giving it a name. Now a default
    name will be assigned. (#2568)
-   Fixed a regression when resolving unpackaged dependencies from
    GitHub releases. (#2571)
-   Fixed a regression with creating a scratch org if the devhub service
    was configured but not set as the default. (#2570)
-   Improved the formatting of `cumulusci.yml` validation warnings.
    (#2567)

## 3.33.0 (2021-04-19)

Critical Changes:

-   CumulusCI's dependency management modules have been rewritten. This
    grants new capabilities and removes some existing features. (#2456)

    -   All package installations now perform retries if the package is
        not yet available.

    -   Package installations are also retried on common row locking
        errors.

    -   You can now obtain fine-grained control over how your projects
        resolve dependencies. It's much easier to control where your
        application uses beta managed packages and second-generation
        packages to satisfy dependencies.

    -   You can now execute 2GP builds that use 2GPs from upstream
        feature branches matching your current branch, not just release
        branches.

    -   The `update_dependencies` task no longer supports uninstalling
        managed packages in a persistent org as part of the dependency
        installation process.

    -   The `update_dependencies` task no longer supports the
        `allow_newer` option, which is always True.

    -   The install order of `update_dependencies` changes slightly
        where multiple levels of upstream dependency have
        `unpackaged/pre` metadata. Where previously one package's
        `unpackaged/pre` might be installed prior to its own upstream
        dependency, `unpackaged/pre` will now always be installed
        immediately prior to the repo's package.

    -   Projects using unmanaged dependencies that reference GitHub
        subfolders will see a change in resolution behavior. Previously,
        a dependency specified like this:

            dependencies:
                - github: https://github.com/SalesforceFoundation/NPSP
                  subfolder: unpackaged/config/trial

        would always deploy from the latest commit on the default
        branch. Now, this dependency will be resolved to a GitHub commit
        just like a dependency without a subfolder, selecting the latest
        beta or production release as determined by the chosen
        resolution strategy.

    -   The `project__dependencies` section in `cumulusci.yml` no longer
        supports nested dependencies specified like this:

            dependencies:
                - namespace: "test"
                  version: "1.0"
                  dependencies:
                    - namespace: "parent"
                      version: "2.2"

        All dependencies should be listed in install order.

Changes:

-   CumulusCI now supports named services! This means you can configure
    multiple services of the same _type_ under different names. If you
    run `cci service list` you will note that your existing global
    services will have the name `global`, and any project-specific
    services will have the name `project_name`. (#2499)
    -   You must now specify both a service type and a service name when
        connecting a new service using `cci service connect`.
    -   CumulusCI has a new command: `cci service default`. This command
        sets the default service for a given type.
    -   CumulusCI has a new command: `cci service rename`. This command
        renames a given service.
    -   CumulusCI has a new command: `cci service remove`. This command
        removes a given service.
-   A validator now checks `cumulusci.yml` and shows warnings about
    values that are not expected. (#1624)
-   Added a friendly error message when a GitHub repository cannot be
    found when set as a dependency or cross-project source. (#2535)
-   Task option command line arguments can now be specified with either
    an underscore or a dash: e.g. `clean_meta_xml` can be specified as
    either `--clean_meta_xml` or `--clean-meta-xml` or
    `-o clean-meta-xml` (#2504)
-   Adjustments to existing tasks:
    -   The `update_package_xml` task now supports additional metadata
        types. (#2549)
    -   The `push_sandbox` and `push_all` tasks now use the Bulk API to
        query for subscriber orgs. (#2338)
    -   The `push_sandbox` and `push_all` tasks now default to including
        all orgs whose status is not Inactive, rather than only orgs
        with a status of Active. This means that sandboxes, scratch
        orgs, and Developer Edition orgs are included. (#2338)
    -   The `user_alias` option for the `assign_permission_sets`,
        `assign_permission_set_groups`, and
        `assign_permission_set_licenses` tasks now accepts a list of
        user aliases, and can now create permission assignments for
        multiple users with a single task invocation. (#2483)
    -   The `command` task now sets the `return_values` to a dictionary
        that contains the return code of the command that was run.
        (#2453)
-   Data generation with Snowfakery:
    -   Updated to [Snowfakery
        1.9](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.9)
        (#2538)
-   Robot Framework:
    -   The `run task` keyword now includes all task output in the robot
        log instead of printing it to stdout. (#2453)
    -   Documented the use of the options/options section of CumulusCI
        for the `robot` task. (#2536)
-   Changes for CumulusCI developers:
    -   Tasks now get access to the `--debug-mode` option and can output
        debugging information conditional on it. (#2481)
-   `cci org connect` can now connect to orgs running in an internal
    build environment with a different port. (#2501, with thanks to
    \@force2b)

Issues Closed:

-   The `load_custom_settings` task now resolves a relative
    `settings_path` correctly when used in a cross-project flow. (#2523)
-   Fixed the `min_version` option for the `push_sandbox` and `push_all`
    tasks to include the `min_version` and not only versions greater
    than it. (#2338)

## 3.32.1 (2021-04-01)

April Fool's! This is the real new release, because there was a
packaging problem with 3.32.0.

## 3.32.0 (2021-04-01)

Changes:

-   A new task, `create_network_member_groups`, creates
    NetworkMemberGroup records to grant specified Profiles or
    Permissions Sets access to an Experience Cloud site (community).
    (#2460, thanks \@ClayTomerlin)
-   A new preflight check task, `get_existing_sites`, returns a list of
    existing Experience Cloud site names in the org. (#2493)
-   It is now possible to create a flow which runs the same sub-flow
    multiple times, as long as they don't create a self-referential
    cycle. (#2494)
-   Improvements to support for releasing 2nd-generation (2GP) packages:
    -   The `github_release` task now includes the package version's
        04t id in the message of the tag that is created. (#2485)
    -   The `promote_package_version` task now defaults to promoting the
        package version corresponding to the most recent beta tag in the
        repository, if `version_id` is not specified explicitly. (#2485)
    -   Added a new flow, `release_2gp_beta`, which creates a beta
        package version of a 2GP managed package and a corresponding tag
        and release in GitHub. (#2509)
    -   Added a new flow, `release_2gp_production`, which promotes a 2gp
        managed package version to released status and creates a
        corresponding tag and release in GitHub. (#2510)
-   Data generation with Snowfakery:
    -   Updated to [Snowfakery
        1.8.1](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.8)
        (#2516)
    -   Snowfakery can now use "load files" to provide hints about how
        objects should be loaded.
    -   Values for the `bulk_mode`, `api`, and `action` parameters in
        mapping files are now case insensitive.
-   Robot Framework:
    -   Added a new keyword, `Input Form Data`, for populating form
        fields of many different types. This keyword is considered
        experimental but is intended to eventually replace
        `Populate Form`. (#2496)
    -   Added a new keyword, `Locate Element by Label`, for finding form
        inputs using their label. (#2496)
    -   Added a custom locator strategy called `label` which uses
        `Locate Element By Label` (e.g. `label:First Name`). (#2496)
    -   Added two new options to the robot task: `ordering` and
        `testlevelsplit`. These only have an effect when combined with
        the `processes` option to run tests in parallel.

Issues Closed:

-   The `cci org import` command now shows a clearer error message if
    you try to import an org that is not a locally created scratch org.
    (#2482)

## 3.31.0 (2021-03-18)

Changes:

-   It is now possible to pass the `--noancestors` flag to sfdx when
    creating a scratch org by setting `noancestors: True` in the scratch
    org config in `cumulusci.yml`. Thanks \@lionelarmanet (#2452)
-   The `robot_outputdir` return value from the `robot` task is now an
    absolute path. (#2442)
-   New tasks:
    -   `get_available_permission_sets`: retrieves the list of available
        permission sets from an org. (#2455)
    -   `promote_2gp_package`: will promote a `Package2Version` to the
        "IsReleased" state, making it available for installation in
        production orgs. (#2454)

Snowfakery
[1.7](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.7):

-   Adds support for Salesforce Person Accounts.

Issues Closed:

-   `cci project init` no longer overwrites existing files. If files
    already exist, it displays a warning and outputs the rendered file
    template. (#1325)

## 3.30.0 (2021-03-04)

Critical changes:

-   We are planning to remove functionality in CumulusCI's dependency
    management in a future release.

    -   The `update_dependencies` task will no longer support
        uninstalling managed packages in a persistent org as part of the
        dependency installation process.

    -   The `allow_newer` option on `update_dependencies` will be
        removed and always be True.

    -   The `project__dependencies` section in `cumulusci.yml` will no
        longer support nested dependencies specified like this :

            dependencies:
              - namespace: "test"
                version: "1.0"
                dependencies:
                  - namespace: "parent"
                    version: "2.2"

    All dependencies should be listed in install order.

    We recommend reformatting nested dependencies and discontinuing use
    of `allow_newer` and package uninstalls now to prepare for these
    future changes.

Changes:

-   We released a [new suite of documentation for
    CumulusCI](https://cumulusci.readthedocs.io/en/latest/).
-   CumulusCI now caches org describe data in a local database to
    provide significant performance gains, especially in
    `generate_dataset_mapping`.
-   The `cci org browser` command now has a `--path` option to open a
    specific page and a `--url-only` option to output the login URL
    without spawning a browser.
-   We improved messaging about errors while loading `cumulusci.yml`.
-   CumulusCI now uses Snowfakery 1.6 (see its [release
    notes](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.6)).

## 3.29.0 (2021-02-18)

Changes:

-   The message shown at the end of running a flow now includes the org
    name. ##2390, thanks \@Julian88Tex
-   Added new preflight check tasks:
    -   `get_existing_record_types` checks for existing Record Types.
        ##2371, thanks \@ClayTomerlin
    -   `get_assigned_permission_sets` checks the current user's
        Permission Set Assignments. ##2386
-   The `generate_package_xml` task now supports the Muting Permission
    Set metadata type. ##2382
-   The `uninstall_packaged_incremental` and `uninstall_packaged` tasks
    now support a `dry_run` option, which outputs the destructiveChanges
    package manifest to the log instead of executing it. ##2393
-   Robot Framework:
    -   The `Run Task` keyword now uses the correct project config when
        running a task from a different source project. ##2391
    -   The SalesforceLibrary has a new keyword,
        `Scroll Element Into View`, which is more reliable on Firefox
        than the keyword of the same name in SeleniumLibrary. ##2391

Issues closed:

-   Fixed very slow `cci org connect` on Safari. ##2373
-   Added a workaround for decode errors that sometimes happen while
    processing cci logs on Windows. ##2392
-   If there's an error while doing JWT authentication to an org, we
    now log the full response from the server. ##2384
-   Robot Framework: Improved stability of the
    `ObjectManagerPageObject`. ##2391

## 3.28.0 (2021-02-04)

Changes:

-   Added a new task, `composite_request`, for calling the Composite
    REST Resource. ##2341
-   The `create_package_version` task has a new option, `version_base`,
    which can be used to increment the package version from a different
    base version instead of from the highest existing version of the 2gp
    package. The `build_feature_test_package` flow now uses this option
    to create a package version with the minor version incremented from
    the most recent 1gp release published to github. ##2357
-   The `create_package_version` task now supports setting a
    post-install script and uninstall script when creating a managed
    package version, by setting the `post_install_script` and
    `uninstall_script` options. By default, these options will use the
    values of `install_class` and `uninstall_class` from the `package`
    section of `cumulusci.yml`. ##2366
-   Updated to [Snowfakery
    1.5](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.5).
-   Robot Framework:
    -   The `Click related list button` keyword has been modified to be
        more liberal in the types of DOM elements it will click on.
        Prior to this change it only clicked on anchor elements, but now
        also works for related list buttons that use an actual button
        element. ##2356
    -   The `Click modal button` keyword now attempts to find the given
        button anywhere on the modal rather than only inside a
        `force-form-footer` element. ##2356

Issues closed:

-   Robot Framework:
    -   Custom locators can now be used with keywords that expect no
        element to be found (such as `Page should not contain`). This
        previously resulted in an error. ##2346
    -   Fixed an error when setting the `tagstatexclude` option for the
        `robot` task. ##2365
-   Fixed a possible error when running CumulusCI flows embedded in a
    multi-threaded context. ##2347

## 3.27.0 (2021-01-21)

Changes:

-   Snowfakery 1.4 which includes min, max, round functions. PR ##2335

-   The `ensure_record_types` task has a new option, `force_create`,
    which will create the Record Type even if other Record Types already
    exist on the object. (Thanks to \@bethbrains) PR ##2323

-   Allow num_records and num_records_tablename to be omitted when using
    the task generate_and_load_from_yaml. PR ##2322

-   Added a new Metadata ETL task, add_fields_to_field_set which allows
    adding fields to existing field sets. (Thanks to \@bethbrains) PR
    ##2334

-   org_settings now accepts a dict option called settings in addition
    to (or instead of) the existing definition_file option. (Thanks to
    \@bethbrains) PR ##2337

-   New Robot Keywords for Performance Testing: ##2291

    > -   Set Test Elapsed Time: This keyword captures a computed rather
    >     than measured elapsed time for performance tests.
    > -   Start Perf Time, End Perf Time: start a timer and then store
    >     the result.
    > -   Set Test Metric: store any test metric, not just elapsed time.

-   CumulusCI now reports how long it took for flows to run. ##2249

Issues Closed:

-   Fixed an error that could occur while cleaning cache directories.
-   Fixed potential bugs in the Push Upgrade tasks.
-   CumulusCI displays more user friendly error message when
    encountering parsing errors in cumulusci.yml. ##2311
-   We fixed an issue causing the extract_dataset task to fail in some
    circumstances when both an anchor date and Record Types were used.
    ##2300
-   Handle a possible gack while collecting info about installed
    packages ##2299

## 3.26.0 (2021-01-08)

Changes:

-   CumulusCI now reports how long it took for flows to run.
-   Flows `ci_feature` and `ci_feature_beta_deps` now only run the
    `github_automerge_feature` task if the branch begins with the
    configured feature branch prefix.
-   Running the `deploy` task with the `path` option set to a path that
    doesn't exist will log a warning instead of raising an error.
-   When the `ci_feature_2gp` and `qa_org_2gp` flows install
    dependencies, the latest beta version will be used when available.
-   CumulusCI can now resolve dependencies using second-generation
    packages (2GPs) for upstream projects. When a
    [](ci-feature-2gp) or [](qa-org-2gp) flow runs
    on a release branch (starting with `prefix/NNN`, where `prefix` is
    the feature branch prefix and `NNN` is an integer), CumulusCI will
    look for a matching release branch in each upstream dependency and
    use a 2GP package build on that release branch, if present, falling
    back to a 1GP beta release if not present.

Issues Closed:

-   Fixed the `org_settings` task to handle nested structures in org
    settings.
-   Fixed a bug where cci task run could fail without a helpful error if
    run outside of a cci project folder.
-   Fixed an issue that caused CumulusCI to generate invalid
    `package.xml` entries for Metadata API-format projects that include
    `__mocks__` or `__tests__` LWC directories.
-   Fixed the `update_dependencies` task to handle automatic injection
    of namespace prefixes when deploying an unpackaged dependency. The
    fix for the same issue in CumulusCI 3.25.0 was incomplete.
-   Fixed an issue where an unquoted `anchor_date` in bulk data mapping
    failed validation.
-   CumulusCI now handles an error that can occur while collecting info
    about installed packages
-   Fixed an issue causing the `extract_dataset` task to fail in some
    circumstances when both an anchor date and Record Types were used.
-   Fixed an issue where the deprecated syntax for record types was not
    working.

## 3.25.0 (2020-12-10)

Changes:

-   New tasks:
    -   `assign_permission_set_groups` assigns Permission Set Groups to
        a user if not already assigned.
    -   `assign_permission_set_licenses` assigns Permission Set Licenses
        to a user if not already assigned.
-   New preflight checks for use with MetaDeploy install plans:
    -   `check_enhanced_notes_enabled` checks if Enhanced Notes are
        enabled
    -   `check_my_domain_active` checks if My Domain is active
-   The `github_copy_subtree` task has a new option, `renames`, which
    allows mapping between local and target path names when publishing
    to support renaming a file or directory from the source repository
    in the target repository.
-   The `ensure_record_types` task has a new option,
    `record_type_description`, which can be used to set the description
    of the new record type if it is created.
-   Robot Framework:
    -   New keyword `Field value should be`
    -   New keyword `Modal should show edit error for fields` to check
        form field error notifications in Spring '21
    -   Adjusted `Get field value` and `Select dropdown value` fields to
        work in Spring '21
-   Command line improvements:
    -   The various `cci org` commands now accept an org name with the
        `--org` option, for better consistency with other commands.
        Specifying an org name without `--org` also still works.
    -   Running `cci org default` without specifying an org name will
        now display the current default org.
-   Org configs now have properties
    `org_config.is_multiple_currencies_enabled` and
    `org_config.is_advanced_currency_management_enabled` which can be
    used to check if these features are enabled.
-   The `MergeBranchOld` task, which was previously deprecated, has now
    been removed.

Issues closed:

-   Fixed the `update_dependencies` task to handle automatic injection
    of namespace prefixes when deploying an unpackaged dependency.
-   Fixed the `query` task, which was completely broken.
-   Fixed the `connected_app` task to pass the correct username to sfdx.
    Thanks \@atrancadoris
-   Fixed the display of task options with an underscore in
    `cci task info` output.
-   Fixed a confusing warning when creating record types using
    Snowfakery. (#2093)
-   Improved handling of errors while deleting a scratch org.

## 3.24.1 (2020-12-01)

Issues Closed:

-   Fixed a regression that prevented running unmanaged flows on
    persistent orgs, due to the use of the `include_beta` option while
    installing dependencies, which is not allowed for persistent orgs.
    We changed the `update_dependencies` task to ignore the option and
    log a warning when running against a persistent org, instead of
    erroring.

## 3.24.0 (2020-11-30)

Critical Changes:

-   The flows `dev_org`, `dev_org_namespaced`, `qa_org`, `ci_feature`,
    and `install_beta` now run the `update_dependencies` task with the
    `include_beta` option enabled, so dependencies will be installed
    using the most recent beta release instead of the most recent final
    release. The `beta_dependencies` flow is no longer used and is
    considered deprecated.
-   The flows `ci_feature_beta_deps` and `dev_org_beta_deps` are now
    deprecated and should be replaced by their default equivalents
    above.
-   The `ci_feature_2gp` flow has been changed to use `config_apextest`
    instead of `config_managed` to avoid configuration steps that are
    unnecessary for running Apex tests. This means that in order for
    `ci_feature_2gp` to work, `config_apextest` must be set up to work
    in both managed and unmanaged contexts.
-   When connecting GitHub using `cci service connect github`, we now
    prompt for a personal access token instead of a password. (GitHub
    has removed support for accessing the API using a password as of
    November 2020.) If you already had a token stored in the `password`
    field, it will be transparently migrated to `token`. If you were
    specifying `--password` on the command line when running this
    command, you need to switch to `--token` instead.
-   Removed the old `cumulusci.tasks.command.SalesforceBrowserTest` task
    class which has not been used for some time.

Changes:

-   Added a standard `qa_org_2gp` flow, which can be used to set up a QA
    org using a 2nd-generation package version that was previously
    created using the `build_feature_test_package` flow. This flow makes
    use of the `config_qa` flow, which means that `config_qa` must be
    set up to work in both managed and unmanaged contexts. This flow is
    considered experimental and may change at any time.
-   The `batch_apex_wait` task can now wait for Queueable Apex jobs in
    addition to batch Apex.
-   The `custom_settings_value_wait` task now waits if the expected
    Custom Settings record does not yet exist, and does case insensitive
    comparison of field names.
-   Preflight checks:
    -   Added a task, `check_sobject_permissions`, to validate sObject
        permissions.
    -   Added a task, `check_advanced_currency_management`, to determine
        whether or not Advanced Currency Management is active.
-   Robot Framework:
    -   In the Robot Framework Salesforce resource, the
        `Open Test Browser` keyword now accepts an optional `useralias`
        argument which can be used to open a browser as a different
        user. The user must already have been created or authenticated
        using the Salesforce CLI.
-   Updated to [Snowfakery
    1.3](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.3).

Issues Closed:

-   Improved error handling of REST API responses to confirm they are
    JSON.
-   Fixed error handling in the `load_dataset` task in Windows.
-   Fixed a bug where pressing `Ctrl+C` while running `cci org connect`
    in Windows did not exit. (#2027)
-   Fixed a bug where deploying an LWC component bundle using the
    `deploy` task did not include files in subfolders.
-   Fixed the `deploy` task so that deploying an empty metadata
    directory does not error.
-   Fixed a bug where the `namespace_inject` option was not included
    when freezing deploy steps for MetaDeploy, causing namespace
    injection to not work when running the plan in MetaDeploy.
-   Fixed a bug where running the `robot` task as a cross-project task
    could not load Robot Framework libraries from the other project.

## 3.23.0 (2020-11-12)

Changes:

-   CumulusCI now accepts a normalized task option syntax in the form
    of: `--opt-name value`. This can be used in place of the old task
    option syntax: `-o opt-name value`.
-   Tasks which perform namespace injection can now automatically
    determine whether they are running in the context of a managed
    installation or a namespaced scratch org. This means that in many
    cases it is no longer necessary to explicitly specify options like
    `managed`/`unmanaged`/`namespaced`/`namespaced_org`/`namespace_inject`,
    or to use a separate flow for namespaced scratch orgs.
-   The `deploy_unmanaged` flow now deploys sfdx-formatted metadata
    using the Metadata API rather than the sfdx `force:source:push`
    command. This avoids an issue where sfdx could show an error about
    the pushed components conflicting with other changes that already
    happened in the org. It also improves consistency between how
    metadata is deployed to a scratch org and how it is deployed to a
    packaging org.
-   Removed the `namespaced_org` option for the `update_dependencies`
    task, which was not functional.
-   We added support for including SOQL where-clauses `Salesforce Query`
    Robot keyword via the `where` keyword argument.
-   The `create_package_version` task can accept a
    `static_resource_path` option.
-   The FindReplace task now has a `replace_env` option which, if true,
    will interpret the `replace` option as the name of an environment
    variable whose value should be used for the replacement.
-   We added a new command, `cci project doc`, which will document
    project-specific tasks to a reStructuredText file.

Issues closed:

-   An error that occurred when building a second-generation package
    using a cross-project task has been fixed.
-   The `github_package_data` task will now work for projects using API
    versions prior to 44.0.
-   Fixed a bug where namespace injection of the `%%%NAMESPACED_ORG%%%`
    token with the `namespaced_org` option enabled did not actually add
    the namespace prefix unless the `managed` option was also enabled.
-   We fixed an issue that resulted in the `batch_size`
    option in a data mapping file being ignored.

## 3.22.0 (2020-10-29)

Changes:

-   We added support for using Robot keywords from other projects that
    are included as `sources`.
    -   The `suites` option of the robot task can now take a list of
        suite paths. Paths can include a prefix representing a remote
        repository as defined by the `sources` configuration option (eg:
        `-o suites npsp:robot/Cumulus/tests/api`)
    -   The robot task has a new `sources` option to work in conjunction
        with the global `sources` option to allow the use of keywords
        and tests from other repositories.
    -   When running the `robot` task, the folder containing downloaded
        repositories via the `sources` option are added to `PYTHONPATH`
        so that robot tests can find library and resource files in those
        repositories
-   Bulk Data tasks now support adding or removing a namespace from a
    mapping file to match the target org.
-   We improved how we parse Boolean values in Bulk Data tasks and in
    command line options. True can be represented as "yes", "y",
    "true", "on", or "1", with any capitalization, and False as
    "no", "n", "false", "off", "0". None as a synonym for
    False is deprecated.
-   We added support for including managed package release details in
    automatically generated release notes.
-   We added a task, `assign_permission_sets`, to assign Permission Sets
    to a user.
-   We updated the default API version for new projects to 50.0.
-   The `build_feature_test_package` flow now creates a 2GP package
    version with the "skip validation" option turned on.
-   `github_automerge_main` now only merges to the lowest numbered
    release branch when multiple are detected.

Issues closed:

-   We fixed an issue with relative imports within parallel Robot test
    runs by adding the repo root to PYTHONPATH.
-   We fixed an issue with generating `package.xml` manifests for
    directories that contain reports in folders that aren't owned by
    the project.
-   We now handle an exception that may occur while creating merge
    conflict PRs during parent-child automerges.

## 3.21.1 (2020-10-19)

Issues closed: - Added a workaround for a slow query error while looking
up installed packages in Winter '21 orgs.

## 3.21.0 (2020-10-15)

Changes:

-   The `update_admin_profile` task now accepts the `api_names` option
    to target extra Profiles, even when using a custom `package.xml`.
-   The `github_automerge_main` task can now be used on source branches
    other than the default branch to merge them into branches starting
    with the `branch_prefix` option, as long as the source branch does
    not also start with `branch_prefix`.
-   Added preflight check tasks to validate org settings
    (`check_org_settings_value`) and to check that Chatter is enabled
    (`check_chatter_enabled`). These are intended for use with
    MetaDeploy install plans.
-   Updated to [Snowfakery
    1.2](https://github.com/SFDO-Tooling/Snowfakery/releases/tag/v1.2).

Issues closed:

-   Fixed an issue in the `load_dataset` task which left out
    non-Person-Account Contacts if the dataset was extracted using the
    REST API.

## 3.20.1 (2020-10-05)

Issues closed:

-   Fixed a bug introduced in CumulusCI 3.20.0 in which the
    `upload_beta` and `upload_production` tasks could hit a connection
    error if uploading the package took over 10 minutes.
-   We corrected edge cases in how we processed Boolean options for the
    `custom_settings_wait`, `exec_anon`, and `uninstall_post` tasks.
    (Thanks to \@davidjray)

## 3.20.0 (2020-09-30)

Critical Changes:

-   We've removed the standard flow: `retrieve_scratch`. The
    recommended way for retrieving source-tracked changes is to use the
    `retrieve_changes` task.
-   Changes to automatic merging:
    -   The `github_master_to_feature` task has been renamed to
        `github_automerge_main`. It still merges changes from the
        default branch to feature branches. In the case of an orphaned
        feature branch (a branch with a name like
        `feature/parent__child` where `feature/parent` does not exist as
        its own branch), the `github_automerge_main` branch will no
        longer merge to the orphaned branch.
    -   The `github_parent_to_children` task has been renamed to
        `github_automerge_feature`. It still merges changes from feature
        branches to their children (e.g. `feature/parent` would be
        merged to `feature/parent__child`). It is now possible to use
        multiple double-underscores to create more deeply nested
        children, and the task will only merge to the next level (e.g.
        `feature/parent` would merge to `feature/parent__child` which
        would merge to `feature/parent__child__grandchild`).
    -   The `children_only` option for these tasks has been removed. The
        strategy for picking which branches to target for merging is now
        determined by the `source_branch`.

Tasks, Flows, and Automation:

-   `cci flow list` now displays flows in different groups that are
    organized by functional area. (This is similar to how
    `cci task list` currently works).
-   The `insert_record` task can now be used against the Tooling API. We
    clarified that this task can accept a dict of values if configured
    in `cumulusci.yml`.
-   Added support for newer metadata types to the `update_package_xml`
    task.
-   Previously, large data loads and extracts would use enormous amounts
    of memory. Now they should use roughly constant amounts of memory.
-   Adjusted tasks: `install_managed` and `update_dependencies` can now
    install packages from just a version id (04t).
-   Added support for creating 2GP packages (experimental)
    -   New task: `github_package_data` gets a package version id from a
        GitHub commit status. It is intended primarily for use as part
        of the `ci_feature_2gp` flow. Implementation details can be
        found in the
        [features](https://cumulusci.readthedocs.io/en/latest/features.html)
        section of the documentation.
    -   New task: `create_package_version` - Builds a 2gp package
        (managed or unlocked) via a Dev Hub org. Includes some automated
        handling of dependencies:
    -   New Flow: `build_feature_test_package` - Runs the
        `create_package_version task`, and in the context of MetaCI it
        will set a commit status with the package version id.
    -   New Flow: `ci_feature_2gp` - Retrieves the package version from
        the commit status set by `build_feature_test_package`, installs
        dependencies and the package itself in a scratch org, and runs
        Apex tests. (There is another new task, `github_package_data`,
        which is used by this flow.)

User Experience:

-   Improved error messaging when encountering errors during bulk data
    mapping validation.

Issues Closed:

-   Fixed a very rare bug that caused CumulusCI to fail to retrieve
    installed packages from an org when running package-related tasks or
    evaluating `when` conditional expressions.
-   Fixed `UnicodeDecodeError` while opening config files on Windows.
-   Fixed a bug in `cumulusci.core.sfdx.sfdx` when capture_output is
    False

## 3.19.1 (2020-09-18)

Issues closed:

-   Fixed an issue (#2032) where REST API data loads incorrectly handled
    Boolean values.

## 3.19.0 (2020-09-17)

Changes:

-   Tasks and automation:
    -   CumulusCI now supports using the REST Collections API in data
        load, extract, and delete operations. By default, CumulusCI will
        select an API for you based on data volume (\<2000 records uses
        the REST API, \>=2000 uses Bulk); a desired API can be
        configured via the mapping file.
    -   Removed the namespace_tokenize option from tasks that deploy
        metadata, and removed the namespace_inject option from tasks
        that retrieve metadata, because it's unclear when they would be
        useful.
    -   The task create_permission_set allows for creating and assigning
        a Permission Set that enables specific User Permissions. (Note:
        other types of permissions are not yet supported).
    -   The task create_bulk_data_permission_set creates a Permission
        Set with the Hard Delete and Set Audit Fields permissions for
        use with data load operations. The org permission to allow Set
        Audit Fields must be turned on.
    -   CumulusCI's load_dataset and extract_dataset tasks now support
        relative dates. To take advantage of relative dates, include the
        anchor_date key (with a date in YYYY-MM-DD format) in each
        mapping step you wish to relativize. On extract, dates will be
        modified to be the same interval from the anchor date as they
        are from the current date; on load, dates will be modified to be
        the same interval from today's date as they are from their
        anchor. Both date and date-time fields are supported.
-   Other:
    -   The oid_as_pk key is no longer supported in bulk data mappings.
        (This key was already deprecated). Select object Id mode by
        including the Id field in mappings.

Issues closed:

> -   Fixed an issue (#2001) that caused CumulusCI to extract invalid
>     data sets when using after: steps with autoincrement primary keys.
> -   Fixed an issue where the retrieve_changes task did not actually
>     retrieve folders.
> -   Fixed a bug in the metadeploy-publish task where labels starting
>     with "Install " were not extracted for localization.
> -   Fixed a bug that prevented using JWT auth with sandboxes if the
>     sandbox's instance_url did not include an instance name.
> -   Fixed a bug where `cci project init` generated an invalid mapping
>     for bulk data tasks.

## 3.18.0 (2020-09-03)

Changes:

-   Tasks and automation:
    -   CumulusCI now tries 10 times (instead of 5) to install managed
        package versions, which helps ameliorate timeouts when new
        versions are released.
    -   We added support for CSV files to the `push_list` task.
    -   We added a `ref` option to `github_copy_subtree` to allow
        publishing a git reference (commit hash, branch, or tag).
    -   Changed the `disable_tdtm_trigger_handlers`
        (SetTDTMHandlerStatus) task so that trigger handler state is
        remembered in the cache directory instead of `REPO_ROOT`.
-   User experience:
    -   The `cci error info` command now defaults to showing the entire
        traceback when it is more than 30 lines.
-   Robot Framework:
    -   The following robot keywords have been updated to work with
        Winter '21:
        -   `Load related list`
        -   `Click related list button`
        -   `Click related item link`
        -   `Click related item popup link`
        -   `Go to object home`
        -   `Go to object list`
        -   `Go to record home`
        -   `Populate lookup field`
    -   The keyword `Load related list` has been rewritten to be
        slightly more efficient. It also has a new parameter `tries`
        which can be used if the target is more than 1000 pixels below
        the bottom of the window.

Issues Closed:

-   Fixed a bug where `cci error gist` could throw a UnicodeDecodeError
    on Windows (fixes ##1977)
-   Fixed a bug where `cci org list` could throw a TypeError when run
    outside a project directory (fixes ##1998)
-   The `metadeploy_publish` task can now update translations for
    language codes with more than 2 letters.
-   Fixed a bug where the `extract_dataset` task could fail with a
    UnicodeEnodeError on Windows.
-   `update_dependencies` deduplicates its package install list, making
    it possible to handle situations where the same beta package is
    reached by two dependency paths.

## 3.17.0 (2020-08-20)

Changes:

-   Tasks and automation:
    -   We added the `upload_user_profile_photo` and
        `upload_default_user_profile_photo` tasks, which allow for
        setting Users' profile photos from images stored in the
        repository. (Thanks to \@spelak-salesforce).
    -   We added the property `is_person_accounts_enabled` to the
        `org_config` object, which is available in `when` clauses.
        (Thanks to \@spelak-salesforce).
-   Policies and inclusive language:
    -   We added information about Salesforce's Open Source Community
        Code of Conduct and Security policies.
    -   We updated documentation to more consistently refer to the
        "main" branch, reflecting CumulusCI's support for per-project
        specification of main branches other than `master`.
-   User experience:
    -   We modified how we handle situations where the default org is
        not valid for better user experience.
    -   We catch a common mistake in entering command-line options
        (`-org` instead of `--org`, as well as incorrectly-formatted
        flow options) and show a clearer error.
    -   We now capture and display the `InstanceName` of orgs in
        `cci org list`'s output.
-   Robot Framework:
    -   We now cleanly fall back to the latest available API version for
        Robot locators if the newest API version does not have an
        available locator file. This change helps support Robot testing
        on the latest prerelease editions of Salesforce.
    -   We included some updates to locators for API version 50.0.
-   Other:
    -   We added a new environment variable, `SFDX_SIGNUP_INSTANCE`, and
        an `instance` key in org definitions, to specify a preferred
        instance routing. NOTE: this functionality requires Dev Hub
        permissions that are not Generally Available.

Issues closed:

-   Fixed a bug which prevented package install links from getting added
    to release notes.
-   Fixed a bug (#1914) which caused errors when customizing some Flow
    steps with decimal step numbers.
-   Fixed a bug making it difficult to troubleshoot issues with
    Snowfakery and CumulusCI on Windows.
-   Fixed a bug in `update_admin_profile` that resulted in errors when
    attempting to manage Record Types across multiple objects.

## 3.16.0 (2020-08-06)

Changes:

-   Project initialization:

    -   When starting a new CumulusCI project, the `cci project init`
        command now uses the current git branch as the project's
        default branch.
    -   API version 49.0 is now set as the default for new projects.

-   Bulk data tasks:

    -   Added a task called `delete_data` for deleting all data from
        specified objects. This was previously available but required
        manually adding it to `cumulusci.yml`
    -   The `load_dataset`, `extract_dataset`, and `delete_data` tasks
        now support automatic namespace injection. When object and field
        names are specified without namespaces, but the target org only
        has them with a namespace prefix attached, CumulusCI
        automatically adds the namespace prefix. This makes it easier
        for projects to use a single mapping file for unmanaged orgs,
        namespaced scratch org, and managed orgs.

    This behavior is on by default, but may be disabled by setting the
    `inject_namespaces` option to False. This feature is believed to be
    backwards-compatible; however, projects that subclass built-in data
    loading classes, or which use data loading tasks in very unusual
    ways, might be impacted.

    -   The `load_dataset` and `extract_dataset` tasks have a new
        option, `drop_missing_schema`. When enabled, this option causes
        CumulusCI to silently ignore elements in a dataset or mapping
        that are not present in the target org. This option is useful
        when building datasets that support additional, optional managed
        packages or features, which may or may not be installed.
    -   The `extract_dataset` and `load_dataset` tasks now support
        Person Accounts. These will be handled automatically as long as
        both Account and Contact are in the mapping file. Additional
        fields should be added to the Account mapping rather than
        Contact. Thanks \@spelak-salesforce
    -   The `generate_dataset_mapping` task generates mappings in line
        with the latest revisions of load/extract functionality: fields
        are specified as a list, the `table` key is omitted, and
        namespaces are stripped.
    -   The `generate_dataset_mapping` has improved logic for resolving
        reference cycles between objects. If one of the lookup fields is
        nillable, the object with that field will be listed first in the
        generated mapping file.
    -   The `generate_and_load_from_yaml` task has a new option,
        `working_directory`, which can be used to keep temporary files
        for debugging. The `debug_dir` option has been removed.

-   Robot Framework:

    -   The `robot` task has a new option, `processes`. If the value is
        \> 1, tests will be run in parallel in the given number of
        processes, using [pabot](https://pabot.org/). Note: It's still
        up to the test author to make sure the tests won't conflict
        with each other when running in parallel. This feature is
        considered experimental.
    -   Added an `ObjectManager` page object for interacting with the
        Object Manager in Setup. Thanks to \@rjanjanam
    -   [RequestsLibrary](https://github.com/MarketSquare/robotframework-requests)
        is now included as a way to test REST APIs from Robot Framework.

-   Metadata ETL:

    -   Added a new task, `set_field_help_text`, which can be used to
        update Help Text values on existing fields.
    -   Added a new task, `update_metadata_first_child_text`, which can
        be used to update a single value in existing metadata. Thanks
        \@spelak-salesforce
    -   Added a new task, `assign_compact_layout`, which can update a
        compact layout assignment in existing object metadata. Thanks
        \@spelak-salesforce

-   Added a new task, `github_copy_subtree`, to allow publishing
    selected files or folders to another repository after a release.
    This allows publishing a subset of your project's code from a
    private repository to a public one, for example.

-   The `create_community` task has a new option, `skip_existing`. When
    True, the task will not error if a community with the specified name
    already exists.

-   The `release_beta` and `release_production` flows now generate a
    section in the release notes on GitHub including package install
    links.

-   Task options can now use `$project_config` substitutions in any
    position, not just at the start of the value.

Issues closed:

-   Fixed a bug where changes to global orgs would be saved as
    project-specific orgs.
-   Fixed a bug where `cumulusci.yml` could fail to parse if certain
    options were specified in `cci project init` (#1780)
-   The `install_managed` task now recognizes an additional error
    message that indicates a package version has not yet finished
    propagating, and performs retries appropriately.
-   Fixed a bug in the logic to prevent installing beta packages in
    non-scratch orgs.
-   Fixed a bug where the `list_changes`, `retrieve_changes`, and
    `snapshot_changes` tasks could error while trying to reset sfdx
    source tracking.
-   Fixed a bug where the `push_failure_report` task could be missing
    some failed orgs if there were more than 200 errors.
-   Fixed a bug where the `github_release_notes` task could list a
    change note under a wrong subheading from a different section.
-   Fixed freezing of command tasks for MetaDeploy.

Internal changes (these should not affect you unless you're interacting
with CumulusCI at the Python level):

> -   Standardized naming of different levels of configuration:
>     -   `BaseGlobalConfig` is now `UniversalConfig`.
>     -   `BaseGlobalConfig.config_global_local_path` is now
>         `UniversalConfig.config_global_path`
>     -   `BaseGlobalConfig.config_global_path` is now
>         `UniversalConfig.config_universal_path`
>     -   `BaseProjectConfig.global_config_obj` is now
>         `universal_config_obj`
>     -   `BaseProjectConfig.config_global` is now `config_universal`
>     -   `BaseProjectConfig.config_global_local` is now `config_global`
>     -   `EncryptedFileProjectKeychain.config_local_dir` is now
>         `global_config_dir`
>     -   `BaseCumulusCI.global_config_class` is now
>         `universal_config_class`
>     -   `BaseCumulusCI.global_config` is now `universal_config`
> -   Added `UniversalConfig.cumulusci_config_dir` as a central way to
>     get the path for storing configuration.
>     `UniversalConfig.config_local_dir` was removed.
> -   OrgConfigs now keep track of which keychain they were loaded from,
>     and have a new `save` method which is the preferred
>     API for persisting updates to the config.

## 3.15.0 (2020-07-09)

Changes:

-   The `run_tests` task now defaults to only logging tests that failed.
    Set the `verbose` option to True to see all results including tests
    that passed.
-   The `update_dependencies` task now supports an `ignore_dependencies`
    option, which prevents CumulusCI from processing a specific
    dependency (whether direct or transitive). This feature may be
    useful in installers for packages that extend other packages if the
    installer is not meant to include the base package.
-   Improvements to the mapping file for the `extract_dataset` and
    `load_dataset` tasks:
    -   Fields can now be specified as a simple list of Salesforce API
        names, instead of a mapping. CumulusCI will infer the database
        column names.
    -   Mappings may omit the `table` key and CumulusCI will use the
        object name.
    -   The tasks will check and show an error if mappings do not use a
        consistent object Id mode.
    -   Mappings can now include junction objects with no additional
        fields.
-   The `generate_dataset_mapping` task now has an `include` option to
    specify additional objects to include in the mapping if they aren't
    found by the default heuristics.
-   Added additional tasks intended for use as preflight checks for
    MetaDeploy install plans:
    -   `check_sobjects_enabled` returns a set of available SObject
        names.
    -   `check_org_wide_defaults` returns a boolean indicating whether
        Organization-Wide Defaults match the specified values.
-   The `update_package_xml` task now supports the MessageChannel
    metadata type.
-   Adjusted the default rules for the `robot_lint` task.
-   CumulusCI can be configured to always show Python stack traces in
    the case of an error by setting the `show_stacktraces` option to
    True in the `cli` section of `~/.cumulusci/cumulusci.yml`.
-   The prompt provided by `cci org shell` now has access to the Tooling
    API through the keyword `tooling`.
-   When using the JWT OAuth2 flow, CumulusCI can be configured to use
    alternate Salesforce login URLs by setting the SF_PROD_LOGIN_URL and
    SF_SANDBOX_LOGIN_URL environment variables.

Issues closed:

-   Fixed a UnicodeDecodeError that could happen while using the
    `extract_dataset` task on Windows. (#1838)
-   Fixed support for the CustomHelpMenuSection metadata type in the
    `update_package_xml` task. (#1832)
-   Deleting a scratch org now clears its domain from showing in `cci org list`.
-   If you try to use `cci org connect` with a login URL containing
    `lightning.force.com`, CumulusCI will explain that you should use
    the `.my.salesforce.com` domain instead.
-   Fixed an issue with deriving the Lightning domain from the instance
    URL for some orgs.

## 3.14.0 (2020-06-18)

Changes:

-   Added a generic `dx` task which makes it easy to run Salesforce CLI
    commands against orgs in CumulusCI's keychain. Use the `command`
    option to specify the sfdx command.
-   Tasks which do namespace injection now support the
    `%%%NAMESPACE_DOT%%%` injection token, which can be used to support
    references to packaged Apex classes and Record Types. The token is
    replaced with `ns.` rather than `ns__` (for namespace `ns`).
-   Updated to Robot Framework 3.2.1. Robot Framework has a new parser
    with a few backwards incompatible changes. For details see the
    [release
    notes](https://github.com/robotframework/robotframework/blob/master/doc/releasenotes/rf-3.2.rst).
-   The `run_tests` task now gracefully handles the
    `required_org_code_coverage_percent` option as a string or an
    integer.
-   CumulusCI now logs a success message when a flow finishes running.

Issues closed:

-   Fixed a regression introduced in CumulusCI 3.13.0 where connections
    to a scratch org could fail with a ReadTimeout or other connection
    error if more than 10 minutes elapsed since a prior task that
    interacted with the org. This is similar to the fix from 3.13.2, but
    for scratch orgs.
-   Show a clearer error message if dependencies are configured in an
    unrecognized format.

## 3.13.2 (2020-06-10)

Issues closed:

-   Fixed a regression introduced in CumulusCI 3.13.0 where connections
    to Salesforce could fail with a ReadTimeout or other connection
    error if more than 10 minutes elapsed since a prior task that
    interacted with the org.

## 3.13.1 (2020-06-09)

Issues closed:

-   Fixed a bug with "after:" steps in the [](load-dataset)
    task.
-   Fixed a bug with record types in the [](extract-dataset)
    task.

## 3.13.0 (2020-06-04)

Changes:

-   A new Metadata ETL task, `add_picklist_entries`, safely adds
    picklist values to an existing custom field.
-   Added the `cci org prune` command to automatically remove all
    expired scratch orgs from the CumulusCI keychain.
-   Improvements to the `cci org shell` command:
    -   Better inline help
    -   New `query` and `describe` functions
-   Scratch org creation will now wait up to 120 minutes for the org to
    be created to avoid timeouts with more complex org shapes.
-   The `generate_data_dictionary` task now has more features for
    complex projects. By default, the task will walk through all project
    dependencies and include them in the generated data dictionaries.
    Other non-dependency projects can be included with the
    `additional_dependencies` option. The output format has been
    extensively improved.
-   The `run_tests` task supports a new option,
    `required_org_code_coverage_percent`. If set, the task will fail if
    aggregate code coverage in the org is less than the configured
    value. Code coverage verification is available only in unmanaged
    builds.
-   The `install_managed` and `update_dependencies` tasks now accept a
    `security_type` option to specify whether the package should be
    installed for all users or for admins only.
-   `when` expressions can now use the `has_minimum_package_version`
    method to check if a package is installed with a sufficient version.
    For example:
    `when: org_config.has_minimum_package_version("namespace", "1.0")`
-   Robot Framework:
    -   Added a new keyword in the modal page objects,
        `Select dropdown value`. This keyword will be available whenever
        you use the `Wait for modal` keyword to pull in a modal page
        object.

Issues closed:

> -   Limited the variables available in global scope for the
>     `cci shell` command.
> -   Tasks based on `BaseSalesforceApiTask` which use the Bulk API now
>     default to using the project's API version rather than 40.0.
> -   Bulk data tasks:
>     -   The `extract_dataset` task no longer converts to snake_case
>         when picking a name for lookup columns.
>     -   Improved error message when trying to use the `load_dataset`
>         command with an incorrect record type.
>     -   Fixed a bug with the `generate_mapping_file` option.

## 3.12.2 (2020-05-07)

Changes:

-   Added a task, `set_duplicate_rule_status`, which allows selective
    activation and deactivation of Duplicate Rules.
-   The `create_community` task now retries multiple times if there's
    an error.
-   The `generate_data_dictionary` task now supports multi-select
    picklist fields and will indicate the related object for lookup
    fields.
-   The `update_package_xml` task now supports the `NavigationMenu`
    metadata type.

Issues closed:

-   In the Salesforce library for Robot Framework, fixed locators for
    the actions ribbon and app launcher button in Summer '20.
-   Fixed the `load_dataset` task so that steps which don't explicitly
    specify a `bulk_mode` will inherit the option specified at the task
    level.
-   Fixed error handling if an exception occurs within one of the `cci error`
    commands.
-   Fixed error handling if the Metadata API returns a response that is
    marked as done but also contains an `errorMessage`.

## 3.12.1 (2020-04-27)

Fixed a problem building the Homebrew formula for installing CumulusCI
3.12.0.

## 3.12.0 (2020-04-27)

Changes:

-   We've removed the prompt that users see when trying to use a
    scratch org that has expired, and now automatically recreate the
    scratch org.
-   The `load_dataset` task now automatically avoids creating Bulk API
    batches larger than the 10 million character limit.
-   Robot Framework:
    -   When opening an org in the browser, the Salesforce library now
        attempts to detect if the org was created using the Classic UI
        and automatically switch to Lightning Experience.
    -   The Salesforce library now has preliminary support for Summer
        '20 preview orgs.
-   CumulusCI now directs `simple-salesforce` to return results as
    normal Python dicts instead of OrderedDicts. This should have
    minimal impact since normal dicts are ordered in the versions of
    Python that CumulusCI supports, but we mention it for the sake of
    completeness.

Issues closed:

-   Fixed an issue where non-ASCII output caused an error when trying to
    write to the CumulusCI log in Windows. (#1619)

## 3.11.0 (2020-04-17)

Changes:

-   CumulusCI now includes
    [Snowfakery](https://pypi.org/project/snowfakery/), a tool for
    generating fake data. It can be used to generate and load data into
    an org via the new `generate_and_load_from_yaml` task.
-   Added two new preflight check tasks for use in MetaDeploy:
    `get_available_licenses` and
    `get_available_permission_set_licenses`. These tasks make available
    lists of the License Definition Keys for the org's licenses or
    PSLs.
-   The `get_installed_packages` task now logs its result.
-   Robot Framework: Added two new keywords (`Get Fake Data` and
    `Set Faker Locale`) and a global robot variable (`${faker}`) which
    can be used to generate fake data using the
    [Faker](https://pypi.org/project/Faker/) library.

Issues closed:

-   Fixed an error when loading a dependency whose `cumulusci.yml`
    contains non-breaking spaces.
-   Fixed a PermissionError when running multiple concurrent CumulusCI
    commands in Windows. (#1477)
-   Show a more helpful error message if a keychain entry can't be
    loaded due to a change in the encryption key.
-   Fixed the `org_settings` task to use the API version of the org
    rather than the API version of the package.
-   In the Salesforce Robot Framework library, the `Open App Launcher`
    keyword now tries to detect and recover from an occasional situation
    where the app launcher fails to load.

## 3.10.0 (2020-04-02)

Changes:

-   Added `custom_settings_value_wait` task to wait for a custom setting
    to have a particular value.
-   The `metadeploy_publish` task now has a `labels_path` option which
    specifies a folder to store translations. After publishing a plan,
    labels_en.json will be updated with the untranslated labels from the
    plan. Before publishing a plan, labels from other languages will be
    published to MetaDeploy.

Issues closed:

-   Fixed an issue where running subprocesses could hang if too much
    output was buffered.

## 3.9.1 (2020-03-25)

Issues closed:

-   The `batch_apex_wait` task will now detect aborted and failed jobs
    instead of waiting indefinitely.
-   Fixed reporting of errors from Robot Framework when it exits with a
    return code \> 250.
-   Fixed an ImportError that could happen when importing the new
    metadata ETL tasks.
-   Fixed bugs in how the `set_organization_wide_defaults` and
    `update_admin_profile` tasks operated in namespaced scratch orgs.
-   Show a more helpful error message if CumulusCI can't find a
    project's repository or release on GitHub. (#1281)
-   Fixed the message shown for skipped steps in `cci flow info`.
-   Fixed a regression which accidentally removed support for the
    `bulk_mode` option in bulk data mappings.

## 3.9.0 (2020-03-16)

Critical changes:

-   The `update_admin_profile` task can now add field-level permissions
    for all packaged objects. This behavior is the default for projects
    with `minimum_cumulusci_version` \>= 3.9.0 that are not using the
    `package_xml` option. Other projects can opt into it using the
    `include_packaged_objects` option.

    The Python class used for this task has been renamed to
    `ProfileGrantAllAccess` and refactored to use the Metadata ETL
    framework. This is a breaking change for custom tasks that
    subclassed `UpdateAdminProfile` or `UpdateProfile`.

-   Refactored how CumulusCI uses the Bulk API to load, extract, and
    delete data sets. These changes should have no functional impact,
    but projects that subclass CumulusCI's bulk data tasks should
    carefully review the changes.

Changes:

-   New projects created using `cci project init` will now get set up
    with scratch org settings to:
    -   Use the Enhanced Profile Editor
    -   Allow logging in as another user
    -   _Not_ force relogin after Login-As
-   If `cumulusci.yml` contains non-breaking spaces in indentation, they
    will be automatically converted to normal spaces.
-   Bulk data tasks:
    -   Added improved validation that mapping files are in the expected
        format.
    -   When using the `ignore_row_errors` option, warnings will be
        suppressed after the 10th row with errors.

Issues closed:

-   The `github_release` task now validates the `commit` option to make
    sure it is in the right format.
-   If there is an error from `sfdx` while using the `retrieve_changes`
    task, it will now be logged.

## 3.8.0 (2020-02-28)

Changes:

-   The `batch_apex_wait` task can now wait for chained batch jobs, i.e.
    when one job starts another job of the same class.
-   The metadata ETL tasks that were added in cumulusci 3.7.0 have been
    refactored to use a new library,
    `cumulusci.utils.xml.metadata_tree`, which streamlines building
    Salesforce Metadata XML in Python. If you got an early start writing
    custom tasks using the metadata ETL task framework, you may need to
    adjust them to work with this library instead of lxml.

Issues closed:

-   Adjusted the `run_tests` task to avoid an error due to not being
    able to access the symbol table for managed Apex classes in Spring
    '20. Due to this limitation, CumulusCI now will not attempt to
    retry class-level concurrency failures when running Apex unit tests
    in a managed package. Such failures will be logged but will not
    cause a build failure.
-   Corrected a bug in storing preflight check results for MetaDeploy
    when multiple tasks have the same path.

## 3.7.0 (2020-02-20)

Changes:

-   Added a framework for building tasks that extract, transform, and
    load metadata from a Salesforce org. The initial set of tasks
    include:
    -   `add_standard_value_set_entries` to add entries to a
        StandardValueSet.
    -   `add_page_layout_related_lists` to add Related Lists to a Page
        Layout.
    -   `add_permission_set_perms` to add field permissions and Apex
        class accesses to a Permission Set.
    -   `set_organization_wide_defaults` to set the Organization-Wide
        Defaults for one or more objects and wait for the operation to
        complete.
-   Added a new task `insert_record` to insert a single sObject record
    via the REST API.
-   The `update_admin_profile` task now accepts a `profile_name` option,
    which defaults to Admin. This allows the task to be used to update
    other Profiles. (The task class has been renamed to UpdateProfile,
    but can still be used with the old name.)
-   Updated to use Metadata API version 48.0 as the default for new
    projects.
-   Robot Framework: Improved documentation for the API keywords in the
    Salesforce keyword library.

Issues closed:

-   Fixed the `cci error info` command. It was failing to load the log
    from the previous command.
-   Fixed a bug where some error messages were not displayed correctly.
-   Adjusted the Salesforce Robot Framework keyword library for better
    stability in Chrome 80.
-   Fixed a bug where using SFDXOrgTask to run an sfdx command on a
    non-scratch org would break with "Must pass a username and/or OAuth
    options when creating an AuthInfo instance."
-   Fixed a bug where an error while extracting the repository of a
    cross-project source could leave behind an incomplete copy of the
    codebase which would then be used by future commands.

## 3.6.0 (2020-02-06)

Changes:

-   `cci task info` now has Command Syntax section and
    improved formatting of option information.
-   CumulusCI now displays a more helpful error message when it detects
    a network connection issue. (#1460)
-   We've added the option `ignore_types` to the
    [](uninstall-packaged-incremental) task to allow all
    components of the specified metadata type to be ignored without
    having to explicitly list each one.
-   The [](FindReplace) task now accepts a list of strings for
    the `file_pattern` option.
-   If the [](DeleteData) task fails to delete some rows, this
    is now reported as an error.
-   Robot Framework: Added a new variable
    `\${SELENIUM_SPEED` that is used to control the speed
    at which selenium runs when the `Open Test Browser`
    keyword is called.

Issues Closed:

-   Fixed an issue where existing scratch orgs could sometimes not be
    used in Windows.
-   Fixed a regression where [flow info]{.title-ref} and [task
    info]{.title-ref} commands could show an error [AttributeError:
    'NoneType' object has no attribute 'get_service']{.title-ref}
    when trying to load tasks or flows from a cross-project source.
    (#1529)
-   Fixed an issue where certain HTTP errors while running the bulk data
    tasks were not reported.

## 3.5.4 (2020-01-30)

Changes:

-   There is a new top level [cci error]{.title-ref} command for
    interacting with errors in CumulusCI
-   [cci gist]{.title-ref} is now [cci error gist]{.title-ref}
-   [cci error info]{.title-ref} displays the last 30 lines of a
    stacktrace from the previous [cci]{.title-ref} command run (if
    present).
-   Changed the prompt users receive when encountering errors in
    [cci]{.title-ref}.

Issues Closed:

-   Robot Framework: Reverted a change to the
    [select_record_type]{.title-ref} keyword in the Salesforce library
    to work in both Winter '20 and Spring '20

## 3.5.3 (2020-01-23)

-   Added new features for running Python code (in a file or string)
    without bringing up an interactive shell. You can now use
    [--python]{.title-ref} and [--script]{.title-ref} arguments for
    the [cci shell]{.title-ref} and [cci org shell]{.title-ref}
    commands.
-   Added support for up to two optional parameters in Apex anonymous
    via token substitution.
-   The [EnsureRecordTypes]{.title-ref} class is now exposed as
    [](ensure-record-types) and correctly supports the Case,
    Lead, and Solution sObjects (in addition to other standard objects).
-   Fixed a bug where the github_parent_pr_notes was attempting to post
    comments on issues related to child pull request change notes.
-   Fixed various Robot keyword issues that have been reported for
    Spring '20.

## 3.5.2 (2020-01-21)

Issues closed:

-   Fixed an issue where errors running the [cci gist]{.title-ref}
    command prompt the user to use the [cci gist]{.title-ref} command.
-   Removed reference to [os.uname()]{.title-ref} so that [cci
    gist]{.title-ref} works on Windows.
-   Fixed an issue where the [](dx-pull) task causes an
    infinite loop to occur on Windows.

## 3.5.1 (2020-01-15)

Issues closed:

-   Fixed an issue that was preventing newlines in output.
-   Don't show the prompt to create a gist if the user aborts the
    process.
-   Avoid errors that can happen when trying to store the CumulusCI
    encryption key in the system keychain using Python's keyring
    library, which can fail on some systems such as CI systems:
    -   We fixed a regression that caused CumulusCI to try to load the
        keychain even for commands where it's not used.
    -   We fixed a bug that caused CumulusCI to try to load the keychain
        key even when using an unencrypted keychain such as the
        EnvironmentProjectKeychain.
-   Adjusted some keywords in the Salesforce library for Robot Framework
    to handle changes in the Spring '20 release.

## 3.5.0 (2020-01-15)

Changes:

-   The `load_dataset` task now accepts a `bulk_mode` option which can
    be set to `Serial` to load batches serially instead of in parallel.
-   CumulusCI now stores the logs from the last five executions under
    `~/.cumulusci/logs`
-   CumulusCI has a new top-level command: `cci gist`. This command
    creates a secret GitHub gist which includes: The user's current
    CumulusCI version, current Python version, path to python binary,
    sysname (e.g. Darwin), machine (e.g. x86_64), and the most recent
    CumulusCI logfile (`~/.cumulusci/logs/cci.log`). The command outputs
    a link to the created gist and opens a browser tab with the new
    GitHub gist. This can be helpful for sharing information regarding
    errors and issues encountered when working with cci. This feature
    uses a users GitHub access token for creation of gists. If your
    access token does not have the 'gist (Create gists)' scope this
    command will result in a 404 error. For more info see:
    <https://cumulusci.readthedocs.io/en/latest/features.html#reporting-error-logs>
-   Changed `UpdateAdminProfile` so that it only deploys the modified
    Admin profile. While it is necessary to retrieve profiles along
    their associated metadata objects, we don't need to do that for
    deployments.
-   Added options to the [](deploy) task: `check_only`,
    `test_level`, and `specified_tests`. Run `cci task info deploy` for
    details. (#1066)

## 3.4.0 (2020-01-09)

Changes:

-   Added `activate_flow` task which can be used to activate Flows and
    Process Builder processes.
-   Added two tasks, `disable_tdtm_trigger_handlers` and
    `restore_tdtm_trigger_handlers`, which can be used to disable
    trigger handlers for the table-driven trigger management feature of
    NPSP and EDA.
-   In the `load_dataset` task, added a way to avoid resetting the
    Salesforce Id mapping tables by setting the `reset_oids` option to
    False. This can be useful when running the task multiple times with
    the same org.
-   Added support for a few new metadata types from API versions 47 and
    48 in the `update_package_xml` task.
-   Added a way for Robot Framework libraries to register custom
    locators for use by the selenium library.

Issues closed:

-   Fixed a bug with freezing the `load_data` task for MetaDeploy where
    it would use an invalid option for `database_url`.
-   Fixed a bug in the `github_release_notes` task when processing a
    pull request with no description. (#1444)
-   Fixed inaccurate instructions shown at the end of
    `cci project init`.

## 3.3.0 (2019-12-27)

Breaking changes:

-   Removed tasks which are no longer in use: `mrbelvedere_publish`,
    `generate_apex_docs`, and `commit_apex_docs`.

Changes:

-   Updated Robot Framework Salesforce library to support the Spring
    '20 release.
-   Added `remove_metadata_xml_elements` task which can be used to
    remove specified XML elements from metadata files.
-   Updated references to the NPSP repository to use its new name
    instead of Cumulus.

Issues closed:

-   Fixed the error message shown when a task config has a bad
    `class_path`.
-   Fixed a warning when running the command task in Python 3.8.
-   When the CumulusCI Robot Framework library calls Salesforce APIs, it
    will now automatically retry when it is safe to do so. It will also
    avoid reusing old connections that might have been closed.
-   Fixed the `-o debug True` option for the `robot` task.

## 3.2.0 (2019-12-11)

Breaking changes:

-   We upgraded the SeleniumLibrary for Robot Framework from version
    3.3.1 to version 4.1.0. This includes the removal of some deprecated
    keywords. See the [SeleniumLibrary
    releases](https://github.com/robotframework/SeleniumLibrary/releases)
    for links to detailed release notes.

Changes:

-   The `Persistent Orgs` table shown by `cci org list` has been renamed
    to `Connected Orgs` since scratch orgs will be shown here if they
    were connected using `cci org connect` instead of created via the
    Salesforce CLI. This table now shows the org's expiration date, if
    known.
-   Improvements to the `retrieve_changes` task:
    -   The task now retrieves only the components that actually
        changed, not all components listed in `package.xml` in the
        target directory.
    -   Changes can now be retrieved into folders in DX source format.
        The target directory defaults to `src` if the project is using
        `mdapi` format or the default entry in `packageDirectories` in
        `sfdx-project.json` if the project is using `sfdx` format.
        (Namespace tokenization is not supported in DX format, since
        there isn't currently a way to deploy DX format source
        including namespace tokens.)
-   Added a task, `load_custom_settings`, to upload Custom Settings
    defined in YAML into a target org. See
    <https://cumulusci.readthedocs.io/en/latest/bulk_data.html#custom-settings>
    for more info.

Issues closed:

-   Fixed an issue with how the package upload task logs Apex test
    failures to make sure they show up in MetaCI.
-   Fixed `KeyError: createdDate` error when trying to get scratch org
    info.
-   A rare issue where CumulusCI could fail to load the symbol table for
    a failed Apex test class is now caught and reported.
-   CumulusCI now displays the underlying error if it encounters a
    problem with storing its encryption key in the system keychain.

## 3.1.2 (2019-11-20)

Breaking changes:

-   We changed the default path for the mapping file created by the
    `generate_dataset_mapping` task to `datasets/mapping.yml` so that it
    matches the defaults for `extract_dataset` and `load_dataset`
-   We changed the `extract_dataset` and `load_dataset` tasks to default
    to storing data in an SQL file, `datasets/sample.sql`, instead of a
    binary SQLite database file.

Changes:

-   `run_tests` can now detect and optionally retry two classes of
    concurrency issues with Apex unit tests. `run_tests` should always
    report an accurate total of test methods run, in parallel or serial
    mode.
-   Added the task `generate_data_dictionary`. This task indexes the
    fields and objects created in each GitHub release for the project
    and generates a data dictionary in CSV format.
-   Added a `devhub` service. This can be used to switch a project to a
    non-default sfdx Dev Hub using
    `cci service connect devhub --project`
-   Added a predefined `qa` scratch org. It uses the same scratch org
    definition file as the `dev` org, but makes it easier to spin up a
    second org for QA purposes without needing to first create it using
    `cci org scratch`.
-   The `database_url` option for the `extract_dataset` and
    `load_dataset` tasks is no longer required. Either `database_url` or
    `sql_path` must be specified. If both are specified, the `sql_path`
    will be ignored.
-   Developers can now directly execute CumulusCI from the Python
    command line using `python -m cumulusci` or
    `python cumulusci/__main__.py`

Issues closed:

-   A problem with how `run_tests` performed Apex test retries when
    `retry_always` is set to True has been corrected.

## 3.1.1 (2019-11-13)

New features:

-   After connecting an org with `cci org connect`, the browser now
    shows the message "Congratulations! Your authentication
    succeeded." instead of "OK"
-   External GitHub sources can now specify `release: latest`,
    `release: latest_beta`, or `release: previous` instead of a commit,
    branch, or tag.
-   The `execute_anon` task has been revised to detect when a gack
    occurred during execution.

Issues closed:

-   When importing a scratch org from sfdx using `cci org import`, the
    org's `days` is now set correctly from the org's actual expiration
    date. (#1101)
-   The package API version from `cumulusci.yml` is now validated to
    make sure it's in the "XX.0" format expected by the API. (#1134)
-   Fixed an error deploying new setting objects using the
    `org_settings` task in Winter '20.
-   Fixed a bug in processing preflight check tasks for MetaDeploy.
-   Fixed path handling in the `update_admin_profile` task when run in a
    cross-project flow.

## 3.1.0 (2019-11-01)

Breaking changes:

-   The `metadeploy_publish` task now requires setting `-o publish True`
    in order to automatically set the Version's is_listed flag to True.
    (This is backwards incompatible in order to provide a safer
    default.)

New features:

-   Python 3.8 is now officially supported.
-   Flows can now include tasks or flows from a different project. See
    [Using Tasks and Flows from a Different
    Project](https://cumulusci.readthedocs.io/en/latest/features.html)
    for details.
-   In the `metadeploy_publish` task it is now possible to specify a
    commit hash with `-o commit [sha]`, instead of a tag. This is useful
    while MetaDeploy plans are in development.
-   Bulk data:
    -   Added support for mapping Record Types between orgs (by
        Developer Name) during bulk data extract and load.
    -   Added support for Record Type mapping in the
        `generate_dataset_mapping` task.
    -   Added [new
        documentation](https://cumulusci.readthedocs.io/en/latest/bulk_data.html)
        for bulk data tasks.
-   Robot Framework:
    -   The sample `create_contact.robot` test that is created when
        initializing a new project with `cci project init` now makes use
        of page objects.
    -   The page objects library has two new keywords, `wait for modal`
        and `wait for page object`, which wait for a new page object to
        appear.
    -   `cumulusci.robotframework.utils` now has a decorator named
        `capture_screenshot_on_error` which can be used to automatically
        capture a screenshot when a keyword fails.
    -   Prior to this change, `Go to page Detail Contact` required you
        to use a keyword argument for the object id (eg:
        `Go to page Detail Contact object_id=${object_id}`). You can
        now specify the object id as a positional parameter (eg:
        `Go to page Detail Contact ${object_id}`).
-   `OrgConfig` objects now have a `latest_api_version` property which
    can be used to check what Salesforce API version is available.

Issues closed:

-   Updated the scratch org definition files generated by
    `cci project init` to the new recommended format for org settings.
    Thanks to \@umeditor for the fix.
-   The `create_unmanaged_ee_src` task (part of the `unmanaged_ee` flow)
    has been revised to remove the Protected setting on Custom Objects,
    to ensure that projects using this setting can be deployed to an
    Enterprise Edition org.
-   The Salesforce REST API client used by many tasks will now
    automatically retry requests on certain connection and HTTP errors.
-   Fixed an issue where posts to the Metadata API could reuse an
    existing connection and get a connection reset error if Salesforce
    had closed the connection.
-   Disabled use of PyOpenSSL by the Python requests library, since it
    is no longer needed in the versions of Python we support.

## 3.0.2 (2019-10-17)

Issues closed:

-   Fixed a bug in deploying email templates and dashboards that was
    introduced in 3.0.1.
-   Removed broken `config_qa` flow from the `cci project init`
    template.

## 3.0.1 (2019-10-16)

New features:

-   Added support for new metadata types when generating `package.xml`
    from a directory of metadata using the `update_package_xml` task.
-   The `ci_feature` flow now supports generating change notes for a
    parent feature branch's pull request from the notes on child pull
    requests. The parent pull request description will be overwritten
    with the new notes after a child branch is merged to the parent if
    the parent pull request has a special label, `Build Change Notes`.
-   When running Apex tests with the `run_tasks` task, if there is a
    single remaining class being run, its name will be logged.
-   Apex test failures that happen while uploading a package are now
    logged.
-   In the `robot_libdoc` task, wildcards can now be used in the `path`
    option.
-   Added an `org_settings` task which can deploy scratch org settings
    from a scratch org definition file.

Issues closed:

-   Added a workaround for an issue where refreshing the access token
    for a sandbox or scratch org could fail if the user's credentials
    were new and not fully propagated.

## 3.0.0 (2019-09-30)

Breaking change:

-   CumulusCI 3.0.0 removes support for Python 2 (which will reach end
    of life at the end of 2019). If you're still running Python 2 you
    can use an older version of CumulusCI, but we recommend upgrading to
    Python 3. See our [installation
    instructions](https://cumulusci.readthedocs.io/en/latest/install.html)
    for your platform.

## 2.5.9 (2019-09-26)

New features:

-   Added a Domain column to the list of scratch orgs in `cci org list`.
    (thanks \@bethbrains)

-   Tasks related to Salesforce Communities (thanks \@MatthewBlanski)

    : - New `list_community_templates` task - New `list_communities` task - New `publish_community` task - The `create_community` task can now be used to create a
    community with no URL prefix, as long as one does not
    already exist.

-   Robot Framework:

    : -

            Added keywords for generating a collection of sObjects according to a template:

            :   -   `Generate Test Data`
                -   `Salesforce Collection Insert`
                -   `Salesforce Collection Update`

        -

            Changes to Page Objects:

            :   -   More than one page object can be loaded at once.
                    Once loaded, the keywords of a page object remain
                    visible in the suite. Robot will give priority to
                    keywords in the reverse order in which they were
                    imported.
                -   There is a new keyword, `Log Current Page Object`,
                    which can be useful to see information about the
                    most recently loaded page object.
                -   There is a new keyword, `Get Page Object`, which
                    will return the robot library for a given page
                    object. This can be used in other keywords to access
                    keywords from another page object if necessary.
                -   The `Go To Page` keyword will now automatically load
                    the page object for the given page.

        -   Added a basic debugger for Robot tests. It can be enabled
            using the `-o debug True` option to the robot task.

-   Added support for deploying new metadata types
    `ProfilePasswordPolicy` and `ProfileSessionSetting`.

Issues closed:

-   Fixed a bug where the `batch_apex_wait` task would sometimes fail to
    conclude that the batch was complete.
-   Fixed a bug in rendering tables in Python 2.

## 2.5.8 (2019-09-13)

New features:

-   `LoadData` now supports the key `action: update` to perform a Bulk
    API update job
-   `LoadData` now supports an `after: <step name>` on a lookup entry to
    defer updating that lookup until a dependent sObject step is
    completed.
-   `GenerateMapping` now handles self-lookups and reference cycles by
    generating `after:` markers wherever needed.

Issues closed:

-   Patch selenium to convert `executeScript` to `executeAsyncScript`.
    This is a workaround for the `executeScript` issue in chromedriver 77.
-   A small issue in `QueryData` affecting mappings using
    `oid_as_pk: False` has been fixed.

## 2.5.7 (2019-09-03)

Breaking changes:

-   The `retries`, `retry_interval`, and `retry_interval_add` options
    have been removed from the `run_tests` task. These were misleading
    as they did not actually retry failing tests.

New features:

-   The `run_tests` task now supports a `retry_failures` parameter. This
    is a list of regular expressions to match against each unit test
    failure's message and stack trace; if all failing tests match, the
    failing tests will be retried serially. Set `retry_always` to True
    to trigger this behavior when any failure matches.
-   There is now a default CumulusCI global connected app that can be
    used to connect to persistent orgs (assuming you know the
    credentials) without creating a new connected app. It's still
    possible to configure a custom connected app using
    `cci service connect connected_app` if more control over the
    connected app settings is needed.
-   When CumulusCI is being run in a non-interactive context it can now
    obtain an access token for a persistent org using a JWT instead of a
    refresh token. This approach is used if the SFDX_CLIENT_ID and
    SFDX_HUB_KEY environment variables are set. This makes it easier to
    manage persistent org connections in the context of a hosted service
    because it's possible to replace the connected app's certificate
    without needing to obtain new refresh tokens for each org.

Issues closed:

-   Fixed a bug where showing the summary of flow steps would break with
    sub-steps in MetaDeploy.
-   Fixed a bug in the caching of preflight task results in MetaDeploy.

## 2.5.6 (2019-08-15)

New features:

-   We've changed how the output of some commands are displayed in
    tables. For users that prefer simpler style tables we've added a
    `--plain` option to approximate the previous behavior. To
    permanently set this option, add this in
    `~/.cumulusci/cumulusci.yml`:

        cli:
            plain_output: True

-   Added additional info to the `cci version` command, including the
    Python version, an upgrade check, and a warning on Python 2.

-   Improved the summary of flow steps that is shown at the start of
    running a flow.

-   The `github_release_notes` task now has an `include_empty` option to
    include links to pull requests that have no release notes. This is
    enabled by default when this task is called as part of the
    `release_beta` flow.

-   Robot Framework:

    -   Added locators file to support the Winter '20 release of
        Salesforce.
    -   New `robot_lint` task to check for common problems in Robot
        Framework test suites.
    -   The `Open Test Browser` keyword will now log details about the
        browser.
    -   Added a new keyword to the CumulusCI library,
        `Get Community Info`. It can be used to get information about a
        Community by name via the Salesforce API.

Issues closed:

-   Added workarounds for some intermittent 401 errors when
    authenticating to the GitHub API as a GitHub App.
-   `cci org info` shouldn't show traceback if the org isn't found
    (#1023)

## 2.5.5 (2019-07-31)

New features:

-   Add the `cci org shell` command, which opens a Python shell
    pre-populated with a simple_salesforce session on the selected org
    (as `sf`).
-   The `cci flow info` command now shows nested subflows.
-   Added the `create_community` task allowing for API-based Community
    creation.
-   Added the `generate_dataset_mapping` task to generate a Bulk Data
    mapping file for a package.
-   CumulusCI can now authenticate for GitHub API calls as either a user
    or an app. The latter is for use when CumulusCI is used as part of a
    hosted service.
-   The `OrgConfig` object now provides access to the Organization
    SObject data via the `organization_sobject` attribute.

Issues closed:

-   The `install_regression` flow now upgrades to the latest beta from
    the most recent final release instead of from the previous final
    release.
-   Made sure that an `errorMessage` returned from a metadata API deploy
    will be reported.
-   The `load_dataset` task will now stop with an exception if any
    records fail during the load operation.

## 2.5.4 (2019-07-03)

-   Updated the default API version for new projects to 46.0
-   Fixed a bug in reporting scratch org creation errors encountered
    while running a flow.
-   Fixed the `snapshot_changes` and `list_changes` tasks to avoid
    breaking when the last revision number of a component is null.

## 2.5.3 (2019-06-24)

Breaking changes:

-   Added two new options to the UpdateDependencies task:

    -   `allow_newer`: If the org already has a newer release, use it.
        Defaults to True.
    -   `allow_uninstalls`: Allow uninstalling a beta release or newer
        final release if needed in order to install the requested
        version. Defaults to False.

    These defaults are a change from prior behavior since uninstalling
    packages is not commonly needed when working with scratch orgs, and
    it is potentially destructive.

New features:

-   Added support for defining and evaluating preflight checks for
    MetaDeploy plans.
-   The tasks for bulk data extract and load are now configured by
    default as `extract_data` and `load_data`.
-   Updated the project template created by `cci project init`:
    -   Added `.gitignore`, `README.md`, and a template for GitHub pull
        requests
    -   Added an option to store metadata in DX source format
    -   Added a sample `mapping.yml` for the bulk data tasks
    -   Specify the currently installed CumulusCI version as the
        project's `minimum_cumulusci_version`
    -   Check to make sure the project name only contains supported
        characters
-   The `robot_libdoc` task can now generate documentation for Robot
    Framework page objects.

Issues fixed:

-   Colors in terminal output are now displayed correctly in Windows.
    (#813)
-   `cci` no longer prints tracebacks when a flow or task is not found.
    Additionally, it will suggest a name if a close enough match can be
    found. (#960)
-   Fixed UnicodeDecodeError when reading output from subprocesses if
    the console encoding is different from Python's preferred file
    encoding.
-   Fixes related to source tracking:
    -   Track the max revision retrieved for each component instead of
        the overall max revision. This way components can be retrieved
        in stages into different paths.
    -   If `snapshot_changes` doesn't find any changes, wait 5 seconds
        and try again. There can be a delay after a deployment before
        source tracking is updated.

## 2.5.2 (2019-06-10)

Issues fixed:

-   When generating package.xml, translate `___NAMESPACE___` tokens in
    filenames into `%%%NAMESPACE%%%` tokens in package.xml (#1104).
-   Avoid extraneous output when `--json` output was requested (#1103).
-   Display OS notification when a task or flow completes even if it
    failed.
-   Robot Framework: Added logic to retry the initial page load if it is
    not loading successfully.
-   Internal API change: Errors while processing a response from the
    Metadata API are now raised as MetadataParseError.

## 2.5.1 (2019-05-31)

Issues fixed:

-   Fixed `cci service connect` when run outside of a directory
    containing a CumulusCI project.

## 2.5.0 (2019-05-25)

Breaking changes:

-   We reorganized the flows for setting up a package for regression
    testing for better symmetry with other flows. If you were running
    the `install_regression` flow before, you now probably want
    `regression_org`.

    Details: The `install_regression` flow now installs the package
    _without_ configuring it. There is a new `config_regression`
    flow to configure the package (it defaults to calling
    `config_managed`) and a `regression_org` flow that includes both
    `install_regression` and `config_regression`.

New features:

-   CumulusCI now has experimental support for deploying projects in [DX
    source
    format](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_source_file_format.htm).
    To enable this, set `source_format: sfdx` in the project section of
    `cumulusci.yml`. CumulusCI will deploy DX-format projects to scratch
    orgs using `sfdx force:source:push` and to other orgs using the
    Metadata API (by converting to metadata source format in a temporary
    directory).
-   Setting a default org in CumulusCI (using `cci org default` or the
    `--default` flag when creating a scratch org) will now also update
    the sfdx `defaultusername`. (#868)
-   When connecting to GitHub using `cci service connect github`,
    CumulusCI will now check to make sure the credentials are valid
    before saving them.
-   Robot Framework:
    -   Added a framework for creating "page object" classes to
        contain keywords related to a particular page or component.
    -   The `robot` task now takes a `name` option to control the name
        of the robot suite in output.
    -   Updates to the keyword `Open Test Browser`:
        -   It allows you to open more than one browser in a single test
            case. (#1068)
        -   It sets the default size for the browser window to
            1280x1024.
        -   Added a new keyword argument `size` to override the default
            size.
        -   Added a new keyword argument `alias` to let you assign an
            alias to multiple browser windows.

Issues fixed:

-   Robot Framework: Fixed a bug where the `Delete Session Records`
    keyword would skip deleting some records. (#973)
-   If Salesforce returns an error response while refreshing an OAuth
    token, CumulusCI will now show the response instead of just the HTTP
    status code.
-   Fixed a bug in reporting errors from the Metadata API if the
    response contains `componentFailures` with no `problem` or
    `problemType`.

## 2.4.4 (2019-05-09)

New features:

-   Added tasks `list_changes` and `retrieve_changes` which interact
    with source tracking in scratch orgs to handle retrieving changed
    metadata as Metadata API format source.
-   Added task `EnsureRecordTypes` to generate a Record Type and
    optional Business Process for a specific sObject and deploy the
    metadata, if the object does not already have Record Types.
-   The `update_admin_profile` task now uses Python string formatting on
    the `package.xml` file used for retrieve. This allows injection of
    namespace prefixes using `{managed}` and `{namespaced_org}`.

Issues fixed:

-   If CumulusCI gets a connection error while trying to call the
    Salesforce Metadata API, it will now retry several times before
    giving up.
-   The GitHub release notes parser now recognizes Issues Closed if they
    are linked in Markdown format.
-   Robot Framework: Fixed a locator used by the
    `Select App Launcher App` keyword to work in Summer '19.
-   The `cci project init` command now uses an updated repository URL
    when extending EDA.

## 2.4.3 (2019-04-26)

-   Allow configuration of the email address assigned to scratch org
    users, with the order of priority being (1) any `adminEmail` key in
    the scratch org definition; (2) the `email_address` property on the
    scratch org configuration in `cumulusci.yml`; (3) the `user.email`
    configuration property in Git.
-   CumulusCI can now handle building static resource bundles
    (`*.resource`) while deploying using the Metadata API. To use this
    option, specify the `static_resource_path` option for the deploy
    task. Any subdirectory in this path will be turned into a resource
    file and added to the package during deployment. There must be a
    corresponding `*.resource-meta.xml` file for each static resource
    bundle.
-   Bulk data tasks: Fixed a bug that added extra underscores to field
    names when processing lookups.
-   Robot Framework: The Salesforce library now has the ability to
    switch between different sets of locators based on the Salesforce
    version, and thanks to it we've fixed the robot so it can click on
    modal buttons in the Summer '19 release.
-   The `cci project init` command now generates projects with a
    different preferred structure for Robot Framework tests and
    resources, with everything inside the `robot` directory. Existing
    projects with tests in the `tests` directory should continue to
    work.

## 2.4.2 (2019-04-22)

-   The `purgeOnDelete` flag for the `deploy` task will now
    automatically be set to false when deploying metadata to production
    orgs (previously deployment would fail on production orgs if this
    flag was true).
-   The installation documentation now recommends using `pipx` to
    install CumulusCI on Windows, so that you don't have to set up a
    virtualenv manually.

## 2.4.1 (2019-04-09)

Changes:

-   Updated the default Salesforce Metadata API version to 45.0
-   The scratch org definition files generated by `cci project init` now
    use `orgPreferenceSettings` instead of the deprecated
    `orgPreferences`.
-   The `metadeploy_publish` task now defaults to describing tasks based
    on `Deploy` as "metadata" steps instead of "other".

Issues Fixed:

-   Fixed a couple problems with generating passwords for new scratch
    orgs:
    -   A project's predefined scratch org configs now default to
        `set_password: True` (which was already the case for orgs
        created explicitly using cci org scratch).
    -   A scratch org config's `set_password` flag is now retained when
        recreating an expired org. (Fixes ##670)
-   Fixed the logic for finding the most recent GitHub release so that
    it now only considers tags that start with the project's git
    `prefix_release`.
-   Fixed the `install_prod_no_config` flow. The `deploy_post` task was
    not injecting namespace tokens correctly.
-   Fixed the `connected_app` task to work with version 7 of the
    sfdx CLI. (Fixes ##1013)
-   Robot Framework: Fixed the `Populate Field` keyword to work around
    intermittent problems clearing existing field values.

## 2.4.0 (2019-03-18)

Critical changes:

-   If you are publishing installation plans to MetaDeploy, there have
    been some significant changes:

    > -   Plan options are now read from a new `plans` section of
    >     `cumulusci.yml` instead of from task options. This means that
    >     a single run of the task can now handle publishing multiple
    >     plans, and there is now a generic `metadeploy_publish` task
    >     which can be used instead of setting up different tasks for
    >     each project.
    > -   Plan steps are now defined inline in the plan configuration
    >     rather than by naming a flow. This makes it easier to
    >     configure a plan that is like an existing flow with one or two
    >     adjustments.
    > -   There is now a way to customize MetaDeploy step settings such
    >     as `name` and `is_required` on a step-by-step basis, using
    >     `ui_options` in the plan config.
    > -   The task will now find or create a `PlanTemplate` as
    >     necessary, matching existing PlanTemplates on the product and
    >     plan name. This means the plan config no longer needs to
    >     reference a plan template by id, which makes it easier to
    >     publish to multiple instances of MetaDeploy.

-   The `install_upgrade` flow was renamed to `install_regression` to
    better reflect the use case it is focused on. There are also a few
    updates to what it does:

    > -   It will now install the latest beta release of managed
    >     packages instead of the latest final release.
    > -   It now runs the `config_managed` flow after upgrading the
    >     managed package, so that it will work if this flow has
    >     references to newly added components.

Changes:

-   Added support for deploying Lightning Web Components.
-   Fixed the bulk data load task to handle null values in a datetime
    column.
-   The [](ci-master) flow now explicitly avoids trying to
    install beta releases of dependencies (since it's meant for use
    with non-scratch orgs and we block installing betas there since they
    can't be upgraded).

## 2.3.4 (2019-03-06)

-   Added a new flow, `install_upgrade`, which can be used for testing
    package upgrades. It installs and configures the _previous_
    release of the package, then installs the latest release.
-   Fixed an error when using `cci org info --json` (fixes ##1013).

## 2.3.3 (2019-02-28)

-   Fixed a bug where flow options specified on the command line were
    not passed to tasks correctly.
-   `cci service connect` now shows a more helpful error message if you
    call it with a service name that CumulusCI doesn't know about.
    Fixes ##752.
-   Deleted scratch orgs will no longer show the number of days since
    they were created in `cci org list`. Thanks to \@21aslade for the
    fix.
-   Updates to the MetaDeploy publish task:
    -   It is now possible to publish a new plan for an existing
        version.
    -   It is now possible to specify the AllowedList to which a plan is
        visible.
-   Updates to Robot Framework support:
    -   Fixed a bug in the `robot` task: it now accepts an option called
        `test` rather than `tests`, since the latter was ignored by
        Robot Framework.
    -   Fixed some stability problems with the `Populate Field` keyword.
    -   The `robot_libdoc` task has been replaced with a new task of the
        same name that can generate a single HTML document for multiple
        keyword files by passing a comma-separated list of files to the
        `path` option.

## 2.3.2 (2019-02-19)

-   Mapping enhancements for bulk `QueryData` and `LoadData` tasks
    -   The mapping yaml file no longer requires using `Id: sf_id` as a
        field mapping. If not provided, `QueryData` and `LoadData` will
        use local database ids instead of Saleforce OIDs for storing
        lookup relationships. Previous mappings which specify the
        `Id: sf_id` mapping will continue to work as before using the
        Salesforce OID as the mapping value.
    -   The mapping yaml file's `lookups:` section now handles defaults
        to allow simpler lookup mappings. The only key required is now
        `table`. If the `key_field` is provided it will be used.
-   The `sql_path` option on `QueryData` can be used to provide the file
    path where a SQL script should be written. If this option is used, a
    sqlite in-memory database is used and discarded. This is useful for
    storing data sets in a Github repository and allowing diffs of the
    dataset to be visible when reviewing Pull Requests
    -   When using this option, it is best to make sure your mapping
        yaml file does not provide a field mapping for the `Id` field.
        This will help avoid merge conflicts if querying data from
        different orgs such as scratch orgs.
-   The [sql_path]{.title-ref} option on `LoadData` can be used to
    provide the file path where a SQL script file should be read and
    used to load an in-memory sqlite database for the load operation.

## 2.3.1 (2019-02-15)

-   Fixed a bug that caused the `cci` command to check for a newer
    version on every run, rather than occasionally. Also we now detect
    whether CumulusCI was installed using Homebrew and recommend an
    upgrade command accordingly.
-   CumulusCI now automatically generates its own keychain key and
    stores it in the system keychain (using the Python
    [keyring]{.title-ref} library). This means that it is no longer
    necessary to specify a CUMULUSCI_KEY as an environment variable.
    (However, the environment variable will still be preferred if it is
    there, and it will be migrated to the system keychain.)
-   New task `connected_app` makes it easier to deploy and configure the
    Connected App needed for CumulusCI's keychain to work with
    persistent orgs. The connected app is deployed using `sfdx` to an
    org in the `sfdx` keychain and defaults to the
    `defaultdevhubusername`.
-   The `robot` task gives a more helpful error message if you forget to
    specify an org.
-   Updates to the task for publishing to MetaDeploy:
    -   Dependency installation steps are now named using the package
        name and version.
    -   The task options have been revised to match changes in the
        MetaDeploy API. An optional `plan_template_id` is now accepted.
        `preflight_message` is now named `preflight_message_additional`
        and is optional. `post_install_message` is now named
        `post_install_message_additional` and is optional.

## 2.3.0 (2019-02-04)

Changes:

-   When installing a managed package dependency, pre & post metadata
    bundles are now fetched from the git commit corresponding to the
    most recent release of the managed package, instead of master.
-   Improvements to the task for publishing a release to MetaDeploy:
    -   It can now publish a tag even if it's a different commit than
        what is currently checked out in the working directory.
    -   It now pins managed deployments of metadata bundles to the git
        commit corresponding to the most recent release of the managed
        package.

Issues Closed:

-   ##962: `cumulusci.utils.findReplace` uses wrong file encoding in
    Python 3
-   ##967: Allow `cci service` commands to be run from outside a project
    repository

## 2.3.0b1 (2019-01-28)

Breaking Changes:

-   We refactored the code for running flows. The full list of steps to
    run is now calculated from nested flow configuration when the flow
    is initialized instead of during runtime. Your existing flows should
    continue to run as before, but if you're interacting with CumulusCI
    at the Python API level, you'll need to use the `FlowCoordinator`
    instead of `BaseFlow`.
-   Tasks are now expected to have no side effects when they are
    instantiated. If tasks need to set up resources, do that in
    `_init_task` instead of `__init__` or `_init_options` to make sure
    it doesn't happen until the task is actually being run.

Changes:

-   There is now a `dev_org_beta_deps` flow which sets up an org in the
    same way as `dev_org`, but installs the latest beta versions of
    managed package dependencies.
-   The `github_release` task now records the release dependencies as
    JSON in the release's tag message.
-   Looking up the latest release from GitHub is now done using a single
    HTTP request rather than listing all releases.
-   We added S-Controls to the list of metadata types that the
    `uninstall_packaged_incremental` task will delete.
-   Salesforce Robot Framework library: The `Get Current Record Id`
    keyword now parses the Id correctly when prefixed with `%2F`, which
    apparently happens.
-   The `push_failure_report` task now avoids an error when querying for
    info about lots of subscriber orgs.

Issues Closed:

-   ##911: Fix UnicodeDecodeError when parsing XML retrieved from the
    Metadata API.

## 2.2.6 (2019-01-03)

Changes:

-   Added support for more metadata types: Group, SharingSet,
    SharingCriteriaRule, SharingOwnerRule, and SharingTerritoryRule.
-   Release process: We now have tools in place to release cumulusci so
    that it can be installed using Homebrew or Linuxbrew.

Issues Closed:

-   Fixed an issue where tasks using the Salesforce REST API could build
    a wrong URL with an extra slash after the instance URL.
-   Fixed an issue where overriding a flow step to set flow: None did
    not work.
-   Robot Framework: Added an automatic retry to work around an issue
    with an intermittent ConnectionResetError when connecting to
    headless Chrome in Python 3.

## 2.2.5 (2018-12-26)

-   The `install_managed` and `install_managed_beta` tasks now take
    optional `activateRSS` and `password` options. `activateRSS` is set
    to true by default so that any active Remote Site Settings in the
    package will remain active when installed.
-   When running a task with the `--debug` flag, HTTP requests are now
    logged.
-   Robot Framework:
    -   Fix issue where "Get Current Record Id" could accidentally
        match the object name instead of the record Id.
    -   Fix issue where "Load Related List" would fail to scroll down
        to the list.
    -   Fix issue where errors deleting records during test teardown
        would cause a hidden test failure.

## 2.2.4 (2018-12-17)

Changes:

-   Bulk query task:
    -   Fixed an issue with querying data filtered by record type
        (#904).
    -   Fixed an issue where the optimized approach for loading data
        into PostgreSQL was not used.
    -   The task will now prevent you from accidentally overwriting
        existing data by exiting with an error if the table already
        exists.
-   The `deploy` task now logs the size of the zip payload in bytes.
-   Fixed a TypeError in the `commit_apex_docs` task (#901).
-   Robot Framework:
    -   Add location strategies for locating elements by text and by
        title.

## 2.2.3 (2018-12-07)

Changes:

-   Improved error messages when scratch org creation failed and when a
    service is not configured.
-   Robot Framework: Limit how long the "Load Related List" keyword
    will wait.

## 2.2.2 (2018-11-27)

Changes:

-   Improved error handling during scratch org creation:
    -   Capture and display stderr output from SFDX (issue ##413).
    -   Avoid infinite recursion if username wasn't found in output
        from SFDX.
-   Robot Framework: Increased the timeout for initial loading of the
    browser.

## 2.2.1 (2018-11-21)

Oops, an update in CumulusCI 2.2.0 ended up breaking the
update_dependencies task! Now fixed.

## 2.2.0 (2018-11-21)

Changes:

-   Tasks can now be placed in groups for the task list! Just specify a
    `group` when defining the task in YAML.
-   By popular request, there is now an `org import` command to import
    an org from the SFDX keychain to the CumulusCI keychain. It takes
    two arguments: the SFDX username or alias, and the org name.
-   Robot Framework:
    -   The `Populate Field` keyword now clears an existing value using
        keystrokes to make sure that change events are fired.
    -   Added a `Get Namespace Prefix` keyword to the CumulusCI library
        to get the namespace prefix for a package.
    -   Fixed a bug that broke opening a browser after using the
        `Run Task` keyword.
-   Documentation updates:
    -   The readme now includes a link to the full documentation.
    -   The instructions for installing CumulusCI on macOS have been
        simplified and now recommend using the official Python installer
        from python.org instead of Homebrew. (Homebrew should still work
        fine, but is no longer necessary.) We also now suggest creating
        a virtualenv using venv rather than pyenv since the former is
        included with Python. It's fine to continue using pyenv if you
        want.
    -   Give more useful links for how to set up SFDX.
    -   Updated robot library docs.
-   Internal refactoring:
    -   Removed dependency on HiYaPyCo for YAML loading, which would not
        report which file failed to load in the event of a YAML parse
        error.
    -   We now consistently load YAML in the same manner throughout the
        entire library, which will work with all supported Python
        versions.
    -   Simplified the Python API for setting up a CumulusCI runtime.
        Begone, YamlGlobalConfig and YamlProjectConfig. Our Python API
        is not yet documented, but we're working on it. In the
        meantime, if you were relying on running CCI from within Python,
        you can now just use BaseGlobalConfig (and its
        get_project_config member) to bootstrap CCI.
    -   BaseProjectConfig has shrugged off some methods that just
        delegated to the keychain.
    -   BaseGlobalConfig has shrugged off some unimplemented methods,
        and BaseGlobalConfig.get_project_config is now deprecated in
        favor of using a runtime.
    -   Introducing\... 🥁CumulusCIRuntime! In order to alleviate the
        complexities of getting CumulusCI tasks/flows running from
        within a Python application, CumulusCIRuntime encapsulates a lot
        of the details and wiring between Keychain, GlobalConfig, and
        ProjectConfig. Usage docs are barely included.
    -   CliConfig has been renamed to CliRuntime and now inherits from
        CumulusCIRuntime. It is still accessible as CliConfig.
    -   Upgraded dependencies.
-   Contributor improvement: The contributor docs now explain how to
    install pre-commit hooks to make sure our linters have run before
    you commit.

Issues Closed:

-   ##674: `cci org import <username> <org_name>`
-   ##877: CumulusCI should be able to connect to any DX alias and/or
    understand dx auth files

## 2.1.2 (2018-10-29)

Oops, we broke a few things! This is a bugfix release to fix a few
issues found during the Salesforce.org Open Source Community Sprint last
week.

Issues Closed:

-   ##858 Dataload bulk query fails to load data into the sqlite db
-   ##862 CLI options fail on robot task in 2.1.1
-   ##864 Deploying a -meta.xml file with non-ASCII characters breaks in
    Python 2

## 2.1.1 (2018-10-23)

Changes:

-   Our robotframework library for Salesforce got a number of
    improvements:
    -   New keywords:
        -   `Click Header Field Link`: Clicks a link in a record header
        -   `Load Related List`: Scrolls to a related list and waits for
            it to load
        -   `Click Related List Button`: Clicks a button in the header
            of a related list
        -   `Click Related Item Link`: Clicks the main link for an item
            in a related list
        -   `Click Related Item Popup Link`: Clicks a link in the popup
            menu for an item in a related list
    -   Updated to `robotframework-seleniumlibrary` 3.2.0 which includes
        a `Scroll Element Into View` keyword.
    -   `Wait Until Loading Is Complete` now waits for the main body of
        the page to render
    -   `Populate Lookup Field` now tries several times in case there's
        an indexing delay
    -   Added a `-o verbose True` option to the robot task which logs
        each keyword as it runs.
    -   We now ignore errors while running the script that waits for
        XHRs to complete (it can fail if the page reloads before the
        script finishes).
-   Popup notifications upon completion of a flow or task now work on
    Linux too, if you have the `notify-send` command from libnotify. On
    Ubuntu, install the `notify-osd` package.

Issues Closed:

-   ##827 Bulk data load breaks in Python 2
-   ##832 pip install cumulusci gets the wrong version of urllib3

## 2.1.1b1 (2018-10-17)

-   `uninstall_packaged_incremental` task: Added `ignore` option to
    specify components to skip trying to delete even if they are present
    in the org but not in the local source.

## 2.1.0 (2018-10-16)

-   Fixed the `cci project init` command, which was failing because it
    wanted the project to already exist! Fixes ##816. In addition, other
    commands will now function without an active project or keychain
    when it possible to do so. (For example, try `cci version` which now
    works when you're not in a project directory.)

-   `update_dependencies` task:

    : - Added support for installing private github repositories as
    dependencies. Thanks to Anthony Backhouse (@1handclapping)
    for the patch. Fixes ##793 - Added a `dependencies` option to override the project
    dependencies.

-   `execute_apex` task:

    : - Print more useful error messages when there are Apex
    exceptions.

-   `robot` task:

    : - Our logic for automatically retrying failed selenium
    commands has been encapsulated into the
    `cumulusci.robotframework.utils.selenium_retry` decorator
    which can be applied to a robot library class for increased
    stability. - There is now an option to pause and enter the Python
    debugger after a keyword fails. Run with `-o pdb True`. - Revised keywords and locators to support the Winter '19
    release of Salesforce and improve stability. - The `Salesforce.robot` file now includes the
    `OperatingSystem` and `XML` libraries from Robot Framework
    by default. These libraries are helpful in building
    integration tests such as modifying and deploying a
    PageLayout to include a field needed in Suite Setup of an
    integration test.

-   Revised installation instructions for Windows. Thanks Matthew
    Blanski (@Auchtor).

-   Internal change: Use a thread-local variable instead of a global to
    track the current running task.

## 2.1.0b1 (2018-10-05)

-   It's happening! Hot on the heels of the last release, CumulusCI is
    making the jump to the modern era by adding **support for Python
    3**! (Specifically, Python 3.6 and 3.7.) Don't worry, we'll also
    continue to support Python 2 for the time being. Because this is a
    bit more wide-reaching change than normal, we're releasing a beta
    first. To install the beta you'll need to explicitly request its
    version: `pip install cumulusci==2.1.0b1`. If you already have
    CumulusCI, after the update it will continue to run under your
    Python 2 interpreter. If you want to switch to the Python 3
    interpreter (which is not yet required), we recommend deleting your
    Python virtualenv and starting over with the instructions in the
    [tutorial](https://cumulusci.readthedocs.io/en/latest/tutorial.html).
    If you want to keep your Python 2-based virtualenv around just in
    case, follow those instructions but name the new virtualenv
    `cci-py3` instead of `cci`.
-   There are also some big changes to the **bulk data** tasks. Did you
    know CumulusCI has bulk data tasks? They are not configured by
    default, because we need to finish documenting them. But we'll list
    the changes in case someone is already relying on them:
    -   Fixed connection resets by downloading an entire result file
        before processing.
    -   Improved performance by processing batches in parallel, avoiding
        the SQLAlchemy ORM, storing inserted Ids in separate tables, and
        doing lookups using SQL joins rather than a separate query for
        each row.
    -   If you're using a postgres database for local storage,
        performance gets even better by taking advantage of postgres'
        `COPY` command to load CSV directly.
    -   Added a `hardDelete` option for bulk deletes.
    -   Added a `start_step` option for bulk loads which can be used to
        resume loading after an error.
-   The `push_failure_report` task will now by default hide failures
    that occurred due to the "Package Uninstalled" or "Salesforce
    Subscription Expired" errors, which are generally benign.
-   Fixed the check for newer CumulusCI versions to work around an issue
    with old `setuptools`.
-   Contributor change: We switched CumulusCI's own tests to run using
    `pytest`.
-   Internal change: We switched to the `cryptography` library for
    handling keychain encryption.

## 2.0.13 (2018-10-02)

-   Happy Spooky October! It's unlucky release 2.0.13, with some
    scary-cool improvements. Just to show you how ramped up our RelEng
    team is now, this release had TWENTY THREE pull requests in 12 days!
    From all four of your friendly SFDO Release Engineering committers.
    Thanks so much for continuing to use CCI for all your Salesforce
    automation needs.
-   NEW FLOW: ci_beta_dependencies installs the latest beta of project
    dependencies and run tests. Includes task error when running against
    non-scratch orgs.
-   NEW TASK: ReportPushFailures pulls a list of Package Push Upgrade
    Request failures after a push attempt, including grouping by
    important factors.
-   Issue a terminal "Bell" sound and attempt to display a macOS
    notification when a commandline task or flow completes.
-   Cleaned up python exception and error handling across the board, so
    that we can provide you, the user, with only the most relevant
    information. Try using CCI without setting your CUMULUSCI_KEY and
    see a simplified error message.
-   Fixed the utils for processing namespaces in package zip files to
    handle non-ASCII characters
-   The CONTRIBUTING.rst docs and Makefile have been updated to show how
    we release updates of CCI.
-   Skip beta releases when checking for a newer cumulusci version
-   When using the strip_namespace option on deployments, we now log
    which files had changes made before deploying.
-   Going Out: the SFDXDeploy and SFDXJsonPollingTasks have been
    removed, as they didn't work.
-   Going Out: Use the safe_load() method when loading YAML instead of
    the naive load(). If you relied on executing code in your CCI YAML
    file parsing, that will no longer work.

## 2.0.12 (2018-09-20)

-   Fixed apexdoc URL
-   Fixed [](update-admin-profile) to set any existing record
    type defaults to false before setting new defaults.
-   Fixed deployment of -meta.xml files containing non-ASCII characters.
-   Updated the robot selector for "Click Modal Button" to work for
    modals opened by a Quick Action.

## 2.0.11 (2018-09-14)

-   [](update-admin-profile) now uses xml parsing instead of
    string replacement for more targeted editing of Admin.profile to fix
    issues with deploying record types via dependencies
-   Projects can declare a dependency on a minimum version of cumulusci
    by specifying [minimum_cumulusci_version]{.title-ref} in
    cumulusci.yml

## 2.0.10 (2018-09-13)

-   [](update-admin-profile) task now sets application and tab
    visibility and supports setting record type visibility and default
    via the new [](record-types) task option
-   Restructured exceptions to include two new parent exceptions useful
    in client implementations:
    -   CumulusCIFailure: Used to signify a failure rather than an
        error, such as test or metadata deployment failures
    -   CumulusCIUsageError: Use to signify a usage error such as
        accessing a task that does not exist
-   [](execute-anon) task now accepts either
    [apex]{.title-ref} (string) or [path]{.title-ref} (Apex in a local
    file) for the Apex to execute. Also, the [managed]{.title-ref} and
    [namespaced]{.title-ref} options allow injecting namespace prefixes
    into the Apex to be executed.
-   New flow [retrieve_scratch]{.title-ref} can be used to retrieve
    declarative changes from a scratch org into the src/ directory

## 2.0.9 (2018-09-10)

-   Make robot commands use new lightning URLs
-   Remove unused filter_name arg from Go to Record Home robot keyword.
-   Fix metadata map for Settings.

## 2.0.8 (2018-08-21)

-   Flows that are executed from within another flow now support
    task-level control flow.
-   We no longer support the undocumented ability for a Flow to provide
    its own class_path.
-   Use the connected app details to set a client name on HTTP requests
    to Salesforce.

## 2.0.7 (2018-08-16)

-   [cci service show]{.title-ref} has been renamed [cci service
    info]{.title-ref}!
-   Update default API version in the base YAML to v43.0.
-   Doc updates in the tutorial, thanks to \@justindonnaruma!
-   Significant refactor of the cli module, including a bunch of small
    usability and exception handling changes. See
    <https://github.com/SFDO-Tooling/CumulusCI/pull/708> for details.
-   Display the file name for error causing files in more cases.
-   Strip packageVersions tags from aura/, components/, and pages/
    metadata.
-   Update PyYAML dependency.

## 2.0.6 (2018-08-07)

-   In Robot tests that use the standard keyword for interacting with a
    lookup field, we now wait for all AJAX requests to complete before
    submitting.
-   Add unit tests for large sections of the library.
-   We now support Flow, DuplicateRule, and other new Metadata types
    thanks to \@carlosvl.
-   Fixed refreshing oauth token when deploying metadata to persistent
    orgs.

## 2.0.5 (2018-08-01)

-   Fixes ##695: Update InstallPackageZipBuilder to set activateRSS to
    unblock installs.

## 2.0.4 (2018-07-30)

-   Fixes ##611: Scratch org operations were failing on Windows
-   Fixes ##664: Scratch org aliases incorrectly included double quotes
    in the alias name

## 2.0.3 (2018-07-27)

-   Added support for waiting on Aura HTTP Requests to complete after a
    browser action is performed in selenium from the Robot Salesforce
    Library:
    <http://cumulusci.readthedocs.io/en/latest/robotframework.html#waiting-for-lightning-ui>
-   Github API client will now automatically retry on 502 errors
-   Better error messages from parsing errors during package.xml
    generation which show the file causing the error

## 2.0.2 (2018-06-06)

-   Bugfix: Update InstallPackageZipBuilder to use a recent api version
    to unblock installs.

## 2.0.1 (2018-06-06)

-   Bugfix: Allow passing a connected app directly to
    OrgConfig.refresh_oauth_token.

## 2.0.0 (2018-06-01)

After over 19 months of development as alpha (40 version over 3 months)
and beta (98 releases over 16 months) releases and over a year running
production builds using CumulusCI, it's time to remove the "beta"
label.

This marks the first production release of CumulusCI 2.x!

## 2.0.0-beta99 (2018-05-31)

-   Ensure that github credentials are never shown in the log for github
    dependencies with unmanaged metadata

## 2.0.0-beta98 (2018-05-31)

**WARNING: This release introduces breaking changes to the syntax for
flow definitions and to the default flows. If you customized any of the
default flows in your project or have defined custom flows, you will
need to modify your cumulusci.yml file to work with this release.**

Changes default flows shipped with CumulusCI to a new syntax and
structure taking advantage of the ability for flows to call other flows.
This allows flows to be modularized in ways that weren't possible when
the original set of flows was designed.

-   The **tasks:** section in cumulusci.yml for a flow is now renamed to
    **steps:** A **FlowConfigError** will be raised if an old style flow
    definition is detected. All existing flow customizations and custom
    flows need to be changed in the **cumulusci.yml** to avoid raising
    an exception.

-   All default flows have been restructured. Existing customizations of
    default flows likely need to be changed to adapt to the new
    structure. In most cases, you will want to move your customizations
    to some of the new **config\_**\* or **deploy\_**\* instead of the
    main flows.

-   **ci_beta_install** has been removed and replaced with
    **install_beta** and **uninstall_managed** **install_beta** does not
    attempt to uninstall an existing version of the package. If you need
    to uninstall the package first, use the **uninstall_managed** flow
    before running **install_beta**

-   Added new **qa_org** flow to allow different configurations for dev
    vs QA orgs

-   New modularized flows structure allows for easier and more reusable
    customization:

    > -   **dependencies** Runs the pre-package deployment dependency
    >     tasks **update_dependencies** and **deploy_pre** This flow is
    >     called by almost all the main flows.
    > -   **config\_**\* flows provide a place to customize the package
    >     configuration for different environments. These flows are
    >     called by the main flows after the package metadata is
    >     deployed or a managed version is installed. Customizations to
    >     the config flows automatically apply to the main flows.
    >
    >     > -   **config_apextest** Configure org for running apex tests
    >     > -   **config_dev** Configure org for dev use
    >     > -   **config_managed** Configure org with a managed package
    >     >     version installed
    >     > -   **config_packaging** Configure the packaging org
    >     > -   **config_qa** Configure org for QA use
    >
    > -   **deploy\_**\* flows provide a place to customize how metadata
    >     deployments are done. The deploy flows do more than just a
    >     simple deployment such as unscheduling scheduled jobs,
    >     rebuilding the package.xml, and incrementally deleting any
    >     stale metadata in the package from the org.
    >
    >     > -   **deploy_unmanaged** Used to do a standard deployment of
    >     >     the unmanaged metadata
    >     > -   **deploy_packaging** Used to deploy to packaging. Wraps
    >     >     the **create_managed_src** task around the deploy to
    >     >     inject metadata that can only be deployed to the
    >     >     packaging org
    >     > -   **deploy_unmanaged_ee** Used to deploy unmanaged
    >     >     metadata to an Enterprise Edition org using the
    >     >     **create_unmanaged_ee_src** task

-   **github** dependencies can now point to a private Github
    repository. All zip downloads from Github will pass the password
    (should be a personal access token) from the **github** service
    configured in the CumulusCI keychain.

-   **GithubRelease**, **PushUpgradeRequest**, and
    **PackageUploadRequest** now track the release data as return values

## 2.0.0-beta97 (2018-05-31)

-   Salesforce Connected App is now a CCI Service! Instead of using [cci
    org config_connected_app]{.title-ref} you can use the familiar [cci
    service]{.title-ref} commands.
-   Better error handling when running commands without specifying a
    default org (thanks \@topherlandry)
-   Fix issue where scratch org password may become outdated
-   Improve Robot test runner task to use the already configured CCI
    environment instead of trying to create a new one.
-   Enable Robot testing in Headless Chrome on Heroku.
-   Address Python3 print statement issues.
-   Add LogLine task class to log statements and variables.
-   Add PassOptionAsResult, PassOptionAsReturnValue to pass options
    around in Flows.
-   Further extended the Flow runner subclass API.

## 2.0.0-beta96 (2018-05-18)

-   Fixes for CumulusCI on Windows - CumulusCI 2 now supports Windows
    environments!
-   Support skipping scratch org password creation by specifying
    [--no-password]{.title-ref} to [cci org scratch]{.title-ref}
-   Add additional logging to PackageUpload

## 2.0.0-beta95 (2018-05-10)

-   Add pytz to requirements

## 2.0.0-beta94 (2018-05-10)

-   Support added for nested flows. Specify a flow instead of a task
    inside another flow in cumulusci.yml

-   Add new task github_release_report to report info from GitHub
    release notes

-   Add new flow dev_deploy for minimal deploy (tasks: unschedule_jobs,
    deploy)

-   Enhance BaseFlow to be more easily subclassed/overridden/observed.
    Preserves task step number and adds several hook methods for
    subclasses (\_pre_task, \_post_task, \_post_task_exception)

-   Refactor github_release_notes task to use github3.py instead of calling the GitHub API directly. Includes these minor changes to functionality:

    : - Cannot create release with this task (use
    github_create_release instead) - Merge existing release notes even when not publishing

-   Fix issue that caused duplicate entries in the dependency tree

-   Sort output of os.listdir in all occurrences. Guarantees ordered
    iteration over files on disk

-   Validate CUMULUSCI_KEY value and raise more helpful exceptions if
    invalid

## 2.0.0-beta93 (2018-04-20)

-   Fix issue in command task for Windows
-   Support interactive in command task (thanks Chris Landry!)
-   Search more pull requests (100 vs 30) when generating release notes
-   Add options to Apex documentation generator task

## 2.0.0-beta92 (2018-04-04)

-   Ignore OWNERS file in package.xml generation
-   Pipe stderr in command tasks

## 2.0.0-beta91 (2018-04-03)

-   Fix issue in ZIP functionality for Windows

## 2.0.0-beta90 (2018-03-26)

-   Include missing scratch_def.json template file needed by cci project
    init

## 2.0.0-beta89 (2018-03-23)

-   Improved cci project init

    : - Prompt for extending a repository with HEDA and NPSP as
    selectable options - Use jinja2 templates included with cumulusci to create files - Include a default Robot test

-   update_package_xml now ignores CODEOWNERS files used by Github

-   Fixed an import error for click in cci

## 2.0.0-beta88 (2018-03-20)

-   Fix issue in parsing version from tag name

## 2.0.0-beta87 (2018-03-15)

-   Fix issue in getting latest version

## 2.0.0-beta86 (2018-03-13)

-   Initial Integration with Robot Framework (see here for details:
    <http://cumulusci.readthedocs.io/en/latest/robotframework.html>)
-   Add support for GlobalValueSetTranslation Metadata Type (thanks
    Christian Szandor Knapp!)
-   Use Tooling API for PackageUploadRequest
-   New doc "Why CumulusCI?"
-   Add documentation for the skip option on GitHub dependencies

## 2.0.0-beta85 (2018-02-21)

-   Support bigobject index element in .object
-   Only run meta.xml file cleaning on classes/\* and triggers/\*
    directory
-   Add docs on CumulusCI Flow
-   Add reference to needing the Push API to run release_beta in
    tutorial doc

## 2.0.0-beta84 (2018-02-12)

-   Add new Status 'Queued' to PackageUploadRequest check

## 2.0.0-beta83 (2018-02-08)

-   Add a sleep in between successful PackageUploadRequest and querying
    for MetadataPackageVersion to address issue in Spring '18 packaging
    orgs.

## 2.0.0-beta82 (2018-02-02)

-   Update salesforce-bulk package to version 2.0.0
-   Fix issue in bulk load data task

## 2.0.0-beta81 (2018-01-18)

-   Filter SObjects by record type in bulk data retrieve
-   Fix issue in removing XML elements from file

## 2.0.0-beta80 (2018-01-08)

-   The deploy tasks now automatically clean all meta.xml files in the deployed metadata of any namespace references by removing the \<packageVersions\> element and children. This allows CumulusCI to fully manage the dependencies and avoids the need for new commits to change referenced versions in meta.xml files.

    : - The default functionality can be disabled with the by
    setting [clean_meta_xml]{.title-ref} to False

-   Github dependencies can now point to a specific tag in the
    repository. The tag is used to determine the version to install for
    the dependency if the repository has a namespace configured and will
    be used to determine which unpackaged metadata to deploy.

## 2.0.0-beta79 (2017-11-30)

-   Fixes ##540: Using a custom [prefix_beta]{.title-ref} fails if
    releases with the same version but different prefix already exist in
    the repository. Changed to use [tag_name]{.title-ref} instead of
    [name]{.title-ref} to check if the release already exists in Github.

## 2.0.0-beta78 (2017-11-22)

Resolving a few issues from beta77:

-   A bug in BaseKeychain.create_scratch_org was causing the creation of
    ScratchOrgConfig's with a days value of None. This caused issues
    with subsequent calls against the org.
-   Fixed output from new logging in namespace injection
-   Switch to using org_config.date_created to check if an org has been
    created
-   Fix bug in recreation of an expired scratch org

## 2.0.0-beta77 (2017-11-22)

-   New Salesforce DX tasks: [](dx-convert-from),
    [](dx-convert-to), [](dx-pull), and
    [](dx-push)
-   New flow for creating production releases (use with caution!):
    [](release-production)
-   Scratch org configs can now specify [days]{.title-ref} as an option
    which defaults to 1. The default for a scratch config can be
    overridden in [cci org scratch]{.title-ref} with the [--days
    N]{.title-ref} option
-   [cci org remove]{.title-ref} will now attempt to first delete a
    scratch org if one was already created
-   [cci org scratch]{.title-ref} will prevent you from overwritting a
    scratch config that has already created a scratch org (which would
    create an orphaned scratch org) and direct you to use [cci org
    remove]{.title-ref} instead.
-   [cci org list]{.title-ref} now shows the duration days, elapsed
    days, and if an org is expired.
-   [cci org info]{.title-ref} now shows the expiration date for scratch
    orgs
-   All [cci]{.title-ref} commands that update an org config will now
    attept to automatically recreate an expired scratch org
-   New namespace inject token strings are supported for injecting
    namespaces into Lightning Component references:
    -   **%%%NAMESPACE_OR_C%%%**\*: Replaced with either
        'your_namespace' (unmanaged = False) or 'c' (unmanaged =
        True)
    -   **%%%NAMESPACED_ORG_OR_C%%%**\*: Replaced with either
        'your_namespace' (namespaced_org = True) or 'c'
        (namespaced_org = False)
-   Deleted all tasks and code related to [apextestsdb]{.title-ref}
    since its functionality is now integrated into MetaCI and no longer
    used

## 2.0.0-beta76 (2017-11-14)

-   Fix bug in namespace injection
-   Add option to print org info as JSON

## 2.0.0-beta75 (2017-11-07)

-   Fix syntax for github dependency with [--extend]{.title-ref} option
    on [cci project init]{.title-ref}

## 2.0.0-beta74 (2017-11-07)

-   Default to Salesforce API version 41.0

## 2.0.0-beta73 (2017-11-07)

-   Fix bug in creating the [dev_namespaced]{.title-ref} scratch org
    config from [cci project init]{.title-ref}

## 2.0.0-beta72 (2017-11-06)

-   Fix bug in setting namespace from [cci project init]{.title-ref}

## 2.0.0-beta71 (2017-11-06)

-   Update docs, including tutorial for Windows (thanks Dave Boyce!)
-   Add missing "purge on delete" option for BaseUninstallMetadata
-   Fix crash when decoding certain strings from the Metadata API
    response
-   Add support for featureParameter\* metadata types (thanks Christian
    Szandor Knapp!)

## 2.0.0-beta70 (2017-10-30)

-   Fix issue in zip file processing that was introduced in v2.0.0b69

## 2.0.0-beta69 (2017-10-27)

-   cumulusci.core has been made compatible with Python 3!
-   [cci project init]{.title-ref} has been upgraded
    -   Better prompt driven user experience with explanations of each
        prompt
    -   [--extend \<repo_url\>]{.title-ref} option to set up a
        recursive dependency on another CumulusCI project's Github
        repository
    -   Creates [sfdx-project.json]{.title-ref} if it doesn't already
        exist
    -   Creates and populates the [orgs/]{.title-ref} directory if it
        does not already exist. The directory is populated with starter
        scratch org shape files for the 4 main scratch org configs in
        CumulusCI: [beta.json]{.title-ref}, [dev.json]{.title-ref},
        [feature.json]{.title-ref}, [release.json]{.title-ref}
-   Fix issue with namespace injection
-   [push\_\*]{.title-ref} tasks now accept [now]{.title-ref} for the
    [start_time]{.title-ref} option which will start the push upgrade
    now (technically 5 seconds from now but that's better than 5
    minutes).

## 2.0.0-beta68 (2017-10-20)

-   Configure [namespace_inject]{.title-ref} for
    [deploy_post_managed]{.title-ref}

## 2.0.0-beta67 (2017-10-20)

-   Fix bug where auto-created scratch orgs weren't getting the
    [scratch]{.title-ref} attribute set properly on their
    [ScratchOrgConfig]{.title-ref} instance.

## 2.0.0-beta66 (2017-10-20)

-   Configure [namespace_inject]{.title-ref} for
    [](deploy-post)
-   Fix the [--debug]{.title-ref} flag on [cci task run]{.title-ref}
    and [cci flow run]{.title-ref} to allow debugging of exceptions
    which are caught by the CLI such as MetadataApiError,
    MetadataComponentError, etc.

## 2.0.0-beta65 (2017-10-18)

### Breaking Changes

-   If you created custom tasks off of [DeployNamespaced]{.title-ref} or
    [DeployNamespacedBundles]{.title-ref}, you will need to switch to
    using [Deploy]{.title-ref} and [DeployBundles]{.title-ref}. The
    recommended configuration for such custom tasks is represented
    below. In flows that need to inject the actual namespace prefix,
    override the [unmanaged]{.title-ref} option .. :

        custom_deploy_task:
            class_path: cumulusci.tasks.salesforce.Deploy
            options:
                path: your/custom/metadata
                namespace_inject: $project_config.project__package__namespace
                unmanaged: False

### Enhancements

-   The [cci]{.title-ref} CLI will now check for new versions and print
    output at the top of the log if a new version is available
-   The [cci]{.title-ref} keychain now automatically creates orgs for
    all named scratch org configs in the project. The orgs are created
    with the same name as the config. Out of the box, CumulusCI comes
    with 4 org configs: [dev]{.title-ref}, [feature]{.title-ref},
    [beta]{.title-ref}, and [release]{.title-ref}. You can add
    additional org configs per project using the [orgs]{.title-ref} -\>
    [scratch]{.title-ref} section of the project's
    [cumulusci.yml]{.title-ref}. With this change, [cci org
    list]{.title-ref} will always show at least 4 orgs for any project.
    If an org already exists in the keychain, it is not touched and no
    scratch org config is auto-created for that config. The goal is to
    eliminate the need to call [cci org scratch]{.title-ref} in most
    cases and make it easier for new users to get up and running with
    scratch orgs and CumulusCI.
-   [cci org remove \<org_name\>]{.title-ref} is now available to remove
    orgs from the keychain
-   Scratch orgs created by CumulusCI are now aliased using the naming
    format [ProjectName\_\_org_name]{.title-ref} so you can easily run
    sfdx commands against scratch orgs created by CumulusCI
-   [cci org list]{.title-ref} now shows more information including
    [scratch]{.title-ref}, [config_name]{.title-ref}, and
    [username]{.title-ref}. NOTE: config_name will only be populated for
    newly created scratch configs. You can use [cci org
    scratch]{.title-ref} to recreate the config in the keychain.
-   The new flow [](dev-org-namespaced) provides a base flow
    for deploying unmanaged metadata into a namespaced org such as a
    namespaced scratch org
-   All tasks which previously supported [namespace_inject]{.title-ref}
    now support a new option, [namespaced_org]{.title-ref}. This option
    is designed to handle use cases of namespaced orgs such as a
    namespaced scratch org. In namespaced orgs, all unmanaged metadata
    gets the namespace prefix even if it is not included in the package.
    You can now use the [namespaced_org]{.title-ref} option along with
    the file content token [%%%NAMESPACED_ORG%%%]{.title-ref} and the
    file name token [\_\_\_NAMESPACED_ORG\_\_\_]{.title-ref} to inject
    the namespace when deploying to a namespaced org.
    [namespaced_org]{.title-ref} defaults to False to be backwards
    compatible with previous functionality.
-   New task [](push-list) supports easily pushing a list of
    OrgIds via the Push API from the CLI: [cci task run push_list -o
    file \<file_path\> -o version 1.2 --org packaging]{.title-ref}

## 2.0.0-beta64 (2017-09-29)

-   Show proper exit status for failed tests in heroku_ci.sh
-   Handle BrowserTestFailure in CLI
-   Fix issue that prevented auto-merging master to parent branch

## 2.0.0-beta63 (2017-09-26)

-   Documentation has been updated!
-   CumulusCI now supports auto detection of repository information from
    CI environments. This release includes an implementation for Heroku
    CI

## 2.0.0-beta62 (2017-09-19)

-   cci now supports both namespaced and non-namespaced scratch org
    configurations in the same project. The default behavior changes
    slightly with this release. Before, if the
    [sfdx-project.json]{.title-ref} had a namespace configured, all
    scratch orgs created via [cci org scratch]{.title-ref} would get the
    namespace. With the new functionality, all orgs would by default not
    have the namespace. You can configure individual org configs in your
    project's [cumulusci.yml]{.title-ref} file by setting [namespace:
    True]{.title-ref} under [orgs -\> scratch -\>
    \<org_name\>]{.title-ref}

## 2.0.0-beta61 (2017-09-12)

-   Fix bug that was causing a forced token refresh with [sfdx
    force:org:open]{.title-ref} at the start of a flow or task run
    against a freshly created scratch org.
-   Add support for Big Objects with [\_\_b]{.title-ref} suffix in
    [](update-package-xml) and
    [](update-package-xml-managed)
-   Fix bug that caused release notes sections to not render if only h2
    content found

## 2.0.0-beta60 (2017-09-06)

-   Add support for Platform Events with [\_\_e]{.title-ref} suffix in
    [](update-package-xml) and
    [](update-package-xml-managed)

## 2.0.0-beta59 (2017-09-06)

-   [YamlProjectConfig]{.title-ref} can now accept an
    [additional_yaml]{.title-ref} keyword argument on initialization.
    This allows a 5th level of layering to the
    [cumulusci.yml]{.title-ref} config. This change is not wired up to
    the CLI yet but is available for application built on top of
    cumulusci to use.
-   [cumulusci.core.flow]{.title-ref} and
    [cumulusci.core.keychain]{.title-ref} now have 100% test coverage

## 2.0.0-beta58 (2017-08-29)

-   Fix import error in []github-release-notes() task
    introduced in beta57

## 2.0.0-beta57 (2017-08-28)

-   Task options can now dynamically reference attributes from the
    project_config using the syntax
    [\$project_config.attr_name]{.title-ref}. For example,
    [\$project_config.repo_branch]{.title-ref} will resolve to the
    current branch when the task options are initialized.
-   New task [github_parent_to_children]{.title-ref} uses new
    functionality in [MergeBranch]{.title-ref} to support merging from a
    parent feature branch (ex. [feature/parent]{.title-ref}) into all
    child branches (ex. [feature/parent\_\_child]{.title-ref}).
-   [](github-master-to-feature) task will now skip child
    branches if their corresponding parent branch exists
-   [](ci-feature) flow now runs
    [github_parent_to_children]{.title-ref} at the end of the flow
-   Github task classes were restructured but the
    [class_path]{.title-ref} used in [cumulusci.yml]{.title-ref} remains
    the same
-   New test coverage for github tasks

## 2.0.0-beta56 (2017-08-07)

-   Add stderr logging to scratch org info command

## 2.0.0-beta55 (2017-08-07)

-   Fix API version issue in Apex test runner

## 2.0.0-beta54 (2017-08-04)

-   Fix issue in parsing test failure details when org has objects that
    need to be recompiled.

## 2.0.0-beta53 (2017-08-04)

-   Fix "cci org config_connected_app" for Windows
-   Update tutorial for Windows usage
-   Reverse pull request order for release notes

## 2.0.0-beta52 (2017-08-02)

-   Release notes parsers now specified in cumulusci.yml

## 2.0.0-beta51 (2017-08-01)

-   New task to commit ApexDoc output
-   New test runner uses Tooling API to get limits data

## 2.0.0-beta50 (2017-07-18)

-   Fix handling of boolean command line args

## 2.0.0-beta49 (2017-07-10)

-   New task [](batch-apex-wait) allows pausing until an Apex
    batch job completes. More details at
    <https://github.com/SFDO-Tooling/CumulusCI/pull/372>
-   SalesforceBrowserTest task now accepts [extra]{.title-ref} argument
    for specifying extra command line arguments separate from the
    command itself
-   Resolved ##369: Scratch org tokens expiring after upgrade to SFDX
    beta

## 2.0.0-beta48 (2017-06-28)

-   Upgraded to the Salesforce DX Beta (thanks to \@Szandor72 for the
    contribution!)
    -   NOTE: CumulusCI will no longer work with the sfdx pilot release
        after this version!
    -   Replaced call to [force:org:describe]{.title-ref} with
        [force:org:display]{.title-ref}
    -   Changed json response parsing to match beta format
-   New SFDX wrapper tasks
    -   \`SFDXBaseTask\`: Use for tasks that don't need org access
    -   \`SFDXOrgTask\`: Use for sfdx tasks that need org access. The
        task will refresh the cci keychain org's token and pass it to
        sfdx as the target org for the command
    -   \`SFDXJsonTask\`: Use for building tasks that interact with sfdx
        via json responses
    -   \`SFDXJsonPollingTask\`: Use for building tasks that wrap sfdx
        json responses including polling for task completion
    -   \`SFDXDeploy\`: An example of using
        [SFDXJsonPollingTask]{.title-ref} to wrap
        [force:mdapi:deploy]{.title-ref}
-   Fixed infinite loop if setting scratch org password fails

## 2.0.0-beta47 (2017-06-26)

-   Fix typo in tasks.util

## 2.0.0-beta46 (2017-06-23)

-   Fix bug in implementation of the [--no-prompt]{.title-ref} flag
    when sentry is configured

## 2.0.0-beta45 (2017-06-23)

-   The new [BaseSalesforceApiTask]{.title-ref} class replaces
    [BaseSalesforceApiTask]{.title-ref},
    [BaseSalesforceBulkApiTask]{.title-ref}, and
    [BaseSalesforceToolingApiTask]{.title-ref} by combining them into a
    single task class with access to all 3 API's via
    [self.sf]{.title-ref}, [self.tooling]{.title-ref}, and
    [self.bulk]{.title-ref} from inside a task instance.
-   Added integration with sentry.io
    -   Use [cci service connect sentry]{.title-ref} to enable the
        sentry service
    -   All task execution exceptions will be logged as error events in
        sentry
    -   [cci task run]{.title-ref} and [cci flow run]{.title-ref} will
        now show you the url to the sentry event if one was registered
        and prompt to open in a browser.
    -   [cci task run]{.title-ref} and [cci flow run]{.title-ref} now
        accept the [--no-prompt]{.title-ref} option flag for running in
        non-interactive mode with the sentry service configured. Use
        this if you want to log build errors in sentry but not have
        builds fail due to a hanging prompt.
-   If a scratch org password has expired, it is now regenerated when
    calling [cci org info]{.title-ref}
-   New task [](unschedule-apex) was added to unschedule
    background jobs and added to the start of the [dev_org]{.title-ref}
    flow
-   [](update-meta-xml) task now uses the project's
    dependencies as the namespace/version to update in the meta.xml
    files
-   The bulkdata mapping now properly supports Record Types
-   Fixed a bug with BulkDataQuery where local references weren't
    getting properly set
-   New CumulusCI Branch & Release Overview diagram presention is
    available at
    <http://developer.salesforce.org/CumulusCI/diagram/process_overview.html>
    Use left/right arrow buttons on your keyboard to navigate through
    the presentation.
-   CumulusCI is now being built by Heroku CI using the config in
    [app.json]{.title-ref}

## 2.0.0-beta44 (2017-06-09)

-   Fix issue in [](update-dependencies) when a github
    dependency depends on another github dependency

## 2.0.0-beta43 (2017-06-09)

-   Fix issue in [mrbelvedere_publish]{.title-ref} where the new zip_url
    dependencies weren't being skipped

## 2.0.0-beta42 (2017-06-09)

-   Move github dependency resolution logic into
    project_config.get_static_dependencies() for reuse in tasks other
    than UpdateDependencies
-   Fixed the mrbelvedere_publish task when using github references
-   Improved output from parsing github dependencies
-   Fix issue in [BulkDataQuery]{.title-ref} character encoding when
    value contains utf8 special characters

## 2.0.0-beta41 (2017-06-07)

-   The [dependencies]{.title-ref} section in cumulusci.yml now supports
    the [skip]{.title-ref} option for Github dependencies which can be
    used to skip specific subfolders under [unpackaged/]{.title-ref} in
    the target repository
-   New task class BulkDataQuery reverses the BulkDataLoad and uses the
    mapping to build SOQL queries to capture the data in the mapping
    from the target org. The data is written to a database that can then
    be used by BulkDataLoad to load into a different org.
-   The Delete util task now uses the glob library so it can support
    paths with wildcards like src/\*
-   New tasks [](meta-xml-api) and
    [](meta-xml-dependencies) handle updating
    [\*-meta.xml]{.title-ref} files with api versions or underlying
    package versions.

## 2.0.0-beta40 (2017-06-03)

-   More enhancements to [](update-dependencies) including the
    ability to handle namespace injection, namespace stripping, and
    unmanaged versions of managed repositories. See the new doc at
    <http://cumulusci.readthedocs.io/en/latest/dependencies.html>

## 2.0.0-beta39 (2017-06-02)

-   Fix new bug in [](update-dependencies) which caused
    failure when running against an org that already has a required
    package installed

## 2.0.0-beta38 (2017-06-01)

-   [](update-dependencies) now properly handles references to
    a github repository that itself contains dependencies in its
    cumulusci.yml file
-   [](update-dependencies) now handles deploying unmanaged
    metadata from subfolders under unpackaged/pre of a referenced Github
    repository
-   The [dependencies]{.title-ref} section of
    [cumulusci.yml]{.title-ref} now supports installing from a zip of
    metadata hosted at a url if you provide a [zip_url]{.title-ref} and
    optionally a [subfolder]{.title-ref}

## 2.0.0-beta37 (2017-06-01)

-   [](update-dependencies) now supports dynamically
    referencing other Github repositories configured with a
    cumulusci.yml file. The referenced repository's cumulusci.yml is
    parsed and the dependencies are included. Also, the Github API is
    used to find the latest release of the referenced repo if the
    cumulusci.yml has a namespace configured. Welcome to dynamic package
    dependency management ;)
-   [cci task run]{.title-ref} now supports the option flags
    [--debug-before]{.title-ref} and [--debug-after]{.title-ref}
-   Fix for JUnit output rendering in run_tests

## 2.0.0-beta36 (2017-05-19)

-   Flows can now accept arguments in the CLI to override task options
    -   [cci flow run install_beta -o install_managed_beta\_\_version
        "1.0 (Beta 123)"]{.title-ref}
-   Flows can now accept arguments to in the CLI to skip tasks
    -   [cci flow run ci_feature --skip run_tests_debug --skip
        deploy_post]{.title-ref}
-   Anonymous apex failures will now throw an exception and fail the
    build in [](execute-anon)
-   Fixes ##322: local variable 'message' referenced before assignment

## 2.0.0-beta35 (2017-05-19)

-   New task [](execute-anon) is available to run anonymous
    apex and takes the extra task option [apex]{.title-ref}

## 2.0.0-beta34 (2017-05-16)

-   Fixes ##317: ERROR: Invalid version specified

## 2.0.0-beta33 (2017-05-11)

-   cci org connect and cci org scratch now accept the --default option
    flag to set the newly connected org as the default org for the repo
-   cci org scratch now accepts a new option, --devhub \<username\>,
    which allows you to specify an alternate devhub username to use when
    creating the scratch org
-   The SalesforceBrowserTest class now throws a BrowserTestFailure if
    the command returns an exit status of 1
-   Scratch org creation no longer throws an exception if it fails to
    set a random password on the newly created org
-   Push API task enhancements:
    -   Push org lists (text files with one org ID per line) can now
        have comments and blank lines. The first word on the line is
        assumed to be the org ID and anything after that is ignored.
    -   Fixes ##294
    -   Fixes ##306
    -   Fixes ##208

## 2.0.0-beta32 (2017-05-04)

-   Scratch orgs now get an auto-generated password which is available
    via [cci org info]{.title-ref}
-   Added metadata mapping for StandardValueSets to fix ##310
-   Throw nicer exceptions when scratch org interaction fails

## 2.0.0-beta31 (2017-04-12)

-   Use UTC for all Salesforce API date/time fields
-   Fix issue with listing metadata types
-   Add generic polling method to BaseTask

## 2.0.0-beta30 (2017-04-04)

-   New task list_metadata_types
-   \[push upgrades\] Fix push request status Cancelled --\> Canceled
-   \[push upgrades\] Fix datetime namespace issues
-   \[pyinstaller\] Import project-level modules with run-time hook

## 2.0.0-beta29 (2017-04-04)

-   Report push status if start time is less than 1 minute in the future

## 2.0.0-beta28 (2017-03-30)

-   Fix bug in Push API batch retry logic introduced in beta25

## 2.0.0-beta27 (2017-03-29)

-   Skip org in push if statusCode is UKNOWN_EXCEPTION

## 2.0.0-beta26 (2017-03-29)

-   Fixes ##278: Push upgrade raises exception for DUPLICATE_VALUE
    statusCode

## 2.0.0-beta25 (2017-03-28)

-   Fixes ##277: Push API tasks now correctly handle errors in individual
    orgs in a batch when scheduling a push job

## 2.0.0-beta24 (2017-03-27)

-   Fixes ##231: Handle unicode in package.xml generation
-   Fixes ##239: Replace fix for windows path issues from beta23 with a
    better implementation
-   Fixes ##275: Properly pass purge_on_delete option value in
    uninstall_packaged_incremental

## 2.0.0-beta23 (2017-03-22)

-   Fixes ##239: Add local path to import path when looking up classes.
    This should fix an error that appeared only in Windows

## 2.0.0-beta22 (2017-03-20)

-   []github-release-notes() now supports the
    [link_pr]{.title-ref} option to add links to the pull request where
    each line of content came from
-   Fixes ##266: [](update-dependencies) now supports the
    [purge_on_delete]{.title-ref} option to allow running against
    production orgs
-   Fixes ##267: package.xml generation now skips RecordType when
    rendering in delete mode

## 2.0.0-beta21 (2017-03-17)

-   Fix parsing of OrgId from the access token using the new sfdx CLI

## 2.0.0-beta20 (2017-03-17)

-   Switch to using the [sfdx]{.title-ref} CLI for interacting with
    scratch orgs. If you use [cci]{.title-ref} with scratch orgs, this
    release will no longer work with the [heroku force:\*]{.title-ref}
    commands from the prior Salesforce DX release.
-   Upgrades to release notes generator
    -   Content is now grouped by subheading under each heading
    -   Better error message is thrown if a lightweight tag is found
        when an annotated tag is needed

## 2.0.0-beta19 (2017-03-15)

-   Fixes ##261: cci org info should refresh token first

## 2.0.0-beta18 (2017-03-14)

-   Skip deleting Scontrols in incremental delete
-   Escape package name when generating package.xml

## 2.0.0-beta17 (2017-03-14)

-   OrgConfig and subclasses now support self.username to get the
    username
-   Flows no longer have access to task instance attributes for
    subsequent task options. Instead, custom task classes should set
    their task return_values member.
-   Improve printing of org info when running tasks from a flow by only
    printing once at the start of flow. All tasks have an optional
    self.flow attribute now that contains the flow instance if the task
    is being run from a flow.
-   BaseTask now includes methods for handling retry logic. Implemented
    in the InstallPackageVersion and RunApexTests
-   New task [](retrieve-unpackaged) can be used to retrieve
    metadata from a package.xml manifest
-   Fixes ##240 - CumulusCI should now properly handle escaping special
    characters in xml where appropriate
-   Fixes ##245 - Show config values in task info
-   Fixes ##251 - ApiRetrieveUnpackaged \_clean_package_xml() can't
    handle metadata with spaces in names
-   Fixes ##255 - ApiListMetadata does not list certain metadata types
    with default folder value

## 2.0.0-beta16 (2017-02-17)

-   Allow batch size to be configured for push jobs with the
    [batch_size]{.title-ref} job

## 2.0.0-beta15 (2017-02-15)

-   Bug fix release for bug in [](update-admin-profile) from
    the beta 14 release changes to the ApiRetrieveUnpackaged class

## 2.0.0-beta14 (2017-02-15)

-   The new [RetrieveReportsAndDashboards]{.title-ref} task class that
    can retrieve all reports and dashboards from a specified list of
    folders
-   Documentation improvements contributed by \@tet3
-   Include userinfo in the OrgConfig, and print username and org id at
    the beginning of every task run. Contribution by \@cdcarter
-   [project_local_dir]{.title-ref} (e.g.,
    [\~/.cumulusci/NPSP-Extension-Template/]{.title-ref}, home of the
    encrypted keychain and local override config) now rely on the
    project name configured in cumulusci.yml instead of the existence of
    a git remote named origin. Contribution by \@cdcarter

## 2.0.0-beta13 (2017-02-09)

-   New services registration support added by community contribution
    from \@cdcarter
    -   Services and their schemas can now be defined in the
        cumulusci.yml file. See
        <https://github.com/SFDO-Tooling/CumulusCI/issues/224> for more
        details until docs are fully updated
    -   [cci services list]{.title-ref}
    -   [cci services show github]{.title-ref}
    -   [cci services connect github]{.title-ref}
-   Improved error handling for metadata deployment failures:
    -   Metadata deployments now throw more specific errors when
        appropriate: MetadataComponentFailure, ApexTestFailure, or
        MetadataApiError
    -   Output for each component failure on a deploy now includes more
        information such as the column number of the error
-   [](release-beta) now ignores errors in the
    []github-release-notes() process by default

## 2.0.0-beta12 (2017-02-02)

-   Throw better exceptions if there are failures creating or deleting
    scratch orgs

## 2.0.0-beta11 (2017-02-01)

-   Fixes and new functionality for
    [](update-package-xml-managed) task.
    -   Added support for project -\> package -\> name_managed in the
        cumulusci.yml file to specify a different package name to use
        when deploying to the packaging org.
    -   Fixed bug with install_class and uninstall_class handling

## 2.0.0-beta10 (2017-01-20)

-   Completed removed CumulusCI 1 code from the repository and egg. The
    egg should be 17MB smaller now.
-   Removed [cumulusci.tasks.ant.AntTask]{.title-ref}. Please replace
    any usage with [cumulusci.tasks.command.Command]{.title-ref} or
    [cumulusci.tasks.command.SalesforceCommand]{.title-ref}
-   Removed the [update_meta_xml]{.title-ref} task for now since it was
    the only task relying on Ant. A new and much better Python based
    implementation will be coming soon.

## 2.0.0-beta9 (2017-01-20)

-   A few upgrades to the Command task:
    -   No longer strip left side whitespace from output to preserve
        indentation
    -   New method [\_process_output]{.title-ref} can be overridden to
        change how output lines are processed
    -   New method [\_handle_returncode]{.title-ref} can be overridden
        to change how exit status is handled

## 2.0.0-beta8 (2017-01-19)

-   Added new task classes util.DownloadZip, command.SalesforceCommand,
    and command.SalesforceBrowserTestCommand that can be mapped in
    individual projects to configure browser tests or other commands run
    against a Salesforce org. The commands are automatically passed a
    refreshed [SF_ACCESS_TOKEN]{.title-ref} and
    [SF_INSTANCE_URL]{.title-ref} environment variables.
-   Added new CLI commands [cci project connect_saucelabs]{.title-ref}
    and [cci project show_saucelabs]{.title-ref}
-   Added [](ci-install-beta) flow that uninstalls the
    previous managed version then installs the latest beta without
    running apex tests
-   Added new method cumulusci.utils.download_extract_zip to download
    and extract a zip including re-rooting the zip to a subfolder.
-   All Salesforce tasks now delete any tempdirs they create to prevent
    wasting disk space

## 2.0.0-beta7 (2017-01-17)

-   [run_tests_debug]{.title-ref} now ignores all non-test methods
    including any method decorated with \@testSetup

## 2.0.0-beta6 (2017-01-17)

-   Return full info when a component failure occurs on a Metadata API
    deployment. Previously only the problem was shown without context
    like file name and line number making it difficult to figure out
    what caused the failure.
-   [run_tests_debug]{.title-ref} now ignores the \@testSetup method
    when parsing debug logs. Previously it would throw an error if tests
    used \@testSetup

## 2.0.0-beta5 (2017-01-16)

-   Fixes for the [](unmanaged-ee) flow to fix a bug where
    avialableFields elements were not properly being stripped from
    fieldsSets in .object files
-   Fixes for [](github-master-to-feature) where merge
    conflicts would throw exception rather than creating a pull request
    as expected

## 2.0.0-beta4 (2017-01-13)

-   Add [](update-admin-profile) to all flows that deploy or
    install to a Salesforce org. Note that this adjusted the task
    numbers in some flows so you should double check your project
    specific flow customizations.

## 2.0.0-beta3 (2017-01-13)

-   Remove `deploy-post-managed` task from the default
    [](ci-master) flow. Deploying the unpackaged/post content
    to the packaging org risks the spider accidentally including some of
    it in the package. Projects that want to run
    `deploy-post-managed` against the packaging org can
    extend [](ci-master) in their cumulusci.yml file to add
    it.

## 2.0.0-beta2 (2017-01-12)

-   Fix a bug in project_config.get_latest_version() with tags that
    don't match either the beta or release prefix.

## 2.0.0-beta1 (2017-01-12)

-   Move into the master branch!
-   Changed primary CLI command to [cci]{.title-ref} and left
    [cumulusci2]{.title-ref} available for legacy support
-   Changed all docs to use [cci]{.title-ref} command in examples
-   Peg push api tasks to api version 38.0 rather than project api
    version
-   Added 2 new flows: [](install-beta) and
    [](install-prod) which install the latest managed version
    of the package with all dependencies but without running tests
-   [](release-beta) flow now runs
    [](github-master-to-feature) at the end of the flow

## 2.0.0-alpha42 (2017-01-10)

-   Metadata API calls now progressively wait longer between each status
    check to handle calls with long Pending times. Each check also now
    outputs a line saying how long it will sleep before the next check.

## 2.0.0-alpha41 (2017-01-06)

-   Fix bug in [](uninstall-packaged-incremental) where the
    task would error out if no metadata was found to delete

## 2.0.0-alpha40 (2017-01-06)

-   [](uninstall-packaged-incremental) task now skips the
    deploy step if now metadata was found to be deleted

## 2.0.0-alpha39 (2017-01-06)

-   Two new task classes exist for loading and deleting data via Bulk
    API. Note that there are no default task mappings for these classes
    as the mappings should be project specific. Define your own mappings
    in your project's cumulusci.yml file to use them.
    -   **cumulusci.tasks.bulkdata.LoadData**: Loads relational data
        from a sqlite database into Salesforce objects using a yaml file
        for mapping
    -   **cumulusci.tasks.bulkdata.DeleteData**: Deletes all records
        from specified objects in order of object list
-   Added support for customPermissions
-   Added new Command task that can be used to call arbitrary commands
    with configurable environment variables

## 2.0.0-alpha38 (2016-12-28)

-   Scratch orgs now cache the org info locally during flow execution to
    prevent multiple calls out to the Heroku CLI that are unnecessary
-   Scratch org calls now properly capture and print both stdout and
    stderr in the case of an exception in calls to Heroku CLI
-   [run_tests_debug]{.title-ref} now deletes existing TraceFlag objects
    in addition to DebugLevels
-   Fix bug in [](push-all) and [](push-sandbox)
-   Push tasks now use timezone for start_date option

## 2.0.0-alpha37 (2016-12-20)

-   []github-release-notes() now correctly handles the
    situation where a merge commit's date can be different than the
    PR's merged_at date in Github by comparing commit sha's

## 2.0.0-alpha36 (2016-12-20)

-   [](github-release) now works with an existing tag/ref and
    sleeps for 3 seconds after creating the tag to allow Github time to
    catch up

## 2.0.0-alpha35 (2016-12-20)

-   Remove [draft]{.title-ref} option from [](github-release)
    since the Github API doesn't support querying draft releases

## 2.0.0-alpha34 (2016-12-20)

-   Fix bug with [](github-release) that was causing
    validation errors from Github

## 2.0.0-alpha33 (2016-12-20)

-   []github-release-notes() now raises an exception in
    [publish]{.title-ref} mode if the release doesn't exist instead of
    attempting to create it. Use [](github-release) to create
    the release first before calling []github-release-notes()
-   Fix a bug with dynamic task option lookup in flows

## 2.0.0-alpha32 (2016-12-19)

-   Move logger configuration out of core and into CLI so other
    implementations can provide their own logger configurations
-   Added [retry_interval]{.title-ref} and
    [retry_interval_add]{.title-ref} options to
    [](install-beta) to introduce a progressive delay between
    retry attempts when the package is unavailable

## 2.0.0-alpha30 (2016-12-13)

-   **IMPORANT** This release changes the yaml structure for flows. The
    new structure now looks like this:

        flows:
            flow_name:
                tasks:
                    1:
                        task: deploy
                    2:
                        task: run_tests

-   See the new flow customization examples in the cookbook for examples
    of why this change was made and how to use it:
    <http://cumulusci.readthedocs.io/en/latest/cookbook.html#custom-flows-via-yaml>

## 2.0.0-alpha30 (2016-12-12)

-   Bug fixes submitted by \@ccarter:
    -   [](uninstall-post) was failing to substitute
        namespaces
    -   new util method [findRename]{.title-ref} to rename files with a
        token in their name
-   Bug fix with Unicode handling in run_tests_debug

## 2.0.0-alpha29 (2016-12-12)

-   Require docutils to supprot rst2ansi

## 2.0.0-alpha28 (2016-12-12)

-   Modified tasks and flows to properly re-raise exceptions

## 2.0.0-alpha27 (2016-12-12)

-   [cci]{.title-ref} should now throw the direct exception rather than
    making it look like the exception came through click
-   [cci task doc]{.title-ref} command outputs RST format documentation
    of all tasks
-   New doc with info on all tasks:
    <http://cumulusci.readthedocs.io/en/latest/tasks.html>

## 2.0.0-alpha26 (2016-12-09)

-   Bug fix, missing import of re in core/config.py

## 2.0.0-alpha25 (2016-12-09)

-   Fixed run_tests and run_tests_debug tasks to fail throwing an
    exception on test failure
-   run_tests_debug now stores debug logs in a tempdir
-   Have the CLI handle ApexTestException events with a nicer error
    rather than a full traceback which isn't helpful to determining the
    apex failure
-   BaseMetadataApi will now throw MetadataApiError after a Failed
    status is set
-   BaseFlow now throws the original exception rather than a more
    generic one that obscures the actual failure

## 2.0.0-alpha24 (2016-12-09)

-   Bug fix release, flow_run in the CLI should accept debug argument
    and was throwing and error

## 2.0.0-alpha23 (2016-12-09)

-   [cci org browser]{.title-ref} now saves the org back to the
    keychain. This fixes an issue with scratch orgs where a call to org
    browser on a scratch org that hasn't been created yet gets created
    but doesn't persist after the command
-   [task run]{.title-ref} and [flow run]{.title-ref} now support the
    [--debug]{.title-ref} flag which will drop you into the Python
    interactive debugger (pdb) at the point of the exception.
-   Added Cookbook to the docs:
    <http://cumulusci.readthedocs.io/en/latest/cookbook.html>
-   [flow run]{.title-ref} with the [--delete-org]{.title-ref} option
    flag and scratch orgs no longer fails the flow if the delete org
    call fails.
-   Fixed the [](deploy-post) task which has having errors
    with namespaced file names
-   Fixed [](update-admin-profile) to properly update the
    profile. This involved fixing the utils [findReplace]{.title-ref}
    and [findReplaceRegex]{.title-ref}.
-   Reworked exceptions structure and ensure that tasks throw an
    exception where approriate.

## 2.0.0-alpha22 (2016-12-02)

-   Fix for bug in deploy_post when using the filename token to merge
    namespace into a filename

## 2.0.0-alpha21 (2016-12-01)

-   Added support for global and project specific orgs, services, and
    connected app. The global credentials will be used by default if
    they exist and individual projects an override them.
    -   Orgs still default to creating in the project level but the
        [--global]{.title-ref} flag can be used in the CLI to create an
        org
    -   [config_connected_app]{.title-ref} command now sets the
        connected app as global by default. Use the '--project' flag
        to set as a project override
    -   [connect_github]{.title-ref}, [connect_mrbelvedere]{.title-ref},
        and [connect_apextestsdb]{.title-ref} commands now set the
        service as global by default. Use the '--project' flag to set
        as a project override

## 2.0.0-alpha20 (2016-11-29)

-   Remove pdb from BaseFlow.\_\_call\_\_ (oops)

## 2.0.0-alpha19 (2016-11-29)

-   Fix IOError issue with update_admin_profile when using the egg
    version
-   Changed cci task_run and flow_run commands to no longer swallow
    unknown exceptions so a useful error message with traceback is shown
-   Centralized loggers for BaseConfig, BaseTask, and BaseFlow under
    cumulusci.core.logger and changed logs to always write to a temp
    file available as self.log_file on any config, task, or flow
    subclass.

## 2.0.0-alpha18 (2016-11-17)

-   New task [apextestsdb_upload]{.title-ref} uploads json test data to
    an instance of ApexTestsDB
-   Fixed bug in CLI when running tasks that don't require an org
-   Include mappings for Community Template metadata types in
    package.xml generator

## 2.0.0-alpha17 (2016-11-15)

-   Community contributions by \@cdcarter

    -   [](query) task using the Bulk Data API
    -   [--login-url]{.title-ref} option on [cci org
        connect]{.title-ref}

-   Salesforce DX wrapper

    -   NOTE: Requires developer preview access to Salesforce DX
    -   [cci org scratch \<config_name\> \<org_name\>]{.title-ref}
        creates a wrapper for a scratch org in your keychain
    -   Tasks and Flows run against a scratch org will create the
        scratch org if needed
    -   [cci org scratch_delete \<org_name\>]{.title-ref} deletes a
        scratch org that was created by running a task or flow
    -   [cci flow run]{.title-ref} now supports the
        [--delete-org]{.title-ref} option to delete a scratch org at
        the end of the flow
    -   [BaseSalesforceDXTask]{.title-ref} wraps the heroku force:\*
        commands. The [](dx-push) task is provided as an
        example.
        -   NOTE: Currently the command output is buffered and only
            outputs when the command completes.

-   Integration with mrbelvedere

    -   [](mrbelvedere-publish) task publishes a beta or
        release tag to an existing package on mrbelvedere

-   Flow changes

    > -   [](ci-feature) now runs tests as part of the flow
    > -   New flow task configuration [ignore_failure]{.title-ref} can
    >     be used to ignore a failure from a particular task in the flow

-   CUMULUSCI_KEY is no longer required if using a keychain class with
    the encrypted attribute set to False such as the
    EnvironmentProjectKeychain

-   Refactored OAuth token refresh to be more centralized and raise a
    proper exception if there is an issue

-   The org keychain now correctly uses the instance url when
    appropriate

-   Calls to runTestsAsynchronous in the Tooling API are now done via
    POST instead of GET

## 2.0.0-alpha16 (2016-11-3)

-   Fix bug in SOAP calls to MDAPI with newer versions of the requests
    library
-   This version was used to record the demo screencast:
    <https://asciinema.org/a/91555>

## 2.0.0-alpha15 (2016-11-3)

-   Fix CLI bug in new exception handling logic

## 2.0.0-alpha14 (2016-11-3)

-   Fix version number
-   Fix bug in BaseSalesforceBulkApiTask (thanks \@cdcarter)

## 2.0.0-alpha13 (2016-11-3)

-   Nicer log output from tasks and flows using
    [coloredlogs]{.title-ref}
-   Added handling for packed git references in the file
    .git/packed-refs
-   Docs now available at <http://cumulusci.readthedocs.io>
-   Tasks and Flows run through the CLI now show a more simple message
    if an exception is thrown

## 2.0.0-alpha12 (2016-11-2)

-   Automatic detection of latest production and beta release via Github
    Releases
    -   project_config.get_latest_release() added to query Github
        Releases to find the latest production or beta release version
    -   InstallPackage now accepts the virtual versions 'latest' and
        'latest_beta' as well as specific versions for the version
        option
-   New flows:
    -   ci_feature: Runs a full deployment of the unmanaged code for
        testing in a feature org
    -   ci_master: Runs a full deployment of the managed version of the
        code into the packaging org
    -   ci_beta: Installs the latest beta and runs all tests
    -   ci_release: Installs the latest release and runs all tests
    -   release_beta: Uploads a beta release of the metadata in the
        packaging org, creates a Github Release, and generates release
        notes
-   Removed the hard coded slots in the keychain for github,
    mrbelvedere, and apextestsdb and replaced with a more generic
    concept of named keychain services. keychain.get_service('name')
    retrieves a named service. The CLI commands for setting github,
    mrbelvedere, and apextestsdb were modified to write the service
    configs to the new structure.
-   Flow tasks can now access previous tasks' attributes in their
    options definitions. The syntax is \^\^task_name.attr1.attr2
-   Flow output is now nicer showing the flow configuration and the
    active configuration for each task before execution
-   New tasks
    -   update_package_xml_managed: Create a new package.xml from the
        metadata in src/ with attributes only available when deploying
        to packaging org
    -   run_tests: Runs matching apex tests in parallel and generate a
        JUnit report
    -   run_tests_debug: Runs matching apex tests in parallel, generates
        JUnit report, captures debug logs, and parses debug logs for
        limits usage outputing results to test_results.json
    -   run_tests_managed: Runs matching apex tests in parallel from the
        package's namespace and generate a JUnit report

## 2.0.0-alpha11 (2016-10-31)

-   project_config.repo_root is now added to the python syspath, thanks
    \@cdcarter for the contribution
-   Tasks for the new Package Upload API
    -   upload_beta: Uploads a beta release of the metadata currently in
        the packaging org
    -   upload_production: Uploads a production release of the metadata
        currently in the packaging org
-   Dependency management for managed packages:
    -   update_dependencies: Task that ensures the target org has all
        dependencies installed at the correct version
    -   Dependencies are configured using the dependencies: heading in
        cumulusci.yml under the project: section
-   Integrated salesforce-bulk and created BaseSalesforceBulkApiTask for
    building bulk data tasks
-   Added [cci version]{.title-ref} command to print out current package
    version, thanks \@cdcarter for the contribution

## 2.0.0-alpha10 (2016-10-28)

-   More pure Python tasks to replace ant targets:
    -   create_ee_src
    -   retrieve_packaged
    -   retrieve_src
    -   revert_ee_src
    -   uninstall_packaged_incremental
    -   update_admin_profile
-   New flow:
    -   unmanaged_ee: Deploys unmanaged code to an EE org
-   New cumulusci.utils
    -   CUMULUSCI_PATH: The absolute path to the root of CumulusCI
    -   findReplaceRegex: Recursive regex based search/replace for files
    -   zip_subfolder: Accepts a zipfile and path, returns a zipfile
        with path as root
-   Fix bug where repo_name was not being properly handled if it origin
    ended in .git

## 2.0.0-alpha9 (2016-10-27)

-   Switch to using [plaintable]{.title-ref} for printing text tables in
    the following CLI commands:
    -   cci org list
    -   cci task list
    -   cci task info
    -   cci flow list
-   Easier project set up: [cci project init]{.title-ref} now prompts
    for all project values using the global default values
-   More pure Python Metadata API tasks:
    -   create_package
    -   install_package
    -   uninstall_managed
    -   uninstall_packaged
    -   uninstall_pre
    -   uninstall_post
    -   uninstall_post_managed
-   New tasks to interact with the new PackageUploadRequest object in
    the Tooling API
    -   upload_beta
    -   upload_production
-   Python task to replace deployUnpackagedPost ant target with support
    for replacing namespace prefix in filenames and file contents
    -   deploy_post
    -   deploy_post_managed
-   Python tasks to replace createManagedSrc and revertManagedSrc ant
    targets
    -   create_managed_src
    -   revert_managed_src

## 2.0.0-alpha8 (2016-10-26)

-   New tasks for push upgrading packages
    -   push_all: Pushes a package version to all available subscriber
        orgs
        -   ex: cci task run --org packaging -o version 1.1 push_all
    -   push_qa: Pushes a package version to all org ids in the file
        push/orgs_qa.txt in the repo
        -   ex: cci task run --org packaging -o version 1.1 push_qa
    -   push_sandbox: Pushes a package version to all available sandbox
        subscriber orgs
        -   ex: cci task run --org packaging -o version 1.1
            push_sandbox
    -   push_trial: Pushes a package version to all org ids in the file
        push/orgs_trial.txt in the repo
        -   ex: cci task run --org packaging -o version 1.1 push_trial
    -   Configurable push tasks in cumulusci.tasks.push.tasks:
        -   SchedulePushOrgList: uses a file with one OrgID per line as
            the target list
        -   SchedulePushOrgQuery: queries PackageSubscribers to select
            orgs for the target list
    -   Additional push tasks can be built by subclassing
        cumulusci.tasks.push.tasks.BaseSalesforcePushTask

## 2.0.0-alpha7 (2016-10-25)

-   New commands for connecting to other services
    -   cci project connect_apextestsdb: Stores ApexTestDB auth
        configuration in the keychain for use by tasks that require
        ApexTestsDB access
    -   cci project connect_github: Stores Github auth configuration in
        the keychain for use by tasks that require Github access
    -   cci project connect_mrbelvedere: Stores mrbelvedere auth
        configuration in the keychain for use by tasks that require
        access to mrbelvedere
    -   cci project show_apextestsdb: Shows the configured ApexTestsDB
        auth info
    -   cci project show_github: Shows the configured Github auth info
    -   cci project show_mrbelvedere: Shows the configured mrbelvedere
        auth info
-   Github Tasks
    -   The new BaseGithubTask wraps the github3.py API library to allow
        writing tasks targetting Github
    -   The following new Github tasks are implemented on top of
        BaseGithubTask:
        -   github_clone_tag: Clones one git tag to another via the
            Github API
        -   github_master_to_feature: Merges the HEAD commit on master
            to all open feature branches via the Github API
        -   github_release: Creates a Release via the Github API
        -   github_release_notes: Generates release notes by parsing
            merged Github pull request bodies between two tags
-   BaseTask now enforces required task_options raising TaskOptionError
    if required options are missing
-   Restructured the project: heading in cumulusci.yml

## 2.0.0-alpha6 (2016-10-24)

-   Moved the build and ci directories back to the root so 2.0 is
    backwards compatible with 1.0
-   Allow override of keychain class via CUMULUSCI_KEYCHAIN_CLASS env
    var
-   New keychain class
    cumulusci.core.keychain.EnvironmentProjectKeychain for storing org
    credentials as json in environment variables
-   Tasks now support the salesforce_task option for requiring a
    Salesforce org
-   The new BaseSalesforceToolingApi task wraps simple-salesforce for
    building tasks that interact with the Tooling API
-   cumulusci org default \<name\>
    -   Set a default org for tasks and flows
    -   No longer require passing org name in task run and flow run
    -   --unset option flag unsets current default
    -   cumulusci org list shows a \* next to the default org
-   BaseAntTask split out into AntTask and SalesforceAntTask
-   cumulusci.tasks.metadata.package.UpdatePackageXml:
    -   Pure python based package.xml generation controlled by
        metadata_map.yml for mapping in new types
    -   Wired into the update_package_xml task instead of the old ant
        target
-   130 unit tests and counting, and our test suite now exceeds 1
    second!

## 2.0.0-alpha5 (2016-10-21)

-   Update README

## 2.0.0-alpha4 (2016-10-21)

-   Fix imports in tasks/ant.py

## 2.0.0-alpha3 (2016-10-21)

-   Added yaml files to the MANIFEST.in for inclusion in the egg
-   Fixed keychain import in cumulusci.yml

## 2.0.0-alpha2 (2016-10-21)

-   Added additional python package requirements to setup.py for
    automatic installation of dependencies

## 2.0.0-alpha1 (2016-10-21)

-   First release on PyPI.

```

```
