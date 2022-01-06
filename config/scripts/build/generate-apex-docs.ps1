# This script is used to generate the markdown files used by Github pages for Apex docs
rm -f ./docs/apex/*/*.md
rm -rf ./docs/apex/configuration/
rm -rf ./docs/apex/logger-engine/
rm -rf ./docs/apex/log-management/
rm -rf ./docs/apex/plugin-framework/

npx apexdocs-generate --configPath ./config/docs/apexdocs.json --scope global public --sourceDir ./nebula-logger/core/main/ --targetDir ./docs/apex --targetGenerator jekyll

# Make a few adjustments to the generated markdown files so that they work correctly in Github Pages
$indexPageFile = "docs/apex/index.md"
Write-Output "Processing file: $indexPageFile"
(Get-Content -path $indexPageFile -Raw) -replace "# Classes","# Nebula Logger for Apex" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace ".md","" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Configuration/","configuration/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Logger-Engine/","logger-engine/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Log-Management/","log-management/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Plugin-Framework/","plugin-framework/" | Set-Content -Path $indexPageFile -NoNewline

$docsSubdirectories = "docs/apex/*/*.*"
foreach($file in Get-ChildItem $docsSubdirectories) {
    Write-Output "Processing file: $file"
    (Get-Content -path $file -Raw) -replace ".md","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Configuration/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Logger-Engine/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Log-Management/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Plugin-Framework/","" | Set-Content -Path $file -NoNewline
}

mv ./docs/apex/Configuration/ ./docs/apex/configuration/
mv ./docs/apex/Logger-Engine/ ./docs/apex/logger-engine/
mv ./docs/apex/Log-Management/ ./docs/apex/log-management/
mv ./docs/apex/Plugin-Framework/ ./docs/apex/plugin-framework/
prettier ./docs/apex/ --write