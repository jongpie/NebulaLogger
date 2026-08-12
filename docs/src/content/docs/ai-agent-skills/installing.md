---
title: Installing the skills
description: How to add Nebula Logger's AI agent skills to your project.
---

Nebula Logger ships a set of [Agent Skills](https://www.skills.sh/docs) that teach AI coding agents (Claude Code, GitHub Copilot, Cursor, and similar tools) how to install, use, and extend Nebula Logger. When installed in a repo, these skills become available to any AI agent that supports the skills.sh convention.

## Install

From the root of your project:

```bash
npx skills add jongpie/NebulaLogger
```

This copies the skills into a local `skills/` directory in your project and updates `skills.sh.json` to register them.

## What gets added

- A `skills/` directory containing one folder per skill, each with a `SKILL.md` describing when and how to use it.
- A `skills.sh.json` manifest that groups the skills by topic.

## Verifying

After install, `skills/` should contain the seven Nebula Logger skills:

- `nebula-logger-install`
- `nebula-logger-instrumentation`
- `nebula-logger-console`
- `nebula-logger-purging-and-retention`
- `nebula-logger-best-practices`
- `nebula-logger-plugin-development`
- `nebula-logger-testing-your-code`

Each has a `SKILL.md` file with the skill's description and usage guidance.

## Using with Claude Code

Claude Code automatically loads project-scoped skills. Once installed, ask Claude Code any question about Nebula Logger and it'll consult the relevant skill(s) for context.

## Using with other agents

The skills.sh convention is agent-agnostic - any agent that reads the manifest can consume them. Consult your agent's documentation for how it loads project-local skills.

## Where next

- [Skill catalog](/ai-agent-skills/catalog/) - what each skill covers.
