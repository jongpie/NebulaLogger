import { Deps } from '../lib/deps';
import { buildPackageVersionAlias, findPackageDirectory, mergePackageAlias, SfdxProjectJson } from '../lib/sfdx-project';

export interface SfdxProjectAliasesUpdateOptions {
  packageAlias: string;
  packageVersionId: string;
  sfdxProjectPath: string;
  originalSfdxProjectContents?: string;
}

export const runSfdxProjectAliasesUpdate = (deps: Deps, options: SfdxProjectAliasesUpdateOptions): string => {
  const contentsToParse = options.originalSfdxProjectContents ?? deps.fileSystem.readTextFile(options.sfdxProjectPath);
  const project = JSON.parse(contentsToParse) as SfdxProjectJson;
  const packageInfo = findPackageDirectory(project, options.packageAlias);
  const versionName = packageInfo.versionName ?? '';
  const versionNumber = packageInfo.versionNumber ?? '';
  const versionAlias = buildPackageVersionAlias(options.packageAlias, versionNumber, versionName);
  deps.logger.debug(`Merging package alias '${versionAlias}' -> '${options.packageVersionId}' into ${options.sfdxProjectPath}`);

  const merged = mergePackageAlias(project, versionAlias, options.packageVersionId);
  deps.fileSystem.writeTextFile(options.sfdxProjectPath, `${JSON.stringify(merged, null, 2)}\n`);
  deps.logger.info(`Added ${versionAlias} to ${options.sfdxProjectPath}`);
  return versionAlias;
};
