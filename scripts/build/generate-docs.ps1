# This script is used to generate the markdown files used by Github pages
rm -f ./docs/*/*.md
rm -rf ./docs/configuration/
rm -rf ./docs/logger-engine/
rm -rf ./docs/log-management/
rm -rf ./docs/plugin-framework/

npx apexdocs-generate --configPath config/apexdocs.json --scope global public --sourceDir nebula-logger/main/ --targetDir docs

# Make a few adjustments to the generated markdown files so that they work correctly in Github Pages
$indexPageFile = "docs/index.md"
Write-Output "Processing file: $indexPageFile"
(Get-Content -path $indexPageFile -Raw) -replace ".md","" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Configuration/","configuration/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Logger-Engine/","logger-engine/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Log-Management/","log-management/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Plugin-Framework/","plugin-framework/" | Set-Content -Path $indexPageFile -NoNewline

$docsSubdirectories = "docs/*/*.*"
foreach($file in Get-ChildItem $docsSubdirectories) {
    Write-Output "Processing file: $file"
    (Get-Content -path $file -Raw) -replace ".md","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "/Configuration/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "/Logger-Engine/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "/Log-Management/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "/Plugin-Framework/","" | Set-Content -Path $file -NoNewline
}

mv ./docs/Configuration/ ./docs/configuration/
mv ./docs/Logger-Engine/ ./docs/logger-engine/
mv ./docs/Log-Management/ ./docs/log-management/
mv ./docs/Plugin-Framework/ ./docs/plugin-framework/
prettier ./docs/ --write
