# This script is used to create a new package version for the specified package alias
# It then auto-adds the new package version the files sfdx-project.json and README.md
# Finally, the new package version is installed it into an org, using the specified target username
param ([string]$targetpackagealias, [string]$targetreadme, [string]$targetusername)

$DebugPreference = 'Continue'
$ErrorActionPreference = 'Stop'

# TODO WHYYYY IS THIS NECESSARY?!
$targetpackagealias = $targetpackagealias -replace '"', ''
$sfdxProjectJsonPath = "./sfdx-project.json"

function Get-SFDX-Project-JSON {
    Get-Content -Path $sfdxProjectJsonPath | ConvertFrom-Json -Depth 10
}

function Get-Package-Info {
    $sfdxProjectJson = Get-SFDX-Project-JSON
    $packageDirectories = $sfdxProjectJson.packageDirectories
    $packageInfo

    Write-Debug "Checking $sfdxProjectJsonPath for target package $targetpackagealias"
    foreach ($packageDirectory in $packageDirectories) {
        $currentPackageName = $packageDirectory.package
        Write-Debug "Comparing to package: '$currentPackageName'"
        if ($currentPackageName -eq $targetpackagealias) {
            Write-Debug "Found target package $targetpackagealias $sfdxProjectJsonPath "
            $packageInfo = $packageDirectory
            break
        }
    }
    if ($null -eq $packageInfo) {
        throw "Package alias $targetpackagealias not found!"
    }
    return $packageInfo
}

function Get-Formatted-Package-Version-Name {
    param (
        $packageInfo
    )

    return ($packageInfo.versionName).ToLower() -replace " ", "-"
}

function Get-Formatted-Package-Version-Number {
    param(
        $packageInfo
    )

    $packageVersionNumber = $packageInfo.versionNumber

    # In sfdx-project.json, the packageDirectories section uses version number format W.X.Y.Z (all dots "." as delimiters)
    # but in packageAliases, it uses the format W.X.Y-Z (last delimiter is a dash "-")
    [int]$lastDotIndex = $packageVersionNumber.LastIndexOf('.')
    $cleanedPackageVersionNumber = $packageVersionNumber.SubString(0, $lastDotIndex)
    Write-Debug "Formatted Package Version Number $cleanedPackageVersionNumber"
    return $cleanedPackageVersionNumber
}

function Get-Package-Version-Alias {
    param (
        $packageInfo
    )

    return $targetpackagealias + "@" + (Get-Formatted-Package-Version-Number $packageInfo) + "-" + (Get-Formatted-Package-Version-Name $packageInfo)
}

function Build-New-Package-Version {
    $gitBranch = (git branch --show-current)
    $gitCommit = (git rev-parse HEAD)

    $packageVersionCreateResult = npx sf package version create --json --skip-ancestor-check --package $targetpackagealias --code-coverage --installation-key-bypass --wait 30 --branch $gitBranch --tag $gitCommit | ConvertFrom-Json
    $result = $packageVersionCreateResult.result
    Write-Debug "Package version creation result: $result"
    $packageVersionId = $packageVersionCreateResult.result.SubscriberPackageVersionId

    if ($null -eq $packageVersionId -or $packageVersionId -eq "") {
        throw "Error creating package version ID: $packageVersionCreateResult"
    }

    $packageVersionId = "$packageVersionId".Trim()
    return $packageVersionId
}

function Update-SFDX-Project-JSON-Package-Version-Id {
    param (
        $packageVersionAlias,
        $packageVersionId
    )
    # Sometimes, the sfdx commands change the contents of sfdx-project.json
    # But we don't want that here, so revert the file first, in case there are any undesired changes
    git reset HEAD $sfdxProjectJsonPath
    git checkout -- $sfdxProjectJsonPath

    $projectJSON = Get-SFDX-Project-JSON

    # Add the new package version alias & sort all of the package aliases
    # TODO: this sorting "works," but doesn't take into account double digits in parts of the version number
    # For example, 4.6.10-0 is sorted before 4.6.2-0, even though 2 < 10
    ($projectJSON).packageAliases | Add-Member -Name "$packageVersionAlias" -value "$packageVersionId" -MemberType NoteProperty -Force
    $sortedPropertiess = [ordered] @{}
    Get-Member -Type NoteProperty -InputObject $projectJSON.packageAliases | Sort-Object { $_.Name } | % { $sortedPropertiess[$_.Name] = $projectJSON.packageAliases.$($_.Name) }

    # Add the new package version to sfdx-project.json
    $sortedPackageAliases = New-Object PSCustomObject
    Add-Member -InputObject $sortedPackageAliases -NotePropertyMembers $sortedPropertiess
    $projectJSON.packageAliases = $sortedPackageAliases
    $projectJSON | Sort-Object -Property Id -Descending | ConvertTo-Json -depth 32 | Set-Content $sfdxProjectJsonPath
}

function Update-README-Package-Version-Id {
    param (
        $packageVersionId
    )

    $packageVersionId = "$packageVersionId".Trim()
    # Since there are links for both the unlocked & managed packages, the unlocked package buttons & sf commands are used to ensure the correct package version ID is updated
    $sandboxUnlockedPackageReplacement = "btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=$packageVersionId"
    ((Get-Content -path $targetreadme -Raw) -replace "btn-install-unlocked-package-sandbox.png\)\]\(https:\/\/test.salesforce.com\/packaging\/installPackage.apexp\?p0=.{0,18}", $sandboxUnlockedPackageReplacement) | Set-Content -Path $targetreadme -NoNewline
    $productionUnlockedPackageReplacement = "btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=$packageVersionId"
    ((Get-Content -path $targetreadme -Raw) -replace "btn-install-unlocked-package-production.png\)\]\(https:\/\/login.salesforce.com\/packaging\/installPackage.apexp\?p0=.{0,18}", $productionUnlockedPackageReplacement) | Set-Content -Path $targetreadme -NoNewline
    $sfUnlockedPackageReplacement = "sf package install --wait 20 --security-type AdminsOnly --package $packageVersionId"
    ((Get-Content -path $targetreadme -Raw) -replace "sf package install --wait 20 --security-type AdminsOnly --package .{0,18}", $sfUnlockedPackageReplacement) | Set-Content -Path $targetreadme -NoNewline
}

function Install-Package-Version {
    param (
        $packageVersionId
    )

    $packageVersionId = "$packageVersionId".Trim()
    npx sf package install --no-prompt --target-org $targetusername --wait 20 --publish-wait 5 --package $packageVersionId
    if ($LASTEXITCODE -ne 0) {
        throw "Error installing package version ID: $packageVersionId"
    }
    else {
        Write-Debug "Installed package version ID $packageVersionId for alias $targetusername"
    }
}

$packageInfo = Get-Package-Info
$packagePath = $packageInfo.path
Write-Debug "Creating new package version for '$targetpackagealias' package, using path $packagePath"
$packageVersionId = Build-New-Package-Version
Write-Debug "Successfully created new package version ID $packageVersionId"

Write-Debug "Adding new package version to $sfdxProjectJsonPath"
$packageVersionAlias = Get-Package-Version-Alias $packageInfo
Update-SFDX-Project-JSON-Package-Version-Id $packageVersionAlias $packageVersionId
npx prettier --write $sfdxProjectJsonPath
git add $sfdxProjectJsonPath

Write-Debug "Adding new package version ID $packageVersionId to $targetreadme"
Update-README-Package-Version-Id $packageVersionId
npx prettier --write $targetreadme
git add $targetreadme

Write-Debug "Installing new package version ID $packageVersionId for target user $targetusername"
Install-Package-Version $packageVersionId
