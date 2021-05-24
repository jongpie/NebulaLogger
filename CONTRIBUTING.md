# Contributing / Development

Contributions to Nebula Logger are welcome, however we ask that Apex Prettier be run on prior to any pull requests being submitted to this repo.

When developing, to get started:

-   run `npm -i` or `npm install` or `yarn` to grab the latest version of our dependencies
-   when using VS Code: ensure that your "Format On Save" editor option is set to `true` (in `settings.json`: `"editor.formatOnSave": true`)
-   all unit tests should be run and passing prior to submitting a PR. We understand that you may be developing on a sandbox / Developer Edition org, and that you may have test classes other than the ones included with Nebula Logger on your org. You can use `npm run test` or `yarn test` to run _only_ the unit tests associated with Nebula Logger in your org
