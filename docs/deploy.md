# Configure Metadata Deployment

CumulusCI's `deploy` task uses the Metadata API to deploy metadata from the repository to a Salesforce org. `deploy` offers multiple sophisticated capabilities to suit the needs of your project.

## Specifying the Deploying Package and Test Run Levels

Use the `path` option to specify the path to the metadata you wish to deploy. The metadata may be in either Metadata API or Salesforce DX source format. SFDX-format source will automatically be converted to Metadata API for deployment. This conversion takes place prior to application of transforms (below) and requires that the path be listed as a package directory in `sfdx-project.json`.

Set the test run level with the `test_level` option. Available values are `NoTestRun`, `RunLocalTests`, `RunAllTestsInOrg`, and `RunSpecifiedTests`. If you use `RunSpecifiedTests`, you must also supply a list of tests with the `specified_tests` option. This option accept a comma-separated value at the command line or a list in your `cumulusci.yml` markup.

## Source Transforms

`deploy` allows you to specify _transforms_ that run against your metadata before it is delivered to the Salesforce platform. Some of these transforms are built-in, and others you can specify in your `cumulusci.yml` to suit your project's specific needs.

### Specifying Transforms

Four of the `deploy` transformations are built-in, and controlled by task options (see below). Others, including the flexible `find_replace` transform, are specified by your customization in `cumulusci.yml`.

You can specify transforms to run everywhere `deploy` is invoked by using customization in your `tasks` section:

```yaml
tasks:
    deploy:
        options:
            transforms:
                - transform: find_replace
                  options:
                      patterns:
                          - find: foo
                            replace: bar
```

You can also add a transform for just a specific flow step:

```yaml
flows:
    my_flow:
        steps:
            1:
                task: deploy
                options:
                    transforms:
                        - transform: find_replace
                          options:
                              patterns:
                                  - find: foo
                                    replace: bar
```

or override the options in an out-of-the-box flow:

```yaml
flows:
    deploy_packaging:
        options:
            deploy:
                transforms:
                    - transform: find_replace
                      options:
                          patterns:
                              - find: foo
                                replace: bar
```

To learn more about customization, see [](config). To discover the available transform options, consult the section for each transform in [](deploy).

### Namespace Injection

The `deploy` task, like many others in CumulusCI, supports _namespace injection_. This strategy allows you to flexibly inject your package's namespace into (or remove it from) your metadata to suit various deployment contexts. See [](namespace-injection) for more information about namespace injection.

In most cases, you don't need to customize `deploy` options for namespace injection, as the task will automatically infer the appropriate strategy. If you do find an edge case where inference does not suit your needs, you can configure namespace injection using the following options.

-   `namespace_inject`: set to specify the namespace to inject against tokens.
-   `namespace_strip`: set to specify the namespace prefix to remove.
-   `unmanaged`: set to `True` to replace namespace tokens with the empty string.
-   `namespaced_org`: set to `True` to replace the special `NAMESPACED_ORG` tokens with the namespace. Note that the packaging org is considered a namespaced-org context.

### Meta-XML Cleaning

`deploy` can automatically remove references (`<packageVersions/>` elements) to the versions of other managed packages from `*-meta.xml` files in your metadata. This cleaning is controlled by the `clean_meta_xml` option, which defaults to `True`.

### Static Resource Bundling

For products that are in Metadata API source format, `deploy`, can automatically Static Resource content that is stored uncompressed in an alternate directory into the ZIP files expected by the platform. To use this capability, set the option `static_resource_path` to the path where you store unzipped Static Resource content. CumulusCI will ZIP each subdirectory and place the archives in the `staticresources` directory in the deployment bundle. You must include required `-meta.xml` files in the `static_resource_path`.

### Feature-Parameter Cleaning for Unlocked Packages

Unlocked Packages do not support Feature Parameter metadata. When CumulusCI is building an Unlocked Package, this transform will automatically remove Feature Parameter metadata from the deployment bundle.

### Find-and-Replace Variable Injection

CumulusCI allows you to specify arbitrary injections of data against tokens you define in your metadata. This capability is often used, for example, to inject secure keys or tokens from environment variables.

Configure injection with the `find_replace` transform in two ways - `find` and `xpath`.

-   Using the `find` parameter, it modifies the metadata for each occurrence of its value by utilizing the supplied `replace` parameter. For XML files, this adjustment exclusively affects the values within the XML elements, leaving the tags unchanged.
-   Using the `xpath` parameter, it exclusively modifies the content of the XML files within the specific element indicated by the provided `xpath`, replacing it with the specified `replace` parameter.

**Note:** The Find-and-Replace Injection only supports one of the two parameters `find` or `xpath`.

Injection with `find` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - find: foo
                    replace: bar
```

Injection with `xpath` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - xpath: /path/to/element
                    replace: bar
```

The `xpath` also supports the use of predicates such as `- xpath: /path[1]/to/element[text()="some_text"]`

To use an environment variable as the source of the value to replace, use the `replace_env` key. Note that it's valid to use multiple runs of `find_replace`; they will be applied in sequence.

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - find: AUTH_TOKEN
                    replace_env: SECURE_ACCESS_KEY
                  - xpath: /path/to/AUTH_TOKEN
                    replace_env: SECURE_ACCESS_KEY
```

#### Find-and-Replace Id Injection

Some metadata components contain ID references. CumulusCI offers a way to insert the ID of an existing record from the target org directly into such components during a deployment. Specify a SOQL query with the `replace_record_id_query` option as follows:

Injection with `find` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - find: special_string
                    replace_record_id_query: SELECT Id from Account WHERE name='Specific Account'
                    api: rest
```

Injection with `xpath` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - xpath: /path/to/element
                    replace_record_id_query: SELECT Id from Account WHERE name='Specific Account'
                    api: rest
```

Available values for `api` include `rest` and `tooling`.

#### Find-and-Replace Current Username Injection

CumulusCI can replace a given token with the username of the current running user in the target Salesforce org.
All that is needed is to specify a value for `find` or `xpath` and set `inject_username: True`:

Injection with `find` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - find: special_string
                    inject_username: True
```

Injection with `xpath` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - xpath: /path/to/element
                    inject_username: True
```

#### Find-and-Replace Org URL Injection

CumulusCI can replace a given token with the org URL of the target Salesforce org.
All that is needed is to specify a value for `find` or `xpath` and set `inject_org_url: True`:

Injection with `find` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - find: special_string
                    inject_org_url: True
```

Injection with `xpath` parameter:

```yaml
task: deploy
options:
    transforms:
        - transform: find_replace
          options:
              patterns:
                  - xpath: /path/to/element
                    inject_org_url: True
```

### Stripping Components with a `package.xml` Manifest

This transformation allows you to deploy a subset of a metadata directory based on a `package.xml` manifest by removing unwanted components. It will compare components available in the source folder with a provided `package.xml` file and delete/modify component files which are not found.

```yaml
task: deploy
options:
    transforms:
        - transform: strip_unwanted_components
          options:
              package_xml: PACKAGE_XML_FILE_PATH
```
