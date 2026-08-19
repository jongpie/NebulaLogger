import { Deps } from '../lib/deps';
import { updateReadmePackageVersionId } from '../lib/readme';

export interface ReadmeUpdatePackageVersionOptions {
  readmePath: string;
  packageVersionId: string;
}

export const runReadmeUpdatePackageVersion = (deps: Deps, options: ReadmeUpdatePackageVersionOptions): void => {
  const current = deps.fileSystem.readTextFile(options.readmePath);
  const updated = updateReadmePackageVersionId(current, options.packageVersionId);
  deps.fileSystem.writeTextFile(options.readmePath, updated);
  deps.logger.info(`Updated ${options.readmePath} with package version ${options.packageVersionId}`);
};
