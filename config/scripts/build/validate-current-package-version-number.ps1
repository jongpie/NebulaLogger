# This script is used to automatically verify that the package version number for Nebula Logger (stored in sfdx-project.json)
# has not already been released/promoted

function Get-SFDX-Project-Version-Number {
    $projectJSON = Get-Content -Path ./sfdx-project.json | ConvertFrom-Json
    $versionNumber = ($projectJSON).packageDirectories[0].versionNumber
    $versionNumber = $versionNumber.substring(0, $versionNumber.LastIndexOf('.'))
    return $versionNumber
}

function Get-Released-Versions {
    $releasedPackageVersions = (npx sfdx force:package:version:list --packages "Nebula Logger - Core" --released --orderby "MajorVersion DESC, MinorVersion DESC, PatchVersion DESC" --json | ConvertFrom-Json).result
    return $releasedPackageVersions
}

function Get-Simplified-Version-Number {
    param (
        $packageVersion
    )
    $simplifiedReleasedVersionNumber = ($packageVersion.MajorVersion.ToString()) + '.' + ($packageVersion.MinorVersion.ToString()) + '.' + ($packageVersion.PatchVersion.ToString())
    return $simplifiedReleasedVersionNumber
}

$currentPackageVersionNumber = Get-SFDX-Project-Version-Number
Write-Output "Current package version number == $currentPackageVersionNumber"
$releasedPackageVersions = Get-Released-Versions
Write-Output "Released package versions == $releasedPackageVersions"

foreach($releasedPackageVersion in $releasedPackageVersions) {
    $simplifiedReleasedVersionNumber = Get-Simplified-Version-Number($releasedPackageVersion)
    if ($currentPackageVersionNumber -eq $simplifiedReleasedVersionNumber) {
        throw "Current package version number $currentPackageVersionNumber has already been released - please increment the package version number"
    }
}
Write-Output "Package version number verified: current package version number $currentPackageVersionNumber has not been released yet"
