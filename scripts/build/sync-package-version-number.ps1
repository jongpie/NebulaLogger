# This script is used to automatically sync the package version number for Nebula Logger (stored in sfdx-project.json)
# and update other files - package.json and Logger.cls - to ensure that all 3 files have the same version number

$sfdxProjectJsonPath = "./sfdx-project.json"
$packageJsonPath = "./package.json"
$readmeClassPath = "./README.md"
$loggerClassPath = "./nebula-logger/core/main/logger-engine/classes/Logger.cls"

function Get-SFDX-Project-JSON {
    Get-Content -Path $sfdxProjectJsonPath | ConvertFrom-Json
}

function Get-Version-Number {
    $projectJSON = Get-SFDX-Project-JSON
    $versionNumber = ($projectJSON).packageDirectories[0].versionNumber
    $versionNumber = $versionNumber.substring(0, $versionNumber.LastIndexOf('.'))
    return $versionNumber
}

function Get-Package-JSON {
    Get-Content -Raw -Path $packageJsonPath | ConvertFrom-Json
}

function Update-Package-JSON {
    param (
        $versionNumber
    )
    $packageJson = Get-Package-JSON
    Write-Output "Bumping package.json version number to: $versionNumber"

    $packageJson.version = $versionNumber
    ConvertTo-Json -InputObject $packageJson | Set-Content -Path $packageJsonPath -NoNewline
    npx prettier --write $packageJsonPath
    git add $packageJsonPath
}

function Get-README {
    Get-Content -Raw -Path $readmeClassPath
}

function Update-README {
    param (
        $versionNumber
    )
    $versionNumber = "v" + $versionNumber
    $readmeContents = Get-README
    Write-Output "Bumping README unlocked package version number to: $versionNumber"

    $targetRegEx = "(.+ Unlocked Package - )(.+)"
    $replacementRegEx = '$1' + $versionNumber
    $readmeContents -replace $targetRegEx, $replacementRegEx | Set-Content -Path $readmeClassPath -NoNewline
    npx prettier --write $readmeClassPath
    git add $readmeClassPath
}

function Get-Logger-Class {
    Get-Content -Raw -Path $loggerClassPath
}

function Update-Logger-Class {
    param (
        $versionNumber
    )
    $versionNumber = "v" + $versionNumber
    $loggerClassContents = Get-Logger-Class
    Write-Output "Bumping Logger.cls version number to: $versionNumber"

    $targetRegEx = "(.+CURRENT_VERSION_NUMBER = ')(.+)(';)"
    $replacementRegEx = '$1' + $versionNumber + '$3'
    $loggerClassContents -replace $targetRegEx, $replacementRegEx | Set-Content -Path $loggerClassPath -NoNewline
    npx prettier --write $loggerClassPath
    git add $loggerClassPath
}

$versionNumber = Get-Version-Number
Write-Output "Target Version Number: $versionNumber"

Update-Package-JSON $versionNumber
Update-README $versionNumber
Update-Logger-Class $versionNumber
