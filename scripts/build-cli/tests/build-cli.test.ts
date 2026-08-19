import { buildCli } from '../src/build-cli';
import { createStubDeps } from './test-doubles';

describe('buildCli commander wiring', () => {
  it('registers the top-level subcommands', () => {
    const deps = createStubDeps();
    const program = buildCli(deps);
    const names = program.commands.map((command) => command.name());
    expect(names.sort()).toEqual(['package', 'readme', 'release', 'sfdx-project']);
  });

  it('dispatches `package install --security-type AllUsers` through to the sfRunner', async () => {
    const deps = createStubDeps();
    const program = buildCli(deps);
    await program.parseAsync(
      ['package', 'install', '--package', '04t5Y0000015zzz', '--target-org', 'scratch-alias', '--security-type', 'AllUsers'],
      { from: 'user' }
    );

    expect(deps.sfRunner.commands).toHaveLength(1);
    expect(deps.sfRunner.commands[0]).toContain('npx sf package install');
    expect(deps.sfRunner.commands[0]).toContain('--target-org "scratch-alias"');
    expect(deps.sfRunner.commands[0]).toContain('--package 04t5Y0000015zzz');
    expect(deps.sfRunner.commands[0]).toContain('--security-type AllUsers');
  });

  it('dispatches `package install` without --security-type when omitted', async () => {
    const deps = createStubDeps();
    const program = buildCli(deps);
    await program.parseAsync(
      ['package', 'install', '--package', '04t5Y0000015zzz', '--target-org', 'scratch-alias'],
      { from: 'user' }
    );
    expect(deps.sfRunner.commands[0]).not.toContain('--security-type');
  });

  it('errors when --security-type gets an unknown value', async () => {
    const deps = createStubDeps();
    const program = buildCli(deps);
    await expect(
      program.parseAsync(
        ['package', 'install', '--package', '04t', '--target-org', 'x', '--security-type', 'SomeoneElse'],
        { from: 'user' }
      )
    ).rejects.toThrow(/Invalid --security-type/);
  });

  it('errors when a required option is missing', async () => {
    const deps = createStubDeps();
    const program = buildCli(deps);
    program.configureOutput({
      writeErr: () => {},
      writeOut: () => {},
    });
    await expect(program.parseAsync(['package', 'install', '--target-org', 'scratch-alias'], { from: 'user' })).rejects.toThrow();
  });

  it('nests `package version create` under `package version`', async () => {
    const deps = createStubDeps();
    deps.gitRunner.queueResult({ stdout: 'main\n', stderr: '', exitCode: 0 });
    deps.gitRunner.queueResult({ stdout: 'abc123\n', stderr: '', exitCode: 0 });
    deps.sfRunner.queueResult({
      stdout: JSON.stringify({ result: { SubscriberPackageVersionId: '04t5Y0000015zzz' } }),
      stderr: '',
      exitCode: 0,
    });

    const program = buildCli(deps);
    await program.parseAsync(['package', 'version', 'create', '--alias', 'Nebula Logger - Core'], { from: 'user' });

    expect(deps.sfRunner.commands[0]).toContain('npx sf package version create');
    expect(deps.sfRunner.commands[0]).toContain('--package "Nebula Logger - Core"');
  });

  it('nests `sfdx-project aliases update` under `sfdx-project aliases`', async () => {
    const deps = createStubDeps({
      initialFiles: {
        '/repo/sfdx-project.json': JSON.stringify({
          packageDirectories: [
            {
              package: 'Nebula Logger - Core',
              path: './x',
              versionName: 'Some Version',
              versionNumber: '1.2.3.NEXT',
            },
          ],
          packageAliases: {},
        }),
      },
    });

    const program = buildCli(deps);
    await program.parseAsync(
      ['sfdx-project', 'aliases', 'update', '--alias', 'Nebula Logger - Core', '--package', '04t5Y0000015zzz', '--sfdx-project-path', 'sfdx-project.json'],
      { from: 'user' }
    );

    const written = JSON.parse(deps.fileSystem.files['/repo/sfdx-project.json']) as { packageAliases: Record<string, string> };
    expect(written.packageAliases['Nebula Logger - Core@1.2.3-some-version']).toBe('04t5Y0000015zzz');
  });
});
