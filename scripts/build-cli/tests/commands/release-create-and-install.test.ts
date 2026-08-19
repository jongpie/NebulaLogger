import { runReleaseCreateAndInstall } from '../../src/commands/release-create-and-install';
import { createStubDeps } from '../test-doubles';

const buildSfdxProjectFixture = (): string =>
  JSON.stringify(
    {
      packageDirectories: [
        {
          package: 'Nebula Logger - Core',
          path: './nebula-logger/core',
          versionName: 'PrismJS Loading Improvements & Error Handling',
          versionNumber: '4.18.3.NEXT',
        },
      ],
      packageAliases: {
        'Nebula Logger - Core': '0Ho5Y000000TNKASA4',
      },
    },
    null,
    2
  );

const buildReadmeFixture = (): string =>
  [
    '[![Sandbox](./btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000aaa)',
    '[![Prod](./btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5Y0000000bbb)',
    'sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000000ccc',
  ].join('\n');

describe('runReleaseCreateAndInstall', () => {
  it('runs create, updates sfdx-project.json + README, and installs, in order', () => {
    const deps = createStubDeps({
      initialFiles: {
        '/repo/sfdx-project.json': buildSfdxProjectFixture(),
        '/repo/README.md': buildReadmeFixture(),
      },
    });
    deps.gitRunner.queueResult({ stdout: 'main\n', stderr: '', exitCode: 0 });
    deps.gitRunner.queueResult({ stdout: 'abc123\n', stderr: '', exitCode: 0 });
    deps.sfRunner.queueResult({
      stdout: JSON.stringify({ result: { SubscriberPackageVersionId: '04t5Y0000015zzz' } }),
      stderr: '',
      exitCode: 0,
    });
    deps.sfRunner.queueResult({ stdout: '', stderr: '', exitCode: 0 });

    const packageVersionId = runReleaseCreateAndInstall(deps, {
      packageAlias: 'Nebula Logger - Core',
      readmePath: '/repo/README.md',
      targetUsername: 'scratch-alias',
      sfdxProjectPath: '/repo/sfdx-project.json',
      securityType: 'AllUsers',
    });

    expect(packageVersionId).toBe('04t5Y0000015zzz');
    expect(deps.sfRunner.commands[0]).toContain('sf package version create');
    expect(deps.sfRunner.commands[1]).toContain('sf package install');
    expect(deps.sfRunner.commands[1]).toContain('--security-type AllUsers');

    const writtenReadme = deps.fileSystem.files['/repo/README.md'];
    expect(writtenReadme).toContain('installPackage.apexp?p0=04t5Y0000015zzz');
    expect(writtenReadme).toContain('sf package install --wait 20 --security-type AdminsOnly --package 04t5Y0000015zzz');

    const writtenSfdxProject = JSON.parse(deps.fileSystem.files['/repo/sfdx-project.json']) as { packageAliases: Record<string, string> };
    expect(writtenSfdxProject.packageAliases['Nebula Logger - Core@4.18.3-prismjs-loading-improvements-&-error-handling']).toBe('04t5Y0000015zzz');

    expect(deps.logger.records.some((record) => record.level === 'info' && record.message === 'PACKAGE_VERSION_ID=04t5Y0000015zzz')).toBe(true);
  });

  it('captures the original sfdx-project.json BEFORE calling sf package version create (defends against sf mutating it)', () => {
    const deps = createStubDeps({
      initialFiles: {
        '/repo/sfdx-project.json': buildSfdxProjectFixture(),
        '/repo/README.md': buildReadmeFixture(),
      },
    });
    const spy = jest.spyOn(deps.fileSystem, 'readTextFile');
    deps.gitRunner.queueResult({ stdout: 'main', stderr: '', exitCode: 0 });
    deps.gitRunner.queueResult({ stdout: 'abc', stderr: '', exitCode: 0 });
    deps.sfRunner.queueResult({
      stdout: JSON.stringify({ result: { SubscriberPackageVersionId: '04t5Y0000015zzz' } }),
      stderr: '',
      exitCode: 0,
    });
    deps.sfRunner.queueResult({ stdout: '', stderr: '', exitCode: 0 });

    runReleaseCreateAndInstall(deps, {
      packageAlias: 'Nebula Logger - Core',
      readmePath: '/repo/README.md',
      targetUsername: 'scratch-alias',
      sfdxProjectPath: '/repo/sfdx-project.json',
    });

    const firstSfdxProjectReadCallIndex = spy.mock.calls.findIndex((args) => args[0] === '/repo/sfdx-project.json');
    expect(firstSfdxProjectReadCallIndex).toBe(0);
  });
});
