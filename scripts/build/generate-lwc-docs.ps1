# This script is used to generate the markdown files used by Github pages for lightning component jsdocs
npx jsdoc2md nebula-logger/core/main/logger-engine/lwc/logger/logger.js > ./docs/lightning-components/Logger.md
npx jsdoc2md nebula-logger/core/main/logger-engine/lwc/logger/logEntryBuilder.js > ./docs/lightning-components/LogEntryBuilder.md

$docsSubdirectories = "docs/lightning-components/*.*"
foreach($file in Get-ChildItem $docsSubdirectories) {
    Write-Output "Processing file: $file"
    # For whatever reason, this weird string is auto-added to the MD files, so this removes it
    (Get-Content -path $file -Raw) -replace " ΓçÆ","" | Set-Content -Path $file -NoNewline
}
prettier ./docs/lightning-components --write