# This script is used to automatically verify that the package version number for Nebula Logger (stored in sfdx-project.json)
# has not already been released/promoted

function Get-SFDX-Project-Version-Number {
    $projectJSON = Get-Content -Path ./sfdx-project.json | ConvertFrom-Json
    $versionNumber = ($projectJSON).packageDirectories[0].versionNumber
    $versionNumber = $versionNumber.substring(0, $versionNumber.LastIndexOf('.'))
    return $versionNumber
}

function Get-Latest-Released-Version-Number {
    $latestReleasedPackageVersionNumber = (sfdx force:package:version:list --packages "Nebula Logger - Unlocked Package" --released --orderby "MajorVersion DESC, MinorVersion DESC, PatchVersion DESC" --json | ConvertFrom-Json).result[0].Version
    $latestReleasedPackageVersionNumber = $latestReleasedPackageVersionNumber.substring(0, $latestReleasedPackageVersionNumber.LastIndexOf('.'))
    return $latestReleasedPackageVersionNumber
}

$currentPackageVersionNumber = Get-SFDX-Project-Version-Number
Write-Output "Current package version number == $currentPackageVersionNumber"
$latestReleasedPackageVersionNumber = Get-Latest-Released-Version-Number
Write-Output "Latest released package version number == $latestReleasedPackageVersionNumber"

if ($currentPackageVersionNumber -eq $latestReleasedPackageVersionNumber) {
    throw "Current package version number $currentPackageVersionNumber has already been released - please increment the package version number"
} else {
    Write-Output "Current package version number $currentPackageVersionNumber has not been released"
}
