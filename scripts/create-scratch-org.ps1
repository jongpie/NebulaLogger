# This is used to circumvent the daily scratch org limits of 6 in dev orgs
# To avoid this limitation, the script checks several dev hubs until it finds one that has an allotment of 1+ scratch org
# This script assumes that the dev hubs have already been authorized locally
param ([string[]]$devHubs)

Write-Output "Starting scratch org creation script"

# Get the configured default dev hub if no devHubs have been specified via parameter
if ($devHubs -eq $null) {
    Write-Output "No dev hubs specified, checking for default dev hub instead"

    $defaultDevHub = (sfdx config:get defaultdevhubusername  --json | ConvertFrom-Json).result.value
    Write-Output "Default Dev Hub: $defaultDevHub"

    [string[]]$devHubs = $defaultDevHub
}
Write-Output "List of possible dev hubs: $devHubs"

foreach($devHub in $devHubs) {
    Write-Output "Trying dev hub: $devHub"
    $scratchOrgAllotment = ((sfdx force:limits:api:display --json --targetusername $devHub | ConvertFrom-Json).result | Where-Object -Property name -eq "DailyScratchOrgs").remaining
    Write-Output "Total remaining scratch orgs for the day for $devHub : $scratchOrgAllotment"

    if($scratchOrgAllotment -gt 0) {
        Write-Output "Beginning scratch org creation"
        # Create Scratch Org
        try {
            $scratchOrgCreateMessage = sfdx force:org:create --setdefaultusername --durationdays 1 --definitionfile config/project-scratch-def-with-experience-cloud.json
            # # # Sometimes SFDX lies (UTC date problem?) about the number of scratch orgs remaining in a given day
            # # # The other issue is that this doesn't throw, so we have to test the response message ourselves
            if($scratchOrgCreateMessage -eq 'The signup request failed because this organization has reached its active scratch org limit') {
                throw $1
            }
            break
        } catch {
            Write-Output "There was an issue with scratch org creation, continuing ..."
        }
    }
}
