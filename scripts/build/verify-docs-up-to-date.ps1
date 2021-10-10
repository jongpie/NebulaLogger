# This script is used to verify that the ./docs folder is up to date, based on running npm run docs:fix
$ErrorActionPreference = 'Stop'

function Verify-No-Uncommitted-Changes-To-Docs {
    $uncommittedChanges = git status ./docs --porcelain

    if ($uncommittedChanges -ne $null) {
        throw "Uncommitted changes found: $uncommittedChanges"
    }
}

npm run docs:fix
Verify-No-Uncommitted-Changes-To-Docs
