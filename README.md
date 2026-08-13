# Nebula Logger for Salesforce

[![Build](https://github.com/jongpie/NebulaLogger/actions/workflows/build.yml/badge.svg)](https://github.com/jongpie/NebulaLogger/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/jongpie/NebulaLogger/branch/main/graph/badge.svg?token=1DJPDRM3N4)](https://codecov.io/gh/jongpie/NebulaLogger)

The most robust observability solution for Salesforce experts. Built 100% natively on the platform, and designed to work seamlessly with Apex, Lightning Components, Flow, OmniStudio, and integrations.

**Full documentation: [nebulalogger.com](https://nebulalogger.com)**

## Install

### Unlocked Package - v4.19.2

[![Install Unlocked Package in a Sandbox](./images/btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000HNrRAAW)
[![Install Unlocked Package in Production](./images/btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000HNrRAAW)

```
sf package install --wait 20 --security-type AdminsOnly --package 04tg7000000HNrRAAW
```

### Managed Package - v4.19.0

[![Install Managed Package in a Sandbox](./images/btn-install-managed-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW)
[![Install Managed Package in Production](./images/btn-install-managed-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW)

```
sf package install --wait 30 --security-type AdminsOnly --package 04tg7000000GZbJAAW
```

Choose the unlocked package unless you specifically need a namespaced install. See [Package options](https://nebulalogger.com/introduction/package-options/) for the full comparison.

## AI agent skills

Nebula Logger ships [Agent Skills](https://www.skills.sh/docs) that teach Claude Code, GitHub Copilot, Cursor, and similar tools how to install, use, and extend Nebula Logger.

```
npx skills add jongpie/NebulaLogger
```

See [AI Agent Skills](https://nebulalogger.com/ai-agent-skills/installing/) for what's included.

## Contributing

Fork the repo, work in a `feature/*` or `bugfix/*` branch, open a PR against `main`. See [Contributing](https://nebulalogger.com/contributing/repo-layout/) for local setup, testing, and PR conventions. AI coding agents should also read [CLAUDE.md](CLAUDE.md).

## License

[MIT](LICENSE).
