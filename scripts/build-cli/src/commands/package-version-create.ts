import { Deps } from '../lib/deps';
import { getCurrentBranch, getCurrentCommitSha } from '../lib/git';
import { createPackageVersion } from '../lib/sf';

export interface PackageVersionCreateOptions {
  packageAlias: string;
}

export const runPackageVersionCreate = (deps: Deps, options: PackageVersionCreateOptions): string => {
  const gitBranch = getCurrentBranch(deps.gitRunner);
  const gitCommit = getCurrentCommitSha(deps.gitRunner);
  deps.logger.debug(`Creating package version for '${options.packageAlias}' on branch ${gitBranch} @ ${gitCommit}`);

  const result = createPackageVersion(deps.sfRunner, {
    packageAlias: options.packageAlias,
    gitBranch,
    gitCommit,
  });
  const packageVersionId = result.SubscriberPackageVersionId?.trim();
  if (!packageVersionId) {
    throw new Error(`sf package version create returned no SubscriberPackageVersionId: ${JSON.stringify(result)}`);
  }
  deps.logger.info(`Created package version: ${packageVersionId}`);
  return packageVersionId;
};
