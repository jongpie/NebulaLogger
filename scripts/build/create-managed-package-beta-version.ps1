# There is some deprecated metadata that only lives in the managed package
# This script handles combining the managed package's deprecated metadata with
# the core unlocked package's metadata, and then creates a new package version

$sfdxProjectJsonPath = "./sfdx-project.json"

Write-Output "Copying metadata in ./nebula-logger/core/ to ./nebula-logger/managed-package/"
cp --recursive --force ./nebula-logger/core/ ./nebula-logger/managed-package/

# Create a new version of the managed package
Write-Output "Creating new package version for the managed package"
$gitBranch = (git branch --show-current)
$gitCommit = (git rev-parse HEAD)
npx sfdx package version create --json --package "Nebula Logger - Managed Package" --code-coverage --installation-key-bypass --wait 60 --branch $gitBranch --tag $gitCommit
$packageVersionCreateExitCode = $LASTEXITCODE
git clean -df -- nebula-logger/managed-package/core
if ($packageVersionCreateExitCode -ne 0) {
    throw "Error creating package version for managed package"
}

Write-Output "Formatting $sfdxProjectJsonPath with prettier"
npx prettier --write $sfdxProjectJsonPath
