# This script is used to verify that the ./docs folder is up to date, based on running npm run docs:fix
$ErrorActionPreference = 'Stop'

function Verify-No-Uncommitted-Changes-To-Docs {
    $diff = git diff --cached
    Write-Output "Diff: : $diff"

    $uncommittedChanges = git status --porcelain ./docs/

    if ($uncommittedChanges -ne $null) {
        throw "Uncommitted changes found: $uncommittedChanges"
    }
}

npm run docs:fix:apex
Verify-No-Uncommitted-Changes-To-Docs
