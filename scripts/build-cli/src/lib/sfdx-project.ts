export interface PackageDirectory {
  package?: string;
  path: string;
  versionName?: string;
  versionNumber?: string;
  versionDescription?: string;
  default?: boolean;
  [additionalField: string]: unknown;
}

export interface SfdxProjectJson {
  packageDirectories: PackageDirectory[];
  packageAliases?: Record<string, string>;
  [additionalField: string]: unknown;
}

export const findPackageDirectory = (project: SfdxProjectJson, packageAlias: string): PackageDirectory => {
  const packageDirectory = project.packageDirectories.find((entry) => entry.package === packageAlias);
  if (!packageDirectory) {
    throw new Error(`Package alias '${packageAlias}' not found in sfdx-project.json`);
  }
  return packageDirectory;
};

export const buildPackageVersionAlias = (packageAlias: string, versionNumber: string, versionName: string): string => {
  return `${packageAlias}@${formatVersionNumber(versionNumber)}-${formatVersionName(versionName)}`;
};

export const formatVersionNumber = (versionNumber: string): string => {
  const lastDotIndex = versionNumber.lastIndexOf('.');
  if (lastDotIndex < 0) {
    return versionNumber;
  }
  return versionNumber.substring(0, lastDotIndex);
};

export const formatVersionName = (versionName: string): string => {
  return versionName.toLowerCase().replace(/ /g, '-');
};

export const mergePackageAlias = (project: SfdxProjectJson, versionAlias: string, packageVersionId: string): SfdxProjectJson => {
  const existingAliases = project.packageAliases ?? {};
  const merged: Record<string, string> = { ...existingAliases, [versionAlias]: packageVersionId };
  const sortedKeys = Object.keys(merged).sort((first, second) => first.localeCompare(second));
  const sortedAliases: Record<string, string> = {};
  for (const key of sortedKeys) {
    sortedAliases[key] = merged[key];
  }
  return { ...project, packageAliases: sortedAliases };
};
