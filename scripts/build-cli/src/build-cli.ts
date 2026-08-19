import { Command } from 'commander';
import { createDefaultDeps, Deps } from './lib/deps';
import { runPackageInstall } from './commands/package-install';
import { runPackageVersionCreate } from './commands/package-version-create';
import { runReadmeUpdatePackageVersion } from './commands/readme-update-package-version';
import { runReleaseCreateAndInstall } from './commands/release-create-and-install';
import { runSfdxProjectAliasesUpdate } from './commands/sfdx-project-aliases-update';

const ALLOWED_SECURITY_TYPES = ['AllUsers', 'AdminsOnly', 'Custom'] as const;

export const buildCli = (deps: Deps = createDefaultDeps()): Command => {
  const program = new Command();
  program.name('nebula').description('Nebula Logger build & release CLI').version('0.1.0').exitOverride();

  const packageCmd = program.command('package').description('Package version create/install commands');

  const packageVersionCmd = packageCmd.command('version').description('Package version subcommands');

  packageVersionCmd
    .command('create')
    .description('Create a new 2GP package version for the given package alias')
    .requiredOption('-a, --alias <alias>', '2GP package alias as defined in sfdx-project.json')
    .action((raw: { alias: string }) => {
      runPackageVersionCreate(deps, { packageAlias: raw.alias });
    });

  packageCmd
    .command('install')
    .description('Install a package version into a target org')
    .requiredOption('-p, --package <packageVersionId>', 'Subscriber package version ID (04t...)')
    .requiredOption('-o, --target-org <username>', 'Target org username or alias')
    .option('-s, --security-type <type>', `Package install security type (${ALLOWED_SECURITY_TYPES.join(', ')})`)
    .option('--wait <minutes>', 'Wait minutes for install (default: 20)', parseIntOption)
    .option('--publish-wait <minutes>', 'Publish wait minutes (default: 5)', parseIntOption)
    .action((raw: { package: string; targetOrg: string; securityType?: string; wait?: number; publishWait?: number }) => {
      runPackageInstall(deps, {
        packageVersionId: raw.package,
        targetUsername: raw.targetOrg,
        securityType: raw.securityType,
        waitMinutes: raw.wait,
        publishWaitMinutes: raw.publishWait,
      });
    });

  const sfdxProjectCmd = program.command('sfdx-project').description('sfdx-project.json maintenance commands');

  const sfdxProjectAliasesCmd = sfdxProjectCmd.command('aliases').description('sfdx-project.json packageAliases subcommands');

  sfdxProjectAliasesCmd
    .command('update')
    .description('Merge a newly-created package version alias into sfdx-project.json')
    .requiredOption('-a, --alias <alias>', '2GP package alias')
    .requiredOption('-p, --package <packageVersionId>', 'Subscriber package version ID (04t...)')
    .option('--sfdx-project-path <path>', 'Path to sfdx-project.json', './sfdx-project.json')
    .action((raw: { alias: string; package: string; sfdxProjectPath: string }) => {
      runSfdxProjectAliasesUpdate(deps, {
        packageAlias: raw.alias,
        packageVersionId: raw.package,
        sfdxProjectPath: deps.fileSystem.resolve(deps.cwd, raw.sfdxProjectPath),
      });
    });

  const readmeCmd = program.command('readme').description('README maintenance commands');

  readmeCmd
    .command('update-package-version')
    .description('Rewrite the README package-install snippets to point at a new package version ID')
    .requiredOption('-p, --package <packageVersionId>', 'Subscriber package version ID (04t...)')
    .option('--readme-path <path>', 'Path to the README file', './README.md')
    .action((raw: { package: string; readmePath: string }) => {
      runReadmeUpdatePackageVersion(deps, {
        packageVersionId: raw.package,
        readmePath: deps.fileSystem.resolve(deps.cwd, raw.readmePath),
      });
    });

  const releaseCmd = program.command('release').description('Higher-level release orchestration commands');

  releaseCmd
    .command('create-and-install')
    .description('Create a new package version, update sfdx-project.json + README, and install into a target org')
    .requiredOption('-a, --alias <alias>', '2GP package alias')
    .requiredOption('-o, --target-org <username>', 'Target org username or alias')
    .option('--readme-path <path>', 'Path to the README file', './README.md')
    .option('--sfdx-project-path <path>', 'Path to sfdx-project.json', './sfdx-project.json')
    .option('-s, --security-type <type>', `Package install security type (${ALLOWED_SECURITY_TYPES.join(', ')})`)
    .action((raw: { alias: string; targetOrg: string; readmePath: string; sfdxProjectPath: string; securityType?: string }) => {
      runReleaseCreateAndInstall(deps, {
        packageAlias: raw.alias,
        readmePath: deps.fileSystem.resolve(deps.cwd, raw.readmePath),
        targetUsername: raw.targetOrg,
        sfdxProjectPath: deps.fileSystem.resolve(deps.cwd, raw.sfdxProjectPath),
        securityType: raw.securityType,
      });
    });

  return program;
};

const parseIntOption = (raw: string): number => {
  const parsed = Number.parseInt(raw, 10);
  if (Number.isNaN(parsed)) {
    throw new Error(`Expected an integer, got: ${raw}`);
  }
  return parsed;
};
