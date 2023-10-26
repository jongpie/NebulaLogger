# Environment Variables

CumulusCI has environment variables that are useful when CumulusCI is
being run inside of web applications, such as MetaCI, MetaDeploy, and
Metecho. The following is a reference list of available environment
variables that can be set.

## `CUMULUSCI_AUTO_DETECT`

Set this environment variable to autodetect branch and commit
information from `HEROKU_TEST_RUN_BRANCH` and
`HEROKU_TEST_RUN_COMMIT_VERSION` environment variables.

## `CUMULUSCI_DISABLE_REFRESH`

If present, will instruct CumulusCI to not refresh OAuth tokens for
orgs.

## `CUMULUSCI_KEY`

An alphanumeric string used to encrypt org credentials at rest when an
OS keychain is not available.

## `CUMULUSCI_REPO_URL`

Used for specifying a GitHub Repository for CumulusCI to use when
running in a CI environment.

## `CUMULUSCI_SYSTEM_CERTS`

If set to `True`, CumulusCI will configure the Python `requests` library
to validate server TLS certificates using the system's certificate
authorities, instead of the set of CA certs that is bundled with
`requests`.

## `GITHUB_APP_ID`

Your GitHub App's identifier.

## `GITHUB_APP_KEY`

Contents of a JSON Web Token (JWT) used to [authenticate a GitHub
app](https://developer.github.com/apps/building-github-apps/authenticating-with-github-apps/##authenticating-as-a-github-app).

## `GITHUB_TOKEN`

A GitHub [personal access
token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

## `HEROKU_TEST_RUN_BRANCH`

Used for specifying a specific branch to test against in a Heroku CI
environment

## `HEROKU_TEST_RUN_COMMIT_VERSION`

Used to specify a specific commit to test against in a Heroku CI
environment.

## `SFDX_CLIENT_ID`

Client ID for a Connected App used to authenticate to a persistent org,
e.g. a Developer Hub. Set with SFDX_HUB_KEY.

## `SFDX_HUB_KEY`

Contents of JSON Web Token (JWT) used to authenticate to a persistent
org, e.g. a Dev Hub. Set with SFDX_CLIENT_ID.

## `SFDX_ORG_CREATE_ARGS`

Extra arguments passed to `sfdx force:org:create`. Can be used to pass
key-value pairs.
