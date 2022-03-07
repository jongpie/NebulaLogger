# There are 2 versions of sfdx-project.json - 1 for the unlocked package and 1 for the managed package
# This script handles switching to the managed package's version of the file, and creating a beta of the managed package

$rootProject = "./sfdx-project.json"
$unlockedProject = "./unlocked-sfdx-project.json"
$managedProject = "./nebula-logger/managed-package/sfdx-project.json"

# Switch to using the managed package's sfdx-project.json file
Write-Output "Switching to managed package's version of sfdx-project.json"
Write-Output "Copying $rootProject to $unlockedProject"
Copy-Item -Path $rootProject -Destination $unlockedProject -Force
Write-Output "Overwriting $rootProject with $managedProject"
Copy-Item -Path $managedProject -Destination $rootProject -Force

# Create a beta of the managed package version (no `--codecoverage` flag)
cp -R ./nebula-logger/core/ ./nebula-logger/managed-package/
$gitBranch = (git branch --show-current)
$gitCommit = (git rev-parse HEAD)
npx sfdx force:package:version:create --json --package "Nebula Logger - Managed Package" --codecoverage --installationkeybypass --wait 30 --branch $gitBranch --tag $gitCommit
if ($LASTEXITCODE -ne 0) {
    throw "Error creating package version for managed package"
}
git clean -df -- nebula-logger/managed-package/core

# Restore the sfdx-project.json files to their original locations
Write-Output "Restoring unlocked package's version of sfdx-project.json"
Write-Output "Copying $rootProject to $managedProject"
Copy-Item -Path $rootProject -Destination $managedProject -Force
npx prettier --write $managedProject
Write-Output "Overwriting $rootProject with $unlockedProject"
Copy-Item -Path $unlockedProject -Destination $rootProject -Force
Remove-Item -Path $unlockedProject
