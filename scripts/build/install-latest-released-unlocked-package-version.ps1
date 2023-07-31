# This script is used to install the latest promoted package version into an org, using the specified target username
param ([string]$targetusername)

Write-Output "Target Username: $targetusername"

npx sf package version list --json --concise --released --order-by CreatedDate > released-package-versions.json
$releasedPackageVersionsOutput = Get-Content -Raw -Path ./released-package-versions.json | ConvertFrom-Json
Write-Output "Released Package Versions Create Output: $releasedPackageVersionsOutput"

$countOfReleasedPackageVersions = ($releasedPackageVersionsOutput).result.Count
$latestReleasedPackageVersion = ($releasedPackageVersionsOutput).result[$countOfReleasedPackageVersions – 1]
Write-Output "Latest Released Package Version: $latestReleasedPackageVersion"

$latestReleasedPackageVersionId = ($latestReleasedPackageVersion).SubscriberPackageVersionId
Write-Output "Latest Released Package Version ID: $latestReleasedPackageVersionId"

Write-Output "Installing package in org: $targetusername"
npx sf package install --no-prompt --target-org $targetusername --wait 20 --package $latestReleasedPackageVersionId
