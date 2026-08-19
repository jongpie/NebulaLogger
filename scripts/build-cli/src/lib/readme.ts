export const updateReadmePackageVersionId = (readmeContents: string, packageVersionId: string): string => {
  let updated = readmeContents;
  updated = updated.replace(
    /(btn-install-unlocked-package-sandbox\.png\)\]\(https:\/\/test\.salesforce\.com\/packaging\/installPackage\.apexp\?p0=)[A-Za-z0-9]+/,
    `$1${packageVersionId}`
  );
  updated = updated.replace(
    /(btn-install-unlocked-package-production\.png\)\]\(https:\/\/login\.salesforce\.com\/packaging\/installPackage\.apexp\?p0=)[A-Za-z0-9]+/,
    `$1${packageVersionId}`
  );
  updated = updated.replace(
    /(sf package install --wait 20 --security-type AdminsOnly --package )[A-Za-z0-9]+/,
    `$1${packageVersionId}`
  );
  return updated;
};
