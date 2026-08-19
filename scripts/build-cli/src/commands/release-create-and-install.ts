import { Deps } from '../lib/deps';
import { runPackageInstall } from './package-install';
import { runPackageVersionCreate } from './package-version-create';
import { runReadmeUpdatePackageVersion } from './readme-update-package-version';
import { runSfdxProjectAliasesUpdate } from './sfdx-project-aliases-update';

export interface ReleaseCreateAndInstallOptions {
  packageAlias: string;
  readmePath: string;
  targetUsername: string;
  sfdxProjectPath: string;
  securityType?: string;
}

export const runReleaseCreateAndInstall = (deps: Deps, options: ReleaseCreateAndInstallOptions): string => {
  const originalSfdxProjectContents = deps.fileSystem.readTextFile(options.sfdxProjectPath);
  const packageVersionId = runPackageVersionCreate(deps, { packageAlias: options.packageAlias });

  runSfdxProjectAliasesUpdate(deps, {
    packageAlias: options.packageAlias,
    packageVersionId,
    sfdxProjectPath: options.sfdxProjectPath,
    originalSfdxProjectContents,
  });

  runReadmeUpdatePackageVersion(deps, {
    readmePath: options.readmePath,
    packageVersionId,
  });

  runPackageInstall(deps, {
    packageVersionId,
    targetUsername: options.targetUsername,
    securityType: options.securityType,
  });

  deps.logger.info(`PACKAGE_VERSION_ID=${packageVersionId}`);
  return packageVersionId;
};
