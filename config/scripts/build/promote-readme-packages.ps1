# This script finds any production install links for packages within README files & automatically promotes them

$DebugPreference = 'Continue'
$ErrorActionPreference = 'Stop'

function Start-Package-Promotion {
    Write-Debug "Beginning promote script"

    $allReadmes = Get-ChildItem -Exclude node_modules, .sfdx, tests | Get-ChildItem -Filter README.md -Recurse
    foreach ($readme in $allReadmes) {
        $readmePackageIdResults = (Select-String -Path $readme 'https:\/\/login.salesforce.com\/packaging\/installPackage.apexp\?p0=.{0,18}')
        if ($readmePackageIdResults.Matches.Length -gt 0) {
            $packageIdSplit = $readmePackageIdResults.Matches[0].Value.Split("=")
            if ($packageIdSplit.Length -eq 2) {
                $packageId = $packageIdSplit[1]
                Write-Debug "Promoting $packageId from $readme"
                npx sfdx force:package:version:promote --package $packageId --noprompt
            }
        }
    }
    Write-Debug "Finished package promotion!"
}

Start-Package-Promotion