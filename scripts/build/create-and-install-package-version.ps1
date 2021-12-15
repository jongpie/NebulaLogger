# This script is used to create a new package version & install it into an org, using the specified target username
# The new package version is auto-added to sfdx-project.json and README.md
param ([string]$targetusername)

$ErrorActionPreference = 'Stop'

$sfdxProjectJsonPath = "./sfdx-project.json"
$readmePath = "./README.md"

function Get-SFDX-Project-JSON {
    Get-Content -Path $sfdxProjectJsonPath | ConvertFrom-Json
}

function Get-Package-Name {
    (Get-SFDX-Project-JSON).packageDirectories[0].package
}

function Get-Package-Version-Name {
    ((Get-SFDX-Project-JSON).packageDirectories[0].versionName).ToLower() -replace " ", "-"
}

function Get-Package-Version-Number {
    $packageVersionNumber = (Get-SFDX-Project-JSON).packageDirectories[0].versionNumber
    # In sfdx-project.json, the packageDirectories section uses version number format W.X.Y.Z (all dots "." as delimiters)
    # but in packageAliases, it uses the format W.X.Y-Z (last delimiter is a dash "-")
    [int]$lastDotIndex = $packageVersionNumber.LastIndexOf('.')
    $cleanedPackageVersionNumber = $packageVersionNumber.remove($lastDotIndex, 1).insert($lastDotIndex, "-")
    return $cleanedPackageVersionNumber
}

function Generate-Package-Version-Alias {
    return (Get-Package-Name) + "@" + (Get-Package-Version-Number) + "-" + (Get-Package-Version-Name)
}

function Create-New-Package-Version {
    $projectJSON = Get-SFDX-Project-JSON
    $packageVersionAlias = Generate-Package-Version-Alias

    # Get the ID of the old package version for the package version number (if there is one)
    $oldPackageVersionId
    if(Get-Member -inputobject $($projectJSON).packageAliases -name $packageVersionAlias -Membertype Properties){
        $oldPackageVersionId = ($projectJSON).packageAliases.$packageVersionAlias
    }

    # Create a new package version
    $packageVersionCreateResult = npx sfdx force:package:version:create --json --package (Get-Package-Name) --codecoverage --installationkeybypass --wait 30 | ConvertFrom-Json
    $packageVersionId = $packageVersionCreateResult.result.SubscriberPackageVersionId

    if ($packageVersionId -eq $null -or $packageVersionId -eq "") {
        throw "Error creating package version ID"
    }

    # Now delete the old package version (if there is one)
    # Purposefully commented-out - not 100% I want to keep this, I might move this to happen after a PR is merged
    # if($oldPackageVersionId -ne $null) {
    #     npx sfdx force:package:version:delete --noprompt --package $oldPackageVersionId --json | ConvertFrom-Json
    # }

    # Add the new package version alias & sort all of the package aliases
    # TODO: this sorting "works," but doesn't take into account double digits in parts of the version number
    # For example, 4.6.10-0 is sorted before 4.6.2-0, even though 2 < 10
    ($projectJSON).packageAliases | Add-Member -Name "$packageVersionAlias" -value "$packageVersionId" -MemberType NoteProperty -Force
    $sortedPropertiess = [ordered] @{}
    Get-Member -Type NoteProperty -InputObject $projectJSON.packageAliases | Sort-Object {$_.Name} | % { $sortedPropertiess[$_.Name] = $projectJSON.packageAliases.$($_.Name) }

    # Add the new package version to sfdx-project.json
    $sortedPackageAliases = New-Object PSCustomObject
    Add-Member -InputObject $sortedPackageAliases -NotePropertyMembers $sortedPropertiess
    $projectJSON.packageAliases = $sortedPackageAliases
    $projectJSON | Sort-Object -Property Id -Descending | ConvertTo-Json -depth 32 | Set-Content $sfdxProjectJsonPath

    $packageVersionId = "$packageVersionId".Trim()
    return $packageVersionId
}

function Update-README-Package-Version-Id {
    param (
        $packageVersionId
    )
    $packageVersionId = "$packageVersionId".Trim()
    # Since there are links for both the unlocked & managed packages, the unlocked package buttons are used to ensure the correct link is updated
    $sandboxUnlockedPackageReplacement = "btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=$packageVersionId"
    ((Get-Content -path $readmePath -Raw) -replace "btn-install-unlocked-package-sandbox.png\)\]\(https:\/\/test.salesforce.com\/packaging\/installPackage.apexp\?p0=.{0,18}", $sandboxUnlockedPackageReplacement) | Set-Content -Path $readmePath -NoNewline
    $productionUnlockedPackageReplacement = "btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=$packageVersionId"
    ((Get-Content -path $readmePath -Raw) -replace "btn-install-unlocked-package-production.png\)\]\(https:\/\/login.salesforce.com\/packaging\/installPackage.apexp\?p0=.{0,18}", $productionUnlockedPackageReplacement) | Set-Content -Path $readmePath -NoNewline
}

function Install-Package-Version {
    param (
        $packageVersionId
    )
    $packageVersionId = "$packageVersionId".Trim()
    npx sfdx force:package:install --noprompt --targetusername $targetusername --wait 20 --package $packageVersionId
}

Write-Output "Creating new package version"
$packageVersionId = Create-New-Package-Version
$packageVersionId = "$packageVersionId".Trim()
Write-Output "Created new package version ID $packageVersionId"
Write-Output "Adding new package version to $sfdxProjectJsonPath"
prettier --write $sfdxProjectJsonPath
git add $sfdxProjectJsonPath

Write-Output "Adding new package version to $readmePath"
Update-README-Package-Version-Id $packageVersionId
prettier --write $readmePath
git add $readmePath

Write-Output "Installing new package version ID $packageVersionId for target user $targetusername"
Install-Package-Version $packageVersionId
