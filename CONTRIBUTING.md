# Contributing

Contributions to Nebula Logger are welcome - following these guidelines will help make it easier & faster to review & merge any changes you want to contribute. When contributing, the typical process is:

1. Familiarize yourself with the codebase - you can check out the [wiki](https://github.com/jongpie/NebulaLogger/wiki) and the [Apex docs site](https://jongpie.github.io/NebulaLogger/) to learn more about the code.
2. Before starting your work, create a new issue (or add a comment to an existing issue you want to contribute to) so that we can keep track of who is actively working on an item.
3. Fork this repository.
4. Create a `feature` or `bugfix` branch in your fork based on the `main` branch.
5. Edit the code/metadata in your fork.
6. Send us a pull request when you are done. We'll review your code, provide feedback for any suggestions or required changes, and then merge it when everything is ready.

# Development

Once you're ready to start working on an issue, you can develop your changes in any scratch org, sandbox, or developer-edition org of your choosing. Using SFDX (Salesforce CLI), VS Code and npm are recommended - this repository includes several scripts and automations using these tools. However, you can use any tools that you prefer, so long as the resulting code changes still conform to the repository's coding standards.

- Clone your fork of the Nebula Logger repository locally
- Run `npm -i` or `npm install` to grab the latest version of our dependencies, and setup the repository's git hooks
- When committing your changes in `git`, the repository's git hooks automatically run to:
  1. Automatically fix/standardize some quality standards - for example, all Apex files will automatically be formatted using `prettier`
  2. Automatically verify coding standards - for example, all Apex files will be automatically scanned for PMD rule violations, based on the repository's configured PMD rules.
- Run all unit tests for LWC and Apex, and verify everything is passing prior to submitting a pull request

# Pull Requests

- All pull requests should use the `main` branch as the base branch
- Your pull request should have a detailed description that describes your changes, and include any screenshots of noteworthy UI changes (when applicable)
- Pull request merging is restricted to only 'squash and merge'
