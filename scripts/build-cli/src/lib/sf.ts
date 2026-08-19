import { CommandRunner } from './deps';

export interface PackageVersionCreateResult {
  SubscriberPackageVersionId?: string;
  [additionalField: string]: unknown;
}

export interface SfPackageVersionCreateOptions {
  packageAlias: string;
  gitBranch: string;
  gitCommit: string;
}

export const createPackageVersion = (sfRunner: CommandRunner, options: SfPackageVersionCreateOptions): PackageVersionCreateResult => {
  const command = [
    'npx sf package version create',
    '--json',
    '--skip-ancestor-check',
    `--package ${quote(options.packageAlias)}`,
    '--code-coverage',
    '--installation-key-bypass',
    '--wait 30',
    `--branch ${quote(options.gitBranch)}`,
    `--tag ${quote(options.gitCommit)}`,
  ].join(' ');

  const result = sfRunner.run(command);
  if (result.exitCode !== 0) {
    throw new Error(`sf package version create failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`);
  }

  const parsed = tryParseJson(result.stdout);
  if (!parsed || typeof parsed !== 'object' || !('result' in parsed)) {
    throw new Error(`Could not parse sf package version create output as JSON: ${result.stdout}`);
  }
  return (parsed as { result: PackageVersionCreateResult }).result;
};

export type PackageInstallSecurityType = 'AllUsers' | 'AdminsOnly' | 'Custom';

export const isPackageInstallSecurityType = (value: string): value is PackageInstallSecurityType => {
  return value === 'AllUsers' || value === 'AdminsOnly' || value === 'Custom';
};

export interface SfPackageInstallOptions {
  packageVersionId: string;
  targetUsername: string;
  securityType?: PackageInstallSecurityType;
  waitMinutes?: number;
  publishWaitMinutes?: number;
}

export const installPackage = (sfRunner: CommandRunner, options: SfPackageInstallOptions): void => {
  const commandParts = [
    'npx sf package install',
    '--no-prompt',
    `--target-org ${quote(options.targetUsername)}`,
    `--wait ${options.waitMinutes ?? 20}`,
    `--publish-wait ${options.publishWaitMinutes ?? 5}`,
    `--package ${options.packageVersionId}`,
  ];
  if (options.securityType) {
    commandParts.push(`--security-type ${options.securityType}`);
  }
  const command = commandParts.join(' ');

  const result = sfRunner.run(command);
  if (result.exitCode !== 0) {
    throw new Error(`sf package install failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`);
  }
};

const quote = (value: string): string => `"${value.replace(/"/g, '\\"')}"`;

const tryParseJson = (raw: string): unknown => {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
};
