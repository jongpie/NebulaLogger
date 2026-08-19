import { Deps } from '../lib/deps';
import { installPackage, isPackageInstallSecurityType, PackageInstallSecurityType } from '../lib/sf';

export interface PackageInstallOptions {
  packageVersionId: string;
  targetUsername: string;
  securityType?: string;
  waitMinutes?: number;
  publishWaitMinutes?: number;
}

export const runPackageInstall = (deps: Deps, options: PackageInstallOptions): void => {
  let validatedSecurityType: PackageInstallSecurityType | undefined;
  if (options.securityType) {
    if (!isPackageInstallSecurityType(options.securityType)) {
      throw new Error(`Invalid --security-type '${options.securityType}'. Allowed values: AllUsers, AdminsOnly, Custom`);
    }
    validatedSecurityType = options.securityType;
  }

  deps.logger.debug(
    `Installing package version ${options.packageVersionId} into ${options.targetUsername}` +
      (validatedSecurityType ? ` with security type ${validatedSecurityType}` : '')
  );

  installPackage(deps.sfRunner, {
    packageVersionId: options.packageVersionId.trim(),
    targetUsername: options.targetUsername,
    securityType: validatedSecurityType,
    waitMinutes: options.waitMinutes,
    publishWaitMinutes: options.publishWaitMinutes,
  });
  deps.logger.info(`Installed package version ${options.packageVersionId} for target ${options.targetUsername}`);
};
