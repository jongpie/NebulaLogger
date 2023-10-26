# Extend NPSP and EDA with Second-Generation Packaging

Building packages that extend (depend on) NPSP and EDA using
second-generation packaging involves some unique complications. Both
NPSP and EDA have install-time dependencies on Record Type org features:
an Account Record Type must exist in order for the packages to install.

When building first-generation packages, both NPSP and EDA serve this
need by installing unpackaged Record Types stored in their
`unpackaged/pre` folders. However, second-generation packaging doesn't
allow interactive access to its build orgs, where package versions are
created.

We recommend that projects which extend EDA or NPSP with a
second-generation package use scratch org definition files to satisfy
these Record Type dependencies. You can do this by creating a new org
definition file in `orgs`, based on your existing org definitions, and
adding to it an `objectSettings` section. We'll call this file
`orgs/build.json`.

For NPSP, use:

```json
"settings": {
    /* Your project's settings are here */
},
"objectSettings": {
    "account": {
        "defaultRecordType": "default"
    }
}
```

and for EDA, use:

```json
"settings": {
    /* Your project's settings are here */
},
"objectSettings": {
    "account": {
        "defaultRecordType": "Administrative"
    }
}
```

This satisfies EDA's requirement for a specific Record Type name.

You'll also add to your \`cumulusci.yml\`:

```yaml
orgs:
    scratch:
        build:
            config_file: orgs/build.json
```

Then, run your 2GP builds against the org \`build\`:

```console
$ cci flow run dependencies --org build
$ cci flow run release_2gp_beta --org build
```

This will result in the creation of default Record Types in the build
org, allowing NPSP to be installed. Meanwhile, your other scratch orgs
will continue to use the NPSP or EDA default Record Types, installed by
CumulusCI's dependency-management system and reflecting the
configuration of the subscriber orgs into which your package will
ultimately be installed.
