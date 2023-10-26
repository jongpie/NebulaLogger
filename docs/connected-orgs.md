# Connect Persistent Orgs

In addition to creating [scratch orgs](scratch-orgs) in CumulusCI, you can connect persistent orgs to your
project to run tasks and flows on them. This feature supports use cases
such as deploying to a Developer Edition org to release a package
version, or installing to a sandbox for user acceptance testing.

```{attention}
A different setup is required to connect to orgs in the context of an
automated build. See
[continuous integration](continuous-integration) for more information.
```

## The `org connect` Command

To connect to a persistent org:

```console
$ cci org connect <org_name>
```

This command automatically opens a browser window pointed to a
Salesforce login page. The provided `<org_name>` is the alias that
CumulusCI will assign to the persistent org.

```{note}
Connecting an org via `cci org connect` does _not_ expose that org to
the Salesforce CLI.
```

If your org has a custom domain, use the `--login-url` option along with
the corresponding login url.

```console
cci org connect <org_name> --login-url https://example.my.domain.salesforce.com
```

### Production and Developer Edition Orgs

No options are needed for these org types. Just run the same command you
normally would to connect to a persistent org.

```console
$ cci org connect <org_name>
```

### Sandboxes

For sandboxes, pass the `--sandbox` flag along with the org name.

```console
$ cci org connect <org_name> --sandbox
```

```{note}
The `--sandbox` flag can also be used for connecting a scratch org
created externally to CumulusCI.
```

## Verify Your Connected Orgs

Run `cci org list` to see your org listed under the "Connected Org"
table. This example output shows a single persistent org connected to
CumulusCI with the name `devhub`.

```console
$ cci org list

┌Scratch Orgs──────────────┬─────────┬──────┬─────────┬──────────────┬────────┐
│ Name                     │ Default │ Days │ Expired │ Config       │ Domain │
├──────────────────────────┼─────────┼──────┼─────────┼──────────────┼────────┤
│ dev                      │         │ 7    │ X       | dev          │        │
├──────────────────────────┼─────────┼──────┼─────────┼──────────────┼────────┤
│ feature                  │         │ 1    │ X       | feature      │        │
├──────────────────────────┼─────────┼──────┼─────────┼──────────────┼────────┤
│ prerelease               │         │ 1    │ X       | prerelease   │        │
├──────────────────────────┼─────────┼──────┼─────────┼──────────────┼────────┤
│ qa                       │         │ 7    │ X       | qa           │        │
├──────────────────────────┼─────────┼──────┼─────────┼──────────────┼────────┤
│ release                  │         │ 1    │ X       | release      │        │
└──────────────────────────┴─────────┴──────┴─────────┴──────────────┴────────┘

┌Connected Orgs────┬──────────────────────────────┬────────────┐
│ Name   │ Default │ Username                     │ Expires    │
├────────┼─────────┼──────────────────────────────┼────────────┤
│ devhub │         │ j.holt@mydomain.devhub       │ Persistent │
└────────┴─────────┴──────────────────────────────┴────────────┘
```

Verify a successful connection to the org by logging in.

```console
$ cci org browser <org_name>
```

## Global Orgs

By default, `cci org connect` stores the OAuth credentials for connected
orgs in a _project-specific_ keychain. Using a project-specific keychain
means that an org connected in Project A's directory isn't available
when you're working in Project B's directory.

Connect an org and make it available to _all_ CumulusCI projects on your
computer by passing the `--global-org` flag.

```console
$ cci org connect <org_name> --global-org
```

(use-a-custom-connected-app)=

## Use a Custom Connected App

CumulusCI uses a preconfigured Connected App to authenticate to
Salesforce orgs that use OAuth2. In most cases this preconfigured app is
all you need to authenticate into orgs. To control the Connected App for
specific security or compliance requirements (such as adding a private
key to sign a certificate connected with the configuration, or enforcing
restrictions on user activity), create your own Connected App and
configure CumulusCI to use it when connecting to orgs.

To create a custom Connected App, run the `connected_app` task, and then
manually [edit its
configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_connected_app.htm)
to suit your requirements.

```{important}
Make sure to create the Connected App in a production org!
```

This command will create a Connected App in the Dev Hub org connected to
`sfdx`, and connect it to CumulusCI as a `connected_app` service named
`custom`.

```console
$ cci task run connected_app --label custom --connect true
```

After running this task, `cci service list` should show that the
`custom` connected_app service exists.

```console
$ cci service list
                                                Services

Default   Type              Name         Description
─────────────────────────────────────────────────────────────────────────────────────────────────────────
✔         connected_app     built-in     A Connected App is required to connect to and run commands
                                         against persistent orgs. See https://cumulusci.readthedocs.io/
                                         en/latest/connected-orgs.html#use-a-custom-connected-app for
                                         more info.
          connected_app     custom       A Connected App is required to connect to and run commands
                                         against persistent orgs. See https://cumulusci.readthedocs.io/
                                         en/latest/connected-orgs.html#use-a-custom-connected-app for
                                         more info.
```

Use the `--connected_app` option to connect an org using the custom
connected app:

```console
$ cci org connect <org_name> --connected_app custom
```

To edit the Connected App's OAuth scopes:

1.  In Lightning Experience, go to Setup --\> Apps --\> Apps Manager.
2.  Click the arrow on the far right side of the row that pertains to
    the newly created Connected App.
3.  Click "Edit."
4.  Add or remove OAuth scopes as desired. CumulusCI requires the `api`,
    `full`, and `refresh_token` scopes.

For a full list of options, run the [](connected-app) task reference documentation.
