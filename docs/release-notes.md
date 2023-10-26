# Generate Release Notes

## Using Automatic Release Note Generation

The `github_release_notes` task fetches the text from Pull Requests that
were merged between two given tags. The task then searches for specific
titles (Critical Changes, Changes, Issues Closed, New Metadata,
Installation Info, and so on) in the Pull Request bodies, and aggregates
the text together under those titles in the GitHub tag description.

`github_release_notes` is automatically run during CumulusCI's built-in
release flows.

To see what the release notes look like without publishing them to
GitHub:

```
$ cci task run github_release_notes --tag release/1.2
```

```{note}
The `--tag` option indicates which release's change notes are
aggregated. The previous command aggregates all change notes between the
[1.2]{.title-ref} release and the [1.1]{.title-ref} release.
```

To see where each line in the release notes comes from, use the
`--link_pr True` option.

```
$ cci task run github_release_notes --tag release/1.2 --link_pr True
```

To publish the release notes to a release tag in GitHub, use the
`--publish True` option:

```
$ cci task run github_release_notes --tag release/1.2 --publish True
```

To use additional headings, add new ones (as parsers) under the
`project__git__release_notes` section of the `cumulusci.yml` file.

```
release_notes:
    parsers:
        7: class_path: cumulusci.tasks.release_notes.parser.GithubLinesParser
```

```{note}
The new parser is listed with the number `7` because the first six are
the [default
parsers](https://github.com/SFDO-Tooling/CumulusCI/blob/671a0e88cef79e9aeefe1e2b835816cd8141bdbb/cumulusci/cumulusci.yml#L1154)
that come with CumulusCI.
```

## Using Static Release Notes

In some cases, you may wish to use static text as your release notes instead of aggregating them
from Pull Request content. You can do that by making customizations in your `cumulusci.yml`.

Customize the `github_release` task to include your static content:

```yaml
tasks:
    github_release:
        options:
            release_content: |
                # This is my top-level heading

                Here is some body content.
```

Note that you may use Markdown, provided you indent the content as shown and
utilize the `|` indicator, which marks a YAML block.

Then, turn off the `github_release_notes` task, where you don't want it to run:

```yaml
flows:
    release_beta:
        steps:
            3:
                task: None
```

You can repeat this configuration for any or all of the flows `release_beta`, `release_production`,
`release_2gp_beta`, `release_2gp_production`, `release_unlocked_beta`, and `release_unlocked_production`.
You may choose to customize only the production flows if you want to use auto-generated release notes
for your beta releases.
