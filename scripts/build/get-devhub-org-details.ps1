# This is used to easily check org details for any devhub
# If no devhub is specified using the `-devhub` parameter, then the default devhub is used
param ([string]$devHub)

if (!$devHub) {
    Write-Output "No dev hub specified, checking for default dev hub instead"

    $defaultDevHub = (npx sf config get target-dev-hub  --json | ConvertFrom-Json).result.value
    Write-Output "Default Dev Hub: $defaultDevHub"

    $devHub = $defaultDevHub
}

Write-Output "Getting dev hub limits for dev hub: $devHub"
npx sf org display --json --verbose --target-org $devHub