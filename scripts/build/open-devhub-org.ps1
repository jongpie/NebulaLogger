# This is used to easily open a devhub org in your browser
# If no devhub is specified using the `-devhub` parameter, then the default devhub is used
param ([string]$devHub)

if (!$devHub) {
    Write-Output "No dev hub specified, checking for default dev hub instead"

    $defaultDevHub = (npx sf config get target-dev-hub  --json | ConvertFrom-Json).result.value
    Write-Output "Default Dev Hub: $defaultDevHub"

    $devHub = $defaultDevHub
}

Write-Output "Opening dev hub: $devHub"
npx sf org open --target-org $devHub