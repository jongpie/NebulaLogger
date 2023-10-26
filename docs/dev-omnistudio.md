# Develop a Project that uses OmniStudio

An overview of the additional steps required to develop an OmniStudio project with
CumulusCI.

## Set Up a Dev Org with OmniStudio

Create an org from a json file in `\orgs` that includes the following:

```
  "features": [
    "OmniStudioDesigner",
    "OmniStudioRuntime"
  ],
```

Create custom tasks to install VBT and OmniStudio managed packages, as per the following examples. Run these tasks on your scratch org. Note that newer versions are available; these are examples only.

```
    install_vbt:
        description: Install VBT Package (for migrating OmniStudio components)
        class_path: cumulusci.tasks.salesforce.InstallPackageVersion
        group: OmniStudio
        options:
            namespace: vbtapp
            version: "1.3"
            name: VBT App

    install_omnistudio:
        description: Install OmniStudio
        class_path: cumulusci.tasks.salesforce.InstallPackageVersion
        group: OmniStudio
        options:
            namespace: omnistudio
            version: "234.4"
            name: OmniStudio
```

Run the task `deploy_omni_studio_site_settings` against your scratch org. This deploys remote site settings needed for OmniStudio.

## Retrieve OmniStudio Changes

Run the task `vlocity_pack_export` against your scratch org, defining the jobfile yaml path in the `--job_file` parameter. This is a simple wrapper on `vlocity packExport`. See vlocity documentation for further details.

## Deploy OmniStudio Changes

Run the task `vlocity_pack_deploy` against your scratch org, defining the jobfile yaml path in the `--job_file` parameter. This is a simple wrapper on `vlocity packDeploy`. See vlocity documentation for further details.
