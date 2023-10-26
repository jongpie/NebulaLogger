# Manage Push Upgrades

If your packaging org (for first-generation packages) or Dev Hub (for
second-generation packages) is enabled to use push upgrades, CumulusCI
can schedule push upgrades with the `push_sandbox` and `push_all` tasks.

```{warning}
`push_all` schedules push upgrades to _all_ customers' production and
sandbox orgs. Please confirm that this action is desired before
executing the task.
```

```console
$ cci task run push_all --version <version> --org packaging
```

Replace `<version>` with the version of the managed package to be
pushed.

By default, push upgrades are scheduled to run immediately.

To schedule the push upgrades to occur at a specific time, use the
`--start_time` option with a time value in UTC.

```console
$ cci task run push_all --version <version> --start_time 2020-10-19T10:00 --org packaging
```

There are additional tasks related to push upgrades in the CumulusCI
standard library.

-   [](push-failure-report): Produces a
    `csv` report of the failed and otherwise anomalous push jobs.
-   [](push-list): Schedules a push
    upgrade of a package version to all orgs listed in a specified file.
-   [](push-qa): Schedules a push
    upgrade of a package version to all orgs listed in
    `push/orgs_qa.txt`.
-   [](push-sandbox): Schedules a push
    upgrade of a package version to all subscribers' sandboxes.
-   [](push-trial): Schedules a push
    upgrade of a package version to Trialforce Template orgs listed in
    `push/orgs_trial.txt`.
