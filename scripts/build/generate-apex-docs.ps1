# This script is used to generate the markdown files used by Github pages for Apex docs
find ./docs/apex/ -maxdepth 2 -type f -name "*.md" -delete

npx apexdocs-generate --configPath ./config/docs/apexdocs.json --scope global public --sourceDir ./nebula-logger/core/ ./nebula-logger/plugins/ --targetDir ./docs/apex --targetGenerator jekyll

# Make a few adjustments to the generated markdown files so that they work correctly in Github Pages
$indexPageFile = "docs/apex/index.md"
Write-Output "Processing file: $indexPageFile"
(Get-Content -path $indexPageFile -Raw) -replace "# Classes","# Nebula Logger for Apex" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace ".md","" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Configuration/","Configuration/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Logger-Engine/","Logger-Engine/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Log-Management/","Log-Management/" | Set-Content -Path $indexPageFile -NoNewline
(Get-Content -path $indexPageFile -Raw) -replace "/Plugins/","Plugins/" | Set-Content -Path $indexPageFile -NoNewline

$docsSubdirectories = "docs/apex/*/*.*"
foreach($file in Get-ChildItem $docsSubdirectories) {
    Write-Output "Processing file: $file"
    (Get-Content -path $file -Raw) -replace ".md","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Configuration/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Logger-Engine/","" | Set-Content -Path $file -NoNewline
    (Get-Content -path $file -Raw) -replace "../Log-Management/","" | Set-Content -Path $file -NoNewline
}

# mv ./docs/apex/Configuration/ ./docs/apex/configuration/
# mv ./docs/apex/Logger-Engine/ ./docs/apex/logger-engine/
# mv ./docs/apex/Log-Management/ ./docs/apex/log-management/
prettier ./docs/apex/ --write