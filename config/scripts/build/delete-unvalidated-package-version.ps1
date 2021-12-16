# This script is used to deleted an unvalidated package version, based on the contents of ./unvalidated-package-version-id.txt
$unvalidatedPackageVersionId = Get-Content -Path ./unvalidated-package-version-id.txt
Write-Output "Unvalidated Package Version ID to Delete: $unvalidatedPackageVersionId"
npx sfdx force:package:version:delete --noprompt --package $unvalidatedPackageVersionId
